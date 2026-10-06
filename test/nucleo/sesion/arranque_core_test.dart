import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/nucleo/sesion/arranque_core.dart';

void main() {
  test('sin sesión → entrar', () {
    expect(
      destinoArranque(haySesion: false, tipoYo: null),
      DestinoArranque.entrar,
    );
  });

  test('con sesión de negocio → negocio', () {
    expect(
      destinoArranque(haySesion: true, tipoYo: 'negocio'),
      DestinoArranque.negocio,
    );
  });

  test('con sesión de candidato → aviso y salir', () {
    expect(
      destinoArranque(haySesion: true, tipoYo: 'candidato'),
      DestinoArranque.candidatoNoSoportado,
    );
  });

  test(
    'con sesión pero /yo falló → negocio (la pantalla muestra el error)',
    () {
      expect(
        destinoArranque(haySesion: true, tipoYo: null),
        DestinoArranque.negocio,
      );
    },
  );
}
