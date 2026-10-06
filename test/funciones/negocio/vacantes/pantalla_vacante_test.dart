import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/vacantes.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/funciones/negocio/vacantes/pantalla_vacante.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/tema/tema.dart';
import 'package:reclutaya_app/nucleo/util/resultado.dart';

import '../../../apoyo/datos.dart';
import '../../../apoyo/repositorio_falso.dart';
import '../../../apoyo/telefono.dart';

Widget _app(RepositorioFalso r) => ProviderScope(
  overrides: [repositorioProvider.overrideWithValue(r)],
  retry: sinReintentos,
  child: MaterialApp(
    theme: temaClaro(),
    home: const PantallaVacante(slug: 'mesero-abc'),
  ),
);

void main() {
  setUpAll(() => initializeDateFormatting('es_MX'));

  testWidgets('pinta puesto, estado, datos, conteos y el acceso al ranking', (
    tester,
  ) async {
    comoTelefono(tester);
    await tester.pumpWidget(_app(RepositorioFalso()));
    await tester.pumpAndSettle();
    expect(find.text(fichaVacante.puesto), findsWidgets);
    expect(find.text('Activa'), findsOneWidget);
    expect(find.text('Matutino'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Requisito'),
      find.byType(CustomScrollView),
      const Offset(0, -300),
    );
    expect(find.text('Requisito'), findsOneWidget);
    final boton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Ver ranking'),
    );
    expect(boton.onPressed, isNotNull);
  });

  testWidgets('sin candidatos el botón lo dice y está deshabilitado', (
    tester,
  ) async {
    comoTelefono(tester);
    final r = RepositorioFalso()
      ..vacanteR = const Exito(
        VacanteFicha(
          id: 'v9',
          puesto: 'Cajero',
          estado: 'ACTIVA',
          slug: 'cajero',
          diasParaResponder: 3,
          conteos: Conteos(
            total: 0,
            rankeados: 0,
            sinRankear: 0,
            cumplenRequisitos: 0,
          ),
        ),
      );
    await tester.pumpWidget(_app(r));
    await tester.pumpAndSettle();
    final boton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Aún no hay candidatos'),
    );
    expect(boton.onPressed, isNull);
    expect(find.text('Cumplen requisitos'), findsNothing);
  });

  testWidgets('si ya no existe, lo dice y ofrece Volver', (tester) async {
    comoTelefono(tester);
    final r = RepositorioFalso()..vacanteR = const Falla(NoEncontrado());
    await tester.pumpWidget(_app(r));
    await tester.pumpAndSettle();
    expect(find.text('Esto ya no está disponible.'), findsOneWidget);
    expect(find.text('Volver'), findsOneWidget);
  });
}
