# App nativa de ReclutaYa — paso 2: lado negocio, solo lectura

**Fecha:** 6-oct-2026 · **Estado:** aprobado en conversación por el dueño · **Alcance:** la
primera app de iPhone y Android, lado negocio, contra la API móvil v1 (solo lectura).

Documento hermano, en el repo de la web: `docs/superpowers/specs/2026-10-02-api-movil-v1-design.md`
(el diseño de la API) y `docs/movil/api-v1.md` (el contrato que esta app consume).

---

## 1. Qué se construye y para quién

Una app de ReclutaYa en Flutter, repo `sebastianmoctezuma/reclutaya-app`, identificador
`com.reclutaya.app`, nombre visible «ReclutaYa». El dueño de un negocio (o su
administrador o un miembro) entra con la misma cuenta de la web y **ve** lo que ya ve en
su panel: su Inicio con los indicadores de 30 días y el saldo de contactos, sus vacantes
activas y cerradas, la ficha de cada vacante, el ranking de candidatos y la ficha de cada
candidato. **No hace nada**: no contacta, no pide material, no cobra, no publica. Eso es
la v2 de la API, con su propio diseño.

**Decisiones del dueño que fijan este documento:**

- Negocio primero. El lado candidato entra después, por los mismos cimientos.
- Que en iPhone **se sienta como una app escrita en Swift**: vidrio líquido nativo de Apple
  en iOS 26, navegación y gestos de iOS. Con la condición de que **no cueste rendimiento**.
- La **misma interfaz** de la web: paleta, tipografías, tarjetas, la fila del ranking.
- Buenas prácticas, seguridad y escalabilidad desde el primer archivo.

**Fuera de alcance de este paso** (cada uno es su propio diseño después): entrar con
Google (Antonio debe crear las credenciales de iOS y Android en Google Cloud), el lado
candidato, notificaciones push, cualquier escritura (contactar, pedir material), Pagos
(la v1 no tiene rutas de cobro), y la publicación en las tiendas.

**Éxito del paso 2:** la app corre en el simulador de iPhone (iOS 26.5) y en el emulador
de Android (API 36) contra producción, con la cuenta real del dueño, mostrando las seis
pantallas con sus cuatro estados; análisis estático y pruebas en verde; 60 fps estables al
desplazar el ranking en un iPhone de la generación 12 o más nuevo.

---

## 2. Fuente de verdad: el contrato de la API v1

La app **no reimplementa ninguna regla del producto**. Todo lo que muestra llega resuelto
del servidor, que además la enmascara:

- De un candidato no contactado llega solo el primer nombre, `apellidoOculto: true` y
  `whatsapp: null`. La app pinta un bloque difuminado después del nombre, y **nunca**
  intenta deducir un teléfono ni un apellido.
- `requisitosTotal: 0` → no se muestra «Cumple X de Y». `cumplenPct: null` → «—».
- Los estados del proceso (`contactado`, `noRespondio`, `entregaFallo`, `fechaLimite`)
  vienen calculados: la app los traduce a chips, no los calcula.
- Las URLs de video y documento son firmadas y vencen: si una falla, la app vuelve a pedir
  la ficha, no guarda la URL.
- `Cache-Control: private, no-store`: nada de la API se escribe en disco.
- Agregar campos es compatible: los modelos ignoran lo que no conocen. Un campo que falta
  y es obligatorio es un error de parseo que se reporta a Sentry y se muestra como «No
  pudimos leer esta información. Intenta de nuevo.», nunca un crash.

### Errores (tabla del contrato, traducida a comportamiento)

| HTTP | `codigo` | La app |
|---|---|---|
| 401 | `no_autenticado` | Renueva la sesión con Supabase y reintenta **una** vez. Si vuelve 401, cierra la sesión y manda al login con el aviso «Tu sesión terminó. Vuelve a entrar.». |
| 403 | `prohibido` | Esta cuenta no es de negocio: aviso y cierre de sesión (ver §5, Entrar). |
| 404 | `no_encontrado` | Pantalla «Esto ya no está disponible» con botón para volver. |
| 429 | `limite` | Espera `Retry-After` segundos (tope 30) y reintenta sola una vez; si vuelve, «Demasiadas consultas. Espera un momento.». |
| 500 | `interno` | «No se pudo cargar. Intenta de nuevo.» con Reintentar. **Nunca** manda al login. |
| Sin red / tiempo agotado | — | Banner «Sin conexión» y el último dato en memoria si lo hay; Reintentar. |

Toda petición lleva tiempo límite: 10 s para conectar, 20 s para recibir.

---

## 3. Identidad y sensación

### 3.1 Tokens, portados de la web

| Concepto | Valor | De dónde |
|---|---|---|
| Papel (fondo) | `#f7f7f4` | `--bg` |
| Tarjeta | `#ffffff` | `--bg-card` |
| Tinta | `#1f2937` · suave `#52606e` · tenue `#8a96a3` | `--ink*` |
| Verde | `#146a43` · profundo `#0e5234` · brillo `#e8f6ef` · suave `#cfe6d8` | `--green*` |
| Naranja (la «Ya») | `#ff8a00` · profundo `#cc6e00` · brillo `#fff0db` | `--amber*` |
| Azul | `#197cbb` · brillo `#e8f0ff` | `--blue*` |
| Líneas | `#e6e8e4` · fuerte `#ccd3cd` | `--line*` |
| Radios | 14 · 22 | `--radius`, `--radius-lg` |
| Sombras | las tres de la web (`sm`, `md`, `lg`) | `--shadow-*` |
| Tipografías | **Poppins** 500–800 (títulos y cifras) · **Hanken Grotesk** 400–700 (texto) | `app/fonts/` |

Modo oscuro: sigue el sistema, con la paleta oscura que ya tiene el panel (sin verdes
neón). Los tokens viven en UN archivo (`lib/nucleo/tema/tokens.dart`) y el tema de Flutter
se deriva de ahí; ningún widget escribe un color a mano.

Las fuentes se **empaquetan** en la app (`assets/fonts/`, TTF), nunca se descargan: la
misma lección del build de la web.

### 3.2 Vidrio líquido

- **Paquete:** `liquid_design` ^0.4 (hareerapp). En iOS 26+ usa el vidrio real de Apple
  (`UIGlassEffect`) por vistas nativas; en iOS 15–25 y Android no pone vistas nativas.
- **La app nunca llama al paquete directo.** Todo pasa por un componente propio,
  `Vidrio` (`lib/nucleo/vidrio/`), con tres variantes: `Vidrio.barra` (barras de
  navegación y pestañas), `Vidrio.pastilla` (segmentados, botones flotantes) y
  `Vidrio.hoja` (hojas modales). El componente decide: nativo en iOS 26+, desenfoque
  propio (`BackdropFilter` + tinte + borde especular, la receta del dock cápsula de la
  web) en lo demás. Cambiar o quitar el paquete toca ese directorio y nada más. Es la
  salida prevista para cuando Flutter publique su Cupertino de iOS 26.
- **Regla de rendimiento, no negociable:** el vidrio nativo va **solo en lo que flota**:
  barra de pestañas, barra de navegación, segmentado, botones flotantes y hojas. **Nunca
  dentro de una fila de lista** ni en tarjetas de contenido. Las superficies con vidrio en
  una misma pantalla se agrupan (`LiquidGlassGroup`) y nunca se apilan más de dos.
- **Presupuesto medido**, no supuesto: con el ranking de 40 candidatos desplazándose en
  un iPhone 12 o superior, 60 fps estables y raster por cuadro bajo 8 ms (DevTools,
  modo profile). Si el vidrio nativo rompe el presupuesto en alguna pantalla, esa
  pantalla cae al desenfoque propio desde `Vidrio`, y se anota en este documento.
- Con «Reducir movimiento» o «Reducir transparencia» del sistema, `Vidrio` pinta
  superficies sólidas.

### 3.3 Swift por dentro (iPhone) y Material por dentro (Android)

| Aspecto | iPhone | Android |
|---|---|---|
| Navegación | Rutas Cupertino: deslizar desde el borde para regresar, títulos grandes que se encogen al bajar | Material 3, botón atrás predictivo, transición de contenedor |
| Scroll | Física de iOS (rebote), `CupertinoSliverRefreshControl` | Física de Android, `RefreshIndicator` |
| Barra inferior | Pestañas sobre `Vidrio.barra` | Barra de navegación Material 3 con tinte suave |
| Hojas y alertas | `showCupertinoModalPopup` / hojas con `Vidrio.hoja` | Hojas Material 3 |
| Retroalimentación | Hápticos (`HapticFeedback.selectionClick` al cambiar pestaña o segmento) | Igual |
| Tipografía | Poppins/Hanken, tamaños con escala dinámica del sistema | Igual |
| Bordes | Esquinas continuas (`ContinuousRectangleBorder`), como iOS | Esquinas circulares |

La elección por plataforma se centraliza en `lib/nucleo/plataforma/` (`Plataforma.esIOS`
y constructores `adaptativos`); una pantalla nunca pregunta `Platform.isIOS` por su cuenta.

### 3.4 La pantalla de arranque

Al abrir, fondo del color del papel y el **isotipo llenándose como líquido** de abajo
hacia arriba mientras se restaura la sesión y se pide `/yo`: la misma identidad del login
web. Pintado con `CustomPainter` + `ShaderMask` sobre dos capas del isotipo (la apagada y
la de color), una ola de máscara; sin paquetes. Dura lo que dure la espera, con el mismo
ritmo de la web (sube rápido, se frena cerca del 90 %, termina al tener respuesta). Con
«Reducir movimiento», aparece lleno y quieto.

---

## 4. Arquitectura

### 4.1 Estructura por secciones

```
lib/
  main.dart                      arranque: sabor, Sentry, Supabase, ProviderScope, app
  app.dart                       MaterialApp.router (una sola raíz; en iOS las transiciones
                                 y widgets son Cupertino vía `adaptativos`), tema, rutas
  nucleo/
    tema/        tokens.dart, tema.dart (claro/oscuro), tipografia.dart
    vidrio/      vidrio.dart (API propia), vidrio_nativo.dart, vidrio_propio.dart
    plataforma/  plataforma.dart, adaptativos.dart (botón, hoja, refresco, página)
    red/         cliente_api.dart, errores_api.dart, politica_reintento.dart
    sesion/      sesion.dart (Supabase + almacenamiento seguro), sesion_provider.dart
    rutas/       rutas.dart (go_router, guardas)
    ui/          tarjeta, chip, esqueleto, estado_vacio, estado_error, banner_sin_red,
                 avatar_iniciales, apellido_difuminado, cifra
    util/        formato.dart (fechas relativas, números es-MX), resultado.dart
  funciones/
    arranque/    pantalla_arranque.dart (isotipo líquido), controlador_arranque.dart
    acceso/      pantalla_entrar.dart, controlador_acceso.dart
    cuenta/      pantalla_cuenta.dart
    negocio/
      comun/     modelos/yo.dart, repositorio_negocio.dart
      inicio/    modelos/inicio.dart, pantalla_inicio.dart, tarjetas_indicadores.dart
      vacantes/  modelos/vacante_lista.dart, vacante_ficha.dart, pantalla_vacantes.dart,
                 pantalla_vacante.dart
      ranking/   modelos/ranking.dart, pantalla_ranking.dart, fila_candidato.dart
      candidato/ modelos/ficha_candidato.dart, pantalla_candidato.dart, resultado_test.dart
test/            espejo de lib/: unitarias de lógica pura, widget tests con repositorio falso
assets/          fonts/, imagenes/isotipo.png, isotipo_apagado.png
```

Cada sección depende solo de `nucleo` y de `negocio/comun`. El lado candidato, cuando
llegue, es `funciones/candidato/` y una guarda más en rutas. La v2 de escritura agrega
métodos al repositorio y acciones a las pantallas; no cambia modelos ni rutas.

### 4.2 Piezas y dependencias

| Pieza | Elección | Por qué |
|---|---|---|
| Estado | **Riverpod** (`flutter_riverpod`, `riverpod_annotation`) | Compilación segura, sin `BuildContext` en la lógica, probable sin widgets, `AsyncValue` da los cuatro estados gratis. |
| Rutas | **go_router** con rutas tipadas y guardas | Deep links después sin rehacer; la guarda redirige según sesión y tipo. |
| Modelos | **freezed** + **json_serializable** | Inmutables, tolerantes a campos nuevos (`@JsonSerializable(checked: false)`, campos opcionales donde el contrato dice `null`). |
| Sesión | **supabase_flutter** con `flutter_secure_storage` como almacenamiento | La sesión vive en Keychain/Keystore, no en preferencias planas. Supabase renueva el token solo. |
| Red | **dio** con un interceptor propio | Bearer, `X-Api-Version`, política de reintento, errores tipados. |
| Vidrio | **liquid_design** detrás de `Vidrio` | §3.2. |
| Video | **video_player** (+ `chewie` solo si hace falta control completo) | Reproducir la URL firmada dentro de la app. |
| Documento | **url_launcher** (visor del sistema) | Un PDF o imagen firmada se abre en Vista Rápida / el visor de Android. Sin visor propio en la v1. |
| Imágenes | **cached_network_image** solo para logos (públicos) | El logo del negocio sí se puede cachear; las URLs firmadas no pasan por aquí. |
| Errores | **sentry_flutter**, `sendDefaultPii: false` | Igual que la web: solo errores, sin datos personales. |
| Lint | **very_good_analysis** | Reglas estrictas desde el día uno. |

### 4.3 El cliente de red

Un solo `ClienteApi` (dio) construido con la URL base del sabor:

1. Antes de cada petición pone `Authorization: Bearer <access_token>` tomado de la sesión
   actual de Supabase (que ya renueva sola cerca del vencimiento).
2. Toda respuesta se mapea a `Resultado<T>`: `Exito(T)` o `Falla(ErrorApi)`. `ErrorApi` es
   una unión cerrada: `sesionVencida`, `prohibido`, `noEncontrado`, `limite(segundos)`,
   `servidor`, `sinRed`, `respuestaInvalida`.
3. **Política de reintento** (pura, con prueba, `politica_reintento.dart`): 401 → renovar
   sesión y reintentar una vez; 429 → esperar `Retry-After` (tope 30 s) y reintentar una
   vez; 5xx y sin red → no reintentar solo (el usuario tiene Reintentar); 403/404 → nunca.
4. Si `X-Api-Version` llega con un valor distinto de `1`, se reporta a Sentry (aviso) y se
   sigue: agregar campos es compatible.
5. Nunca registra en logs el token ni el cuerpo de las respuestas.

### 4.4 Repositorio y caché en memoria

`RepositorioNegocio` expone un método por ruta del contrato (`yo()`, `inicio()`,
`vacantes(estado)`, `vacante(slug)`, `ranking(slug)`, `candidato(postulacionId)`). Cada
método devuelve `Resultado<T>`. Los providers de Riverpod guardan el último valor en
memoria y, al refrescar, muestran el anterior mientras llega el nuevo (el usuario nunca ve
un parpadeo a esqueletos si ya había datos). Cerrar sesión invalida todos los providers:
no queda nada en memoria. Nada se persiste en disco (`no-store`).

### 4.5 Sesión y guardas

- `Sesion` envuelve a Supabase: `entrar(correo, contraseña)`, `salir()`, `tokenActual`,
  `cambios` (stream). Persistencia en `flutter_secure_storage`.
- Al arrancar: si hay sesión guardada → `/yo`; `tipo: "negocio"` → pestañas;
  `tipo: "candidato"` → aviso «Esta versión es para negocios» + `salir()` → login; sin
  sesión → login.
- Guarda de go_router: sin sesión, cualquier ruta interna redirige a `/entrar`; con sesión,
  `/entrar` redirige a `/inicio`.
- `salir()` limpia Supabase, el almacenamiento seguro y todos los providers.

### 4.6 Sabores y secretos

Dos sabores por `--dart-define-from-file`: `prod` (`https://app.reclutaya.com/api/movil/v1`,
Supabase de producción) y `local` (`http://localhost:3000/api/movil/v1`, misma Supabase:
dev y prod comparten proyecto). Los archivos de define **no se suben**: `.gitignore` los
excluye y el repo trae `defines/prod.example.json`. La llave `anon` de Supabase es pública
por diseño, pero igual viaja por define, no en el código. Ningún secreto de servidor
existe en la app. Identificador `com.reclutaya.app` en los dos sistemas; íconos generados
del isotipo con `flutter_launcher_icons`.

---

## 5. Pantallas y estados

Tres pestañas: **Inicio · Vacantes · Cuenta**. Todas las listas con «deslizar para
actualizar». Todas las pantallas con cuatro estados: **cargando** (esqueletos con la forma
real de la pantalla, sin spinners genéricos), **vacío** (texto en el tono de la web, sin
ilustraciones genéricas), **error** (mensaje + «Reintentar»), **sin conexión** (banner
arriba, dato anterior si lo hay).

**Arranque.** Isotipo líquido (§3.4) mientras se restaura la sesión y llega `/yo`.

**Entrar.** Tarjeta sobre papel con el logo, correo y contraseña (ojo para ver/ocultar),
«Entrar». Errores de Supabase traducidos: credenciales malas → «Correo o contraseña
incorrectos.»; correo sin confirmar → «Tu correo aún no está verificado. Ábrelo desde el
enlace que te mandamos.»; sin red → banner. Al entrar, `/yo`: si es candidato, aviso y
salir. Pie: «¿Olvidaste tu contraseña?» abre la recuperación **web** en el navegador
(`url_launcher` a `https://app.reclutaya.com/recuperar`): la app no reimplementa ese
flujo. «Crear cuenta» abre `https://reclutaya.com/crear-cuenta`.

**Inicio.** Encabezado con el logo (recorte `logoFit` como la web) y el nombre del negocio;
las cuatro tarjetas de indicadores de 30 días (velocidad, cumplen requisitos, respuesta,
tiempo) con su delta en verde/naranja y «—» cuando es `null`; la tarjeta de saldo (plan +
adicionales, con la barra de dos colores de la ficha del admin) solo si `saldo` no es
`null`. Vacío: cuenta sin vacantes → «Publica tu primera vacante desde la web» (la app no
publica).

**Vacantes.** Segmentado Activas | Cerradas (`Vidrio.pastilla` en iOS). Fila: puesto,
sucursal con su punto de color (`colorIdx`, la misma paleta de sucursales de la web),
«N candidatos», chip naranja «N sin rankear» si > 0, «N días restantes» (o «Cerrada el
…», «Hubo contratación», «Se archiva en N días» en cerradas; «Datos purgados» si
`purgada`). Tocar → ficha.

**Ficha de vacante.** Título grande; chips de estado; datos (ubicación, sueldo, turno,
sucursal, días para responder); conteos (total, rankeados, sin rankear, cumplen
requisitos si `pideRequisitos`); descripción; preguntas con marca «Requisito». Botón
principal «Ver ranking» (deshabilitado con `total: 0` y texto «Aún no hay candidatos»).

**Ranking.** Lista ordenada tal como llega. Fila (la `.candRow` de la web): número,
nombre + bloque difuminado si `apellidoOculto`, puntaje en píldora («87 pts»), zona y
«a N min», «Cumple X de Y» solo si `requisitosTotal > 0`, chips de materiales (video,
documento, test) en sus tres estados (pedido / recibido / nada), chips de proceso
(«Contactado», «No respondió», «Contratado»), fecha límite si hay. `bloqueados` como
filas difuminadas sin tocar. Tocar → ficha del candidato. Sin ranking → «Genera el
ranking desde la web».

**Ficha del candidato.** Página completa en iOS (empuje), con: nombre (parcial o completo
según `contactado`), WhatsApp solo si llega (se puede copiar; no se abre WhatsApp: eso es
acción de la v2), zona y traslado, puntaje y resumen, experiencia, turno, sueldo esperado;
video (reproductor en la app si `url`; «Pedido, aún no llega» si `solicitado` sin
`recibido`); documento («Abrir» con el visor del sistema); test (`resultado` con barras
de rasgos, top 3, arquetipo, comentarios e integridad con su tono: bajo = verde, nota =
ámbar, medio = rojo); respuestas y extras con marca de requisito e incumplimiento. Si una
URL firmada falla al abrir, la pantalla vuelve a pedir la ficha una vez.

**Cuenta.** Avatar con iniciales, nombre, rol (traducido: dueño / administrador /
miembro), negocio, «Cerrar sesión» (confirmación nativa), versión y sabor. Enlaces a
Términos y Aviso de privacidad (web).

---

## 6. Seguridad

- Sesión en Keychain / Keystore; nunca en preferencias planas ni en logs.
- Nada de la API en disco. Caché solo en memoria y solo mientras hay sesión.
- La app confía en el enmascarado del servidor y no deriva nada: no compone teléfonos,
  no revela apellidos, no guarda URLs firmadas.
- Tiempo límite en toda petición; ningún `await` sin tope.
- Sentry sin PII; los errores de parseo se reportan con la ruta y el campo, nunca con el
  cuerpo.
- Sin deep links ni esquemas propios en la v1 (menos superficie).
- Sin permisos del sistema: no cámara, no ubicación, no contactos. El reproductor de video
  no pide ninguno.
- Dependencias fijadas con `pubspec.lock` versionado; `flutter pub outdated` en cada
  revisión.

---

## 7. Pruebas y verificación

- **Unitarias (lógica pura):** parseo tolerante de cada modelo (campos extra, `null`
  donde el contrato lo permite, campo obligatorio ausente → `respuestaInvalida`), mapa de
  errores HTTP → `ErrorApi`, política de reintento, formato de fechas y números es-MX,
  reglas de presentación («Cumple X de Y» solo con total > 0, delta en verde/naranja,
  textos de cerradas, traducción de rol).
- **Widget tests:** cada pantalla en sus cuatro estados con un `RepositorioNegocio` falso;
  la fila del ranking enmascarada y contactada; el login con cada error.
- **Guardián:** una prueba falla si algún archivo fuera de `lib/nucleo/vidrio/` importa
  `liquid_design`, y otra si alguno fuera de `lib/nucleo/plataforma/` usa `Platform.isIOS`
  o `defaultTargetPlatform`.
- **Rendimiento:** sesión de DevTools en modo profile sobre el ranking; el resultado se
  anota en el README con fecha y dispositivo.
- **CI:** acción de GitHub en cada push: `flutter analyze`, `flutter test`, `flutter build
  ios --no-codesign` y `flutter build apk --debug`. Regla de la casa, igual que la web:
  nada se sube en rojo.
- **Prueba manual del dueño** al final: las seis pantallas con su cuenta en el simulador
  de iPhone y en el emulador de Android.

---

## 8. Riesgos y salidas

| Riesgo | Mitigación |
|---|---|
| `liquid_design` es joven (0.4.1, pocos usuarios). | Aislado en `Vidrio`; el desenfoque propio ya existe como respaldo; la prueba guardián impide que se cuele fuera. |
| Las vistas nativas cuestan en listas. | Prohibidas en filas y tarjetas; presupuesto medido antes de dar por bueno el paso. |
| Flutter publica su Cupertino iOS 26 a fin de 2026. | Migrar es cambiar `vidrio_nativo.dart`. |
| Dev y prod comparten Supabase. | La app solo lee; el sabor `local` apunta al servidor local pero a la misma base, igual que la web. |
| Un cambio en la API rompe la app. | El contrato dice que solo se agregan campos; los modelos son tolerantes; cualquier cambio de significado es v2 con ruta nueva. |

---

## 9. Lo que debe hacer el dueño antes de las siguientes etapas

- **Google en la app** (etapa aparte): crear en Google Cloud dos credenciales OAuth, una
  de tipo iOS (`com.reclutaya.app`) y una de Android (con la huella SHA-1 del certificado
  de firma, que se le entregará); después se dan de alta en Supabase.
- **Tiendas** (etapa aparte): las cuentas de Apple Developer y Google Play ya existen; se
  necesitarán el certificado de distribución de Apple y la llave de firma de Android.
