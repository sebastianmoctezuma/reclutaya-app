import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/ranking.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/vacantes.dart';
import 'package:reclutaya_app/funciones/negocio/comun/presentacion.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/funciones/negocio/ranking/fila_candidato.dart';
import 'package:reclutaya_app/funciones/negocio/ranking/filtro_material.dart';
import 'package:reclutaya_app/nucleo/plataforma/adaptativos.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/ui/chip.dart';
import 'package:reclutaya_app/nucleo/ui/esqueleto.dart';
import 'package:reclutaya_app/nucleo/ui/estados.dart';
import 'package:reclutaya_app/nucleo/ui/tarjeta.dart';
import 'package:reclutaya_app/nucleo/ui/tesela.dart';
import 'package:reclutaya_app/nucleo/util/formato.dart';
import 'package:reclutaya_app/nucleo/vidrio/vidrio.dart';

const _lados = EdgeInsets.symmetric(horizontal: 16);

/// La ficha de una vacante como en la web: la tarjeta con sus datos duros (ubicación,
/// turno, sueldo), la descripción plegada, el resumen del proceso y, DEBAJO, el ranking
/// completo — no es otra pantalla ni otro botón. Pura vista: sin generar, contactar,
/// pedir material ni finalizar.
class PantallaVacante extends ConsumerWidget {
  const PantallaVacante({required this.slug, super.key});

  final String slug;

  Future<void> _refrescar(WidgetRef ref) async {
    ref
      ..invalidate(vacanteProvider(slug))
      ..invalidate(rankingProvider(slug));
    try {
      await ref.read(vacanteProvider(slug).future);
    } on ErrorApi {
      // La pantalla ya muestra el error.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ficha = ref.watch(vacanteProvider(slug));
    final v = ficha.value;
    return PaginaConTitulo(
      titulo: v?.puesto ?? 'Vacante',
      subtitulo: v == null ? null : _Subtitulo(v),
      alRefrescar: () => _refrescar(ref),
      slivers: [
        if (ficha.hasValue && ficha.error is SinRed)
          const SliverToBoxAdapter(child: BannerSinRed()),
        ...ficha.when(
          skipError: ficha.hasValue,
          data: (v) => [
            SliverPadding(
              padding: _lados,
              sliver: SliverToBoxAdapter(child: _Cabecera(v)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(child: _Proceso(v.conteos)),
            ),
            _Ranking(vacante: v),
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
                    : ref.invalidate(vacanteProvider(slug)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Bajo el puesto, sobre el verde y en blanco: el estado con su punto, los días que
/// le quedan y la sucursal (como el subtítulo de una ficha en iOS).
class _Subtitulo extends StatelessWidget {
  const _Subtitulo(this.v);

  final VacanteFicha v;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final blanco = t.sobreVerde;
    final suave = tt.bodyMedium!.copyWith(
      color: blanco.withValues(alpha: 0.88),
    );
    final dias = v.estado == 'ACTIVA'
        ? textoDiasRestantes(v.diasRestantes)
        : null;
    final punto = switch (v.estado) {
      'ACTIVA' => t.verdeBrillo,
      'PAUSADA' => t.naranja,
      _ => blanco.withValues(alpha: 0.6),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: punto, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Text(
              textoEstadoVacante(v.estado),
              style: tt.labelLarge!.copyWith(color: blanco),
            ),
            if (dias != null) ...[
              Text('  ·  ', style: suave),
              Flexible(child: Text(dias, style: suave)),
            ],
          ],
        ),
        if (v.sucursal != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.storefront_rounded, size: 16, color: blanco),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  v.sucursal!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: suave,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// La tarjeta de la vacante como lista agrupada de iOS: cada dato con su ícono, y
/// plegadas la descripción y las preguntas de filtro. Los avisos (cerrada, formulario
/// cerrado, hubo contratación) van como un renglón más.
class _Cabecera extends StatelessWidget {
  const _Cabecera(this.v);

  final VacanteFicha v;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final aviso = switch (v) {
      VacanteFicha(:final cerradaAt?) =>
        'Cerrada el ${fechaCorta(cerradaAt)}'
            '${v.diasParaArchivar != null ? ' · se archiva en ${v.diasParaArchivar} días' : ''}',
      VacanteFicha(formularioCerrado: true) => 'Formulario cerrado',
      _ => null,
    };
    final renglones = <Widget>[
      if (aviso != null)
        _Dato(
          tesela: Tesela(icono: CupertinoIcons.lock_fill, color: t.tintaSuave),
          etiqueta: 'Aviso',
          valor: aviso,
        ),
      if (v.huboContratacion ?? false)
        _Dato(
          tesela: Tesela(icono: Icons.verified_rounded, color: t.verde),
          etiqueta: 'Resultado',
          valor: 'Hubo contratación',
        ),
      if (v.ubicacion != null)
        _Dato(
          tesela: Tesela(icono: Icons.place_rounded, color: t.azul),
          etiqueta: 'Ubicación',
          valor: v.ubicacion!,
        ),
      if (v.turno != null)
        _Dato(
          tesela: Tesela(icono: Icons.schedule_rounded, color: t.naranja),
          etiqueta: 'Turno',
          valor: v.turno!.isEmpty
              ? v.turno!
              : v.turno![0].toUpperCase() + v.turno!.substring(1),
        ),
      if (v.sueldoTexto != null)
        _Dato(
          tesela: Tesela(icono: Icons.payments_rounded, color: t.verde),
          etiqueta: 'Sueldo',
          valor: v.sueldoTexto!,
        ),
    ];
    return Tarjeta(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, r) in renglones.indexed) ...[
            if (i > 0) Divider(height: 1, indent: 58, color: t.linea),
            r,
          ],
          if (v.descripcion != null && v.descripcion!.trim().isNotEmpty)
            _Plegable(
              titulo: 'Descripción de la vacante',
              hijo: Text(
                v.descripcion!,
                style: tt.bodyMedium!.copyWith(height: 1.6),
              ),
            ),
          _Plegable(
            titulo: v.preguntas.isEmpty
                ? 'Sin preguntas de filtro'
                : 'Preguntas de filtro · ${v.preguntas.length}',
            hijo: v.preguntas.isEmpty
                ? null
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (i, p) in v.preguntas.indexed)
                        _Pregunta(i + 1, p),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({
    required this.tesela,
    required this.etiqueta,
    required this.valor,
  });

  final Widget tesela;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          tesela,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta, style: tt.bodySmall),
                const SizedBox(height: 1),
                Text(valor, style: tt.labelLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Un renglón que se abre al tocarlo, con el chevrón que gira (como en Ajustes).
class _Plegable extends StatefulWidget {
  const _Plegable({required this.titulo, required this.hijo});

  final String titulo;
  final Widget? hijo;

  @override
  State<_Plegable> createState() => _PlegableState();
}

class _PlegableState extends State<_Plegable> {
  bool _abierto = false;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final abrible = widget.hijo != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.linea)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: abrible
                ? () {
                    hapticoSeleccion();
                    setState(() => _abierto = !_abierto);
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.titulo,
                      style: tt.labelLarge!.copyWith(
                        color: abrible ? t.tinta : t.tintaSuave,
                      ),
                    ),
                  ),
                  if (abrible)
                    AnimatedRotation(
                      turns: _abierto ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        CupertinoIcons.chevron_right,
                        size: 15,
                        color: t.tintaTenue,
                      ),
                    ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _abierto
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: widget.hijo,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// El resumen del proceso: postulados, los que cumplen (si pidió requisitos), los que
/// ya están en el ranking y los que faltan por rankear.
class _Proceso extends StatelessWidget {
  const _Proceso(this.c);

  final Conteos c;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final celdas = <(String, int, Color?)>[
      ('Postulados', c.total, null),
      if (c.pideRequisitos) ('Cumplen requisitos', c.cumplenRequisitos, null),
      ('En el ranking', c.rankeados, t.verdeProfundo),
      if (c.sinRankear > 0) ('Sin rankear', c.sinRankear, t.naranjaProfundo),
    ];
    final tt = Theme.of(context).textTheme;
    return Tarjeta(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, (k, n, color)) in celdas.indexed) ...[
              if (i > 0) VerticalDivider(width: 1, color: t.linea),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      numero(n),
                      style: tt.headlineSmall!.copyWith(
                        fontSize: 22,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      k.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: tt.labelSmall!.copyWith(letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// El ranking, dentro de la ficha. Solo se pide si hay candidatos. Arriba, el filtro
/// por material recibido (el «Recibido» de la web).
class _Ranking extends ConsumerStatefulWidget {
  const _Ranking({required this.vacante});

  final VacanteFicha vacante;

  @override
  ConsumerState<_Ranking> createState() => _RankingState();
}

class _RankingState extends ConsumerState<_Ranking> {
  final Set<MaterialRecibido> _filtro = {};

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final vacante = widget.vacante;
    final slug = vacante.slug;
    Widget titulo(String sub) => SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 10),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ranking', style: tt.titleLarge),
            if (sub.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(sub, style: tt.bodySmall),
            ],
          ],
        ),
      ),
    );
    Widget aviso(String t, String texto) => SliverToBoxAdapter(
      child: EstadoVacio(titulo: t, texto: texto),
    );

    if (vacante.purgada) {
      return SliverMainAxisGroup(
        slivers: [
          titulo(''),
          aviso(
            'Datos archivados',
            'El ranking, los videos y los documentos de este proceso se borraron por privacidad a los 30 días de cerrarse.',
          ),
        ],
      );
    }
    if (vacante.conteos.total == 0) {
      return SliverMainAxisGroup(
        slivers: [
          titulo(''),
          aviso(
            'Aún no hay candidatos',
            'Comparte el formulario o el flyer de esta vacante. Cada postulación aparece aquí, ordenada por qué tan bien encaja.',
          ),
        ],
      );
    }
    final ranking = ref.watch(rankingProvider(slug));
    return SliverMainAxisGroup(
      slivers: [
        ...ranking.when(
          skipError: ranking.hasValue,
          data: (r) {
            if (r.visibles.isEmpty && r.bloqueados.isEmpty) {
              return [
                titulo(''),
                aviso(
                  'Aún no hay ranking',
                  'Genera el ranking desde la web y aquí verás a los candidatos ordenados.',
                ),
              ];
            }
            final n = r.total;
            final conteo = conteoMateriales(r.visibles);
            // Los tres siempre, como el «Recibido» de la web, con cuántos lo tienen.
            const ofrecidos = MaterialRecibido.values;
            final filas = filtrarPorMaterial(r.visibles, _filtro);
            final bloqueados = _filtro.isEmpty
                ? r.bloqueados
                : const <Bloqueado>[];
            return [
              titulo(
                '$n ${n == 1 ? 'candidato, ordenado' : 'candidatos, ordenados'} por qué tan bien encajan',
              ),
              if (ranking.error is SinRed)
                const SliverToBoxAdapter(child: BannerSinRed()),
              if (ofrecidos.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  sliver: SliverToBoxAdapter(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final m in ofrecidos)
                          _ChipFiltro(
                            etiqueta: '${m.etiqueta} · ${conteo[m]}',
                            icono: switch (m) {
                              MaterialRecibido.video => Icons.videocam_rounded,
                              MaterialRecibido.documento =>
                                Icons.description_rounded,
                              MaterialRecibido.test =>
                                Icons.donut_large_rounded,
                            },
                            activo: _filtro.contains(m),
                            alTocar: () => setState(() {
                              hapticoSeleccion();
                              if (!_filtro.remove(m)) _filtro.add(m);
                            }),
                          ),
                      ],
                    ),
                  ),
                ),
              if (filas.isEmpty)
                const SliverToBoxAdapter(
                  child: EstadoVacio(titulo: 'Nadie con ese material todavía'),
                )
              else
                SliverPadding(
                  padding: _lados,
                  sliver: SliverList.separated(
                    itemCount: filas.length + bloqueados.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      if (i < filas.length) {
                        final f = filas[i];
                        return FilaCandidato(
                          fila: f,
                          alTocar: () => context.go(
                            '/vacantes/$slug/ranking/${f.postulacionId}',
                          ),
                        );
                      }
                      return FilaBloqueada(
                        bloqueado: bloqueados[i - filas.length],
                      );
                    },
                  ),
                ),
            ];
          },
          loading: () => [
            titulo(''),
            SliverPadding(
              padding: _lados,
              sliver: SliverList.separated(
                itemCount: 3,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, _) => const EsqueletoFilaCandidato(),
              ),
            ),
          ],
          error: (e, _) => [
            titulo(''),
            SliverToBoxAdapter(
              child: EstadoError(
                error: e is ErrorApi ? e : const Servidor(),
                alReintentar: () => ref.invalidate(rankingProvider(slug)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Pregunta extends StatelessWidget {
  const _Pregunta(this.n, this.p);

  final int n;
  final Pregunta p;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: t.papel, shape: BoxShape.circle),
            child: Text('$n', style: tt.labelMedium),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.texto, style: tt.bodyMedium),
                if (p.esRequisito) ...[
                  const SizedBox(height: 4),
                  const ChipRY('Requisito', tono: TonoChip.verde),
                ],
              ],
            ),
          ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Esqueleto(alto: 22, ancho: 160, radio: 999),
        SizedBox(height: 14),
        Tarjeta(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Esqueleto(alto: 14, ancho: 100),
              SizedBox(height: 14),
              Esqueleto(alto: 30, ancho: 220),
            ],
          ),
        ),
        SizedBox(height: 12),
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

/// Un filtro de material: pastilla de vidrio apagada; encendida, verde sólido con el
/// texto en blanco.
class _ChipFiltro extends StatelessWidget {
  const _ChipFiltro({
    required this.etiqueta,
    required this.icono,
    required this.activo,
    required this.alTocar,
  });

  final String etiqueta;
  final IconData icono;
  final bool activo;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    // Apagado, vidrio con texto en tinta; encendido, verde sólido con texto blanco.
    final color = activo ? t.sobreVerde : t.tinta;
    final cuerpo = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            etiqueta,
            style: Theme.of(context).textTheme.labelLarge!
                .copyWith(color: color),
          ),
        ],
      ),
    );
    final toque = Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: alTocar,
        child: cuerpo,
      ),
    );
    return Semantics(
      selected: activo,
      button: true,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: activo
            ? DecoratedBox(
                key: const ValueKey(true),
                decoration: BoxDecoration(
                  color: t.verde,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: toque,
              )
            : Vidrio.pastilla(key: const ValueKey(false), child: toque),
      ),
    );
  }
}
