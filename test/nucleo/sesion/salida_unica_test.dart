import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// SALIDA ÚNICA (7-oct): cerrar sesión desde la app pasa SIEMPRE por
// `cerrarSesionProvider`, que primero da de baja el teléfono (avisos) y luego sale.
// Una pantalla que llamara `sesion.salir()` directo dejaría el teléfono recibiendo
// avisos de la cuenta anterior (le pasó a Controlify, BUG_025).
void main() {
  test('nadie fuera de la salida única llama a .salir()', () {
    const permitidos = {
      'lib/nucleo/sesion/sesion.dart',
      'lib/nucleo/sesion/sesion_supabase.dart',
      'lib/funciones/negocio/novedades/controlador_avisos.dart',
    };
    final infractores = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final ruta = f.path.replaceAll(r'\', '/');
      if (permitidos.contains(ruta)) continue;
      if (RegExp(r'\.salir\(\)').hasMatch(f.readAsStringSync())) {
        infractores.add(ruta);
      }
    }
    expect(infractores, isEmpty);
  });
}
