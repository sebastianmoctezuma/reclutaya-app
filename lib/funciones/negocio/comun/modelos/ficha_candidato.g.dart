// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ficha_candidato.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Entregable _$EntregableFromJson(Map<String, dynamic> json) => Entregable(
  solicitado: json['solicitado'] as bool? ?? false,
  recibido: json['recibido'] as bool? ?? false,
  url: json['url'] as String?,
  tipo: json['tipo'] as String?,
);

ResultadoTest _$ResultadoTestFromJson(
  Map<String, dynamic> json,
) => ResultadoTest(
  integridad: json['integridad'] as String,
  integridadTono: json['integridadTono'] as String,
  rasgos:
      (json['rasgos'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as num),
      ) ??
      {},
  top3:
      (json['top3'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
  arquetipo:
      (json['arquetipo'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      [],
  comentarios:
      (json['comentarios'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  respuestasMarcadas: (json['respuestasMarcadas'] as num?)?.toInt() ?? 0,
);

Test _$TestFromJson(Map<String, dynamic> json) => Test(
  estado: json['estado'] as String? ?? 'NO_ENVIADA',
  duracion: json['duracion'] as String?,
  resultado: json['resultado'] == null
      ? null
      : ResultadoTest.fromJson(json['resultado'] as Map<String, dynamic>),
);

Respuesta _$RespuestaFromJson(Map<String, dynamic> json) => Respuesta(
  texto: json['texto'] as String,
  respuesta: json['respuesta'] as String,
  abierta: json['abierta'] as bool? ?? false,
  requisito: json['requisito'] as bool? ?? false,
  incumple: json['incumple'] as bool? ?? false,
);

FichaCandidato _$FichaCandidatoFromJson(Map<String, dynamic> json) =>
    FichaCandidato(
      postulacionId: json['postulacionId'] as String,
      nombre: json['nombre'] as String,
      contactado: json['contactado'] as bool? ?? false,
      contratado: json['contratado'] as bool? ?? false,
      noRespondio: json['noRespondio'] as bool? ?? false,
      whatsapp: json['whatsapp'] as String?,
      zona: json['zona'] as String?,
      resumen: json['resumen'] as String?,
      turnoDisponible: json['turnoDisponible'] as String?,
      sueldoEsperado: json['sueldoEsperado'] as String?,
      entregaFallo: json['entregaFallo'] as String?,
      minutosTraslado: (json['minutosTraslado'] as num?)?.toInt(),
      experienciaMeses: (json['experienciaMeses'] as num?)?.toInt(),
      score: json['score'] as num?,
      fechaLimite: json['fechaLimite'] == null
          ? null
          : DateTime.parse(json['fechaLimite'] as String),
      video: json['video'] == null
          ? const Entregable()
          : Entregable.fromJson(json['video'] as Map<String, dynamic>),
      documento: json['documento'] == null
          ? const Entregable()
          : Entregable.fromJson(json['documento'] as Map<String, dynamic>),
      test: json['test'] == null
          ? const Test()
          : Test.fromJson(json['test'] as Map<String, dynamic>),
      respuestas:
          (json['respuestas'] as List<dynamic>?)
              ?.map((e) => Respuesta.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      extras:
          (json['extras'] as List<dynamic>?)
              ?.map((e) => Respuesta.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
