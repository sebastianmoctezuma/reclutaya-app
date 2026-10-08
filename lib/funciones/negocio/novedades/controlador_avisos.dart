import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reclutaya_app/funciones/cuentas/gestor_cuentas.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/funciones/negocio/novedades/avisos_core.dart';
import 'package:reclutaya_app/nucleo/almacen/almacen_local.dart';
import 'package:reclutaya_app/nucleo/push/servicio_avisos.dart';
import 'package:reclutaya_app/nucleo/rutas/rutas.dart';
import 'package:reclutaya_app/nucleo/sesion/cuentas_core.dart';
import 'package:reclutaya_app/nucleo/sesion/providers.dart';
import 'package:reclutaya_app/nucleo/ui/mensaje_global.dart';

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
    // El interruptor es de CADA cuenta (varias cuentas, 8-oct); sin cuenta confirmada
    // todavía, el del teléfono.
    final deLaCuenta = await ref
        .read(gestorCuentasProvider.notifier)
        .avisosActiva();
    final guardado = await ref.read(almacenLocalProvider).leer(_llaveActivos);
    return EstadoAvisos(
      disponible: _avisos.disponible,
      activos: deLaCuenta ?? guardado != 'no',
    );
  }

  Future<EstadoAvisos> _estado() async => state.value ?? await future;

  /// Registra el teléfono para la cuenta activa. Con `reconfirmar`, además renueva y
  /// reconfirma las demás cuentas guardadas (al abrir; al cambiar de cuenta no hace
  /// falta).
  Future<void> alEntrar({bool reconfirmar = true}) async {
    final e = await _estado();
    if (!e.disponible) return;
    final token = await _avisos.pedirPermisoYToken();
    if (token == null || !ref.mounted) return;
    await _registrar(token, e.activos);
    if (!ref.mounted) return;
    if (reconfirmar) {
      unawaited(
        ref
            .read(gestorCuentasProvider.notifier)
            .reconfirmarInactivas(token)
            .then((perdidas) {
              for (final n in perdidas) {
                mostrarMensaje(
                  ref,
                  'La sesión de $n terminó. Vuelve a entrar.',
                );
              }
            }),
      );
    }
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
    if (!ref.mounted) return;
    state = AsyncData((await _estado()).con(token: token));
  }

  Future<void> cambiar({required bool activos}) async {
    final e = await _estado();
    state = AsyncData(e.con(activos: activos));
    await ref
        .read(almacenLocalProvider)
        .guardar(_llaveActivos, activos ? 'si' : 'no');
    await ref
        .read(gestorCuentasProvider.notifier)
        .marcarAvisosActiva(activos: activos);
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

  /// Al perder la sesión por CUALQUIER camino (cerrar sesión, sesión vencida, una
  /// cuenta del otro lado): deja de escuchar la rotación y borra el token en el
  /// teléfono. No toca el servidor: la sesión puede ya no servir.
  Future<void> alPerderSesion() async {
    await _rotacion?.cancel();
    _rotacion = null;
    await _avisos.olvidarToken();
    final e = state.value;
    if (e != null) {
      state = AsyncData(
        EstadoAvisos(disponible: e.disponible, activos: e.activos),
      );
    }
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
    final avisosCtl = ref.read(controladorAvisosProvider.notifier);
    if (ahora.value == true && antes?.value != true) {
      unawaited(avisosCtl.alEntrar());
    } else if (ahora.value == false && antes?.value == true) {
      unawaited(avisosCtl.alPerderSesion());
    }
  }, fireImmediately: true);
  Future<void> abrir(Map<String, dynamic>? datos) async {
    if (datos == null) return;
    final ruta = rutaDeAviso(datos);
    if (ruta == null) return;
    final gestor = ref.read(gestorCuentasProvider.notifier);
    final cuentas = await ref.read(gestorCuentasProvider.future);
    final deCuenta = datos['usuarioId'];
    final accion = accionAviso(
      activa: cuentas.firstOrNull?.usuarioId,
      usuarioIdAviso: deCuenta is String ? deCuenta : null,
      cuentas: cuentas,
    );
    final router = ref.read(routerProvider);
    switch (accion) {
      case AccionAviso.abrir:
        ref.invalidate(novedadesProvider);
        router.go(ruta);
      case AccionAviso.inicio:
        router.go('/inicio');
      case AccionAviso.cambiarYAbrir:
        final negocio = await gestor.cambiarA(deCuenta as String);
        if (negocio == null) {
          router.go('/inicio');
          return;
        }
        router.go(ruta);
        mostrarMensaje(ref, 'Cambiaste a $negocio');
    }
  }

  final sub = avisos.tocados.listen((d) => unawaited(abrir(d)));
  ref.onDispose(sub.cancel);
  unawaited(avisos.tocadoAlAbrir().then(abrir));
});

/// LA salida de la app (7-oct): primero da de baja el teléfono en el servidor (con la
/// sesión aún válida y con tiempo límite), luego borra el token en el teléfono y al
/// final cierra la sesión. Nadie llama `sesion.salir()` directo: lo vigila
/// `test/nucleo/sesion/salida_unica_test.dart`.
final cerrarSesionProvider = Provider<Future<void> Function()>(
  (ref) => () async {
    // Con otra cuenta guardada, «salir» es quitar esta y pasar a la otra (8-oct).
    if (await ref.read(gestorCuentasProvider.notifier).quitarActiva()) return;
    final avisos = ref.read(controladorAvisosProvider.notifier);
    await avisos.alSalir();
    await avisos.alPerderSesion();
    await ref.read(sesionProvider).salir();
  },
);
