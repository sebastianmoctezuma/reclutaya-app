import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/novedades.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/funciones/negocio/novedades/novedades_core.dart';
import 'package:reclutaya_app/nucleo/plataforma/adaptativos.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/ui/tarjeta.dart';
import 'package:reclutaya_app/nucleo/ui/tesela.dart';
import 'package:reclutaya_app/nucleo/vidrio/hoja.dart';
import 'package:reclutaya_app/nucleo/vidrio/vidrio.dart';

/// La campana del Inicio: un botón redondo de vidrio con cuántas novedades llegaron
/// desde la última vez que se abrió. Al tocarla, la hoja con todo lo nuevo; al
/// abrirla, lo nuevo se da por visto.
class CampanaNovedades extends ConsumerWidget {
  const CampanaNovedades({super.key});

  Future<void> _abrir(BuildContext context, WidgetRef ref, Novedades n) async {
    hapticoSeleccion();
    final visto = ref.read(vistoHastaProvider).value;
    final nuevas = nuevasDesde(n.items, visto).toSet();
    await ref.read(vistoHastaProvider.notifier).marcar(n.hasta);
    if (!context.mounted) return;
    unawaited(
      mostrarHojaVidrio(
        context,
        builder: (_) => _HojaNovedades(items: n.items, nuevas: nuevas),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final novedades = ref.watch(novedadesProvider).value;
    final visto = ref.watch(vistoHastaProvider);
    final cuantas = novedades == null || visto.isLoading
        ? 0
        : nuevasDesde(novedades.items, visto.value).length;
    return Semantics(
      button: true,
      label: cuantas == 0 ? 'Novedades' : 'Novedades, $cuantas nuevas',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Vidrio.pastilla(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: novedades == null
                    ? null
                    : () => _abrir(context, ref, novedades),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    CupertinoIcons.bell_fill,
                    size: 20,
                    color: t.sobreVerde,
                  ),
                ),
              ),
            ),
          ),
          if (cuantas > 0)
            Positioned(
              right: -2,
              top: -2,
              child: ExcludeSemantics(
                child: Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  height: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: t.naranja,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: t.sobreVerde, width: 1.5),
                  ),
                  child: Text(
                    cuantas > 99 ? '99+' : '$cuantas',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: t.sobreVerde,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HojaNovedades extends StatelessWidget {
  const _HojaNovedades({required this.items, required this.nuevas});

  final List<Novedad> items;
  final Set<Novedad> nuevas;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final recientes = [
      for (final n in items)
        if (nuevas.contains(n)) n,
    ];
    final antes = [
      for (final n in items)
        if (!nuevas.contains(n)) n,
    ];
    Widget seccion(String titulo, List<Novedad> lista) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
          child: Text(
            titulo.toUpperCase(),
            style: tt.labelSmall!.copyWith(letterSpacing: 0.6),
          ),
        ),
        Tarjeta(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (final (i, n) in lista.indexed) ...[
                if (i > 0) Divider(height: 1, indent: 58, color: t.linea),
                _Renglon(n),
              ],
            ],
          ),
        ),
      ],
    );
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      children: [
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            width: 38,
            height: 5,
            decoration: BoxDecoration(
              color: t.tinta.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 0),
          child: Text('Novedades', style: tt.headlineSmall),
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Text(
              'Sin novedades en los últimos 7 días.',
              textAlign: TextAlign.center,
              style: tt.bodyMedium!.copyWith(color: t.tintaSuave),
            ),
          ),
        if (recientes.isNotEmpty) seccion('Nuevas', recientes),
        if (antes.isNotEmpty) seccion('Esta semana', antes),
      ],
    );
  }
}

class _Renglon extends StatelessWidget {
  const _Renglon(this.n);

  final Novedad n;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final (icono, color) = switch (n.tipo) {
      'video' => (Icons.videocam_rounded, t.verde),
      'documento' => (Icons.description_rounded, t.verdeProfundo),
      'test' => (Icons.donut_large_rounded, t.naranja),
      _ => (Icons.person_add_alt_1_rounded, t.azul),
    };
    return InkWell(
      onTap: () {
        final router = GoRouter.maybeOf(context);
        Navigator.pop(context);
        router?.go('/vacantes/${n.slug}/ranking/${n.postulacionId}');
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 11, 14, 11),
        child: Row(
          children: [
            Tesela(icono: icono, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${n.candidato} ${n.accion}', style: tt.labelLarge),
                  const SizedBox(height: 2),
                  Text(
                    [
                      n.puesto,
                      ?n.sucursal,
                      haceCuanto(n.at, DateTime.now()),
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right, size: 15, color: t.tintaTenue),
          ],
        ),
      ),
    );
  }
}
