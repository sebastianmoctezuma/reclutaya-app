import 'package:flutter/material.dart';
import 'package:reclutaya_app/nucleo/plataforma/adaptativos.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';

/// La tarjeta de contenido de la casa, SÓLIDA como las agrupadas de iOS (8-oct):
/// blanca (gris oscuro en modo oscuro), un borde fino y una sombra suave. Antes era
/// de vidrio con un desenfoque por tarjeta (6-oct); sobre el fondo se veía lavada, el
/// borde blanco la confundía con el fondo y cada desenfoque costaba al desplazar una
/// lista. El vidrio se queda para lo que flota: la barra de pestañas y las hojas.
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

/// La superficie de las tarjetas, reutilizable con otra forma o un tinte.
class SuperficieVidrio extends StatelessWidget {
  const SuperficieVidrio({
    required this.forma,
    required this.child,
    this.decoracion,
    super.key,
  });

  final OutlinedBorder forma;
  final Widget child;

  /// Algo que se pinta sobre el fondo (p. ej. la mancha de color de una sucursal).
  final Decoration? decoracion;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final cuerpo = Material(
      color: t.tarjeta,
      shape: forma.copyWith(
        side: BorderSide(
          color: t.linea.withValues(alpha: t.esOscuro ? 1 : 0.75),
          width: 0.6,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: decoracion == null
          ? child
          : Ink(decoration: decoracion, child: child),
    );
    // Sombra suave por fuera: separa la tarjeta del fondo.
    return DecoratedBox(
      decoration: ShapeDecoration(shape: forma, shadows: sombraSm(t)),
      child: cuerpo,
    );
  }
}
