import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/funciones/negocio/novedades/controlador_avisos.dart';
import 'package:reclutaya_app/nucleo/almacen/almacen_local.dart';
import 'package:reclutaya_app/nucleo/push/servicio_avisos.dart';

import '../../../apoyo/repositorio_falso.dart';

class _Avisos implements ServicioAvisos {
  _Avisos({this.disponible = true, this.tokenDado = 'tok-1'});

  @override
  final bool disponible;
  final String? tokenDado;
  final _nuevos = StreamController<String>.broadcast();
  final _tocados = StreamController<Map<String, dynamic>>.broadcast();

  @override
  String get plataforma => 'ios';
  @override
  Future<void> iniciar() async {}
  @override
  Future<String?> pedirPermisoYToken() async => tokenDado;
  @override
  Stream<String> get tokensNuevos => _nuevos.stream;
  @override
  Stream<Map<String, dynamic>> get tocados => _tocados.stream;
  @override
  Future<Map<String, dynamic>?> tocadoAlAbrir() async => null;
}

ProviderContainer _c(RepositorioFalso r, ServicioAvisos a, AlmacenMemoria m) {
  final c = ProviderContainer(
    overrides: [
      repositorioProvider.overrideWithValue(r),
      servicioAvisosProvider.overrideWithValue(a),
      almacenLocalProvider.overrideWithValue(m),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('al entrar registra el teléfono con los avisos prendidos', () async {
    final r = RepositorioFalso();
    final c = _c(r, _Avisos(), AlmacenMemoria());
    await c.read(controladorAvisosProvider.future);
    await c.read(controladorAvisosProvider.notifier).alEntrar();
    expect(r.registros, [('tok-1', 'ios', true)]);
    expect(c.read(controladorAvisosProvider).value!.activos, isTrue);
  });

  test('si los apagó en este teléfono, se registra apagado', () async {
    final r = RepositorioFalso();
    final m = AlmacenMemoria()..datos['ry_avisos_activos'] = 'no';
    final c = _c(r, _Avisos(), m);
    await c.read(controladorAvisosProvider.future);
    await c.read(controladorAvisosProvider.notifier).alEntrar();
    expect(r.registros, [('tok-1', 'ios', false)]);
  });

  test(
    'el interruptor avisa al servidor y se recuerda en el teléfono',
    () async {
      final r = RepositorioFalso();
      final m = AlmacenMemoria();
      final c = _c(r, _Avisos(), m);
      await c.read(controladorAvisosProvider.future);
      final n = c.read(controladorAvisosProvider.notifier);
      await n.alEntrar();
      await n.cambiar(activos: false);
      expect(r.cambios, [('tok-1', false)]);
      expect(m.datos['ry_avisos_activos'], 'no');
      expect(c.read(controladorAvisosProvider).value!.activos, isFalse);
    },
  );

  test('al salir da de baja el teléfono', () async {
    final r = RepositorioFalso();
    final c = _c(r, _Avisos(), AlmacenMemoria());
    await c.read(controladorAvisosProvider.future);
    final n = c.read(controladorAvisosProvider.notifier);
    await n.alEntrar();
    await n.alSalir();
    expect(r.bajas, ['tok-1']);
  });

  test('sin Firebase configurado no toca el servidor', () async {
    final r = RepositorioFalso();
    final c = _c(r, _Avisos(disponible: false), AlmacenMemoria());
    await c.read(controladorAvisosProvider.future);
    await c.read(controladorAvisosProvider.notifier).alEntrar();
    expect(r.registros, isEmpty);
    expect(c.read(controladorAvisosProvider).value!.disponible, isFalse);
  });

  test('sin permiso (no hay token) no registra nada', () async {
    final r = RepositorioFalso();
    final c = _c(r, _Avisos(tokenDado: null), AlmacenMemoria());
    await c.read(controladorAvisosProvider.future);
    await c.read(controladorAvisosProvider.notifier).alEntrar();
    expect(r.registros, isEmpty);
  });
}
