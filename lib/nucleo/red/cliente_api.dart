import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/red/politica_reintento.dart';
import 'package:reclutaya_app/nucleo/util/resultado.dart';

abstract class ProveedorToken {
  String? get token;

  /// El token listo para MANDAR (12-oct): si el actual ya venció o está por vencer, se
  /// renueva antes, para no gastar un viaje en un 401. Sin red devuelve el actual y
  /// deja que el servidor decida.
  Future<String?> tokenVigente();

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
      _base = base,
      _propio = dio == null,
      _dio = dio ?? _crearDio(base);

  static Dio _crearDio(String base) => Dio(
    BaseOptions(
      baseUrl: base,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
      validateStatus: (_) => true,
    ),
  );

  Dio _dio;
  final String _base;

  /// El Dio lo creó este cliente (en producción). Uno inyectado (pruebas) no se toca.
  final bool _propio;
  final ProveedorToken _tokens;

  /// Empieza con conexiones nuevas (12-oct). Al volver del fondo, iOS ya cerró los
  /// sockets que el cliente cree vivos: la primera petición se iba por uno muerto y se
  /// quedaba esperando hasta el timeout, y la pantalla no cargaba hasta cerrar la app.
  /// Se llama al volver del fondo y antes de reintentar una lectura sin red. Las
  /// peticiones que vayan en vuelo terminan por el cliente viejo: no se cortan.
  void reiniciarConexiones() {
    if (!_propio) return;
    final viejo = _dio;
    _dio = _crearDio(_base);
    viejo.close();
  }

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
    // Solo en desarrollo (8-oct): ruta, estado y tiempo de cada petición, para medir
    // contra producción desde el simulador. Nunca el token ni los cuerpos.
    final reloj = kDebugMode ? (Stopwatch()..start()) : null;
    // El token ya renovado si estaba por vencer (12-oct): al abrir la app tras horas
    // en el fondo, antes salía un 401 seguro, luego renovar y luego repetir.
    final enviado = await _tokens.tokenVigente();
    try {
      res = await _dio.request<dynamic>(
        ruta,
        queryParameters: query,
        data: cuerpo,
        options: Options(
          method: metodo,
          headers: {'Authorization': 'Bearer ${enviado ?? ''}'},
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
      // Una LECTURA que falla por red se reintenta UNA vez con conexiones nuevas: casi
      // siempre era un socket muerto de antes de ir al fondo. Las escrituras no.
      if (error is SinRed && metodo == 'GET' && intento == 0) {
        reiniciarConexiones();
        return await _intentar(
          metodo,
          ruta,
          query,
          cuerpo,
          intento: intento + 1,
        );
      }
      return Falla(error);
    }

    final status = res.statusCode ?? 0;
    if (reloj != null) {
      debugPrint(
        'API $metodo ${Uri.parse(ruta).path} $status ${reloj.elapsedMilliseconds} ms',
      );
    }
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
    // Un 401 con un token que YA cambió (otra petición o Supabase lo renovaron mientras
    // esta iba en camino): se repite con el nuevo, sin renovar otra vez.
    final actual = _tokens.token;
    if (error is SesionVencida &&
        intento == 0 &&
        actual != null &&
        actual != enviado) {
      return await _intentar(metodo, ruta, query, cuerpo, intento: intento + 1);
    }
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
