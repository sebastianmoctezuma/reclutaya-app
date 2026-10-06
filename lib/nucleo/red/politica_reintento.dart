import 'package:reclutaya_app/nucleo/red/errores_api.dart';

enum AccionReintento { renovarYReintentar, esperarYReintentar, noReintentar }

/// UNA sola vez: 401 → renovar sesión y repetir; 429 → esperar y repetir.
/// Lo demás lo reintenta la persona con «Reintentar». 500 jamás manda al login.
AccionReintento decidirReintento(ErrorApi e, {required int intento}) {
  if (intento > 0) return AccionReintento.noReintentar;
  return switch (e) {
    SesionVencida() => AccionReintento.renovarYReintentar,
    Limite() => AccionReintento.esperarYReintentar,
    _ => AccionReintento.noReintentar,
  };
}
