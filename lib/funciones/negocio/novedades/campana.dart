import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/novedades.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/funciones/negocio/novedades/novedades_core.dart';
import 'package:reclutaya_app/funciones/negocio/novedades/pantalla_actividad.dart';
import 'package:reclutaya_app/nucleo/plataforma/adaptativos.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/vidrio/vidrio.dart';

/// La campana del Inicio: un botón redondo de vidrio con cuántas novedades llegaron
/// desde la última vez que se abrió. Al tocarla abre la Actividad y lo nuevo se da
/// por visto.
class CampanaNovedades extends ConsumerWidget {
  const CampanaNovedades({super.key});

  Future<void> _abrir(BuildContext context, WidgetRef ref, Novedades n) async {
    hapticoSeleccion();
    final antes = ref.read(vistoHastaProvider).value;
    await ref.read(vistoHastaProvider.notifier).marcar(n.hasta);
    if (!context.mounted) return;
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      await router.push<void>('/inicio/actividad', extra: antes);
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
