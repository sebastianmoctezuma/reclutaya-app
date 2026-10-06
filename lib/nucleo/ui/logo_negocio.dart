import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:reclutaya_app/funciones/negocio/comun/presentacion.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';

/// El logo del negocio (público, sí se cachea). Sin URL, la inicial.
class LogoNegocio extends StatelessWidget {
  const LogoNegocio({
    required this.nombre,
    this.url,
    this.logoFit,
    this.tam = 44,
    super.key,
  });

  final String nombre;
  final String? url;
  final String? logoFit;
  final double tam;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final inicial = Container(
      width: tam,
      height: tam,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: t.verde, shape: BoxShape.circle),
      child: Text(
        nombre.isEmpty ? '' : nombre.characters.first.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w800,
          fontSize: tam * 0.42,
          color: t.tarjeta,
        ),
      ),
    );
    if (url == null || url!.isEmpty) return inicial;
    return ClipOval(
      child: SizedBox(
        width: tam,
        height: tam,
        child: CachedNetworkImage(
          imageUrl: url!,
          fit: ajusteLogo(logoFit),
          placeholder: (_, _) => inicial,
          errorWidget: (_, _, _) => inicial,
        ),
      ),
    );
  }
}
