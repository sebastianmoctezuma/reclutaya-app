import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/funciones/acceso/pantalla_entrar.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/nucleo/almacen/almacen_local.dart';
import 'package:reclutaya_app/nucleo/plataforma/plataforma.dart';
import 'package:reclutaya_app/nucleo/sesion/acceso_social.dart';
import 'package:reclutaya_app/nucleo/sesion/acceso_social_core.dart';
import 'package:reclutaya_app/nucleo/sesion/providers.dart';
import 'package:reclutaya_app/nucleo/tema/tema.dart';
import 'package:reclutaya_app/nucleo/util/resultado.dart';

import '../../apoyo/acceso_social_falso.dart';
import '../../apoyo/repositorio_falso.dart';
import '../../apoyo/sesion_falsa.dart';

// Entrar con Google o Apple (8-oct). La app es solo para entrar: con un correo que no
// tiene negocio se avisa y no queda ninguna sesión abierta.
Widget _app(SesionFalsa s, RepositorioFalso r, AccesoSocialFalso a) =>
    ProviderScope(
      overrides: [
        sesionProvider.overrideWithValue(s),
        almacenLocalProvider.overrideWithValue(AlmacenMemoria()),
        repositorioProvider.overrideWithValue(r),
        accesoSocialProvider.overrideWithValue(a),
      ],
      retry: sinReintentos,
      child: MaterialApp(theme: temaClaro(), home: const PantallaEntrar()),
    );

Future<void> _tocar(WidgetTester tester, String texto) async {
  await tester.ensureVisible(find.text(texto));
  await tester.tap(find.text(texto));
  await tester.pumpAndSettle();
}

void main() {
  // El botón de Apple solo existe en iPhone; las pruebas corren como Android.
  setUp(() => Plataforma.forzada = TargetPlatform.iOS);
  tearDown(() => Plataforma.forzada = null);

  testWidgets('con Google y un negocio, entra sin pedir contraseña', (
    tester,
  ) async {
    final s = SesionFalsa();
    final r = RepositorioFalso();
    final a = AccesoSocialFalso();
    await tester.pumpWidget(_app(s, r, a));
    await _tocar(tester, 'Continuar con Google');
    expect(s.entradasSociales, [ProveedorSocial.google]);
    expect(r.llamadasSinCuenta, 1);
    expect(s.autenticado, isTrue);
    expect(find.byKey(const Key('mensaje')), findsNothing);
  });

  testWidgets('con Google sin cuenta: avisa y no deja la sesión abierta', (
    tester,
  ) async {
    final s = SesionFalsa();
    final r = RepositorioFalso()..sinCuentaR = const Exito(true);
    await tester.pumpWidget(_app(s, r, AccesoSocialFalso()));
    await _tocar(tester, 'Continuar con Google');
    expect(
      find.textContaining('no tiene un negocio en ReclutaYa'),
      findsOneWidget,
    );
    expect(s.autenticado, isFalse);
    expect(r.llamadasYo, 0, reason: 'sin cuenta no se pregunta /yo');
  });

  testWidgets('con Apple sin cuenta: explica lo de compartir el correo', (
    tester,
  ) async {
    final s = SesionFalsa();
    final r = RepositorioFalso()..sinCuentaR = const Exito(true);
    await tester.pumpWidget(_app(s, r, AccesoSocialFalso()));
    await _tocar(tester, 'Continuar con Apple');
    expect(find.textContaining('Compartir mi correo'), findsOneWidget);
    expect(s.autenticado, isFalse);
  });

  testWidgets('si cancela la hoja de Apple o Google, no pasa nada', (
    tester,
  ) async {
    final s = SesionFalsa();
    final a = AccesoSocialFalso()..cancela = true;
    await tester.pumpWidget(_app(s, RepositorioFalso(), a));
    await _tocar(tester, 'Continuar con Apple');
    expect(a.pedidos, [ProveedorSocial.apple]);
    expect(s.entradasSociales, isEmpty);
    expect(find.byKey(const Key('mensaje')), findsNothing);
  });
}
