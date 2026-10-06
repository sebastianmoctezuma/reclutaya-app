import 'package:json_annotation/json_annotation.dart';

part 'sucursales.g.dart';

@JsonSerializable(createToJson: false)
class VacanteDeSucursal {
  const VacanteDeSucursal({
    required this.slug,
    required this.puesto,
    required this.estado,
    this.candidatos = 0,
    this.sinRankear = 0,
  });

  factory VacanteDeSucursal.fromJson(Map<String, dynamic> json) =>
      _$VacanteDeSucursalFromJson(json);

  final String slug;
  final String puesto;
  final String estado;
  @JsonKey(defaultValue: 0)
  final int candidatos;
  @JsonKey(defaultValue: 0)
  final int sinRankear;
}

@JsonSerializable(createToJson: false)
class SucursalConVacantes {
  const SucursalConVacantes({
    required this.id,
    required this.nombre,
    required this.colorIdx,
    this.imagenUrl,
    this.principal = false,
    this.vacantesActivas = 0,
    this.vacantes = const [],
  });

  factory SucursalConVacantes.fromJson(Map<String, dynamic> json) =>
      _$SucursalConVacantesFromJson(json);

  final String id;
  final String nombre;
  final int colorIdx;
  final String? imagenUrl;
  @JsonKey(defaultValue: false)
  final bool principal;
  @JsonKey(defaultValue: 0)
  final int vacantesActivas;
  @JsonKey(defaultValue: <VacanteDeSucursal>[])
  final List<VacanteDeSucursal> vacantes;
}

/// `GET /negocio/sucursales` (6-oct).
@JsonSerializable(createToJson: false)
class Sucursales {
  const Sucursales({required this.multisucursal, this.items = const []});

  factory Sucursales.fromJson(Map<String, dynamic> json) =>
      _$SucursalesFromJson(json);

  @JsonKey(defaultValue: false)
  final bool multisucursal;
  @JsonKey(defaultValue: <SucursalConVacantes>[])
  final List<SucursalConVacantes> items;
}
