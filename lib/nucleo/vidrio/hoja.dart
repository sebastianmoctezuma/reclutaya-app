import 'package:flutter/material.dart';
import 'package:reclutaya_app/nucleo/plataforma/adaptativos.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';

/// Una hoja que sube desde abajo, como las de iOS: a todo lo ancho, alta (llega
/// cerca de arriba), con las esquinas de arriba redondas y el tirador. Superficie
/// sólida: el vidrio en una hoja grande dejaba bordes raros.
Future<void> mostrarHojaVidrio(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final t = context.t;
  return showModalBottomSheet<void>(
    context: context,
    // Desde el navegador raíz: la hoja cubre también la barra de pestañas.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    // Fondo con el tinte verde de la app: lo de adentro va en tarjetas blancas.
    backgroundColor: colorFondo(t),
    elevation: 0,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (c) {
      final alto = MediaQuery.sizeOf(c).height;
      return ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: alto * 0.62,
          maxHeight: alto * 0.92,
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(c).bottom),
          child: builder(c),
        ),
      );
    },
  );
}
