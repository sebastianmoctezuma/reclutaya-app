import 'package:reclutaya_app/nucleo/sesion/acceso_social.dart';
import 'package:reclutaya_app/nucleo/sesion/acceso_social_core.dart';

/// La hoja de Google/Apple de mentira: devuelve un comprobante, o null (canceló).
class AccesoSocialFalso implements AccesoSocial {
  bool cancela = false;
  final pedidos = <ProveedorSocial>[];

  @override
  Future<CredencialSocial?> obtener(ProveedorSocial p) async {
    pedidos.add(p);
    if (cancela) return null;
    return CredencialSocial(proveedor: p, idToken: 'id-$p', nonce: 'n');
  }
}
