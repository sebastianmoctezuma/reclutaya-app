import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/novedades.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/funciones/negocio/novedades/novedades_core.dart';
import 'package:reclutaya_app/funciones/negocio/novedades/pantalla_actividad.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/ui/boton_redondo.dart';

/// La campana del Inicio: un botón redondo sólido (blanco con la campana en verde,
/// 8-oct; el vidrio pálido se perdía sobre el verde) con cuántas novedades llegaron
/// desde la última vez que se abrió. Al tocarla abre la Actividad y lo nuevo se da
/// por visto.
class CampanaNovedades extends ConsumerWidget {
  const CampanaNovedades({super.key});

  Future<void> _abrir(BuildContext context, WidgetRef ref, Novedades n) async {
    final antes = ref.read(vistoHastaProvider).value;
    await ref.read(vistoHastaProvider.notifier).marcar(n.hasta);
    if (!context.mounted) return;
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      // `go`, no `push` (8-oct): `push` de una subruta apilaba OTRO Inicio debajo; al
      // cerrar quedaba un Inicio duplicado, con flecha que no llevaba a nada.
      router.go('/inicio/actividad', extra: antes);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaActividad(vistoAntes: antes),
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        BotonRedondo(
          icono: CupertinoIcons.bell_fill,
          colorIcono: t.verdeProfundo,
          etiqueta: cuantas == 0 ? 'Novedades' : 'Novedades, $cuantas nuevas',
          alTocar: novedades == null
              ? null
              : () => _abrir(context, ref, novedades),
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
    );
  }
}
