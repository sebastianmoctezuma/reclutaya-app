import 'package:flutter/material.dart';

/// Los tokens de la web (`app/globals.css`), portados. ÚNICO lugar con colores.
/// El oscuro sigue la regla del panel: sin verdes neón, tinta clara sobre carbón.
@immutable
class Tokens extends ThemeExtension<Tokens> {
  const Tokens({
    required this.papel,
    required this.tarjeta,
    required this.tinta,
    required this.tintaSuave,
    required this.tintaTenue,
    required this.verde,
    required this.verdeProfundo,
    required this.verdeBrillo,
    required this.verdeSuave,
    required this.naranja,
    required this.naranjaProfundo,
    required this.naranjaBrillo,
    required this.azul,
    required this.azulBrillo,
    required this.rojo,
    required this.rojoBrillo,
    required this.linea,
    required this.lineaFuerte,
    required this.heroInicio,
    required this.heroFin,
    required this.sobreVerde,
    required this.esOscuro,
  });

  final Color papel;
  final Color tarjeta;
  final Color tinta;
  final Color tintaSuave;
  final Color tintaTenue;
  final Color verde;
  final Color verdeProfundo;
  final Color verdeBrillo;
  final Color verdeSuave;
  final Color naranja;
  final Color naranjaProfundo;
  final Color naranjaBrillo;
  final Color azul;
  final Color azulBrillo;
  final Color rojo;
  final Color rojoBrillo;
  final Color linea;
  final Color lineaFuerte;

  /// El degradado de la tarjeta principal del Inicio (el de «Últimas 24
  /// horas» del panel web) y el texto que va encima.
  final Color heroInicio;
  final Color heroFin;
  final Color sobreVerde;
  final bool esOscuro;

  static const claro = Tokens(
    papel: Color(0xFFF7F7F4),
    tarjeta: Color(0xFFFFFFFF),
    tinta: Color(0xFF1F2937),
    tintaSuave: Color(0xFF52606E),
    tintaTenue: Color(0xFF8A96A3),
    verde: Color(0xFF146A43),
    verdeProfundo: Color(0xFF0E5234),
    verdeBrillo: Color(0xFFE8F6EF),
    verdeSuave: Color(0xFFCFE6D8),
    naranja: Color(0xFFFF8A00),
    naranjaProfundo: Color(0xFFCC6E00),
    naranjaBrillo: Color(0xFFFFF0DB),
    azul: Color(0xFF197CBB),
    azulBrillo: Color(0xFFE8F0FF),
    rojo: Color(0xFFC0432E),
    rojoBrillo: Color(0xFFFDEAE6),
    linea: Color(0xFFE6E8E4),
    lineaFuerte: Color(0xFFCCD3CD),
    heroInicio: Color(0xFF1A7A4E),
    heroFin: Color(0xFF0E5234),
    sobreVerde: Color(0xFFFFFFFF),
    esOscuro: false,
  );

  static const oscuro = Tokens(
    papel: Color(0xFF15181D),
    tarjeta: Color(0xFF1B1E24),
    tinta: Color(0xFFE8EAED),
    tintaSuave: Color(0xFF9AA4B0),
    tintaTenue: Color(0xFF8A93A0),
    verde: Color(0xFF4FAE74),
    verdeProfundo: Color(0xFF7BC99A),
    verdeBrillo: Color(0xFF1B2A22),
    verdeSuave: Color(0xFF22302A),
    naranja: Color(0xFFEDA04F),
    naranjaProfundo: Color(0xFFF2B977),
    naranjaBrillo: Color(0xFF2E251A),
    azul: Color(0xFF7FA8EC),
    azulBrillo: Color(0xFF1C2433),
    rojo: Color(0xFFE58585),
    rojoBrillo: Color(0xFF2E1F1E),
    linea: Color(0xFF2C3037),
    lineaFuerte: Color(0xFF3A414B),
    heroInicio: Color(0xFF1F5E3A),
    heroFin: Color(0xFF123826),
    sobreVerde: Color(0xFFF2F8F4),
    esOscuro: true,
  );

  static Tokens de(BuildContext context) =>
      Theme.of(context).extension<Tokens>() ?? claro;

  @override
  Tokens copyWith() => this;

  @override
  Tokens lerp(covariant ThemeExtension<Tokens>? other, double t) =>
      t < 0.5 ? this : (other is Tokens ? other : this);
}

const double radio = 14;
const double radioGrande = 22;

/// La paleta de sucursales de la web (`COLORES_SUCURSAL`), en el mismo orden.
const coloresSucursal = <({Color luz, Color oscuro})>[
  (luz: Color(0xFF1F5E3A), oscuro: Color(0xFF4FAE74)),
  (luz: Color(0xFFD97A1C), oscuro: Color(0xFFEDA04F)),
  (luz: Color(0xFF2F6FD0), oscuro: Color(0xFF7FA8EC)),
  (luz: Color(0xFF5B7285), oscuro: Color(0xFF93A9BC)),
  (luz: Color(0xFFBF4342), oscuro: Color(0xFFE58585)),
];

const _sombraTinte = Color(0xFF14281E);

/// El oscurecido de lo de abajo mientras una pantalla crece o se encoge (zoom, 8-oct).
const veloTransicion = Color(0x2E000000);

List<BoxShadow> sombraSm(Tokens t) => [
  BoxShadow(
    color: _sombraTinte.withValues(alpha: t.esOscuro ? 0.3 : 0.06),
    blurRadius: 3,
    offset: const Offset(0, 1),
  ),
  BoxShadow(
    color: _sombraTinte.withValues(alpha: t.esOscuro ? 0.25 : 0.05),
    blurRadius: 12,
    offset: const Offset(0, 4),
  ),
];

List<BoxShadow> sombraMd(Tokens t) => [
  BoxShadow(
    color: _sombraTinte.withValues(alpha: t.esOscuro ? 0.4 : 0.09),
    blurRadius: 14,
    offset: const Offset(0, 4),
  ),
  BoxShadow(
    color: _sombraTinte.withValues(alpha: t.esOscuro ? 0.35 : 0.08),
    blurRadius: 40,
    offset: const Offset(0, 14),
  ),
];

extension TokensX on BuildContext {
  Tokens get t => Tokens.de(this);
}
