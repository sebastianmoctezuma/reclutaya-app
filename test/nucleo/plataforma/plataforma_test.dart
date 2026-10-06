import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/nucleo/plataforma/plataforma.dart';

void main() {
  tearDown(() => Plataforma.forzada = null);

  test('se puede forzar la plataforma en pruebas', () {
    Plataforma.forzada = TargetPlatform.iOS;
    expect(Plataforma.esIOS, isTrue);
    expect(Plataforma.esAndroid, isFalse);
    Plataforma.forzada = TargetPlatform.android;
    expect(Plataforma.esAndroid, isTrue);
  });
}
