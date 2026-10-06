import 'package:flutter/material.dart';
import 'package:reclutaya_app/nucleo/plataforma/adaptativos.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';

/// La tarjeta de contenido de la casa: superficie SÓLIDA (nunca vidrio),
/// esquinas continuas en iOS, sombra suave.
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
    final t = context.t;
    final forma = formaTarjeta(radioGrande);
    final cuerpo = Material(
      color: t.tarjeta,
      shape: forma,
      clipBehavior: Clip.antiAlias,
      child: alTocar == null
          ? Padding(padding: padding, child: child)
          : InkWell(
              onTap: alTocar,
              child: Padding(padding: padding, child: child),
            ),
    );
    return DecoratedBox(
      decoration: ShapeDecoration(shape: forma, shadows: sombraSm(t)),
      child: cuerpo,
    );
  }
}
