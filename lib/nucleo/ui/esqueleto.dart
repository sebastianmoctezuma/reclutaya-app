import 'package:flutter/material.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/vidrio/vidrio.dart';

/// Un bloque gris que respira mientras carga. Con «Reducir movimiento», quieto.
class Esqueleto extends StatefulWidget {
  const Esqueleto({
    required this.alto,
    this.ancho = double.infinity,
    this.radio = 10,
    super.key,
  });

  final double alto;
  final double ancho;
  final double radio;

  @override
  State<Esqueleto> createState() => _EsqueletoState();
}

class _EsqueletoState extends State<Esqueleto>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (vidrioSolido(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Container(
        width: widget.ancho,
        height: widget.alto,
        decoration: BoxDecoration(
          color: t.linea.withValues(alpha: 0.55 + 0.3 * _c.value),
          borderRadius: BorderRadius.circular(widget.radio),
        ),
      ),
    );
  }
}
