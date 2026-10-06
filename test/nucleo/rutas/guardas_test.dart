import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/nucleo/rutas/guardas.dart';

void main() {
  test('sin sesión todo va a /entrar, salvo /entrar y /arranque', () {
    expect(redirigir(autenticado: false, ruta: '/inicio'), '/entrar');
    expect(
      redirigir(autenticado: false, ruta: '/vacantes/x/ranking'),
      '/entrar',
    );
    expect(redirigir(autenticado: false, ruta: '/entrar'), isNull);
    expect(redirigir(autenticado: false, ruta: '/arranque'), isNull);
  });

  test('con sesión nada se mueve: /entrar decide tras comprobar /yo', () {
    expect(redirigir(autenticado: true, ruta: '/entrar'), isNull);
    expect(redirigir(autenticado: true, ruta: '/cuenta'), isNull);
  });
}
