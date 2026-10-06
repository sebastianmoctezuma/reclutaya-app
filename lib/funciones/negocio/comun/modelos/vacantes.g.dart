// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vacantes.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SucursalRef _$SucursalRefFromJson(Map<String, dynamic> json) => SucursalRef(
  id: json['id'] as String,
  nombre: json['nombre'] as String,
  colorIdx: (json['colorIdx'] as num).toInt(),
);

VacanteResumen _$VacanteResumenFromJson(Map<String, dynamic> json) =>
    VacanteResumen(
      id: json['id'] as String,
      puesto: json['puesto'] as String,
      estado: json['estado'] as String,
      slug: json['slug'] as String,
      candidatos: (json['candidatos'] as num).toInt(),
      sinRankear: (json['sinRankear'] as num).toInt(),
      ubicacion: json['ubicacion'] as String?,
      sueldoTexto: json['sueldoTexto'] as String?,
      sucursal: json['sucursal'] == null
          ? null
          : SucursalRef.fromJson(json['sucursal'] as Map<String, dynamic>),
      diasRestantes: (json['diasRestantes'] as num?)?.toInt(),
      siguientePaso: json['siguientePaso'] as String?,
    );

VacanteCerrada _$VacanteCerradaFromJson(Map<String, dynamic> json) =>
    VacanteCerrada(
      id: json['id'] as String,
      puesto: json['puesto'] as String,
      slug: json['slug'] as String,
      candidatos: (json['candidatos'] as num).toInt(),
      ubicacion: json['ubicacion'] as String?,
      sueldoTexto: json['sueldoTexto'] as String?,
      cerradaAt: json['cerradaAt'] == null
          ? null
          : DateTime.parse(json['cerradaAt'] as String),
      huboContratacion: json['huboContratacion'] as bool? ?? false,
      purgada: json['purgada'] as bool? ?? false,
      sucursal: json['sucursal'] == null
          ? null
          : SucursalRef.fromJson(json['sucursal'] as Map<String, dynamic>),
      diasParaArchivar: (json['diasParaArchivar'] as num?)?.toInt(),
    );

Pregunta _$PreguntaFromJson(Map<String, dynamic> json) => Pregunta(
  id: json['id'] as String,
  texto: json['texto'] as String,
  esRequisito: json['esRequisito'] as bool? ?? false,
);

Conteos _$ConteosFromJson(Map<String, dynamic> json) => Conteos(
  total: (json['total'] as num).toInt(),
  rankeados: (json['rankeados'] as num).toInt(),
  sinRankear: (json['sinRankear'] as num).toInt(),
  cumplenRequisitos: (json['cumplenRequisitos'] as num).toInt(),
  pideRequisitos: json['pideRequisitos'] as bool? ?? false,
);

VacanteFicha _$VacanteFichaFromJson(Map<String, dynamic> json) => VacanteFicha(
  id: json['id'] as String,
  puesto: json['puesto'] as String,
  estado: json['estado'] as String,
  slug: json['slug'] as String,
  diasParaResponder: (json['diasParaResponder'] as num).toInt(),
  conteos: Conteos.fromJson(json['conteos'] as Map<String, dynamic>),
  descripcion: json['descripcion'] as String?,
  ubicacion: json['ubicacion'] as String?,
  sueldoTexto: json['sueldoTexto'] as String?,
  turno: json['turno'] as String?,
  sucursal: json['sucursal'] as String?,
  formularioCerrado: json['formularioCerrado'] as bool? ?? false,
  purgada: json['purgada'] as bool? ?? false,
  diasRestantes: (json['diasRestantes'] as num?)?.toInt(),
  diasParaArchivar: (json['diasParaArchivar'] as num?)?.toInt(),
  cerradaAt: json['cerradaAt'] == null
      ? null
      : DateTime.parse(json['cerradaAt'] as String),
  huboContratacion: json['huboContratacion'] as bool?,
  preguntas:
      (json['preguntas'] as List<dynamic>?)
          ?.map((e) => Pregunta.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);
