import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/nucleo/util/esperar.dart';

void main() {
  test('da el valor en cuanto aparece, sin agotar los intentos', () async {
    var llamadas = 0;
    final v = await esperarValor<String>(
      () async => ++llamadas == 3 ? 'apns' : null,
      pausa: Duration.zero,
    );
    expect(v, 'apns');
    expect(llamadas, 3);
  });

  test('si nunca aparece, se rinde tras los intentos y da null', () async {
    var llamadas = 0;
    final v = await esperarValor<String>(() async {
      llamadas++;
      return null;
    }, pausa: Duration.zero);
    expect(v, isNull);
    expect(llamadas, 10);
  });

  test('un intento que truena cuenta como «todavía no»', () async {
    var llamadas = 0;
    final v = await esperarValor<String>(
      () async => ++llamadas < 2 ? throw Exception('aún no') : 'listo',
      pausa: Duration.zero,
    );
    expect(v, 'listo');
  });
}
