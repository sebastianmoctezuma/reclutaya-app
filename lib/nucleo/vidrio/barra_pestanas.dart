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
    this.imagen,
  });

  final IconData icono;
  final IconData iconoActivo;
  final String etiqueta;

  /// En lugar del ícono, una imagen (el logo del negocio en «Cuenta», como la foto de
  /// perfil de Instagram). Recibe si la pestaña está activa.
  final Widget Function({required bool activa})? imagen;
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
    this.compacta = false,
    super.key,
  });

  final int indice;
  final ValueChanged<int> alCambiar;
  final List<PestanaItem> items;

  /// Dejar presionada una pestaña (p. ej. «Cuenta» abre las cuentas del teléfono). Solo
  /// en la barra propia: la de vidrio nativo de iOS 26 no la reporta a Flutter.
  final ValueChanged<int>? alMantener;

  /// Al bajar por una lista (8-oct): más chica y sin los nombres. No desaparece: se
  /// sigue pudiendo cambiar de pestaña.
  final bool compacta;

  static const _duracion = Duration(milliseconds: 260);

  /// Cuánto se encoge al compactarse.
  static const _escala = 0.82;

  void _tocar(int i) {
    hapticoSeleccion();
    alCambiar(i);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    if (Plataforma.esIOS) {
      // Se ENCOGE con una escala (8-oct): la hace la GPU y no rehace la barra en cada
      // cuadro. La nativa es una vista de iOS incrustada: cambiarle el tamaño cuadro
      // por cuadro la hacía ir a tirones. Con «Reducir movimiento», directo.
      return AnimatedScale(
        scale: compacta ? _escala : 1,
        alignment: Alignment.bottomCenter,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : _duracion,
        curve: Curves.easeOutCubic,
        child: vidrioNativoDisponible && !vidrioSolido(context)
            ? _nativa(context)
            : _Capsula(this),
      );
    }
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

extension on BarraPestanas {
  /// La barra NATIVA de iOS 26. Compacta, sin nombres: el ícono queda al centro. El
  /// alto se fija para que la vista nativa no cambie de tamaño (solo la escala).
  Widget _nativa(BuildContext context) {
    final t = context.t;
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
          height: 64,
          items: [
            for (final p in items)
              LiquidGlassNavItem(
                icon: p.imagen?.call(activa: false) ?? Icon(p.icono),
                activeIcon: p.imagen?.call(activa: true) ?? Icon(p.iconoActivo),
                label: compacta ? null : p.etiqueta,
              ),
          ],
        ),
      ),
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
                                    compacta: barra.compacta,
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
    required this.compacta,
  });

  final PestanaItem item;
  final bool activa;
  final TextStyle estilo;
  final bool compacta;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final color = activa ? t.verdeProfundo : t.tintaSuave;
    return ExcludeSemantics(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Compacta: el nombre se desvanece y el ícono baja al centro (implícitos y
          // baratos: sin reconstruir la barra en cada cuadro).
          AnimatedSlide(
            offset: compacta ? const Offset(0, 0.3) : Offset.zero,
            duration: BarraPestanas._duracion,
            curve: Curves.easeOutCubic,
            child: AnimatedScale(
              scale: activa ? 1.08 : 1,
              duration: const Duration(milliseconds: 220),
              child:
                  item.imagen?.call(activa: activa) ??
                  Icon(
                    activa ? item.iconoActivo : item.icono,
                    color: color,
                    size: 23,
                  ),
            ),
          ),
          const SizedBox(height: 2),
          AnimatedOpacity(
            opacity: compacta ? 0 : 1,
            duration: BarraPestanas._duracion,
            child: Text(
              item.etiqueta,
              maxLines: 1,
              style: estilo.copyWith(
                color: color,
                fontSize: 10.5,
                fontWeight: activa ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
