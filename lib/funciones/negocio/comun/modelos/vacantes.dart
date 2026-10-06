import 'package:json_annotation/json_annotation.dart';

part 'vacantes.g.dart';

@JsonSerializable(createToJson: false)
class SucursalRef {
  const SucursalRef({
    required this.id,
    required this.nombre,
    required this.colorIdx,
  });

  factory SucursalRef.fromJson(Map<String, dynamic> json) =>
      _$SucursalRefFromJson(json);

  final String id;
  final String nombre;
  final int colorIdx;
}

/// `GET /negocio/vacantes?estado=activas` (incluye pausadas y borradores).
@JsonSerializable(createToJson: false)
class VacanteResumen {
  const VacanteResumen({
    required this.id,
    required this.puesto,
    required this.estado,
    required this.slug,
    required this.candidatos,
    required this.sinRankear,
    this.ubicacion,
    this.sueldoTexto,
    this.sucursal,
    this.diasRestantes,
    this.siguientePaso,
  });

  factory VacanteResumen.fromJson(Map<String, dynamic> json) =>
      _$VacanteResumenFromJson(json);

  final String id;
  final String puesto;
  final String estado;
  final String slug;
  final String? ubicacion;
  final String? sueldoTexto;
  final SucursalRef? sucursal;
  final int candidatos;
  final int sinRankear;
  final int? diasRestantes;

  /// Solo en el Inicio: «Revisar candidatos», «Compartir formulario»…
  final String? siguientePaso;
}

/// `GET /negocio/vacantes?estado=cerradas`.
@JsonSerializable(createToJson: false)
class VacanteCerrada {
  const VacanteCerrada({
    required this.id,
    required this.puesto,
    required this.slug,
    required this.candidatos,
    this.ubicacion,
    this.sueldoTexto,
    this.cerradaAt,
    this.huboContratacion = false,
    this.purgada = false,
    this.sucursal,
    this.diasParaArchivar,
  });

  factory VacanteCerrada.fromJson(Map<String, dynamic> json) =>
      _$VacanteCerradaFromJson(json);

  final String id;
  final String puesto;
  final String slug;
  final String? ubicacion;
  final String? sueldoTexto;
  final DateTime? cerradaAt;
  @JsonKey(defaultValue: false)
  final bool huboContratacion;
  @JsonKey(defaultValue: false)
  final bool purgada;
  final int candidatos;
  final SucursalRef? sucursal;
  final int? diasParaArchivar;
}

@JsonSerializable(createToJson: false)
class Pregunta {
  const Pregunta({
    required this.id,
    required this.texto,
    this.esRequisito = false,
  });

  factory Pregunta.fromJson(Map<String, dynamic> json) =>
      _$PreguntaFromJson(json);

  final String id;
  final String texto;
  @JsonKey(defaultValue: false)
  final bool esRequisito;
}

@JsonSerializable(createToJson: false)
class Conteos {
  const Conteos({
    required this.total,
    required this.rankeados,
    required this.sinRankear,
    required this.cumplenRequisitos,
    this.pideRequisitos = false,
  });

  factory Conteos.fromJson(Map<String, dynamic> json) =>
      _$ConteosFromJson(json);

  final int total;
  final int rankeados;
  final int sinRankear;
  final int cumplenRequisitos;
  @JsonKey(defaultValue: false)
  final bool pideRequisitos;
}

/// `GET /negocio/vacantes/{slug}`.
@JsonSerializable(createToJson: false)
class VacanteFicha {
  const VacanteFicha({
    required this.id,
    required this.puesto,
    required this.estado,
    required this.slug,
    required this.diasParaResponder,
    required this.conteos,
    this.descripcion,
    this.ubicacion,
    this.sueldoTexto,
    this.turno,
    this.sucursal,
    this.formularioCerrado = false,
    this.purgada = false,
    this.diasRestantes,
    this.diasParaArchivar,
    this.cerradaAt,
    this.huboContratacion,
    this.preguntas = const [],
  });

  factory VacanteFicha.fromJson(Map<String, dynamic> json) =>
      _$VacanteFichaFromJson(json);

  final String id;
  final String puesto;
  final String estado;
  final String slug;
  final String? descripcion;
  final String? ubicacion;
  final String? sueldoTexto;
  final String? turno;
  final String? sucursal;
  final int diasParaResponder;
  @JsonKey(defaultValue: false)
  final bool formularioCerrado;
  @JsonKey(defaultValue: false)
  final bool purgada;
  final int? diasRestantes;
  final int? diasParaArchivar;
  final DateTime? cerradaAt;
  final bool? huboContratacion;
  @JsonKey(defaultValue: <Pregunta>[])
  final List<Pregunta> preguntas;
  final Conteos conteos;
}
