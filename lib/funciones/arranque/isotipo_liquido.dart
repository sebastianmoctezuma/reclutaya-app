import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';

/// El isotipo llenándose como líquido: dos capas de la misma imagen, la
/// apagada abajo y la de color recortada desde abajo hasta `nivel`, con una
/// ola en el borde. Pintado con un recorte, sin paquetes ni filtros.
class IsotipoLiquido extends StatelessWidget {
  const IsotipoLiquido({
    required this.nivel,
    required this.fase,
    this.tam = 96,
    super.key,
  });

  /// 0–1: cuánto está lleno.
  final double nivel;

  /// Radianes: avanza con el tiempo para que la ola se mueva.
  final double fase;
  final double tam;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final imagen = Image.asset(
      'assets/imagenes/isotipo.png',
      width: tam,
      height: tam,
    );
    return SizedBox(
      width: tam,
      height: tam,
      child: Stack(
        children: [
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              t.linea.withValues(alpha: 0.9),
              BlendMode.srcIn,
            ),
            child: imagen,
          ),
          ClipPath(
            clipper: _Ola(nivel: nivel.clamp(0, 1), fase: fase),
            child: imagen,
          ),
        ],
      ),
    );
  }
}

class _Ola extends CustomClipper<Path> {
  const _Ola({required this.nivel, required this.fase});

  final double nivel;
  final double fase;

  @override
  Path getClip(Size size) {
    // El líquido ocupa de abajo hacia arriba; el borde superior es una onda
    // de 5 px que se mueve con `fase`. Con 1.0 no hay onda: lleno.
    final y = size.height * (1 - nivel * 1.04);
    final amp = nivel >= 0.999 ? 0.0 : 5.0;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, y);
    const pasos = 24;
    for (var i = 0; i <= pasos; i++) {
      final x = size.width * i / pasos;
      final onda = math.sin(fase + i / pasos * 2 * math.pi) * amp;
      path.lineTo(x, y + onda);
    }
    path
      ..lineTo(size.width, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(_Ola old) => old.nivel != nivel || old.fase != fase;
}
