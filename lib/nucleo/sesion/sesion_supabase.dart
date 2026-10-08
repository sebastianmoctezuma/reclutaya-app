import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:reclutaya_app/nucleo/config.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/sesion/acceso_social_core.dart';
import 'package:reclutaya_app/nucleo/sesion/arranque_core.dart';
import 'package:reclutaya_app/nucleo/sesion/sesion.dart';
import 'package:reclutaya_app/nucleo/util/resultado.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// La sesión vive en Keychain / Keystore, nunca en preferencias planas.
class _AlmacenSeguro extends LocalStorage {
  const _AlmacenSeguro();

  static const _s = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  static const _llave = 'ry_sesion';

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() => _s.read(key: _llave);

  @override
  Future<bool> hasAccessToken() async => (await _s.read(key: _llave)) != null;

  @override
  Future<void> persistSession(String persistSessionString) =>
      _s.write(key: _llave, value: persistSessionString);

  @override
  Future<void> removePersistedSession() => _s.delete(key: _llave);
}

class SesionSupabase extends Sesion {
  SesionSupabase._();

  static Future<SesionSupabase> iniciar() async {
    await Supabase.initialize(
      url: Config.supabaseUrl,
      publishableKey: Config.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        localStorage: _AlmacenSeguro(),
      ),
    );
    return SesionSupabase._();
  }

  GoTrueClient get _auth => Supabase.instance.client.auth;

  @override
  bool get autenticado => _auth.currentSession != null;

  @override
  Stream<bool> get cambios =>
      _auth.onAuthStateChange.map((e) => e.session != null).distinct();

  @override
  String? get token => _auth.currentSession?.accessToken;

  /// null = la sesión ya no vale (el proveedor la rechazó). Un fallo de RED
  /// no es eso: se lanza `SinRed` y la sesión se queda.
  @override
  Future<String?> renovar() async {
    try {
      final r = await _auth.refreshSession().timeout(
        const Duration(seconds: 10),
      );
      return r.session?.accessToken;
    } on AuthException {
      return null;
    } on Exception {
      throw const SinRed();
    }
  }

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

  // ── Varias cuentas (8-oct) ──

  @override
  Future<void> Function()? alVencer;

  @override
  String? get refreshToken => _auth.currentSession?.refreshToken;

  @override
  String? get correo => _auth.currentUser?.email;

  @override
  Future<bool> usarCuenta(String refreshToken) async {
    try {
      final r = await _auth
          .setSession(refreshToken)
          .timeout(const Duration(seconds: 10));
      return r.session != null;
    } on AuthException {
      return false;
    } on Exception {
      throw const SinRed();
    }
  }

  /// Directo al endpoint de Supabase Auth: el cliente solo maneja UNA sesión, y
  /// renovar otra cuenta con él la volvería la activa.
  static final _http = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      validateStatus: (_) => true,
    ),
  );

  @override
  Future<({String acceso, String refresh})?> renovarAparte(
    String refreshToken,
  ) async {
    final Response<dynamic> r;
    try {
      r = await _http.post<dynamic>(
        '${Config.supabaseUrl}/auth/v1/token',
        queryParameters: {'grant_type': 'refresh_token'},
        data: {'refresh_token': refreshToken},
        options: Options(headers: {'apikey': Config.supabaseAnonKey}),
      );
    } on DioException {
      throw const SinRed();
    }
    final cuerpo = r.data;
    if (r.statusCode == 200 && cuerpo is Map) {
      final acceso = cuerpo['access_token'];
      final refresh = cuerpo['refresh_token'];
      if (acceso is String && refresh is String) {
        return (acceso: acceso, refresh: refresh);
      }
    }
    if (r.statusCode == 400 || r.statusCode == 401 || r.statusCode == 403) {
      return null;
    }
    throw const SinRed();
  }

  @override
  Future<void> revocar(String accesoToken) async {
    try {
      await _http.post<dynamic>(
        '${Config.supabaseUrl}/auth/v1/logout',
        queryParameters: {'scope': 'local'},
        options: Options(
          headers: {
            'apikey': Config.supabaseAnonKey,
            'Authorization': 'Bearer $accesoToken',
          },
        ),
      );
    } on DioException {
      // Sin red: la sesión queda viva hasta que caduque; no hay nada más que hacer.
    }
  }

  @override
  Future<Resultado<void>> entrar(String correo, String contrasena) async {
    try {
      await _auth
          .signInWithPassword(email: correo.trim(), password: contrasena)
          .timeout(const Duration(seconds: 15));
      return const Exito(null);
    } on AuthException catch (e) {
      return Falla(errorDeAcceso(e.code ?? '', e.message));
    } on TimeoutException {
      return const Falla(SinRed());
    } on Exception {
      return const Falla(SinRed());
    }
  }

  @override
  Future<Resultado<void>> entrarConToken({
    required ProveedorSocial proveedor,
    required String idToken,
    required String nonce,
  }) async {
    try {
      await _auth
          .signInWithIdToken(
            provider: proveedor == ProveedorSocial.apple
                ? OAuthProvider.apple
                : OAuthProvider.google,
            idToken: idToken,
            nonce: nonce,
          )
          .timeout(const Duration(seconds: 15));
      return const Exito(null);
    } on AuthException catch (e) {
      return Falla(errorDeAcceso(e.code ?? '', e.message));
    } on TimeoutException {
      return const Falla(SinRed());
    } on Exception {
      return const Falla(SinRed());
    }
  }

  @override
  Future<void> salir() async {
    try {
      await _auth.signOut().timeout(const Duration(seconds: 10));
    } on Exception {
      // Aunque Supabase no conteste, la sesión local se tira.
    }
  }
}
