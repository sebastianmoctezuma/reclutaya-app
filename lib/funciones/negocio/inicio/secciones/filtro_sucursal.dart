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
      await showCupertinoModalPopup<void>(
        context: context,
        builder: (c) => CupertinoActionSheet(
          title: const Text('Ver indicadores de'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                elegido = null;
                cambio = true;
                Navigator.pop(c);
              },
              child: const Text('Todas las sucursales'),
            ),
            for (final s in sucursales)
              CupertinoActionSheetAction(
                onPressed: () {
                  elegido = s.id;
                  cambio = true;
                  Navigator.pop(c);
                },
                child: Text(s.nombre),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancelar'),
          ),
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
                    style: Theme.of(context).textTheme.labelLarge,
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
