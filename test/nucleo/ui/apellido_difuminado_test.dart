import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/nucleo/tema/tema.dart';
import 'package:reclutaya_app/nucleo/ui/apellido_difuminado.dart';

void main() {
  testWidgets('no usa filtros de imagen (rendimiento en listas)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: temaClaro(),
        home: const Scaffold(body: ApellidoDifuminado()),
      ),
    );
    expect(find.byType(ImageFiltered), findsNothing);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.bySemanticsLabel('Apellido oculto'), findsOneWidget);
  });
}
