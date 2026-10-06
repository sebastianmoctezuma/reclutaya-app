// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ranking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FilaRanking _$FilaRankingFromJson(Map<String, dynamic> json) => FilaRanking(
  postulacionId: json['postulacionId'] as String,
  ranking: (json['ranking'] as num).toInt(),
  nombre: json['nombre'] as String,
  apellidoOculto: json['apellidoOculto'] as bool? ?? false,
  whatsapp: json['whatsapp'] as String?,
  zona: json['zona'] as String?,
  score: json['score'] as num?,
  resumen: json['resumen'] as String?,
  minutosTraslado: (json['minutosTraslado'] as num?)?.toInt(),
  contactado: json['contactado'] as bool? ?? false,
  noRespondio: json['noRespondio'] as bool? ?? false,
  contratado: json['contratado'] as bool? ?? false,
  videoSolicitado: json['videoSolicitado'] as bool? ?? false,
  videoRecibido: json['videoRecibido'] as bool? ?? false,
  documentoSolicitado: json['documentoSolicitado'] as bool? ?? false,
  documentoRecibido: json['documentoRecibido'] as bool? ?? false,
  testEstado: json['testEstado'] as String? ?? 'NO_ENVIADA',
  testScore: json['testScore'] as num?,
  fechaLimite: json['fechaLimite'] == null
      ? null
      : DateTime.parse(json['fechaLimite'] as String),
  entregaFallo: json['entregaFallo'] as String?,
  requisitosIncumplidos: (json['requisitosIncumplidos'] as num?)?.toInt() ?? 0,
  requisitosTotal: (json['requisitosTotal'] as num?)?.toInt() ?? 0,
);

Bloqueado _$BloqueadoFromJson(Map<String, dynamic> json) => Bloqueado(
  postulacionId: json['postulacionId'] as String,
  ranking: (json['ranking'] as num).toInt(),
  score: json['score'] as num?,
);

Ranking _$RankingFromJson(Map<String, dynamic> json) => Ranking(
  visibles: (json['visibles'] as List<dynamic>)
      .map((e) => FilaRanking.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num).toInt(),
  bloqueados:
      (json['bloqueados'] as List<dynamic>?)
          ?.map((e) => Bloqueado.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);
