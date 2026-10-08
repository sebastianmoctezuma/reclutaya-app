// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmpresaYo _$EmpresaYoFromJson(Map<String, dynamic> json) => EmpresaYo(
  nombre: json['nombre'] as String,
  logoUrl: json['logoUrl'] as String?,
  logoFit: json['logoFit'] as String?,
  plan: json['plan'] as String?,
);

Yo _$YoFromJson(Map<String, dynamic> json) => Yo(
  tipo: json['tipo'] as String,
  iniciales: json['iniciales'] as String,
  nombre: json['nombre'] as String?,
  rol: json['rol'] as String?,
  veDinero: json['veDinero'] as bool? ?? false,
  empresa: json['empresa'] == null
      ? null
      : EmpresaYo.fromJson(json['empresa'] as Map<String, dynamic>),
  variasSucursales: json['variasSucursales'] as bool? ?? false,
  correo: json['correo'] as String?,
  usuarioId: json['usuarioId'] as String?,
);
