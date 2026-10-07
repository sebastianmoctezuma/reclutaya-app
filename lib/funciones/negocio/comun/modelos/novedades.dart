import 'package:json_annotation/json_annotation.dart';

part 'novedades.g.dart';

/// Una novedad de la campana (6-oct), tal como la arma el servidor: el candidato con
/// nombre parcial y la acción en palabras («se postuló», «mandó su video»…).
@JsonSerializable(createToJson: false)
class Novedad {
  const Novedad({
    required this.tipo,
    required this.at,
    required this.candidato,
    required this.accion,
    required this.puesto,
    required this.slug,
    required this.postulacionId,
    this.sucursal,
  });

  factory Novedad.fromJson(Map<String, dynamic> json) =>
      _$NovedadFromJson(json);

  /// `postulacion` · `video` · `documento` · `test`.
  final String tipo;
  final DateTime at;
  final String candidato;
  final String accion;
  final String puesto;
  final String? sucursal;
  final String slug;
  final String postulacionId;
}

/// `GET /negocio/novedades`. `hasta` es el «visto hasta» que se guarda al abrirla.
@JsonSerializable(createToJson: false)
class Novedades {
  const Novedades({required this.hasta, this.items = const []});

  factory Novedades.fromJson(Map<String, dynamic> json) =>
      _$NovedadesFromJson(json);

  @JsonKey(defaultValue: <Novedad>[])
  final List<Novedad> items;
  final DateTime hasta;
}
