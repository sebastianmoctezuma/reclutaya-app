import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/red/politica_reintento.dart';

void main() {
  test('401 en el primer intento renueva y reintenta; en el segundo, no', () {
    expect(
      decidirReintento(const SesionVencida(), intento: 0),
      AccionReintento.renovarYReintentar,
    );
    expect(
      decidirReintento(const SesionVencida(), intento: 1),
      AccionReintento.noReintentar,
    );
  });

  test('429 espera y reintenta una sola vez', () {
    expect(
      decidirReintento(const Limite(5), intento: 0),
      AccionReintento.esperarYReintentar,
    );
    expect(
      decidirReintento(const Limite(5), intento: 1),
      AccionReintento.noReintentar,
    );
  });

  test('500, sin red, 403 y 404 nunca reintentan solos', () {
    for (final e in [
      const Servidor(),
      const SinRed(),
      const Prohibido(),
      const NoEncontrado(),
    ]) {
      expect(
        decidirReintento(e, intento: 0),
        AccionReintento.noReintentar,
        reason: '$e',
      );
    }
  });
}
