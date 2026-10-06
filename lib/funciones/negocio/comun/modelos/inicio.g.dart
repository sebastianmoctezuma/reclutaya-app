// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inicio.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Indicadores _$IndicadoresFromJson(Map<String, dynamic> json) => Indicadores(
  velocidad: json['velocidad'] as num?,
  velocidadDelta: json['velocidadDelta'] as num?,
  cumplenPct: (json['cumplenPct'] as num?)?.toInt(),
  cumplenN: (json['cumplenN'] as num?)?.toInt(),
  cumplenTotal: (json['cumplenTotal'] as num?)?.toInt(),
  cumplenDelta: json['cumplenDelta'] as num?,
  respuestaPct: json['respuestaPct'] as num?,
  respuestaDelta: json['respuestaDelta'] as num?,
  tiempoDias: (json['tiempoDias'] as num?)?.toInt(),
  tiempoDelta: json['tiempoDelta'] as num?,
);

Saldo _$SaldoFromJson(Map<String, dynamic> json) => Saldo(
  plan: (json['plan'] as num).toInt(),
  extra: (json['extra'] as num).toInt(),
  total: (json['total'] as num).toInt(),
);

NegocioInicio _$NegocioInicioFromJson(Map<String, dynamic> json) =>
    NegocioInicio(
      nombre: json['nombre'] as String,
      meta: json['meta'] as String? ?? '',
      logoUrl: json['logoUrl'] as String?,
      logoFit: json['logoFit'] as String?,
    );

ResumenInicio _$ResumenInicioFromJson(Map<String, dynamic> json) =>
    ResumenInicio(
      vacantesAbiertas: (json['vacantesAbiertas'] as num).toInt(),
      candidatosNuevos: (json['candidatosNuevos'] as num).toInt(),
      contratacionesMes: (json['contratacionesMes'] as num).toInt(),
      contactos: (json['contactos'] as num?)?.toInt(),
      ilimitada: json['ilimitada'] as bool? ?? false,
    );

SucursalInicio _$SucursalInicioFromJson(Map<String, dynamic> json) =>
    SucursalInicio(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      colorIdx: (json['colorIdx'] as num).toInt(),
      imagenUrl: json['imagenUrl'] as String?,
      principal: json['principal'] as bool? ?? false,
      vacantesActivas: (json['vacantesActivas'] as num?)?.toInt() ?? 0,
      candidatosSemana: (json['candidatosSemana'] as num?)?.toInt() ?? 0,
      gastados: (json['gastados'] as num?)?.toInt() ?? 0,
      sinRanking: (json['sinRanking'] as num?)?.toInt() ?? 0,
    );

ConsumoInicio _$ConsumoInicioFromJson(Map<String, dynamic> json) =>
    ConsumoInicio(
      resto: (json['resto'] as num?)?.toInt(),
      disponibles: (json['disponibles'] as num?)?.toInt(),
    );

PendienteInicio _$PendienteInicioFromJson(Map<String, dynamic> json) =>
    PendienteInicio(
      id: json['id'] as String,
      tipo: json['tipo'] as String,
      titulo: json['titulo'] as String,
      sub: json['sub'] as String,
      slug: json['slug'] as String?,
    );

EmbudoInicio _$EmbudoInicioFromJson(Map<String, dynamic> json) => EmbudoInicio(
  postulaciones: (json['postulaciones'] as num).toInt(),
  contactados: (json['contactados'] as num).toInt(),
  contratados: (json['contratados'] as num).toInt(),
  cumplenRequisitos: (json['cumplenRequisitos'] as num?)?.toInt() ?? 0,
  conRequisitos: (json['conRequisitos'] as num?)?.toInt() ?? 0,
);

ProcesoInicio _$ProcesoInicioFromJson(Map<String, dynamic> json) =>
    ProcesoInicio(
      total: EmbudoInicio.fromJson(json['total'] as Map<String, dynamic>),
      porSucursal: (json['porSucursal'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, EmbudoInicio.fromJson(e as Map<String, dynamic>)),
      ),
    );

ActividadInicio _$ActividadInicioFromJson(Map<String, dynamic> json) =>
    ActividadInicio(
      postulacionId: json['postulacionId'] as String,
      tipo: json['tipo'] as String,
      candidato: json['candidato'] as String,
      accion: json['accion'] as String,
      puesto: json['puesto'] as String,
      slug: json['slug'] as String,
      hace: json['hace'] as String,
      sucursalId: json['sucursalId'] as String?,
      sucursal: json['sucursal'] as String?,
    );

Inicio _$InicioFromJson(Map<String, dynamic> json) => Inicio(
  indicadores: Indicadores.fromJson(
    json['indicadores'] as Map<String, dynamic>,
  ),
  saldo: json['saldo'] == null
      ? null
      : Saldo.fromJson(json['saldo'] as Map<String, dynamic>),
  negocio: json['negocio'] == null
      ? null
      : NegocioInicio.fromJson(json['negocio'] as Map<String, dynamic>),
  resumen: json['resumen'] == null
      ? null
      : ResumenInicio.fromJson(json['resumen'] as Map<String, dynamic>),
  indicadoresPorSucursal:
      (json['indicadoresPorSucursal'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, Indicadores.fromJson(e as Map<String, dynamic>)),
      ),
  sucursales: (json['sucursales'] as List<dynamic>?)
      ?.map((e) => SucursalInicio.fromJson(e as Map<String, dynamic>))
      .toList(),
  consumo: json['consumo'] == null
      ? null
      : ConsumoInicio.fromJson(json['consumo'] as Map<String, dynamic>),
  pendientes: (json['pendientes'] as List<dynamic>?)
      ?.map((e) => PendienteInicio.fromJson(e as Map<String, dynamic>))
      .toList(),
  proceso: json['proceso'] == null
      ? null
      : ProcesoInicio.fromJson(json['proceso'] as Map<String, dynamic>),
  actividad: (json['actividad'] as List<dynamic>?)
      ?.map((e) => ActividadInicio.fromJson(e as Map<String, dynamic>))
      .toList(),
  vacantes: (json['vacantes'] as List<dynamic>?)
      ?.map((e) => VacanteResumen.fromJson(e as Map<String, dynamic>))
      .toList(),
);
