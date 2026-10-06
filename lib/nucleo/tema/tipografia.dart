import 'package:flutter/material.dart';

import 'package:reclutaya_app/nucleo/tema/tokens.dart';

/// Poppins para títulos y cifras (500–800); Hanken Grotesk para texto (400–700).
TextTheme tipografia(Tokens t) {
  TextStyle p(double size, FontWeight w, {double? h, double ls = -0.02}) =>
      TextStyle(
        fontFamily: 'Poppins',
        fontSize: size,
        fontWeight: w,
        height: h ?? 1.15,
        letterSpacing: size * ls,
        color: t.tinta,
      );
  TextStyle hk(double size, FontWeight w, {Color? c, double h = 1.45}) =>
      TextStyle(
        fontFamily: 'HankenGrotesk',
        fontSize: size,
        fontWeight: w,
        height: h,
        color: c ?? t.tinta,
      );
  return TextTheme(
    displaySmall: p(34, FontWeight.w800),
    headlineMedium: p(26, FontWeight.w800),
    headlineSmall: p(21, FontWeight.w700),
    titleLarge: p(17, FontWeight.w700, ls: -0.015),
    titleMedium: p(15, FontWeight.w600, ls: -0.01),
    bodyLarge: hk(16, FontWeight.w400),
    bodyMedium: hk(14.5, FontWeight.w400),
    bodySmall: hk(12.5, FontWeight.w400, c: t.tintaSuave),
    labelLarge: hk(14, FontWeight.w700),
    labelMedium: hk(12, FontWeight.w700, c: t.tintaSuave),
    labelSmall: hk(11, FontWeight.w700, c: t.tintaTenue, h: 1.3),
  );
}
