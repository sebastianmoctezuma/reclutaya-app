import 'package:flutter/material.dart';
import 'package:liquid_design/liquid_design.dart';
import 'package:reclutaya_app/nucleo/plataforma/adaptativos.dart';
import 'package:reclutaya_app/nucleo/plataforma/plataforma.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/vidrio/vidrio.dart';
import 'package:reclutaya_app/nucleo/vidrio/vidrio_nativo.dart';

class PestanaItem {
  const PestanaItem({
    required this.icono,
    required this.iconoActivo,
    required this.etiqueta,
  });

  final IconData icono;
  final IconData iconoActivo;
  final String etiqueta;
}

/// El dock: en iPhone con iOS 26, la barra de pestañas NATIVA de Apple
/// (`LiquidGlassNavigationBar`: su vidrio crece bajo el dedo, se puede
/// presionar y arrastrar entre pestañas) flotando separada de los bordes, con
/// sus esquinas redondas. En iOS anterior, una cápsula propia con pastilla que
/// se desliza. En Android, la barra de Material 3.
class BarraPestanas extends StatelessWidget {
  const BarraPestanas({
    required this.indice,
    required this.alCambiar,
    required this.items,
    this.alMantener,
    super.key,
  });

  final int indice;
  final ValueChanged<int> alCambiar;
  final List<PestanaItem> items;

  /// Dejar presionada una pestaña (p. ej. «Cuenta» abre las cuentas del teléfono). Solo
  /// en la barra propia: la de vidrio nativo de iOS 26 no la reporta a Flutter.
  final ValueChanged<int>? alMantener;

  void _tocar(int i) {
    hapticoSeleccion();
    alCambiar(i);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    if (Plataforma.esIOS && vidrioNativoDisponible && !vidrioSolido(context)) {
      return SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: LiquidGlassNavigationBar(
            currentIndex: indice,
            onTap: _tocar,
            activeColor: t.verdeProfundo,
            inactiveColor: t.tintaSuave,
            items: [
              for (final p in items)
                LiquidGlassNavItem(
                  icon: Icon(p.icono),
                  activeIcon: Icon(p.iconoActivo),
                  label: p.etiqueta,
                ),
            ],
          ),
        ),
      );
    }
    if (Plataforma.esIOS) return _Capsula(this);
    return NavigationBar(
      selectedIndex: indice,
      onDestinationSelected: _tocar,
      backgroundColor: t.tarjeta,
      indicatorColor: t.verdeBrillo,
      destinations: [
        for (final p in items)
          NavigationDestination(
            icon: Icon(p.icono),
            selectedIcon: Icon(p.iconoActivo, color: t.verdeProfundo),
            label: p.etiqueta,
          ),
      ],
    );
  }
}

class _Capsula extends StatelessWidget {
  const _Capsula(this.barra);

  final BarraPestanas barra;

  static const _alto = 62.0;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final estilo = Theme.of(context).textTheme.labelSmall!;
    final n = barra.items.length;
    final quieto = vidrioSolido(context);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: SizedBox(
          height: _alto,
          child: Vidrio.barra(
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: LayoutBuilder(
                builder: (context, c) {
                  final ancho = c.maxWidth / n;
                  return Stack(
                    children: [
                      // La pastilla que se desliza a la pestaña activa.
                      AnimatedPositioned(
                        duration: quieto
                            ? Duration.zero
                            : const Duration(milliseconds: 380),
                        curve: const Cubic(0.32, 0.72, 0, 1),
                        left: ancho * barra.indice,
                        top: 0,
                        bottom: 0,
                        width: ancho,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: t.verde.withValues(
                              alpha: t.esOscuro ? 0.28 : 0.14,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (var i = 0; i < n; i++)
                            Expanded(
                              child: Semantics(
                                button: true,
                                selected: i == barra.indice,
                                label: barra.items[i].etiqueta,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => barra._tocar(i),
                                  onLongPress: barra.alMantener == null
                                      ? null
                                      : () {
                                          hapticoSeleccion();
                                          barra.alMantener!(i);
                                        },
                                  child: _Pestana(
                                    item: barra.items[i],
                                    activa: i == barra.indice,
                                    estilo: estilo,
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
      ),
    );
  }
}

class _Pestana extends StatelessWidget {
  const _Pestana({
    required this.item,
    required this.activa,
    required this.estilo,
  });

  final PestanaItem item;
  final bool activa;
  final TextStyle estilo;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final color = activa ? t.verdeProfundo : t.tintaSuave;
    return ExcludeSemantics(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: activa ? 1.08 : 1,
            duration: const Duration(milliseconds: 220),
            child: Icon(
              activa ? item.iconoActivo : item.icono,
              color: color,
              size: 23,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.etiqueta,
            maxLines: 1,
            style: estilo.copyWith(
              color: color,
              fontSize: 10.5,
              fontWeight: activa ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
