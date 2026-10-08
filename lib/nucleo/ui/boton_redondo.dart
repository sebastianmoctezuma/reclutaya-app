import 'package:flutter/material.dart';
import 'package:reclutaya_app/nucleo/plataforma/adaptativos.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';

/// El botón redondo SÓLIDO que flota sobre el verde (8-oct): blanco (gris oscuro en
/// modo oscuro), borde fino, sombra suave y el ícono con contraste. Lo usan la campana
/// del Inicio y la cruz de cerrar. El vidrio pálido con ícono blanco se perdía sobre
/// el verde.
class BotonRedondo extends StatelessWidget {
  const BotonRedondo({
    required this.icono,
    required this.etiqueta,
    required this.alTocar,
    this.colorIcono,
    super.key,
  });

  final IconData icono;

  /// Lo que lee el lector de pantalla.
  final String etiqueta;
  final VoidCallback? alTocar;
  final Color? colorIcono;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Semantics(
      button: true,
      label: etiqueta,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: const CircleBorder(),
          shadows: sombraSm(t),
        ),
        child: Material(
          color: t.tarjeta,
          shape: CircleBorder(
            side: BorderSide(
              color: t.linea.withValues(alpha: t.esOscuro ? 1 : 0.75),
              width: 0.6,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: alTocar == null
                ? null
                : () {
                    hapticoSeleccion();
                    alTocar!();
                  },
            child: SizedBox(
              width: 44,
              height: 44,
              child: ExcludeSemantics(
                child: Icon(icono, size: 20, color: colorIcono ?? t.tinta),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
