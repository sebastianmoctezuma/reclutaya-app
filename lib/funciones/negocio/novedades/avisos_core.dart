/// A dónde lleva tocar un aviso (lo que manda el servidor en `data`): la ficha del
/// candidato o, para el ranking listo, la vacante. Solo letras, números y guiones: un
/// aviso mal formado no abre nada.
///
/// Con SECCIÓN (13-oct): si el aviso es de un video, un documento o un test, la ruta
/// lleva `?seccion=` y la ficha se abre ya desplazada a esa parte, sin que el dueño
/// tenga que buscarla.
String? rutaDeAviso(Map<String, dynamic> datos) {
  final valido = RegExp(r'^[A-Za-z0-9_-]{1,120}$');
  final slug = datos['slug'];
  final id = datos['postulacionId'];
  if (slug is! String || !valido.hasMatch(slug)) return null;
  if (id == null) return '/vacantes/$slug';
  if (id is! String || !valido.hasMatch(id)) return null;
  final seccion = seccionDeAviso(datos['tipo']);
  return '/vacantes/$slug/ranking/$id${seccion == null ? '' : '?seccion=$seccion'}';
}

/// Las secciones de la ficha a las que un aviso puede llevar directo.
const seccionesFicha = {'video', 'documento', 'test'};

/// La sección de la ficha que corresponde al tipo del aviso; null = arriba del todo
/// (una postulación nueva se lee desde el principio).
String? seccionDeAviso(Object? tipo) =>
    tipo is String && seccionesFicha.contains(tipo) ? tipo : null;

/// Lo que la pantalla acepta como sección (viene de la URL: nunca se confía).
String? seccionValida(String? s) =>
    s != null && seccionesFicha.contains(s) ? s : null;
