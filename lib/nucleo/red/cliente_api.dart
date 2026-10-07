import 'package:dio/dio.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/red/politica_reintento.dart';
import 'package:reclutaya_app/nucleo/util/resultado.dart';

abstract class ProveedorToken {
  String? get token;

  Future<String?> renovar();

  /// La sesión no se pudo rescatar: quien implementa cierra y manda al login.
  Future<void> sesionVencida();
}

/// El ÚNICO cliente HTTP de la app. Solo GET (la v1 es de lectura). Nunca
/// registra el token ni los cuerpos.
class ClienteApi {
  ClienteApi({required String base, required ProveedorToken tokens, Dio? dio})
    // El campo es privado y el parámetro público: no hay forma inicializadora.
    // ignore: prefer_initializing_formals
    : _tokens = tokens,
      _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: base,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              headers: {'Accept': 'application/json'},
              validateStatus: (_) => true,
            ),
          );

  final Dio _dio;
  final ProveedorToken _tokens;

  Future<Resultado<Map<String, dynamic>>> get(
    String ruta, {
    Map<String, String>? query,
  }) => _intentar('GET', ruta, query, null, intento: 0);

  /// Las únicas escrituras de la app (API v2: el registro del teléfono para los
  /// avisos). Mismos reintentos y misma renovación de sesión que las lecturas. `ruta`
  /// puede ser una URL completa (la v2 vive junto a la v1).
  Future<Resultado<Map<String, dynamic>>> escribir(
    String metodo,
    String ruta,
    Map<String, Object?> cuerpo,
  ) => _intentar(metodo, ruta, null, cuerpo, intento: 0);

  Future<Resultado<Map<String, dynamic>>> _intentar(
    String metodo,
    String ruta,
    Map<String, String>? query,
    Map<String, Object?>? cuerpo, {
    required int intento,
  }) async {
    final Response<dynamic> res;
    try {
      res = await _dio.request<dynamic>(
        ruta,
        queryParameters: query,
        data: cuerpo,
        options: Options(
          method: metodo,
          headers: {'Authorization': 'Bearer ${_tokens.token ?? ''}'},
          validateStatus: (_) => true,
        ),
      );
    } on DioException catch (e) {
      final error = switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.connectionError => const SinRed(),
        _ => const Servidor(),
      };
      return Falla(error);
    }

    final status = res.statusCode ?? 0;
    if (status >= 200 && status < 300) {
      final datos = res.data;
      if (datos is Map<String, dynamic>) return Exito(datos);
      return const Falla(RespuestaInvalida('el cuerpo no es un objeto JSON'));
    }

    final error = errorDeRespuesta(
      status,
      res.data,
      retryAfter: res.headers.value('retry-after'),
    );
    switch (decidirReintento(error, intento: intento)) {
      case AccionReintento.renovarYReintentar:
        final String? nuevo;
        try {
          nuevo = await _tokens.renovar();
        } on SinRed {
          // Sin red no se sabe si la sesión vale: no se cierra.
          return const Falla(SinRed());
        }
        if (nuevo == null) {
          await _tokens.sesionVencida();
          return Falla(error);
        }
        return await _intentar(
          metodo,
          ruta,
          query,
          cuerpo,
          intento: intento + 1,
        );
      case AccionReintento.esperarYReintentar:
        await Future<void>.delayed(
          Duration(seconds: (error as Limite).segundos),
        );
        return await _intentar(
          metodo,
          ruta,
          query,
          cuerpo,
          intento: intento + 1,
        );
      case AccionReintento.noReintentar:
        if (error is SesionVencida) await _tokens.sesionVencida();
        return Falla(error);
    }
  }
}
