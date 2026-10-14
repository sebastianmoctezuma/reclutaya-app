import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/funciones/cascaron/pestanas_core.dart';

void main() {
  test(
    'con varias sucursales hay cuatro pestañas, Sucursales después de Vacantes',
    () {
      expect(ramasVisibles(variasSucursales: true), [
        ramaInicio,
        ramaVacantes,
        ramaSucursales,
        ramaCuenta,
      ]);
    },
  );

  test('con una sola sucursal no hay pestaña Sucursales', () {
    expect(ramasVisibles(variasSucursales: false), [
      ramaInicio,
      ramaVacantes,
      ramaCuenta,
    ]);
  });

  test('la pestaña de cada rama; Sucursales sin varias no tiene pestaña', () {
    final tres = ramasVisibles(variasSucursales: false);
    expect(pestanaDeRama(ramaCuenta, tres), 2);
    expect(pestanaDeRama(ramaSucursales, tres), isNull);
    final cuatro = ramasVisibles(variasSucursales: true);
    expect(pestanaDeRama(ramaCuenta, cuatro), 3);
    expect(pestanaDeRama(ramaSucursales, cuatro), 2);
  });
}
