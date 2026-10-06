import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:reclutaya_app/funciones/negocio/ranking/fila_candidato.dart';
import 'package:reclutaya_app/nucleo/tema/tema.dart';

import '../../../apoyo/datos.dart';

// Dentro de una tarjeta tocable las etiquetas de accesibilidad se fusionan:
// «Apellido oculto» se busca como parte del texto, no exacta.
Widget _envuelve(Widget w) => MaterialApp(
  theme: temaClaro(),
  home: Scaffold(body: ListView(children: [w])),
);

void main() {
  setUpAll(() => initializeDateFormatting('es_MX'));

  testWidgets(
    'sin contactar: primer nombre, apellido difuminado, sin teléfono',
    (tester) async {
      await tester.pumpWidget(
        _envuelve(
          FilaCandidato(fila: rankingEjemplo.visibles[0], alTocar: () {}),
        ),
      );
      expect(find.text('Ana'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Apellido oculto')), findsOneWidget);
      expect(find.textContaining('52'), findsNothing);
      expect(find.text('87 pts'), findsOneWidget);
      expect(find.text('Cumple 3 de 4'), findsOneWidget);
      expect(find.textContaining('a 20 min'), findsOneWidget);
    },
  );

  testWidgets(
    'contactado con video recibido: chips, y sin «Cumple» si no pide requisitos',
    (tester) async {
      await tester.pumpWidget(
        _envuelve(
          FilaCandidato(fila: rankingEjemplo.visibles[1], alTocar: () {}),
        ),
      );
      expect(find.text('Contactado'), findsOneWidget);
      expect(find.text('Video recibido'), findsOneWidget);
      expect(find.text('Test respondido'), findsOneWidget);
      expect(find.textContaining('Cumple'), findsNothing);
      expect(find.bySemanticsLabel(RegExp('Apellido oculto')), findsNothing);
    },
  );

  testWidgets('contratado muestra su chip', (tester) async {
    await tester.pumpWidget(
      _envuelve(
        FilaCandidato(fila: rankingEjemplo.visibles[2], alTocar: () {}),
      ),
    );
    expect(find.text('Contratado'), findsOneWidget);
  });

  testWidgets('bloqueado: fila difuminada con su puntaje', (tester) async {
    await tester.pumpWidget(
      _envuelve(FilaBloqueada(bloqueado: rankingEjemplo.bloqueados[0])),
    );
    expect(find.textContaining('Bloqueado'), findsOneWidget);
    expect(find.textContaining('41 pts'), findsOneWidget);
  });

  testWidgets('el nombre usa todo el ancho libre (sin Spacer a medias)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _envuelve(
        FilaCandidato(fila: rankingEjemplo.visibles[1], alTocar: () {}),
      ),
    );
    expect(
      find.descendant(
        of: find.byType(FilaCandidato),
        matching: find.byType(Spacer),
      ),
      findsNothing,
    );
  });
}
