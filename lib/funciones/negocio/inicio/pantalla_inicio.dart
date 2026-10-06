import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/inicio.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/yo.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/funciones/negocio/inicio/inicio_core.dart';
import 'package:reclutaya_app/funciones/negocio/inicio/secciones/comunes.dart';
import 'package:reclutaya_app/funciones/negocio/inicio/secciones/consumo.dart';
import 'package:reclutaya_app/funciones/negocio/inicio/secciones/encabezado.dart';
import 'package:reclutaya_app/funciones/negocio/inicio/secciones/filtro_sucursal.dart';
import 'package:reclutaya_app/funciones/negocio/inicio/secciones/listas.dart';
import 'package:reclutaya_app/funciones/negocio/inicio/secciones/vistazo.dart';
import 'package:reclutaya_app/funciones/negocio/inicio/tarjetas_indicadores.dart';
import 'package:reclutaya_app/nucleo/plataforma/adaptativos.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/ui/esqueleto.dart';
import 'package:reclutaya_app/nucleo/ui/estados.dart';

/// Inicio: el mismo tablero del panel web, en orden y con sus mismos números, pero
/// como listas agrupadas de iOS. Pura vista: sin «Crear vacante», campana, «Generar»
/// ni «Agregar sucursal». Lo que solo ve Pro o una cuenta multisucursal llega `null`
/// del servidor y aquí simplemente no se pinta; con un servidor anterior queda lo de
/// siempre (encabezado, saldo, indicadores y vacantes activas).
class PantallaInicio extends ConsumerWidget {
  const PantallaInicio({super.key});

  Future<void> _refrescar(WidgetRef ref) async {
    ref
      ..invalidate(yoProvider)
      ..invalidate(inicioProvider)
      ..invalidate(vacantesActivasProvider);
    try {
      await ref.read(inicioProvider.future);
    } on ErrorApi {
      // La pantalla ya muestra el error.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yo = ref.watch(yoProvider).value;
    final inicio = ref.watch(inicioProvider);
    return PaginaConTitulo(
      titulo: 'Inicio',
      alRefrescar: () => _refrescar(ref),
      slivers: [
        if (inicio.hasValue && inicio.error is SinRed)
          const SliverToBoxAdapter(child: BannerSinRed()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          sliver: SliverToBoxAdapter(
            child: _Encabezado(yo: yo, negocio: inicio.value?.negocio),
          ),
        ),
        ...inicio.when(
          skipError: inicio.hasValue,
          data: _secciones,
          loading: () => const [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 26, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Esqueleto(alto: 220, radio: radioGrande),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 26, 16, 0),
              sliver: EsqueletoIndicadores(),
            ),
          ],
          error: (e, _) => [
            SliverToBoxAdapter(
              child: EstadoError(
                error: e is ErrorApi ? e : const Servidor(),
                alReintentar: () => ref.invalidate(inicioProvider),
              ),
            ),
          ],
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  List<Widget> _secciones(Inicio i) {
    final sucursales = i.sucursales ?? const <SucursalInicio>[];
    final consumo = i.consumo;
    final pendientes = i.pendientes;
    final embudo = i.proceso?.total;
    final actividad = i.actividad;
    return [
      if (Vistazo.hayAlgo(i.resumen, i.saldo))
        SliverSeccion(
          titulo: 'De un vistazo',
          hijo: Vistazo(resumen: i.resumen, saldo: i.saldo),
        ),
      _Indicadores(inicio: i),
      if (consumo != null && sucursales.isNotEmpty)
        SliverSeccion(
          titulo: 'Consumo de contactos por sucursal',
          hijo: ConsumoSucursales(
            sucursales: sucursales,
            resto: consumo.resto,
            disponibles: consumo.disponibles,
            ilimitada: i.resumen?.ilimitada ?? false,
          ),
        ),
      if (sucursales.isNotEmpty)
        SliverSeccion(
          titulo: 'Tus sucursales',
          hijo: TusSucursales(sucursales: sucursales),
        ),
      if (pendientes != null)
        SliverSeccion(
          titulo: 'Pendientes',
          hijo: Pendientes(items: pendientes),
        ),
      if (embudo != null) _ProcesoFiltrado(inicio: i),
      if (actividad != null)
        SliverSeccion(
          titulo: 'Actividad reciente',
          hijo: Actividad(eventos: actividad),
        ),
      _VacantesEnCurso(inicio: i),
    ];
  }
}

/// El encabezado verde: con el servidor nuevo usa el negocio de `/inicio` (con su
/// giro y ciudad); si no, el de `/yo`.
class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.yo, required this.negocio});

  final Yo? yo;
  final NegocioInicio? negocio;

  @override
  Widget build(BuildContext context) {
    final nombre = negocio?.nombre ?? yo?.empresa?.nombre;
    if (nombre == null) return const Esqueleto(alto: 100, radio: radioGrande);
    final pila = yo?.nombre?.trim().split(RegExp(r'\s+')).first ?? '';
    return EncabezadoNegocio(
      nombre: nombre,
      saludo: pila.isEmpty ? 'Hola' : 'Hola, $pila',
      meta: negocio?.meta ?? '',
      logoUrl: negocio?.logoUrl ?? yo?.empresa?.logoUrl,
      logoFit: negocio?.logoFit ?? yo?.empresa?.logoFit,
    );
  }
}

/// «Últimos 30 días»: los cuatro indicadores, con el filtro de sucursal si la cuenta
/// tiene varias (los de cada sucursal ya vienen calculados del servidor).
class _Indicadores extends ConsumerWidget {
  const _Indicadores({required this.inicio});

  final Inicio inicio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sucursales = inicio.sucursales ?? const <SucursalInicio>[];
    final filtrable =
        inicio.indicadoresPorSucursal != null && sucursales.length > 1;
    final id = filtrable ? ref.watch(filtroSucursalProvider) : null;
    return SliverMainAxisGroup(
      slivers: [
        const SliverPadding(
          padding: ladosInicio,
          sliver: SliverToBoxAdapter(child: TituloSeccion('Últimos 30 días')),
        ),
        if (filtrable)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            sliver: SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FiltroSucursalPastilla(sucursales: sucursales),
              ),
            ),
          ),
        SliverPadding(
          padding: ladosInicio,
          sliver: TarjetasIndicadores(k: indicadoresDe(inicio, id)),
        ),
      ],
    );
  }
}

class _ProcesoFiltrado extends ConsumerWidget {
  const _ProcesoFiltrado({required this.inicio});

  final Inicio inicio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ref.watch(filtroSucursalProvider);
    final embudo = embudoDe(inicio, id) ?? inicio.proceso!.total;
    return SliverSeccion(
      titulo: 'Tu proceso · 30 días',
      hijo: Proceso(embudo: embudo),
    );
  }
}

/// «Vacantes en curso»: las del servidor nuevo (con su siguiente paso) o, con uno
/// anterior, las activas de `/vacantes`.
class _VacantesEnCurso extends ConsumerWidget {
  const _VacantesEnCurso({required this.inicio});

  final Inicio inicio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final propias = inicio.vacantes;
    final activas = propias == null ? ref.watch(vacantesActivasProvider) : null;
    final lista = propias ?? activas?.value;
    final conSucursal = (inicio.sucursales?.length ?? 0) > 1;
    return SliverSeccion(
      titulo: 'Vacantes en curso',
      extra: (lista?.isNotEmpty ?? false)
          ? TextButton(
              onPressed: () => GoRouter.maybeOf(context)?.go('/vacantes'),
              child: Text(
                'Ver todas',
                style: Theme.of(context).textTheme.labelLarge!
                    .copyWith(color: t.verdeProfundo),
              ),
            )
          : null,
      hijo: lista == null
          ? (activas?.hasError ?? false)
                ? const SizedBox.shrink()
                : const Esqueleto(alto: 160, radio: radioGrande)
          : VacantesEnCurso(vacantes: lista, conSucursal: conSucursal),
    );
  }
}
