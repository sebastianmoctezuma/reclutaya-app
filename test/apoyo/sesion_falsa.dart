import 'dart:async';

import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/sesion/acceso_social_core.dart';
import 'package:reclutaya_app/nucleo/sesion/sesion.dart';
import 'package:reclutaya_app/nucleo/util/resultado.dart';

/// La sesión de mentira de las pruebas de pantallas.
class SesionFalsa extends Sesion {
  Resultado<void> entrarR = const Exito(null);
  int salidas = 0;
  bool _autenticado = false;
  final _cambios = StreamController<bool>.broadcast();

  @override
  bool get autenticado => _autenticado;

  @override
  Stream<bool> get cambios => _cambios.stream;

  @override
  String? get token => _autenticado ? 't' : null;

  @override
  Future<String?> renovar() async => token;

  bool _vencio = false;

  @override
  bool consumirVencimiento() {
    final v = _vencio;
    _vencio = false;
    return v;
  }

  @override
  Future<void> sesionVencida() {
    final decide = alVencer;
    if (decide != null) return decide();
    return salirPorVencimiento();
  }

  @override
  Future<void> salirPorVencimiento() {
    _vencio = true;
    return salir();
  }

  // ── Varias cuentas ──
  @override
  Future<void> Function()? alVencer;

  /// Los refresh que el «servidor» acepta, y a qué correo pertenecen.
  final validos = <String, String>{};
  @override
  String? refreshToken;
  @override
  String? correo;
  final revocados = <String>[];
  int usadas = 0;

  /// Simula estar sin red en las operaciones de cuentas.
  bool sinRed = false;

  @override
  Future<bool> usarCuenta(String r) async {
    if (sinRed) throw const SinRed();
    usadas++;
    final c = validos[r];
    if (c == null) return false;
    validos.remove(r);
    refreshToken = '$r+';
    validos[refreshToken!] = c;
    correo = c;
    return true;
  }

  @override
  Future<({String acceso, String refresh})?> renovarAparte(String r) async {
    if (sinRed) throw const SinRed();
    final c = validos[r];
    if (c == null) return null;
    validos.remove(r);
    validos['$r+'] = c;
    return (acceso: 'acc-$c', refresh: '$r+');
  }

  @override
  Future<void> revocar(String accesoToken) async => revocados.add(accesoToken);

  @override
  Future<Resultado<void>> entrar(String correo, String contrasena) async {
    if (entrarR is Exito) {
      _autenticado = true;
      _cambios.add(true);
    }
    return entrarR;
  }

  /// Entrar con Google o Apple: misma respuesta que `entrarR`.
  final entradasSociales = <ProveedorSocial>[];
  @override
  Future<Resultado<void>> entrarConToken({
    required ProveedorSocial proveedor,
    required String idToken,
    required String nonce,
  }) {
    entradasSociales.add(proveedor);
    return entrar('$proveedor@social', 'x');
  }

  @override
  Future<void> salir() async {
    salidas++;
    _autenticado = false;
    _cambios.add(false);
  }
}
