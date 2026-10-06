import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/tema/tema.dart';
import 'package:reclutaya_app/nucleo/ui/estados.dart';

void main() {
  testWidgets('EstadoError muestra el mensaje del error y Reintentar', (
    tester,
  ) async {
    var toques = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: temaClaro(),
        home: Scaffold(
          body: EstadoError(
            error: const Servidor(),
            alReintentar: () => toques++,
          ),
        ),
      ),
    );
    expect(find.text('No se pudo cargar. Intenta de nuevo.'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    expect(toques, 1);
  });

  testWidgets('con NoEncontrado el botón dice Volver', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: temaClaro(),
        home: Scaffold(
          body: EstadoError(error: const NoEncontrado(), alReintentar: () {}),
        ),
      ),
    );
    expect(find.text('Volver'), findsOneWidget);
  });
}
