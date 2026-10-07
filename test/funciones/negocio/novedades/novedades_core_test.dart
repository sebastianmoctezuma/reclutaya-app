import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
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
  setUpAll(() => initializeDateFormatting('es_MX'));
  final ahora = DateTime(2026, 10, 6, 18);

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

  test('agrupa por día: Hoy, Ayer y luego la fecha', () {
    final grupos = porDia([
      _n(DateTime(2026, 10, 6, 9)),
      _n(DateTime(2026, 10, 6, 8)),
      _n(DateTime(2026, 10, 5, 20)),
      _n(DateTime(2026, 10, 2, 10)),
    ], ahora);
    expect(grupos.map((g) => g.$1), ['Hoy', 'Ayer', 'viernes 2 de octubre']);
    expect(grupos.first.$2, hasLength(2));
  });

  test('el resumen cuenta cada tipo', () {
    final n = [
      _n(ahora),
      _n(ahora),
      Novedad(
        tipo: 'video',
        at: ahora,
        accion: 'envió su video',
        puesto: 'Cajero',
        slug: 'cajero',
      ),
    ];
    expect(conteoPorTipo(n), {'postulacion': 2, 'video': 1});
  });
}
