import 'package:flutter/foundation.dart';

/// ÚNICO lugar que pregunta en qué sistema corre la app. Una pantalla nunca
/// consulta `Platform` por su cuenta: usa `adaptativos.dart`.
abstract final class Plataforma {
  @visibleForTesting
  static TargetPlatform? forzada;

  static TargetPlatform get actual => forzada ?? defaultTargetPlatform;
  static bool get esIOS => actual == TargetPlatform.iOS;
  static bool get esAndroid => actual == TargetPlatform.android;
}
