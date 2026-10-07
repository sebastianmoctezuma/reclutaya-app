import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/inicio.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/vacantes.dart';
import 'package:reclutaya_app/funciones/negocio/comun/presentacion.dart';
import 'package:reclutaya_app/funciones/negocio/inicio/inicio_core.dart';
import 'package:reclutaya_app/funciones/negocio/inicio/secciones/comunes.dart';
import 'package:reclutaya_app/funciones/negocio/sucursales/piezas.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/ui/chip.dart';
import 'package:reclutaya_app/nucleo/ui/tarjeta.dart';

void _ir(BuildContext context, String ruta) =>
    GoRouter.maybeOf(context)?.go(ruta);

/// «Tus sucursales»: un carrusel con las tarjetas teñidas de la vista Sucursales (logo,
/// «Principal», vacantes y lo de la semana). Tocar una lleva a la pestaña Sucursales.
/// Sin «Agregar sucursal»: es pura vista.
class TusSucursales extends StatelessWidget {
  const TusSucursales({required this.sucursales, super.key});

  final List<SucursalInicio> sucursales;

  @override
  Widget build(BuildContext context) {
    final escala = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
    return SizedBox(
      height: 150 * escala,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // A sangre: corre hasta la orilla de la pantalla, como los carruseles de iOS.
        padding: ladosInicio,
        clipBehavior: Clip.none,
        itemCount: sucursales.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) =>
            SizedBox(width: 250, child: _MiniSucursal(sucursales[i])),
      ),
    );
  }
}

class _MiniSucursal extends StatelessWidget {
  const _MiniSucursal(this.s);

  final SucursalInicio s;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final semana = [
      '${plural(s.candidatosSemana, 'candidato', 'candidatos')} esta semana',
      if (s.sinRanking > 0) '${s.sinRanking} sin ranking',
    ].join(' · ');
    return SuperficieSucursal(
      colorIdx: s.colorIdx,
      padding: const EdgeInsets.all(14),
      alTocar: () => _ir(context, '/vacantes'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LogoSucursal(
                nombre: s.nombre,
                imagenUrl: s.imagenUrl,
                colorIdx: s.colorIdx,
                tam: 28,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.titleMedium,
                ),
              ),
              if (s.principal) ...[
                const SizedBox(width: 6),
                const ChipRY('Principal'),
              ],
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${s.vacantesActivas}',
                style: tt.headlineMedium!.copyWith(fontSize: 30, height: 1),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  s.vacantesActivas == 1 ? 'vacante' : 'vacantes',
                  style: tt.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            semana,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.labelMedium!.copyWith(
              color: s.sinRanking > 0 ? t.naranjaProfundo : t.tintaSuave,
            ),
          ),
        ],
      ),
    );
  }
}

/// «Pendientes»: lo que espera al dueño, como texto. Sin «Generar» ni «Atender»: tocar
/// uno de vacante abre su ficha.
class Pendientes extends StatelessWidget {
  const Pendientes({required this.items, super.key});

  final List<PendienteInicio> items;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    if (items.isEmpty) {
      return Grupo(
        renglones: [
          Renglon(
            inicio: Icon(Icons.check_circle_rounded, color: t.verde, size: 22),
            hijo: Text('Nada pendiente por ahora.', style: tt.bodyMedium),
          ),
        ],
        sangria: 16,
      );
    }
    return Grupo(
      sangria: 34,
      renglones: [
        for (final p in items)
          Renglon(
            inicio: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: switch (p.tipo) {
                  'vence' => t.rojo,
                  'solicitud' => t.naranja,
                  _ => t.verde,
                },
              ),
            ),
            hijo: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tt.labelLarge,
                ),
                const SizedBox(height: 2),
                Text(p.sub, style: tt.bodySmall),
              ],
            ),
            alTocar: p.slug == null
                ? null
                : () => _ir(context, '/vacantes/${p.slug}'),
          ),
      ],
    );
  }
}

/// «Tu proceso · 30 días»: postulaciones → cumplen → contactados → contratados, en
/// barras horizontales, y la conversión total. La etapa «Cumplen» solo si se pidió algo.
class Proceso extends StatelessWidget {
  const Proceso({required this.embudo, super.key});

  final EmbudoInicio embudo;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final etapas = <(IconData, String, int, Color)>[
      (
        Icons.person_outline_rounded,
        'Postulaciones',
        embudo.postulaciones,
        t.verde.withValues(alpha: 0.45),
      ),
      if (embudo.conRequisitos > 0)
        (
          Icons.filter_alt_outlined,
          'Cumplen requisitos',
          embudo.cumplenRequisitos,
          t.verde.withValues(alpha: 0.6),
        ),
      (
        Icons.chat_bubble_outline_rounded,
        'Contactados',
        embudo.contactados,
        t.verde.withValues(alpha: 0.8),
      ),
      (
        Icons.check_circle_outline_rounded,
        'Contratados',
        embudo.contratados,
        t.verdeProfundo,
      ),
    ];
    final maximo = etapas.fold<int>(1, (a, e) => e.$3 > a ? e.$3 : a);
    return Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (icono, etiqueta, n, color) in etapas)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Tesela(icono: icono, color: t.verdeProfundo, tam: 28),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 104,
                    child: Text(
                      etiqueta,
                      maxLines: 2,
                      style: tt.labelMedium!.copyWith(color: t.tinta),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        // Lo mínimo para que el número quepa en un renglón.
                        final minimo = MediaQuery.textScalerOf(context)
                            .scale(20 + 9.0 * '$n'.length)
                            .clamp(34.0, c.maxWidth);
                        final ancho = (c.maxWidth * n / maximo).clamp(
                          minimo,
                          c.maxWidth,
                        );
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: ancho,
                            height: 34,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$n',
                              maxLines: 1,
                              softWrap: false,
                              style: tt.labelLarge!.copyWith(
                                color: t.sobreVerde,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Divider(height: 1, color: t.linea),
          const SizedBox(height: 10),
          Text(textoConversion(embudo), style: tt.bodySmall),
        ],
      ),
    );
  }
}

/// «Actividad reciente»: material entregado esta semana. Tres a la vista y «Ver toda
/// la semana» despliega el resto. Tocar abre el ranking de esa vacante.
class Actividad extends StatefulWidget {
  const Actividad({required this.eventos, super.key});

  final List<ActividadInicio> eventos;

  @override
  State<Actividad> createState() => _ActividadState();
}

class _ActividadState extends State<Actividad> {
  bool _todo = false;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final evs = widget.eventos;
    if (evs.isEmpty) {
      return Grupo(
        sangria: 16,
        renglones: [
          Renglon(
            hijo: Text(
              'Esta semana aún no entregan material.',
              style: tt.bodyMedium,
            ),
          ),
        ],
      );
    }
    final visibles = _todo ? evs : evs.take(3).toList();
    return Grupo(
      renglones: [
        for (final e in visibles)
          Renglon(
            inicio: Tesela(
              icono: switch (e.tipo) {
                'video' => Icons.videocam_outlined,
                'test' => Icons.fact_check_outlined,
                _ => Icons.description_outlined,
              },
              color: e.tipo == 'test' ? t.naranjaProfundo : t.azul,
            ),
            hijo: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: e.candidato, style: tt.labelLarge),
                      TextSpan(text: ' ${e.accion}', style: tt.bodyMedium),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    e.puesto,
                    e.sucursal,
                    e.hace,
                  ].whereType<String>().join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodySmall,
                ),
              ],
            ),
            alTocar: () => _ir(context, '/vacantes/${e.slug}/ranking'),
          ),
        if (evs.length > 3)
          InkWell(
            onTap: () => setState(() => _todo = !_todo),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Center(
                child: Text(
                  _todo ? 'Ver menos' : 'Ver toda la semana · ${evs.length}',
                  style: tt.labelLarge!.copyWith(color: t.verdeProfundo),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// «Vacantes en curso»: cada vacante con su sucursal, su ubicación, estado, candidatos
/// y el siguiente paso COMO TEXTO (sin «Revisar candidatos» como botón). Tocar abre la
/// ficha.
class VacantesEnCurso extends StatelessWidget {
  const VacantesEnCurso({
    required this.vacantes,
    required this.conSucursal,
    super.key,
  });

  final List<VacanteResumen> vacantes;
  final bool conSucursal;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    if (vacantes.isEmpty) {
      return Tarjeta(
        child: Row(
          children: [
            Tesela(icono: Icons.add_rounded, color: t.naranjaProfundo, tam: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Publica tu primera vacante desde la web y aquí verás a tus candidatos.',
                style: tt.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        for (final v in vacantes) ...[
          Tarjeta(
            padding: EdgeInsets.zero,
            alTocar: () => _ir(context, '/vacantes/${v.slug}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(v.puesto, style: tt.titleLarge),
                          if (conSucursal && v.sucursal != null)
                            _ChipSucursal(v.sucursal!),
                        ],
                      ),
                      if (v.ubicacion != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          v.ubicacion!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                _Dato('Estado', _Estado(v.estado)),
                _Dato(
                  'Candidatos',
                  Text('${v.candidatos}', style: tt.labelLarge),
                ),
                _Dato(
                  'Siguiente paso',
                  Text(
                    v.siguientePaso ?? '—',
                    style: tt.labelLarge!.copyWith(color: t.verdeProfundo),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ChipSucursal extends StatelessWidget {
  const _ChipSucursal(this.s);

  final SucursalRef s;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: t.papel,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: t.linea),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: colorSucursal(s.colorIdx, oscuro: t.esOscuro),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              s.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _Estado extends StatelessWidget {
  const _Estado(this.estado);

  final String estado;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final color = switch (estado) {
      'ACTIVA' => t.verde,
      'PAUSADA' => t.naranja,
      _ => t.tintaTenue,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          textoEstadoVacante(estado),
          style: Theme.of(context).textTheme.labelLarge!.copyWith(color: color),
        ),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.etiqueta, this.valor);

  final String etiqueta;
  final Widget valor;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.linea)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              etiqueta.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall!
                  .copyWith(letterSpacing: 0.6),
            ),
          ),
          valor,
        ],
      ),
    );
  }
}
