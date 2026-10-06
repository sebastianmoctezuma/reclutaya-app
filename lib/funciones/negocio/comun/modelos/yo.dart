import 'package:json_annotation/json_annotation.dart';

part 'yo.g.dart';

/// `GET /yo`. Los modelos del contrato son TOLERANTES: ignoran campos que no
/// conocen (agregar campos es compatible) y solo exigen los obligatorios.
@JsonSerializable(createToJson: false)
class EmpresaYo {
  const EmpresaYo({required this.nombre, this.logoUrl, this.logoFit});

  factory EmpresaYo.fromJson(Map<String, dynamic> json) =>
      _$EmpresaYoFromJson(json);

  final String nombre;
  final String? logoUrl;
  final String? logoFit;
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
  final String? correo;

  bool get esNegocio => tipo == 'negocio';
}
