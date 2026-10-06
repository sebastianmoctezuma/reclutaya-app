# ReclutaYa · app

La app de ReclutaYa para iPhone y Android. Paso 2: el lado **negocio**, de **solo lectura**,
contra la API móvil v1 (`reclutaya-web/docs/movil/api-v1.md`). El dueño entra con su cuenta de
siempre y ve su Inicio, sus vacantes, la ficha de cada una, el ranking y la ficha del candidato.
No hace nada: contactar, pedir material y cobrar son la v2.

- Especificación: `docs/superpowers/specs/2026-10-06-app-negocio-v1-design.md`
- Plan: `docs/superpowers/plans/2026-10-06-app-negocio-v1.md`

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

## Verificar antes de subir

```bash
tool/verificar.sh
```

Formato, análisis estricto, pruebas y build de Android. Nada se sube en rojo. La acción de
GitHub corre lo mismo en cada push (el trabajo de iOS avisa pero no bloquea hasta que los
runners traigan el SDK de iOS 26).

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

## Reglas que cuidan tres pruebas guardián

- Ningún widget escribe `Color(0x…)`: los colores viven en `lib/nucleo/tema/tokens.dart`.
- Nadie pregunta `Platform.isIOS` fuera de `lib/nucleo/plataforma/`.
- Nadie importa `liquid_design` fuera de `lib/nucleo/vidrio/`: el vidrio nativo va detrás de `Vidrio`.

## Decisiones que conviene saber

- **Vidrio solo en lo que flota** (barra de pestañas, segmentado, botón flotante, hojas). Nunca en
  filas ni tarjetas: el contenido es sólido. El apellido difuminado del ranking es un degradado,
  no un filtro de desenfoque (cuarenta filas con filtro cuestan un `saveLayer` cada una).
- **Riverpod 3 sin reintentos automáticos** (`sinReintentos`): reintentaría un 500 hasta diez
  veces; los reintentos los decide `ClienteApi` (401 → renovar y repetir una vez; 429 → esperar
  `Retry-After`, tope 30 s, una vez; 5xx y sin red → el usuario reintenta).
- **`analyzer: <14.0.0`** fijado en dev: `build_runner` 2.16 no compila con analyzer 14. Quitar
  el pin cuando build_runner lo alcance. Los `*.g.dart` se versionan.
- **Nada de la API toca el disco.** Caché en memoria, se vacía al cerrar sesión. La sesión vive en
  el almacenamiento seguro del teléfono.

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
