import 'package:flutter/material.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';

/// Etiqueta arriba, cifra grande en Poppins, contexto abajo (la banda de
/// cifras del panel interno).
class Cifra extends StatelessWidget {
  const Cifra({
    required this.valor,
    required this.etiqueta,
    this.sub,
    this.delta,
    this.unidad,
    this.principal = false,
    super.key,
  });

  final String valor;
  final String etiqueta;
  final String? sub;
  final Widget? delta;
  final String? unidad;
  final bool principal;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                etiqueta,
                style: tt.labelMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ?delta,
          ],
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            text: valor,
            style: tt.headlineMedium!.copyWith(
              fontSize: 30,
              color: principal ? t.verdeProfundo : t.tinta,
            ),
            children: [
              if (unidad != null)
                TextSpan(
                  text: ' $unidad',
                  style: tt.titleMedium!.copyWith(color: t.tintaTenue),
                ),
            ],
          ),
        ),
        if (sub != null) ...[
          const SizedBox(height: 4),
          Text(
            sub!,
            style: tt.labelSmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
