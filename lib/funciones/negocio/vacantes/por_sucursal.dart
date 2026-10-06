import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/sucursales.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/funciones/negocio/inicio/secciones/comunes.dart';
import 'package:reclutaya_app/funciones/negocio/inicio/secciones/listas.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/ui/chip.dart';
import 'package:reclutaya_app/nucleo/ui/esqueleto.dart';
import 'package:reclutaya_app/nucleo/ui/estados.dart';

/// Las activas de una cuenta multisucursal, como en la web: cada sucursal con su
/// logo, «Principal» y sus vacantes debajo. Pura vista: sin «Agregar sucursal» ni
/// «Crear vacante». Si el servidor aún no tiene `/negocio/sucursales`, `alternativa`
/// (la lista plana de siempre) toma su lugar.
class VacantesPorSucursal extends ConsumerWidget {
  const VacantesPorSucursal({required this.alternativa, super.key});

  final Widget alternativa;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sucursalesProvider);
    if (s.hasError && !s.hasValue) {
      final e = s.error;
      if (e is SinRed || e is SesionVencida) {
        return SliverToBoxAdapter(
          child: EstadoError(
            error: e! as ErrorApi,
            alReintentar: () => ref.invalidate(sucursalesProvider),
          ),
        );
      }
      return alternativa;
    }
    final datos = s.value;
    if (datos == null) {
      return const SliverPadding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
        sliver: SliverToBoxAdapter(
          child: Esqueleto(alto: 220, radio: radioGrande),
        ),
      );
    }
    if (datos.items.isEmpty) return alternativa;
    return SliverMainAxisGroup(
      slivers: [
        if (s.error is SinRed) const SliverToBoxAdapter(child: BannerSinRed()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          sliver: SliverList.list(
            children: [for (final x in datos.items) _Sucursal(x)],
          ),
        ),
      ],
    );
  }
}

class _Sucursal extends StatelessWidget {
  const _Sucursal(this.s);

  final SucursalConVacantes s;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
          child: Row(
            children: [
              LogoSucursal(
                nombre: s.nombre,
                imagenUrl: s.imagenUrl,
                colorIdx: s.colorIdx,
                tam: 36,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            s.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.titleLarge,
                          ),
                        ),
                        if (s.principal) ...[
                          const SizedBox(width: 6),
                          const ChipRY('Principal'),
                        ],
                      ],
                    ),
                    Text(
                      s.vacantesActivas == 1
                          ? '1 vacante activa'
                          : '${s.vacantesActivas} vacantes activas',
                      style: tt.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (s.vacantes.isEmpty)
          Grupo(
            sangria: 16,
            renglones: [
              Renglon(
                hijo: Text(
                  'Sin vacantes activas.',
                  style: tt.bodyMedium!.copyWith(color: t.tintaSuave),
                ),
              ),
            ],
          )
        else
          Grupo(
            sangria: 16,
            renglones: [
              for (final v in s.vacantes)
                Renglon(
                  hijo: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.puesto,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        v.candidatos == 1
                            ? '1 candidato'
                            : '${v.candidatos} candidatos',
                        style: tt.bodySmall,
                      ),
                    ],
                  ),
                  final_: v.sinRankear > 0
                      ? ChipRY(
                          '${v.sinRankear} sin rankear',
                          tono: TonoChip.naranja,
                        )
                      : null,
                  alTocar: () =>
                      GoRouter.maybeOf(context)?.go('/vacantes/${v.slug}'),
                ),
            ],
          ),
      ],
    );
  }
}
