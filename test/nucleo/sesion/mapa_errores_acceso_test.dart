import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/nucleo/sesion/arranque_core.dart';

void main() {
  test('los errores de Supabase se traducen', () {
    expect(
      errorDeAcceso('invalid_credentials', 'Invalid login').mensaje,
      'Correo o contraseña incorrectos.',
    );
    expect(
      errorDeAcceso('email_not_confirmed', 'x').mensaje,
      startsWith('Tu correo aún no está verificado'),
    );
    expect(
      errorDeAcceso('otro', 'x').mensaje,
      'No se pudo entrar. Intenta de nuevo.',
    );
  });
}
