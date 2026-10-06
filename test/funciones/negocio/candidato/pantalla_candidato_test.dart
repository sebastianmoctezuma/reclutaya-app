import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:reclutaya_app/funciones/negocio/candidato/pantalla_candidato.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
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
    home: const PantallaCandidato(postulacionId: 'p2'),
  ),
);

Future<void> _bajarHasta(WidgetTester tester, Finder f) => tester
    .dragUntilVisible(f, find.byType(CustomScrollView), const Offset(0, -300));

void main() {
  setUpAll(() => initializeDateFormatting('es_MX'));

  testWidgets('sin contactar: nombre parcial, sin teléfono, video pedido', (
    tester,
  ) async {
    comoTelefono(tester);
    final r = RepositorioFalso()
      ..candidatoR = const Exito(fichaCandidatoSinContactar);
    await tester.pumpWidget(_app(r));
    await tester.pumpAndSettle();
    expect(find.text('Ana P.'), findsWidgets);
    expect(find.textContaining('5218'), findsNothing);
    expect(find.text('Copiar'), findsNothing);
    await _bajarHasta(tester, find.text('Pedido, aún no llega'));
    expect(find.text('Pedido, aún no llega'), findsWidgets);
    await _bajarHasta(tester, find.text('Test enviado, sin responder'));
    expect(find.text('Test enviado, sin responder'), findsOneWidget);
  });

  testWidgets(
    'contactada: teléfono con Copiar, test e integridad, respuestas',
    (tester) async {
      comoTelefono(tester);
      await tester.pumpWidget(_app(RepositorioFalso()));
      await tester.pumpAndSettle();
      expect(find.text('Luis Pérez Ruiz'), findsWidgets);
      expect(find.text('Copiar'), findsOneWidget);
      expect(find.text('1 año 2 meses'), findsOneWidget);
      await _bajarHasta(tester, find.text('Integridad aceptable'));
      expect(find.text('Integridad aceptable'), findsOneWidget);
      expect(find.text('Colaborador'), findsOneWidget);
      await _bajarHasta(tester, find.text('No cumple'));
      expect(find.text('No cumple'), findsOneWidget);
      expect(find.text('Requisito'), findsWidgets);
    },
  );
}
