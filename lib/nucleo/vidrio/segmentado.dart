import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:reclutaya_app/nucleo/plataforma/adaptativos.dart';
import 'package:reclutaya_app/nucleo/plataforma/plataforma.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/vidrio/vidrio.dart';

/// Activas | Cerradas. En iOS, el segmentado deslizante de Cupertino dentro de
/// una pastilla de vidrio; en Android, SegmentedButton de Material 3.
class Segmentado<T extends Object> extends StatelessWidget {
  const Segmentado({
    required this.opciones,
    required this.valor,
    required this.alCambiar,
    super.key,
  });

  final Map<T, String> opciones;
  final T valor;
  final ValueChanged<T> alCambiar;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final estilo = Theme.of(context).textTheme.labelLarge!;
    if (Plataforma.esIOS) {
      return Vidrio.pastilla(
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: CupertinoSlidingSegmentedControl<T>(
            groupValue: valor,
            thumbColor: t.verde,
            backgroundColor: Colors.transparent,
            onValueChanged: (v) {
              if (v == null) return;
              hapticoSeleccion();
              alCambiar(v);
            },
            children: {
              for (final e in opciones.entries)
                e.key: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  child: Text(
                    e.value,
                    style: estilo.copyWith(
                      color: e.key == valor ? t.tarjeta : t.tinta,
                    ),
                  ),
                ),
            },
          ),
        ),
      );
    }
    return SegmentedButton<T>(
      segments: [
        for (final e in opciones.entries)
          ButtonSegment(value: e.key, label: Text(e.value)),
      ],
      selected: {valor},
      showSelectedIcon: false,
      onSelectionChanged: (s) {
        hapticoSeleccion();
        alCambiar(s.first);
      },
    );
  }
}
