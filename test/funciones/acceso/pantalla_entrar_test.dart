import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reclutaya_app/funciones/acceso/pantalla_entrar.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/nucleo/almacen/almacen_local.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/rutas/guardas.dart';
import 'package:reclutaya_app/nucleo/sesion/providers.dart';
import 'package:reclutaya_app/nucleo/tema/tema.dart';
import 'package:reclutaya_app/nucleo/util/resultado.dart';

import '../../apoyo/datos.dart';
import '../../apoyo/repositorio_falso.dart';
import '../../apoyo/sesion_falsa.dart';

Widget _app(SesionFalsa s, RepositorioFalso r) => ProviderScope(
  overrides: [
    sesionProvider.overrideWithValue(s),
    almacenLocalProvider.overrideWithValue(AlmacenMemoria()),
    repositorioProvider.overrideWithValue(r),
  ],
  retry: sinReintentos,
  child: MaterialApp(theme: temaClaro(), home: const PantallaEntrar()),
);

Future<void> _llenarYEntrar(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('correo')), 'a@b.c');
  await tester.enterText(find.byKey(const Key('contrasena')), 'x');
  await tester.pump(); // el botón se habilita al reconstruir
  await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('con credenciales malas muestra el texto nuestro', (
    tester,
  ) async {
    final s = SesionFalsa()
      ..entrarR = const Falla(Servidor('Correo o contraseña incorrectos.'));
    await tester.pumpWidget(_app(s, RepositorioFalso()));
    await _llenarYEntrar(tester);
    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
  });

  testWidgets('una cuenta de candidato ve el aviso y se cierra su sesión', (
    tester,
  ) async {
    final s = SesionFalsa();
    final r = RepositorioFalso()..yoR = const Exito(yoCandidato);
    await tester.pumpWidget(_app(s, r));
    await _llenarYEntrar(tester);
    expect(
      find.textContaining('Esta versión es para negocios'),
      findsOneWidget,
    );
    expect(s.salidas, 1);
  });

  testWidgets('el botón está deshabilitado hasta que hay correo y contraseña', (
    tester,
  ) async {
    await tester.pumpWidget(_app(SesionFalsa(), RepositorioFalso()));
    final boton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Entrar'),
    );
    expect(boton.onPressed, isNull);
  });

  testWidgets('con router: un negocio entra a /inicio; un candidato se queda', (
    tester,
  ) async {
    Future<GoRouter> montar(SesionFalsa s, RepositorioFalso r) async {
      final router = GoRouter(
        initialLocation: '/entrar',
        redirect: (_, e) =>
            redirigir(autenticado: s.autenticado, ruta: e.matchedLocation),
        routes: [
          GoRoute(path: '/entrar', builder: (_, _) => const PantallaEntrar()),
          GoRoute(
            path: '/inicio',
            builder: (_, _) => const Scaffold(body: Text('INICIO')),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sesionProvider.overrideWithValue(s),
            almacenLocalProvider.overrideWithValue(AlmacenMemoria()),
            repositorioProvider.overrideWithValue(r),
          ],
          retry: sinReintentos,
          child: MaterialApp.router(theme: temaClaro(), routerConfig: router),
        ),
      );
      return router;
    }

    await montar(SesionFalsa(), RepositorioFalso());
    await _llenarYEntrar(tester);
    expect(find.text('INICIO'), findsOneWidget);

    final s = SesionFalsa();
    await montar(s, RepositorioFalso()..yoR = const Exito(yoCandidato));
    await _llenarYEntrar(tester);
    expect(find.text('INICIO'), findsNothing);
    expect(
      find.textContaining('Esta versión es para negocios'),
      findsOneWidget,
    );
    expect(s.salidas, 1);
  });
}
