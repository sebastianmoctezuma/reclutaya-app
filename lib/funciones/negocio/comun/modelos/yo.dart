import 'package:json_annotation/json_annotation.dart';

part 'yo.g.dart';

/// `GET /yo`. Los modelos del contrato son TOLERANTES: ignoran campos que no
/// conocen (agregar campos es compatible) y solo exigen los obligatorios.
@JsonSerializable(createToJson: false)
class EmpresaYo {
  const EmpresaYo({
    required this.nombre,
    this.logoUrl,
    this.logoFit,
    this.plan,
  });

  factory EmpresaYo.fromJson(Map<String, dynamic> json) =>
      _$EmpresaYoFromJson(json);

  final String nombre;
  final String? logoUrl;
  final String? logoFit;

  /// El nombre del plan (Esencial · Básico · Pro · Ilimitada · Gratis), con la regla de
  /// la página de Pagos. null con un servidor anterior.
  final String? plan;
}

@JsonSerializable(createToJson: false)
class Yo {
  const Yo({
    required this.tipo,
    required this.iniciales,
    this.nombre,
    this.rol,
    this.veDinero = false,
    this.empresa,
    this.variasSucursales = false,
    this.correo,
    this.usuarioId,
  });

  factory Yo.fromJson(Map<String, dynamic> json) => _$YoFromJson(json);

  final String tipo;

  /// null si el usuario no capturó su nombre (es opcional en la base).
  final String? nombre;
  final String iniciales;
  final String? rol;
  @JsonKey(defaultValue: false)
  final bool veDinero;
  final EmpresaYo? empresa;
  @JsonKey(defaultValue: false)
  final bool variasSucursales;

  /// El id de ReclutaYa del usuario (8-oct, varias cuentas); null con un servidor anterior.
  final String? usuarioId;
  final String? correo;

  bool get esNegocio => tipo == 'negocio';
}
