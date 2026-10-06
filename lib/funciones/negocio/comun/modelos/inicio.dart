import 'package:json_annotation/json_annotation.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/vacantes.dart';

part 'inicio.g.dart';

/// `GET /negocio/inicio`. Los indicadores cubren 30 días; `cumplenPct` y
/// `tiempoDias` en null significan «—» (ver presentación).
@JsonSerializable(createToJson: false)
class Indicadores {
  const Indicadores({
    this.velocidad,
    this.velocidadDelta,
    this.cumplenPct,
    this.cumplenN,
    this.cumplenTotal,
    this.cumplenDelta,
    this.respuestaPct,
    this.respuestaDelta,
    this.tiempoDias,
    this.tiempoDelta,
  });

  factory Indicadores.fromJson(Map<String, dynamic> json) =>
      _$IndicadoresFromJson(json);

  final num? velocidad;
  final num? velocidadDelta;
  final int? cumplenPct;
  final int? cumplenN;
  final int? cumplenTotal;
  final num? cumplenDelta;
  final num? respuestaPct;
  final num? respuestaDelta;
  final int? tiempoDias;
  final num? tiempoDelta;
}

@JsonSerializable(createToJson: false)
class Saldo {
  const Saldo({required this.plan, required this.extra, required this.total});

  factory Saldo.fromJson(Map<String, dynamic> json) => _$SaldoFromJson(json);

  final int plan;
  final int extra;
  final int total;
}

@JsonSerializable(createToJson: false)
class NegocioInicio {
  const NegocioInicio({
    required this.nombre,
    this.meta = '',
    this.logoUrl,
    this.logoFit,
  });

  factory NegocioInicio.fromJson(Map<String, dynamic> json) =>
      _$NegocioInicioFromJson(json);

  final String nombre;

  /// «Giro · Ciudad, Estado».
  @JsonKey(defaultValue: '')
  final String meta;
  final String? logoUrl;
  final String? logoFit;
}

/// «De un vistazo».
@JsonSerializable(createToJson: false)
class ResumenInicio {
  const ResumenInicio({
    required this.vacantesAbiertas,
    required this.candidatosNuevos,
    required this.contratacionesMes,
    this.contactos,
    this.ilimitada = false,
  });

  factory ResumenInicio.fromJson(Map<String, dynamic> json) =>
      _$ResumenInicioFromJson(json);

  final int vacantesAbiertas;
  final int candidatosNuevos;

  /// null = cuenta ilimitada (∞) o quien no ve el dinero.
  final int? contactos;
  @JsonKey(defaultValue: false)
  final bool ilimitada;
  final int contratacionesMes;
}

/// Una sucursal en el Inicio (multisucursal).
@JsonSerializable(createToJson: false)
class SucursalInicio {
  const SucursalInicio({
    required this.id,
    required this.nombre,
    required this.colorIdx,
    this.imagenUrl,
    this.principal = false,
    this.vacantesActivas = 0,
    this.candidatosSemana = 0,
    this.gastados = 0,
    this.sinRanking = 0,
  });

  factory SucursalInicio.fromJson(Map<String, dynamic> json) =>
      _$SucursalInicioFromJson(json);

  final String id;
  final String nombre;
  final int colorIdx;
  final String? imagenUrl;
  @JsonKey(defaultValue: false)
  final bool principal;
  @JsonKey(defaultValue: 0)
  final int vacantesActivas;
  @JsonKey(defaultValue: 0)
  final int candidatosSemana;
  @JsonKey(defaultValue: 0)
  final int gastados;
  @JsonKey(defaultValue: 0)
  final int sinRanking;
}

@JsonSerializable(createToJson: false)
class ConsumoInicio {
  const ConsumoInicio({this.resto, this.disponibles});

  factory ConsumoInicio.fromJson(Map<String, dynamic> json) =>
      _$ConsumoInicioFromJson(json);

  /// Lo gastado por sucursales ajenas (miembro), sumado. null = no aplica.
  final int? resto;
  final int? disponibles;
}

/// Un pendiente: `ranking`, `vence` o `solicitud`. Solo informa: sin acciones.
@JsonSerializable(createToJson: false)
class PendienteInicio {
  const PendienteInicio({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.sub,
    this.slug,
  });

  factory PendienteInicio.fromJson(Map<String, dynamic> json) =>
      _$PendienteInicioFromJson(json);

  final String id;
  final String tipo;
  final String titulo;
  final String sub;
  final String? slug;
}

@JsonSerializable(createToJson: false)
class EmbudoInicio {
  const EmbudoInicio({
    required this.postulaciones,
    required this.contactados,
    required this.contratados,
    this.cumplenRequisitos = 0,
    this.conRequisitos = 0,
  });

  factory EmbudoInicio.fromJson(Map<String, dynamic> json) =>
      _$EmbudoInicioFromJson(json);

  final int postulaciones;
  @JsonKey(defaultValue: 0)
  final int cumplenRequisitos;

  /// 0 = ninguna vacante pedía requisitos: la etapa no se muestra.
  @JsonKey(defaultValue: 0)
  final int conRequisitos;
  final int contactados;
  final int contratados;
}

@JsonSerializable(createToJson: false)
class ProcesoInicio {
  const ProcesoInicio({required this.total, this.porSucursal});

  factory ProcesoInicio.fromJson(Map<String, dynamic> json) =>
      _$ProcesoInicioFromJson(json);

  final EmbudoInicio total;
  final Map<String, EmbudoInicio>? porSucursal;
}

@JsonSerializable(createToJson: false)
class ActividadInicio {
  const ActividadInicio({
    required this.postulacionId,
    required this.tipo,
    required this.candidato,
    required this.accion,
    required this.puesto,
    required this.slug,
    required this.hace,
    this.sucursalId,
    this.sucursal,
  });

  factory ActividadInicio.fromJson(Map<String, dynamic> json) =>
      _$ActividadInicioFromJson(json);

  final String postulacionId;

  /// video · documento · test
  final String tipo;
  final String candidato;
  final String accion;
  final String puesto;
  final String slug;
  final String? sucursalId;
  final String? sucursal;
  final String hace;
}

@JsonSerializable(createToJson: false)
class Inicio {
  const Inicio({
    required this.indicadores,
    this.saldo,
    this.negocio,
    this.resumen,
    this.indicadoresPorSucursal,
    this.sucursales,
    this.consumo,
    this.pendientes,
    this.proceso,
    this.actividad,
    this.vacantes,
  });

  factory Inicio.fromJson(Map<String, dynamic> json) => _$InicioFromJson(json);

  final Indicadores indicadores;

  /// null para quien no ve el dinero o si el sistema de contactos está apagado.
  final Saldo? saldo;

  // Lo de abajo llegó el 6-oct (el Inicio completo). Todo es opcional: un servidor
  // anterior no lo manda y la app sigue funcionando.
  final NegocioInicio? negocio;
  final ResumenInicio? resumen;

  /// Precalculados por sucursal, para filtrar sin otra petición (multisucursal).
  final Map<String, Indicadores>? indicadoresPorSucursal;
  final List<SucursalInicio>? sucursales;
  final ConsumoInicio? consumo;

  /// Solo Pro.
  final List<PendienteInicio>? pendientes;
  final ProcesoInicio? proceso;
  final List<ActividadInicio>? actividad;
  final List<VacanteResumen>? vacantes;
}
