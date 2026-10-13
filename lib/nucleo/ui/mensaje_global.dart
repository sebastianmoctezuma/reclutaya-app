import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Un aviso corto abajo de la pantalla, desde donde sea (p. ej. «Cambiaste a Grupo
/// Yaqui» al tocar un aviso de otra cuenta). `App` lo muestra.
final mensajeriaProvider = Provider<GlobalKey<ScaffoldMessengerState>>(
  (_) => GlobalKey<ScaffoldMessengerState>(),
);

void mostrarMensaje(Ref ref, String texto) =>
    mostrarMensajeEn(ref.read(mensajeriaProvider), texto);

/// Lo mismo con la llave del mensajero en la mano (desde un widget, con `WidgetRef`).
void mostrarMensajeEn(GlobalKey<ScaffoldMessengerState> llave, String texto) {
  llave.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(texto), behavior: SnackBarBehavior.floating),
    );
}
