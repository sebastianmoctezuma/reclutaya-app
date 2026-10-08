import 'package:flutter/material.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';

/// El logo REAL de ReclutaYa, el mismo de la web (`public/logoclaro.png` y
/// `logodark.png`): isotipo, «ReclutaYa» y «Filtramos. Tú decides.». En modo oscuro,
/// la versión con letras claras. Un solo lugar para el login y el pie de Cuenta (8-oct).
class MarcaReclutaYa extends StatelessWidget {
  const MarcaReclutaYa({this.ancho = 220, this.sobreVerde = false, super.key});

  final double ancho;

  /// Sobre el verde de la marca (el encabezado del Inicio): siempre la versión de
  /// letras claras, en cualquier tema; la verde no se leería.
  final bool sobreVerde;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      sobreVerde || context.t.esOscuro
          ? 'assets/imagenes/logo_oscuro.png'
          : 'assets/imagenes/logo_claro.png',
      width: ancho,
      // A su tamaño: no decodificar 1400 px para pintar 220.
      cacheWidth: (ancho * MediaQuery.devicePixelRatioOf(context)).round(),
      semanticLabel: 'ReclutaYa. Filtramos. Tú decides.',
    );
  }
}
