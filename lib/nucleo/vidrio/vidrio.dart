import 'package:flutter/material.dart';
import 'package:reclutaya_app/nucleo/plataforma/plataforma.dart';
import 'package:reclutaya_app/nucleo/vidrio/vidrio_nativo.dart';
import 'package:reclutaya_app/nucleo/vidrio/vidrio_propio.dart';

enum VidrioVariante { barra, pastilla, hoja }

/// Sistema «Reducir movimiento» o «Aumentar contraste»: superficies sólidas.
/// (Flutter no expone «Reducir transparencia» por separado; se cubre con estas dos.)
bool vidrioSolido(BuildContext context) {
  final mq = MediaQuery.maybeOf(context);
  return mq != null && (mq.disableAnimations || mq.highContrast);
}

/// El vidrio de la casa. La app NUNCA llama a liquid_design directo: aquí se decide
/// nativo (iOS 26+), propio (Android, iOS viejo) o sólido (accesibilidad).
/// Regla: solo en lo que flota. Nunca en filas de lista ni tarjetas de contenido.
class Vidrio extends StatelessWidget {
  const Vidrio.barra({required this.child, super.key})
    : variante = VidrioVariante.barra;
  const Vidrio.pastilla({required this.child, super.key})
    : variante = VidrioVariante.pastilla;
  const Vidrio.hoja({required this.child, super.key})
    : variante = VidrioVariante.hoja;

  final Widget child;
  final VidrioVariante variante;

  @override
  Widget build(BuildContext context) {
    if (vidrioSolido(context)) {
      return VidrioPropio(variante: variante, solido: true, child: child);
    }
    if (Plataforma.esIOS && vidrioNativoDisponible) {
      return VidrioNativo(variante: variante, child: child);
    }
    return VidrioPropio(variante: variante, child: child);
  }
}
