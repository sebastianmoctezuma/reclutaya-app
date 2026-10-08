import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Un aviso corto abajo de la pantalla, desde donde sea (p. ej. «Cambiaste a Grupo
/// Yaqui» al tocar un aviso de otra cuenta). `App` lo muestra.
final mensajeriaProvider = Provider<GlobalKey<ScaffoldMessengerState>>(
  (_) => GlobalKey<ScaffoldMessengerState>(),
);

void mostrarMensaje(Ref ref, String texto) {
  ref.read(mensajeriaProvider).currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(texto), behavior: SnackBarBehavior.floating),
    );
}
