import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/nucleo/tema/tema.dart';
import 'package:reclutaya_app/nucleo/vidrio/vidrio.dart';

void main() {
  testWidgets('con reducir movimiento o alto contraste, el vidrio es sólido', (
    tester,
  ) async {
    late bool solido;
    await tester.pumpWidget(
      MaterialApp(
        theme: temaClaro(),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (c) {
              solido = vidrioSolido(c);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(solido, isTrue);
  });

  testWidgets('sin ajustes de accesibilidad, no es sólido', (tester) async {
    late bool solido;
    await tester.pumpWidget(
      MaterialApp(
        theme: temaClaro(),
        home: Builder(
          builder: (c) {
            solido = vidrioSolido(c);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(solido, isFalse);
  });
}
