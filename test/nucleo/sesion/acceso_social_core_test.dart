import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/nucleo/sesion/acceso_social_core.dart';

void main() {
  test('cada intento lleva un nonce nuevo, largo y seguro para URL', () {
    final r = Random(7);
    final a = nonceCrudo(r);
    final b = nonceCrudo(r);
    expect(a, isNot(b));
    expect(a.length, greaterThanOrEqualTo(43));
    expect(RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(a), isTrue);
  });

  test('a Google y Apple va el SHA-256 del nonce; a Supabase, el crudo', () {
    // Vector conocido: sha256("abc").
    expect(
      nonceParaProveedor('abc'),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });

  test(
    'sin cuenta: el mensaje dice qué hacer, y con Apple explica el correo',
    () {
      // Sin mandar a crear nada fuera de la app (revisión de Apple, 15-oct).
      expect(
        mensajeSinCuenta(ProveedorSocial.google),
        contains('Entra con el correo de tu cuenta'),
      );
      expect(
        mensajeSinCuenta(ProveedorSocial.google),
        isNot(contains('reclutaya.com')),
      );
      expect(
        mensajeSinCuenta(ProveedorSocial.apple),
        contains('Compartir mi correo'),
      );
    },
  );
}
