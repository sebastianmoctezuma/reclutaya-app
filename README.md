# ReclutaYa · app

La app de ReclutaYa para iPhone y Android. Paso 2: el lado **negocio**, de **solo lectura**,
contra la API móvil v1 (`reclutaya-web/docs/movil/api-v1.md`). El dueño entra con su cuenta de
siempre y ve su Inicio, sus vacantes, la ficha de cada una, el ranking y la ficha del candidato.
No hace nada: contactar, pedir material y cobrar son la v2.

- Especificación: `docs/superpowers/specs/2026-10-06-app-negocio-v1-design.md`
- Plan: `docs/superpowers/plans/2026-10-06-app-negocio-v1.md`
- Avisos al celular (7-oct): `reclutaya-web/docs/superpowers/specs/2026-10-07-notificaciones-push-design.md`
- Varias cuentas en el mismo teléfono (8-oct, hasta 5, como Instagram): `docs/superpowers/specs/2026-10-07-multicuenta-design.md`

La única escritura de la app es registrar su teléfono para avisos (API v2,
`/api/movil/v2/dispositivos`). Todo lo demás es de pura consulta.

## Requisitos

Flutter 3.47.2 (stable), Xcode 26 con el SDK de iOS 26 (lo exige el vidrio nativo), CocoaPods
(instalado; Flutter 3.47 integra iOS por Swift Package Manager, pero algunos plugins lo piden),
Android SDK 36 con Android Studio.

## Correr

```bash
cp defines/prod.example.json defines/prod.json   # y pon las llaves reales (no se versiona)
flutter run --dart-define-from-file=defines/prod.json -d <iPhone|android>
```

Sabores: `defines/prod.json` (producción) y `defines/local.json` (`http://localhost:3000`,
misma Supabase: desarrollo y producción comparten proyecto). La llave de Supabase es la
`sb_publishable_…` del proyecto; la define se sigue llamando `SUPABASE_ANON_KEY`.

Avisos al celular: los `FIREBASE_*` de la app de iOS registrada en el proyecto de Firebase
«Reclutaya» (públicos; salen del `GoogleService-Info.plist`, que NO se usa: la app los lee
de las defines). Sin ellos la app funciona igual, sin avisos. Android aún sin registrar
(`FIREBASE_APP_ID_ANDROID` vacío). Los avisos solo llegan en un iPhone real; el simulador
no los recibe.

## Verificar antes de subir

```bash
tool/verificar.sh
```

Formato, análisis estricto, pruebas y build de Android. Nada se sube en rojo. La acción de
GitHub corre lo mismo en cada push (el trabajo de iOS avisa pero no bloquea hasta que los
runners traigan el SDK de iOS 26).

## Subir a TestFlight

Firma: equipo de Apple `4XCU67J8TF` (cuenta de Antonio), bundle `com.reclutaya.app`, firma
automática. El archivo de permisos dice `aps-environment = development`; al exportar para
la tienda, Xcode lo cambia solo a producción. `Info.plist` declara el cifrado como exento
(`ITSAppUsesNonExemptEncryption = false`), así App Store Connect no lo pregunta en cada
build. Una sola vez: crear la app en App Store Connect (bundle `com.reclutaya.app`) y
tener en Xcode una cuenta con permiso de certificados del equipo.

```bash
tool/verificar.sh
flutter build ipa --release --dart-define-from-file=defines/prod.json --build-number=<N>
```

Sube `build/ios/ipa/*.ipa` con Transporter (o abre `build/ios/archive/Runner.xcarchive` en
Xcode → Distribute App). `<N>` debe subir en cada envío. Versión visible: `version` en
`pubspec.yaml`.

**Estado (8-oct-2026):** la compilación **1.0.0 (5)** está en TestFlight con el grupo
interno «Reclutaya app» (5 testers: Antonio con sus dos correos, Job, Sergio y
Sebastián). La siguiente entrega va con `--build-number=6` o más (Apple rechaza uno
repetido). Lo que trae la 5, además de varias cuentas y avisos:

- **Tarjetas sólidas** con la superelipse de iOS (`RoundedSuperellipseBorder`; la
  `ContinuousRectangleBorder` abombaba los lados) y sin desenfoque por tarjeta.
- **Botón redondo blanco** (`BotonRedondo`) para la campana y la cruz de cerrar.
- **Actividad** con la transición de zoom de iOS 18 (`paginaZoom`): nace de la campana y
  vuelve a ella. Se abre con `go`, no `push` (con `push` se apilaba otro Inicio).
- **Dock** que se encoge al 82 % al bajar (escala, no cambio de tamaño: la barra nativa
  es una vista de iOS incrustada) y se decide en cada movimiento, no solo al cambiar de
  dirección. Con VoiceOver no se compacta.
- **«Revisar candidatos»** como botón teñido con chevron; el **logo del negocio** en la
  pestaña Cuenta; el **logo real** de la web (`logo_claro.png` / `logo_oscuro.png`) en el
  login y abajo en Cuenta (`MarcaReclutaYa`).
- **Sucursal del Inicio** abre Sucursales con su hoja abierta (`/vacantes?sucursal=`);
  filtro de sucursal en hoja sólida; los miembros con un solo estilo en todas.
- **Carga:** `/yo` una sola vez al abrir con el Inicio y la campana en paralelo
  (`yoAlArrancar`); vacante, ranking y candidato se quedan 5 min en memoria
  (`conservarFichaProvider`) y se actualizan solos al volver (`RevalidarAlEntrar`); el
  ranking sale junto con la ficha. En desarrollo, cada petición deja en el log su ruta y
  su tiempo (nunca el token ni los datos).

**Ícono:** sale de `assets/imagenes/icono_1024.png` (iOS, sin transparencia: iOS pone sus
propias esquinas) e `icono_frontal.png` (primer plano del ícono adaptable de Android) con
`dart run flutter_launcher_icons`; la configuración vive en `flutter_launcher_icons.yaml`.

## Estructura

```
lib/
  main.dart · app.dart
  nucleo/        tema (tokens, tipografía), vidrio (liquid_design detrás de `Vidrio`),
                 plataforma (adaptativos iOS/Android), red (ClienteApi, errores, reintento),
                 sesion (Supabase en Keychain/Keystore), rutas, ui (tarjeta, chip, estados…)
  funciones/     arranque (isotipo líquido), acceso (Entrar), cascaron (pestañas), cuenta,
                 negocio/{comun, inicio, vacantes, ranking, candidato}
test/            espejo de lib/ + apoyo/ (datos, repositorio falso, sesión falsa)
```

## Reglas que cuidan cuatro pruebas guardián

- Ningún widget escribe `Color(0x…)`: los colores viven en `lib/nucleo/tema/tokens.dart`.
- Nadie pregunta `Platform.isIOS` fuera de `lib/nucleo/plataforma/`.
- Nadie importa `liquid_design` fuera de `lib/nucleo/vidrio/`: el vidrio nativo va detrás de `Vidrio`.
- Nadie llama `sesion.salir()` fuera de la salida única (`cerrarSesionProvider`): primero
  da de baja el teléfono en el servidor, luego borra su token y al final cierra la sesión.

## Decisiones que conviene saber

- **Vidrio solo en lo que flota** (barra de pestañas, segmentado, botón flotante, hojas). Nunca en
  filas ni tarjetas: el contenido es sólido. El apellido difuminado del ranking es un degradado,
  no un filtro de desenfoque (cuarenta filas con filtro cuestan un `saveLayer` cada una).
- **Riverpod 3 sin reintentos automáticos** (`sinReintentos`): reintentaría un 500 hasta diez
  veces; los reintentos los decide `ClienteApi` (401 → renovar y repetir una vez; 429 → esperar
  `Retry-After`, tope 30 s, una vez; 5xx y sin red → el usuario reintenta).
- **`analyzer: <14.0.0`** fijado en dev: `build_runner` 2.16 no compila con analyzer 14. Quitar
  el pin cuando build_runner lo alcance. Los `*.g.dart` se versionan.
- **Nada de la API toca el disco.** Caché en memoria, se vacía al cerrar sesión **y al entrar con
  otra cuenta** (`limpiezaSesionProvider`). La sesión vive en el almacenamiento seguro del
  teléfono; lo poco que se guarda (interruptor de avisos, «visto hasta» de la campana) va por
  `AlmacenLocal`.
- **Avisos:** Firebase va detrás de `ServicioAvisos` (las pruebas usan uno falso). En iPhone se
  espera el token de APNs hasta 5 s (`esperarValor`). Al perder la sesión por cualquier camino
  el teléfono borra su token (`olvidarToken`): ningún aviso de la cuenta anterior llega.
- **Nada se redibuja dentro de un aviso de desplazamiento:** el fondo verde se pinta con un
  `CustomPainter` atado al desplazamiento y el dock se esconde en el cuadro siguiente. Un
  `setState` ahí congelaba la barra y dejaba el fondo fijo.

## Rendimiento

Pendiente de medir con la cuenta del dueño sobre un ranking de 30+ candidatos, en modo profile:

```bash
flutter run --profile --dart-define-from-file=defines/prod.json -d <iPhone>
```

Meta (spec §3.2): 60 fps estables y raster < 8 ms al desplazar el ranking. Anotar aquí dispositivo,
fecha y cifras. Si el vidrio nativo de la barra rompe el presupuesto, `BarraPestanas` cae a
`VidrioPropio` y se anota.

## Lo que NO hace la v1 y qué falta del dueño

- Entrar con Google: Antonio debe crear en Google Cloud dos credenciales OAuth (iOS con
  `com.reclutaya.app`; Android con la huella SHA-1 del certificado de firma) y se dan de alta en
  Supabase.
- Lado candidato, notificaciones, acciones (contactar, pedir material): v2.
- Tiendas: certificado de distribución de Apple y llave de firma de Android (las cuentas ya existen).
