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

/// Una persona del equipo, como la pinta la web: nombre, iniciales y, en «Ver equipo»,
/// su rol y sus sucursales. Nunca correos.
@JsonSerializable(createToJson: false)
class Persona {
  const Persona({
    required this.nombre,
    required this.iniciales,
    this.rol,
    this.sucursales = const [],
  });

  factory Persona.fromJson(Map<String, dynamic> json) =>
      _$PersonaFromJson(json);

  final String nombre;
  final String iniciales;
  final String? rol;
  @JsonKey(defaultValue: <SucursalDePersona>[])
  final List<SucursalDePersona> sucursales;
}

@JsonSerializable(createToJson: false)
class SucursalDePersona {
  const SucursalDePersona({required this.nombre, required this.colorIdx});

  factory SucursalDePersona.fromJson(Map<String, dynamic> json) =>
      _$SucursalDePersonaFromJson(json);

  final String nombre;
  final int colorIdx;
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
    this.direccion,
    this.activas = 0,
    this.sinRanking = 0,
    this.contactosUsados = 0,
    this.miembros = const [],
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

  /// Calle y ciudad, como la tarjeta web.
  final String? direccion;

  /// Los tres números de la ventana de la sucursal (Activas · Sin ranking · Contactos
  /// usados), calculados en el servidor con la regla de la web.
  @JsonKey(defaultValue: 0)
  final int activas;
  @JsonKey(defaultValue: 0)
  final int sinRanking;
  @JsonKey(defaultValue: 0)
  final int contactosUsados;
  @JsonKey(defaultValue: <Persona>[])
  final List<Persona> miembros;
}

/// `GET /negocio/sucursales` (6-oct).
@JsonSerializable(createToJson: false)
class Sucursales {
  const Sucursales({
    required this.multisucursal,
    this.items = const [],
    this.equipo,
  });

  factory Sucursales.fromJson(Map<String, dynamic> json) =>
      _$SucursalesFromJson(json);

  @JsonKey(defaultValue: false)
  final bool multisucursal;
  @JsonKey(defaultValue: <SucursalConVacantes>[])
  final List<SucursalConVacantes> items;

  /// «Ver equipo»: el dueño primero. null si quien mira no es dueño ni administrador.
  final List<Persona>? equipo;
}
