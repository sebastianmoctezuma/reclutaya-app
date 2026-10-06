import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:reclutaya_app/nucleo/plataforma/plataforma.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/ui/tarjeta.dart';

/// Piezas comunes de las secciones del Inicio, al estilo de las listas agrupadas de
/// iOS (Ajustes, Salud): título de sección grande, tarjeta con renglones separados por
/// una línea fina que no llega al borde izquierdo, ícono en un cuadro de color.

const ladosInicio = EdgeInsets.symmetric(horizontal: 16);

class TituloSeccion extends StatelessWidget {
  const TituloSeccion(this.texto, {this.extra, super.key});

  final String texto;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 26, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(texto, style: Theme.of(context).textTheme.titleLarge),
          ),
          ?extra,
        ],
      ),
    );
  }
}

/// Una sección completa: título + contenido, como un sliver.
class SliverSeccion extends StatelessWidget {
  const SliverSeccion({
    required this.titulo,
    required this.hijo,
    this.extra,
    super.key,
  });

  final String titulo;
  final Widget hijo;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: ladosInicio,
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TituloSeccion(titulo, extra: extra),
            hijo,
          ],
        ),
      ),
    );
  }
}

/// La tarjeta agrupada: renglones con separador fino a partir de `sangria`.
class Grupo extends StatelessWidget {
  const Grupo({required this.renglones, this.sangria = 58, super.key});

  final List<Widget> renglones;
  final double sangria;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Tarjeta(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (final (i, r) in renglones.indexed) ...[
            if (i > 0) Divider(height: 1, indent: sangria, color: t.linea),
            r,
          ],
        ],
      ),
    );
  }
}

/// Un renglón agrupado: ícono, contenido y, si se toca, el chevrón de iOS.
class Renglon extends StatelessWidget {
  const Renglon({
    required this.hijo,
    this.inicio,
    this.final_,
    this.alTocar,
    super.key,
  });

  final Widget? inicio;
  final Widget hijo;
  final Widget? final_;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final cuerpo = Padding(
      padding: const EdgeInsets.fromLTRB(16, 11, 14, 11),
      child: Row(
        children: [
          if (inicio != null) ...[inicio!, const SizedBox(width: 12)],
          Expanded(child: hijo),
          if (final_ != null) ...[const SizedBox(width: 8), final_!],
          if (alTocar != null && Plataforma.esIOS) ...[
            const SizedBox(width: 6),
            Icon(CupertinoIcons.chevron_right, size: 15, color: t.tintaTenue),
          ],
        ],
      ),
    );
    if (alTocar == null) return cuerpo;
    return InkWell(onTap: alTocar, child: cuerpo);
  }
}

/// El cuadro de color con un ícono (como los íconos de Ajustes de iOS).
class Tesela extends StatelessWidget {
  const Tesela({
    required this.icono,
    required this.color,
    required this.fondo,
    this.tam = 30,
    super.key,
  });

  final IconData icono;
  final Color color;
  final Color fondo;
  final double tam;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tam,
      height: tam,
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(tam * 0.28),
      ),
      child: Icon(icono, size: tam * 0.56, color: color),
    );
  }
}
