import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/inicio.dart';
import 'package:reclutaya_app/funciones/negocio/comun/presentacion.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/nucleo/plataforma/adaptativos.dart';
import 'package:reclutaya_app/nucleo/plataforma/plataforma.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/vidrio/vidrio.dart';

/// «Todas las sucursales ⌄»: una pastilla de vidrio que abre la hoja nativa con las
/// sucursales. Cambia los indicadores y el proceso al instante (vienen precalculados).
class FiltroSucursalPastilla extends ConsumerWidget {
  const FiltroSucursalPastilla({required this.sucursales, super.key});

  final List<SucursalInicio> sucursales;

  Future<void> _elegir(BuildContext context, WidgetRef ref) async {
    hapticoSeleccion();
    final notificador = ref.read(filtroSucursalProvider.notifier);
    final actual = ref.read(filtroSucursalProvider);
    var elegido = actual;
    var cambio = false;
    if (Plataforma.esIOS) {
      // Hoja SÓLIDA con la forma de la de iOS (8-oct): la nativa es translúcida y
      // sobre los indicadores no se leía.
      await showCupertinoModalPopup<void>(
        context: context,
        builder: (c) => _HojaFiltro(
          sucursales: sucursales,
          actual: actual,
          alElegir: (id) {
            elegido = id;
            cambio = true;
            Navigator.pop(c);
          },
        ),
      );
    } else {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (c) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Todas las sucursales'),
                trailing: actual == null ? const Icon(Icons.check) : null,
                onTap: () {
                  elegido = null;
                  cambio = true;
                  Navigator.pop(c);
                },
              ),
              for (final s in sucursales)
                ListTile(
                  leading: _Punto(s.colorIdx),
                  title: Text(s.nombre),
                  trailing: actual == s.id ? const Icon(Icons.check) : null,
                  onTap: () {
                    elegido = s.id;
                    cambio = true;
                    Navigator.pop(c);
                  },
                ),
            ],
          ),
        ),
      );
    }
    if (cambio) notificador.valor = elegido;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final id = ref.watch(filtroSucursalProvider);
    final elegida = sucursales.where((s) => s.id == id).firstOrNull;
    return Vidrio.pastilla(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => _elegir(context, ref),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (elegida != null) ...[
                  _Punto(elegida.colorIdx),
                  const SizedBox(width: 6),
                ] else ...[
                  Icon(Icons.tune_rounded, size: 16, color: t.tintaSuave),
                  const SizedBox(width: 6),
                ],
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 170),
                  child: Text(
                    elegida?.nombre ?? 'Todas las sucursales',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge!
                        .copyWith(color: t.tinta),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.expand_more_rounded, size: 18, color: t.tintaSuave),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Punto extends StatelessWidget {
  const _Punto(this.colorIdx);

  final int colorIdx;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: colorSucursal(colorIdx, oscuro: context.t.esOscuro),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// La hoja del filtro en iOS: opciones arriba y «Cancelar» aparte, como la de acciones
/// de iOS, pero sólida. La elegida lleva palomita; cada sucursal, su punto de color.
class _HojaFiltro extends StatelessWidget {
  const _HojaFiltro({
    required this.sucursales,
    required this.actual,
    required this.alElegir,
  });

  final List<SucursalInicio> sucursales;
  final String? actual;
  final ValueChanged<String?> alElegir;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final forma = formaTarjeta(16);
    Widget opcion(String? id, String nombre, {int? colorIdx}) {
      final elegida = id == actual;
      return Semantics(
        button: true,
        selected: elegida,
        child: InkWell(
          onTap: () {
            hapticoSeleccion();
            alElegir(id);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            child: Row(
              children: [
                if (colorIdx != null) ...[
                  _Punto(colorIdx),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodyLarge!.copyWith(
                      color: t.tinta,
                      fontWeight: elegida ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (elegida)
                  Icon(CupertinoIcons.checkmark_alt, size: 20, color: t.verde),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: t.tarjeta,
              shape: forma,
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.6,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                        child: Text(
                          'Ver indicadores de',
                          style: tt.labelMedium!.copyWith(color: t.tintaSuave),
                        ),
                      ),
                      Divider(height: 1, color: t.linea),
                      opcion(null, 'Todas las sucursales'),
                      for (final s in sucursales) ...[
                        Divider(height: 1, indent: 18, color: t.linea),
                        opcion(s.id, s.nombre, colorIdx: s.colorIdx),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Material(
              color: t.tarjeta,
              shape: forma,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Center(
                    child: Text(
                      'Cancelar',
                      style: tt.titleMedium!.copyWith(color: t.verdeProfundo),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
