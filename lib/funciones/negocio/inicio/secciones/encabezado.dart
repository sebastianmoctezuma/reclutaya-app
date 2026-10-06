import 'package:flutter/material.dart';
import 'package:reclutaya_app/nucleo/plataforma/adaptativos.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/ui/logo_negocio.dart';

/// El encabezado del negocio, con el degradado verde del widget «Últimas 24 horas» del
/// panel web: logo con aro, saludo, nombre y giro · ciudad. Sin botones: es pura vista.
class EncabezadoNegocio extends StatelessWidget {
  const EncabezadoNegocio({
    required this.nombre,
    required this.saludo,
    this.meta = '',
    this.logoUrl,
    this.logoFit,
    super.key,
  });

  final String nombre;
  final String saludo;
  final String meta;
  final String? logoUrl;
  final String? logoFit;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final blanco = t.sobreVerde;
    final forma = formaTarjeta(radioGrande + 4);
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: forma,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.heroInicio, t.heroFin],
        ),
        shadows: [
          BoxShadow(
            color: t.heroFin.withValues(alpha: t.esOscuro ? 0.5 : 0.26),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: forma),
        child: Stack(
          children: [
            // El brillo de la esquina (el `radial-gradient` del widget web).
            Positioned(
              right: -60,
              top: -90,
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      blanco.withValues(alpha: 0.16),
                      blanco.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: blanco.withValues(alpha: 0.55),
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: LogoNegocio(
                        nombre: nombre,
                        url: logoUrl,
                        logoFit: logoFit,
                        tam: 56,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          saludo,
                          style: tt.bodySmall!.copyWith(
                            color: blanco.withValues(alpha: 0.82),
                          ),
                        ),
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
                              color: blanco.withValues(alpha: 0.82),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
