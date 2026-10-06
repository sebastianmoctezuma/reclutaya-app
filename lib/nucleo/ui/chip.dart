import 'package:flutter/material.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';

enum TonoChip { neutro, verde, naranja, azul, rojo }

/// El chip del panel: punto de color + texto corto en píldora.
class ChipRY extends StatelessWidget {
  const ChipRY(
    this.texto, {
    this.tono = TonoChip.neutro,
    this.icono,
    super.key,
  });

  final String texto;
  final TonoChip tono;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final (tinta, fondo) = switch (tono) {
      TonoChip.neutro => (t.tintaSuave, t.linea.withValues(alpha: 0.6)),
      TonoChip.verde => (t.verdeProfundo, t.verdeBrillo),
      TonoChip.naranja => (t.naranjaProfundo, t.naranjaBrillo),
      TonoChip.azul => (t.azul, t.azulBrillo),
      TonoChip.rojo => (t.rojo, t.rojoBrillo),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 12, color: tinta),
            const SizedBox(width: 4),
          ] else ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: tinta, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall!
                  .copyWith(color: tinta, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
