import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/funciones/negocio/candidato/controlador_ficha.dart';

void main() {
  test('al fallar la URL se invalida la ficha una sola vez', () {
    final c = ControladorFicha();
    expect(c.puedeReintentarUrl(), isTrue);
    expect(c.puedeReintentarUrl(), isFalse);
  });
}
