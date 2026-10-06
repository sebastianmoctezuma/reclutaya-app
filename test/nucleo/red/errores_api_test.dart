import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';

void main() {
  test('cada HTTP del contrato cae en su error', () {
    expect(
      errorDeRespuesta(401, {
        'error': {'codigo': 'no_autenticado', 'mensaje': 'x'},
      }),
      isA<SesionVencida>(),
    );
    expect(errorDeRespuesta(403, null), isA<Prohibido>());
    expect(errorDeRespuesta(404, null), isA<NoEncontrado>());
    expect(errorDeRespuesta(429, null, retryAfter: '7'), const Limite(7));
    expect(errorDeRespuesta(500, null), isA<Servidor>());
    expect(errorDeRespuesta(503, null), isA<Servidor>());
  });

  test(
    'el mensaje del servidor se usa tal cual si viene; si no, uno nuestro',
    () {
      expect(
        errorDeRespuesta(500, {
          'error': {'codigo': 'interno', 'mensaje': 'Falló X'},
        }).mensaje,
        'Falló X',
      );
      expect(
        errorDeRespuesta(500, null).mensaje,
        'No se pudo cargar. Intenta de nuevo.',
      );
    },
  );

  test('Retry-After se acota entre 1 y 30 segundos', () {
    expect(segundosEspera(null), 1);
    expect(segundosEspera('0'), 1);
    expect(segundosEspera('12'), 12);
    expect(segundosEspera('900'), 30);
    expect(segundosEspera('basura'), 1);
  });
}
