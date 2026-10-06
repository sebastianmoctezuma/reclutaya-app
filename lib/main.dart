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
  await initializeDateFormatting('es_MX');
  await prepararVidrio();
  final sesion = await SesionSupabase.iniciar();
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
