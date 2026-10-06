import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/ranking.dart';
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
    'sin contactar: primer nombre, apellido difuminado, sin teléfono, la ficha de la IA',
    (tester) async {
      await tester.pumpWidget(
        _envuelve(
          FilaCandidato(fila: rankingEjemplo.visibles[0], alTocar: () {}),
        ),
      );
      expect(find.text('Ana'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Apellido oculto')), findsOneWidget);
      expect(find.textContaining('52'), findsNothing);
      expect(find.text('87'), findsOneWidget);
      expect(find.text('pts'), findsOneWidget);
      expect(find.text('Cumple 3 de 4'), findsOneWidget);
      expect(find.text('~20 min'), findsOneWidget);
      expect(find.text('Buena actitud'), findsOneWidget);
      expect(find.text('Vive cerca'), findsOneWidget);
      // Nada pedido: ni íconos de material ni chip de fase.
      expect(find.byKey(const ValueKey('mat-video')), findsNothing);
      expect(find.byKey(const ValueKey('mat-test')), findsNothing);
      expect(find.text('En proceso'), findsNothing);
    },
  );

  testWidgets(
    'el material aparece solo cuando ya se entregó (el documento pedido no)',
    (tester) async {
      await tester.pumpWidget(
        _envuelve(
          FilaCandidato(fila: rankingEjemplo.visibles[1], alTocar: () {}),
        ),
      );
      expect(find.byKey(const ValueKey('mat-video')), findsOneWidget);
      expect(find.byKey(const ValueKey('mat-test')), findsOneWidget);
      expect(find.text('74%'), findsOneWidget);
      expect(find.byKey(const ValueKey('mat-doc')), findsNothing);
      expect(find.text('En proceso'), findsOneWidget);
      expect(find.textContaining('Cumple'), findsNothing);
      expect(find.bySemanticsLabel(RegExp('Apellido oculto')), findsNothing);
    },
  );

  testWidgets('contratado y no respondió llevan su chip', (tester) async {
    await tester.pumpWidget(
      _envuelve(
        Column(
          children: [
            FilaCandidato(fila: rankingEjemplo.visibles[2], alTocar: () {}),
            FilaCandidato(
              fila: const FilaRanking(
                postulacionId: 'p9',
                ranking: 9,
                nombre: 'Rosa',
                fase: 'no_respondio',
              ),
              alTocar: () {},
            ),
          ],
        ),
      ),
    );
    expect(find.text('Contratado'), findsOneWidget);
    expect(find.text('No respondió'), findsOneWidget);
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
