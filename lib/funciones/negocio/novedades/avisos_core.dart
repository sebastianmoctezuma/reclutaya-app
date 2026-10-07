/// A dónde lleva tocar un aviso (lo que manda el servidor en `data`): la ficha del
/// candidato o, para el ranking listo, la vacante. Solo letras, números y guiones: un
/// aviso mal formado no abre nada.
String? rutaDeAviso(Map<String, dynamic> datos) {
  final valido = RegExp(r'^[A-Za-z0-9_-]{1,120}$');
  final slug = datos['slug'];
  final id = datos['postulacionId'];
  if (slug is! String || !valido.hasMatch(slug)) return null;
  if (id == null) return '/vacantes/$slug';
  if (id is! String || !valido.hasMatch(id)) return null;
  return '/vacantes/$slug/ranking/$id';
}
