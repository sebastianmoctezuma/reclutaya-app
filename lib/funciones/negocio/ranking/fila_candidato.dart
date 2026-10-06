import 'package:flutter/material.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/ranking.dart';
import 'package:reclutaya_app/funciones/negocio/comun/presentacion.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/ui/apellido_difuminado.dart';
import 'package:reclutaya_app/nucleo/ui/chip.dart';
import 'package:reclutaya_app/nucleo/ui/esqueleto.dart';
import 'package:reclutaya_app/nucleo/ui/tarjeta.dart';

/// La fila del ranking, la `.candRow` de la web: posición, nombre con el apellido
/// difuminado si no se ha contactado, el chip de la fase, «Cumple X de Y» y traslado,
/// la ficha de la IA en renglones y, a la derecha, el material YA ENTREGADO (video,
/// documento, test con su %) y los puntos. Lo pedido y aún no entregado no se pinta.
/// TAL COMO LLEGA del servidor: aquí no se deriva nada.
class FilaCandidato extends StatelessWidget {
  const FilaCandidato({required this.fila, required this.alTocar, super.key});

  final FilaRanking fila;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = fila;
    final cumple = textoCumple(f.requisitosIncumplidos, f.requisitosTotal);
    final fase = switch (f.fase) {
      'contratado' => const ChipRY('Contratado', tono: TonoChip.verde),
      'no_respondio' => const ChipRY('No respondió', tono: TonoChip.naranja),
      'en_proceso' => const ChipRY('En proceso', tono: TonoChip.azul),
      // Servidor anterior (sin `fase`): lo que ya traía la fila.
      null when f.contratado => const ChipRY(
        'Contratado',
        tono: TonoChip.verde,
      ),
      null when f.noRespondio => const ChipRY(
        'No respondió',
        tono: TonoChip.naranja,
      ),
      _ => null,
    };
    final razones = f.razones.isNotEmpty
        ? f.razones
        : [if (f.resumen != null && f.resumen!.trim().isNotEmpty) f.resumen!];
    final materiales = <Widget>[
      if (f.videoRecibido)
        const _Material(
          key: ValueKey('mat-video'),
          icono: Icons.videocam_rounded,
          etiqueta: 'Video recibido',
        ),
      if (f.documentoRecibido)
        const _Material(
          key: ValueKey('mat-doc'),
          icono: Icons.description_rounded,
          etiqueta: 'Documento recibido',
        ),
      if (f.testScore != null)
        _DonaTest(key: const ValueKey('mat-test'), pct: f.testScore!),
    ];

    return RepaintBoundary(
      child: Tarjeta(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        alTocar: alTocar,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: f.ranking <= 3 ? t.verdeBrillo : t.papel,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${f.ranking}',
                    style: tt.labelLarge!.copyWith(
                      color: f.ranking <= 3 ? t.verdeProfundo : t.tintaSuave,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              f.nombre,
                              style: tt.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (f.apellidoOculto) const ApellidoDifuminado(),
                        ],
                      ),
                      if (fase != null ||
                          cumple != null ||
                          f.minutosTraslado != null) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ?fase,
                            if (cumple != null)
                              Text(
                                cumple,
                                style: tt.labelMedium!.copyWith(
                                  color: f.requisitosIncumplidos == 0
                                      ? t.verdeProfundo
                                      : t.naranjaProfundo,
                                ),
                              ),
                            if (f.minutosTraslado != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 13,
                                    color: t.tintaSuave,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '~${f.minutosTraslado} min',
                                    style: tt.labelMedium,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _Puntaje(f.score),
              ],
            ),
            if (razones.isNotEmpty) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 38),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final r in razones)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 7, right: 8),
                              child: Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: t.verde,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Expanded(child: Text(r, style: tt.bodySmall)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (materiales.isNotEmpty) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 38),
                child: Wrap(spacing: 8, runSpacing: 8, children: materiales),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Un material entregado: el ícono en su cuadro verde, como el `.candMatOk` web.
class _Material extends StatelessWidget {
  const _Material({required this.icono, required this.etiqueta, super.key});

  final IconData icono;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Semantics(
      label: etiqueta,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: t.verdeBrillo,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icono, size: 18, color: t.verdeProfundo),
      ),
    );
  }
}

/// El test respondido: su dona con el porcentaje de compatibilidad.
class _DonaTest extends StatelessWidget {
  const _DonaTest({required this.pct, super.key});

  final num pct;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final p = pct.clamp(0, 100).toDouble();
    return Semantics(
      label: 'Test respondido: ${p.round()}% de compatibilidad',
      child: SizedBox(
        width: 34,
        height: 34,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: p / 100,
                strokeWidth: 3.5,
                backgroundColor: t.linea,
                color: t.naranja,
                strokeCap: StrokeCap.round,
              ),
            ),
            Text(
              '${p.round()}%',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 9.5,
                color: t.tinta,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// «87 pts», como el `.candScore` web.
class _Puntaje extends StatelessWidget {
  const _Puntaje(this.score);

  final num? score;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          score == null ? '—' : '${score!.round()}',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w800,
            fontSize: 22,
            height: 1,
            color: t.verdeProfundo,
          ),
        ),
        Text(
          'pts',
          style: Theme.of(context).textTheme.labelSmall!
              .copyWith(color: t.tintaSuave),
        ),
      ],
    );
  }
}

/// Vacantes del modelo viejo: el candidato existe pero no se ve.
class FilaBloqueada extends StatelessWidget {
  const FilaBloqueada({required this.bloqueado, super.key});

  final Bloqueado bloqueado;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final pts = bloqueado.score == null
        ? ''
        : ' · ${bloqueado.score!.round()} pts';
    return Opacity(
      opacity: 0.45,
      child: Tarjeta(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '${bloqueado.ranking}',
                style: tt.titleMedium!.copyWith(color: t.tintaTenue),
              ),
            ),
            const ApellidoDifuminado(),
            const SizedBox(width: 10),
            Text('Bloqueado$pts', style: tt.labelMedium),
          ],
        ),
      ),
    );
  }
}

class EsqueletoFilaCandidato extends StatelessWidget {
  const EsqueletoFilaCandidato({super.key});

  @override
  Widget build(BuildContext context) {
    return const Tarjeta(
      padding: EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Esqueleto(alto: 16, ancho: 160),
          SizedBox(height: 8),
          Esqueleto(alto: 12, ancho: 120),
          SizedBox(height: 10),
          Esqueleto(alto: 20, ancho: 200, radio: 999),
        ],
      ),
    );
  }
}
