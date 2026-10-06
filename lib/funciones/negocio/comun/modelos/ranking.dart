import 'package:json_annotation/json_annotation.dart';

part 'ranking.g.dart';

/// Una fila del ranking, TAL COMO LLEGA: enmascarada por el servidor. La app
/// no deriva nada de aquí (ni teléfono ni apellido).
@JsonSerializable(createToJson: false)
class FilaRanking {
  const FilaRanking({
    required this.postulacionId,
    required this.ranking,
    required this.nombre,
    this.apellidoOculto = false,
    this.whatsapp,
    this.zona,
    this.score,
    this.resumen,
    this.minutosTraslado,
    this.contactado = false,
    this.noRespondio = false,
    this.contratado = false,
    this.videoSolicitado = false,
    this.videoRecibido = false,
    this.documentoSolicitado = false,
    this.documentoRecibido = false,
    this.testEstado = 'NO_ENVIADA',
    this.testScore,
    this.fechaLimite,
    this.entregaFallo,
    this.requisitosIncumplidos = 0,
    this.requisitosTotal = 0,
  });

  factory FilaRanking.fromJson(Map<String, dynamic> json) =>
      _$FilaRankingFromJson(json);

  final String postulacionId;
  final int ranking;
  final String nombre;
  @JsonKey(defaultValue: false)
  final bool apellidoOculto;
  final String? whatsapp;
  final String? zona;
  final num? score;
  final String? resumen;
  final int? minutosTraslado;
  @JsonKey(defaultValue: false)
  final bool contactado;
  @JsonKey(defaultValue: false)
  final bool noRespondio;
  @JsonKey(defaultValue: false)
  final bool contratado;
  @JsonKey(defaultValue: false)
  final bool videoSolicitado;
  @JsonKey(defaultValue: false)
  final bool videoRecibido;
  @JsonKey(defaultValue: false)
  final bool documentoSolicitado;
  @JsonKey(defaultValue: false)
  final bool documentoRecibido;
  @JsonKey(defaultValue: 'NO_ENVIADA')
  final String testEstado;
  final num? testScore;
  final DateTime? fechaLimite;
  final String? entregaFallo;
  @JsonKey(defaultValue: 0)
  final int requisitosIncumplidos;
  @JsonKey(defaultValue: 0)
  final int requisitosTotal;
}

/// Solo en vacantes del modelo viejo de desbloqueos: filas difuminadas.
@JsonSerializable(createToJson: false)
class Bloqueado {
  const Bloqueado({
    required this.postulacionId,
    required this.ranking,
    this.score,
  });

  factory Bloqueado.fromJson(Map<String, dynamic> json) =>
      _$BloqueadoFromJson(json);

  final String postulacionId;
  final int ranking;
  final num? score;
}

/// `GET /negocio/vacantes/{slug}/ranking`.
@JsonSerializable(createToJson: false)
class Ranking {
  const Ranking({
    required this.visibles,
    required this.total,
    this.bloqueados = const [],
  });

  factory Ranking.fromJson(Map<String, dynamic> json) =>
      _$RankingFromJson(json);

  final List<FilaRanking> visibles;
  @JsonKey(defaultValue: <Bloqueado>[])
  final List<Bloqueado> bloqueados;
  final int total;
}
