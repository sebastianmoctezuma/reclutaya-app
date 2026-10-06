import 'package:reclutaya_app/nucleo/red/errores_api.dart';

enum DestinoArranque { entrar, negocio, candidatoNoSoportado }

/// Pura. `tipoYo` es lo que contestó `/yo` (null si falló: entonces se entra
/// y la pantalla de Inicio muestra el error con Reintentar; no se expulsa a
/// nadie por un 500).
DestinoArranque destinoArranque({
  required bool haySesion,
  required String? tipoYo,
}) {
  if (!haySesion) return DestinoArranque.entrar;
  if (tipoYo == 'candidato') return DestinoArranque.candidatoNoSoportado;
  return DestinoArranque.negocio;
}

/// Los errores del proveedor de cuentas, en nuestras palabras.
ErrorApi errorDeAcceso(String codigo, String mensaje) {
  return switch (codigo) {
    'invalid_credentials' ||
    'invalid_grant' => const Servidor('Correo o contraseña incorrectos.'),
    'email_not_confirmed' => const Servidor(
      'Tu correo aún no está verificado. Ábrelo desde el enlace que te mandamos.',
    ),
    _ => const Servidor('No se pudo entrar. Intenta de nuevo.'),
  };
}
