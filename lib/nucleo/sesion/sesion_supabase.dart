import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:reclutaya_app/nucleo/config.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/sesion/acceso_social_core.dart';
import 'package:reclutaya_app/nucleo/sesion/arranque_core.dart';
import 'package:reclutaya_app/nucleo/sesion/renovacion_core.dart';
import 'package:reclutaya_app/nucleo/sesion/sesion.dart';
import 'package:reclutaya_app/nucleo/util/resultado.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// La sesión vive en Keychain / Keystore, nunca en preferencias planas.
///
/// Con copia en memoria (12-oct): al arrancar, Supabase pregunta «¿hay sesión?» y
/// luego la pide, dos veces (al inicializar y al recuperarla): cuatro lecturas del
/// Keychain, cada una un viaje a la plataforma, antes del primer cuadro. Aquí se lee
/// UNA vez y las demás salen de la copia; cada escritura la actualiza.
class _AlmacenSeguro extends LocalStorage {
  _AlmacenSeguro();

  static const _s = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  static const _llave = 'ry_sesion';

  bool _leido = false;
  String? _copia;

  Future<String?> _leer() async {
    if (!_leido) {
      _copia = await _s.read(key: _llave);
      _leido = true;
    }
    return _copia;
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() => _leer();

  @override
  Future<bool> hasAccessToken() async => (await _leer()) != null;

  @override
  Future<void> persistSession(String persistSessionString) async {
    _copia = persistSessionString;
    _leido = true;
    await _s.write(key: _llave, value: persistSessionString);
  }

  @override
  Future<void> removePersistedSession() async {
    _copia = null;
    _leido = true;
    await _s.delete(key: _llave);
  }
}

class SesionSupabase extends Sesion {
  SesionSupabase._();

  static Future<SesionSupabase> iniciar() async {
    await Supabase.initialize(
      url: Config.supabaseUrl,
      publishableKey: Config.supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(localStorage: _AlmacenSeguro()),
    );
    return SesionSupabase._();
  }

  GoTrueClient get _auth => Supabase.instance.client.auth;

  @override
  bool get autenticado => _auth.currentSession != null;

  /// Solo «hay sesión» / «no hay». Los ERRORES del flujo de Supabase no pasan
  /// (12-oct): cuando una renovación en segundo plano falla por red, Supabase mete la
  /// excepción en este mismo flujo; el router y el provider de autenticación la recibían
  /// como un fallo sin manejar aunque la sesión seguía viva. Supabase ya la registra.
  /// Si Supabase cierra la sesión por su cuenta (el token fue rechazado de forma
  /// definitiva: contraseña cambiada, sesión revocada), se anota como vencimiento para
  /// que Entrar diga «Tu sesión terminó».
  @override
  Stream<bool> get cambios =>
      _auth.onAuthStateChange.handleError((Object _) {}).map((e) {
        if (e.event == AuthChangeEvent.signedOut &&
            e.signOutReason != null &&
            e.signOutReason != SignOutReason.userInitiated) {
          _vencio = true;
        }
        return e.session != null;
      }).distinct();

  @override
  String? get token => _auth.currentSession?.accessToken;

  /// null = la sesión ya no vale (el proveedor la rechazó DE FORMA DEFINITIVA). Un fallo
  /// de RED no es eso: se lanza `SinRed` y la sesión se queda (12-oct; ver
  /// `renovacion_core.dart`: antes, una falla de red al renovar te sacaba de la app).
  @override
  Future<String?> renovar() async {
    try {
      final r = await _auth.refreshSession().timeout(
        const Duration(seconds: 10),
      );
      return r.session?.accessToken;
    } on AuthException catch (e) {
      // ¿Alguien más ya la renovó mientras tanto? Al volver del fondo, Supabase renueva
      // solo: si su renovación ganó, la sesión es válida y no hay nada que vencer.
      final actual = _auth.currentSession;
      if (actual != null && !actual.isExpired) return actual.accessToken;
      final fallo = clasificarFalloRenovacion(
        reintentable:
            e is AuthRetryableFetchException || e is AuthUnknownException,
        sinSesion: e is AuthSessionMissingException,
        estado: int.tryParse(e.statusCode ?? ''),
      );
      if (fallo == FalloRenovacion.sinRed) throw const SinRed();
      return null;
    } on Exception {
      throw const SinRed();
    }
  }

  @override
  Future<String?> tokenVigente() async {
    final s = _auth.currentSession;
    if (s == null) return null;
    if (!debeRenovarAntes(expiraEn: s.expiresAt, ahora: DateTime.now())) {
      return s.accessToken;
    }
    try {
      return await renovar() ?? s.accessToken;
    } on SinRed {
      // Sin red no se sabe; se manda el que hay y el servidor decide.
      return s.accessToken;
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
      debugPrint('signInWithPassword: ${e.statusCode} ${e.code} ${e.message}');
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
      debugPrint('signInWithIdToken: ${e.statusCode} ${e.code} ${e.message}');
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
