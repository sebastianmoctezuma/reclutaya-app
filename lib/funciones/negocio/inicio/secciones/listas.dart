import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/inicio.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/vacantes.dart';
import 'package:reclutaya_app/funciones/negocio/comun/presentacion.dart';
import 'package:reclutaya_app/funciones/negocio/inicio/inicio_core.dart';
import 'package:reclutaya_app/funciones/negocio/inicio/secciones/comunes.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/ui/chip.dart';
import 'package:reclutaya_app/nucleo/ui/tarjeta.dart';

void _ir(BuildContext context, String ruta) =>
    GoRouter.maybeOf(context)?.go(ruta);

/// «Tus sucursales»: logo, nombre, «Principal» y cuántas vacantes tiene. Tocar lleva a
/// la pestaña Sucursales. Sin «Agregar sucursal»: es pura vista.
class TusSucursales extends StatelessWidget {
  const TusSucursales({required this.sucursales, super.key});

  final List<SucursalInicio> sucursales;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Grupo(
      renglones: [
        for (final s in sucursales)
          Renglon(
            inicio: LogoSucursal(
              nombre: s.nombre,
              imagenUrl: s.imagenUrl,
              colorIdx: s.colorIdx,
            ),
            hijo: Row(
              children: [
                Flexible(
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
            final_: Text(
              s.vacantesActivas == 1
                  ? '1 vacante'
                  : '${s.vacantesActivas} vacantes',
              style: tt.bodySmall,
            ),
            alTocar: () => _ir(context, '/vacantes'),
          ),
      ],
    );
  }
}

/// El logo de una sucursal (su imagen pública) o su inicial sobre su color.
class LogoSucursal extends StatelessWidget {
  const LogoSucursal({
    required this.nombre,
    required this.colorIdx,
    this.imagenUrl,
    this.tam = 32,
    super.key,
  });

  final String nombre;
  final String? imagenUrl;
  final int colorIdx;
  final double tam;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final inicial = Container(
      width: tam,
      height: tam,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorSucursal(colorIdx, oscuro: t.esOscuro),
        shape: BoxShape.circle,
      ),
      child: Text(
        nombre.isEmpty ? '' : nombre.characters.first.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: tam * 0.42,
          color: t.sobreVerde,
        ),
      ),
    );
    if (imagenUrl == null || imagenUrl!.isEmpty) return inicial;
    return ClipOval(
      child: SizedBox(
        width: tam,
        height: tam,
        child: CachedNetworkImage(
          imageUrl: imagenUrl!,
          fit: BoxFit.cover,
          placeholder: (_, _) => inicial,
          errorWidget: (_, _, _) => inicial,
        ),
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
                  Tesela(
                    icono: icono,
                    color: t.verdeProfundo,
                    fondo: t.verdeBrillo,
                    tam: 28,
                  ),
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
              fondo: e.tipo == 'test' ? t.naranjaBrillo : t.azulBrillo,
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
            Tesela(
              icono: Icons.add_rounded,
              color: t.naranjaProfundo,
              fondo: t.naranjaBrillo,
              tam: 40,
            ),
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
