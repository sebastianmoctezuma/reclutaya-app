import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';

/// Transición de ZOOM como la de iOS 18 (8-oct): la pantalla nace del botón que la
/// abrió —crece desde su esquina, con las esquinas redondeadas— y al cerrar se encoge de
/// vuelta hacia él, con lo de abajo siempre a la vista (sin pantallazo). Solo escala,
/// opacidad y recorte: baratos para la GPU. Con «Reducir movimiento», un desvanecido.
CustomTransitionPage<void> paginaZoom({
  required Widget child,
  required Alignment origen,
  LocalKey? key,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    // Lo de abajo se queda pintado mientras crece o se encoge.
    opaque: false,
    barrierColor: veloTransicion,
    transitionDuration: const Duration(milliseconds: 440),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    transitionsBuilder: (context, animacion, _, hijo) {
      if (MediaQuery.disableAnimationsOf(context)) {
        return FadeTransition(opacity: animacion, child: hijo);
      }
      // Al abrir, frena suave como resorte; al cerrar, acelera hacia el botón.
      final curva = CurvedAnimation(
        parent: animacion,
        curve: Curves.easeOutQuint,
        reverseCurve: Curves.easeInCubic,
      );
      // Aparece al principio del zoom y se va al final del cierre.
      final opacidad = CurvedAnimation(
        parent: animacion,
        curve: const Interval(0, 0.32, curve: Curves.easeOut),
      );
      return FadeTransition(
        opacity: opacidad,
        child: AnimatedBuilder(
          animation: curva,
          child: hijo,
          builder: (context, hijo) {
            final k = curva.value;
            return Transform.scale(
              scale: lerpDouble(0.14, 1, k),
              alignment: origen,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(lerpDouble(56, 0, k)!),
                child: hijo,
              ),
            );
          },
        ),
      );
    },
  );
}
