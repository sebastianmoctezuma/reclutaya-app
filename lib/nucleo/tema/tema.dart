import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:reclutaya_app/nucleo/tema/tipografia.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';

ThemeData temaClaro() => _tema(Tokens.claro);
ThemeData temaOscuro() => _tema(Tokens.oscuro);

ThemeData _tema(Tokens t) {
  final esquema = ColorScheme.fromSeed(
    seedColor: t.verde,
    brightness: t.esOscuro ? Brightness.dark : Brightness.light,
    primary: t.verde,
    secondary: t.naranja,
    surface: t.tarjeta,
    onSurface: t.tinta,
    error: t.rojo,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: t.papel,
    canvasColor: t.papel,
    textTheme: tipografia(t),
    extensions: [t],
    splashFactory: NoSplash.splashFactory,
    dividerColor: t.linea,
    cardTheme: CardThemeData(
      color: t.tarjeta,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radioGrande),
      ),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: t.tinta,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
      },
    ),
  );
}
