import 'dart:math' as math;

const _tope = 0.9;
const _ritmoS = 1.6;

/// El nivel del líquido según la ESPERA real (la misma curva del login web):
/// sube rápido y se frena cerca del 90 % sin llegar; al tener respuesta, se
/// termina de llenar.
double nivelEspera(double segundos, {double desde = 0}) {
  final base = desde.clamp(0.0, _tope);
  return base +
      (_tope - base) * (1 - math.exp(-math.max(segundos, 0) / _ritmoS));
}
