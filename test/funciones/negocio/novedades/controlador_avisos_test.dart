import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/funciones/negocio/novedades/controlador_avisos.dart';
import 'package:reclutaya_app/nucleo/almacen/almacen_local.dart';
import 'package:reclutaya_app/nucleo/push/servicio_avisos.dart';

import 'package:reclutaya_app/nucleo/sesion/providers.dart';

import '../../../apoyo/repositorio_falso.dart';
import '../../../apoyo/sesion_falsa.dart';

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

  int olvidos = 0;
  @override
  Future<void> olvidarToken() async => olvidos++;
}

ProviderContainer _c(
  RepositorioFalso r,
  ServicioAvisos a,
  AlmacenMemoria m, [
  SesionFalsa? sesion,
]) {
  final c = ProviderContainer(
    overrides: [
      repositorioProvider.overrideWithValue(r),
      servicioAvisosProvider.overrideWithValue(a),
      almacenLocalProvider.overrideWithValue(m),
      sesionProvider.overrideWithValue(sesion ?? SesionFalsa()),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  _pruebasAvisoPendiente();
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

  test('al perder la sesión por cualquier camino (aquí, vencida), el teléfono olvida su token', () async {
    final r = RepositorioFalso();
    final a = _Avisos();
    final sesion = SesionFalsa();
    _c(r, a, AlmacenMemoria(), sesion).listen(avisosSesionProvider, (_, _) {});
    await sesion.entrar('a@b.mx', 'x');
    await Future<void>.delayed(Duration.zero);
    await sesion.sesionVencida();
    await Future<void>.delayed(Duration.zero);
    expect(a.olvidos, 1);
  });

  test(
    'cerrar sesión da de baja el teléfono, olvida el token y sale',
    () async {
      final r = RepositorioFalso();
      final a = _Avisos();
      final sesion = SesionFalsa();
      final c = _c(r, a, AlmacenMemoria(), sesion);
      await sesion.entrar('a@b.mx', 'x');
      await c.read(controladorAvisosProvider.future);
      await c.read(controladorAvisosProvider.notifier).alEntrar();
      await c.read(cerrarSesionProvider)();
      expect(r.bajas, ['tok-1']);
      expect(a.olvidos, greaterThanOrEqualTo(1));
      expect(sesion.salidas, 1);
    },
  );
}

// Un aviso tocado ANTES de que el arranque navegue se guarda y lo abre el arranque; uno
// de después navega solo (13-oct). Lo que se prueba aquí es la mano a mano, sin router.
void _pruebasAvisoPendiente() {
  test(
    'antes de que el arranque esté listo, el aviso se guarda y no navega',
    () async {
      final c = _c(RepositorioFalso(), _Avisos(), AlmacenMemoria());
      final datos = {
        'tipo': 'test',
        'slug': 'cajero-x1',
        'postulacionId': 'p9',
      };
      await c.read(abrirAvisoProvider)(datos);
      expect(c.read(avisoPendienteProvider), datos);
      expect(c.read(avisoPendienteProvider.notifier).consumir(), datos);
      expect(
        c.read(avisoPendienteProvider),
        isNull,
        reason: 'se consume una sola vez',
      );
    },
  );

  test(
    'el arranque resuelve el aviso guardado a su ruta con sección',
    () async {
      final c = _c(RepositorioFalso(), _Avisos(), AlmacenMemoria());
      final ruta = await resolverAviso(c.read, {
        'tipo': 'video',
        'slug': 'cajero-x1',
        'postulacionId': 'p9',
      });
      expect(ruta, '/vacantes/cajero-x1/ranking/p9?seccion=video');
    },
  );

  test(
    'el arranque decide con la cuenta de la sesión, no con el llavero',
    () async {
      final c = _c(RepositorioFalso(), _Avisos(), AlmacenMemoria());
      final datos = {
        'tipo': 'test',
        'slug': 'cajero-x1',
        'postulacionId': 'p9',
        'usuarioId': 'u-mia',
      };
      expect(
        await resolverAviso(c.read, datos, activa: 'u-mia'),
        '/vacantes/cajero-x1/ranking/p9?seccion=test',
      );
      // De otra cuenta que no está guardada: al Inicio, sin cambiar de cuenta.
      expect(await resolverAviso(c.read, datos, activa: 'u-otra'), '/inicio');
    },
  );

  test('un aviso mal formado no deja nada pendiente que abrir', () async {
    final c = _c(RepositorioFalso(), _Avisos(), AlmacenMemoria());
    expect(await resolverAviso(c.read, {'slug': '../x'}), isNull);
  });
}
