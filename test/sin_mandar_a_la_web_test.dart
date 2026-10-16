import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guardián (15-oct, revisión de Apple 2.1(b) / 3.1.3): la app es de solo lectura para
/// el equipo de una empresa y ningún texto debe mandar a la persona a hacer algo fuera de
/// ella (crear una cuenta, publicar, comprar). Las URLs de términos, aviso y recuperar
/// contraseña sí pueden estar: no son llamados a hacer algo de pago.
void main() {
  test('ningún texto manda a la web a crear, publicar o comprar', () {
    final prohibidos = RegExp(
      r'desde la web|en la web|Créalo en|Crea tu cuenta en|compra(lo|los)? en|reclutaya\.com/(pagos|precios|planes)',
      caseSensitive: false,
    );
    final hallazgos = <String>[];
    for (final f in Directory(
      'lib',
    ).listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart') || f.path.endsWith('.g.dart')) continue;
      final lineas = f.readAsLinesSync();
      for (var i = 0; i < lineas.length; i++) {
        final l = lineas[i].trimLeft();
        if (l.startsWith('//')) continue;
        if (prohibidos.hasMatch(l)) hallazgos.add('${f.path}:${i + 1}: $l');
      }
    }
    expect(hallazgos, isEmpty, reason: hallazgos.join('\n'));
  });
}
