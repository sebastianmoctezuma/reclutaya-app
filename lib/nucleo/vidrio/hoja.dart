import 'package:flutter/material.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/vidrio/vidrio.dart';

/// Una hoja que sube desde abajo, de vidrio (iOS 26: el vidrio real; si no, el propio),
/// flotando con margen como las hojas de iOS 26. El contenido lleva un velo del papel
/// para leerse bien sobre lo que haya detrás.
Future<void> mostrarHojaVidrio(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: Colors.black.withValues(alpha: 0.28),
    builder: (c) {
      final t = c.t;
      final alto = MediaQuery.sizeOf(c).height * 0.86;
      return Padding(
        padding: EdgeInsets.fromLTRB(
          8,
          0,
          8,
          MediaQuery.paddingOf(c).bottom + 8,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: alto),
          child: Vidrio.hoja(
            child: Material(
              color: t.papel.withValues(alpha: t.esOscuro ? 0.55 : 0.62),
              child: builder(c),
            ),
          ),
        ),
      );
    },
  );
}
