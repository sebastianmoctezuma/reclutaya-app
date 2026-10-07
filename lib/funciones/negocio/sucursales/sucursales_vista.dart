import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/sucursales.dart';
import 'package:reclutaya_app/funciones/negocio/comun/presentacion.dart';
import 'package:reclutaya_app/funciones/negocio/sucursales/piezas.dart';
import 'package:reclutaya_app/nucleo/plataforma/adaptativos.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/ui/chip.dart';
import 'package:reclutaya_app/nucleo/ui/tarjeta.dart';
import 'package:reclutaya_app/nucleo/util/formato.dart';
import 'package:reclutaya_app/nucleo/vidrio/hoja.dart';

/// La tarjeta de una sucursal en la vista «Sucursales», como la web: logo, nombre,
/// «Principal», dirección, vacantes · miembros y las iniciales del equipo. Tocarla
/// abre su ventana. Sin engrane ni «Invitar»: es pura vista.
class TarjetaSucursal extends StatelessWidget {
  const TarjetaSucursal(this.s, {super.key});

  final SucursalConVacantes s;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    return SuperficieSucursal(
      colorIdx: s.colorIdx,
      alTocar: () => unawaited(mostrarSucursal(context, s)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LogoSucursal(
                nombre: s.nombre,
                imagenUrl: s.imagenUrl,
                colorIdx: s.colorIdx,
                tam: 30,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
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
                      const SizedBox(width: 8),
                      const ChipRY('Principal'),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(CupertinoIcons.chevron_right, size: 15, color: t.tintaTenue),
            ],
          ),
          if (s.direccion != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    CupertinoIcons.location_solid,
                    size: 13,
                    color: t.tintaSuave,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(child: Text(s.direccion!, style: tt.bodyMedium)),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Text(
            '${plural(s.vacantesActivas, 'vacante', 'vacantes')} · '
            '${plural(s.miembros.length, 'miembro', 'miembros')}',
            style: tt.bodySmall,
          ),
          if (s.sinRanking > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: t.naranja,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  plural(
                    s.sinRanking,
                    'candidato sin ranking',
                    'candidatos sin ranking',
                  ),
                  style: tt.labelMedium!.copyWith(color: t.naranjaProfundo),
                ),
              ],
            ),
          ],
          if (s.miembros.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final m in s.miembros.take(6))
                  Iniciales(m.iniciales, colorIdx: s.colorIdx),
                if (s.miembros.length > 6)
                  Text('+${s.miembros.length - 6}', style: tt.labelMedium),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// «Tu equipo»: una fila como las de Ajustes de iOS, con las iniciales encimadas,
/// cuántas personas son y el chevrón. Abre la hoja del equipo.
class FilaEquipo extends StatelessWidget {
  const FilaEquipo(this.equipo, {super.key});

  final List<Persona> equipo;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final visibles = equipo.take(4).toList();
    const tam = 34.0;
    return Tarjeta(
      padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
      alTocar: () {
        hapticoSeleccion();
        unawaited(
          mostrarHojaVidrio(context, builder: (_) => _HojaEquipo(equipo)),
        );
      },
      child: Row(
        children: [
          SizedBox(
            width: tam + (visibles.length - 1) * (tam * 0.62),
            height: tam,
            child: Stack(
              children: [
                for (final (i, p) in visibles.indexed)
                  Positioned(
                    left: i * tam * 0.62,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: t.tarjeta, width: 2),
                      ),
                      child: Iniciales(
                        p.iniciales,
                        colorIdx: p.sucursales.isEmpty
                            ? 0
                            : p.sucursales.first.colorIdx,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tu equipo', style: tt.titleMedium),
                Text(
                  plural(equipo.length, 'persona', 'personas'),
                  style: tt.bodySmall,
                ),
              ],
            ),
          ),
          Icon(CupertinoIcons.chevron_right, size: 15, color: t.tintaTenue),
        ],
      ),
    );
  }
}

/// La ventana de una sucursal (el `SucursalVacantesModal` web): su encabezado, los tres
/// números y sus vacantes. Sin «Crear vacante», «Finalizar» ni «Administrar»: tocar una
/// vacante abre su ficha.
Future<void> mostrarSucursal(BuildContext context, SucursalConVacantes s) =>
    mostrarHojaVidrio(context, builder: (_) => _HojaSucursal(s));

class _Cerrar extends StatelessWidget {
  const _Cerrar();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Semantics(
      button: true,
      label: 'Cerrar',
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: t.tinta.withValues(alpha: 0.07),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.close_rounded, size: 18, color: t.tintaSuave),
        ),
      ),
    );
  }
}

class _Tirador extends StatelessWidget {
  const _Tirador();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        width: 38,
        height: 5,
        decoration: BoxDecoration(
          color: context.t.tinta.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _HojaSucursal extends StatelessWidget {
  const _HojaSucursal(this.s);

  final SucursalConVacantes s;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final color = colorSucursal(s.colorIdx, oscuro: t.esOscuro);
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      children: [
        const _Tirador(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: LogoSucursal(
                    nombre: s.nombre,
                    imagenUrl: s.imagenUrl,
                    colorIdx: s.colorIdx,
                    tam: 48,
                  ),
                ),
              ),
            ),
            const Spacer(),
            const Padding(padding: EdgeInsets.only(top: 10), child: _Cerrar()),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(s.nombre, style: tt.headlineSmall),
            if (s.principal) const ChipRY('Principal'),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${plural(s.vacantesActivas, 'vacante', 'vacantes')} en esta sucursal',
          style: tt.bodySmall,
        ),
        const SizedBox(height: 16),
        DecoratedBox(
          decoration: BoxDecoration(
            color: t.tarjeta,
            borderRadius: BorderRadius.circular(radio),
            border: Border.all(color: t.linea),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Numero(numero(s.activas), 'Activas', null),
                VerticalDivider(width: 1, color: t.linea),
                _Numero(
                  numero(s.sinRanking),
                  'Sin ranking',
                  s.sinRanking > 0 ? t.naranjaProfundo : null,
                ),
                VerticalDivider(width: 1, color: t.linea),
                _Numero(numero(s.contactosUsados), 'Contactos usados', null),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (s.vacantes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Esta sucursal no tiene vacantes abiertas.',
              style: tt.bodyMedium!.copyWith(color: t.tintaSuave),
            ),
          )
        else
          for (final v in s.vacantes) ...[
            _VacanteDeSucursal(v),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _Numero extends StatelessWidget {
  const _Numero(this.valor, this.etiqueta, this.color);

  final String valor;
  final String etiqueta;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        child: Column(
          children: [
            Text(
              valor,
              style: tt.headlineSmall!.copyWith(fontSize: 22, color: color),
            ),
            const SizedBox(height: 2),
            Text(etiqueta, textAlign: TextAlign.center, style: tt.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _VacanteDeSucursal extends StatelessWidget {
  const _VacanteDeSucursal(this.v);

  final VacanteDeSucursal v;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    return Material(
      color: t.tarjeta,
      shape: formaTarjeta(radio),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          final router = GoRouter.maybeOf(context);
          Navigator.pop(context);
          router?.go('/vacantes/${v.slug}');
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            v.puesto,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.titleMedium,
                          ),
                        ),
                        if (v.estado != 'ACTIVA') ...[
                          const SizedBox(width: 6),
                          ChipRY(textoEstadoVacante(v.estado)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 4,
                      children: [
                        Text(
                          plural(v.candidatos, 'candidato', 'candidatos'),
                          style: tt.bodySmall,
                        ),
                        if (v.sinRankear > 0) ...[
                          Text('·', style: tt.bodySmall),
                          Text(
                            '${v.sinRankear} sin ranking',
                            style: tt.labelMedium!.copyWith(
                              color: t.naranjaProfundo,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(CupertinoIcons.chevron_right, size: 15, color: t.tintaTenue),
            ],
          ),
        ),
      ),
    );
  }
}

class _HojaEquipo extends StatelessWidget {
  const _HojaEquipo(this.equipo);

  final List<Persona> equipo;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      children: [
        const _Tirador(),
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Row(
            children: [
              Expanded(child: Text('Tu equipo', style: tt.headlineSmall)),
              const _Cerrar(),
            ],
          ),
        ),
        Text(
          'Quién opera cada sucursal. Las invitaciones y los cambios se hacen desde la web.',
          style: tt.bodySmall,
        ),
        const SizedBox(height: 14),
        DecoratedBox(
          decoration: BoxDecoration(
            color: t.tarjeta,
            borderRadius: BorderRadius.circular(radio),
            border: Border.all(color: t.linea),
          ),
          child: Column(
            children: [
              for (final (i, p) in equipo.indexed) ...[
                if (i > 0) Divider(height: 1, indent: 60, color: t.linea),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Row(
                    children: [
                      Iniciales(
                        p.iniciales,
                        colorIdx: p.sucursales.isEmpty
                            ? 0
                            : p.sucursales.first.colorIdx,
                        tam: 34,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.nombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tt.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              p.sucursales.isEmpty
                                  ? 'Todas las sucursales'
                                  : p.sucursales
                                        .map((x) => x.nombre)
                                        .join(', '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: tt.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (p.rol != null)
                        ChipRY(
                          p.rol!,
                          tono: p.rol == 'Dueño'
                              ? TonoChip.verde
                              : p.rol == 'Administrador'
                              ? TonoChip.azul
                              : TonoChip.neutro,
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
