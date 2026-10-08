import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/yo.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/funciones/negocio/comun/repositorio_negocio.dart';
import 'package:reclutaya_app/funciones/negocio/novedades/controlador_avisos.dart';
import 'package:reclutaya_app/nucleo/almacen/almacen_local.dart';
import 'package:reclutaya_app/nucleo/config.dart';
import 'package:reclutaya_app/nucleo/push/servicio_avisos.dart';
import 'package:reclutaya_app/nucleo/red/cliente_api.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/sesion/cuentas_core.dart';
import 'package:reclutaya_app/nucleo/sesion/providers.dart';
import 'package:reclutaya_app/nucleo/sesion/sesion.dart';
import 'package:reclutaya_app/nucleo/ui/mensaje_global.dart';

const _llave = 'ry_cuentas';

/// Una sesión fija (la de una cuenta INACTIVA, recién renovada), para reconfirmar su
/// teléfono sin volverla la activa.
class _TokenFijo implements ProveedorToken {
  const _TokenFijo(this.token);

  @override
  final String token;
  @override
  Future<String?> renovar() async => null;
  @override
  Future<void> sesionVencida() async {}
}

/// El repositorio con la sesión de otra cuenta (se sobreescribe en pruebas).
final repositorioConTokenProvider =
    Provider<RepositorioNegocio Function(String acceso)>(
      (_) =>
          (acceso) => RepositorioNegocioApi(
            ClienteApi(base: Config.apiBase, tokens: _TokenFijo(acceso)),
          ),
    );

/// ¿Se está agregando una cuenta? (la pantalla de Entrar se vuelve «Agregar cuenta»).
class AgregandoCuenta extends Notifier<bool> {
  @override
  bool build() => false;

  bool get valor => state;
  set valor(bool v) => state = v;
}

final agregandoCuentaProvider = NotifierProvider<AgregandoCuenta, bool>(
  AgregandoCuenta.new,
);

/// Varias cuentas en el mismo teléfono (8-oct). Guarda en el llavero cada cuenta con su
/// sesión; la activa va primero. Cambiar NO cierra la sesión anterior (la invalidaría):
/// guarda su token vivo y usa el de la otra. Quitar la última es el cierre de siempre.
/// Diseño: docs/superpowers/specs/2026-10-07-multicuenta-design.md.
class GestorCuentas extends AsyncNotifier<List<CuentaGuardada>> {
  /// La cuenta que de verdad está activa (la confirmó `/yo`). null = sesión
  /// desconocida (p. ej. a media alta de otra cuenta).
  String? _activa;
  String? _previa;

  /// Las operaciones van en FILA: los tokens de Supabase rotan en cada uso, y dos
  /// operaciones a la vez (p. ej. reconfirmar al abrir y quitar una cuenta) usarían un
  /// token que la otra ya gastó.
  Future<void> _fila = Future<void>.value();

  Future<T> _enFila<T>(Future<T> Function() trabajo) {
    final r = _fila.then((_) => trabajo());
    _fila = r.then<void>((_) {}, onError: (_) {});
    return r;
  }

  AlmacenLocal get _almacen => ref.read(almacenLocalProvider);
  Sesion get _sesion => ref.read(sesionProvider);

  @override
  Future<List<CuentaGuardada>> build() async =>
      cuentasDesdeJson(await _almacen.leer(_llave));

  Future<List<CuentaGuardada>> _lista() async => state.value ?? await future;

  Future<void> _guardar(List<CuentaGuardada> l) async {
    state = AsyncData(l);
    await _almacen.guardar(_llave, cuentasAJson(l));
  }

  bool get puedeAgregar => (state.value?.length ?? 0) < maxCuentas;

  /// La activa con su token VIVO: Supabase lo rota, y el guardado envejece.
  Future<List<CuentaGuardada>> _conActivaAlDia() async {
    final l = await _lista();
    final r = _sesion.refreshToken;
    if (l.isEmpty || r == null || l.first.usuarioId != _activa) return l;
    return [l.first.con(refreshToken: r), ...l.skip(1)];
  }

  /// Tras confirmar con `/yo` quién entró (arranque, entrar, agregar).
  Future<void> recordarActiva(Yo yo) => _enFila(() => _recordarActiva(yo));

  Future<void> _recordarActiva(Yo yo) async {
    final id = yo.usuarioId;
    final refresh = _sesion.refreshToken;
    final empresa = yo.empresa;
    if (id == null || refresh == null || empresa == null) return;
    final l = await _lista();
    final previa = l.where((c) => c.usuarioId == id).firstOrNull;
    final r = agregarCuenta(
      l,
      CuentaGuardada(
        usuarioId: id,
        negocio: empresa.nombre,
        correo: _sesion.correo,
        logoUrl: empresa.logoUrl,
        logoFit: empresa.logoFit,
        refreshToken: refresh,
        avisos: previa?.avisos ?? true,
      ),
    );
    _activa = id;
    _previa = null;
    ref.read(agregandoCuentaProvider.notifier).valor = false;
    if (!r.lleno) await _guardar(r.lista);
  }

  /// Cambia a otra cuenta guardada. Devuelve su negocio, o null si no se pudo (sin
  /// red: no se pierde nada; sesión que ya no vale: esa cuenta sale de la lista).
  Future<String?> cambiarA(String id) => _enFila(() => _cambiarA(id));

  Future<String?> _cambiarA(String id) async {
    final l = await _conActivaAlDia();
    final destino = l.where((c) => c.usuarioId == id).firstOrNull;
    if (destino == null) return null;
    if (_activa == id) return destino.negocio;
    final bool ok;
    try {
      ok = await _sesion.usarCuenta(destino.refreshToken);
    } on SinRed {
      await _guardar(l);
      return null;
    }
    if (!ok) {
      await _guardar(quitarCuenta(l, id));
      return null;
    }
    await _guardar([
      destino.con(refreshToken: _sesion.refreshToken),
      ...l.where((c) => c.usuarioId != id),
    ]);
    _activa = id;
    await _alCambiar();
    return destino.negocio;
  }

  /// Nada de la cuenta anterior se queda en memoria, y el teléfono queda registrado
  /// (y con su interruptor) para la nueva.
  Future<void> _alCambiar() async {
    limpiarDatosDeCuenta(ref);
    await ref.read(vistoHastaProvider.notifier).olvidar();
    ref
      ..invalidate(vistoHastaProvider)
      ..invalidate(controladorAvisosProvider);
    await ref.read(controladorAvisosProvider.future);
    unawaited(
      ref.read(controladorAvisosProvider.notifier).alEntrar(reconfirmar: false),
    );
  }

  /// «Quitar esta cuenta»: la saca de la lista y, si hay otra, pasa a ella (true). Si
  /// era la última o no se pudo pasar a otra, false: quien llama cierra la sesión.
  Future<bool> quitarActiva() => _enFila(_quitarActiva);

  Future<bool> _quitarActiva() async {
    final l = await _conActivaAlDia();
    if (l.isEmpty || _activa == null || l.first.usuarioId != _activa) {
      return false;
    }
    var resto = l.skip(1).toList();
    if (resto.isEmpty) {
      _activa = null;
      await _guardar(const []);
      return false;
    }
    // La baja de ESTE teléfono para ESTA cuenta, con su sesión aún válida.
    await ref.read(controladorAvisosProvider.notifier).alSalir();
    final acceso = _sesion.token;
    while (resto.isNotEmpty) {
      final sig = resto.first;
      bool ok;
      try {
        ok = await _sesion.usarCuenta(sig.refreshToken);
      } on SinRed {
        // Sin red no se puede pasar a otra: se cierra esta y las demás se quedan.
        _activa = null;
        await _guardar(resto);
        return false;
      }
      if (!ok) {
        resto = resto.skip(1).toList();
        continue;
      }
      if (acceso != null) await _sesion.revocar(acceso);
      await _guardar([
        sig.con(refreshToken: _sesion.refreshToken),
        ...resto.skip(1),
      ]);
      _activa = sig.usuarioId;
      await _alCambiar();
      return true;
    }
    _activa = null;
    await _guardar(const []);
    return false;
  }

  /// «Cerrar todas las sesiones»: revoca las inactivas y cierra la activa.
  Future<void> cerrarTodas() async {
    await _enFila(_revocarInactivas);
    await ref.read(cerrarSesionProvider)();
  }

  Future<void> _revocarInactivas() async {
    final l = await _conActivaAlDia();
    for (final c in l.skip(1)) {
      try {
        final r = await _sesion.renovarAparte(c.refreshToken);
        if (r != null) await _sesion.revocar(r.acceso);
      } on SinRed {
        // Sin red: esa sesión caduca sola; el teléfono igual olvida su token.
      }
    }
    await _guardar(l.isEmpty ? const [] : [l.first]);
  }

  /// La activa venció sin rescate: sale de la lista y, si hay otra, se pasa a ella en
  /// vez de mandar al dueño al login.
  Future<void> alVencerActiva() => _enFila(_alVencerActiva);

  Future<void> _alVencerActiva() async {
    final l = await _lista();
    final muerta = l.where((c) => c.usuarioId == _activa).firstOrNull;
    var resto = muerta == null ? l : quitarCuenta(l, muerta.usuarioId);
    while (muerta != null && resto.isNotEmpty) {
      final sig = resto.first;
      bool ok;
      try {
        ok = await _sesion.usarCuenta(sig.refreshToken);
      } on SinRed {
        break;
      }
      if (!ok) {
        resto = resto.skip(1).toList();
        continue;
      }
      await _guardar([
        sig.con(refreshToken: _sesion.refreshToken),
        ...resto.skip(1),
      ]);
      _activa = sig.usuarioId;
      await _alCambiar();
      mostrarMensaje(
        ref,
        'La sesión de ${muerta.negocio} terminó. Cambiaste a ${sig.negocio}.',
      );
      return;
    }
    _activa = null;
    await _guardar(resto);
    await _sesion.salirPorVencimiento();
  }

  /// Al abrir: cada cuenta INACTIVA se renueva (sin volverse la activa) y reconfirma
  /// su teléfono con su propia sesión. Devuelve los negocios cuya sesión terminó.
  Future<List<String>> reconfirmarInactivas(String tokenTelefono) =>
      _enFila(() => _reconfirmarInactivas(tokenTelefono));

  Future<List<String>> _reconfirmarInactivas(String tokenTelefono) async {
    final l = await _conActivaAlDia();
    if (l.length < 2) return const [];
    final plataforma = ref.read(servicioAvisosProvider).plataforma;
    final quedan = <CuentaGuardada>[l.first];
    final perdidas = <String>[];
    for (final c in l.skip(1)) {
      ({String acceso, String refresh})? r;
      try {
        r = await _sesion.renovarAparte(c.refreshToken);
      } on SinRed {
        quedan.add(c);
        continue;
      }
      if (r == null) {
        perdidas.add(c.negocio);
        continue;
      }
      quedan.add(c.con(refreshToken: r.refresh));
      await ref
          .read(repositorioConTokenProvider)(r.acceso)
          .registrarDispositivo(
            token: tokenTelefono,
            plataforma: plataforma,
            activos: c.avisos,
          );
    }
    await _guardar(quedan);
    return perdidas;
  }

  /// El interruptor de avisos de la cuenta activa.
  Future<void> marcarAvisosActiva({required bool activos}) =>
      _enFila(() => _marcarAvisosActiva(activos: activos));

  Future<void> _marcarAvisosActiva({required bool activos}) async {
    final l = await _lista();
    if (l.isEmpty || l.first.usuarioId != _activa) return;
    await _guardar([l.first.con(avisos: activos), ...l.skip(1)]);
  }

  /// ¿Los avisos de la cuenta activa están prendidos? null = no se sabe aún.
  Future<bool?> avisosActiva() async {
    final l = await _lista();
    if (l.isEmpty || l.first.usuarioId != _activa) return null;
    return l.first.avisos;
  }

  /// «Agregar cuenta»: guarda la activa al día y la pantalla de Entrar se vuelve
  /// «Agregar cuenta».
  Future<void> prepararAgregar() => _enFila(_prepararAgregar);

  Future<void> _prepararAgregar() async {
    await _guardar(await _conActivaAlDia());
    _previa = _activa;
    _activa = null;
    ref.read(agregandoCuentaProvider.notifier).valor = true;
  }

  /// Cancela el alta. Si ya había entrado otra sesión (p. ej. una cuenta de candidato),
  /// la revoca y regresa a la cuenta que estaba.
  Future<void> cancelarAgregar({required bool sesionNueva}) =>
      _enFila(() => _cancelarAgregar(sesionNueva: sesionNueva));

  Future<void> _cancelarAgregar({required bool sesionNueva}) async {
    ref.read(agregandoCuentaProvider.notifier).valor = false;
    final previa = _previa;
    _previa = null;
    if (previa == null) return;
    final l = await _lista();
    final c = l.where((x) => x.usuarioId == previa).firstOrNull;
    if (sesionNueva && c != null) {
      final acceso = _sesion.token;
      if (acceso != null) await _sesion.revocar(acceso);
      try {
        if (!await _sesion.usarCuenta(c.refreshToken)) return;
      } on SinRed {
        return;
      }
      await _guardar([
        c.con(refreshToken: _sesion.refreshToken),
        ...l.where((x) => x.usuarioId != previa),
      ]);
    }
    _activa = previa;
  }
}

final gestorCuentasProvider =
    AsyncNotifierProvider<GestorCuentas, List<CuentaGuardada>>(
      GestorCuentas.new,
    );

/// Conecta el gestor con la sesión: si la activa vence, decide el gestor. `App` lo
/// observa.
final cuentasSesionProvider = Provider<void>((ref) {
  final sesion = ref.watch(sesionProvider)
    ..alVencer = () =>
        ref.read(gestorCuentasProvider.notifier).alVencerActiva();
  ref.onDispose(() => sesion.alVencer = null);
});
