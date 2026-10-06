import 'package:flutter/material.dart';
import 'package:liquid_design/liquid_design.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/vidrio/vidrio.dart';

/// ¿Este dispositivo tiene el vidrio real de Apple? (iOS 26+, tras `prepararVidrio`.)
bool get vidrioNativoDisponible =>
    LiquidGlassService.instance.isLiquidGlassSupported;

/// Inicializa el servicio antes del primer cuadro, así `vidrioNativoDisponible`
/// ya es confiable en el arranque. Renderizador nativo (el más rápido en iPhone)
/// y sin respaldo del paquete: el respaldo es nuestro (`VidrioPropio`).
Future<void> prepararVidrio() async {
  await LiquidGlassService.instance.ensureInitialized();
  LiquidGlassService.instance
    ..setRenderer(LiquidGlassRenderer.native)
    ..setFallback(LiquidGlassFallback.none)
    ..setBrightness(LiquidGlassBrightness.auto);
}

class VidrioNativo extends StatelessWidget {
  const VidrioNativo({required this.variante, required this.child, super.key});

  final VidrioVariante variante;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final forma = switch (variante) {
      VidrioVariante.barra ||
      VidrioVariante.pastilla => const LiquidGlassShape.capsule(),
      VidrioVariante.hoja => const LiquidGlassShape.roundedRect(radioGrande),
    };
    return LiquidGlass(
      shape: forma,
      style: LiquidGlassStyle.regular,
      tintColor: t.papel,
      tintOpacity: 0.12,
      interactive: variante == VidrioVariante.pastilla,
      renderer: LiquidGlassRenderer.native,
      child: child,
    );
  }
}
