import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ningún widget escribe un color a mano: todo sale de `lib/nucleo/tema/tokens.dart`.
void main() {
  test('solo lib/nucleo/tema escribe Color(0x…)', () {
    final culpables = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'))
        .where((f) => !f.path.startsWith('lib/nucleo/tema/'))
        .where(
          (f) =>
              RegExp(r'Color\(0x[0-9A-Fa-f]{8}\)')
                  .hasMatch(f.readAsStringSync()),
        )
        .map((f) => f.path)
        .toList();
    expect(
      culpables,
      isEmpty,
      reason: 'Usa los tokens: ${culpables.join(', ')}',
    );
  });
}
