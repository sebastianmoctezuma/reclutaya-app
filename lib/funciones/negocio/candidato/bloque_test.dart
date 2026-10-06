import 'package:flutter/material.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/ficha_candidato.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/ui/chip.dart';

/// El resultado del test de compatibilidad, como en el panel: barras por
/// rasgo, los tres más altos, el arquetipo, comentarios e integridad (bajo =
/// verde, nota = ámbar, medio = rojo). El servidor ya resolvió todo.
class BloqueTest extends StatelessWidget {
  const BloqueTest({required this.test, super.key});

  final Test test;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final r = test.resultado;
    if (test.estado == 'NO_ENVIADA') {
      return Text('Sin test', style: tt.bodySmall);
    }
    if (r == null) {
      return Text('Test enviado, sin responder', style: tt.bodySmall);
    }
    final tono = switch (r.integridadTono) {
      'bajo' => TonoChip.verde,
      'nota' => TonoChip.naranja,
      'medio' => TonoChip.rojo,
      _ => TonoChip.neutro,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ChipRY(r.integridad, tono: tono),
            if (test.duracion != null) ChipRY(test.duracion!),
            if (r.respuestasMarcadas > 0)
              ChipRY(
                r.respuestasMarcadas == 1
                    ? '1 respuesta marcada'
                    : '${r.respuestasMarcadas} respuestas marcadas',
              ),
          ],
        ),
        if (r.arquetipo.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(r.arquetipo.join(' · '), style: tt.titleMedium),
        ],
        if (r.top3.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('Lo más fuerte', style: tt.labelMedium),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final x in r.top3) ChipRY(x, tono: TonoChip.verde)],
          ),
        ],
        if (r.rasgos.isNotEmpty) ...[
          const SizedBox(height: 14),
          for (final e in r.rasgos.entries) _Rasgo(e.key, e.value),
        ],
        if (r.comentarios.isNotEmpty) ...[
          const SizedBox(height: 10),
          for (final c in r.comentarios)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: t.tintaTenue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(c, style: tt.bodyMedium)),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _Rasgo extends StatelessWidget {
  const _Rasgo(this.nombre, this.valor);

  final String nombre;
  final num valor;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final p = (valor / 100).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(nombre, style: tt.bodySmall)),
              Text('${valor.round()}%', style: tt.labelMedium),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  ColoredBox(color: t.papel, child: const SizedBox.expand()),
                  FractionallySizedBox(
                    widthFactor: p,
                    child: ColoredBox(
                      color: t.verde,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
