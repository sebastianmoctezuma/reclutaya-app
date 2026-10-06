import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Solo `lib/nucleo/plataforma/` pregunta en qué sistema corre la app.
void main() {
  test('solo lib/nucleo/plataforma pregunta por la plataforma', () {
    final patron = RegExp(
      r'Platform\.is(IOS|Android)|defaultTargetPlatform|Theme\.of\([^)]*\)\.platform',
    );
    final culpables = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (f) =>
              f.path.endsWith('.dart') &&
              !f.path.startsWith('lib/nucleo/plataforma/'),
        )
        .where((f) => patron.hasMatch(f.readAsStringSync()))
        .map((f) => f.path)
        .toList();
    expect(
      culpables,
      isEmpty,
      reason: 'Usa Plataforma/adaptativos: ${culpables.join(', ')}',
    );
  });
}
