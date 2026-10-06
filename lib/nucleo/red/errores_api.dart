import 'package:meta/meta.dart';

/// Los errores del contrato (api-v1.md §Errores), como unión cerrada.
sealed class ErrorApi implements Exception {
  const ErrorApi();

  String get mensaje;
}

final class SesionVencida extends ErrorApi {
  const SesionVencida();

  @override
  String get mensaje => 'Tu sesión terminó. Vuelve a entrar.';
}

final class Prohibido extends ErrorApi {
  const Prohibido();

  @override
  String get mensaje => 'Esta cuenta no puede ver esto.';
}

final class NoEncontrado extends ErrorApi {
  const NoEncontrado();

  @override
  String get mensaje => 'Esto ya no está disponible.';
}

@immutable
final class Limite extends ErrorApi {
  const Limite(this.segundos);

  final int segundos;

  @override
  String get mensaje => 'Demasiadas consultas. Espera un momento.';

  @override
  bool operator ==(Object other) =>
      other is Limite && other.segundos == segundos;

  @override
  int get hashCode => segundos;
}

final class Servidor extends ErrorApi {
  const Servidor([this.detalle]);

  final String? detalle;

  @override
  String get mensaje => detalle ?? 'No se pudo cargar. Intenta de nuevo.';
}

final class SinRed extends ErrorApi {
  const SinRed();

  @override
  String get mensaje => 'Sin conexión. Revisa tu internet e intenta de nuevo.';
}

final class RespuestaInvalida extends ErrorApi {
  const RespuestaInvalida(this.detalle);

  final String detalle;

  @override
  String get mensaje => 'No pudimos leer esta información. Intenta de nuevo.';
}

int segundosEspera(String? retryAfter) {
  final n = int.tryParse(retryAfter ?? '') ?? 1;
  return n.clamp(1, 30);
}

String? _mensajeDe(Object? cuerpo) {
  if (cuerpo is Map && cuerpo['error'] is Map) {
    final m = (cuerpo['error'] as Map)['mensaje'];
    if (m is String && m.isNotEmpty) return m;
  }
  return null;
}

ErrorApi errorDeRespuesta(int status, Object? cuerpo, {String? retryAfter}) {
  return switch (status) {
    401 => const SesionVencida(),
    403 => const Prohibido(),
    404 => const NoEncontrado(),
    429 => Limite(segundosEspera(retryAfter)),
    _ => Servidor(_mensajeDe(cuerpo)),
  };
}
