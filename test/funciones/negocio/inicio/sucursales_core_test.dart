import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/vacantes.dart';
import 'package:reclutaya_app/funciones/negocio/inicio/sucursales_core.dart';

VacanteResumen _v(String id, SucursalRef? s, int c) => VacanteResumen(
  id: id,
  puesto: id,
  estado: 'ACTIVA',
  slug: id,
  sucursal: s,
  candidatos: c,
  sinRankear: 0,
);

void main() {
  const centro = SucursalRef(id: 's1', nombre: 'Centro', colorIdx: 0);
  const norte = SucursalRef(id: 's2', nombre: 'Norte', colorIdx: 1);

  test('agrupa por sucursal, suma candidatos y ordena por vacantes', () {
    final r = resumenSucursales([
      _v('a', norte, 5),
      _v('b', centro, 3),
      _v('c', centro, 4),
      _v('d', null, 9),
    ]);
    expect(r.map((x) => x.sucursal.nombre), ['Centro', 'Norte']);
    expect(r.first.vacantes, 2);
    expect(r.first.candidatos, 7);
  });

  test('sin sucursales no hay resumen', () {
    expect(resumenSucursales([_v('a', null, 1)]), isEmpty);
  });
}
