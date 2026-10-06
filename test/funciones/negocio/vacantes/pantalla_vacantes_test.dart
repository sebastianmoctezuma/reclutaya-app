import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/yo.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/funciones/negocio/vacantes/pantalla_vacantes.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
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
    expect(find.text('3 sin rankear'), findsOneWidget);
    expect(find.text('40 días restantes'), findsOneWidget);
    expect(find.text('Centro'), findsOneWidget);
    expect(find.text('14 candidatos'), findsOneWidget);
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

  testWidgets('sin activas: vacío con salida a la web', (tester) async {
    comoTelefono(tester);
    final r = RepositorioFalso()..activasR = const Exito([]);
    await tester.pumpWidget(_app(r));
    await tester.pumpAndSettle();
    expect(find.text('Aún no tienes vacantes activas'), findsOneWidget);
    expect(find.textContaining('desde la web'), findsOneWidget);
  });

  group('con varias sucursales', () {
    const yoMulti = Yo(
      tipo: 'negocio',
      nombre: 'Antonio',
      iniciales: 'AP',
      rol: 'owner',
      veDinero: true,
      variasSucursales: true,
      empresa: EmpresaYo(nombre: 'Grupo Yaqui'),
    );

    testWidgets('se llama Sucursales y agrupa las vacantes por sucursal', (
      tester,
    ) async {
      comoTelefono(tester);
      final r = RepositorioFalso()
        ..yoR = const Exito(yoMulti)
        ..sucursalesR = const Exito(sucursalesMulti);
      await tester.pumpWidget(_app(r));
      await tester.pumpAndSettle();
      expect(find.text('Sucursales'), findsWidgets);
      expect(find.text('Yaqui Parrilla Sonorense'), findsOneWidget);
      expect(find.text('Principal'), findsOneWidget);
      expect(find.text('Altomar'), findsOneWidget);
      expect(find.text('Cocinero/a'), findsOneWidget);
      expect(find.text('Mesero'), findsOneWidget);
      expect(find.text('2 sin rankear'), findsOneWidget);
      expect(find.text('Agregar sucursal'), findsNothing);
    });

    testWidgets('con un servidor anterior cae a la lista de activas', (
      tester,
    ) async {
      comoTelefono(tester);
      final r = RepositorioFalso()
        ..yoR = const Exito(yoMulti)
        ..sucursalesR = const Falla(NoEncontrado());
      await tester.pumpWidget(_app(r));
      await tester.pumpAndSettle();
      expect(find.text(vacanteActiva.puesto), findsOneWidget);
    });

    testWidgets('Cerradas sigue igual', (tester) async {
      comoTelefono(tester);
      final r = RepositorioFalso()
        ..yoR = const Exito(yoMulti)
        ..sucursalesR = const Exito(sucursalesMulti);
      await tester.pumpWidget(_app(r));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cerradas'));
      await tester.pumpAndSettle();
      expect(find.text('Yaqui Parrilla Sonorense'), findsNothing);
    });
  });
}
