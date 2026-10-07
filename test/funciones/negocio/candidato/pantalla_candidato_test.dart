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
    'contactada: el nombre una sola vez, la fase, las razones y los datos',
    (tester) async {
      comoTelefono(tester);
      await tester.pumpWidget(_app(RepositorioFalso()));
      await tester.pumpAndSettle();
      expect(find.text('Luis Pérez Ruiz'), findsOneWidget);
      expect(find.text('En proceso'), findsOneWidget);
      expect(find.text('Experiencia en cocina rápida'), findsOneWidget);
      expect(find.text('Vive cerca'), findsOneWidget);
      expect(find.text('Copiar'), findsOneWidget);
      expect(find.text('1 año 2 meses'), findsOneWidget);
    },
  );

  testWidgets(
    'el test con su integridad y las respuestas alineadas, como la web',
    (tester) async {
      comoTelefono(tester);
      await tester.pumpWidget(_app(RepositorioFalso()));
      await tester.pumpAndSettle();
      await _bajarHasta(tester, find.text('Integridad aceptable'));
      expect(find.text('Integridad aceptable'), findsOneWidget);
      expect(find.text('Colaborador'), findsOneWidget);
      await _bajarHasta(tester, find.text('Escolaridad'));
      expect(find.text('No cumple'), findsOneWidget);
      // Como la web: solo se marca lo que no cumple, no cada requisito.
      expect(find.text('Requisito'), findsNothing);
      // Todas las preguntas arrancan en el mismo margen (antes salían centradas).
      final x1 = tester.getTopLeft(find.text('¿Tienes licencia?')).dx;
      final x2 = tester
          .getTopLeft(find.text('¿Disponibilidad fines de semana?'))
          .dx;
      final x3 = tester.getTopLeft(find.text('Escolaridad')).dx;
      expect(x1, x2);
      expect(x1, x3);
    },
  );
}
