import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// El visor de pruebas mide 800×600 por defecto y las listas son perezosas:
/// lo que queda fuera de la pantalla no se construye. Un iPhone de 6.3".
void comoTelefono(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1206, 2622)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}
