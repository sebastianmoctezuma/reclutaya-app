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

  static bool get esProduccion => sabor == 'prod';
  static bool get configurado =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
