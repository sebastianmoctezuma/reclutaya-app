import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/novedades.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/funciones/negocio/novedades/avisos_core.dart';
import 'package:reclutaya_app/funciones/negocio/novedades/novedades_core.dart';
import 'package:reclutaya_app/nucleo/plataforma/adaptativos.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/ui/esqueleto.dart';
import 'package:reclutaya_app/nucleo/ui/estados.dart';
import 'package:reclutaya_app/nucleo/ui/tarjeta.dart';
import 'package:reclutaya_app/nucleo/ui/tesela.dart';

/// La Actividad (7-oct), como la de la web pero de la app: lo de la semana agrupado
/// por día, con un resumen arriba. Cada evento dice SIEMPRE la vacante y la sucursal;
/// lo que llegó desde la última vez lleva su punto. Tocar uno abre al candidato (o la
/// vacante, si es el ranking listo).
class PantallaActividad extends ConsumerWidget {
  const PantallaActividad({this.vistoAntes, super.key});

  /// Hasta dónde se había visto ANTES de abrirla (para marcar lo nuevo).
  final DateTime? vistoAntes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final novedades = ref.watch(novedadesProvider);
    return PaginaConTitulo(
      titulo: 'Actividad',
      alRefrescar: () async {
        ref.invalidate(novedadesProvider);
        try {
          await ref.read(novedadesProvider.future);
        } on ErrorApi {
          // La pantalla ya muestra el error.
        }
      },
      slivers: novedades.when(
        skipError: novedades.hasValue,
        data: (n) => _cuerpo(context, n),
        loading: () => const [
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Esqueleto(alto: 300, radio: radioGrande),
            ),
          ),
        ],
        error: (e, _) => [
          SliverToBoxAdapter(
            child: EstadoError(
              error: e is ErrorApi ? e : const Servidor(),
              alReintentar: () => ref.invalidate(novedadesProvider),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _cuerpo(BuildContext context, Novedades n) {
    if (n.items.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: EstadoVacio(
            titulo: 'Sin actividad esta semana',
            texto: 'Aquí verás a quién se postula, quién manda su video, documento o test y cuándo está listo un ranking.',
          ),
        ),
      ];
    }
    final nuevas = nuevasDesde(n.items, vistoAntes).toSet();
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        sliver: SliverToBoxAdapter(child: _Resumen(conteoPorTipo(n.items))),
      ),
      for (final (dia, lista) in porDia(n.items, DateTime.now()))
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
                  child: Text(
                    dia[0].toUpperCase() + dia.substring(1),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Tarjeta(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      for (final (i, e) in lista.indexed) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            indent: 62,
                            color: context.t.linea,
                          ),
                        _Evento(e, nueva: nuevas.contains(e)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    ];
  }
}

(IconData, Color) _iconoDe(String tipo, Tokens t) => switch (tipo) {
  'video' => (Icons.videocam_rounded, t.verde),
  'documento' => (Icons.description_rounded, t.verdeProfundo),
  'test' => (Icons.donut_large_rounded, t.naranja),
  'ranking' => (Icons.leaderboard_rounded, t.azul),
  'expediente_documento' => (Icons.folder_rounded, t.naranjaProfundo),
  'expediente_completo' => (Icons.folder_special_rounded, t.verdeProfundo),
  'entrevista_pronto' => (Icons.videocam_rounded, t.azul),
  _ => (Icons.person_add_alt_1_rounded, t.azul),
};

/// Arriba: cuántos de cada cosa en la semana, como los chips de la Actividad web.
class _Resumen extends StatelessWidget {
  const _Resumen(this.conteo);

  final Map<String, int> conteo;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    const nombres = {
      'postulacion': ('candidato', 'candidatos'),
      'video': ('video', 'videos'),
      'documento': ('documento', 'documentos'),
      'test': ('test', 'tests'),
      'ranking': ('ranking', 'rankings'),
      'expediente_documento': ('papel', 'papeles'),
      'expediente_completo': ('expediente', 'expedientes'),
      'entrevista_pronto': ('entrevista', 'entrevistas'),
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tipo in nombres.keys)
          if ((conteo[tipo] ?? 0) > 0)
            Tarjeta(
              padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tesela(
                    icono: _iconoDe(tipo, t).$1,
                    color: _iconoDe(tipo, t).$2,
                    tam: 26,
                  ),
                  const SizedBox(width: 8),
                  Text('${conteo[tipo]}', style: tt.titleMedium),
                  const SizedBox(width: 4),
                  Text(
                    conteo[tipo] == 1 ? nombres[tipo]!.$1 : nombres[tipo]!.$2,
                    style: tt.bodySmall,
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _Evento extends StatelessWidget {
  const _Evento(this.e, {required this.nueva});

  final Novedad e;
  final bool nueva;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final (icono, color) = _iconoDe(e.tipo, t);
    final ruta = rutaDeAviso({
      'slug': e.slug,
      'postulacionId': e.postulacionId,
    });
    return InkWell(
      onTap: ruta == null
          ? null
          : () {
              hapticoSeleccion();
              GoRouter.maybeOf(context)?.go(ruta);
            },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Tesela(icono: icono, color: color, tam: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(e.titulo ?? e.frase, style: tt.labelLarge),
                      ),
                      Text(
                        DateFormat('h:mm a', 'es_MX').format(e.at.toLocal()),
                        style: tt.labelSmall,
                      ),
                    ],
                  ),
                  if (e.titulo != null) ...[
                    const SizedBox(height: 2),
                    Text(e.frase, style: tt.bodyMedium),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    // SIEMPRE la vacante y la sucursal.
                    [e.puesto, ?e.sucursal].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: nueva
                  ? Semantics(
                      label: 'Nueva',
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: t.naranja,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : Icon(
                      CupertinoIcons.chevron_right,
                      size: 15,
                      color: t.tintaTenue,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
