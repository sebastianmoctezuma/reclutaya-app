import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/funciones/negocio/novedades/avisos_core.dart';
import 'package:reclutaya_app/nucleo/almacen/almacen_local.dart';
import 'package:reclutaya_app/nucleo/push/servicio_avisos.dart';
import 'package:reclutaya_app/nucleo/rutas/rutas.dart';
import 'package:reclutaya_app/nucleo/sesion/providers.dart';

const _llaveActivos = 'ry_avisos_activos';

class EstadoAvisos {
  const EstadoAvisos({
    required this.disponible,
    required this.activos,
    this.token,
  });

  /// ¿Hay avisos en esta compilación (Firebase configurado)?
  final bool disponible;

  /// El interruptor de este teléfono.
  final bool activos;
  final String? token;

  EstadoAvisos con({bool? activos, String? token}) => EstadoAvisos(
    disponible: disponible,
    activos: activos ?? this.activos,
    token: token ?? this.token,
  );
}

/// Los avisos al celular de este teléfono (7-oct): lo registra al entrar (con el
/// interruptor como lo dejó la persona), lo vuelve a registrar si Firebase rota el
/// token, lo prende o apaga, y lo da de baja al cerrar sesión. Nunca bloquea: si el
/// servidor no contesta, la app sigue.
class ControladorAvisos extends AsyncNotifier<EstadoAvisos> {
  StreamSubscription<String>? _rotacion;

  ServicioAvisos get _avisos => ref.read(servicioAvisosProvider);

  @override
  Future<EstadoAvisos> build() async {
    ref.onDispose(() => _rotacion?.cancel());
    final guardado = await ref.read(almacenLocalProvider).leer(_llaveActivos);
    return EstadoAvisos(
      disponible: _avisos.disponible,
      activos: guardado != 'no',
    );
  }

  Future<EstadoAvisos> _estado() async => state.value ?? await future;

  Future<void> alEntrar() async {
    final e = await _estado();
    if (!e.disponible) return;
    final token = await _avisos.pedirPermisoYToken();
    if (token == null) return;
    await _registrar(token, e.activos);
    await _rotacion?.cancel();
    _rotacion = _avisos.tokensNuevos.listen(
      (nuevo) => unawaited(_registrar(nuevo, state.value?.activos ?? true)),
    );
  }

  Future<void> _registrar(String token, bool activos) async {
    await ref
        .read(repositorioProvider)
        .registrarDispositivo(
          token: token,
          plataforma: _avisos.plataforma,
          activos: activos,
        );
    state = AsyncData((await _estado()).con(token: token));
  }

  Future<void> cambiar({required bool activos}) async {
    final e = await _estado();
    state = AsyncData(e.con(activos: activos));
    await ref
        .read(almacenLocalProvider)
        .guardar(_llaveActivos, activos ? 'si' : 'no');
    final token = e.token;
    if (token == null) return;
    await ref
        .read(repositorioProvider)
        .cambiarAvisos(
          token: token,
          plataforma: _avisos.plataforma,
          activos: activos,
        );
  }

  /// Antes de cerrar sesión (con la sesión todavía válida). Con tiempo límite: salir
  /// nunca espera al servidor más de unos segundos.
  Future<void> alSalir() async {
    await _rotacion?.cancel();
    final token = state.value?.token;
    if (token == null) return;
    try {
      await ref
          .read(repositorioProvider)
          .bajaDispositivo(token: token, plataforma: _avisos.plataforma)
          .timeout(const Duration(seconds: 4));
    } on TimeoutException {
      // El teléfono queda registrado; el servidor lo da de baja cuando su token falle.
    }
  }
}

final controladorAvisosProvider =
    AsyncNotifierProvider<ControladorAvisos, EstadoAvisos>(
      ControladorAvisos.new,
    );

/// Une los avisos con la sesión y la navegación: al ENTRAR registra el teléfono, y al
/// tocar un aviso (con la app abierta, en segundo plano o cerrada) abre lo que dice.
/// `App` lo observa, como la limpieza de sesión.
final avisosSesionProvider = Provider<void>((ref) {
  final avisos = ref.watch(servicioAvisosProvider);
  if (!avisos.disponible) return;
  ref.listen(autenticadoProvider, (antes, ahora) {
    if (ahora.value == true && antes?.value != true) {
      unawaited(ref.read(controladorAvisosProvider.notifier).alEntrar());
    }
  }, fireImmediately: true);
  void abrir(Map<String, dynamic>? datos) {
    if (datos == null) return;
    final ruta = rutaDeAviso(datos);
    if (ruta == null) return;
    ref.invalidate(novedadesProvider);
    ref.read(routerProvider).go(ruta);
  }

  final sub = avisos.tocados.listen(abrir);
  ref.onDispose(sub.cancel);
  unawaited(avisos.tocadoAlAbrir().then(abrir));
});
