// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'novedades.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Novedad _$NovedadFromJson(Map<String, dynamic> json) => Novedad(
  tipo: json['tipo'] as String,
  at: DateTime.parse(json['at'] as String),
  candidato: json['candidato'] as String,
  accion: json['accion'] as String,
  puesto: json['puesto'] as String,
  slug: json['slug'] as String,
  postulacionId: json['postulacionId'] as String,
  sucursal: json['sucursal'] as String?,
);

Novedades _$NovedadesFromJson(Map<String, dynamic> json) => Novedades(
  hasta: DateTime.parse(json['hasta'] as String),
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => Novedad.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);
