import 'package:flutter/material.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/ui/logo_negocio.dart';

/// El encabezado del negocio, directo sobre el verde del fondo (como el saldo en las
/// apps de banca): logo con aro, nombre y giro · ciudad, en blanco. Sin botones.
class EncabezadoNegocio extends StatelessWidget {
  const EncabezadoNegocio({
    required this.nombre,
    this.meta = '',
    this.logoUrl,
    this.logoFit,
    super.key,
  });

  final String nombre;
  final String meta;
  final String? logoUrl;
  final String? logoFit;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final blanco = t.sobreVerde;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: blanco.withValues(alpha: 0.7),
                width: 2,
              ),
              boxShadow: sombraMd(t),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: LogoNegocio(
                nombre: nombre,
                url: logoUrl,
                logoFit: logoFit,
                tam: 60,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tt.headlineSmall!.copyWith(color: blanco),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall!.copyWith(
                      color: blanco.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
