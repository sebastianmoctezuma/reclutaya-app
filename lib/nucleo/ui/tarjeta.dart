import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:reclutaya_app/nucleo/plataforma/adaptativos.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/vidrio/vidrio.dart';

/// La tarjeta de contenido de la casa, de vidrio (decisión del dueño, 6-oct): el
/// fondo se desenfoca detrás, un velo translúcido y un borde de luz arriba, como las
/// tarjetas de las apps de banca. Es vidrio dibujado por Flutter (un desenfoque por
/// tarjeta), no el nativo: el nativo en cada tarjeta de una lista pesa al desplazar.
/// Con «Reducir movimiento» o «Aumentar contraste», sólida.
class Tarjeta extends StatelessWidget {
  const Tarjeta({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.alTocar,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final forma = formaTarjeta(radioGrande);
    return SuperficieVidrio(
      forma: forma,
      child: alTocar == null
          ? Padding(padding: padding, child: child)
          : InkWell(
              onTap: alTocar,
              child: Padding(padding: padding, child: child),
            ),
    );
  }
}

/// La superficie de vidrio de las tarjetas, reutilizable con otra forma o un tinte.
class SuperficieVidrio extends StatelessWidget {
  const SuperficieVidrio({
    required this.forma,
    required this.child,
    this.decoracion,
    super.key,
  });

  final OutlinedBorder forma;
  final Widget child;

  /// Algo que se pinta sobre el velo (p. ej. la mancha de color de una sucursal).
  final Decoration? decoracion;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final solido = vidrioSolido(context);
    final velo = solido
        ? t.tarjeta
        // Casi blanca (como las tarjetas agrupadas de iOS): se distingue del fondo
        // con tinte verde y aun así deja ver un poco lo que pasa detrás.
        : t.tarjeta.withValues(alpha: t.esOscuro ? 0.72 : 0.88);
    final cuerpo = Material(
      color: velo,
      shape: forma.copyWith(
        side: BorderSide(
          color: t.sobreVerde.withValues(alpha: t.esOscuro ? 0.12 : 0.9),
          width: 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: decoracion == null
          ? child
          : Ink(decoration: decoracion, child: child),
    );
    final conVidrio = solido
        ? cuerpo
        : ClipPath(
            clipper: ShapeBorderClipper(shape: forma),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: cuerpo,
            ),
          );
    // Sombra suave por fuera del recorte: separa la tarjeta del fondo.
    return DecoratedBox(
      decoration: ShapeDecoration(shape: forma, shadows: sombraSm(t)),
      child: conVidrio,
    );
  }
}
