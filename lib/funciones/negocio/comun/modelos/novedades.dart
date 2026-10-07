import 'package:json_annotation/json_annotation.dart';

part 'novedades.g.dart';

/// Una novedad de la campana (6-oct), tal como la arma el servidor: el candidato con
/// nombre parcial y la acción en palabras («se postuló», «mandó su video»…).
@JsonSerializable(createToJson: false)
class Novedad {
  const Novedad({
    required this.tipo,
    required this.at,
    required this.accion,
    required this.puesto,
    required this.slug,
    this.candidato,
    this.postulacionId,
    this.sucursal,
    this.titulo,
  });

  factory Novedad.fromJson(Map<String, dynamic> json) =>
      _$NovedadFromJson(json);

  /// `postulacion` · `video` · `documento` · `test` · `ranking` (7-oct).
  final String tipo;
  final DateTime at;

  /// null en el ranking listo (no es de un candidato).
  final String? candidato;
  final String accion;
  final String puesto;

  /// Siempre viene desde el 7-oct (sin sucursal, el nombre del negocio).
  final String? sucursal;
  final String slug;
  final String? postulacionId;

  /// «Nuevo candidato», «Video recibido»… (7-oct; null con un servidor anterior).
  final String? titulo;

  /// «Ana P. envió su video» o, en el ranking, solo la acción.
  String get frase => candidato == null ? accion : '$candidato $accion';
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
