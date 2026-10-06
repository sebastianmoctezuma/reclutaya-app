import 'package:flutter/material.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';

/// Las iniciales llegan del servidor (nombre + apellido, regla de la casa).
class AvatarIniciales extends StatelessWidget {
  const AvatarIniciales(this.iniciales, {this.tam = 40, super.key});

  final String iniciales;
  final double tam;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      width: tam,
      height: tam,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: t.verdeBrillo, shape: BoxShape.circle),
      child: Text(
        iniciales,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: tam * 0.38,
          color: t.verdeProfundo,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
