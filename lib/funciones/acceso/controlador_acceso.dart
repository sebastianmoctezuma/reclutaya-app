import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reclutaya_app/funciones/cuentas/gestor_cuentas.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/funciones/negocio/novedades/controlador_avisos.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/sesion/acceso_social.dart';
import 'package:reclutaya_app/nucleo/sesion/acceso_social_core.dart';
import 'package:reclutaya_app/nucleo/sesion/providers.dart';
import 'package:reclutaya_app/nucleo/ui/mensaje_global.dart';
import 'package:reclutaya_app/nucleo/util/resultado.dart';

const avisoSoloNegocios =
    'Esta versión es para negocios. Pronto llega la de candidatos.';

/// Entrar con correo y contraseña, o con Google o Apple (8-oct). La app es SOLO para
/// entrar: no crea cuentas. Tras entrar pide `/yo`: si la cuenta es de candidato,
/// cierra la sesión y lo dice; si no, la guarda de rutas lleva al Inicio sola.
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
    final r = await ref.read(sesionProvider).entrar(correo, contrasena);
    if (r case Falla(:final error)) {
      state = AsyncError(error, StackTrace.current);
      return;
    }
    await _trasEntrar();
  }

  /// Google o Apple. La hoja nativa se abre ANTES del spinner: si la persona cancela,
  /// la pantalla queda exactamente como estaba (también en «Agregar cuenta»).
  Future<void> entrarCon(ProveedorSocial proveedor) async {
    ref.read(avisoAccesoProvider.notifier).aviso = null;
    final CredencialSocial? c;
    try {
      c = await ref.read(accesoSocialProvider).obtener(proveedor);
    } on ErrorApi catch (e) {
      state = AsyncError(e, StackTrace.current);
      return;
    }
    if (c == null) return; // Canceló: no es un error.
    state = const AsyncLoading();
    final enCurso = ref.read(accesoSocialEnCursoProvider.notifier)
      ..valor = true;
    try {
      final r = await ref
          .read(sesionProvider)
          .entrarConToken(
            proveedor: c.proveedor,
            idToken: c.idToken,
            nonce: c.nonce,
          );
      if (r case Falla(:final error)) {
        state = AsyncError(error, StackTrace.current);
        return;
      }
      // ¿Ese correo tiene cuenta? Si no, el servidor borró el acceso recién creado
      // (para que no bloquee el correo) y aquí se suelta la sesión.
      final sinCuenta = await ref.read(repositorioProvider).accesoSinCuenta();
      if (sinCuenta case Exito(valor: true)) {
        await _soltarSesionNueva(huerfana: true);
        state = AsyncError(
          Servidor(mensajeSinCuenta(proveedor)),
          StackTrace.current,
        );
        return;
      }
      await _trasEntrar(registrarAvisos: true);
    } finally {
      if (ref.mounted) enCurso.valor = false;
    }
  }

  /// Lo que pasa después de abrir la sesión, igual para las tres puertas.
  Future<void> _trasEntrar({bool registrarAvisos = false}) async {
    final gestor = ref.read(gestorCuentasProvider.notifier);
    final agregando = ref.read(agregandoCuentaProvider);
    final yo = await ref.read(repositorioProvider).yo();
    if (yo case Exito(:final valor) when !valor.esNegocio) {
      await _soltarSesionNueva(huerfana: false);
      state = AsyncError(const Servidor(avisoSoloNegocios), StackTrace.current);
      return;
    }
    if (yo case Exito(:final valor)) {
      await gestor.recordarActiva(valor);
      if (agregando) {
        // La cuenta agregada queda como la activa: nada de la anterior en memoria.
        limpiarDatosDeCuenta(ref);
        ref.invalidate(controladorAvisosProvider);
        unawaited(ref.read(controladorAvisosProvider.notifier).alEntrar());
        mostrarMensaje(
          ref,
          'Cambiaste a ${valor.empresa?.nombre ?? 'tu cuenta'}',
        );
      } else if (registrarAvisos) {
        // Con Google o Apple, el registro del teléfono esperó a saber que hay negocio.
        unawaited(ref.read(controladorAvisosProvider.notifier).alEntrar());
      }
    }
    state = const AsyncData(null);
  }

  /// La sesión que se acaba de abrir no sirve. Si se estaba agregando una cuenta, se
  /// regresa a la que estaba. Si no: la de un candidato se cierra completa; la huérfana
  /// (su usuario ya no existe en el servidor) solo se tira en el teléfono — cerrarla
  /// «completa» intentaría dar de baja un teléfono con un usuario borrado.
  Future<void> _soltarSesionNueva({required bool huerfana}) async {
    if (ref.read(agregandoCuentaProvider)) {
      await ref
          .read(gestorCuentasProvider.notifier)
          .cancelarAgregar(sesionNueva: true);
    } else if (huerfana) {
      await ref.read(soltarSesionHuerfanaProvider)();
    } else {
      await ref.read(cerrarSesionProvider)();
    }
  }
}

final accesoProvider = AsyncNotifierProvider<ControladorAcceso, void>(
  ControladorAcceso.new,
);
