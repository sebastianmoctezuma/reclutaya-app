import 'package:json_annotation/json_annotation.dart';

part 'ficha_candidato.g.dart';

/// Video o documento. `url` es firmada y vence: no se guarda, se vuelve a
/// pedir la ficha.
@JsonSerializable(createToJson: false)
class Entregable {
  const Entregable({
    this.solicitado = false,
    this.recibido = false,
    this.url,
    this.tipo,
  });

  factory Entregable.fromJson(Map<String, dynamic> json) =>
      _$EntregableFromJson(json);

  @JsonKey(defaultValue: false)
  final bool solicitado;
  @JsonKey(defaultValue: false)
  final bool recibido;
  final String? url;
  final String? tipo;
}

@JsonSerializable(createToJson: false)
class ResultadoTest {
  const ResultadoTest({
    required this.integridad,
    required this.integridadTono,
    this.rasgos = const {},
    this.top3 = const [],
    this.arquetipo = const [],
    this.comentarios = const [],
    this.respuestasMarcadas = 0,
  });

  factory ResultadoTest.fromJson(Map<String, dynamic> json) =>
      _$ResultadoTestFromJson(json);

  @JsonKey(defaultValue: <String, num>{})
  final Map<String, num> rasgos;
  @JsonKey(defaultValue: <String>[])
  final List<String> top3;
  @JsonKey(defaultValue: <String>[])
  final List<String> arquetipo;
  @JsonKey(defaultValue: <String>[])
  final List<String> comentarios;
  final String integridad;

  /// bajo = verde, nota = ámbar, medio = rojo (igual que el panel).
  final String integridadTono;
  @JsonKey(defaultValue: 0)
  final int respuestasMarcadas;
}

@JsonSerializable(createToJson: false)
class Test {
  const Test({this.estado = 'NO_ENVIADA', this.duracion, this.resultado});

  factory Test.fromJson(Map<String, dynamic> json) => _$TestFromJson(json);

  @JsonKey(defaultValue: 'NO_ENVIADA')
  final String estado;
  final String? duracion;
  final ResultadoTest? resultado;
}

@JsonSerializable(createToJson: false)
class Respuesta {
  const Respuesta({
    required this.texto,
    required this.respuesta,
    this.abierta = false,
    this.requisito = false,
    this.incumple = false,
  });

  factory Respuesta.fromJson(Map<String, dynamic> json) =>
      _$RespuestaFromJson(json);

  final String texto;
  final String respuesta;
  @JsonKey(defaultValue: false)
  final bool abierta;
  @JsonKey(defaultValue: false)
  final bool requisito;
  @JsonKey(defaultValue: false)
  final bool incumple;
}

/// `GET /negocio/postulaciones/{id}`: la ficha del panel lateral. Sin
/// contactar, `nombre` llega parcial y las URLs en null.
@JsonSerializable(createToJson: false)
class FichaCandidato {
  const FichaCandidato({
    required this.postulacionId,
    required this.nombre,
    this.contactado = false,
    this.contratado = false,
    this.noRespondio = false,
    this.whatsapp,
    this.zona,
    this.resumen,
    this.turnoDisponible,
    this.sueldoEsperado,
    this.entregaFallo,
    this.minutosTraslado,
    this.experienciaMeses,
    this.score,
    this.fechaLimite,
    this.video = const Entregable(),
    this.documento = const Entregable(),
    this.test = const Test(),
    this.respuestas = const [],
    this.extras = const [],
    this.razones = const [],
    this.fase,
  });

  factory FichaCandidato.fromJson(Map<String, dynamic> json) =>
      _$FichaCandidatoFromJson(json);

  final String postulacionId;
  final String nombre;
  @JsonKey(defaultValue: false)
  final bool contactado;
  @JsonKey(defaultValue: false)
  final bool contratado;
  @JsonKey(defaultValue: false)
  final bool noRespondio;
  final String? whatsapp;
  final String? zona;
  final String? resumen;
  final String? turnoDisponible;
  final String? sueldoEsperado;
  final String? entregaFallo;
  final int? minutosTraslado;
  final int? experienciaMeses;
  final num? score;
  final DateTime? fechaLimite;
  final Entregable video;
  final Entregable documento;
  final Test test;
  @JsonKey(defaultValue: <Respuesta>[])
  final List<Respuesta> respuestas;
  @JsonKey(defaultValue: <Respuesta>[])
  final List<Respuesta> extras;

  /// La ficha de la IA en renglones (6-oct). Con un servidor anterior, vacía.
  @JsonKey(defaultValue: <String>[])
  final List<String> razones;

  /// La misma fase del chip del ranking. null con un servidor anterior.
  final String? fase;
}
