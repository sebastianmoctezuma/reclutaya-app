import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/funciones/negocio/novedades/avisos_core.dart';

void main() {
  test('con postulación abre la ficha del candidato; sin ella, la vacante', () {
    expect(
      rutaDeAviso({
        'slug': 'cajero-x1',
        'postulacionId': 'a1b2-c3',
        'tipo': 'postulacion',
      }),
      '/vacantes/cajero-x1/ranking/a1b2-c3',
    );
    expect(
      rutaDeAviso({'slug': 'cajero-x1', 'tipo': 'ranking'}),
      '/vacantes/cajero-x1',
    );
  });

  test(
    'un video, documento o test abre la ficha ya en esa sección (13-oct)',
    () {
      expect(
        rutaDeAviso({
          'slug': 'cajero-x1',
          'postulacionId': 'p9',
          'tipo': 'test',
        }),
        '/vacantes/cajero-x1/ranking/p9?seccion=test',
      );
      expect(
        rutaDeAviso({
          'slug': 'cajero-x1',
          'postulacionId': 'p9',
          'tipo': 'video',
        }),
        '/vacantes/cajero-x1/ranking/p9?seccion=video',
      );
      expect(
        rutaDeAviso({
          'slug': 'cajero-x1',
          'postulacionId': 'p9',
          'tipo': 'documento',
        }),
        '/vacantes/cajero-x1/ranking/p9?seccion=documento',
      );
    },
  );

  test('un tipo desconocido no agrega sección ni rompe la ruta', () {
    expect(
      rutaDeAviso({
        'slug': 'cajero-x1',
        'postulacionId': 'p9',
        'tipo': 'lo-que-sea',
      }),
      '/vacantes/cajero-x1/ranking/p9',
    );
    expect(seccionValida('test'), 'test');
    expect(seccionValida('../x'), isNull);
    expect(seccionValida(null), isNull);
  });

  test('un aviso mal formado no abre nada (ni rutas inventadas)', () {
    expect(rutaDeAviso({}), isNull);
    expect(rutaDeAviso({'slug': '../cuenta'}), isNull);
    expect(rutaDeAviso({'slug': 'ok', 'postulacionId': 'x/../y'}), isNull);
    expect(rutaDeAviso({'slug': 3}), isNull);
  });
}
