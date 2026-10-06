import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/funciones/arranque/nivel_espera.dart';

void main() {
  test('sube rápido y nunca pasa de 0.9 mientras espera', () {
    expect(nivelEspera(0), 0);
    expect(nivelEspera(1), greaterThan(0.4));
    expect(nivelEspera(60), lessThanOrEqualTo(0.9));
  });

  test('arranca desde un nivel dado y no baja', () {
    expect(nivelEspera(0, desde: 0.5), 0.5);
    expect(nivelEspera(2, desde: 0.5), greaterThan(0.5));
  });
}
