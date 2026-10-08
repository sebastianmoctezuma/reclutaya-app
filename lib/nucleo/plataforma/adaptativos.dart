import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:reclutaya_app/nucleo/plataforma/plataforma.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/ui/boton_redondo.dart';
import 'package:reclutaya_app/nucleo/vidrio/vidrio.dart';

/// Esquinas de iPhone en iOS (la superelipse de Apple), circulares en Android.
/// Antes era `ContinuousRectangleBorder` con el radio por 2.2: no es la curva de
/// Apple y en tarjetas chicas abombaba los lados (8-oct, «se ven raras»).
OutlinedBorder formaTarjeta(double r) => Plataforma.esIOS
    ? RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(r))
    : RoundedRectangleBorder(borderRadius: BorderRadius.circular(r));

void hapticoSeleccion() => HapticFeedback.selectionClick();
void hapticoLigero() => HapticFeedback.lightImpact();

/// Página con título grande, como las apps de banca: el título vive en el contenido y
/// se va al desplazar (sin barra verde pegada arriba). Arriba solo queda una franja
/// translúcida para leer la hora y, en pantallas internas, el botón redondo de vidrio
/// para regresar. Con `alRefrescar`, deslizar para actualizar.
class PaginaConTitulo extends StatefulWidget {
  const PaginaConTitulo({
    required this.titulo,
    required this.slivers,
    this.accion,
    this.alRefrescar,
    this.subtitulo,
    this.cerrar = false,
    this.encabezado,
    super.key,
  });

  final String titulo;

  /// Lo que va bajo el título, sobre el verde (en blanco): p. ej. el estado.
  final Widget? subtitulo;
  final List<Widget> slivers;
  final Widget? accion;
  final Future<void> Function()? alRefrescar;

  /// Pantalla que sube como hoja (8-oct): en vez de la flecha a la izquierda, una cruz
  /// a la derecha.
  final bool cerrar;

  /// En lugar del título en texto (p. ej. el logo de ReclutaYa en el Inicio). El
  /// `titulo` se sigue usando para el lector de pantalla.
  final Widget? encabezado;

  @override
  State<PaginaConTitulo> createState() => _PaginaConTituloState();
}

class _PaginaConTituloState extends State<PaginaConTitulo> {
  /// Lo desplazado: lo escucha SOLO el pintor del verde (repinta, no reconstruye).
  final _desplazamiento = ValueNotifier<double>(0);

  /// ¿Lo blanco ya pasó bajo la hora? Cambia pocas veces y nunca en medio de un cuadro.
  final _cubierto = ValueNotifier<bool>(false);

  /// A partir de aquí el contenido blanco ya pasó bajo la hora: franja y texto oscuro.
  static const _umbral = 180.0;

  @override
  void dispose() {
    _desplazamiento.dispose();
    _cubierto.dispose();
    super.dispose();
  }

  bool _alDesplazar(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    // Los avisos de desplazamiento también llegan DURANTE el acomodo de la pantalla:
    // aquí nada reconstruye widgets (eso trababa la app y el dock).
    _desplazamiento.value = n.metrics.pixels;
    final cubierto = n.metrics.pixels > _umbral;
    if (cubierto != _cubierto.value) {
      if (SchedulerBinding.instance.schedulerPhase ==
          SchedulerPhase.persistentCallbacks) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) _cubierto.value = cubierto;
        });
      } else {
        _cubierto.value = cubierto;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final arriba = MediaQuery.paddingOf(context).top;
    final puedeVolver = Navigator.of(context).canPop();
    final cuerpo = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        if (widget.alRefrescar != null)
          CupertinoSliverRefreshControl(onRefresh: widget.alRefrescar),
        // Sin título (vacío), solo el espacio de arriba: la pantalla se presenta sola.
        if (widget.titulo.isEmpty)
          SliverPadding(
            padding: EdgeInsets.only(top: arriba + (puedeVolver ? 58 : 10)),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              20,
              arriba + (puedeVolver ? 58 : 6),
              20,
              12,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: widget.encabezado == null
                            ? Text(
                                widget.titulo,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium!
                                    .copyWith(color: t.sobreVerde),
                              )
                            : Semantics(
                                header: true,
                                label: widget.titulo,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: ExcludeSemantics(
                                    child: widget.encabezado,
                                  ),
                                ),
                              ),
                      ),
                      ?widget.accion,
                    ],
                  ),
                  if (widget.subtitulo != null) ...[
                    const SizedBox(height: 6),
                    widget.subtitulo!,
                  ],
                ],
              ),
            ),
          ),
        ...widget.slivers,
        // Con `extendBody`, el padding inferior incluye la barra de pestañas.
        SliverPadding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom + 24,
          ),
        ),
      ],
    );
    return FondoMarca(
      desplazamiento: _desplazamiento,
      child: Stack(
        children: [
          Positioned.fill(
            child: NotificationListener<ScrollNotification>(
              onNotification: _alDesplazar,
              child: cuerpo,
            ),
          ),
          // La franja de la hora: aparece cuando lo blanco ya pasó por debajo.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: arriba,
            child: ValueListenableBuilder<bool>(
              valueListenable: _cubierto,
              builder: (context, cubierto, _) {
                return AnnotatedRegion<SystemUiOverlayStyle>(
                  value: cubierto
                      ? SystemUiOverlayStyle.dark
                      : SystemUiOverlayStyle.light,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: cubierto ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: ColoredBox(
                            color: t.papel.withValues(alpha: 0.78),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (puedeVolver && !widget.cerrar)
            Positioned(top: arriba + 8, left: 14, child: const _Regresar()),
          if (puedeVolver && widget.cerrar)
            Positioned(
              top: arriba + 8,
              right: 14,
              child: BotonRedondo(
                icono: Plataforma.esIOS
                    ? CupertinoIcons.xmark
                    : Icons.close_rounded,
                etiqueta: 'Cerrar',
                alTocar: () => Navigator.of(context).maybePop(),
              ),
            ),
        ],
      ),
    );
  }
}

/// Regresar: un botón redondo de vidrio que flota arriba a la izquierda (iOS 26).
class _Regresar extends StatelessWidget {
  const _Regresar();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Semantics(
      button: true,
      label: 'Regresar',
      child: Vidrio.pastilla(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              hapticoSeleccion();
              Navigator.of(context).maybePop();
            },
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Plataforma.esIOS
                    ? CupertinoIcons.chevron_back
                    : Icons.arrow_back_rounded,
                size: 22,
                color: t.tinta,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lo alto del verde, en puntos desde arriba de la pantalla: sólido detrás del
/// encabezado y luego se funde, despacio, con el fondo.
const altoVerde = 360.0;

/// El verde brillante de arriba.
Color colorVerdeArriba(Tokens t) => Color.lerp(t.heroInicio, t.verde, 0.25)!;

/// El fondo de la app: no es blanco puro, lleva un toque del verde de la marca para
/// que las tarjetas blancas se distingan.
Color colorFondo(Tokens t) => Color.alphaBlend(
  t.verde.withValues(alpha: t.esOscuro ? 0.08 : 0.07),
  t.papel,
);

/// El fondo de la app, como las apps de banca: un verde SOLO arriba que se funde con
/// el fondo y se va con el contenido al desplazar (no se queda fijo). Se pinta con un
/// pintor que escucha el desplazamiento: mover el verde no reconstruye la pantalla.
class FondoMarca extends StatelessWidget {
  const FondoMarca({required this.child, this.desplazamiento, super.key});

  final Widget child;

  /// Cuánto se ha desplazado el contenido: el verde sube con él.
  final ValueListenable<double>? desplazamiento;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final fondo = colorFondo(t);
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _PintorVerde(
                arriba: MediaQuery.paddingOf(context).top,
                brillante: colorVerdeArriba(t),
                verde: t.heroInicio,
                fondo: fondo,
                desplazamiento: desplazamiento,
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _PintorVerde extends CustomPainter {
  _PintorVerde({
    required this.arriba,
    required this.brillante,
    required this.verde,
    required this.fondo,
    this.desplazamiento,
  }) : super(repaint: desplazamiento);

  final double arriba;
  final Color brillante;
  final Color verde;
  final Color fondo;
  final ValueListenable<double>? desplazamiento;

  @override
  void paint(Canvas canvas, Size size) {
    final alto = arriba + altoVerde;
    final y = (desplazamiento?.value ?? 0).clamp(-size.height, alto);
    final rect = Rect.fromLTWH(0, 0, size.width, alto);
    // Sólido detrás del título y el encabezado; luego se funde en varios pasos
    // suaves (sin el corte de un degradado de dos colores).
    final verdeQueSeFunde = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          brillante,
          verde,
          Color.lerp(verde, fondo, 0.3)!,
          Color.lerp(verde, fondo, 0.62)!,
          Color.lerp(verde, fondo, 0.87)!,
          fondo,
        ],
        stops: const [0, 0.42, 0.6, 0.75, 0.89, 1],
      ).createShader(rect);
    canvas
      ..drawRect(Offset.zero & size, Paint()..color = fondo)
      ..save()
      ..translate(0, -y)
      // Al estirar hacia abajo (rebote), lo de arriba sigue verde: sin huecos.
      ..drawRect(
        Rect.fromLTWH(0, -size.height, size.width, size.height),
        Paint()..color = brillante,
      )
      ..drawRect(rect, verdeQueSeFunde)
      ..restore();
  }

  @override
  bool shouldRepaint(_PintorVerde old) =>
      old.arriba != arriba ||
      old.brillante != brillante ||
      old.verde != verde ||
      old.fondo != fondo ||
      old.desplazamiento != desplazamiento;
}

/// Confirmación nativa. Devuelve true si aceptó.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  required String aceptar,
  bool destructivo = false,
}) async {
  if (Plataforma.esIOS) {
    final r = await showCupertinoDialog<bool>(
      context: context,
      builder: (c) => CupertinoAlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: destructivo,
            onPressed: () => Navigator.pop(c, true),
            child: Text(aceptar),
          ),
        ],
      ),
    );
    return r ?? false;
  }
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(c, true),
          child: Text(aceptar),
        ),
      ],
    ),
  );
  return r ?? false;
}
