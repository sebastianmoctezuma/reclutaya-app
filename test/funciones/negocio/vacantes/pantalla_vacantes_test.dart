import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/funciones/negocio/vacantes/pantalla_vacantes.dart';
import 'package:reclutaya_app/nucleo/tema/tema.dart';
import 'package:reclutaya_app/nucleo/util/resultado.dart';

import '../../../apoyo/datos.dart';
import '../../../apoyo/repositorio_falso.dart';
import '../../../apoyo/telefono.dart';

Widget _app(RepositorioFalso r) => ProviderScope(
  overrides: [repositorioProvider.overrideWithValue(r)],
  retry: sinReintentos,
  child: MaterialApp(theme: temaClaro(), home: const PantallaVacantes()),
);

void main() {
  // Las fechas en español: en la app lo hace `main`.
  setUpAll(() => initializeDateFormatting('es_MX'));

  testWidgets('por defecto lista las activas con sus datos', (tester) async {
    comoTelefono(tester);
    await tester.pumpWidget(_app(RepositorioFalso()));
    await tester.pumpAndSettle();
    expect(find.text(vacanteActiva.puesto), findsOneWidget);
    expect(find.text('3 nuevos esta semana'), findsOneWidget);
    expect(find.text('40 días restantes'), findsOneWidget);
    expect(find.text('Centro'), findsOneWidget);
    expect(find.text('14 candidatos'), findsOneWidget);
  });

  testWidgets('apoyar el dedo en una vacante ya pide su ficha y su ranking', (
    tester,
  ) async {
    comoTelefono(tester);
    final r = RepositorioFalso();
    await tester.pumpWidget(_app(r));
    await tester.pumpAndSettle();
    expect(r.llamadasVacante, 0);
    final dedo = await tester.startGesture(
      tester.getCenter(find.text(vacanteActiva.puesto)),
    );
    await tester.pump();
    // Todavía sin soltar: ya salieron las dos peticiones.
    expect(r.llamadasVacante, 1);
    expect(r.llamadasRanking, 1);
    await dedo.cancel();
    await tester.pumpAndSettle();
  });

  testWidgets('al tocar Cerradas aparecen las cerradas', (tester) async {
    comoTelefono(tester);
    await tester.pumpWidget(_app(RepositorioFalso()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerradas'));
    await tester.pumpAndSettle();
    expect(find.text(vacanteCerradaEjemplo.puesto), findsOneWidget);
    expect(find.textContaining('Hubo contratación'), findsOneWidget);
    expect(find.text(vacanteActiva.puesto), findsNothing);
  });

  testWidgets('sin activas: vacío que dice qué verá', (tester) async {
    comoTelefono(tester);
    final r = RepositorioFalso()..activasR = const Exito([]);
    await tester.pumpWidget(_app(r));
    await tester.pumpAndSettle();
    expect(find.text('Aún no tienes vacantes activas'), findsOneWidget);
    expect(find.textContaining('Cuando publiques una'), findsOneWidget);
  });
}
