import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/vidrio/vidrio.dart';

/// El vidrio dibujado por Flutter (la receta del dock cápsula de la web):
/// desenfoque del fondo, tinte del papel y borde especular. Es el respaldo en
/// Android y en iOS anterior a 26; con `solido`, sin desenfoque.
class VidrioPropio extends StatelessWidget {
  const VidrioPropio({
    required this.variante,
    required this.child,
    this.solido = false,
    super.key,
  });

  final VidrioVariante variante;
  final Widget child;
  final bool solido;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final r = switch (variante) {
      VidrioVariante.barra || VidrioVariante.pastilla => 999.0,
      VidrioVariante.hoja => radioGrande,
    };
    final decor = BoxDecoration(
      borderRadius: BorderRadius.circular(r),
      color: solido
          ? t.tarjeta
          : t.tarjeta.withValues(alpha: t.esOscuro ? 0.62 : 0.68),
      border: Border.all(
        color: Colors.white.withValues(alpha: t.esOscuro ? 0.08 : 0.42),
      ),
      boxShadow: sombraMd(t),
    );
    final cuerpo = DecoratedBox(decoration: decor, child: child);
    if (solido) {
      return ClipRRect(borderRadius: BorderRadius.circular(r), child: cuerpo);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: cuerpo,
      ),
    );
  }
}
