import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/funciones/negocio/novedades/controlador_avisos.dart';
import 'package:reclutaya_app/nucleo/rutas/rutas.dart';
import 'package:reclutaya_app/nucleo/tema/tema.dart';

/// Una sola raíz Material; en iOS, transiciones y widgets Cupertino vía
/// `adaptativos`. Tema claro y oscuro siguiendo el sistema.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref
      ..watch(limpiezaSesionProvider)
      ..watch(avisosSesionProvider);
    return MaterialApp.router(
      title: 'ReclutaYa',
      routerConfig: ref.watch(routerProvider),
      theme: temaClaro(),
      darkTheme: temaOscuro(),
      // Siempre clara (decisión del dueño, 6-oct): verde arriba que se funde con el
      // blanco hacia abajo.
      themeMode: ThemeMode.light,
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
    );
  }
}
