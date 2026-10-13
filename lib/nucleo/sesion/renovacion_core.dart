/// Qué significa que falle la renovación del token (12-oct). Puro: lo decide esto y
/// `SesionSupabase` solo lo aplica.
///
/// El bug que lo motivó: Supabase lanza `AuthRetryableFetchException` cuando la RED
/// falla al renovar, y esa clase hereda de `AuthException`. La app atrapaba toda
/// `AuthException` como «la sesión ya no vale» y cerraba la sesión: bastaba abrir la
/// app con la señal floja, o volver del fondo antes de que hubiera red, para que te
/// sacara. Solo un rechazo DEFINITIVO del proveedor (un 4xx que no sea 429) vence la
/// sesión; todo lo demás es «sin red» y la sesión se queda.
enum FalloRenovacion { vencida, sinRed }

FalloRenovacion clasificarFalloRenovacion({
  /// Supabase dice que vale la pena reintentar (falla de red, 5xx).
  required bool reintentable,

  /// No había sesión que renovar: eso sí es definitivo.
  required bool sinSesion,

  /// El código HTTP de la respuesta, si hubo respuesta.
  required int? estado,
}) {
  if (sinSesion) return FalloRenovacion.vencida;
  if (reintentable) return FalloRenovacion.sinRed;
  if (estado == null || estado >= 500 || estado == 429) {
    return FalloRenovacion.sinRed;
  }
  return FalloRenovacion.vencida;
}

/// Margen para renovar ANTES de mandar una petición: un token que vence en menos de
/// esto ya no se manda (el servidor lo rechazaría y costaría un viaje de más: 401,
/// renovar y repetir).
const margenRenovacion = Duration(seconds: 30);

/// ¿Hay que renovar antes de usar este token? `expiraEn` son los segundos desde 1970
/// que trae la sesión (`expiresAt`); null = no se sabe, se usa tal cual.
bool debeRenovarAntes({required int? expiraEn, required DateTime ahora}) {
  if (expiraEn == null) return false;
  final vence = DateTime.fromMillisecondsSinceEpoch(
    expiraEn * 1000,
    isUtc: true,
  );
  return !ahora.toUtc().add(margenRenovacion).isBefore(vence);
}

/// Cuánto tiempo fuera cuenta como «volver»: al regresar después de esto, la app pide
/// de nuevo lo principal por detrás (lo de antes se sigue viendo mientras llega).
const ausenciaParaRefrescar = Duration(seconds: 60);

bool debeRefrescarAlVolver({
  required Duration? ausencia,
  required bool hayError,
}) => hayError || (ausencia != null && ausencia >= ausenciaParaRefrescar);
