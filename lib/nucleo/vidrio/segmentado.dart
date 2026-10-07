import 'package:flutter/material.dart';
import 'package:reclutaya_app/nucleo/plataforma/adaptativos.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/vidrio/vidrio.dart';

/// El selector de segmentos de la casa: una cápsula de vidrio con una pastilla que se
/// desliza a la opción elegida (la misma forma del dock, sin esquinas cuadradas).
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
    final claves = opciones.keys.toList();
    final indice = claves.indexOf(valor).clamp(0, claves.length - 1);
    final alto = MediaQuery.textScalerOf(context).scale(38);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Vidrio.pastilla(
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: SizedBox(
            height: alto,
            child: LayoutBuilder(
              builder: (context, c) {
                final ancho = c.maxWidth / claves.length;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      left: ancho * indice,
                      top: 0,
                      bottom: 0,
                      width: ancho,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: t.sobreVerde,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: sombraSm(t),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (final (i, k) in claves.indexed)
                          Expanded(
                            child: Semantics(
                              button: true,
                              selected: i == indice,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  if (k == valor) return;
                                  hapticoSeleccion();
                                  alCambiar(k);
                                },
                                child: Center(
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 200),
                                    style: estilo.copyWith(
                                      color: i == indice
                                          ? t.verdeProfundo
                                          : t.sobreVerde,
                                    ),
                                    child: Text(
                                      opciones[k]!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
