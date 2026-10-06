import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/nucleo/config.dart';

void main() {
  test('sin defines, apunta a producción y se sabe no configurada', () {
    expect(Config.apiBase, 'https://app.reclutaya.com/api/movil/v1');
    expect(Config.esProduccion, isTrue);
    expect(Config.configurado, isFalse);
  });
}
