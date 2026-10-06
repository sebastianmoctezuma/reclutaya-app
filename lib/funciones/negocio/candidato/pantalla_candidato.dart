import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reclutaya_app/funciones/negocio/candidato/bloque_test.dart';
import 'package:reclutaya_app/funciones/negocio/candidato/bloque_video.dart';
import 'package:reclutaya_app/funciones/negocio/candidato/controlador_ficha.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/ficha_candidato.dart';
import 'package:reclutaya_app/funciones/negocio/comun/presentacion.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/nucleo/plataforma/adaptativos.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/ui/avatar_iniciales.dart';
import 'package:reclutaya_app/nucleo/ui/chip.dart';
import 'package:reclutaya_app/nucleo/ui/esqueleto.dart';
import 'package:reclutaya_app/nucleo/ui/estados.dart';
import 'package:reclutaya_app/nucleo/ui/tarjeta.dart';
import 'package:reclutaya_app/nucleo/util/formato.dart';
import 'package:url_launcher/url_launcher.dart';

const _lados = EdgeInsets.symmetric(horizontal: 16);

/// La ficha del candidato, la misma del panel lateral de la web. Sin contactar
/// llega parcial (nombre corto, sin teléfono ni archivos) y así se pinta. Las
/// URLs firmadas vencen: si una falla, se pide la ficha otra vez, una sola vez.
class PantallaCandidato extends ConsumerStatefulWidget {
  const PantallaCandidato({required this.postulacionId, super.key});

  final String postulacionId;

  @override
  ConsumerState<PantallaCandidato> createState() => _PantallaCandidatoState();
}

class _PantallaCandidatoState extends ConsumerState<PantallaCandidato> {
  final _control = ControladorFicha();

  void _urlFallo() {
    if (_control.puedeReintentarUrl()) {
      ref.invalidate(candidatoProvider(widget.postulacionId));
    }
  }

  Future<void> _abrir(String url) async {
    // Dentro de la app (Safari View / Custom Tabs): la URL firmada no queda en
    // el historial del navegador.
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.inAppBrowserView,
    );
    if (!ok) _urlFallo();
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.postulacionId;
    final ficha = ref.watch(candidatoProvider(id));
    return PaginaConTitulo(
      titulo: ficha.value?.nombre ?? 'Candidato',
      alRefrescar: () async {
        ref.invalidate(candidatoProvider(id));
        try {
          await ref.read(candidatoProvider(id).future);
        } on ErrorApi {
          // La pantalla ya muestra el error.
        }
      },
      slivers: [
        if (ficha.hasValue && ficha.error is SinRed)
          const SliverToBoxAdapter(child: BannerSinRed()),
        ...ficha.when(
          skipError: ficha.hasValue,
          data: (f) => [
            SliverPadding(
              padding: _lados,
              sliver: SliverList.list(children: _cuerpo(context, f)),
            ),
          ],
          loading: () => const [
            SliverPadding(
              padding: _lados,
              sliver: SliverToBoxAdapter(child: _Cargando()),
            ),
          ],
          error: (e, _) => [
            SliverToBoxAdapter(
              child: EstadoError(
                error: e is ErrorApi ? e : const Servidor(),
                alReintentar: () => e is NoEncontrado
                    ? context.pop()
                    : ref.invalidate(candidatoProvider(id)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _cuerpo(BuildContext context, FichaCandidato f) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final zona = [
      if (f.zona != null) f.zona!,
      if (f.minutosTraslado != null) textoTraslado(f.minutosTraslado),
    ].join(' · ');
    final datos = <(String, Widget)>[
      if (f.whatsapp != null)
        (
          'WhatsApp',
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(child: Text(f.whatsapp!, style: tt.labelLarge)),
              const SizedBox(width: 10),
              _Copiar(f.whatsapp!),
            ],
          ),
        ),
      if (zona.isNotEmpty) ('Zona', Text(zona, style: tt.labelLarge)),
      (
        'Experiencia',
        Text(experiencia(f.experienciaMeses), style: tt.labelLarge),
      ),
      if (f.turnoDisponible != null)
        ('Turno', Text(f.turnoDisponible!, style: tt.labelLarge)),
      if (f.sueldoEsperado != null)
        ('Sueldo esperado', Text(f.sueldoEsperado!, style: tt.labelLarge)),
    ];
    final chips = <Widget>[
      if (f.contactado) const ChipRY('Contactado', tono: TonoChip.azul),
      if (f.noRespondio) const ChipRY('No respondió', tono: TonoChip.naranja),
      if (f.contratado) const ChipRY('Contratado', tono: TonoChip.verde),
      if (f.fechaLimite != null && !f.contratado)
        ChipRY('Vence ${fechaCorta(f.fechaLimite!)}'),
      if (f.entregaFallo == 'sin_whatsapp')
        const ChipRY('Sin WhatsApp', tono: TonoChip.rojo),
    ];
    return [
      Row(
        children: [
          AvatarIniciales(_iniciales(f.nombre), tam: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.nombre,
                  style: tt.titleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 6, children: chips),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (f.score != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: t.verdeBrillo,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${f.score!.round()} pts',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: t.verdeProfundo,
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 16),
      if (f.resumen != null && f.resumen!.trim().isNotEmpty) ...[
        _Seccion(
          'Resumen',
          Text(f.resumen!, style: tt.bodyMedium!.copyWith(height: 1.6)),
        ),
        const SizedBox(height: 12),
      ],
      _Seccion(
        'Datos',
        Column(children: [for (final (k, v) in datos) _Fila(k, v)]),
      ),
      const SizedBox(height: 12),
      _Seccion('Video', BloqueVideo(video: f.video, alFallarUrl: _urlFallo)),
      const SizedBox(height: 12),
      _Seccion(
        'Documento',
        f.documento.url != null
            ? Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => _abrir(f.documento.url!),
                  icon: const Icon(Icons.description_outlined, size: 18),
                  label: const Text('Abrir'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: t.verdeProfundo,
                    side: BorderSide(color: t.lineaFuerte),
                    shape: const StadiumBorder(),
                  ),
                ),
              )
            : Text(
                f.documento.solicitado
                    ? 'Pedido, aún no llega'
                    : 'Sin documento',
                style: tt.bodySmall,
              ),
      ),
      const SizedBox(height: 12),
      _Seccion('Test de compatibilidad', BloqueTest(test: f.test)),
      if (f.respuestas.isNotEmpty) ...[
        const SizedBox(height: 12),
        _Seccion(
          'Respuestas',
          Column(children: [for (final r in f.respuestas) _Respuesta(r)]),
        ),
      ],
      if (f.extras.isNotEmpty) ...[
        const SizedBox(height: 12),
        _Seccion(
          'Datos adicionales',
          Column(children: [for (final r in f.extras) _Respuesta(r)]),
        ),
      ],
    ];
  }

  static String _iniciales(String nombre) {
    final partes = nombre
        .split(' ')
        .where((p) => p.isNotEmpty && p != '·')
        .toList();
    if (partes.isEmpty) return '';
    final a = partes.first.characters.first;
    final b = partes.length > 1 ? partes[1].characters.first : '';
    return (a + b).toUpperCase();
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion(this.titulo, this.hijo);

  final String titulo;
  final Widget hijo;

  @override
  Widget build(BuildContext context) {
    return Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          hijo,
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila(this.k, this.v);

  final String k;
  final Widget v;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.linea)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(k, style: Theme.of(context).textTheme.bodySmall),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Align(alignment: Alignment.centerRight, child: v),
          ),
        ],
      ),
    );
  }
}

/// Copia el WhatsApp. Abrir WhatsApp es acción: eso es la v2.
class _Copiar extends StatelessWidget {
  const _Copiar(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: texto));
        hapticoLigero();
        if (context.mounted) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            const SnackBar(
              content: Text('Número copiado'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: t.verdeBrillo,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          'Copiar',
          style: Theme.of(context).textTheme.labelSmall!
              .copyWith(color: t.verdeProfundo),
        ),
      ),
    );
  }
}

class _Respuesta extends StatelessWidget {
  const _Respuesta(this.r);

  final Respuesta r;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.linea)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(r.texto, style: tt.bodySmall),
          const SizedBox(height: 3),
          Text(r.respuesta, style: tt.labelLarge),
          if (r.requisito || r.incumple) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                if (r.requisito)
                  const ChipRY('Requisito', tono: TonoChip.verde),
                if (r.incumple) const ChipRY('No cumple', tono: TonoChip.rojo),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Esqueleto(alto: 52, ancho: 52, radio: 26),
            SizedBox(width: 12),
            Expanded(child: Esqueleto(alto: 20)),
          ],
        ),
        SizedBox(height: 16),
        Tarjeta(
          child: Column(
            children: [
              Esqueleto(alto: 14),
              SizedBox(height: 12),
              Esqueleto(alto: 14),
              SizedBox(height: 12),
              Esqueleto(alto: 14),
            ],
          ),
        ),
      ],
    );
  }
}
