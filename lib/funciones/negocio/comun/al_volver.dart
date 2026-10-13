import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/nucleo/sesion/providers.dart';
import 'package:reclutaya_app/nucleo/sesion/renovacion_core.dart';

/// Al volver a la app desde el fondo (12-oct). Antes, si la app había estado un rato
/// fuera, a veces no cargaba: la primera petición se iba por una conexión que iOS ya
/// había cerrado, la pantalla se quedaba en error y solo cerrar la app lo arreglaba.
///
/// Al regresar: (1) si la app de verdad se fue al fondo (no solo se tapó un instante
/// con el centro de control), conexiones nuevas; (2) con sesión, si estuvo fuera más
/// de un minuto o si algo se quedó en error, se piden otra vez los datos principales
/// POR DETRÁS: se sigue viendo lo de antes y cambia solo cuando llega lo nuevo. La
/// regla de cuándo vive en `debeRefrescarAlVolver` (con prueba). `App` lo observa.
final alVolverProvider = Provider<void>((ref) {
  DateTime? salio;
  final escucha = AppLifecycleListener(
    onHide: () => salio ??= DateTime.now(),
    onPause: () => salio ??= DateTime.now(),
    onResume: () {
      final ausencia = salio == null ? null : DateTime.now().difference(salio!);
      salio = null;
      if (ausencia == null) return;
      ref.read(clienteApiProvider).reiniciarConexiones();
      if (!ref.read(sesionProvider).autenticado) return;
      final principales = <ProviderBase<AsyncValue<Object?>>>[
        yoProvider,
        inicioProvider,
        novedadesProvider,
        vacantesActivasProvider,
        sucursalesProvider,
      ];
      for (final p in principales) {
        final hayError = ref.read(p).hasError;
        if (debeRefrescarAlVolver(ausencia: ausencia, hayError: hayError)) {
          // Sin `asReload`: se conserva el valor que ya se veía mientras llega el nuevo.
          ref.invalidate(p);
        }
      }
    },
  );
  ref.onDispose(escucha.dispose);
});
