import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/ranking.dart';
import 'package:reclutaya_app/funciones/negocio/ranking/filtro_material.dart';

FilaRanking _f(String id, {bool video = false, bool doc = false, num? test}) =>
    FilaRanking(
      postulacionId: id,
      ranking: 1,
      nombre: id,
      videoRecibido: video,
      documentoRecibido: doc,
      testScore: test,
    );

void main() {
  final filas = [
    _f('a', video: true),
    _f('b', doc: true, test: 70),
    _f('c'),
    _f('d', video: true, test: 55),
  ];

  test('sin filtro, todos', () {
    expect(filtrarPorMaterial(filas, {}).map((f) => f.postulacionId), [
      'a',
      'b',
      'c',
      'd',
    ]);
  });

  test('con varios materiales, quien tenga CUALQUIERA (como la web)', () {
    expect(
      filtrarPorMaterial(filas, {
        MaterialRecibido.video,
      }).map((f) => f.postulacionId),
      ['a', 'd'],
    );
    expect(
      filtrarPorMaterial(filas, {
        MaterialRecibido.documento,
        MaterialRecibido.test,
      }).map((f) => f.postulacionId),
      ['b', 'd'],
    );
  });

  test('cuenta cuántos tienen cada material recibido (no lo pedido)', () {
    expect(conteoMateriales(filas), {
      MaterialRecibido.video: 2,
      MaterialRecibido.documento: 1,
      MaterialRecibido.test: 2,
    });
    expect(
      conteoMateriales([
        const FilaRanking(
          postulacionId: 'x',
          ranking: 1,
          nombre: 'x',
          videoSolicitado: true,
          testEstado: 'ENVIADA',
        ),
      ]).values.every((n) => n == 0),
      isTrue,
    );
  });

  test('el nivel del test usa la escala de la web', () {
    expect(nivelTest(70), NivelTest.alto);
    expect(nivelTest(69), NivelTest.medio);
    expect(nivelTest(45), NivelTest.medio);
    expect(nivelTest(44), NivelTest.bajo);
  });
}
