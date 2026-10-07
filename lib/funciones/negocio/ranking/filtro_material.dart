import 'package:reclutaya_app/funciones/negocio/comun/modelos/ranking.dart';

/// El material YA RECIBIDO de un candidato: lo que filtra el «Recibido» de la web.
enum MaterialRecibido {
  video('Video'),
  documento('Documento'),
  test('Test');

  MaterialRecibido(this.etiqueta);
  final String etiqueta;
}

bool _tiene(FilaRanking f, MaterialRecibido m) => switch (m) {
  MaterialRecibido.video => f.videoRecibido,
  MaterialRecibido.documento => f.documentoRecibido,
  MaterialRecibido.test => f.testScore != null,
};

/// Sin materiales elegidos, todos; con varios, quien tenga CUALQUIERA de ellos (la
/// misma regla OR del filtro web). Conserva el orden del ranking.
List<FilaRanking> filtrarPorMaterial(
  List<FilaRanking> filas,
  Set<MaterialRecibido> elegidos,
) {
  if (elegidos.isEmpty) return filas;
  return [
    for (final f in filas)
      if (elegidos.any((m) => _tiene(f, m))) f,
  ];
}

/// Cuántos candidatos tienen cada material ya recibido.
Map<MaterialRecibido, int> conteoMateriales(List<FilaRanking> filas) => {
  for (final m in MaterialRecibido.values)
    m: filas.where((f) => _tiene(f, m)).length,
};

enum NivelTest { alto, medio, bajo }

/// La escala del test de la web (`nivelCompat`): verde desde 70, ámbar desde 45, rojo
/// abajo.
NivelTest nivelTest(num pct) => pct >= 70
    ? NivelTest.alto
    : pct >= 45
    ? NivelTest.medio
    : NivelTest.bajo;
