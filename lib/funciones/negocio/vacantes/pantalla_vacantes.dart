import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reclutaya_app/funciones/negocio/comun/precarga.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/funciones/negocio/vacantes/fila_vacante.dart';
import 'package:reclutaya_app/nucleo/plataforma/adaptativos.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/ui/estados.dart';
import 'package:reclutaya_app/nucleo/vidrio/segmentado.dart';

enum EstadoLista { activas, cerradas }

/// «Vacantes»: Activas | Cerradas, con el segmentado pegado arriba al desplazar. Cada
/// fila lleva su sucursal. Las sucursales tienen su propia pestaña desde el 14-oct
/// (como el menú de la web); antes vivían aquí como un tercer segmento.
class PantallaVacantes extends ConsumerStatefulWidget {
  const PantallaVacantes({super.key});

  @override
  ConsumerState<PantallaVacantes> createState() => _PantallaVacantesState();
}

class _PantallaVacantesState extends ConsumerState<PantallaVacantes> {
  EstadoLista _elegida = EstadoLista.activas;

  Future<void> _refrescar(EstadoLista lista) async {
    ref
      ..invalidate(vacantesActivasProvider)
      ..invalidate(vacantesCerradasProvider);
    try {
      await switch (lista) {
        EstadoLista.activas => ref.read(vacantesActivasProvider.future),
        EstadoLista.cerradas => ref.read(vacantesCerradasProvider.future),
      };
    } on ErrorApi {
      // La lista ya muestra el error.
    }
  }

  @override
  Widget build(BuildContext context) {
    final lista = _elegida;
    return PaginaConTitulo(
      titulo: 'Vacantes',
      alRefrescar: () => _refrescar(lista),
      slivers: [
        SliverPersistentHeader(
          delegate: _Pegado(
            alto: MediaQuery.textScalerOf(context).scale(58),
            hijo: Segmentado<EstadoLista>(
              opciones: const {
                EstadoLista.activas: 'Activas',
                EstadoLista.cerradas: 'Cerradas',
              },
              valor: lista,
              alCambiar: (v) => setState(() => _elegida = v),
            ),
          ),
        ),
        switch (lista) {
          EstadoLista.activas => _Activas(),
          EstadoLista.cerradas => _Cerradas(),
        },
      ],
    );
  }
}

const _lados = EdgeInsets.fromLTRB(16, 4, 16, 0);

class _Activas extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lista = ref.watch(vacantesActivasProvider);
    return _conBanner(
      lista,
      lista.when(
        skipError: lista.hasValue,
        data: (vs) => vs.isEmpty
            ? const SliverToBoxAdapter(
                child: EstadoVacio(
                  titulo: 'Aún no tienes vacantes activas',
                  texto: 'Cuando publiques una, aquí la verás con su ranking.',
                ),
              )
            : SliverPadding(
                padding: _lados,
                sliver: SliverList.separated(
                  itemCount: vs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => PrecargaAlTocar.vacante(
                    vs[i].slug,
                    child: FilaVacante.activa(
                      vs[i],
                      alTocar: () => context.go('/vacantes/${vs[i].slug}'),
                    ),
                  ),
                ),
              ),
        loading: () => const _Cargando(),
        error: (e, _) => SliverToBoxAdapter(
          child: EstadoError(
            error: e is ErrorApi ? e : const Servidor(),
            alReintentar: () => ref.invalidate(vacantesActivasProvider),
          ),
        ),
      ),
    );
  }
}

class _Cerradas extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lista = ref.watch(vacantesCerradasProvider);
    return _conBanner(
      lista,
      lista.when(
        skipError: lista.hasValue,
        data: (vs) => vs.isEmpty
            ? const SliverToBoxAdapter(
                child: EstadoVacio(titulo: 'Aún no hay vacantes cerradas'),
              )
            : SliverPadding(
                padding: _lados,
                sliver: SliverList.separated(
                  itemCount: vs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => PrecargaAlTocar.vacante(
                    vs[i].slug,
                    child: FilaVacante.cerrada(
                      vs[i],
                      alTocar: () => context.go('/vacantes/${vs[i].slug}'),
                    ),
                  ),
                ),
              ),
        loading: () => const _Cargando(),
        error: (e, _) => SliverToBoxAdapter(
          child: EstadoError(
            error: e is ErrorApi ? e : const Servidor(),
            alReintentar: () => ref.invalidate(vacantesCerradasProvider),
          ),
        ),
      ),
    );
  }
}

/// Un refresco sin red no borra la lista: la conserva con el banner arriba.
Widget _conBanner(AsyncValue<Object?> v, Widget lista) {
  if (v.hasValue && v.error is SinRed) {
    return SliverMainAxisGroup(
      slivers: [
        const SliverToBoxAdapter(child: BannerSinRed()),
        lista,
      ],
    );
  }
  return lista;
}

class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: _lados,
      sliver: SliverList.separated(
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, _) => const EsqueletoFilaVacante(),
      ),
    );
  }
}

/// El segmentado, centrado sobre papel, que se queda arriba al desplazar.
class _Pegado extends SliverPersistentHeaderDelegate {
  const _Pegado({required this.alto, required this.hijo});

  final double alto;
  final Widget hijo;

  @override
  double get minExtent => alto;

  @override
  double get maxExtent => alto;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    // Sin fondo propio: el segmentado de vidrio flota sobre el degradado y la lista.
    return Center(child: hijo);
  }

  @override
  bool shouldRebuild(_Pegado old) => old.hijo != hijo || old.alto != alto;
}
