import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:reclutaya_app/funciones/negocio/comun/presentacion.dart';
import 'package:reclutaya_app/nucleo/plataforma/adaptativos.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/ui/tarjeta.dart';

/// El logo de una sucursal (su imagen pública) o su inicial sobre su color.
class LogoSucursal extends StatelessWidget {
  const LogoSucursal({
    required this.nombre,
    required this.colorIdx,
    this.imagenUrl,
    this.tam = 32,
    super.key,
  });

  final String nombre;
  final String? imagenUrl;
  final int colorIdx;
  final double tam;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final inicial = Container(
      width: tam,
      height: tam,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorSucursal(colorIdx, oscuro: t.esOscuro),
        shape: BoxShape.circle,
      ),
      child: Text(
        nombre.isEmpty ? '' : nombre.characters.first.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: tam * 0.42,
          color: t.sobreVerde,
        ),
      ),
    );
    if (imagenUrl == null || imagenUrl!.isEmpty) return inicial;
    return Container(
      width: tam,
      height: tam,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: t.tarjeta,
        border: Border.all(color: t.linea),
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: imagenUrl!,
          fit: BoxFit.cover,
          placeholder: (_, _) => inicial,
          errorWidget: (_, _, _) => inicial,
        ),
      ),
    );
  }
}

/// La superficie de las tarjetas de sucursal de la web: blanca, con la mancha de luz
/// del color de la sucursal en la esquina y un borde especular. Es un degradado
/// dibujado (sin desenfoque en vivo): en una lista no cuesta nada al desplazar.
class SuperficieSucursal extends StatelessWidget {
  const SuperficieSucursal({
    required this.colorIdx,
    required this.child,
    this.alTocar,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final int colorIdx;
  final Widget child;
  final VoidCallback? alTocar;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final color = colorSucursal(colorIdx, oscuro: t.esOscuro);
    final forma = formaTarjeta(radioGrande);
    // El mismo vidrio de las tarjetas, con la mancha de luz del color de la sucursal.
    return SuperficieVidrio(
      forma: forma,
      decoracion: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.95, -0.35),
          radius: 1.05,
          colors: [
            color.withValues(alpha: t.esOscuro ? 0.34 : 0.22),
            color.withValues(alpha: t.esOscuro ? 0.12 : 0.07),
            color.withValues(alpha: 0),
          ],
          stops: const [0, 0.45, 1],
        ),
      ),
      child: InkWell(
        onTap: alTocar == null
            ? null
            : () {
                hapticoSeleccion();
                alTocar!();
              },
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Las iniciales de una persona del equipo en un círculo del color de su sucursal.
class Iniciales extends StatelessWidget {
  const Iniciales(
    this.texto, {
    required this.colorIdx,
    this.tam = 30,
    super.key,
  });

  final String texto;
  final int colorIdx;
  final double tam;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final color = colorSucursal(colorIdx, oscuro: t.esOscuro);
    return Container(
      width: tam,
      height: tam,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.alphaBlend(color.withValues(alpha: 0.14), t.tarjeta),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: tam * 0.33,
          color: color,
        ),
      ),
    );
  }
}

String plural(int n, String uno, String varios) =>
    n == 1 ? '1 $uno' : '$n $varios';
