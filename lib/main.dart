import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:reclutaya_app/app.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/nucleo/config.dart';
import 'package:reclutaya_app/nucleo/sesion/providers.dart';
import 'package:reclutaya_app/nucleo/sesion/sesion_supabase.dart';
import 'package:reclutaya_app/nucleo/vidrio/vidrio_nativo.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Las tres son independientes y cada una espera a la plataforma: en paralelo, el
  // arranque tarda lo que la más lenta (la sesión), no la suma (12-oct).
  final (_, _, sesion) = await (
    initializeDateFormatting('es_MX'),
    prepararVidrio(),
    SesionSupabase.iniciar(),
  ).wait;
  final app = ProviderScope(
    overrides: [sesionProvider.overrideWithValue(sesion)],
    retry: sinReintentos,
    child: const App(),
  );
  if (Config.sentryDsn.isEmpty) {
    runApp(app);
    return;
  }
  // Solo errores, sin datos personales: la regla de la web.
  await SentryFlutter.init((o) {
    o
      ..dsn = Config.sentryDsn
      ..environment = Config.sabor
      ..sendDefaultPii = false
      ..tracesSampleRate = 0;
  }, appRunner: () => runApp(app));
}
