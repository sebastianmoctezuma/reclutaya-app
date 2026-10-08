# Varias cuentas en el mismo teléfono (multicuenta) — diseño

**Fecha:** 7-oct-2026 · **Estado:** implementado el 8-oct (app + servidor), por probar
en un iPhone real.

**Cómo quedó implementado:** núcleo puro `lib/nucleo/sesion/cuentas_core.dart`; el
gestor `lib/funciones/cuentas/gestor_cuentas.dart` (operaciones EN FILA: los tokens de
Supabase rotan en cada uso); la hoja `selector_cuentas.dart`. Cambiar usa
`Sesion.usarCuenta` (setSession) sin cerrar la anterior; las inactivas se renuevan por
REST (`renovarAparte`) sin tocar la activa. La pulsación larga en «Cuenta» solo existe en
la barra propia: el vidrio nativo de iOS 26 no la reporta a Flutter; ahí la puerta es
tocar el negocio en Cuenta. El punto naranja de novedades por cuenta en la hoja quedó
fuera.

## Qué es

Como Instagram en iOS: varias cuentas de negocio en la misma app, se cambia con un toque
sin volver a escribir contraseña, y llegan los avisos de **todas** las cuentas mientras
sigan con sesión.

## Decisiones del dueño (7-oct)

1. **Hasta 5 cuentas** por teléfono.
2. **Avisos de todas las cuentas por defecto**, con el interruptor de avisos **por
   cuenta** (en Cuenta, el de hoy pasa a ser de la cuenta activa).
3. **Tocar un aviso de otra cuenta cambia sola a esa cuenta** y muestra un aviso chico:
   «Cambiaste a Grupo Yaqui».
4. **Selector tipo Instagram en iOS**:
   - **Dejar presionado el botón «Cuenta» del dock** abre la hoja de cuentas (como
     mantener presionada la foto de perfil en Instagram), con háptico.
   - **Tocar el nombre del negocio** arriba en Cuenta (con un ⌄ junto) abre la misma hoja.
   - La hoja: cada cuenta con su logo, nombre del negocio y correo; palomita en la
     activa; punto naranja si tiene novedades sin ver; al final «Agregar cuenta».
     Cambiar = un toque; háptico de selección.

## Cómo funciona

### Sesiones guardadas (app)

- Supabase maneja **una** sesión activa. Por cada cuenta se guarda en el llavero
  (`AlmacenLlavero`, Keychain) su refresh token, cifrado, más lo que pinta la hoja (id
  del usuario, negocio, logo, correo). Nunca contraseñas.
- **Cambiar** = `setSession(refreshToken)` de la elegida, guardar el refresh token
  nuevo que devuelve (Supabase los rota en cada uso) y limpiar la memoria con la MISMA
  limpieza de hoy (`limpiezaSesionProvider`: providers invalidados, «visto hasta» de
  la campana por cuenta).
- **Agregar cuenta** = el login de siempre, sin tirar las demás. Si ya hay 5: «Quita una
  cuenta para agregar otra». La misma cuenta dos veces no se duplica: se actualiza.
- **Al abrir la app**: por cada cuenta inactiva se renueva su sesión por REST (sin
  cambiar la activa) y se reconfirma su registro de avisos. Si una cuenta ya no renueva
  (cambió contraseña, la borraron, la sacaron del equipo), sale de la lista con aviso:
  «La sesión de Grupo Yaqui terminó. Vuelve a entrar.».

### Avisos de todas las cuentas (servidor)

- **Migración**: `dispositivos_push` deja de ser único por token → único por
  `(token, usuario_id)`. El mismo teléfono queda registrado con cada cuenta.
- Columna `confirmado_at`: la app la renueva al abrir (por cada cuenta). El servidor
  **solo manda a registros confirmados en los últimos 30 días** y un cron borra los
  más viejos: una cuenta perdida no sigue avisando para siempre.
- Cada aviso lleva en `data` el **id del usuario** destinatario y el **título con el
  negocio** («Grupo Yaqui · Nuevo candidato»; regla de Controlify: el sistema operativo
  recorta, el negocio va primero). Con una sola cuenta el título queda como hoy.
- API v2 `/dispositivos`: POST registra/reconfirma (token + usuario de la sesión),
  PATCH el interruptor de esa cuenta, DELETE da de baja solo ese par. Sigue siendo la
  única escritura de la app (guardián `v2-acotada`).

### Tocar un aviso

- Si el `usuarioId` del aviso es la cuenta activa: abre lo de siempre.
- Si es otra cuenta guardada: cambia a ella, muestra «Cambiaste a …» y abre.
- Si no está en el teléfono (se quitó): abre Inicio de la activa, sin error.
- `rutaDeAviso` sigue validando slug y postulación; se valida también el `usuarioId`.

### Salir (cambia la salida única de hoy)

- Cuenta tendrá **«Quitar esta cuenta del teléfono»** y, con 2+ cuentas, **«Cerrar
  todas las sesiones»**.
- Quitar una: DELETE de su par (con su sesión válida, tiempo límite 4 s) → borrar su
  refresh token del llavero → si quedan otras, cambiar a la siguiente; si era la
  última, el flujo de hoy (Entrar).
- **Borrar el token de Firebase del teléfono (`olvidarToken`) solo cuando sale la
  ÚLTIMA cuenta**; si se borrara antes, las demás se quedarían sin avisos.
- Sesión vencida de una cuenta: sale de la lista; su registro muere solo por
  `confirmado_at` (30 días) o cuando FCM rechace el token.
- `cerrarSesionProvider` sigue siendo la única salida (la prueba guardián se queda);
  cambia lo que hace por dentro.

## Privacidad

- En la pantalla bloqueada salen avisos de todas las cuentas: nombres siempre parciales
  (ya es así), nunca teléfonos.
- El refresh token de cada cuenta solo vive en el Keychain; quitar la cuenta lo borra.

## Pruebas

- Pura: la lista de cuentas (agregar, tope de 5, no duplicar, quitar, orden, cuál
  sigue al quitar la activa), decidir qué hacer al tocar un aviso (activa / otra /
  desconocida).
- Controlador: cambiar limpia memoria y no mezcla datos (la prueba de hoy del cambio
  de cuenta se extiende), quitar la última olvida el token, quitar una no.
- Servidor: único por `(token, usuario)`, solo confirmados ≤30 días, el título con el
  negocio, guardián v2 intacto.
- iPhone real: dos cuentas, avisos de ambas con la app cerrada, tocar el de la
  inactiva cambia y abre.

## Fuera de alcance

- Android (la app de Android aún no arranca).
- Multicuenta en la web.
- Cuentas de candidato.
