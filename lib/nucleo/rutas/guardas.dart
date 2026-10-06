/// La guarda de go_router, pura: sin sesión todo va a `/entrar` (salvo
/// `/entrar` y `/arranque`). Con sesión NO se adelanta nada: Entrar navega a
/// Inicio solo después de comprobar `/yo` (una cuenta de candidato no debe
/// pisar Inicio ni un instante), y el arranque decide por su cuenta.
String? redirigir({required bool autenticado, required String ruta}) {
  const libres = {'/entrar', '/arranque'};
  if (!autenticado) return libres.contains(ruta) ? null : '/entrar';
  return null;
}
