import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Entrar con Google o Apple (8-oct), lógica PURA. La app es solo para entrar: Google y
/// Apple son otra puerta a una cuenta que YA existe (Supabase la liga sola por correo).

enum ProveedorSocial { apple, google }

/// El nonce de un intento: 32 bytes al azar en base64 de URL. Viaja crudo a Supabase y
/// su SHA-256 a Google/Apple; Supabase comprueba que coincidan, así un token robado de
/// otro intento no sirve.
String nonceCrudo([Random? r]) {
  final azar = r ?? Random.secure();
  final bytes = List<int>.generate(32, (_) => azar.nextInt(256));
  return base64Url.encode(bytes).replaceAll('=', '');
}

/// Lo que se le pasa a Google o Apple: el SHA-256 del nonce crudo, en hexadecimal.
String nonceParaProveedor(String crudo) =>
    sha256.convert(utf8.encode(crudo)).toString();

/// Entró, pero ese correo no tiene un negocio en ReclutaYa (la app no crea cuentas).
/// Con Apple casi siempre es porque ocultó su correo: Apple manda uno de relevo que no
/// coincide con ninguna cuenta.
String mensajeSinCuenta(ProveedorSocial p) => switch (p) {
  ProveedorSocial.google =>
    'Esa cuenta de Google no tiene un negocio en ReclutaYa. '
        'Créalo en reclutaya.com o entra con el correo de tu cuenta.',
  ProveedorSocial.apple =>
    'No encontramos un negocio con ese correo. Para entrar con Apple, elige '
        '«Compartir mi correo» y usa el mismo de tu cuenta de ReclutaYa. Si antes lo '
        'ocultaste: Ajustes › tu nombre › Iniciar sesión con Apple › ReclutaYa › '
        'Dejar de usar, y vuelve a intentar.',
};
