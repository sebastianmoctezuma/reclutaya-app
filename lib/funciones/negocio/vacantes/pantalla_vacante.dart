import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/vacantes.dart';
import 'package:reclutaya_app/funciones/negocio/comun/presentacion.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/nucleo/plataforma/adaptativos.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/ui/chip.dart';
import 'package:reclutaya_app/nucleo/ui/cifra.dart';
import 'package:reclutaya_app/nucleo/ui/esqueleto.dart';
import 'package:reclutaya_app/nucleo/ui/estados.dart';
import 'package:reclutaya_app/nucleo/ui/tarjeta.dart';
import 'package:reclutaya_app/nucleo/util/formato.dart';
import 'package:reclutaya_app/nucleo/vidrio/vidrio.dart';

const _lados = EdgeInsets.symmetric(horizontal: 16);

/// La ficha de una vacante: datos, conteos, descripción y preguntas, con el
/// botón «Ver ranking» flotando abajo sobre vidrio.
class PantallaVacante extends ConsumerWidget {
  const PantallaVacante({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ficha = ref.watch(vacanteProvider(slug));
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final v = ficha.value;
    final hayCandidatos = (v?.conteos.total ?? 0) > 0;

    return Stack(
      children: [
        PaginaConTitulo(
          titulo: v?.puesto ?? 'Vacante',
          alRefrescar: () async {
            ref.invalidate(vacanteProvider(slug));
            try {
              await ref.read(vacanteProvider(slug).future);
            } on ErrorApi {
              // La pantalla ya muestra el error.
            }
          },
          slivers: [
            if (ficha.hasValue && ficha.error is SinRed)
              const SliverToBoxAdapter(child: BannerSinRed()),
            ...ficha.when(
              skipError: ficha.hasValue,
              data: (v) => _cuerpo(context, v),
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
        ),
        if (v != null)
          Positioned(
            left: 20,
            right: 20,
            // Con `extendBody`, el padding inferior YA incluye la barra de pestañas.
            bottom: MediaQuery.paddingOf(context).bottom + 12,
            child: Vidrio.pastilla(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: FilledButton(
                  onPressed: hayCandidatos
                      ? () => context.go('/vacantes/$slug/ranking')
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: t.verde,
                    foregroundColor: t.tarjeta,
                    disabledBackgroundColor: t.verde.withValues(alpha: 0.35),
                    disabledForegroundColor: t.tarjeta,
                    minimumSize: const Size.fromHeight(48),
                    shape: const StadiumBorder(),
                    textStyle: tt.labelLarge!.copyWith(fontSize: 15),
                  ),
                  child: Text(
                    hayCandidatos ? 'Ver ranking' : 'Aún no hay candidatos',
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _cuerpo(BuildContext context, VacanteFicha v) {
    final tt = Theme.of(context).textTheme;
    final c = v.conteos;
    final estado = textoEstadoVacante(v.estado);
    final datos = <(String, String)>[
      if (v.ubicacion != null) ('Ubicación', v.ubicacion!),
      if (v.sueldoTexto != null) ('Sueldo', v.sueldoTexto!),
      if (v.turno != null) ('Turno', v.turno!),
      if (v.sucursal != null) ('Sucursal', v.sucursal!),
      ('Días para responder', '${v.diasParaResponder}'),
      if (v.formularioCerrado) ('Formulario', 'Cerrado'),
      if (v.cerradaAt != null) ('Cerrada el', fechaCorta(v.cerradaAt!)),
      if (v.diasParaArchivar != null)
        ('Se archiva en', '${v.diasParaArchivar} días'),
    ];
    return [
      SliverPadding(
        padding: _lados,
        sliver: SliverList.list(
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ChipRY(
                  estado,
                  tono: switch (v.estado) {
                    'ACTIVA' => TonoChip.verde,
                    'PAUSADA' => TonoChip.naranja,
                    _ => TonoChip.neutro,
                  },
                ),
                if (v.diasRestantes != null && v.estado == 'ACTIVA')
                  ChipRY(textoDiasRestantes(v.diasRestantes)!),
                if (v.huboContratacion ?? false)
                  const ChipRY('Hubo contratación', tono: TonoChip.verde),
                if (v.purgada) const ChipRY('Datos purgados'),
              ],
            ),
            const SizedBox(height: 14),
            Tarjeta(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Candidatos', style: tt.titleMedium),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 24,
                    runSpacing: 16,
                    children: [
                      _Conteo('Postulados', c.total),
                      _Conteo('En el ranking', c.rankeados),
                      _Conteo('Sin rankear', c.sinRankear),
                      if (c.pideRequisitos)
                        _Conteo('Cumplen requisitos', c.cumplenRequisitos),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Tarjeta(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Datos', style: tt.titleMedium),
                  const SizedBox(height: 6),
                  for (final (k, val) in datos) _Fila(k, val),
                ],
              ),
            ),
            if (v.descripcion != null && v.descripcion!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Tarjeta(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Descripción', style: tt.titleMedium),
                    const SizedBox(height: 8),
                    _Descripcion(v.descripcion!),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Tarjeta(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Preguntas de filtro', style: tt.titleMedium),
                  const SizedBox(height: 4),
                  if (v.preguntas.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Sin preguntas de filtro.',
                        style: tt.bodySmall,
                      ),
                    )
                  else
                    for (final (i, p) in v.preguntas.indexed)
                      _Pregunta(i + 1, p),
                ],
              ),
            ),
            const SizedBox(height: 72),
          ],
        ),
      ),
    ];
  }
}

class _Conteo extends StatelessWidget {
  const _Conteo(this.etiqueta, this.n);

  final String etiqueta;
  final int n;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: Cifra(valor: numero(n), etiqueta: etiqueta),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila(this.k, this.v);

  final String k;
  final String v;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.linea)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(k, style: tt.bodySmall)),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(v, style: tt.labelLarge, textAlign: TextAlign.end),
          ),
        ],
      ),
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

/// La descripción, plegada a seis líneas con «Ver más».
class _Descripcion extends StatefulWidget {
  const _Descripcion(this.texto);

  final String texto;

  @override
  State<_Descripcion> createState() => _DescripcionState();
}

class _DescripcionState extends State<_Descripcion> {
  bool _todo = false;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final larga = widget.texto.length > 280;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.texto,
          style: tt.bodyMedium!.copyWith(height: 1.6),
          maxLines: _todo ? null : 6,
          overflow: _todo ? null : TextOverflow.ellipsis,
        ),
        if (larga && !_todo)
          GestureDetector(
            onTap: () => setState(() => _todo = true),
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Ver más',
                style: tt.labelMedium!.copyWith(color: t.verdeProfundo),
              ),
            ),
          ),
      ],
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
