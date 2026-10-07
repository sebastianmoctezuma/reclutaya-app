import 'package:flutter/material.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';

/// El cuadro de ícono de la casa, como los de Ajustes de iOS: fondo de color SÓLIDO
/// con un brillo sutil arriba y el ícono en blanco. Un solo lugar para todos.
class Tesela extends StatelessWidget {
  const Tesela({
    required this.icono,
    required this.color,
    this.tam = 30,
    super.key,
  });

  final IconData icono;
  final Color color;
  final double tam;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      width: tam,
      height: tam,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tam * 0.28),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.alphaBlend(t.sobreVerde.withValues(alpha: 0.16), color),
            color,
          ],
        ),
      ),
      child: Icon(icono, size: tam * 0.56, color: t.sobreVerde),
    );
  }
}
