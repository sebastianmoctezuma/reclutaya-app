import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/inicio.dart';
import 'package:reclutaya_app/funciones/negocio/inicio/inicio_core.dart';

const _k = Indicadores(velocidad: 1, respuestaPct: 10);
const _k2 = Indicadores(velocidad: 9, respuestaPct: 90);
SucursalInicio _s(String id, int g) =>
    SucursalInicio(id: id, nombre: id, colorIdx: 0, gastados: g);

void main() {
  test('porcentajes del consumo por sucursal, con «El resto» al final', () {
    final r = rebanadasConsumo([_s('a', 285), _s('b', 4), _s('c', 119)], 0);
    expect(r.total, 408);
    expect(r.rebanadas.map((x) => x.pct), [70, 1, 29]);
    final conResto = rebanadasConsumo([_s('a', 10)], 30);
    expect(conResto.rebanadas.last.nombre, 'El resto');
    expect(conResto.rebanadas.map((x) => x.pct), [25, 75]);
  });

  test('sin consumo, todo en cero y sin dividir entre cero', () {
    final r = rebanadasConsumo([_s('a', 0)], null);
    expect(r.total, 0);
    expect(r.rebanadas.single.pct, 0);
  });

  test('conversión total: contratados sobre postulaciones, redondeada', () {
    expect(
      textoConversion(
        const EmbudoInicio(postulaciones: 96, contactados: 72, contratados: 1),
      ),
      'Conversión total: 1% — de 96 postulaciones, 1 contratación.',
    );
    expect(
      textoConversion(
        const EmbudoInicio(postulaciones: 0, contactados: 0, contratados: 0),
      ),
      'Aún sin postulaciones en estos 30 días.',
    );
  });

  test('el filtro por sucursal toma lo precalculado; sin dato, el total', () {
    const i = Inicio(indicadores: _k, indicadoresPorSucursal: {'s1': _k2});
    expect(indicadoresDe(i, null).velocidad, 1);
    expect(indicadoresDe(i, 's1').velocidad, 9);
    expect(indicadoresDe(i, 'otra').velocidad, 1);
  });

  test('la pestaña se llama Sucursales en multisucursal', () {
    expect(nombrePestanaVacantes(variasSucursales: true), 'Sucursales');
    expect(nombrePestanaVacantes(variasSucursales: false), 'Vacantes');
  });
}
