import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/funciones/negocio/sucursales/sucursales_vista.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/ui/esqueleto.dart';
import 'package:reclutaya_app/nucleo/ui/estados.dart';

/// La vista «Sucursales» de una cuenta multisucursal, como en la web: «Ver equipo» y
/// una tarjeta por sucursal (tocarla abre su ventana). Pura vista: sin «Crear
/// sucursal» ni «Invitar». Si el servidor aún no tiene `/negocio/sucursales`,
/// `alternativa` (la lista plana de siempre) toma su lugar.
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
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        sliver: SliverList.separated(
          itemCount: 3,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, _) => const Esqueleto(alto: 150, radio: radioGrande),
        ),
      );
    }
    if (datos.items.isEmpty) return alternativa;
    final equipo = datos.equipo;
    return SliverMainAxisGroup(
      slivers: [
        if (s.error is SinRed) const SliverToBoxAdapter(child: BannerSinRed()),
        if (equipo != null && equipo.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            sliver: SliverToBoxAdapter(child: FilaEquipo(equipo)),
          ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.separated(
            itemCount: datos.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) => TarjetaSucursal(datos.items[i]),
          ),
        ),
      ],
    );
  }
}
