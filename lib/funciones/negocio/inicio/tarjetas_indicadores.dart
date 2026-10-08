import 'package:flutter/material.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/inicio.dart';
import 'package:reclutaya_app/funciones/negocio/comun/presentacion.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/ui/cifra.dart';
import 'package:reclutaya_app/nucleo/ui/esqueleto.dart';
import 'package:reclutaya_app/nucleo/ui/tarjeta.dart';
import 'package:reclutaya_app/nucleo/ui/tesela.dart';

/// Dos columnas con alto fijo que ESCALA con la letra del sistema: la
/// etiqueta puede ocupar dos líneas y la cifra es grande; una proporción fija
/// se quedaba corta y desbordaba.
SliverGridDelegate _rejilla(BuildContext context) =>
    SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      mainAxisExtent: MediaQuery.textScalerOf(context).scale(178),
    );

/// Las cuatro tarjetas de 30 días del Inicio, con los textos del panel web.
/// `cumplenPct` y `tiempoDias` en null se leen como «—».
class TarjetasIndicadores extends StatelessWidget {
  const TarjetasIndicadores({required this.k, super.key});

  final Indicadores k;

  @override
  Widget build(BuildContext context) {
    final cumple = k.cumplenPct != null;
    final tiempo = k.tiempoDias != null;
    final tarjetas = [
      _Indicador(
        tono: TonoIndicador.verde,
        icono: Icons.speed_rounded,
        etiqueta: 'Velocidad de postulaciones',
        valor: _num(k.velocidad),
        sub: 'postulaciones por día',
        delta: k.velocidadDelta,
        unidadDelta: '%',
      ),
      _Indicador(
        tono: TonoIndicador.azul,
        icono: Icons.filter_alt_outlined,
        etiqueta: 'Cumplen requisitos',
        valor: cumple ? '${k.cumplenPct}' : '—',
        unidad: cumple ? '%' : null,
        sub: cumple
            ? '${k.cumplenN ?? 0} de ${k.cumplenTotal ?? 0} postulaciones'
            : 'Aún no pides requisitos',
        delta: cumple ? k.cumplenDelta : null,
        unidadDelta: '%',
      ),
      _Indicador(
        tono: TonoIndicador.naranja,
        icono: Icons.chat_bubble_outline_rounded,
        etiqueta: 'Tasa de respuesta',
        valor: _num(k.respuestaPct),
        unidad: k.respuestaPct == null ? null : '%',
        sub: 'de los contactados',
        delta: k.respuestaDelta,
        unidadDelta: '%',
      ),
      _Indicador(
        tono: TonoIndicador.profundo,
        icono: Icons.schedule_rounded,
        etiqueta: 'Tiempo a contratación',
        valor: tiempo ? '${k.tiempoDias}' : '—',
        unidad: tiempo ? 'días' : null,
        sub: tiempo ? 'De publicar a contratar' : 'Aún sin contrataciones',
        delta: tiempo ? k.tiempoDelta : null,
        unidadDelta: ' días',
      ),
    ];
    return SliverGrid(
      gridDelegate: _rejilla(context),
      delegate: SliverChildListDelegate(tarjetas),
    );
  }

  static String _num(num? v) {
    if (v == null) return '—';
    return v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);
  }
}

/// Cada indicador con un color de la marca (verde, azul, naranja, verde
/// profundo), como los íconos de las tarjetas del panel.
enum TonoIndicador { verde, azul, naranja, profundo }

class _Indicador extends StatelessWidget {
  const _Indicador({
    required this.tono,
    required this.icono,
    required this.etiqueta,
    required this.valor,
    required this.sub,
    required this.unidadDelta,
    this.unidad,
    this.delta,
  });

  final TonoIndicador tono;
  final IconData icono;
  final String etiqueta;
  final String valor;
  final String? unidad;
  final String sub;
  final num? delta;
  final String unidadDelta;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final color = switch (tono) {
      TonoIndicador.verde => t.verde,
      TonoIndicador.azul => t.azul,
      TonoIndicador.naranja => t.naranja,
      TonoIndicador.profundo => t.verdeProfundo,
    };
    return Tarjeta(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      // Arriba el ícono con el cambio contra el periodo anterior a la derecha; abajo
      // la etiqueta a todo el ancho, la cifra y su contexto (8-oct: con el cambio junto
      // a la etiqueta, ésta se partía en dos renglones y el cambio quedaba flotando).
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Tesela(icono: icono, color: color, tam: 32),
              const SizedBox(width: 8),
              // En un teléfono angosto el cambio largo («12 días») se encoge, no se sale.
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: delta == null
                      ? null
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _Delta(delta!, unidadDelta),
                        ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Cifra(valor: valor, unidad: unidad, etiqueta: etiqueta, sub: sub),
        ],
      ),
    );
  }
}

class _Delta extends StatelessWidget {
  const _Delta(this.d, this.unidad);

  final num d;
  final String unidad;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final r = delta(d, unidad);
    final (color, fondo, icono) = switch (r.tono) {
      TonoDelta.sube => (
        t.verdeProfundo,
        t.verdeBrillo,
        Icons.arrow_upward_rounded,
      ),
      TonoDelta.baja => (
        t.naranjaProfundo,
        t.naranjaBrillo,
        Icons.arrow_downward_rounded,
      ),
      TonoDelta.neutro => (t.tintaTenue, t.linea, null),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) Icon(icono, size: 11, color: color),
          Text(
            r.texto,
            style: Theme.of(context).textTheme.labelSmall!
                .copyWith(color: color, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

/// Mientras carga: la misma rejilla, en gris.
class EsqueletoIndicadores extends StatelessWidget {
  const EsqueletoIndicadores({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: _rejilla(context),
      delegate: SliverChildListDelegate([
        for (var i = 0; i < 4; i++)
          const Tarjeta(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Esqueleto(alto: 34, ancho: 34, radio: 17),
                Spacer(),
                Esqueleto(alto: 12, ancho: 110),
                SizedBox(height: 10),
                Esqueleto(alto: 30, ancho: 70),
                SizedBox(height: 8),
                Esqueleto(alto: 10, ancho: 90),
              ],
            ),
          ),
      ]),
    );
  }
}
