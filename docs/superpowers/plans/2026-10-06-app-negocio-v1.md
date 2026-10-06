# App nativa de ReclutaYa — paso 2 (negocio, solo lectura) · Plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Una app Flutter (iPhone y Android) con la que el negocio entra con su cuenta de siempre y ve Inicio, vacantes, ficha de vacante, ranking y ficha de candidato, tal como los sirve la API móvil v1, con vidrio líquido nativo de Apple en iOS 26 y la identidad de la web.

**Architecture:** Secciones por función (`funciones/negocio/*`) sobre un `nucleo` (tema, vidrio, plataforma, red, sesión, rutas, ui). Riverpod para el estado, go_router con guardas, un solo cliente HTTP (dio) con política de reintento pura, Supabase para la sesión guardada en Keychain/Keystore. El vidrio y la detección de plataforma viven detrás de componentes propios; dos pruebas guardián impiden que se cuelen fuera.

**Tech Stack:** Flutter 3.47.2 (stable) · Dart 3 · flutter_riverpod · go_router · dio · json_serializable + build_runner · supabase_flutter + flutter_secure_storage · liquid_design ^0.4 · video_player + chewie · url_launcher · cached_network_image · intl · sentry_flutter · very_good_analysis · http_mock_adapter (pruebas).

**Spec:** `docs/superpowers/specs/2026-10-06-app-negocio-v1-design.md` (este repo). Contrato de la API: `reclutaya-web/docs/movil/api-v1.md`.

## Global Constraints

- Identificador `com.reclutaya.app` en iOS y Android; nombre visible «ReclutaYa». iOS mínimo 15.0; Android `minSdk` 24.
- La app **no reimplementa reglas del producto** ni deriva datos enmascarados: no compone teléfonos, no revela apellidos, no guarda URLs firmadas. Nada de la API se escribe en disco.
- Vidrio nativo (`liquid_design`) **solo** en barras, segmentados, botones flotantes y hojas; **nunca** en filas de lista ni tarjetas. Solo `lib/nucleo/vidrio/` importa `liquid_design`. Solo `lib/nucleo/plataforma/` consulta `Platform`/`defaultTargetPlatform`.
- Tokens en `lib/nucleo/tema/tokens.dart`; ningún widget escribe `Color(0x…)` fuera de `lib/nucleo/tema/`.
- Fuentes empaquetadas (Poppins 500–800, Hanken Grotesk 400–700); nunca descargadas en tiempo de ejecución.
- Toda petición con tiempo límite: 10 s conectar, 20 s recibir. 401 → renovar y reintentar UNA vez, luego login; 429 → esperar `Retry-After` (tope 30 s) y reintentar UNA vez; 5xx y sin red → no reintentar solo; 500 **nunca** manda al login.
- Textos en español de México, sin emojis. Nunca «PyME» ni «negocios pequeños».
- Sentry con `sendDefaultPii: false`; nunca el token ni cuerpos de respuesta en logs.
- Antes de cualquier push: `tool/verificar.sh` en verde (`dart format --set-exit-if-changed`, `flutter analyze`, `flutter test`, `flutter build apk --debug`). Los commits los hace el dueño: el plan indica qué se comitearía, pero no se corre `git commit`.
- Archivos generados (`*.g.dart`) se versionan. `defines/*.json` no se versionan (solo `defines/prod.example.json`).

## Review Focus

1. **Respuesta con un campo obligatorio ausente** (p. ej. `puesto` sin valor en una vacante): la pantalla debe mostrar «No pudimos leer esta información» con Reintentar, nunca cerrar la app. → Task 7, prueba `parsear devuelve respuestaInvalida si falta un campo obligatorio`.
2. **401 persistente tras renovar** (sesión revocada desde la web): un solo reintento, después login con aviso; nunca un bucle. → Task 5, prueba `tras un 401 renovado que vuelve 401 no hay tercer intento y cierra sesión`.
3. **Cuenta de candidato entrando a la app**: aviso «Esta versión es para negocios» y cierre de sesión, sin dejar sesión colgada. → Task 6, prueba `con sesión de candidato → aviso y salir`; Task 12, prueba `una cuenta de candidato ve el aviso y se cierra su sesión`.
4. **URL firmada vencida al abrir video o documento**: se vuelve a pedir la ficha una vez; a la segunda falla, mensaje. → Task 17, prueba `al fallar la URL se invalida la ficha una sola vez`.
5. **Reducir movimiento / transparencia del sistema**: `Vidrio` pinta sólido y el isotipo aparece lleno y quieto. → Task 4 (`Vidrio` sólido con `disableAnimations`/`highContrast`) y Task 11 (arranque sin animación).

---

### Task 1: Herramientas, proyecto base, sabores, análisis estricto y CI

**Files:**
- Create: proyecto Flutter en la raíz del repo (`flutter create`), `pubspec.yaml`, `analysis_options.yaml`, `.gitignore` (añadir), `defines/prod.example.json`, `lib/nucleo/config.dart`, `tool/verificar.sh`, `tool/fuentes.sh`, `.github/workflows/verificar.yml`, `README.md`
- Modify: `ios/Runner.xcodeproj/project.pbxproj`, `ios/Podfile`, `ios/Runner/Info.plist`, `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`
- Test: `test/nucleo/config_test.dart`

**Interfaces:**
- Produces: `class Config { static const String apiBase; static const String supabaseUrl; static const String supabaseAnonKey; static const String sabor; static const String sentryDsn; static bool get esProduccion; }`

- [ ] **Step 1: Instalar lo que falta en la Mac** (una vez)

```bash
brew install cocoapods && pod --version
```
Expected: una versión de CocoaPods (1.16 o más). Después, herramientas de Android:
```bash
brew install --cask android-commandlinetools && yes | sdkmanager --licenses >/dev/null 2>&1; flutter doctor --android-licenses <<< "y" >/dev/null 2>&1; flutter doctor
```
Expected: `[✓] Android toolchain` y `[✓] Xcode`. Si `sdkmanager` no está en el PATH, usar el de `~/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager` tras descargarlo con Android Studio.

- [ ] **Step 2: Crear el proyecto en la raíz del repo**

```bash
cd /Users/sebastianmoctezumatoral/dev/reclutaya-app && flutter create --org com.reclutaya --project-name reclutaya_app --platforms ios,android --empty . && flutter --version | head -1
```
Expected: `All done!` y Flutter 3.47.2.

- [ ] **Step 3: Identificador, nombre visible y mínimos de plataforma**

```bash
cd /Users/sebastianmoctezumatoral/dev/reclutaya-app && sed -i '' 's/com\.reclutaya\.reclutayaApp/com.reclutaya.app/g' ios/Runner.xcodeproj/project.pbxproj && sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 1[0-9]\.[0-9];/IPHONEOS_DEPLOYMENT_TARGET = 15.0;/g' ios/Runner.xcodeproj/project.pbxproj && sed -i '' "s/^# platform :ios, '1[0-9].0'/platform :ios, '15.0'/" ios/Podfile && sed -i '' 's/applicationId = "com\.reclutaya\.reclutaya_app"/applicationId = "com.reclutaya.app"/; s/minSdk = flutter\.minSdkVersion/minSdk = 24/' android/app/build.gradle.kts && sed -i '' 's/android:label="reclutaya_app"/android:label="ReclutaYa"/' android/app/src/main/AndroidManifest.xml && grep -c "com.reclutaya.app" ios/Runner.xcodeproj/project.pbxproj android/app/build.gradle.kts
```
Expected: cuentas mayores a 0 en los dos archivos. Después, en `ios/Runner/Info.plist`, poner `CFBundleDisplayName` = `ReclutaYa` y `CFBundleName` = `ReclutaYa`.

- [ ] **Step 4: Dependencias**

```bash
cd /Users/sebastianmoctezumatoral/dev/reclutaya-app && flutter pub add flutter_riverpod go_router dio json_annotation supabase_flutter flutter_secure_storage liquid_design video_player chewie url_launcher cached_network_image intl sentry_flutter && flutter pub add --dev very_good_analysis build_runner json_serializable http_mock_adapter flutter_launcher_icons && flutter pub get | tail -2
```
Expected: `Got dependencies!`. Si `liquid_design` pide un SDK de Flutter más nuevo, se anota y se evalúa `liquid_glass_native`; no se baja la versión de Flutter.

- [ ] **Step 5: Análisis estricto**

`analysis_options.yaml`:
```yaml
include: package:very_good_analysis/analysis_options.yaml
analyzer:
  exclude:
    - "**/*.g.dart"
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
linter:
  rules:
    public_member_api_docs: false
    lines_longer_than_80_chars: false
```

- [ ] **Step 6: Sabores por `--dart-define-from-file`**

`defines/prod.example.json`:
```json
{
  "SABOR": "prod",
  "API_BASE": "https://app.reclutaya.com/api/movil/v1",
  "SUPABASE_URL": "https://TU-PROYECTO.supabase.co",
  "SUPABASE_ANON_KEY": "la llave anon (pública) del proyecto",
  "SENTRY_DSN": ""
}
```
Añadir a `.gitignore`:
```
defines/*.json
!defines/prod.example.json
```
Crear en local `defines/prod.json` y `defines/local.json` (`API_BASE` `http://localhost:3000/api/movil/v1`, `SABOR` `local`) copiando `NEXT_PUBLIC_SUPABASE_URL` y `NEXT_PUBLIC_SUPABASE_ANON_KEY` del `.env` de `reclutaya-web`. No se versionan.

`lib/nucleo/config.dart`:
```dart
/// Lo que llega por `--dart-define-from-file=defines/<sabor>.json`.
/// Nada de esto es secreto de servidor: la llave anon de Supabase es pública por
/// diseño, pero igual no se escribe en el código.
abstract final class Config {
  static const String sabor = String.fromEnvironment('SABOR', defaultValue: 'prod');
  static const String apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://app.reclutaya.com/api/movil/v1',
  );
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');

  static bool get esProduccion => sabor == 'prod';
  static bool get configurado => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
```

- [ ] **Step 7: Prueba de la configuración (falla primero)**

`test/nucleo/config_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/nucleo/config.dart';

void main() {
  test('sin defines, apunta a producción y se sabe no configurada', () {
    expect(Config.apiBase, 'https://app.reclutaya.com/api/movil/v1');
    expect(Config.esProduccion, isTrue);
    expect(Config.configurado, isFalse);
  });
}
```
Run: `flutter test test/nucleo/config_test.dart`
Expected: FAIL (`config.dart` no existe) antes del Step 6; PASS después.

- [ ] **Step 8: Fuentes empaquetadas**

`tool/fuentes.sh` (misma táctica que `scripts/generar-fuentes-reporte.mjs` de la web: un agente de usuario viejo hace que Google Fonts entregue TTF en vez de woff2):
```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p assets/fonts
UA="Mozilla/5.0 (Windows NT 6.1; rv:40.0) Gecko/20100101 Firefox/40.0"
bajar() {
  local familia="$1" peso="$2" nombre="$3"
  local css; css=$(curl -fsSL -A "$UA" "https://fonts.googleapis.com/css2?family=${familia}:wght@${peso}")
  local url; url=$(echo "$css" | grep -o 'https://[^)]*\.ttf' | head -1)
  curl -fsSL "$url" -o "assets/fonts/${nombre}.ttf"
  echo "$nombre: $(wc -c < "assets/fonts/${nombre}.ttf") bytes"
}
bajar Poppins 500 Poppins-Medium
bajar Poppins 600 Poppins-SemiBold
bajar Poppins 700 Poppins-Bold
bajar Poppins 800 Poppins-ExtraBold
bajar Hanken+Grotesk 400 HankenGrotesk-Regular
bajar Hanken+Grotesk 500 HankenGrotesk-Medium
bajar Hanken+Grotesk 600 HankenGrotesk-SemiBold
bajar Hanken+Grotesk 700 HankenGrotesk-Bold
```
Run: `chmod +x tool/fuentes.sh && tool/fuentes.sh && file assets/fonts/Poppins-Bold.ttf`
Expected: ocho archivos de más de 100 KB cada uno y `TrueType Font data`. Las fuentes se versionan (licencia OFL). Copiar el isotipo: `cp ../reclutaya-web/public/isotipo.png assets/imagenes/isotipo.png`.

En `pubspec.yaml`:
```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/imagenes/
  fonts:
    - family: Poppins
      fonts:
        - asset: assets/fonts/Poppins-Medium.ttf
          weight: 500
        - asset: assets/fonts/Poppins-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Poppins-Bold.ttf
          weight: 700
        - asset: assets/fonts/Poppins-ExtraBold.ttf
          weight: 800
    - family: HankenGrotesk
      fonts:
        - asset: assets/fonts/HankenGrotesk-Regular.ttf
          weight: 400
        - asset: assets/fonts/HankenGrotesk-Medium.ttf
          weight: 500
        - asset: assets/fonts/HankenGrotesk-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/HankenGrotesk-Bold.ttf
          weight: 700
```

- [ ] **Step 9: El verificador y la CI**

`tool/verificar.sh`:
```bash
#!/usr/bin/env bash
# Los cuatro checks de la casa. Nada se sube en rojo.
set -euo pipefail
cd "$(dirname "$0")/.."
dart format --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test
flutter build apk --debug --dart-define-from-file=defines/prod.example.json >/dev/null
echo "verificar: todo en verde"
```

`.github/workflows/verificar.yml`:
```yaml
name: verificar
on: [push, pull_request]
jobs:
  analizar-y-probar:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: "3.47.2", channel: stable, cache: true }
      - run: flutter pub get
      - run: dart format --set-exit-if-changed lib test
      - run: flutter analyze --fatal-infos
      - run: flutter test
      - run: flutter build apk --debug --dart-define-from-file=defines/prod.example.json
  ios-sin-firma:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: maxim-lobanov/setup-xcode@v1
        with: { xcode-version: latest-stable }
      - uses: subosito/flutter-action@v2
        with: { flutter-version: "3.47.2", channel: stable, cache: true }
      - run: flutter pub get
      - run: flutter build ios --no-codesign --dart-define-from-file=defines/prod.example.json
```
Si el runner de macOS no trae el SDK de iOS 26 que exige `liquid_design`, se anota en el README y el trabajo `ios-sin-firma` queda como `continue-on-error: true` hasta que exista.

- [ ] **Step 10: README mínimo y verificación**

`README.md`: qué es (una línea), cómo correr (`flutter run --dart-define-from-file=defines/prod.json -d <iphone|android>`), cómo verificar (`tool/verificar.sh`), dónde viven la spec y el plan, y las dos reglas guardián.

Run: `cd /Users/sebastianmoctezumatoral/dev/reclutaya-app && chmod +x tool/verificar.sh && tool/verificar.sh`
Expected: `verificar: todo en verde`.

- [ ] **Step 11: Commit (lo hace el dueño)**
`git add -A && git commit -m "Proyecto base de la app: Flutter 3.47, identificador com.reclutaya.app, sabores por define, análisis estricto, fuentes empaquetadas y CI"`

---

### Task 2: Tokens, tema claro y oscuro, tipografía

**Files:**
- Create: `lib/nucleo/tema/tokens.dart`, `lib/nucleo/tema/tipografia.dart`, `lib/nucleo/tema/tema.dart`
- Test: `test/nucleo/tema/tokens_test.dart`, `test/guardianes/sin_colores_sueltos_test.dart`

**Interfaces:**
- Produces: `class Tokens { final Color papel, tarjeta, tinta, tintaSuave, tintaTenue, verde, verdeProfundo, verdeBrillo, verdeSuave, naranja, naranjaProfundo, naranjaBrillo, azul, azulBrillo, linea, lineaFuerte; static const Tokens claro; static const Tokens oscuro; static Tokens de(BuildContext); }`, `const double radio = 14, radioGrande = 22;`, `List<BoxShadow> sombraSm/Md/Lg(Tokens)`, `TextTheme tipografia(Tokens)`, `ThemeData temaClaro()`, `ThemeData temaOscuro()`, `extension TokensX on BuildContext { Tokens get t; }`.

- [ ] **Step 1: Prueba de tokens (falla primero)**

`test/nucleo/tema/tokens_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/nucleo/tema/tema.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';

void main() {
  test('los tokens claros son los de la web', () {
    expect(Tokens.claro.papel, const Color(0xFFF7F7F4));
    expect(Tokens.claro.verde, const Color(0xFF146A43));
    expect(Tokens.claro.naranja, const Color(0xFFFF8A00));
    expect(Tokens.claro.tinta, const Color(0xFF1F2937));
  });
  test('el tema se deriva de los tokens', () {
    expect(temaClaro().scaffoldBackgroundColor, Tokens.claro.papel);
    expect(temaOscuro().scaffoldBackgroundColor, Tokens.oscuro.papel);
    expect(temaClaro().textTheme.headlineMedium!.fontFamily, 'Poppins');
    expect(temaClaro().textTheme.bodyMedium!.fontFamily, 'HankenGrotesk');
  });
}
```

- [ ] **Step 2: Correr y ver fallar**
Run: `flutter test test/nucleo/tema/tokens_test.dart` → FAIL (archivos inexistentes).

- [ ] **Step 3: Tokens**

`lib/nucleo/tema/tokens.dart`:
```dart
import 'package:flutter/widgets.dart';

/// Los tokens de la web (`app/globals.css`), portados. ÚNICO lugar con colores.
/// El oscuro sigue la regla del panel: sin verdes neón, tinta clara sobre carbón.
@immutable
class Tokens extends ThemeExtension<Tokens> {
  const Tokens({
    required this.papel,
    required this.tarjeta,
    required this.tinta,
    required this.tintaSuave,
    required this.tintaTenue,
    required this.verde,
    required this.verdeProfundo,
    required this.verdeBrillo,
    required this.verdeSuave,
    required this.naranja,
    required this.naranjaProfundo,
    required this.naranjaBrillo,
    required this.azul,
    required this.azulBrillo,
    required this.linea,
    required this.lineaFuerte,
    required this.esOscuro,
  });

  final Color papel, tarjeta, tinta, tintaSuave, tintaTenue;
  final Color verde, verdeProfundo, verdeBrillo, verdeSuave;
  final Color naranja, naranjaProfundo, naranjaBrillo;
  final Color azul, azulBrillo;
  final Color linea, lineaFuerte;
  final bool esOscuro;

  static const claro = Tokens(
    papel: Color(0xFFF7F7F4),
    tarjeta: Color(0xFFFFFFFF),
    tinta: Color(0xFF1F2937),
    tintaSuave: Color(0xFF52606E),
    tintaTenue: Color(0xFF8A96A3),
    verde: Color(0xFF146A43),
    verdeProfundo: Color(0xFF0E5234),
    verdeBrillo: Color(0xFFE8F6EF),
    verdeSuave: Color(0xFFCFE6D8),
    naranja: Color(0xFFFF8A00),
    naranjaProfundo: Color(0xFFCC6E00),
    naranjaBrillo: Color(0xFFFFF0DB),
    azul: Color(0xFF197CBB),
    azulBrillo: Color(0xFFE8F0FF),
    linea: Color(0xFFE6E8E4),
    lineaFuerte: Color(0xFFCCD3CD),
    esOscuro: false,
  );

  static const oscuro = Tokens(
    papel: Color(0xFF15181D),
    tarjeta: Color(0xFF1B1E24),
    tinta: Color(0xFFE8EAED),
    tintaSuave: Color(0xFF9AA4B0),
    tintaTenue: Color(0xFF8A93A0),
    verde: Color(0xFF4FAE74),
    verdeProfundo: Color(0xFF7BC99A),
    verdeBrillo: Color(0xFF1B2A22),
    verdeSuave: Color(0xFF22302A),
    naranja: Color(0xFFEDA04F),
    naranjaProfundo: Color(0xFFF2B977),
    naranjaBrillo: Color(0xFF2E251A),
    azul: Color(0xFF7FA8EC),
    azulBrillo: Color(0xFF1C2433),
    linea: Color(0xFF2C3037),
    lineaFuerte: Color(0xFF3A414B),
    esOscuro: true,
  );

  static Tokens de(BuildContext context) =>
      Theme.of(context).extension<Tokens>() ?? claro;

  @override
  Tokens copyWith() => this;

  @override
  Tokens lerp(Tokens? other, double t) => t < 0.5 ? this : (other ?? this);
}

const double radio = 14;
const double radioGrande = 22;

List<BoxShadow> sombraSm(Tokens t) => [
      BoxShadow(color: const Color(0x0F14281E), blurRadius: 3, offset: const Offset(0, 1)),
      BoxShadow(color: const Color(0x0D14281E), blurRadius: 12, offset: const Offset(0, 4)),
    ];
List<BoxShadow> sombraMd(Tokens t) => [
      BoxShadow(color: const Color(0x1714281E), blurRadius: 14, offset: const Offset(0, 4)),
      BoxShadow(color: const Color(0x1414281E), blurRadius: 40, offset: const Offset(0, 14)),
    ];

extension TokensX on BuildContext {
  Tokens get t => Tokens.de(this);
}
```
Nota: `Theme.of` viene de `material.dart`; importar `package:flutter/material.dart` en vez de `widgets.dart` si el analizador lo pide.

- [ ] **Step 4: Tipografía y tema**

`lib/nucleo/tema/tipografia.dart`:
```dart
import 'package:flutter/material.dart';
import 'tokens.dart';

/// Poppins para títulos y cifras (500–800); Hanken Grotesk para texto (400–700).
TextTheme tipografia(Tokens t) {
  TextStyle p(double size, FontWeight w, {double? h, double ls = -0.02}) => TextStyle(
        fontFamily: 'Poppins', fontSize: size, fontWeight: w, height: h ?? 1.15,
        letterSpacing: size * ls, color: t.tinta);
  TextStyle hk(double size, FontWeight w, {Color? c, double h = 1.45}) => TextStyle(
        fontFamily: 'HankenGrotesk', fontSize: size, fontWeight: w, height: h, color: c ?? t.tinta);
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
```

`lib/nucleo/tema/tema.dart`:
```dart
import 'package:flutter/material.dart';
import 'tipografia.dart';
import 'tokens.dart';

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
    error: const Color(0xFFC0432E),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radioGrande)),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: t.tinta,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
    }),
  );
}
```

- [ ] **Step 5: Prueba guardián de colores sueltos**

`test/guardianes/sin_colores_sueltos_test.dart`:
```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Ningún widget escribe un color a mano: todo sale de `lib/nucleo/tema/tokens.dart`.
void main() {
  test('solo lib/nucleo/tema escribe Color(0x…)', () {
    final culpables = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'))
        .where((f) => !f.path.startsWith('lib/nucleo/tema/'))
        .where((f) => RegExp(r'Color\(0x[0-9A-Fa-f]{8}\)').hasMatch(f.readAsStringSync()))
        .map((f) => f.path)
        .toList();
    expect(culpables, isEmpty, reason: 'Usa los tokens: ${culpables.join(', ')}');
  });
}
```

- [ ] **Step 6: Verificar**
Run: `flutter test test/nucleo/tema test/guardianes` → PASS.

- [ ] **Step 7: Commit (dueño)** — `"Tema de la app: tokens de la web en claro y oscuro, Poppins y Hanken Grotesk, guardián de colores sueltos"`

---

### Task 3: Plataforma y adaptativos (Swift por dentro)

**Files:**
- Create: `lib/nucleo/plataforma/plataforma.dart`, `lib/nucleo/plataforma/adaptativos.dart`
- Test: `test/nucleo/plataforma/plataforma_test.dart`, `test/guardianes/sin_platform_suelto_test.dart`

**Interfaces:**
- Produces: `abstract final class Plataforma { static bool get esIOS; static bool get esAndroid; @visibleForTesting static TargetPlatform? forzada; }`, widgets `PaginaConTitulo({required String titulo, required List<Widget> slivers, Widget? accion, bool tituloGrande = true})`, `Refrescable({required Future<void> Function() alRefrescar, required List<Widget> slivers})`, `Future<bool> confirmar(BuildContext, {required String titulo, required String mensaje, required String aceptar, bool destructivo = false})`, `void hapticoSeleccion()`, `BorderRadius radioContinuo(double)`.

- [ ] **Step 1: Pruebas (fallan primero)**

`test/nucleo/plataforma/plataforma_test.dart`:
```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/nucleo/plataforma/plataforma.dart';

void main() {
  tearDown(() => Plataforma.forzada = null);
  test('se puede forzar la plataforma en pruebas', () {
    Plataforma.forzada = TargetPlatform.iOS;
    expect(Plataforma.esIOS, isTrue);
    expect(Plataforma.esAndroid, isFalse);
    Plataforma.forzada = TargetPlatform.android;
    expect(Plataforma.esAndroid, isTrue);
  });
}
```

`test/guardianes/sin_platform_suelto_test.dart`:
```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('solo lib/nucleo/plataforma pregunta por la plataforma', () {
    final patron = RegExp(r'Platform\.is(IOS|Android)|defaultTargetPlatform|Theme\.of\([^)]*\)\.platform');
    final culpables = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.startsWith('lib/nucleo/plataforma/'))
        .where((f) => patron.hasMatch(f.readAsStringSync()))
        .map((f) => f.path)
        .toList();
    expect(culpables, isEmpty, reason: 'Usa Plataforma/adaptativos: ${culpables.join(', ')}');
  });
}
```

- [ ] **Step 2: Correr y ver fallar** — `flutter test test/nucleo/plataforma test/guardianes/sin_platform_suelto_test.dart` → FAIL.

- [ ] **Step 3: Implementar**

`lib/nucleo/plataforma/plataforma.dart`:
```dart
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
```

`lib/nucleo/plataforma/adaptativos.dart`:
```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tema/tokens.dart';
import 'plataforma.dart';

/// Esquinas continuas en iOS (como las de Apple), circulares en Android.
ShapeBorder formaTarjeta(double r) => Plataforma.esIOS
    ? ContinuousRectangleBorder(borderRadius: BorderRadius.circular(r * 2.2))
    : RoundedRectangleBorder(borderRadius: BorderRadius.circular(r));

void hapticoSeleccion() => HapticFeedback.selectionClick();
void hapticoLigero() => HapticFeedback.lightImpact();

/// Página con título: grande y que se encoge al bajar (iOS), `SliverAppBar.large` (Android).
class PaginaConTitulo extends StatelessWidget {
  const PaginaConTitulo({
    required this.titulo, required this.slivers, this.accion, this.alRefrescar, super.key,
  });
  final String titulo;
  final List<Widget> slivers;
  final Widget? accion;
  final Future<void> Function()? alRefrescar;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final refresco = alRefrescar == null
        ? const <Widget>[]
        : [
            if (Plataforma.esIOS)
              CupertinoSliverRefreshControl(onRefresh: alRefrescar)
          ];
    final cuerpo = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (Plataforma.esIOS)
          CupertinoSliverNavigationBar(
            largeTitle: Text(titulo, style: Theme.of(context).textTheme.headlineMedium),
            backgroundColor: t.papel.withValues(alpha: 0.85),
            border: null,
            trailing: accion,
            stretch: true,
          )
        else
          SliverAppBar.large(
            title: Text(titulo),
            actions: [if (accion != null) accion!],
            backgroundColor: t.papel,
          ),
        ...refresco,
        ...slivers,
        const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
      ],
    );
    if (!Plataforma.esIOS && alRefrescar != null) {
      return RefreshIndicator.adaptive(onRefresh: alRefrescar!, child: cuerpo);
    }
    return cuerpo;
  }
}

/// Confirmación nativa. Devuelve true si aceptó.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  required String aceptar,
  bool destructivo = false,
}) async {
  if (Plataforma.esIOS) {
    final r = await showCupertinoDialog<bool>(
      context: context,
      builder: (c) => CupertinoAlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          CupertinoDialogAction(
            isDestructiveAction: destructivo,
            onPressed: () => Navigator.pop(c, true),
            child: Text(aceptar),
          ),
        ],
      ),
    );
    return r ?? false;
  }
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(aceptar)),
      ],
    ),
  );
  return r ?? false;
}
```

- [ ] **Step 4: Verificar** — `flutter test test/nucleo/plataforma test/guardianes` → PASS; `flutter analyze` limpio.
- [ ] **Step 5: Commit (dueño)** — `"Plataforma y adaptativos: título grande Cupertino, refresco, confirmación nativa, guardián de Platform suelto"`

---

### Task 4: `Vidrio` (liquid_design detrás) y barra de pestañas

**Files:**
- Create: `lib/nucleo/vidrio/vidrio.dart`, `lib/nucleo/vidrio/vidrio_propio.dart`, `lib/nucleo/vidrio/vidrio_nativo.dart`, `lib/nucleo/vidrio/barra_pestanas.dart`, `lib/nucleo/vidrio/segmentado.dart`
- Test: `test/guardianes/sin_liquid_design_suelto_test.dart`, `test/nucleo/vidrio/vidrio_test.dart`

**Interfaces:**
- Produces: `enum VidrioVariante { barra, pastilla, hoja }`, `class Vidrio extends StatelessWidget { const Vidrio.barra({required Widget child}); const Vidrio.pastilla({required Widget child}); const Vidrio.hoja({required Widget child}); }`, `bool vidrioSolido(BuildContext)`, `class BarraPestanas({required int indice, required ValueChanged<int> alCambiar, required List<PestanaItem> items})`, `class PestanaItem { const PestanaItem({required IconData icono, required IconData iconoActivo, required String etiqueta}); }`, `class Segmentado<T>({required Map<T,String> opciones, required T valor, required ValueChanged<T> alCambiar})`, `Future<void> prepararVidrio()` (llama `LiquidGlassService.instance.ensureInitialized()`), `bool get vidrioNativoDisponible`.

- [ ] **Step 1: Guardián y prueba de sólido (fallan primero)**

`test/guardianes/sin_liquid_design_suelto_test.dart`:
```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('solo lib/nucleo/vidrio importa liquid_design', () {
    final culpables = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.startsWith('lib/nucleo/vidrio/'))
        .where((f) => f.readAsStringSync().contains('package:liquid_design/'))
        .map((f) => f.path)
        .toList();
    expect(culpables, isEmpty, reason: 'Usa Vidrio: ${culpables.join(', ')}');
  });
}
```

`test/nucleo/vidrio/vidrio_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/nucleo/tema/tema.dart';
import 'package:reclutaya_app/nucleo/vidrio/vidrio.dart';

void main() {
  testWidgets('con reducir movimiento o alto contraste, el vidrio es sólido', (tester) async {
    late bool solido;
    await tester.pumpWidget(MaterialApp(
      theme: temaClaro(),
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(builder: (c) { solido = vidrioSolido(c); return const SizedBox(); }),
      ),
    ));
    expect(solido, isTrue);
  });
  testWidgets('sin ajustes de accesibilidad, no es sólido', (tester) async {
    late bool solido;
    await tester.pumpWidget(MaterialApp(
      theme: temaClaro(),
      home: Builder(builder: (c) { solido = vidrioSolido(c); return const SizedBox(); }),
    ));
    expect(solido, isFalse);
  });
}
```

- [ ] **Step 2: Correr y ver fallar.**

- [ ] **Step 3: Implementar**

`lib/nucleo/vidrio/vidrio.dart`:
```dart
import 'package:flutter/material.dart';
import '../plataforma/plataforma.dart';
import 'vidrio_nativo.dart';
import 'vidrio_propio.dart';

enum VidrioVariante { barra, pastilla, hoja }

/// Sistema «Reducir movimiento» o «Aumentar contraste»: superficies sólidas.
/// (Flutter no expone «Reducir transparencia» por separado; se cubre con estas dos.)
bool vidrioSolido(BuildContext context) {
  final mq = MediaQuery.maybeOf(context);
  return mq != null && (mq.disableAnimations || mq.highContrast);
}

/// El vidrio de la casa. La app NUNCA llama a liquid_design directo: aquí se decide
/// nativo (iOS 26+), propio (Android, iOS viejo) o sólido (accesibilidad).
/// Regla: solo en lo que flota. Nunca en filas de lista ni tarjetas de contenido.
class Vidrio extends StatelessWidget {
  const Vidrio.barra({required this.child, super.key}) : variante = VidrioVariante.barra;
  const Vidrio.pastilla({required this.child, super.key}) : variante = VidrioVariante.pastilla;
  const Vidrio.hoja({required this.child, super.key}) : variante = VidrioVariante.hoja;

  final Widget child;
  final VidrioVariante variante;

  @override
  Widget build(BuildContext context) {
    if (vidrioSolido(context)) return VidrioPropio(variante: variante, solido: true, child: child);
    if (Plataforma.esIOS && vidrioNativoDisponible) {
      return VidrioNativo(variante: variante, child: child);
    }
    return VidrioPropio(variante: variante, child: child);
  }
}
```

`lib/nucleo/vidrio/vidrio_propio.dart` (la receta del dock cápsula de la web):
```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../tema/tokens.dart';
import 'vidrio.dart';

class VidrioPropio extends StatelessWidget {
  const VidrioPropio({required this.variante, required this.child, this.solido = false, super.key});
  final VidrioVariante variante;
  final Widget child;
  final bool solido;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final radio = switch (variante) {
      VidrioVariante.barra => 999.0,
      VidrioVariante.pastilla => 999.0,
      VidrioVariante.hoja => radioGrande,
    };
    final decor = BoxDecoration(
      borderRadius: BorderRadius.circular(radio),
      color: solido ? t.tarjeta : t.tarjeta.withValues(alpha: t.esOscuro ? 0.62 : 0.68),
      border: Border.all(color: Colors.white.withValues(alpha: t.esOscuro ? 0.08 : 0.42)),
      boxShadow: sombraMd(t),
    );
    final cuerpo = DecoratedBox(decoration: decor, child: child);
    if (solido) return ClipRRect(borderRadius: BorderRadius.circular(radio), child: cuerpo);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radio),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22), child: cuerpo),
    );
  }
}
```

`lib/nucleo/vidrio/vidrio_nativo.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:liquid_design/liquid_design.dart';
import '../tema/tokens.dart';
import 'vidrio.dart';

bool get vidrioNativoDisponible => LiquidGlassService.instance.isLiquidGlassSupported;

/// Inicializa el servicio antes del primer cuadro (así `vidrioNativoDisponible`
/// ya es confiable en el arranque).
Future<void> prepararVidrio() async {
  await LiquidGlassService.instance.ensureInitialized();
  LiquidGlassService.instance
    ..setRenderer(LiquidGlassRenderer.native)
    ..setFallback(LiquidGlassFallback.none)
    ..setBrightness(LiquidGlassBrightness.auto);
}

class VidrioNativo extends StatelessWidget {
  const VidrioNativo({required this.variante, required this.child, super.key});
  final VidrioVariante variante;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final forma = switch (variante) {
      VidrioVariante.barra || VidrioVariante.pastilla => LiquidGlassShape.capsule(),
      VidrioVariante.hoja => LiquidGlassShape.roundedRect(radioGrande),
    };
    return LiquidGlass(
      shape: forma,
      style: LiquidGlassStyle.regular,
      tintColor: t.papel,
      tintOpacity: 0.12,
      interactive: variante == VidrioVariante.pastilla,
      renderer: LiquidGlassRenderer.native,
      child: child,
    );
  }
}
```

`lib/nucleo/vidrio/barra_pestanas.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:liquid_design/liquid_design.dart';
import '../plataforma/adaptativos.dart';
import '../plataforma/plataforma.dart';
import '../tema/tokens.dart';
import 'vidrio.dart';
import 'vidrio_nativo.dart';

class PestanaItem {
  const PestanaItem({required this.icono, required this.iconoActivo, required this.etiqueta});
  final IconData icono;
  final IconData iconoActivo;
  final String etiqueta;
}

/// Pestañas: vidrio nativo de Apple en iOS 26 (LiquidGlassNavigationBar), vidrio
/// propio flotante en iOS viejo, NavigationBar de Material 3 en Android.
class BarraPestanas extends StatelessWidget {
  const BarraPestanas({required this.indice, required this.alCambiar, required this.items, super.key});
  final int indice;
  final ValueChanged<int> alCambiar;
  final List<PestanaItem> items;

  void _tocar(int i) { hapticoSeleccion(); alCambiar(i); }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    if (Plataforma.esIOS && vidrioNativoDisponible && !vidrioSolido(context)) {
      return LiquidGlassNavigationBar(
        currentIndex: indice,
        onTap: _tocar,
        activeColor: t.verde,
        inactiveColor: t.tintaSuave,
        items: [
          for (final p in items)
            LiquidGlassNavItem(icon: Icon(p.icono), activeIcon: Icon(p.iconoActivo), label: p.etiqueta),
        ],
      );
    }
    if (Plataforma.esIOS) {
      return SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 0, 24, 10),
        child: Vidrio.barra(
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => _tocar(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(i == indice ? items[i].iconoActivo : items[i].icono,
                            color: i == indice ? t.verde : t.tintaSuave, size: 24),
                        const SizedBox(height: 2),
                        Text(items[i].etiqueta,
                            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                color: i == indice ? t.verde : t.tintaSuave)),
                      ]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return NavigationBar(
      selectedIndex: indice,
      onDestinationSelected: _tocar,
      backgroundColor: t.tarjeta,
      indicatorColor: t.verdeBrillo,
      destinations: [
        for (final p in items)
          NavigationDestination(icon: Icon(p.icono), selectedIcon: Icon(p.iconoActivo), label: p.etiqueta),
      ],
    );
  }
}
```

`lib/nucleo/vidrio/segmentado.dart`:
```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../plataforma/adaptativos.dart';
import '../plataforma/plataforma.dart';
import '../tema/tokens.dart';
import 'vidrio.dart';

/// Activas | Cerradas. En iOS, el segmentado deslizante de Cupertino dentro de una
/// pastilla de vidrio; en Android, SegmentedButton de Material 3.
class Segmentado<T extends Object> extends StatelessWidget {
  const Segmentado({required this.opciones, required this.valor, required this.alCambiar, super.key});
  final Map<T, String> opciones;
  final T valor;
  final ValueChanged<T> alCambiar;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    if (Plataforma.esIOS) {
      return Vidrio.pastilla(
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: CupertinoSlidingSegmentedControl<T>(
            groupValue: valor,
            thumbColor: t.verde,
            backgroundColor: Colors.transparent,
            onValueChanged: (v) { if (v != null) { hapticoSeleccion(); alCambiar(v); } },
            children: {
              for (final e in opciones.entries)
                e.key: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Text(e.value, style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: e.key == valor ? Colors.white : t.tinta)),
                ),
            },
          ),
        ),
      );
    }
    return SegmentedButton<T>(
      segments: [for (final e in opciones.entries) ButtonSegment(value: e.key, label: Text(e.value))],
      selected: {valor},
      showSelectedIcon: false,
      onSelectionChanged: (s) { hapticoSeleccion(); alCambiar(s.first); },
    );
  }
}
```

- [ ] **Step 4: Verificar** — `flutter test test/nucleo/vidrio test/guardianes` → PASS; `flutter analyze` limpio. Si el analizador no encuentra algún nombre de `liquid_design`, abrir `~/.pub-cache/hosted/pub.dev/liquid_design-*/lib/` y ajustar al nombre real **solo dentro de `lib/nucleo/vidrio/`**; anotar el cambio en el README.

- [ ] **Step 5: Commit (dueño)** — `"Vidrio: liquid_design aislado detrás de un componente propio con respaldo de desenfoque y modo sólido; barra de pestañas y segmentado adaptativos; guardián"`

---

### Task 5: Red — `Resultado`, `ErrorApi`, política de reintento y `ClienteApi`

**Files:**
- Create: `lib/nucleo/util/resultado.dart`, `lib/nucleo/red/errores_api.dart`, `lib/nucleo/red/politica_reintento.dart`, `lib/nucleo/red/cliente_api.dart`
- Test: `test/nucleo/red/errores_api_test.dart`, `test/nucleo/red/politica_reintento_test.dart`, `test/nucleo/red/cliente_api_test.dart`

**Interfaces:**
- Produces:
  - `sealed class Resultado<T>`; `final class Exito<T> extends Resultado<T> { final T valor; }`; `final class Falla<T> extends Resultado<T> { final ErrorApi error; }`; `extension ResultadoX<T> on Resultado<T> { T get valorOLanza; }`
  - `sealed class ErrorApi implements Exception { String get mensaje; }` con `SesionVencida()`, `Prohibido()`, `NoEncontrado()`, `Limite(int segundos)`, `Servidor()`, `SinRed()`, `RespuestaInvalida(String detalle)`.
  - `ErrorApi errorDeRespuesta(int status, Object? cuerpo, {String? retryAfter})`
  - `int segundosEspera(String? retryAfter)` (tope 30, mínimo 1)
  - `enum AccionReintento { renovarYReintentar, esperarYReintentar, noReintentar }`; `AccionReintento decidirReintento(ErrorApi e, {required int intento})`
  - `abstract class ProveedorToken { String? get token; Future<String?> renovar(); Future<void> sesionVencida(); }`
  - `class ClienteApi { ClienteApi({required String base, required ProveedorToken tokens, Dio? dio}); Future<Resultado<Map<String, dynamic>>> get(String ruta, {Map<String, String>? query}); }`

- [ ] **Step 1: Pruebas puras (fallan primero)**

`test/nucleo/red/errores_api_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';

void main() {
  test('cada HTTP del contrato cae en su error', () {
    expect(errorDeRespuesta(401, {'error': {'codigo': 'no_autenticado', 'mensaje': 'x'}}), isA<SesionVencida>());
    expect(errorDeRespuesta(403, null), isA<Prohibido>());
    expect(errorDeRespuesta(404, null), isA<NoEncontrado>());
    expect(errorDeRespuesta(429, null, retryAfter: '7'), const Limite(7));
    expect(errorDeRespuesta(500, null), isA<Servidor>());
    expect(errorDeRespuesta(503, null), isA<Servidor>());
  });
  test('el mensaje del servidor se usa tal cual si viene; si no, uno nuestro', () {
    expect(errorDeRespuesta(500, {'error': {'codigo': 'interno', 'mensaje': 'Falló X'}}).mensaje, 'Falló X');
    expect(errorDeRespuesta(500, null).mensaje, 'No se pudo cargar. Intenta de nuevo.');
  });
  test('Retry-After se acota entre 1 y 30 segundos', () {
    expect(segundosEspera(null), 1);
    expect(segundosEspera('0'), 1);
    expect(segundosEspera('12'), 12);
    expect(segundosEspera('900'), 30);
    expect(segundosEspera('basura'), 1);
  });
}
```

`test/nucleo/red/politica_reintento_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/red/politica_reintento.dart';

void main() {
  test('401 en el primer intento renueva y reintenta; en el segundo, no', () {
    expect(decidirReintento(const SesionVencida(), intento: 0), AccionReintento.renovarYReintentar);
    expect(decidirReintento(const SesionVencida(), intento: 1), AccionReintento.noReintentar);
  });
  test('429 espera y reintenta una sola vez', () {
    expect(decidirReintento(const Limite(5), intento: 0), AccionReintento.esperarYReintentar);
    expect(decidirReintento(const Limite(5), intento: 1), AccionReintento.noReintentar);
  });
  test('500, sin red, 403 y 404 nunca reintentan solos', () {
    for (final e in [const Servidor(), const SinRed(), const Prohibido(), const NoEncontrado()]) {
      expect(decidirReintento(e, intento: 0), AccionReintento.noReintentar, reason: '$e');
    }
  });
}
```

- [ ] **Step 2: Correr y ver fallar.**

- [ ] **Step 3: Implementar lo puro**

`lib/nucleo/util/resultado.dart`:
```dart
import '../red/errores_api.dart';

sealed class Resultado<T> {
  const Resultado();
}

final class Exito<T> extends Resultado<T> {
  const Exito(this.valor);
  final T valor;
}

final class Falla<T> extends Resultado<T> {
  const Falla(this.error);
  final ErrorApi error;
}

extension ResultadoX<T> on Resultado<T> {
  /// Para los providers de Riverpod: el valor, o lanza el `ErrorApi` (que
  /// `AsyncValue.error` conserva tal cual para que la UI lo traduzca).
  T get valorOLanza => switch (this) {
        Exito(:final valor) => valor,
        Falla(:final error) => throw error,
      };
}
```

`lib/nucleo/red/errores_api.dart`:
```dart
/// Los errores del contrato (api-v1.md §Errores), como unión cerrada.
sealed class ErrorApi implements Exception {
  const ErrorApi();
  String get mensaje;
}

final class SesionVencida extends ErrorApi {
  const SesionVencida();
  @override
  String get mensaje => 'Tu sesión terminó. Vuelve a entrar.';
}

final class Prohibido extends ErrorApi {
  const Prohibido();
  @override
  String get mensaje => 'Esta cuenta no puede ver esto.';
}

final class NoEncontrado extends ErrorApi {
  const NoEncontrado();
  @override
  String get mensaje => 'Esto ya no está disponible.';
}

final class Limite extends ErrorApi {
  const Limite(this.segundos);
  final int segundos;
  @override
  String get mensaje => 'Demasiadas consultas. Espera un momento.';
  @override
  bool operator ==(Object o) => o is Limite && o.segundos == segundos;
  @override
  int get hashCode => segundos;
}

final class Servidor extends ErrorApi {
  const Servidor([this.detalle]);
  final String? detalle;
  @override
  String get mensaje => detalle ?? 'No se pudo cargar. Intenta de nuevo.';
}

final class SinRed extends ErrorApi {
  const SinRed();
  @override
  String get mensaje => 'Sin conexión. Revisa tu internet e intenta de nuevo.';
}

final class RespuestaInvalida extends ErrorApi {
  const RespuestaInvalida(this.detalle);
  final String detalle;
  @override
  String get mensaje => 'No pudimos leer esta información. Intenta de nuevo.';
}

int segundosEspera(String? retryAfter) {
  final n = int.tryParse(retryAfter ?? '') ?? 1;
  return n.clamp(1, 30);
}

String? _mensajeDe(Object? cuerpo) {
  if (cuerpo is Map && cuerpo['error'] is Map) {
    final m = (cuerpo['error'] as Map)['mensaje'];
    if (m is String && m.isNotEmpty) return m;
  }
  return null;
}

ErrorApi errorDeRespuesta(int status, Object? cuerpo, {String? retryAfter}) {
  return switch (status) {
    401 => const SesionVencida(),
    403 => const Prohibido(),
    404 => const NoEncontrado(),
    429 => Limite(segundosEspera(retryAfter)),
    _ => Servidor(_mensajeDe(cuerpo)),
  };
}
```

`lib/nucleo/red/politica_reintento.dart`:
```dart
import 'errores_api.dart';

enum AccionReintento { renovarYReintentar, esperarYReintentar, noReintentar }

/// UNA sola vez: 401 → renovar sesión y repetir; 429 → esperar y repetir.
/// Lo demás lo reintenta la persona con «Reintentar». 500 jamás manda al login.
AccionReintento decidirReintento(ErrorApi e, {required int intento}) {
  if (intento > 0) return AccionReintento.noReintentar;
  return switch (e) {
    SesionVencida() => AccionReintento.renovarYReintentar,
    Limite() => AccionReintento.esperarYReintentar,
    _ => AccionReintento.noReintentar,
  };
}
```

- [ ] **Step 4: Prueba del cliente con respuestas simuladas (falla primero)**

`test/nucleo/red/cliente_api_test.dart`:
```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:reclutaya_app/nucleo/red/cliente_api.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/util/resultado.dart';

class _Tokens implements ProveedorToken {
  _Tokens(this.token);
  @override
  String? token;
  int renovaciones = 0;
  bool cerrada = false;
  @override
  Future<String?> renovar() async { renovaciones++; token = 'nuevo'; return token; }
  @override
  Future<void> sesionVencida() async { cerrada = true; }
}

void main() {
  late Dio dio;
  late DioAdapter adaptador;
  const base = 'https://x.test/api/movil/v1';

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: base));
    adaptador = DioAdapter(dio: dio);
  });

  test('manda el Bearer y devuelve el JSON', () async {
    adaptador.onGet('/yo', (s) => s.reply(200, {'tipo': 'negocio'}),
        headers: {'Authorization': 'Bearer abc'});
    final c = ClienteApi(base: base, tokens: _Tokens('abc'), dio: dio);
    final r = await c.get('/yo');
    expect((r as Exito).valor['tipo'], 'negocio');
  });

  test('tras un 401 renueva y reintenta una vez; si vuelve 401, cierra sesión y no hay tercer intento', () async {
    var llamadas = 0;
    adaptador.onGet('/yo', (s) { llamadas++; s.reply(401, {'error': {'codigo': 'no_autenticado', 'mensaje': 'x'}}); });
    final t = _Tokens('viejo');
    final r = await ClienteApi(base: base, tokens: t, dio: dio).get('/yo');
    expect(r, isA<Falla<Map<String, dynamic>>>());
    expect((r as Falla).error, isA<SesionVencida>());
    expect(llamadas, 2);
    expect(t.renovaciones, 1);
    expect(t.cerrada, isTrue);
  });

  test('un 500 no cierra la sesión', () async {
    adaptador.onGet('/yo', (s) => s.reply(500, {'error': {'codigo': 'interno', 'mensaje': 'x'}}));
    final t = _Tokens('abc');
    final r = await ClienteApi(base: base, tokens: t, dio: dio).get('/yo');
    expect((r as Falla).error, isA<Servidor>());
    expect(t.cerrada, isFalse);
  });

  test('sin red → SinRed', () async {
    adaptador.onGet('/yo', (s) => s.throws(0, DioException.connectionError(
        requestOptions: RequestOptions(path: '/yo'), reason: 'off')));
    final r = await ClienteApi(base: base, tokens: _Tokens('abc'), dio: dio).get('/yo');
    expect((r as Falla).error, isA<SinRed>());
  });
}
```

- [ ] **Step 5: Implementar el cliente**

`lib/nucleo/red/cliente_api.dart`:
```dart
import 'package:dio/dio.dart';
import '../util/resultado.dart';
import 'errores_api.dart';
import 'politica_reintento.dart';

abstract class ProveedorToken {
  String? get token;
  Future<String?> renovar();
  /// La sesión no se pudo rescatar: quien implementa cierra y manda al login.
  Future<void> sesionVencida();
}

/// El ÚNICO cliente HTTP de la app. Solo GET (la v1 es de lectura). Nunca
/// registra el token ni los cuerpos.
class ClienteApi {
  ClienteApi({required String base, required ProveedorToken tokens, Dio? dio})
      : _tokens = tokens,
        _dio = dio ?? Dio(BaseOptions(
          baseUrl: base,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'Accept': 'application/json'},
          validateStatus: (_) => true,
        ));

  final Dio _dio;
  final ProveedorToken _tokens;

  Future<Resultado<Map<String, dynamic>>> get(String ruta, {Map<String, String>? query}) =>
      _intentar(ruta, query, intento: 0);

  Future<Resultado<Map<String, dynamic>>> _intentar(
    String ruta, Map<String, String>? query, {required int intento}) async {
    final Response<dynamic> res;
    try {
      res = await _dio.get<dynamic>(
        ruta,
        queryParameters: query,
        options: Options(headers: {'Authorization': 'Bearer ${_tokens.token ?? ''}'}, validateStatus: (_) => true),
      );
    } on DioException catch (e) {
      final error = switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.connectionError => const SinRed(),
        _ => const Servidor(),
      };
      return Falla(error);
    }

    final status = res.statusCode ?? 0;
    if (status >= 200 && status < 300) {
      final datos = res.data;
      if (datos is Map<String, dynamic>) return Exito(datos);
      return const Falla(RespuestaInvalida('el cuerpo no es un objeto JSON'));
    }

    final error = errorDeRespuesta(status, res.data, retryAfter: res.headers.value('retry-after'));
    switch (decidirReintento(error, intento: intento)) {
      case AccionReintento.renovarYReintentar:
        final nuevo = await _tokens.renovar();
        if (nuevo == null) { await _tokens.sesionVencida(); return Falla(error); }
        return _intentar(ruta, query, intento: intento + 1);
      case AccionReintento.esperarYReintentar:
        await Future<void>.delayed(Duration(seconds: (error as Limite).segundos));
        return _intentar(ruta, query, intento: intento + 1);
      case AccionReintento.noReintentar:
        if (error is SesionVencida) await _tokens.sesionVencida();
        return Falla(error);
    }
  }
}
```

- [ ] **Step 6: Verificar** — `flutter test test/nucleo/red` → PASS (la prueba del 429 real no se hace con espera: la política pura ya la cubre).
- [ ] **Step 7: Commit (dueño)** — `"Red: Resultado, errores del contrato, política de reintento con prueba y el único cliente HTTP"`

---

### Task 6: Sesión (Supabase + almacenamiento seguro) y decisión de arranque

**Files:**
- Create: `lib/nucleo/sesion/sesion.dart`, `lib/nucleo/sesion/sesion_supabase.dart`, `lib/nucleo/sesion/arranque_core.dart`, `lib/nucleo/sesion/providers.dart`
- Test: `test/nucleo/sesion/arranque_core_test.dart`, `test/nucleo/sesion/mapa_errores_acceso_test.dart`

**Interfaces:**
- Produces:
  - `abstract class Sesion implements ProveedorToken { bool get autenticado; Stream<bool> get cambios; Future<Resultado<void>> entrar(String correo, String contrasena); Future<void> salir(); }`
  - `class SesionSupabase extends Sesion` (persistencia en `flutter_secure_storage`).
  - `enum DestinoArranque { entrar, negocio, candidatoNoSoportado }`; `DestinoArranque destinoArranque({required bool haySesion, required String? tipoYo})`
  - `ErrorApi errorDeAcceso(String codigoSupabase, String mensaje)` → `Servidor` con texto nuestro: `invalid_credentials` → «Correo o contraseña incorrectos.», `email_not_confirmed` → «Tu correo aún no está verificado. Ábrelo desde el enlace que te mandamos.», otro → mensaje genérico.
  - Providers: `sesionProvider: Provider<Sesion>`, `autenticadoProvider: StreamProvider<bool>`, `clienteApiProvider: Provider<ClienteApi>`.

- [ ] **Step 1: Pruebas puras (fallan primero)**

`test/nucleo/sesion/arranque_core_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/nucleo/sesion/arranque_core.dart';

void main() {
  test('sin sesión → entrar', () {
    expect(destinoArranque(haySesion: false, tipoYo: null), DestinoArranque.entrar);
  });
  test('con sesión de negocio → negocio', () {
    expect(destinoArranque(haySesion: true, tipoYo: 'negocio'), DestinoArranque.negocio);
  });
  test('con sesión de candidato → aviso y salir (esta versión es para negocios)', () {
    expect(destinoArranque(haySesion: true, tipoYo: 'candidato'), DestinoArranque.candidatoNoSoportado);
  });
  test('con sesión pero /yo falló → se queda en negocio y la pantalla muestra el error', () {
    expect(destinoArranque(haySesion: true, tipoYo: null), DestinoArranque.negocio);
  });
}
```

`test/nucleo/sesion/mapa_errores_acceso_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/nucleo/sesion/arranque_core.dart';

void main() {
  test('los errores de Supabase se traducen', () {
    expect(errorDeAcceso('invalid_credentials', 'Invalid login').mensaje, 'Correo o contraseña incorrectos.');
    expect(errorDeAcceso('email_not_confirmed', 'x').mensaje, startsWith('Tu correo aún no está verificado'));
    expect(errorDeAcceso('otro', 'x').mensaje, 'No se pudo entrar. Intenta de nuevo.');
  });
}
```

- [ ] **Step 2: Correr y ver fallar.**

- [ ] **Step 3: Implementar**

`lib/nucleo/sesion/arranque_core.dart`:
```dart
import '../red/errores_api.dart';

enum DestinoArranque { entrar, negocio, candidatoNoSoportado }

/// Pura. `tipoYo` es lo que contestó `/yo` (null si falló: entonces se entra y la
/// pantalla de Inicio muestra el error con Reintentar; no se expulsa a nadie por un 500).
DestinoArranque destinoArranque({required bool haySesion, required String? tipoYo}) {
  if (!haySesion) return DestinoArranque.entrar;
  if (tipoYo == 'candidato') return DestinoArranque.candidatoNoSoportado;
  return DestinoArranque.negocio;
}

ErrorApi errorDeAcceso(String codigo, String mensaje) {
  return switch (codigo) {
    'invalid_credentials' || 'invalid_grant' => const Servidor('Correo o contraseña incorrectos.'),
    'email_not_confirmed' => const Servidor('Tu correo aún no está verificado. Ábrelo desde el enlace que te mandamos.'),
    _ => const Servidor('No se pudo entrar. Intenta de nuevo.'),
  };
}
```

`lib/nucleo/sesion/sesion.dart`:
```dart
import '../red/cliente_api.dart';
import '../util/resultado.dart';

abstract class Sesion implements ProveedorToken {
  bool get autenticado;
  Stream<bool> get cambios;
  Future<Resultado<void>> entrar(String correo, String contrasena);
  Future<void> salir();
}
```

`lib/nucleo/sesion/sesion_supabase.dart`:
```dart
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';
import '../red/errores_api.dart';
import '../util/resultado.dart';
import 'arranque_core.dart';
import 'sesion.dart';

/// La sesión vive en Keychain / Keystore, nunca en preferencias planas.
class _AlmacenSeguro extends LocalStorage {
  _AlmacenSeguro() : _s = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );
  final FlutterSecureStorage _s;
  static const _llave = 'ry_sesion';
  @override
  Future<void> initialize() async {}
  @override
  Future<String?> accessToken() => _s.read(key: _llave);
  @override
  Future<bool> hasAccessToken() async => (await _s.read(key: _llave)) != null;
  @override
  Future<void> persistSession(String persistSessionString) => _s.write(key: _llave, value: persistSessionString);
  @override
  Future<void> removePersistedSession() => _s.delete(key: _llave);
}

class SesionSupabase extends Sesion {
  SesionSupabase._();

  static Future<SesionSupabase> iniciar() async {
    await Supabase.initialize(
      url: Config.supabaseUrl,
      anonKey: Config.supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(localStorage: _AlmacenSeguro(), autoRefreshToken: true),
    );
    return SesionSupabase._();
  }

  GoTrueClient get _auth => Supabase.instance.client.auth;

  @override
  bool get autenticado => _auth.currentSession != null;

  @override
  Stream<bool> get cambios => _auth.onAuthStateChange.map((e) => e.session != null).distinct();

  @override
  String? get token => _auth.currentSession?.accessToken;

  @override
  Future<String?> renovar() async {
    try {
      final r = await _auth.refreshSession().timeout(const Duration(seconds: 10));
      return r.session?.accessToken;
    } on Exception {
      return null;
    }
  }

  @override
  Future<void> sesionVencida() => salir();

  @override
  Future<Resultado<void>> entrar(String correo, String contrasena) async {
    try {
      await _auth
          .signInWithPassword(email: correo.trim(), password: contrasena)
          .timeout(const Duration(seconds: 15));
      return const Exito(null);
    } on AuthException catch (e) {
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
      await _auth.signOut(scope: SignOutScope.local).timeout(const Duration(seconds: 10));
    } on Exception {
      // Aunque Supabase no conteste, la sesión local se tira.
    }
  }
}
```

`lib/nucleo/sesion/providers.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config.dart';
import '../red/cliente_api.dart';
import 'sesion.dart';

/// Se sobreescribe en `main` con la sesión real (y en pruebas con una falsa).
final sesionProvider = Provider<Sesion>((_) => throw UnimplementedError('sesionProvider sin override'));

final autenticadoProvider = StreamProvider<bool>((ref) => ref.watch(sesionProvider).cambios);

final clienteApiProvider = Provider<ClienteApi>(
  (ref) => ClienteApi(base: Config.apiBase, tokens: ref.watch(sesionProvider)),
);
```

- [ ] **Step 4: Verificar** — `flutter test test/nucleo/sesion` → PASS. Si `LocalStorage` de `supabase_flutter` tiene otras firmas en la versión instalada, ajustar la clase `_AlmacenSeguro` a la interfaz real (ver `~/.pub-cache/hosted/pub.dev/supabase_flutter-*/lib/src/local_storage.dart`).
- [ ] **Step 5: Commit (dueño)** — `"Sesión con Supabase guardada en Keychain/Keystore, decisión de arranque y traducción de errores de acceso, con pruebas"`

---

### Task 7: Modelos del negocio (tolerantes) y `parsear`

**Files:**
- Create: `lib/funciones/negocio/comun/modelos/yo.dart`, `.../inicio.dart`, `.../vacantes.dart`, `.../ranking.dart`, `.../ficha_candidato.dart`, `lib/funciones/negocio/comun/parsear.dart` (+ los `.g.dart` generados)
- Test: `test/funciones/negocio/comun/modelos_test.dart`

**Interfaces:**
- Produces (todas `@JsonSerializable(createToJson: false)` con `fromJson`):
  - `Yo { String tipo; String nombre; String iniciales; String? rol; bool veDinero; EmpresaYo? empresa; bool variasSucursales; String? correo; }`, `EmpresaYo { String nombre; String? logoUrl; String? logoFit; }`
  - `Inicio { Indicadores indicadores; Saldo? saldo; }`, `Indicadores { num? velocidad, velocidadDelta; int? cumplenPct, cumplenN, cumplenTotal; num? cumplenDelta; num? respuestaPct, respuestaDelta; int? tiempoDias; num? tiempoDelta; }`, `Saldo { int plan, extra, total; }`
  - `SucursalRef { String id; String nombre; int colorIdx; }`, `VacanteResumen { String id, puesto, estado, slug; String? ubicacion, sueldoTexto; SucursalRef? sucursal; int candidatos, sinRankear; int? diasRestantes; }`, `VacanteCerrada { String id, puesto, slug; String? ubicacion, sueldoTexto; DateTime? cerradaAt; bool huboContratacion, purgada; int candidatos; SucursalRef? sucursal; int? diasParaArchivar; }`, `Pregunta { String id, texto; bool esRequisito; }`, `Conteos { int total, rankeados, sinRankear, cumplenRequisitos; bool pideRequisitos; }`, `VacanteFicha { String id, puesto, estado, slug; String? descripcion, ubicacion, sueldoTexto, turno, sucursal; int diasParaResponder; bool formularioCerrado, purgada; int? diasRestantes, diasParaArchivar; DateTime? cerradaAt; bool? huboContratacion; List<Pregunta> preguntas; Conteos conteos; }`
  - `FilaRanking { String postulacionId, nombre; int ranking; bool apellidoOculto; String? whatsapp, zona, resumen, entregaFallo; num? score, testScore; int? minutosTraslado; bool contactado, noRespondio, contratado, videoSolicitado, videoRecibido, documentoSolicitado, documentoRecibido; String testEstado; DateTime? fechaLimite; int requisitosIncumplidos, requisitosTotal; }`, `Bloqueado { String postulacionId; int ranking; num? score; }`, `Ranking { List<FilaRanking> visibles; List<Bloqueado> bloqueados; int total; }`
  - `Material { bool solicitado, recibido; String? url, tipo; }`, `ResultadoTest { Map<String, num> rasgos; List<String> top3, arquetipo, comentarios; String integridad, integridadTono; int respuestasMarcadas; }`, `Test { String estado; String? duracion; ResultadoTest? resultado; }`, `Respuesta { String texto, respuesta; bool abierta, requisito, incumple; }`, `FichaCandidato { String postulacionId, nombre; bool contactado, contratado, noRespondio; String? whatsapp, zona, resumen, turnoDisponible, sueldoEsperado, entregaFallo; int? minutosTraslado, experienciaMeses; num? score; DateTime? fechaLimite; Material video, documento; Test test; List<Respuesta> respuestas, extras; }`
  - `Resultado<T> parsear<T>(Resultado<Map<String, dynamic>> r, T Function(Map<String, dynamic>) fromJson)` y `Resultado<List<T>> parsearLista<T>(Resultado<Map<String, dynamic>> r, T Function(Map<String, dynamic>) fromJson)` (lee `items`).

- [ ] **Step 1: Pruebas (fallan primero)** — `test/funciones/negocio/comun/modelos_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/ranking.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/vacantes.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/yo.dart';
import 'package:reclutaya_app/funciones/negocio/comun/parsear.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/util/resultado.dart';

void main() {
  test('Yo de negocio y de candidato (campos desconocidos se ignoran)', () {
    final n = Yo.fromJson({'tipo': 'negocio', 'nombre': 'Antonio', 'iniciales': 'AP', 'rol': 'owner',
      'veDinero': true, 'empresa': {'nombre': 'Tacos', 'logoUrl': null, 'logoFit': 'cover'},
      'variasSucursales': false, 'campoNuevo': 1});
    expect(n.empresa!.nombre, 'Tacos');
    final c = Yo.fromJson({'tipo': 'candidato', 'nombre': 'Ana', 'iniciales': 'AP', 'correo': 'a@b.c'});
    expect(c.empresa, isNull);
    expect(c.veDinero, isFalse);
  });

  test('una fila del ranking sin contactar llega enmascarada y así se queda', () {
    final f = FilaRanking.fromJson({'postulacionId': 'p1', 'ranking': 1, 'nombre': 'Ana',
      'apellidoOculto': true, 'whatsapp': null, 'score': 87, 'testEstado': 'NO_ENVIADA',
      'requisitosIncumplidos': 1, 'requisitosTotal': 4});
    expect(f.whatsapp, isNull);
    expect(f.apellidoOculto, isTrue);
    expect(f.contactado, isFalse);
  });

  test('parsear devuelve respuestaInvalida si falta un campo obligatorio', () {
    final r = parsear(const Exito(<String, dynamic>{'id': 'v1'}), VacanteResumen.fromJson);
    expect(r, isA<Falla<VacanteResumen>>());
    expect((r as Falla).error, isA<RespuestaInvalida>());
  });

  test('parsearLista lee items y tolera cursor null', () {
    final r = parsearLista(const Exito({'items': [
      {'id': 'v1', 'puesto': 'Mesero', 'estado': 'ACTIVA', 'slug': 'mesero', 'candidatos': 3, 'sinRankear': 0}
    ], 'cursor': null}), VacanteResumen.fromJson);
    expect((r as Exito).valor.single.puesto, 'Mesero');
  });

  test('una Falla pasa tal cual', () {
    final r = parsear<VacanteResumen>(const Falla(SinRed()), VacanteResumen.fromJson);
    expect((r as Falla).error, isA<SinRed>());
  });
}
```

- [ ] **Step 2: Correr y ver fallar.**

- [ ] **Step 3: Implementar modelos** (patrón; repetir para cada clase de la lista de interfaces, con `@JsonKey(defaultValue: …)` en booleanos y enteros que el contrato permite omitir, `DateTime?` para fechas ISO):

`lib/funciones/negocio/comun/modelos/yo.dart`:
```dart
import 'package:json_annotation/json_annotation.dart';
part 'yo.g.dart';

@JsonSerializable(createToJson: false)
class EmpresaYo {
  const EmpresaYo({required this.nombre, this.logoUrl, this.logoFit});
  factory EmpresaYo.fromJson(Map<String, dynamic> j) => _$EmpresaYoFromJson(j);
  final String nombre;
  final String? logoUrl;
  final String? logoFit;
}

@JsonSerializable(createToJson: false)
class Yo {
  const Yo({
    required this.tipo, required this.nombre, required this.iniciales,
    this.rol, this.veDinero = false, this.empresa, this.variasSucursales = false, this.correo,
  });
  factory Yo.fromJson(Map<String, dynamic> j) => _$YoFromJson(j);
  final String tipo;
  final String nombre;
  final String iniciales;
  final String? rol;
  @JsonKey(defaultValue: false)
  final bool veDinero;
  final EmpresaYo? empresa;
  @JsonKey(defaultValue: false)
  final bool variasSucursales;
  final String? correo;
  bool get esNegocio => tipo == 'negocio';
}
```
Los demás archivos siguen exactamente este patrón con los campos de la lista de interfaces (`ranking.dart` incluye `FilaRanking`, `Bloqueado`, `Ranking`; `vacantes.dart` incluye `SucursalRef`, `VacanteResumen`, `VacanteCerrada`, `Pregunta`, `Conteos`, `VacanteFicha`; `ficha_candidato.dart` incluye `Material`, `ResultadoTest`, `Test`, `Respuesta`, `FichaCandidato`; `inicio.dart` incluye `Indicadores`, `Saldo`, `Inicio`). Para `rasgos`: `@JsonKey(defaultValue: <String, num>{}) final Map<String, num> rasgos;`.

`lib/funciones/negocio/comun/parsear.dart`:
```dart
import '../../../nucleo/red/errores_api.dart';
import '../../../nucleo/util/resultado.dart';

Resultado<T> parsear<T>(Resultado<Map<String, dynamic>> r, T Function(Map<String, dynamic>) fromJson) {
  return switch (r) {
    Falla(:final error) => Falla(error),
    Exito(:final valor) => _seguro(() => fromJson(valor)),
  };
}

Resultado<List<T>> parsearLista<T>(
  Resultado<Map<String, dynamic>> r, T Function(Map<String, dynamic>) fromJson) {
  return switch (r) {
    Falla(:final error) => Falla(error),
    Exito(:final valor) => _seguro(() {
        final items = valor['items'];
        if (items is! List) throw const FormatException('falta items');
        return [for (final i in items) fromJson(i as Map<String, dynamic>)];
      }),
  };
}

Resultado<T> _seguro<T>(T Function() f) {
  try {
    return Exito(f());
  } on Object catch (e) {
    // Solo el tipo del error, nunca el cuerpo: podría traer datos de personas.
    return Falla(RespuestaInvalida(e.runtimeType.toString()));
  }
}
```

- [ ] **Step 4: Generar y verificar**
Run: `dart run build_runner build --delete-conflicting-outputs && flutter test test/funciones/negocio/comun` → PASS.
- [ ] **Step 5: Commit (dueño)** — `"Modelos del contrato v1, tolerantes a campos nuevos, y parseo seguro que nunca truena"`

---

### Task 8: Repositorio, falso de pruebas y providers

**Files:**
- Create: `lib/funciones/negocio/comun/repositorio_negocio.dart`, `lib/funciones/negocio/comun/providers.dart`, `test/apoyo/repositorio_falso.dart`, `test/apoyo/datos.dart`
- Test: `test/funciones/negocio/comun/providers_test.dart`

**Interfaces:**
- Produces: `abstract class RepositorioNegocio { Future<Resultado<Yo>> yo(); Future<Resultado<Inicio>> inicio(); Future<Resultado<List<VacanteResumen>>> vacantesActivas(); Future<Resultado<List<VacanteCerrada>>> vacantesCerradas(); Future<Resultado<VacanteFicha>> vacante(String slug); Future<Resultado<Ranking>> ranking(String slug); Future<Resultado<FichaCandidato>> candidato(String postulacionId); }`, `class RepositorioNegocioApi implements RepositorioNegocio { RepositorioNegocioApi(ClienteApi); }`, providers `repositorioProvider`, `yoProvider: FutureProvider<Yo>`, `inicioProvider`, `vacantesActivasProvider`, `vacantesCerradasProvider`, `vacanteProvider: FutureProvider.family<VacanteFicha, String>`, `rankingProvider: FutureProvider.family<Ranking, String>`, `candidatoProvider: FutureProvider.family<FichaCandidato, String>`; `void olvidarTodo(Ref|WidgetRef)` que invalida todos.
- Pruebas: `RepositorioFalso` con campos sobreescribibles (`yoR`, `inicioR`, …) y `datos.dart` con instancias de ejemplo (`yoNegocio`, `inicioEjemplo`, `vacanteActiva`, `vacanteCerradaEjemplo`, `fichaVacante`, `rankingEjemplo` (3 filas: una sin contactar, una contactada con video recibido, una contratada; y 1 bloqueado), `fichaCandidatoContactada`, `fichaCandidatoSinContactar`).

- [ ] **Step 1: Prueba (falla primero)** — `test/funciones/negocio/comun/providers_test.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/util/resultado.dart';
import '../../../apoyo/datos.dart';
import '../../../apoyo/repositorio_falso.dart';

void main() {
  test('el provider entrega el valor y conserva el ErrorApi al fallar', () async {
    final repo = RepositorioFalso()..yoR = Exito(yoNegocio);
    final c = ProviderContainer(overrides: [repositorioProvider.overrideWithValue(repo)]);
    addTearDown(c.dispose);
    expect((await c.read(yoProvider.future)).nombre, yoNegocio.nombre);
    repo.yoR = const Falla(Servidor());
    c.invalidate(yoProvider);
    await expectLater(c.read(yoProvider.future), throwsA(isA<Servidor>()));
  });
}
```

- [ ] **Step 2: Implementar**

`lib/funciones/negocio/comun/repositorio_negocio.dart`:
```dart
import '../../../nucleo/red/cliente_api.dart';
import '../../../nucleo/util/resultado.dart';
import 'modelos/ficha_candidato.dart';
import 'modelos/inicio.dart';
import 'modelos/ranking.dart';
import 'modelos/vacantes.dart';
import 'modelos/yo.dart';
import 'parsear.dart';

/// Un método por ruta del contrato. La v2 agrega métodos; no cambia estos.
abstract class RepositorioNegocio {
  Future<Resultado<Yo>> yo();
  Future<Resultado<Inicio>> inicio();
  Future<Resultado<List<VacanteResumen>>> vacantesActivas();
  Future<Resultado<List<VacanteCerrada>>> vacantesCerradas();
  Future<Resultado<VacanteFicha>> vacante(String slug);
  Future<Resultado<Ranking>> ranking(String slug);
  Future<Resultado<FichaCandidato>> candidato(String postulacionId);
}

class RepositorioNegocioApi implements RepositorioNegocio {
  RepositorioNegocioApi(this._api);
  final ClienteApi _api;

  @override
  Future<Resultado<Yo>> yo() async => parsear(await _api.get('/yo'), Yo.fromJson);
  @override
  Future<Resultado<Inicio>> inicio() async => parsear(await _api.get('/negocio/inicio'), Inicio.fromJson);
  @override
  Future<Resultado<List<VacanteResumen>>> vacantesActivas() async =>
      parsearLista(await _api.get('/negocio/vacantes', query: {'estado': 'activas'}), VacanteResumen.fromJson);
  @override
  Future<Resultado<List<VacanteCerrada>>> vacantesCerradas() async =>
      parsearLista(await _api.get('/negocio/vacantes', query: {'estado': 'cerradas'}), VacanteCerrada.fromJson);
  @override
  Future<Resultado<VacanteFicha>> vacante(String slug) async =>
      parsear(await _api.get('/negocio/vacantes/${Uri.encodeComponent(slug)}'), VacanteFicha.fromJson);
  @override
  Future<Resultado<Ranking>> ranking(String slug) async =>
      parsear(await _api.get('/negocio/vacantes/${Uri.encodeComponent(slug)}/ranking'), Ranking.fromJson);
  @override
  Future<Resultado<FichaCandidato>> candidato(String id) async =>
      parsear(await _api.get('/negocio/postulaciones/${Uri.encodeComponent(id)}'), FichaCandidato.fromJson);
}
```

`lib/funciones/negocio/comun/providers.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../nucleo/sesion/providers.dart';
import '../../../nucleo/util/resultado.dart';
import 'modelos/ficha_candidato.dart';
import 'modelos/inicio.dart';
import 'modelos/ranking.dart';
import 'modelos/vacantes.dart';
import 'modelos/yo.dart';
import 'repositorio_negocio.dart';

final repositorioProvider = Provider<RepositorioNegocio>(
  (ref) => RepositorioNegocioApi(ref.watch(clienteApiProvider)),
);

// Todo vive en MEMORIA y solo mientras hay sesión: `olvidarTodo` al salir.
final yoProvider = FutureProvider<Yo>((ref) async => (await ref.watch(repositorioProvider).yo()).valorOLanza);
final inicioProvider = FutureProvider<Inicio>((ref) async => (await ref.watch(repositorioProvider).inicio()).valorOLanza);
final vacantesActivasProvider = FutureProvider<List<VacanteResumen>>(
    (ref) async => (await ref.watch(repositorioProvider).vacantesActivas()).valorOLanza);
final vacantesCerradasProvider = FutureProvider<List<VacanteCerrada>>(
    (ref) async => (await ref.watch(repositorioProvider).vacantesCerradas()).valorOLanza);
final vacanteProvider = FutureProvider.family<VacanteFicha, String>(
    (ref, slug) async => (await ref.watch(repositorioProvider).vacante(slug)).valorOLanza);
final rankingProvider = FutureProvider.family<Ranking, String>(
    (ref, slug) async => (await ref.watch(repositorioProvider).ranking(slug)).valorOLanza);
final candidatoProvider = FutureProvider.family<FichaCandidato, String>(
    (ref, id) async => (await ref.watch(repositorioProvider).candidato(id)).valorOLanza);

void olvidarTodo(WidgetRef ref) {
  ref
    ..invalidate(yoProvider)
    ..invalidate(inicioProvider)
    ..invalidate(vacantesActivasProvider)
    ..invalidate(vacantesCerradasProvider)
    ..invalidate(vacanteProvider)
    ..invalidate(rankingProvider)
    ..invalidate(candidatoProvider);
}
```

`test/apoyo/repositorio_falso.dart`:
```dart
import 'package:reclutaya_app/funciones/negocio/comun/modelos/ficha_candidato.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/inicio.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/ranking.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/vacantes.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/yo.dart';
import 'package:reclutaya_app/funciones/negocio/comun/repositorio_negocio.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/util/resultado.dart';
import 'datos.dart';

class RepositorioFalso implements RepositorioNegocio {
  Resultado<Yo> yoR = Exito(yoNegocio);
  Resultado<Inicio> inicioR = Exito(inicioEjemplo);
  Resultado<List<VacanteResumen>> activasR = Exito([vacanteActiva]);
  Resultado<List<VacanteCerrada>> cerradasR = Exito([vacanteCerradaEjemplo]);
  Resultado<VacanteFicha> vacanteR = Exito(fichaVacante);
  Resultado<Ranking> rankingR = Exito(rankingEjemplo);
  Resultado<FichaCandidato> candidatoR = Exito(fichaCandidatoContactada);
  int llamadasCandidato = 0;
  Duration demora = Duration.zero;

  Future<T> _r<T>(T v) async { if (demora > Duration.zero) await Future<void>.delayed(demora); return v; }
  @override Future<Resultado<Yo>> yo() => _r(yoR);
  @override Future<Resultado<Inicio>> inicio() => _r(inicioR);
  @override Future<Resultado<List<VacanteResumen>>> vacantesActivas() => _r(activasR);
  @override Future<Resultado<List<VacanteCerrada>>> vacantesCerradas() => _r(cerradasR);
  @override Future<Resultado<VacanteFicha>> vacante(String slug) => _r(vacanteR);
  @override Future<Resultado<Ranking>> ranking(String slug) => _r(rankingR);
  @override Future<Resultado<FichaCandidato>> candidato(String id) { llamadasCandidato++; return _r(candidatoR); }
}

Resultado<T> falla<T>(ErrorApi e) => Falla<T>(e);
```

`test/apoyo/datos.dart`: instancias construidas con los constructores (no con JSON) para cada modelo nombrado arriba; `rankingEjemplo` con tres filas (`Ana` sin contactar, apellidoOculto true, score 87, requisitos 1/4; `Luis Pérez` contactado, videoRecibido, requisitosTotal 0; `Marta Ruiz` contratada) y un bloqueado (ranking 12, score 41).

- [ ] **Step 3: Verificar** — `flutter test test/funciones/negocio/comun` → PASS.
- [ ] **Step 4: Commit (dueño)** — `"Repositorio del negocio (una llamada por ruta), providers en memoria y el repositorio falso de pruebas"`

---

### Task 9: Reglas de presentación y formato (puras)

**Files:**
- Create: `lib/funciones/negocio/comun/presentacion.dart`, `lib/nucleo/util/formato.dart`
- Test: `test/funciones/negocio/comun/presentacion_test.dart`, `test/nucleo/util/formato_test.dart`

**Interfaces:**
- Produces: `String? textoCumple(int incumplidos, int total)`, `String? textoDiasRestantes(int? dias)`, `String textoCerrada(VacanteCerrada v)`, `String etiquetaRol(String? rol)`, `({String texto, TonoDelta tono}) delta(num? d, String unidad)` con `enum TonoDelta { sube, baja, neutro }`, `Color colorSucursal(int colorIdx, {required bool oscuro})` (la paleta `COLORES_SUCURSAL` de la web: `[#1f5e3a/#4fae74, #d97a1c/#eda04f, #2f6fd0/#7fa8ec, #5b7285/#93a9bc, #bf4342/#e58585]`, índice módulo 5), `String? textoMaterial({required bool solicitado, required bool recibido})` → «Recibido» / «Pedido» / null, `String textoEstadoVacante(String estado)` (ACTIVA→Activa, PAUSADA→En pausa, BORRADOR→Borrador, CERRADA→Cerrada), `BoxFit ajusteLogo(String? logoFit)` (cover→cover, otro→contain), `String textoTraslado(int? min)` → «a 20 min» / «».
- `formato.dart`: `String fechaCorta(DateTime d)` → «2 oct 2026» (es-MX, zona local), `String numero(num n)` → «1,290», `String experiencia(int? meses)` → «1 año 2 meses» / «8 meses» / «Sin experiencia».

- [ ] **Step 1: Pruebas (fallan primero)** — `test/funciones/negocio/comun/presentacion_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/funciones/negocio/comun/presentacion.dart';

void main() {
  test('«Cumple X de Y» solo cuando la vacante pide requisitos', () {
    expect(textoCumple(1, 4), 'Cumple 3 de 4');
    expect(textoCumple(0, 0), isNull);
  });
  test('días restantes en singular, plural y hoy', () {
    expect(textoDiasRestantes(40), '40 días restantes');
    expect(textoDiasRestantes(1), '1 día restante');
    expect(textoDiasRestantes(0), 'Vence hoy');
    expect(textoDiasRestantes(null), isNull);
  });
  test('rol traducido; desconocido no truena', () {
    expect(etiquetaRol('owner'), 'Dueño');
    expect(etiquetaRol('admin'), 'Administrador');
    expect(etiquetaRol('member'), 'Miembro');
    expect(etiquetaRol(null), 'Miembro');
  });
  test('delta con signo, unidad y tono', () {
    expect(delta(10, '%'), (texto: '+10%', tono: TonoDelta.sube));
    expect(delta(-3, '%'), (texto: '-3%', tono: TonoDelta.baja));
    expect(delta(0, ' días'), (texto: 'Sin cambio', tono: TonoDelta.neutro));
    expect(delta(null, '%'), (texto: '—', tono: TonoDelta.neutro));
  });
  test('la paleta de sucursales es la de la web y da la vuelta', () {
    expect(colorSucursal(0, oscuro: false), const Color(0xFF1F5E3A));
    expect(colorSucursal(5, oscuro: false), const Color(0xFF1F5E3A));
    expect(colorSucursal(1, oscuro: true), const Color(0xFFEDA04F));
  });
  test('material: pedido, recibido o nada', () {
    expect(textoMaterial(solicitado: true, recibido: true), 'Recibido');
    expect(textoMaterial(solicitado: true, recibido: false), 'Pedido');
    expect(textoMaterial(solicitado: false, recibido: false), isNull);
  });
}
```
`test/nucleo/util/formato_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:reclutaya_app/nucleo/util/formato.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_MX'));
  test('fecha corta en español', () => expect(fechaCorta(DateTime(2026, 10, 2)), '2 oct 2026'));
  test('números con coma de miles', () => expect(numero(1290), '1,290'));
  test('experiencia en años y meses', () {
    expect(experiencia(14), '1 año 2 meses');
    expect(experiencia(8), '8 meses');
    expect(experiencia(24), '2 años');
    expect(experiencia(0), 'Sin experiencia');
    expect(experiencia(null), 'Sin experiencia');
  });
}
```
Nota: `colorSucursal` vive en `presentacion.dart`, fuera de `lib/nucleo/tema/`; para no romper el guardián de colores, la paleta se declara en `lib/nucleo/tema/tokens.dart` como `const coloresSucursal = [(luz: Color(…), oscuro: Color(…)), …]` y `presentacion.dart` solo la indexa.

- [ ] **Step 2: Correr y ver fallar.**
- [ ] **Step 3: Implementar**

En `lib/nucleo/tema/tokens.dart` (único lugar con colores) agregar:
```dart
/// La paleta de sucursales de la web (`COLORES_SUCURSAL`), en el mismo orden.
const coloresSucursal = <({Color luz, Color oscuro})>[
  (luz: Color(0xFF1F5E3A), oscuro: Color(0xFF4FAE74)),
  (luz: Color(0xFFD97A1C), oscuro: Color(0xFFEDA04F)),
  (luz: Color(0xFF2F6FD0), oscuro: Color(0xFF7FA8EC)),
  (luz: Color(0xFF5B7285), oscuro: Color(0xFF93A9BC)),
  (luz: Color(0xFFBF4342), oscuro: Color(0xFFE58585)),
];
```

`lib/funciones/negocio/comun/presentacion.dart`:
```dart
import 'package:flutter/widgets.dart';
import '../../../nucleo/tema/tokens.dart';
import 'modelos/vacantes.dart';
import '../../../nucleo/util/formato.dart';

/// Reglas de PRESENTACIÓN del negocio: puras, sin widgets. La app no calcula
/// nada del producto; solo decide cómo se lee lo que el servidor ya resolvió.
String? textoCumple(int incumplidos, int total) =>
    total <= 0 ? null : 'Cumple ${total - incumplidos} de $total';

String? textoDiasRestantes(int? dias) => switch (dias) {
      null => null,
      0 => 'Vence hoy',
      1 => '1 día restante',
      final d => '$d días restantes',
    };

String textoCerrada(VacanteCerrada v) {
  final partes = <String>[
    if (v.cerradaAt != null) 'Cerrada el ${fechaCorta(v.cerradaAt!)}',
    if (v.huboContratacion) 'Hubo contratación',
    if (v.purgada) 'Datos purgados'
    else if (v.diasParaArchivar != null) 'Se archiva en ${v.diasParaArchivar} días',
  ];
  return partes.join(' · ');
}

String etiquetaRol(String? rol) => switch (rol) {
      'owner' => 'Dueño',
      'admin' => 'Administrador',
      _ => 'Miembro',
    };

enum TonoDelta { sube, baja, neutro }

({String texto, TonoDelta tono}) delta(num? d, String unidad) {
  if (d == null) return (texto: '—', tono: TonoDelta.neutro);
  if (d == 0) return (texto: 'Sin cambio', tono: TonoDelta.neutro);
  final n = d % 1 == 0 ? d.toInt().toString() : d.toStringAsFixed(1);
  return d > 0
      ? (texto: '+$n$unidad', tono: TonoDelta.sube)
      : (texto: '$n$unidad', tono: TonoDelta.baja);
}

Color colorSucursal(int colorIdx, {required bool oscuro}) {
  final c = coloresSucursal[colorIdx % coloresSucursal.length];
  return oscuro ? c.oscuro : c.luz;
}

String? textoMaterial({required bool solicitado, required bool recibido}) =>
    recibido ? 'Recibido' : (solicitado ? 'Pedido' : null);

String textoEstadoVacante(String estado) => switch (estado) {
      'ACTIVA' => 'Activa',
      'PAUSADA' => 'En pausa',
      'BORRADOR' => 'Borrador',
      'CERRADA' => 'Cerrada',
      _ => estado,
    };

BoxFit ajusteLogo(String? logoFit) => logoFit == 'cover' ? BoxFit.cover : BoxFit.contain;

String textoTraslado(int? min) => min == null ? '' : 'a $min min';
```

`lib/nucleo/util/formato.dart`:
```dart
import 'package:intl/intl.dart';

/// «2 oct 2026»: intl pone «oct.» con punto en es_MX; se quita.
String fechaCorta(DateTime d) =>
    DateFormat('d MMM y', 'es_MX').format(d.toLocal()).replaceAll('.', '');

String numero(num n) => NumberFormat.decimalPattern('es_MX').format(n);

String experiencia(int? meses) {
  if (meses == null || meses <= 0) return 'Sin experiencia';
  final a = meses ~/ 12;
  final m = meses % 12;
  final partes = <String>[
    if (a > 0) a == 1 ? '1 año' : '$a años',
    if (m > 0) m == 1 ? '1 mes' : '$m meses',
  ];
  return partes.join(' ');
}
```
- [ ] **Step 4: Verificar** — `flutter test test/funciones/negocio/comun test/nucleo/util test/guardianes` → PASS.
- [ ] **Step 5: Commit (dueño)** — `"Reglas de presentación del negocio y formato es-MX, puras y con prueba"`

---

### Task 10: UI común (tarjeta, chip, esqueleto, estados, avatar, apellido difuminado, cifra)

**Files:**
- Create: `lib/nucleo/ui/tarjeta.dart`, `chip.dart`, `esqueleto.dart`, `estados.dart` (`EstadoVacio`, `EstadoError`, `BannerSinRed`), `avatar_iniciales.dart`, `apellido_difuminado.dart`, `cifra.dart`, `logo_negocio.dart`
- Test: `test/nucleo/ui/estados_test.dart`, `test/nucleo/ui/apellido_difuminado_test.dart`

**Interfaces:**
- Produces: `Tarjeta({required Widget child, EdgeInsets padding = const EdgeInsets.all(18), VoidCallback? alTocar})`, `enum TonoChip { neutro, verde, naranja, azul, rojo }`, `ChipRY(String texto, {TonoChip tono = TonoChip.neutro, IconData? icono})`, `Esqueleto({double alto, double ancho = double.infinity, double radio = 10})` (brillo suave animado; quieto con `disableAnimations`), `EstadoVacio({required String titulo, String? texto})`, `EstadoError({required ErrorApi error, required VoidCallback alReintentar})` (texto = `error.mensaje`; si es `NoEncontrado` el botón dice «Volver»), `BannerSinRed()`, `AvatarIniciales(String iniciales, {double tam = 40})`, `ApellidoDifuminado()` (pastilla con degradado de la tinta tenue a transparente, **sin filtros de desenfoque**: 40 filas con `ImageFiltered` cuestan un `saveLayer` cada una), `Cifra({required String valor, required String etiqueta, String? sub, Widget? delta, bool principal = false})`, `LogoNegocio({String? url, required String nombre, String? logoFit, double tam = 44})` (cached_network_image; sin URL, iniciales).

- [ ] **Step 1: Pruebas (fallan primero)**
```dart
// test/nucleo/ui/estados_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/tema/tema.dart';
import 'package:reclutaya_app/nucleo/ui/estados.dart';

void main() {
  testWidgets('EstadoError muestra el mensaje del error y Reintentar', (tester) async {
    var toques = 0;
    await tester.pumpWidget(MaterialApp(theme: temaClaro(), home: Scaffold(
      body: EstadoError(error: const Servidor(), alReintentar: () => toques++))));
    expect(find.text('No se pudo cargar. Intenta de nuevo.'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    expect(toques, 1);
  });
  testWidgets('con NoEncontrado el botón dice Volver', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: temaClaro(), home: Scaffold(
      body: EstadoError(error: const NoEncontrado(), alReintentar: () {}))));
    expect(find.text('Volver'), findsOneWidget);
  });
}
```
```dart
// test/nucleo/ui/apellido_difuminado_test.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/nucleo/tema/tema.dart';
import 'package:reclutaya_app/nucleo/ui/apellido_difuminado.dart';

void main() {
  testWidgets('no usa filtros de imagen (rendimiento en listas)', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: temaClaro(), home: const Scaffold(body: ApellidoDifuminado())));
    expect(find.byType(ImageFiltered), findsNothing);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.bySemanticsLabel('Apellido oculto'), findsOneWidget);
  });
}
```
- [ ] **Step 2: Correr y ver fallar.**
- [ ] **Step 3: Implementar** los ocho widgets con los tokens (`context.t`), `formaTarjeta(radioGrande)` en `Tarjeta` y `Semantics(label: 'Apellido oculto')` en la pastilla.
- [ ] **Step 4: Verificar** — `flutter test test/nucleo/ui test/guardianes` → PASS.
- [ ] **Step 5: Commit (dueño)** — `"UI común: tarjeta, chip, esqueleto, estados vacío/error/sin red, avatar, apellido difuminado sin filtros, cifra y logo"`

---

### Task 11: Rutas, cascarón de pestañas y arranque con el isotipo líquido

**Files:**
- Create: `lib/nucleo/rutas/rutas.dart`, `lib/funciones/arranque/pantalla_arranque.dart`, `lib/funciones/arranque/isotipo_liquido.dart`, `lib/funciones/arranque/nivel_espera.dart`, `lib/funciones/cascaron/pantalla_cascaron.dart`, `lib/app.dart`, `lib/main.dart`
- Test: `test/funciones/arranque/nivel_espera_test.dart`, `test/nucleo/rutas/guardas_test.dart`

**Interfaces:**
- Produces: `GoRouter crearRouter(Ref)` con rutas `/arranque`, `/entrar`, y un `StatefulShellRoute.indexedStack` con ramas `/inicio`, `/vacantes` (hijas `/vacantes/:slug`, `/vacantes/:slug/ranking`, `/vacantes/:slug/ranking/:id`) y `/cuenta`; `String? redirigir({required bool autenticado, required String ruta})` (pura: sin sesión y ruta ≠ `/entrar`/`/arranque` → `/entrar`; con sesión y ruta `/entrar` → `/inicio`); `double nivelEspera(double segundos, {double desde = 0})` (misma curva que la web: `0.9 - (0.9 - desde) * e^(-t/1.6)`); `IsotipoLiquido({required double nivel})`; `PantallaArranque` (controla el nivel con un ticker, pide `/yo`, decide con `destinoArranque` y navega; con `candidatoNoSoportado` muestra el aviso y `salir()`); `PantallaCascaron` (`BarraPestanas` + `IndexedStack` de go_router); `main()` (Sentry si hay DSN, `prepararVidrio()`, `SesionSupabase.iniciar()`, `initializeDateFormatting('es_MX')`, `ProviderScope(overrides: [sesionProvider.overrideWithValue(sesion)])`).

- [ ] **Step 1: Pruebas (fallan primero)**
```dart
// test/funciones/arranque/nivel_espera_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/funciones/arranque/nivel_espera.dart';

void main() {
  test('sube rápido y nunca pasa de 0.9 mientras espera', () {
    expect(nivelEspera(0), 0);
    expect(nivelEspera(1), greaterThan(0.4));
    expect(nivelEspera(60), lessThanOrEqualTo(0.9));
  });
  test('arranca desde un nivel dado y no baja', () {
    expect(nivelEspera(0, desde: 0.5), 0.5);
    expect(nivelEspera(2, desde: 0.5), greaterThan(0.5));
  });
}
```
```dart
// test/nucleo/rutas/guardas_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/nucleo/rutas/rutas.dart';

void main() {
  test('sin sesión todo va a /entrar, salvo /entrar y /arranque', () {
    expect(redirigir(autenticado: false, ruta: '/inicio'), '/entrar');
    expect(redirigir(autenticado: false, ruta: '/vacantes/x/ranking'), '/entrar');
    expect(redirigir(autenticado: false, ruta: '/entrar'), isNull);
    expect(redirigir(autenticado: false, ruta: '/arranque'), isNull);
  });
  test('con sesión, /entrar va a /inicio y lo demás se queda', () {
    expect(redirigir(autenticado: true, ruta: '/entrar'), '/inicio');
    expect(redirigir(autenticado: true, ruta: '/cuenta'), isNull);
  });
}
```
- [ ] **Step 2: Correr y ver fallar.**
- [ ] **Step 3: Implementar**

`lib/funciones/arranque/nivel_espera.dart`:
```dart
import 'dart:math' as math;

const _tope = 0.9;
const _ritmoS = 1.6;

/// El nivel del líquido según la ESPERA real (la curva de la web).
double nivelEspera(double segundos, {double desde = 0}) {
  final base = desde.clamp(0.0, _tope);
  return base + (_tope - base) * (1 - math.exp(-math.max(segundos, 0) / _ritmoS));
}
```

`lib/funciones/arranque/isotipo_liquido.dart`: dos capas de `assets/imagenes/isotipo.png` (la apagada con `ColorFiltered(ColorFilter.mode(tintaTenue, BlendMode.srcIn))`); la de color recortada con `ClipRect(clipper: _Recorte(nivel))` que deja ver desde abajo hasta `nivel` + una ola de 6 px dibujada con `CustomClipper<Path>` (seno con fase que avanza con el ticker). 96 px. Con `vidrioSolido(context)` (reduce movimiento) se pinta llena.

`lib/nucleo/rutas/rutas.dart`:
```dart
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../funciones/acceso/pantalla_entrar.dart';
import '../../funciones/arranque/pantalla_arranque.dart';
import '../../funciones/cascaron/pantalla_cascaron.dart';
import '../../funciones/cuenta/pantalla_cuenta.dart';
import '../../funciones/negocio/candidato/pantalla_candidato.dart';
import '../../funciones/negocio/inicio/pantalla_inicio.dart';
import '../../funciones/negocio/ranking/pantalla_ranking.dart';
import '../../funciones/negocio/vacantes/pantalla_vacante.dart';
import '../../funciones/negocio/vacantes/pantalla_vacantes.dart';
import '../sesion/providers.dart';

String? redirigir({required bool autenticado, required String ruta}) {
  const libres = {'/entrar', '/arranque'};
  if (!autenticado) return libres.contains(ruta) ? null : '/entrar';
  if (ruta == '/entrar') return '/inicio';
  return null;
}

class _Escucha extends ChangeNotifier {
  _Escucha(Stream<bool> s) { _sub = s.listen((_) => notifyListeners()); }
  late final StreamSubscription<bool> _sub;
  @override
  void dispose() { _sub.cancel(); super.dispose(); }
}

final routerProvider = Provider<GoRouter>((ref) {
  final sesion = ref.watch(sesionProvider);
  final escucha = _Escucha(sesion.cambios);
  ref.onDispose(escucha.dispose);
  return GoRouter(
    initialLocation: '/arranque',
    refreshListenable: escucha,
    redirect: (_, estado) => redirigir(autenticado: sesion.autenticado, ruta: estado.matchedLocation),
    routes: [
      GoRoute(path: '/arranque', builder: (_, __) => const PantallaArranque()),
      GoRoute(path: '/entrar', builder: (_, __) => const PantallaEntrar()),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => PantallaCascaron(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/inicio', builder: (_, __) => const PantallaInicio())]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/vacantes', builder: (_, __) => const PantallaVacantes(), routes: [
              GoRoute(path: ':slug', builder: (_, s) => PantallaVacante(slug: s.pathParameters['slug']!), routes: [
                GoRoute(path: 'ranking', builder: (_, s) => PantallaRanking(slug: s.pathParameters['slug']!), routes: [
                  GoRoute(path: ':id', builder: (_, s) => PantallaCandidato(postulacionId: s.pathParameters['id']!)),
                ]),
              ]),
            ]),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: '/cuenta', builder: (_, __) => const PantallaCuenta())]),
        ],
      ),
    ],
  );
});
```
Las pantallas que todavía no existen se crean en esta tarea como `Placeholder` con su nombre, y las tareas 12–18 las reemplazan.

`lib/main.dart`:
```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'app.dart';
import 'nucleo/config.dart';
import 'nucleo/sesion/providers.dart';
import 'nucleo/sesion/sesion_supabase.dart';
import 'nucleo/vidrio/vidrio_nativo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_MX');
  await prepararVidrio();
  final sesion = await SesionSupabase.iniciar();
  final app = ProviderScope(overrides: [sesionProvider.overrideWithValue(sesion)], child: const App());
  if (Config.sentryDsn.isEmpty) return runApp(app);
  await SentryFlutter.init((o) {
    o
      ..dsn = Config.sentryDsn
      ..environment = Config.sabor
      ..sendDefaultPii = false
      ..tracesSampleRate = 0;
  }, appRunner: () => runApp(app));
}
```
`lib/app.dart`: `ConsumerWidget` con `MaterialApp.router(routerConfig: ref.watch(routerProvider), theme: temaClaro(), darkTheme: temaOscuro(), locale: const Locale('es','MX'), supportedLocales: [Locale('es','MX')], localizationsDelegates: GlobalMaterialLocalizations.delegates…, title: 'ReclutaYa')`. Agregar `flutter_localizations` al pubspec (`sdk: flutter`).

- [ ] **Step 4: Verificar** — `flutter test` → todo PASS; `flutter run --dart-define-from-file=defines/prod.json -d iPhone` arranca, muestra el isotipo llenándose y cae en `/entrar` (placeholder). Repetir en Android.
- [ ] **Step 5: Commit (dueño)** — `"Rutas con guardas, cascarón de pestañas y arranque con el isotipo líquido"`

---

### Task 12: Entrar

**Files:**
- Create: `lib/funciones/acceso/pantalla_entrar.dart`, `lib/funciones/acceso/controlador_acceso.dart`
- Test: `test/funciones/acceso/pantalla_entrar_test.dart`

**Interfaces:**
- Produces: `class ControladorAcceso extends AsyncNotifier<void> { Future<void> entrar(String correo, String contrasena); }` (`accesoProvider`); tras `Exito`, pide `yoProvider`; si `tipo == 'candidato'` → `salir()` y estado `error` con `Servidor('Esta versión es para negocios. Pronto llega la de candidatos.')`; si no, `context.go('/inicio')` lo hace la pantalla al ver `autenticado`.
- Enlaces: «¿Olvidaste tu contraseña?» → `launchUrl(Uri.parse('https://app.reclutaya.com/recuperar'))`; «Crear cuenta» → `https://reclutaya.com/crear-cuenta`.

- [ ] **Step 1: Prueba (falla primero)**
```dart
// test/funciones/acceso/pantalla_entrar_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/funciones/acceso/pantalla_entrar.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/sesion/providers.dart';
import 'package:reclutaya_app/nucleo/tema/tema.dart';
import 'package:reclutaya_app/nucleo/util/resultado.dart';
import '../../apoyo/datos.dart';
import '../../apoyo/repositorio_falso.dart';
import '../../apoyo/sesion_falsa.dart';

Widget _app(SesionFalsa s, RepositorioFalso r) => ProviderScope(
  overrides: [sesionProvider.overrideWithValue(s), repositorioProvider.overrideWithValue(r)],
  child: MaterialApp(theme: temaClaro(), home: const PantallaEntrar()),
);

void main() {
  testWidgets('con credenciales malas muestra el texto nuestro', (tester) async {
    final s = SesionFalsa()..entrarR = const Falla(Servidor('Correo o contraseña incorrectos.'));
    await tester.pumpWidget(_app(s, RepositorioFalso()));
    await tester.enterText(find.byKey(const Key('correo')), 'a@b.c');
    await tester.enterText(find.byKey(const Key('contrasena')), 'x');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
  });
  testWidgets('una cuenta de candidato ve el aviso y se cierra su sesión', (tester) async {
    final s = SesionFalsa();
    final r = RepositorioFalso()..yoR = Exito(yoCandidato);
    await tester.pumpWidget(_app(s, r));
    await tester.enterText(find.byKey(const Key('correo')), 'a@b.c');
    await tester.enterText(find.byKey(const Key('contrasena')), 'x');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Esta versión es para negocios'), findsOneWidget);
    expect(s.salidas, 1);
  });
}
```
`test/apoyo/sesion_falsa.dart`: `class SesionFalsa extends Sesion` con `entrarR`, `autenticado` mutable, `salidas` contador, `cambios` desde un `StreamController<bool>.broadcast()`; `renovar` devuelve `'t'`; `token` `'t'`. Agregar `yoCandidato` a `datos.dart`.

- [ ] **Step 2: Correr y ver fallar.**
- [ ] **Step 3: Implementar.** Pantalla: `Scaffold` papel, tarjeta centrada (`Tarjeta`) con logo (asset `isotipo.png` 56 px + «ReclutaYa» en Poppins 800 con la «Ya» en naranja), `Text('Bienvenido de vuelta', headlineSmall)`, dos `TextField` (`Key('correo')`, `Key('contrasena')`, `autofillHints`, teclado de correo, ojo para ver/ocultar), botón principal verde de 50 px «Entrar» (deshabilitado si vacíos; spinner mientras `AsyncLoading`), error en rojo bajo el botón, pie con los dos enlaces. En iOS, campos con `CupertinoTextField`-look vía `adaptativos` (borde continuo). `autofocus` en correo. Teclado: `TextInputAction.next` / `.done` que envía.
- [ ] **Step 4: Verificar** — `flutter test test/funciones/acceso` → PASS; en el simulador, entrar con la cuenta real lleva a `/inicio` (placeholder).
- [ ] **Step 5: Commit (dueño)** — `"Pantalla Entrar con errores traducidos y rechazo de cuentas de candidato"`

---

### Task 13: Inicio

**Files:**
- Create: `lib/funciones/negocio/inicio/pantalla_inicio.dart`, `lib/funciones/negocio/inicio/tarjetas_indicadores.dart`, `lib/funciones/negocio/inicio/tarjeta_saldo.dart`
- Test: `test/funciones/negocio/inicio/pantalla_inicio_test.dart`

- [ ] **Step 1: Prueba (falla primero)**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/inicio.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/funciones/negocio/inicio/pantalla_inicio.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/tema/tema.dart';
import 'package:reclutaya_app/nucleo/util/resultado.dart';
import '../../../apoyo/datos.dart';
import '../../../apoyo/repositorio_falso.dart';

Widget _app(RepositorioFalso r) => ProviderScope(
  overrides: [repositorioProvider.overrideWithValue(r)],
  child: MaterialApp(theme: temaClaro(), home: const PantallaInicio()));

void main() {
  testWidgets('pinta el negocio, los cuatro indicadores y el saldo', (tester) async {
    await tester.pumpWidget(_app(RepositorioFalso()));
    await tester.pumpAndSettle();
    expect(find.text(yoNegocio.empresa!.nombre), findsOneWidget);
    expect(find.text('Velocidad de postulaciones'), findsOneWidget);
    expect(find.text('Cumplen requisitos'), findsOneWidget);
    expect(find.text('Tasa de respuesta'), findsOneWidget);
    expect(find.text('Tiempo a contratación'), findsOneWidget);
    expect(find.text('Contactos disponibles'), findsOneWidget);
  });
  testWidgets('sin requisitos muestra «—» y «Aún no pides requisitos»; sin saldo no hay tarjeta', (tester) async {
    final r = RepositorioFalso()..inicioR = const Exito(Inicio(
      indicadores: Indicadores(velocidad: 1, cumplenPct: null, respuestaPct: 50, tiempoDias: null), saldo: null));
    await tester.pumpWidget(_app(r));
    await tester.pumpAndSettle();
    expect(find.text('Aún no pides requisitos'), findsOneWidget);
    expect(find.text('Aún sin contrataciones'), findsOneWidget);
    expect(find.text('Contactos disponibles'), findsNothing);
  });
  testWidgets('con error muestra Reintentar y vuelve a pedir', (tester) async {
    final r = RepositorioFalso()..inicioR = const Falla(Servidor());
    await tester.pumpWidget(_app(r));
    await tester.pumpAndSettle();
    r.inicioR = Exito(inicioEjemplo);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Velocidad de postulaciones'), findsOneWidget);
  });
}
```
- [ ] **Step 2: Correr y ver fallar.**
- [ ] **Step 3: Implementar.** `PantallaInicio` = `PaginaConTitulo(titulo: 'Inicio', alRefrescar: …)`; encabezado con `LogoNegocio` + nombre + «Hola, {nombre}»; `TarjetasIndicadores` en rejilla 2×2 (`SliverGrid`, cada `Tarjeta` con icono de línea, cifra en Poppins 800 de 28 px, unidad, etiqueta y sub; `delta()` como chip verde/naranja con flecha) con los textos de la web: «Velocidad de postulaciones» (sub «postulaciones por día»), «Cumplen requisitos» (sub «N de M postulaciones» o «Aún no pides requisitos»), «Tasa de respuesta» (sub «de los contactados»), «Tiempo a contratación» (sub «De publicar a contratar» o «Aún sin contrataciones»); `TarjetaSaldo` solo si `saldo != null` (total grande, barra plan/extra verde/naranja, leyenda «N del plan · M adicionales»). Cargando: esqueletos con la misma rejilla. Error: `EstadoError` con `ref.invalidate(inicioProvider)`.
- [ ] **Step 4: Verificar** — `flutter test test/funciones/negocio/inicio` → PASS; en simulador, los números coinciden con el panel web del dueño.
- [ ] **Step 5: Commit (dueño)** — `"Inicio: negocio, cuatro indicadores de 30 días y saldo, con sus cuatro estados"`

---

### Task 14: Vacantes (Activas | Cerradas)

**Files:**
- Create: `lib/funciones/negocio/vacantes/pantalla_vacantes.dart`, `lib/funciones/negocio/vacantes/fila_vacante.dart`
- Test: `test/funciones/negocio/vacantes/pantalla_vacantes_test.dart`

- [ ] **Step 1: Prueba (falla primero)** — con `_app` igual al de Inicio: (a) por defecto lista activas: aparece `vacanteActiva.puesto`, «3 sin rankear» si `sinRankear: 3`, «40 días restantes»; (b) al tocar «Cerradas» aparece `vacanteCerradaEjemplo.puesto` y «Hubo contratación»; (c) lista activa vacía → «Aún no tienes vacantes activas» y «Publícala desde la web»; (d) una fila con `sucursal` pinta su nombre.
- [ ] **Step 2: Correr y ver fallar.**
- [ ] **Step 3: Implementar.** `Segmentado<EstadoLista>({activas: 'Activas', cerradas: 'Cerradas'})` fijo arriba (en iOS dentro de la barra con `CupertinoSliverNavigationBar.bottom`-like: un `SliverPersistentHeader` pinned con el segmentado). `FilaVacante`: `Tarjeta` con puesto (titleLarge), punto de `colorSucursal` + nombre de sucursal, línea de ubicación · sueldo, pie con «N candidatos», `ChipRY('N sin rankear', tono: naranja)` si > 0, y `textoDiasRestantes` / `textoCerrada`. Chevron a la derecha en iOS. `alTocar: () => context.go('/vacantes/${v.slug}')`. Las listas son `SliverList.builder` (sin vidrio dentro).
- [ ] **Step 4: Verificar** — PASS; en simulador, deslizar el ranking después (Task 16) y medir aquí 60 fps al desplazar 50 vacantes.
- [ ] **Step 5: Commit (dueño)** — `"Vacantes activas y cerradas con el segmentado de vidrio y filas como las de la web"`

---

### Task 15: Ficha de vacante

**Files:**
- Create: `lib/funciones/negocio/vacantes/pantalla_vacante.dart`
- Test: `test/funciones/negocio/vacantes/pantalla_vacante_test.dart`

- [ ] **Step 1: Prueba (falla primero)** — (a) pinta puesto, `textoEstadoVacante`, «Ver ranking» habilitado con `conteos.total > 0`; (b) con `total: 0` el botón dice «Aún no hay candidatos» y está deshabilitado; (c) una pregunta con `esRequisito` muestra el chip «Requisito»; (d) `NoEncontrado` → «Esto ya no está disponible» y botón «Volver».
- [ ] **Step 2: Correr y ver fallar.**
- [ ] **Step 3: Implementar.** `PaginaConTitulo(titulo: v.puesto)`; chips de estado; `Tarjeta` «Datos» con filas etiqueta/valor (ubicación, sueldo, turno, sucursal, «Días para responder»); `Tarjeta` «Candidatos» con cuatro `Cifra` (total, en el ranking, sin rankear, cumplen requisitos solo si `pideRequisitos`); descripción (`bodyLarge`, `maxLines` 6 con «Ver más»); `Tarjeta` «Preguntas» con lista numerada y `ChipRY('Requisito', tono: verde)`. Botón principal fijo abajo sobre `Vidrio.pastilla` («Ver ranking» → `context.go('/vacantes/$slug/ranking')`).
- [ ] **Step 4: Verificar** — PASS.
- [ ] **Step 5: Commit (dueño)** — `"Ficha de vacante: datos, conteos, preguntas y el acceso al ranking"`

---

### Task 16: Ranking y la fila del candidato

**Files:**
- Create: `lib/funciones/negocio/ranking/pantalla_ranking.dart`, `lib/funciones/negocio/ranking/fila_candidato.dart`
- Test: `test/funciones/negocio/ranking/fila_candidato_test.dart`, `test/funciones/negocio/ranking/pantalla_ranking_test.dart`

- [ ] **Step 1: Pruebas (fallan primero)**
```dart
// fila_candidato_test.dart (fragmento clave)
testWidgets('sin contactar: primer nombre, apellido difuminado, sin teléfono', (tester) async {
  await tester.pumpWidget(_envuelve(FilaCandidato(fila: rankingEjemplo.visibles[0], alTocar: () {})));
  expect(find.text('Ana'), findsOneWidget);
  expect(find.bySemanticsLabel('Apellido oculto'), findsOneWidget);
  expect(find.textContaining('52'), findsNothing);
  expect(find.text('87 pts'), findsOneWidget);
  expect(find.text('Cumple 3 de 4'), findsOneWidget);
});
testWidgets('contactado con video recibido: chip Recibido y sin «Cumple» si no pide requisitos', (tester) async {
  await tester.pumpWidget(_envuelve(FilaCandidato(fila: rankingEjemplo.visibles[1], alTocar: () {})));
  expect(find.text('Contactado'), findsOneWidget);
  expect(find.text('Recibido'), findsWidgets);
  expect(find.textContaining('Cumple'), findsNothing);
});
testWidgets('contratado muestra su chip', (tester) async { /* visibles[2] → 'Contratado' */ });
```
`pantalla_ranking_test.dart`: (a) pinta las tres filas y una fila bloqueada difuminada («Bloqueado»); (b) `Ranking(visibles: [], bloqueados: [], total: 0)` → «Genera el ranking desde la web»; (c) con error, Reintentar.
- [ ] **Step 2: Correr y ver fallar.**
- [ ] **Step 3: Implementar.** `FilaCandidato` (la `.candRow`): a la izquierda el número de ranking en Poppins 700 gris; nombre (titleMedium) + `ApellidoDifuminado` si `apellidoOculto`; a la derecha la píldora `«{score} pts»` (verde brillo / verde profundo); segunda línea zona · `textoTraslado`; tercera: chips de materiales (video/documento/test con `textoMaterial`, el test «Respondido» si `testEstado == 'RESPONDIDA'`), chips de proceso («Contactado» azul, «No respondió» naranja, «Contratado» verde), `textoCumple` en `labelMedium`, «Vence {fechaCorta}» si `fechaLimite`. `RepaintBoundary` por fila. Bloqueados: misma tarjeta con `Opacity(0.45)` y texto «Bloqueado · {score} pts». `PantallaRanking` = `PaginaConTitulo(titulo: 'Ranking', alRefrescar)` + sub «{total} candidatos, ordenados por qué tan bien encajan» + `SliverList.builder`. Tocar → `context.go('/vacantes/$slug/ranking/${f.postulacionId}')`.
- [ ] **Step 4: Verificar rendimiento (obligatorio):** `flutter run --profile --dart-define-from-file=defines/prod.json -d <iPhone físico o simulador>` sobre una vacante con 30+ candidatos; abrir DevTools → Performance; desplazar 10 s. Expected: sin cuadros rojos, raster < 8 ms (en físico). Anotar dispositivo, fecha y cifras en el README. Si falla el presupuesto por el vidrio nativo de la barra, cambiar esa barra a `VidrioPropio` desde `BarraPestanas` y anotarlo.
- [ ] **Step 5: Commit (dueño)** — `"Ranking enmascarado como lo manda el servidor, con la fila de la web y medición de rendimiento"`

---

### Task 17: Ficha del candidato (video, documento, test, respuestas)

**Files:**
- Create: `lib/funciones/negocio/candidato/pantalla_candidato.dart`, `lib/funciones/negocio/candidato/bloque_video.dart`, `lib/funciones/negocio/candidato/bloque_test.dart`, `lib/funciones/negocio/candidato/controlador_ficha.dart`
- Test: `test/funciones/negocio/candidato/pantalla_candidato_test.dart`, `test/funciones/negocio/candidato/controlador_ficha_test.dart`

**Interfaces:**
- Produces: `class ControladorFicha { int reintentosUrl = 0; bool puedeReintentarUrl(); }` puro: la primera URL firmada que falla invalida `candidatoProvider(id)` una vez; a la segunda, mensaje «El archivo ya no está disponible. Vuelve a abrir la ficha.».

- [ ] **Step 1: Pruebas (fallan primero)**
```dart
// controlador_ficha_test.dart
test('al fallar la URL se invalida la ficha una sola vez', () {
  final c = ControladorFicha();
  expect(c.puedeReintentarUrl(), isTrue);
  expect(c.puedeReintentarUrl(), isFalse);
});
```
`pantalla_candidato_test.dart`: (a) sin contactar: nombre parcial, no hay teléfono, video «Pedido, aún no llega» si `solicitado` y sin `url`; (b) contactada: teléfono visible y «Copiar», bloque de test con «Integridad aceptable» y chip verde (`integridadTono: 'bajo'`), respuestas con «Requisito» y «No cumple» cuando `incumple`; (c) `resultado == null` y `estado == 'ENVIADA'` → «Test enviado, sin responder».
- [ ] **Step 2: Correr y ver fallar.**
- [ ] **Step 3: Implementar.** Página empujada (`PaginaConTitulo(titulo: nombre)`); cabecera con `AvatarIniciales`, puntaje grande, chips de proceso; `Tarjeta` «Datos» (WhatsApp con botón «Copiar» → `Clipboard.setData` + háptico; zona y traslado; experiencia con `experiencia()`; turno; sueldo esperado); `Tarjeta` «Resumen»; `BloqueVideo` (`video_player` + `chewie`, `autoInitialize`, 16:9, miniatura con botón de reproducir; si falla la carga → `ControladorFicha`); `Tarjeta` «Documento» con «Abrir» (`launchUrl(mode: LaunchMode.externalApplication)`; «Pedido, aún no llega» / nada); `BloqueTest` (duración, barras horizontales por rasgo en verde con porcentaje, top 3 como chips, arquetipo, comentarios en lista, chip de integridad con tono bajo=verde / nota=naranja / medio=rojo y «N respuestas marcadas»); «Respuestas» y «Datos adicionales» como listas pregunta/respuesta con chips «Requisito» y «No cumple» (rojo).
- [ ] **Step 4: Verificar** — `flutter test test/funciones/negocio/candidato` → PASS; en simulador, un candidato real contactado reproduce su video y abre su documento.
- [ ] **Step 5: Commit (dueño)** — `"Ficha del candidato: datos, video, documento, resultado del test y respuestas, con URLs firmadas que se renuevan una vez"`

---

### Task 18: Cuenta, íconos de la app, README final y prueba del dueño

**Files:**
- Create: `lib/funciones/cuenta/pantalla_cuenta.dart`, `flutter_launcher_icons.yaml`, `assets/imagenes/icono_1024.png`
- Modify: `README.md`, `lib/funciones/cascaron/pantalla_cascaron.dart` (pestañas definitivas: Inicio `house`, Vacantes `briefcase`, Cuenta `person` con los íconos Cupertino en iOS y Material en Android, decididos en `adaptativos`)
- Test: `test/funciones/cuenta/pantalla_cuenta_test.dart`

- [ ] **Step 1: Prueba (falla primero)** — (a) pinta nombre, `etiquetaRol('owner')` = «Dueño», negocio y «Cerrar sesión»; (b) tocar «Cerrar sesión» y aceptar llama `salir()` una vez (`SesionFalsa.salidas == 1`); cancelar no.
- [ ] **Step 2: Correr y ver fallar.**
- [ ] **Step 3: Implementar.** `PaginaConTitulo(titulo: 'Cuenta')`; `Tarjeta` con `AvatarIniciales(yo.iniciales, tam: 56)`, nombre, rol, negocio; `Tarjeta` con «Términos» y «Aviso de privacidad» (`launchUrl` a `https://reclutaya.com/terminos` y `/privacidad`); botón «Cerrar sesión» (rojo suave) → `confirmar(…destructivo: true)` → `salir()` + `olvidarTodo(ref)`; pie «Versión {package_info} · {Config.sabor}» (agregar `package_info_plus`).
- [ ] **Step 4: Íconos.** Generar `icono_1024.png` desde el isotipo centrado sobre papel (`sips` o un script Dart con `dart:ui`), `flutter_launcher_icons.yaml` con `image_path`, `ios: true`, `android: true`, `adaptive_icon_background: "#f7f7f4"`, `adaptive_icon_foreground: assets/imagenes/isotipo_foreground.png`; `dart run flutter_launcher_icons`.
- [ ] **Step 5: Verificación completa** — `tool/verificar.sh` en verde; `flutter run --dart-define-from-file=defines/prod.json` en el simulador de iPhone 17 (iOS 26.5) y en el emulador Android API 36. Recorrer las seis pantallas con la cuenta del dueño. Modo oscuro en los dos. «Reducir movimiento» en iOS: arranque quieto y barras sólidas.
- [ ] **Step 6: README final.** Secciones: qué es, requisitos (Flutter 3.47.2, Xcode 26, CocoaPods, Android SDK 36), correr, sabores, verificar, estructura (la de la spec §4.1), reglas guardián, resultado de rendimiento con fecha y dispositivo, lo que NO hace la v1 y qué necesita el dueño para Google y tiendas (spec §9).
- [ ] **Step 7: Commit (dueño)** — `"Cuenta con cierre de sesión confirmado, íconos de la app y README con la medición de rendimiento"`

---

## Lista de verificación antes de dar por terminado el paso 2

- [ ] `tool/verificar.sh` en verde y la acción de GitHub en verde en `main`.
- [ ] Las tres pruebas guardián existen y pasan (colores, plataforma, liquid_design).
- [ ] Medición de rendimiento del ranking anotada en el README (dispositivo, fecha, fps, raster).
- [ ] El dueño recorrió las seis pantallas en iPhone y Android con su cuenta real.
- [ ] Ningún archivo `defines/*.json` real está versionado.
- [ ] La spec §3.2 sigue siendo cierta: si alguna pantalla cayó a vidrio propio por rendimiento, está anotado ahí y en el README.
