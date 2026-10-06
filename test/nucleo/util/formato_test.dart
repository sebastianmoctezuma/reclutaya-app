import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:reclutaya_app/nucleo/util/formato.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_MX'));

  test('fecha corta en español', () {
    expect(fechaCorta(DateTime(2026, 10, 2)), '2 oct 2026');
  });

  test('números con coma de miles', () {
    expect(numero(1290), '1,290');
  });

  test('experiencia en años y meses', () {
    expect(experiencia(14), '1 año 2 meses');
    expect(experiencia(8), '8 meses');
    expect(experiencia(24), '2 años');
    expect(experiencia(0), 'Sin experiencia');
    expect(experiencia(null), 'Sin experiencia');
  });
}
