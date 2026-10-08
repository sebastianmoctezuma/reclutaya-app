import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reclutaya_app/funciones/cuentas/selector_cuentas.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/funciones/negocio/inicio/inicio_core.dart';
import 'package:reclutaya_app/nucleo/plataforma/plataforma.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/ui/logo_negocio.dart';
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
  /// Al bajar, la barra se COMPACTA (más chica, sin nombres) y vuelve al subir
  /// (8-oct; antes se escondía): tapa menos y se sigue pudiendo cambiar de pestaña.
  bool _barraVisible = true;

  /// Se decide en CADA movimiento (8-oct). Antes se escuchaba solo el cambio de
  /// dirección: estando hasta arriba y bajando, esa notificación llegaba con la
  /// posición aún en 0, decidía «no compactar» y no volvía a preguntar.
  bool _alDesplazar(ScrollUpdateNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    final delta = n.scrollDelta ?? 0;
    final arriba = n.metrics.pixels <= n.metrics.minScrollExtent + 24;
    final bool visible;
    if (arriba || delta < -2) {
      visible = true;
    } else if (delta > 2) {
      visible = false;
    } else {
      return false;
    }
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
    final yo = ref.watch(yoProvider).value;
    final multi = yo?.variasSucursales ?? false;
    final empresa = yo?.empresa;
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
        // El logo del negocio, como la foto de perfil en Instagram (8-oct): con varias
        // cuentas en el teléfono se sabe de un vistazo en cuál se está.
        imagen: empresa == null
            ? null
            : ({required activa}) => _LogoPestana(
                nombre: empresa.nombre,
                url: empresa.logoUrl,
                logoFit: empresa.logoFit,
                activa: activa,
              ),
      ),
    ];
    return Scaffold(
      extendBody: true,
      body: NotificationListener<ScrollUpdateNotification>(
        onNotification: _alDesplazar,
        child: shell,
      ),
      bottomNavigationBar: BarraPestanas(
        // Con VoiceOver no se compacta: sin nombres, el lector no sabría qué es cada una.
        compacta: !_barraVisible && !MediaQuery.accessibleNavigationOf(context),
        indice: shell.currentIndex,
        items: items,
        // Dejar presionada «Cuenta»: las cuentas del teléfono (como Instagram).
        alMantener: (i) {
          if (i == items.length - 1) {
            unawaited(mostrarSelectorCuentas(context));
          }
        },
        alCambiar: (i) {
          setState(() => _barraVisible = true);
          shell.goBranch(i, initialLocation: i == shell.currentIndex);
        },
      ),
    );
  }
}

/// El logo del negocio en la pestaña «Cuenta»: redondo, con un aro verde cuando la
/// pestaña está activa (como la foto de perfil de Instagram).
class _LogoPestana extends StatelessWidget {
  const _LogoPestana({
    required this.nombre,
    required this.url,
    required this.logoFit,
    required this.activa,
  });

  final String nombre;
  final String? url;
  final String? logoFit;
  final bool activa;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      width: 27,
      height: 27,
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: activa ? t.verdeProfundo : t.linea,
          width: activa ? 2 : 1,
        ),
      ),
      child: LogoNegocio(nombre: nombre, url: url, logoFit: logoFit, tam: 22),
    );
  }
}
