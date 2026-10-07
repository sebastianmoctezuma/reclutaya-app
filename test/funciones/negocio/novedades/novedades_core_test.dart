import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/novedades.dart';
import 'package:reclutaya_app/funciones/negocio/novedades/novedades_core.dart';

Novedad _n(DateTime at) => Novedad(
  tipo: 'postulacion',
  at: at,
  candidato: 'Ana P.',
  accion: 'se postuló',
  puesto: 'Cajero',
  slug: 'cajero',
  postulacionId: 'p1',
);

void main() {
  final ahora = DateTime.utc(2026, 10, 6, 18);

  test('sin haber abierto nunca la campana, todo es nuevo', () {
    expect(nuevasDesde([_n(ahora)], null), hasLength(1));
  });

  test('nuevas = las posteriores al «visto hasta»', () {
    final items = [
      _n(ahora.subtract(const Duration(hours: 1))),
      _n(ahora.subtract(const Duration(hours: 5))),
    ];
    expect(
      nuevasDesde(items, ahora.subtract(const Duration(hours: 2))),
      hasLength(1),
    );
  });

  test('hace cuánto, en palabras', () {
    expect(haceCuanto(ahora, ahora), 'ahora');
    expect(
      haceCuanto(ahora.subtract(const Duration(minutes: 5)), ahora),
      'hace 5 min',
    );
    expect(
      haceCuanto(ahora.subtract(const Duration(hours: 3)), ahora),
      'hace 3 h',
    );
    expect(
      haceCuanto(ahora.subtract(const Duration(hours: 30)), ahora),
      'ayer',
    );
    expect(
      haceCuanto(ahora.subtract(const Duration(days: 4)), ahora),
      'hace 4 días',
    );
  });
}
