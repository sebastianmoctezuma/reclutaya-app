import 'package:flutter/material.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/ranking.dart';
import 'package:reclutaya_app/funciones/negocio/comun/presentacion.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/ui/apellido_difuminado.dart';
import 'package:reclutaya_app/nucleo/ui/chip.dart';
import 'package:reclutaya_app/nucleo/ui/esqueleto.dart';
import 'package:reclutaya_app/nucleo/ui/tarjeta.dart';
import 'package:reclutaya_app/nucleo/util/formato.dart';

/// La fila del ranking (la `.candRow` de la web): número, nombre con el
/// apellido difuminado si no se ha contactado, «N pts», zona y traslado, los
/// chips de materiales y de proceso, y «Cumple X de Y». TAL COMO LLEGA del
/// servidor: aquí no se deriva nada. Superficie sólida, con `RepaintBoundary`.
class FilaCandidato extends StatelessWidget {
  const FilaCandidato({required this.fila, required this.alTocar, super.key});

  final FilaRanking fila;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = fila;
    final zona = [
      if (f.zona != null) f.zona!,
      if (f.minutosTraslado != null) textoTraslado(f.minutosTraslado),
    ].join(' · ');
    final cumple = textoCumple(f.requisitosIncumplidos, f.requisitosTotal);
    final chips = <Widget>[
      if (f.contactado) const ChipRY('Contactado', tono: TonoChip.azul),
      if (f.noRespondio) const ChipRY('No respondió', tono: TonoChip.naranja),
      if (f.contratado) const ChipRY('Contratado', tono: TonoChip.verde),
      ..._materiales(f),
      if (f.fechaLimite != null && !f.contratado)
        ChipRY('Vence ${fechaCorta(f.fechaLimite!)}'),
    ];

    return RepaintBoundary(
      child: Tarjeta(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        alTocar: alTocar,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${f.ranking}',
                  style: tt.titleMedium!.copyWith(
                    color: t.tintaTenue,
                    fontVariations: const [FontVariation('wght', 700)],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
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
                      ),
                      const SizedBox(width: 8),
                      _Puntaje(f.score),
                    ],
                  ),
                  if (zona.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      zona,
                      style: tt.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (cumple != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      cumple,
                      style: tt.labelMedium!.copyWith(
                        color: f.requisitosIncumplidos == 0
                            ? t.verdeProfundo
                            : t.naranjaProfundo,
                      ),
                    ),
                  ],
                  if (chips.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 6, children: chips),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<Widget> _materiales(FilaRanking f) {
    final video = textoMaterial(
      solicitado: f.videoSolicitado,
      recibido: f.videoRecibido,
    );
    final doc = textoMaterial(
      solicitado: f.documentoSolicitado,
      recibido: f.documentoRecibido,
    );
    return [
      if (video != null)
        ChipRY(
          'Video ${video.toLowerCase()}',
          tono: f.videoRecibido ? TonoChip.verde : TonoChip.neutro,
        ),
      if (doc != null)
        ChipRY(
          'Documento ${doc.toLowerCase()}',
          tono: f.documentoRecibido ? TonoChip.verde : TonoChip.neutro,
        ),
      if (f.testEstado == 'RESPONDIDA')
        const ChipRY('Test respondido', tono: TonoChip.verde)
      else if (f.testEstado != 'NO_ENVIADA')
        const ChipRY('Test enviado'),
    ];
  }
}

class _Puntaje extends StatelessWidget {
  const _Puntaje(this.score);

  final num? score;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: t.verdeBrillo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        score == null ? '—' : '${score!.round()} pts',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: t.verdeProfundo,
        ),
      ),
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
