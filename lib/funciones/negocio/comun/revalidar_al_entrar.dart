import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Al entrar a una pantalla cuyos datos ya estaban en memoria (8-oct), los pide otra
/// vez POR DETRÁS: se ve lo guardado al instante y cambia solo cuando llega lo nuevo,
/// sin esqueleto (Riverpod conserva el valor anterior mientras recarga). Si no había
/// nada guardado, no hace nada: la carga normal ya está en camino.
class RevalidarAlEntrar extends ConsumerStatefulWidget {
  const RevalidarAlEntrar({
    required this.alEntrar,
    required this.child,
    super.key,
  });

  /// Qué volver a pedir; se llama una vez, después del primer cuadro.
  final void Function(WidgetRef ref) alEntrar;
  final Widget child;

  @override
  ConsumerState<RevalidarAlEntrar> createState() => _RevalidarAlEntrarState();
}

class _RevalidarAlEntrarState extends ConsumerState<RevalidarAlEntrar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.alEntrar(ref);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
