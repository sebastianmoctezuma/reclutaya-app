import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/funciones/cuenta/pantalla_cuenta.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/nucleo/sesion/providers.dart';
import 'package:reclutaya_app/nucleo/tema/tema.dart';

import '../../apoyo/datos.dart';
import '../../apoyo/repositorio_falso.dart';
import '../../apoyo/sesion_falsa.dart';
import '../../apoyo/telefono.dart';

Widget _app(SesionFalsa s) => ProviderScope(
  overrides: [
    sesionProvider.overrideWithValue(s),
    repositorioProvider.overrideWithValue(RepositorioFalso()),
  ],
  retry: sinReintentos,
  child: MaterialApp(theme: temaClaro(), home: const PantallaCuenta()),
);

void main() {
  testWidgets('pinta nombre, rol, negocio y Cerrar sesión', (tester) async {
    comoTelefono(tester);
    await tester.pumpWidget(_app(SesionFalsa()));
    await tester.pumpAndSettle();
    // El negocio arriba y, debajo, quién entró con su rol.
    expect(find.text('${yoNegocio.nombre!} · Dueño'), findsOneWidget);
    expect(find.text(yoNegocio.empresa!.nombre), findsOneWidget);
    expect(find.text('Plan Pro'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });

  testWidgets('cerrar sesión pide confirmación; aceptar sale una vez', (
    tester,
  ) async {
    comoTelefono(tester);
    final s = SesionFalsa();
    await tester.pumpWidget(_app(s));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(s.salidas, 0);
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();
    expect(s.salidas, 1);
  });
}
