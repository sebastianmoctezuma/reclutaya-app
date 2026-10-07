import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/funciones/negocio/inicio/inicio_core.dart';
import 'package:reclutaya_app/funciones/negocio/vacantes/fila_vacante.dart';
import 'package:reclutaya_app/funciones/negocio/vacantes/por_sucursal.dart';
import 'package:reclutaya_app/nucleo/plataforma/adaptativos.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/ui/estados.dart';
import 'package:reclutaya_app/nucleo/vidrio/segmentado.dart';

enum EstadoLista { sucursales, activas, cerradas }

/// Activas | Cerradas. El segmentado queda pegado arriba al desplazar. Con varias
/// sucursales la pestaña se llama «Sucursales» (como en la web) y las activas se
/// agrupan por sucursal.
class PantallaVacantes extends ConsumerStatefulWidget {
  const PantallaVacantes({super.key});

  @override
  ConsumerState<PantallaVacantes> createState() => _PantallaVacantesState();
}

class _PantallaVacantesState extends ConsumerState<PantallaVacantes> {
  /// null = el de entrada: «Sucursales» si la cuenta tiene varias, si no «Activas».
  EstadoLista? _elegida;

  Future<void> _refrescar(EstadoLista lista) async {
    ref
      ..invalidate(vacantesActivasProvider)
      ..invalidate(vacantesCerradasProvider)
      ..invalidate(sucursalesProvider);
    try {
      await switch (lista) {
        EstadoLista.sucursales => ref.read(sucursalesProvider.future),
        EstadoLista.activas => ref.read(vacantesActivasProvider.future),
        EstadoLista.cerradas => ref.read(vacantesCerradasProvider.future),
      };
    } on ErrorApi {
      // La lista ya muestra el error.
    }
  }

  @override
  Widget build(BuildContext context) {
    final multi = ref.watch(yoProvider).value?.variasSucursales ?? false;
    var lista =
        _elegida ?? (multi ? EstadoLista.sucursales : EstadoLista.activas);
    if (!multi && lista == EstadoLista.sucursales) lista = EstadoLista.activas;
    return PaginaConTitulo(
      // Con varias sucursales el selector ya dice dónde estás: sin título arriba.
      titulo: multi ? '' : nombrePestanaVacantes(variasSucursales: multi),
      alRefrescar: () => _refrescar(lista),
      slivers: [
        SliverPersistentHeader(
          delegate: _Pegado(
            alto: MediaQuery.textScalerOf(context).scale(58),
            hijo: Segmentado<EstadoLista>(
              opciones: {
                if (multi) EstadoLista.sucursales: 'Sucursales',
                EstadoLista.activas: multi ? 'Vacantes' : 'Activas',
                EstadoLista.cerradas: 'Cerradas',
              },
              valor: lista,
              alCambiar: (v) => setState(() => _elegida = v),
            ),
          ),
        ),
        switch (lista) {
          EstadoLista.sucursales => VacantesPorSucursal(
            alternativa: _Activas(),
          ),
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
                  texto:
                      'Publícala desde la web y aquí la verás con su ranking.',
                ),
              )
            : SliverPadding(
                padding: _lados,
                sliver: SliverList.separated(
                  itemCount: vs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => FilaVacante.activa(
                    vs[i],
                    alTocar: () => context.go('/vacantes/${vs[i].slug}'),
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
                  itemBuilder: (context, i) => FilaVacante.cerrada(
                    vs[i],
                    alTocar: () => context.go('/vacantes/${vs[i].slug}'),
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
