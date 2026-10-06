import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reclutaya_app/nucleo/plataforma/plataforma.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';

/// Esquinas continuas en iOS (como las de Apple), circulares en Android.
ShapeBorder formaTarjeta(double r) => Plataforma.esIOS
    ? ContinuousRectangleBorder(borderRadius: BorderRadius.circular(r * 2.2))
    : RoundedRectangleBorder(borderRadius: BorderRadius.circular(r));

void hapticoSeleccion() => HapticFeedback.selectionClick();
void hapticoLigero() => HapticFeedback.lightImpact();

/// Página con título: grande y que se encoge al bajar (iOS),
/// `SliverAppBar.large` (Android). Con `alRefrescar`, deslizar para actualizar.
class PaginaConTitulo extends StatelessWidget {
  const PaginaConTitulo({
    required this.titulo,
    required this.slivers,
    this.accion,
    this.alRefrescar,
    super.key,
  });

  final String titulo;
  final List<Widget> slivers;
  final Widget? accion;
  final Future<void> Function()? alRefrescar;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final cuerpo = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (Plataforma.esIOS)
          CupertinoSliverNavigationBar(
            largeTitle: Text(
              titulo,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            backgroundColor: t.papel.withValues(alpha: 0.85),
            border: null,
            trailing: accion,
            stretch: true,
          )
        else
          SliverAppBar.large(
            title: Text(titulo),
            actions: [?accion],
            backgroundColor: t.papel,
          ),
        if (Plataforma.esIOS && alRefrescar != null)
          CupertinoSliverRefreshControl(onRefresh: alRefrescar),
        ...slivers,
        // Con `extendBody`, el padding inferior incluye la barra de pestañas.
        SliverPadding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom + 24,
          ),
        ),
      ],
    );
    if (!Plataforma.esIOS && alRefrescar != null) {
      return RefreshIndicator.adaptive(onRefresh: alRefrescar!, child: cuerpo);
    }
    return cuerpo;
  }
}

/// Confirmación nativa. Devuelve true si aceptó.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  required String aceptar,
  bool destructivo = false,
}) async {
  if (Plataforma.esIOS) {
    final r = await showCupertinoDialog<bool>(
      context: context,
      builder: (c) => CupertinoAlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: destructivo,
            onPressed: () => Navigator.pop(c, true),
            child: Text(aceptar),
          ),
        ],
      ),
    );
    return r ?? false;
  }
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(c, true),
          child: Text(aceptar),
        ),
      ],
    ),
  );
  return r ?? false;
}
