// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sucursales.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VacanteDeSucursal _$VacanteDeSucursalFromJson(Map<String, dynamic> json) =>
    VacanteDeSucursal(
      slug: json['slug'] as String,
      puesto: json['puesto'] as String,
      estado: json['estado'] as String,
      candidatos: (json['candidatos'] as num?)?.toInt() ?? 0,
      sinRankear: (json['sinRankear'] as num?)?.toInt() ?? 0,
    );

SucursalConVacantes _$SucursalConVacantesFromJson(Map<String, dynamic> json) =>
    SucursalConVacantes(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      colorIdx: (json['colorIdx'] as num).toInt(),
      imagenUrl: json['imagenUrl'] as String?,
      principal: json['principal'] as bool? ?? false,
      vacantesActivas: (json['vacantesActivas'] as num?)?.toInt() ?? 0,
      vacantes:
          (json['vacantes'] as List<dynamic>?)
              ?.map(
                (e) => VacanteDeSucursal.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );

Sucursales _$SucursalesFromJson(Map<String, dynamic> json) => Sucursales(
  multisucursal: json['multisucursal'] as bool? ?? false,
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => SucursalConVacantes.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);
