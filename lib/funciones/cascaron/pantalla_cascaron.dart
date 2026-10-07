import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/funciones/negocio/inicio/inicio_core.dart';
import 'package:reclutaya_app/nucleo/plataforma/plataforma.dart';
import 'package:reclutaya_app/nucleo/vidrio/barra_pestanas.dart';

/// El cascarón de las tres pestañas: Inicio · Vacantes (o «Sucursales» si la cuenta
/// tiene varias, como en la web) · Cuenta. El cuerpo se
/// extiende bajo la barra (que flota, de vidrio en iOS).
class PantallaCascaron extends ConsumerStatefulWidget {
  const PantallaCascaron({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<PantallaCascaron> createState() => _PantallaCascaronState();
}

class _PantallaCascaronState extends ConsumerState<PantallaCascaron> {
  /// La barra se esconde al bajar y vuelve al subir (como en iOS 26): no tapa lo que
  /// el dueño está leyendo.
  bool _barraVisible = true;

  bool _alDesplazar(UserScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    final visible = switch (n.direction) {
      ScrollDirection.reverse => n.metrics.pixels <= n.metrics.minScrollExtent,
      ScrollDirection.forward => true,
      ScrollDirection.idle => _barraVisible,
    };
    if (visible != _barraVisible) {
      // Puede llegar durante el acomodo de la pantalla: se aplica al terminar el cuadro.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && visible != _barraVisible) {
          setState(() => _barraVisible = visible);
        }
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final shell = widget.shell;
    final ios = Plataforma.esIOS;
    final multi = ref.watch(yoProvider).value?.variasSucursales ?? false;
    final items = [
      PestanaItem(
        icono: ios ? CupertinoIcons.house : Icons.home_outlined,
        iconoActivo: ios ? CupertinoIcons.house_fill : Icons.home_rounded,
        etiqueta: 'Inicio',
      ),
      PestanaItem(
        icono: multi
            ? (ios ? CupertinoIcons.building_2_fill : Icons.storefront_outlined)
            : (ios ? CupertinoIcons.briefcase : Icons.work_outline_rounded),
        iconoActivo: multi
            ? (ios ? CupertinoIcons.building_2_fill : Icons.storefront_rounded)
            : (ios ? CupertinoIcons.briefcase_fill : Icons.work_rounded),
        etiqueta: nombrePestanaVacantes(variasSucursales: multi),
      ),
      PestanaItem(
        icono: ios ? CupertinoIcons.person : Icons.person_outline_rounded,
        iconoActivo: ios ? CupertinoIcons.person_fill : Icons.person_rounded,
        etiqueta: 'Cuenta',
      ),
    ];
    return Scaffold(
      extendBody: true,
      body: NotificationListener<UserScrollNotification>(
        onNotification: _alDesplazar,
        child: shell,
      ),
      bottomNavigationBar: AnimatedSlide(
        offset: _barraVisible ? Offset.zero : const Offset(0, 1.6),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        child: BarraPestanas(
          indice: shell.currentIndex,
          items: items,
          alCambiar: (i) {
            setState(() => _barraVisible = true);
            shell.goBranch(i, initialLocation: i == shell.currentIndex);
          },
        ),
      ),
    );
  }
}
