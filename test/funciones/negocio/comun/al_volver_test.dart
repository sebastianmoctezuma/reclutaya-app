import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/funciones/negocio/comun/al_volver.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/nucleo/almacen/almacen_local.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/sesion/providers.dart';
import 'package:reclutaya_app/nucleo/util/resultado.dart';

import '../../../apoyo/datos.dart';
import '../../../apoyo/repositorio_falso.dart';
import '../../../apoyo/sesion_falsa.dart';

// Al volver del fondo (12-oct): una pantalla que se quedó en error se vuelve a pedir
// sola, sin cerrar la app; y salir unos segundos no dispara consultas de más.

Future<void> _salirYVolver(WidgetTester tester) async {
  tester.binding
    ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
    ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
    ..handleAppLifecycleStateChanged(AppLifecycleState.paused);
  await tester.pump();
  tester.binding
    ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
    ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
    ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pump();
}

void main() {
  late RepositorioFalso repo;
  late SesionFalsa sesion;
  late ProviderContainer c;

  Future<void> preparar(WidgetTester tester, {bool inicioFalla = false}) async {
    repo = RepositorioFalso();
    if (inicioFalla) repo.inicioR = const Falla(SinRed());
    sesion = SesionFalsa();
    c = ProviderContainer(
      overrides: [
        repositorioProvider.overrideWithValue(repo),
        sesionProvider.overrideWithValue(sesion),
        almacenLocalProvider.overrideWithValue(AlmacenMemoria()),
      ],
      retry: sinReintentos,
    );
    addTearDown(c.dispose);
    final vigia = c.listen(alVolverProvider, (_, _) {});
    addTearDown(vigia.close);
    final sub = c.listen(inicioProvider, (_, _) {});
    addTearDown(sub.close);
    await sesion.entrar('a', 'b');
  }

  testWidgets(
    'si el Inicio se quedó en error, al volver se pide otra vez solo',
    (tester) async {
      await preparar(tester, inicioFalla: true);
      await tester.runAsync(
        () => c.read(inicioProvider.future).then((_) {}, onError: (_) {}),
      );
      expect(c.read(inicioProvider).hasError, isTrue);
      expect(repo.llamadasInicio, 1);

      repo.inicioR = const Exito(inicioEjemplo);
      await _salirYVolver(tester);
      await tester.runAsync(() => c.read(inicioProvider.future));
      expect(repo.llamadasInicio, 2);
      expect(c.read(inicioProvider).hasValue, isTrue);
      // Deja correr lo que la recarga agendó antes de cerrar la prueba.
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets('salir unos segundos con todo cargado no vuelve a pedir nada', (
    tester,
  ) async {
    await preparar(tester);
    await tester.runAsync(() => c.read(inicioProvider.future));
    expect(repo.llamadasInicio, 1);

    await _salirYVolver(tester);
    await tester.runAsync(() => c.read(inicioProvider.future));
    expect(repo.llamadasInicio, 1);
  });

  testWidgets('sin sesión, volver no pide nada', (tester) async {
    await preparar(tester, inicioFalla: true);
    await tester.runAsync(
      () => c.read(inicioProvider.future).then((_) {}, onError: (_) {}),
    );
    await sesion.salir();
    await _salirYVolver(tester);
    expect(repo.llamadasInicio, 1);
  });
}
