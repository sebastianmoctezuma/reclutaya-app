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

Persona _$PersonaFromJson(Map<String, dynamic> json) => Persona(
  nombre: json['nombre'] as String,
  iniciales: json['iniciales'] as String,
  rol: json['rol'] as String?,
  sucursales:
      (json['sucursales'] as List<dynamic>?)
          ?.map((e) => SucursalDePersona.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

SucursalDePersona _$SucursalDePersonaFromJson(Map<String, dynamic> json) =>
    SucursalDePersona(
      nombre: json['nombre'] as String,
      colorIdx: (json['colorIdx'] as num).toInt(),
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
      direccion: json['direccion'] as String?,
      activas: (json['activas'] as num?)?.toInt() ?? 0,
      sinRanking: (json['sinRanking'] as num?)?.toInt() ?? 0,
      contactosUsados: (json['contactosUsados'] as num?)?.toInt() ?? 0,
      miembros:
          (json['miembros'] as List<dynamic>?)
              ?.map((e) => Persona.fromJson(e as Map<String, dynamic>))
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
  equipo: (json['equipo'] as List<dynamic>?)
      ?.map((e) => Persona.fromJson(e as Map<String, dynamic>))
      .toList(),
);
