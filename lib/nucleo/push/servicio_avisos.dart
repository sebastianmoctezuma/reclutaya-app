import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reclutaya_app/nucleo/config.dart';
import 'package:reclutaya_app/nucleo/plataforma/plataforma.dart';
import 'package:reclutaya_app/nucleo/util/esperar.dart';

/// Los avisos al celular (7-oct), detrás de una interfaz: la app nunca llama a
/// Firebase directo, y las pruebas usan uno falso.
abstract class ServicioAvisos {
  /// ¿Hay Firebase configurado en esta compilación?
  bool get disponible;
  String get plataforma;
  Future<void> iniciar();

  /// Pide permiso (la primera vez, el diálogo del sistema) y da el token; null si la
  /// persona no dio permiso o no hay avisos.
  Future<String?> pedirPermisoYToken();

  /// Firebase rota el token de vez en cuando: hay que volver a registrarlo.
  Stream<String> get tokensNuevos;

  /// Los `data` de los avisos que la persona tocó con la app abierta o en segundo plano.
  Stream<Map<String, dynamic>> get tocados;

  /// El aviso que abrió la app desde cerrada (si fue así).
  Future<Map<String, dynamic>?> tocadoAlAbrir();

  /// Borra el token EN EL TELÉFONO: deja de servir en Firebase, así que ningún aviso
  /// de la cuenta anterior llega aunque el servidor no se haya enterado (sesión
  /// vencida). El servidor lo da de baja solo cuando FCM le diga que ya no existe.
  Future<void> olvidarToken();
}

/// Sin Firebase configurado: la app funciona igual, sin avisos.
class AvisosApagados implements ServicioAvisos {
  @override
  bool get disponible => false;
  @override
  String get plataforma => Plataforma.esIOS ? 'ios' : 'android';
  @override
  Future<void> iniciar() async {}
  @override
  Future<String?> pedirPermisoYToken() async => null;
  @override
  Stream<String> get tokensNuevos => const Stream.empty();
  @override
  Stream<Map<String, dynamic>> get tocados => const Stream.empty();
  @override
  Future<Map<String, dynamic>?> tocadoAlAbrir() async => null;
  @override
  Future<void> olvidarToken() async {}
}

class AvisosFirebase implements ServicioAvisos {
  bool _listo = false;

  @override
  bool get disponible => true;

  @override
  String get plataforma => Plataforma.esIOS ? 'ios' : 'android';

  @override
  Future<void> iniciar() async {
    if (_listo) return;
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: Config.firebaseApiKey,
        appId: Plataforma.esIOS
            ? Config.firebaseAppIdIos
            : Config.firebaseAppIdAndroid,
        messagingSenderId: Config.firebaseSenderId,
        projectId: Config.firebaseProjectId,
        iosBundleId: 'com.reclutaya.app',
      ),
    );
    // Con la app abierta también se ve el aviso (iOS no lo muestra por defecto).
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
    _listo = true;
  }

  @override
  Future<String?> pedirPermisoYToken() async {
    await iniciar();
    final m = FirebaseMessaging.instance;
    final permiso = await m.requestPermission();
    if (permiso.authorizationStatus == AuthorizationStatus.denied) return null;
    // En iPhone el token de Firebase necesita antes el de APNs, que al abrir la app
    // por primera vez tarda un poco: se espera hasta 5 s (10 × 500 ms) en vez de
    // rendirse al primer intento.
    if (Plataforma.esIOS && await esperarValor(m.getAPNSToken) == null) {
      return null;
    }
    return await m.getToken();
  }

  @override
  Stream<String> get tokensNuevos => FirebaseMessaging.instance.onTokenRefresh;

  @override
  Stream<Map<String, dynamic>> get tocados =>
      FirebaseMessaging.onMessageOpenedApp.map((m) => m.data);

  @override
  Future<Map<String, dynamic>?> tocadoAlAbrir() async {
    await iniciar();
    return (await FirebaseMessaging.instance.getInitialMessage())?.data;
  }

  @override
  Future<void> olvidarToken() async {
    if (!_listo) return;
    try {
      await FirebaseMessaging.instance.deleteToken().timeout(
        const Duration(seconds: 4),
      );
    } on Object {
      // Sin red: el token sigue vivo; al volver a entrar se re-registra al usuario
      // nuevo (el servidor reasigna el token), así que no queda con el anterior.
    }
  }
}

final servicioAvisosProvider = Provider<ServicioAvisos>(
  (_) => Config.firebaseConfigurado ? AvisosFirebase() : AvisosApagados(),
);
