import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/funciones/negocio/novedades/avisos_core.dart';

void main() {
  test('con postulación abre la ficha del candidato; sin ella, la vacante', () {
    expect(
      rutaDeAviso({'slug': 'cajero-x1', 'postulacionId': 'a1b2-c3'}),
      '/vacantes/cajero-x1/ranking/a1b2-c3',
    );
    expect(rutaDeAviso({'slug': 'cajero-x1'}), '/vacantes/cajero-x1');
  });

  test('un aviso mal formado no abre nada (ni rutas inventadas)', () {
    expect(rutaDeAviso({}), isNull);
    expect(rutaDeAviso({'slug': '../cuenta'}), isNull);
    expect(rutaDeAviso({'slug': 'ok', 'postulacionId': 'x/../y'}), isNull);
    expect(rutaDeAviso({'slug': 3}), isNull);
  });
}
