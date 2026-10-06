import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/sesion/providers.dart';
import 'package:reclutaya_app/nucleo/util/resultado.dart';

const avisoSoloNegocios =
    'Esta versión es para negocios. Pronto llega la de candidatos.';

/// Entrar con correo y contraseña. Tras entrar pide `/yo`: si la cuenta es de
/// candidato, cierra la sesión y lo dice; si no, la guarda de rutas lleva al
/// Inicio sola (escucha los cambios de sesión).
class ControladorAcceso extends AsyncNotifier<void> {
  // Síncrono a propósito: con `async` el estado inicial sería «cargando» y el
  // botón nacería con spinner.
  @override
  FutureOr<void> build() {}

  Future<void> entrar(String correo, String contrasena) async {
    // El aviso anterior (sesión vencida, cuenta de candidato) se consume al
    // intentar de nuevo: no se queda para la siguiente persona.
    ref.read(avisoAccesoProvider.notifier).aviso = null;
    state = const AsyncLoading();
    final sesion = ref.read(sesionProvider);
    final r = await sesion.entrar(correo, contrasena);
    if (r case Falla(:final error)) {
      state = AsyncError(error, StackTrace.current);
      return;
    }
    final yo = await ref.read(repositorioProvider).yo();
    if (yo case Exito(:final valor) when !valor.esNegocio) {
      await sesion.salir();
      state = AsyncError(const Servidor(avisoSoloNegocios), StackTrace.current);
      return;
    }
    state = const AsyncData(null);
  }
}

final accesoProvider = AsyncNotifierProvider<ControladorAcceso, void>(
  ControladorAcceso.new,
);
