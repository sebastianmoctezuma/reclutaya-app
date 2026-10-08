/// Lo que llega por `--dart-define-from-file=defines/<sabor>.json`.
/// Nada de esto es secreto de servidor: la llave anon de Supabase es pública por
/// diseño, pero igual no se escribe en el código.
abstract final class Config {
  static const String sabor = String.fromEnvironment(
    'SABOR',
    defaultValue: 'prod',
  );
  static const String apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://app.reclutaya.com/api/movil/v1',
  );
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');

  // Firebase (avisos al celular, 7-oct). Valores PÚBLICOS de la app en la consola de
  // Firebase; sin ellos la app funciona igual, sin avisos.
  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
  );
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );
  static const String firebaseSenderId = String.fromEnvironment(
    'FIREBASE_SENDER_ID',
  );
  static const String firebaseAppIdIos = String.fromEnvironment(
    'FIREBASE_APP_ID_IOS',
  );
  static const String firebaseAppIdAndroid = String.fromEnvironment(
    'FIREBASE_APP_ID_ANDROID',
  );

  /// El cliente OAuth de iOS para «Continuar con Google» (8-oct). PÚBLICO: va dentro
  /// de la app; Supabase lo tiene en su lista de clientes autorizados.
  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue: '517846735413-2bl9rsj3figkr476mjo22q9kc9gav2bh.apps.googleusercontent.com',
  );

  /// La API v2 vive junto a la v1 (solo el registro del teléfono).
  static String get apiBaseV2 => apiBase.replaceFirst(RegExp(r'/v1$'), '/v2');

  static bool get firebaseConfigurado =>
      firebaseApiKey.isNotEmpty &&
      firebaseProjectId.isNotEmpty &&
      firebaseSenderId.isNotEmpty;

  static bool get esProduccion => sabor == 'prod';
  static bool get configurado =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
