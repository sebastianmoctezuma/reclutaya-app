import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// El vidrio nativo va SOLO detrás de `Vidrio`: nadie más importa liquid_design.
void main() {
  test('solo lib/nucleo/vidrio importa liquid_design', () {
    final culpables = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (f) =>
              f.path.endsWith('.dart') &&
              !f.path.startsWith('lib/nucleo/vidrio/'),
        )
        .where((f) => f.readAsStringSync().contains('package:liquid_design/'))
        .map((f) => f.path)
        .toList();
    expect(culpables, isEmpty, reason: 'Usa Vidrio: ${culpables.join(', ')}');
  });
}
