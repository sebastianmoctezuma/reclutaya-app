import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/nucleo/sesion/cuentas_core.dart';

CuentaGuardada _c(String id, {String negocio = 'N', String refresh = 'r'}) =>
    CuentaGuardada(
      usuarioId: id,
      negocio: negocio,
      correo: '$id@x.mx',
      refreshToken: refresh,
    );

void main() {
  group('agregarCuenta', () {
    test('la nueva va primero', () {
      final r = agregarCuenta([_c('a')], _c('b'));
      expect(r.lista.map((c) => c.usuarioId), ['b', 'a']);
      expect(r.lleno, isFalse);
    });

    test('la misma cuenta no se duplica: se actualiza y sube', () {
      final r = agregarCuenta([
        _c('a'),
        _c('b', refresh: 'viejo'),
      ], _c('b', refresh: 'nuevo'));
      expect(r.lista.map((c) => c.usuarioId), ['b', 'a']);
      expect(r.lista.first.refreshToken, 'nuevo');
    });

    test(
      'tope de 5: una sexta no entra, pero una que ya está sí se actualiza',
      () {
        final cinco = [
          for (final id in ['a', 'b', 'c', 'd', 'e']) _c(id),
        ];
        final r = agregarCuenta(cinco, _c('f'));
        expect(r.lleno, isTrue);
        expect(r.lista, cinco);
        expect(agregarCuenta(cinco, _c('c')).lleno, isFalse);
      },
    );
  });

  test(
    'quitarCuenta y siguienteCuenta: tras quitar, sigue la más reciente',
    () {
      final l = [_c('a'), _c('b'), _c('c')];
      expect(quitarCuenta(l, 'a').map((c) => c.usuarioId), ['b', 'c']);
      expect(siguienteCuenta(l, 'a')?.usuarioId, 'b');
      expect(siguienteCuenta([_c('a')], 'a'), isNull);
    },
  );

  group('accionAviso — tocar un aviso', () {
    final cuentas = [_c('a'), _c('b')];
    test('sin cuenta en el aviso o de la activa: abrir', () {
      expect(
        accionAviso(activa: 'a', usuarioIdAviso: null, cuentas: cuentas),
        AccionAviso.abrir,
      );
      expect(
        accionAviso(activa: 'a', usuarioIdAviso: 'a', cuentas: cuentas),
        AccionAviso.abrir,
      );
    });
    test('de otra cuenta guardada: cambiar y abrir', () {
      expect(
        accionAviso(activa: 'a', usuarioIdAviso: 'b', cuentas: cuentas),
        AccionAviso.cambiarYAbrir,
      );
    });
    test('de una cuenta que ya no está en el teléfono: al Inicio', () {
      expect(
        accionAviso(activa: 'a', usuarioIdAviso: 'z', cuentas: cuentas),
        AccionAviso.inicio,
      );
    });
  });

  test('ida y vuelta por JSON; basura → lista vacía', () {
    final l = [_c('a', negocio: 'Grupo Yaqui')];
    expect(cuentasDesdeJson(cuentasAJson(l)), l);
    expect(cuentasDesdeJson(null), isEmpty);
    expect(cuentasDesdeJson('no es json'), isEmpty);
    expect(cuentasDesdeJson('[{"usuarioId": 3}]'), isEmpty);
  });
}
