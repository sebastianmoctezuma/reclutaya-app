import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:reclutaya_app/nucleo/config.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/sesion/acceso_social_core.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Lo que devuelve Google o Apple al entrar: su comprobante y el nonce CRUDO del intento.
class CredencialSocial {
  const CredencialSocial({
    required this.proveedor,
    required this.idToken,
    required this.nonce,
  });

  final ProveedorSocial proveedor;
  final String idToken;
  final String nonce;
}

/// Abre la hoja NATIVA de Google o de Apple (8-oct): sin navegador ni «supabase.co».
/// null = la persona canceló (no es un error). Las pruebas lo sustituyen.
abstract class AccesoSocial {
  Future<CredencialSocial?> obtener(ProveedorSocial p);
}

class AccesoSocialNativo implements AccesoSocial {
  @override
  Future<CredencialSocial?> obtener(ProveedorSocial p) => switch (p) {
    ProveedorSocial.google => _google(),
    ProveedorSocial.apple => _apple(),
  };

  Future<CredencialSocial?> _google() async {
    final crudo = nonceCrudo();
    final google = GoogleSignIn.instance;
    try {
      // Se configura en cada intento: el nonce es de este intento y de ningún otro.
      await google.initialize(
        clientId: Config.googleIosClientId,
        nonce: nonceParaProveedor(crudo),
      );
      final cuenta = await google.authenticate();
      final id = cuenta.authentication.idToken;
      // Se suelta la cuenta de Google en el teléfono: la próxima vez (otra cuenta,
      // «Agregar cuenta») vuelve a preguntar cuál.
      await google.signOut();
      if (id == null) {
        throw const Servidor('Google no respondió. Intenta de nuevo.');
      }
      return CredencialSocial(
        proveedor: ProveedorSocial.google,
        idToken: id,
        nonce: crudo,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw const Servidor('No se pudo entrar con Google. Intenta de nuevo.');
    }
  }

  Future<CredencialSocial?> _apple() async {
    final crudo = nonceCrudo();
    try {
      final c = await SignInWithApple.getAppleIDCredential(
        scopes: const [AppleIDAuthorizationScopes.email],
        nonce: nonceParaProveedor(crudo),
      );
      final id = c.identityToken;
      if (id == null) {
        throw const Servidor('Apple no respondió. Intenta de nuevo.');
      }
      return CredencialSocial(
        proveedor: ProveedorSocial.apple,
        idToken: id,
        nonce: crudo,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      throw const Servidor('No se pudo entrar con Apple. Intenta de nuevo.');
    }
  }
}

final accesoSocialProvider = Provider<AccesoSocial>(
  (_) => AccesoSocialNativo(),
);
