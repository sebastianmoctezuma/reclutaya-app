// El tipo de las familias (`FutureProviderFamily`) no lo exporta flutter_riverpod 3:
// no se puede anotar, y el genérico en la llamada ya lo deja claro.
// ignore_for_file: specify_nonobvious_property_types
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/ficha_candidato.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/inicio.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/ranking.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/sucursales.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/vacantes.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/yo.dart';
import 'package:reclutaya_app/funciones/negocio/comun/repositorio_negocio.dart';
import 'package:reclutaya_app/nucleo/sesion/providers.dart';
import 'package:reclutaya_app/nucleo/util/resultado.dart';

/// Riverpod 3 reintenta solo los providers que fallan (hasta diez veces, con
/// esperas crecientes). Eso golpearía la API ante un 500 y deja el `future`
/// colgado mientras tanto; los reintentos ya los decide `ClienteApi`.
/// Se pasa como `retry:` al ProviderScope y a los contenedores de prueba.
Duration? sinReintentos(int reintento, Object error) => null;

final repositorioProvider = Provider<RepositorioNegocio>(
  (ref) => RepositorioNegocioApi(ref.watch(clienteApiProvider)),
);

// Nada se guarda en disco: vive en MEMORIA y solo mientras hay sesión
// (`olvidarTodo` al salir).
// Al refrescar, Riverpod conserva el valor anterior mientras llega el nuevo:
// quien ya veía datos nunca vuelve a ver esqueletos.
final yoProvider = FutureProvider<Yo>(
  (ref) async => (await ref.watch(repositorioProvider).yo()).valorOLanza,
);

final inicioProvider = FutureProvider<Inicio>(
  (ref) async => (await ref.watch(repositorioProvider).inicio()).valorOLanza,
);

final vacantesActivasProvider = FutureProvider<List<VacanteResumen>>(
  (ref) async =>
      (await ref.watch(repositorioProvider).vacantesActivas()).valorOLanza,
);

final sucursalesProvider = FutureProvider<Sucursales>(
  (ref) async =>
      (await ref.watch(repositorioProvider).sucursales()).valorOLanza,
);

/// La sucursal elegida en el filtro del Inicio (null = todas). Se olvida al salir.
class FiltroSucursal extends Notifier<String?> {
  @override
  String? build() => null;

  String? get valor => state;
  set valor(String? id) => state = id;
}

final filtroSucursalProvider = NotifierProvider<FiltroSucursal, String?>(
  FiltroSucursal.new,
);

final vacantesCerradasProvider = FutureProvider<List<VacanteCerrada>>(
  (ref) async =>
      (await ref.watch(repositorioProvider).vacantesCerradas()).valorOLanza,
);

// Las fichas se SUELTAN sin oyentes (autoDispose): al volver se piden de nuevo,
// con URLs firmadas frescas, y la memoria no crece con cada ficha abierta.
final vacanteProvider = FutureProvider.autoDispose.family<VacanteFicha, String>(
  (ref, slug) async =>
      (await ref.watch(repositorioProvider).vacante(slug)).valorOLanza,
);

final rankingProvider = FutureProvider.autoDispose.family<Ranking, String>(
  (ref, slug) async =>
      (await ref.watch(repositorioProvider).ranking(slug)).valorOLanza,
);

final candidatoProvider = FutureProvider.autoDispose
    .family<FichaCandidato, String>(
      (ref, id) async =>
          (await ref.watch(repositorioProvider).candidato(id)).valorOLanza,
    );

/// Al cerrar sesión (voluntaria o vencida): no queda NADA en memoria de la
/// cuenta anterior. Vive en el contenedor, no en una pantalla: la pantalla que
/// pide salir se desmonta antes de que termine `salir()`. `App` lo observa.
/// Si la salida fue por vencimiento, deja el aviso para Entrar.
final limpiezaSesionProvider = Provider<void>((ref) {
  ref.listen(autenticadoProvider, (_, siguiente) {
    if (siguiente.value != false) return;
    ref
      ..invalidate(yoProvider)
      ..invalidate(inicioProvider)
      ..invalidate(vacantesActivasProvider)
      ..invalidate(vacantesCerradasProvider)
      ..invalidate(sucursalesProvider)
      ..invalidate(filtroSucursalProvider)
      ..invalidate(vacanteProvider)
      ..invalidate(rankingProvider)
      ..invalidate(candidatoProvider);
    if (ref.read(sesionProvider).consumirVencimiento()) {
      ref.read(avisoAccesoProvider.notifier).aviso =
          'Tu sesión terminó. Vuelve a entrar.';
    }
  });
});
