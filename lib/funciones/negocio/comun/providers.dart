import 'dart:async';

// El tipo de las familias (`FutureProviderFamily`) no lo exporta flutter_riverpod 3:
// no se puede anotar, y el genérico en la llamada ya lo deja claro.
// ignore_for_file: specify_nonobvious_property_types
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/ficha_candidato.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/inicio.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/novedades.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/ranking.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/sucursales.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/vacantes.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/yo.dart';
import 'package:reclutaya_app/funciones/negocio/comun/repositorio_negocio.dart';
import 'package:reclutaya_app/nucleo/almacen/almacen_local.dart';
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

/// Las novedades de la última semana (la campana decide cuáles son nuevas).
final novedadesProvider = FutureProvider<Novedades>(
  (ref) async =>
      (await ref
              .watch(repositorioProvider)
              .novedades(
                desde: DateTime.now().subtract(const Duration(days: 7)),
              ))
          .valorOLanza,
);

/// Al abrir la app con sesión (8-oct): mientras se confirma quién es, ya se piden el
/// Inicio y la campana, y se usa el MISMO `/yo` que leerá el Inicio. Antes el arranque
/// pedía su propio `/yo`, el Inicio lo repetía y sus datos esperaban a que terminara
/// el arranque: unos 2 s en fila. `null` si `/yo` falla (el arranque decide igual que
/// antes). Recibe el `read` de quien llama (pantalla o contenedor de prueba).
Future<Yo?> yoAlArrancar(T Function<T>(ProviderListenable<T>) leer) async {
  void ignorar(Object _) {}
  unawaited(leer(inicioProvider.future).then<void>((_) {}, onError: ignorar));
  unawaited(
    leer(novedadesProvider.future).then<void>((_) {}, onError: ignorar),
  );
  try {
    return await leer(yoProvider.future);
  } on Object {
    return null;
  }
}

const _llaveVistoHasta = 'ry_novedades_visto_hasta';

/// Hasta cuándo vio el dueño las novedades, guardado en el teléfono.
class VistoHasta extends AsyncNotifier<DateTime?> {
  @override
  Future<DateTime?> build() async {
    final v = await ref.watch(almacenLocalProvider).leer(_llaveVistoHasta);
    return v == null ? null : DateTime.tryParse(v);
  }

  Future<void> marcar(DateTime hasta) async {
    state = AsyncData(hasta);
    await ref
        .read(almacenLocalProvider)
        .guardar(_llaveVistoHasta, hasta.toUtc().toIso8601String());
  }

  /// Al cerrar sesión: la cuenta siguiente empieza de cero.
  Future<void> olvidar() =>
      ref.read(almacenLocalProvider).borrar(_llaveVistoHasta);
}

final vistoHastaProvider = AsyncNotifierProvider<VistoHasta, DateTime?>(
  VistoHasta.new,
);

final vacantesCerradasProvider = FutureProvider<List<VacanteCerrada>>(
  (ref) async =>
      (await ref.watch(repositorioProvider).vacantesCerradas()).valorOLanza,
);

/// Cuánto se queda una ficha en memoria después de salir de ella (8-oct). Es un
/// provider para que las pruebas lo acorten.
final conservarFichaProvider = Provider<Duration>(
  (ref) => const Duration(minutes: 5),
);

/// Las fichas se sueltan cuando nadie las ve, pero NO al instante: se quedan
/// [conservarFichaProvider] por si se regresa (del candidato al ranking, o a la misma
/// vacante), y al volver se ven sin esperar; la pantalla las actualiza por detrás
/// (`RevalidarAlEntrar`). Así la memoria no crece con cada ficha abierta y las URLs
/// firmadas no se quedan viejas: la del candidato se vuelve a pedir si una falla.
void _conservarAlSalir(Ref ref) {
  final enlace = ref.keepAlive();
  final espera = ref.read(conservarFichaProvider);
  Timer? soltar;
  ref
    ..onCancel(() => soltar = Timer(espera, enlace.close))
    ..onResume(() => soltar?.cancel())
    ..onDispose(() => soltar?.cancel());
}

final vacanteProvider = FutureProvider.autoDispose.family<VacanteFicha, String>(
  (ref, slug) async {
    _conservarAlSalir(ref);
    return (await ref.watch(repositorioProvider).vacante(slug)).valorOLanza;
  },
);

final rankingProvider = FutureProvider.autoDispose.family<Ranking, String>((
  ref,
  slug,
) async {
  _conservarAlSalir(ref);
  return (await ref.watch(repositorioProvider).ranking(slug)).valorOLanza;
});

final candidatoProvider = FutureProvider.autoDispose
    .family<FichaCandidato, String>((ref, id) async {
      _conservarAlSalir(ref);
      return (await ref.watch(repositorioProvider).candidato(id)).valorOLanza;
    });

/// Al cerrar sesión Y al entrar: no queda NADA en memoria de otra cuenta. Se limpia
/// también al ENTRAR porque, al salir, las pantallas aún montadas vuelven a pedir sus
/// datos sin sesión y ese error se quedaba guardado para la cuenta siguiente (6-oct).
/// Vive en el contenedor, no en una pantalla. `App` lo observa. Si la salida fue por
/// vencimiento, deja el aviso para Entrar.
/// Olvida en memoria todo lo leído de una cuenta: al salir, al entrar con otra y al
/// cambiar de cuenta (varias cuentas, 8-oct). Nada de una cuenta se ve en la otra.
void limpiarDatosDeCuenta(Ref ref) {
  ref
    ..invalidate(yoProvider)
    ..invalidate(inicioProvider)
    ..invalidate(vacantesActivasProvider)
    ..invalidate(vacantesCerradasProvider)
    ..invalidate(sucursalesProvider)
    ..invalidate(novedadesProvider)
    ..invalidate(filtroSucursalProvider)
    ..invalidate(vacanteProvider)
    ..invalidate(rankingProvider)
    ..invalidate(candidatoProvider);
}

final limpiezaSesionProvider = Provider<void>((ref) {
  ref.listen(autenticadoProvider, (anterior, siguiente) {
    final antes = anterior?.value;
    final ahora = siguiente.value;
    if (ahora == null || antes == ahora) return;
    // Al entrar solo hace falta si antes hubo una salida (no en el primer arranque).
    if (ahora && antes == null) return;
    limpiarDatosDeCuenta(ref);
    if (ahora) {
      ref.invalidate(vistoHastaProvider);
    } else {
      unawaited(
        ref
            .read(vistoHastaProvider.notifier)
            .olvidar()
            .whenComplete(() => ref.invalidate(vistoHastaProvider)),
      );
    }
    if (!ahora && ref.read(sesionProvider).consumirVencimiento()) {
      ref.read(avisoAccesoProvider.notifier).aviso =
          'Tu sesión terminó. Vuelve a entrar.';
    }
  });
});
