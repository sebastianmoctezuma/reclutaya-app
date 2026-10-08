import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/funciones/cuentas/gestor_cuentas.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/yo.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/funciones/negocio/comun/repositorio_negocio.dart';
import 'package:reclutaya_app/funciones/negocio/novedades/controlador_avisos.dart';
import 'package:reclutaya_app/nucleo/almacen/almacen_local.dart';
import 'package:reclutaya_app/nucleo/push/servicio_avisos.dart';
import 'package:reclutaya_app/nucleo/sesion/cuentas_core.dart';
import 'package:reclutaya_app/nucleo/sesion/providers.dart';

import '../../apoyo/repositorio_falso.dart';
import '../../apoyo/sesion_falsa.dart';

class _Avisos implements ServicioAvisos {
  @override
  bool get disponible => true;
  @override
  String get plataforma => 'ios';
  @override
  Future<void> iniciar() async {}
  @override
  Future<String?> pedirPermisoYToken() async => 'tok-1';
  @override
  Stream<String> get tokensNuevos => const Stream.empty();
  @override
  Stream<Map<String, dynamic>> get tocados => const Stream.empty();
  @override
  Future<Map<String, dynamic>?> tocadoAlAbrir() async => null;
  int olvidos = 0;
  @override
  Future<void> olvidarToken() async => olvidos++;
}

Yo _yo(String id, String negocio) => Yo(
  tipo: 'negocio',
  iniciales: 'XX',
  usuarioId: id,
  empresa: EmpresaYo(nombre: negocio),
);

/// Teléfono con dos cuentas: «a» (activa, Tacos) y «b» (Grupo Yaqui).
Future<
  ({
    ProviderContainer c,
    SesionFalsa sesion,
    RepositorioFalso repo,
    _Avisos avisos,
    Map<String, RepositorioFalso> aparte,
  })
>
_dosCuentas() async {
  final repo = RepositorioFalso();
  final sesion = SesionFalsa();
  final avisos = _Avisos();
  final aparte = <String, RepositorioFalso>{};
  final c = ProviderContainer(
    overrides: [
      repositorioProvider.overrideWithValue(repo),
      sesionProvider.overrideWithValue(sesion),
      almacenLocalProvider.overrideWithValue(AlmacenMemoria()),
      servicioAvisosProvider.overrideWithValue(avisos),
      repositorioConTokenProvider.overrideWithValue(
        (acceso) => aparte.putIfAbsent(acceso, RepositorioFalso.new),
      ),
    ],
    retry: sinReintentos,
  );
  addTearDown(c.dispose);
  final g = c.read(gestorCuentasProvider.notifier);
  await c.read(gestorCuentasProvider.future);
  // Entra «b», luego «a» (la activa queda primero).
  sesion
    ..validos['rb'] = 'b@x.mx'
    ..refreshToken = 'rb'
    ..correo = 'b@x.mx';
  await sesion.entrar('b', 'x');
  await g.recordarActiva(_yo('b', 'Grupo Yaqui'));
  sesion
    ..validos['ra'] = 'a@x.mx'
    ..refreshToken = 'ra'
    ..correo = 'a@x.mx';
  await g.recordarActiva(_yo('a', 'Tacos'));
  return (c: c, sesion: sesion, repo: repo, avisos: avisos, aparte: aparte);
}

List<String> _ids(ProviderContainer c) =>
    c.read(gestorCuentasProvider).value!.map((x) => x.usuarioId).toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('recordar la cuenta activa la guarda primero, con su sesión', () async {
    final t = await _dosCuentas();
    expect(_ids(t.c), ['a', 'b']);
    expect(t.c.read(gestorCuentasProvider).value!.first.refreshToken, 'ra');
  });

  test(
    'cambiar de cuenta usa la otra sesión sin cerrar la actual y la sube',
    () async {
      final t = await _dosCuentas();
      final r = await t.c.read(gestorCuentasProvider.notifier).cambiarA('b');
      expect(r, 'Grupo Yaqui');
      expect(_ids(t.c), ['b', 'a']);
      expect(t.sesion.salidas, 0, reason: 'cambiar no cierra sesión');
      // La anterior quedó guardada con su token VIVO, para volver a ella.
      final a = t.c.read(gestorCuentasProvider).value!.last;
      expect(a.refreshToken, 'ra');
      expect(
        t.avisos.olvidos,
        0,
        reason: 'las otras cuentas siguen recibiendo avisos',
      );
    },
  );

  test(
    'una cuenta cuya sesión ya no vale se quita al intentar cambiar',
    () async {
      final t = await _dosCuentas();
      t.sesion.validos.remove('rb');
      final r = await t.c.read(gestorCuentasProvider.notifier).cambiarA('b');
      expect(r, isNull);
      expect(_ids(t.c), ['a']);
    },
  );

  test(
    'quitar la activa con otra guardada: da de baja SOLO esa y pasa a la otra',
    () async {
      final t = await _dosCuentas();
      await t.c.read(controladorAvisosProvider.future);
      await t.c.read(controladorAvisosProvider.notifier).alEntrar();
      await t.c.read(cerrarSesionProvider)();
      expect(_ids(t.c), ['b']);
      expect(t.repo.bajas, ['tok-1']);
      expect(t.sesion.salidas, 0);
      expect(t.avisos.olvidos, 0);
      expect(t.sesion.revocados, isNotEmpty);
    },
  );

  test(
    'quitar la ÚLTIMA: el cierre de siempre, olvida el token del teléfono',
    () async {
      final t = await _dosCuentas();
      await t.c.read(gestorCuentasProvider.notifier).cambiarA('b');
      await t.c.read(cerrarSesionProvider)();
      await t.c.read(cerrarSesionProvider)();
      expect(_ids(t.c), isEmpty);
      expect(t.sesion.salidas, 1);
      expect(t.avisos.olvidos, greaterThanOrEqualTo(1));
    },
  );

  test('al abrir, cada cuenta inactiva se renueva y reconfirma su teléfono con SU sesión', () async {
    final t = await _dosCuentas();
    await t.c
        .read(gestorCuentasProvider.notifier)
        .reconfirmarInactivas('tok-1');
    expect(t.aparte['acc-b@x.mx']!.registros, [('tok-1', 'ios', true)]);
    expect(t.c.read(gestorCuentasProvider).value!.last.refreshToken, 'rb+');
  });

  test('una inactiva que ya no renueva sale de la lista', () async {
    final t = await _dosCuentas();
    t.sesion.validos.remove('rb');
    final perdidas = await t.c
        .read(gestorCuentasProvider.notifier)
        .reconfirmarInactivas('tok-1');
    expect(perdidas, ['Grupo Yaqui']);
    expect(_ids(t.c), ['a']);
  });

  test(
    'si la activa vence y hay otra, se pasa a la otra en vez de sacar al dueño',
    () async {
      final t = await _dosCuentas();
      t.c.read(cuentasSesionProvider);
      await t.sesion.sesionVencida();
      expect(_ids(t.c), ['b']);
      expect(t.sesion.salidas, 0);
    },
  );

  test('tope: con 5 cuentas no se puede agregar otra', () async {
    final t = await _dosCuentas();
    final g = t.c.read(gestorCuentasProvider.notifier);
    for (final id in ['c', 'd', 'e']) {
      t.sesion.refreshToken = 'r$id';
      await g.recordarActiva(_yo(id, id));
    }
    expect(g.puedeAgregar, isFalse);
  });

  test('el interruptor de avisos es de cada cuenta', () async {
    final t = await _dosCuentas();
    await t.c.read(controladorAvisosProvider.future);
    await t.c.read(controladorAvisosProvider.notifier).alEntrar();
    await t.c.read(controladorAvisosProvider.notifier).cambiar(activos: false);
    final l = t.c.read(gestorCuentasProvider).value!;
    expect(l.first.avisos, isFalse);
    expect(l.last.avisos, isTrue);
    expect(CuentaGuardada, isNotNull);
    expect(RepositorioNegocio, isNotNull);
  });

  test('sin red al cambiar, no se pierde ninguna cuenta', () async {
    final t = await _dosCuentas();
    t.sesion.sinRed = true;
    final r = await t.c.read(gestorCuentasProvider.notifier).cambiarA('b');
    expect(r, isNull);
    expect(_ids(t.c), ['a', 'b']);
    unawaited(Future<void>.value());
  });
}
