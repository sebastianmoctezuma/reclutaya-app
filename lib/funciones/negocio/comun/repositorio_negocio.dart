import 'package:reclutaya_app/funciones/negocio/comun/modelos/ficha_candidato.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/inicio.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/ranking.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/sucursales.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/vacantes.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/yo.dart';
import 'package:reclutaya_app/funciones/negocio/comun/parsear.dart';
import 'package:reclutaya_app/nucleo/red/cliente_api.dart';
import 'package:reclutaya_app/nucleo/util/resultado.dart';

/// Un método por ruta del contrato. La v2 agrega métodos; no cambia estos.
abstract class RepositorioNegocio {
  Future<Resultado<Yo>> yo();
  Future<Resultado<Inicio>> inicio();
  Future<Resultado<List<VacanteResumen>>> vacantesActivas();
  Future<Resultado<List<VacanteCerrada>>> vacantesCerradas();
  Future<Resultado<VacanteFicha>> vacante(String slug);
  Future<Resultado<Ranking>> ranking(String slug);
  Future<Resultado<FichaCandidato>> candidato(String postulacionId);
  Future<Resultado<Sucursales>> sucursales();
}

class RepositorioNegocioApi implements RepositorioNegocio {
  RepositorioNegocioApi(this._api);

  final ClienteApi _api;

  String _seg(String s) => Uri.encodeComponent(s);

  @override
  Future<Resultado<Yo>> yo() async =>
      parsear(await _api.get('/yo'), Yo.fromJson);

  @override
  Future<Resultado<Inicio>> inicio() async =>
      parsear(await _api.get('/negocio/inicio'), Inicio.fromJson);

  @override
  Future<Resultado<List<VacanteResumen>>> vacantesActivas() async =>
      parsearLista(
        await _api.get('/negocio/vacantes', query: {'estado': 'activas'}),
        VacanteResumen.fromJson,
      );

  @override
  Future<Resultado<List<VacanteCerrada>>> vacantesCerradas() async =>
      parsearLista(
        await _api.get('/negocio/vacantes', query: {'estado': 'cerradas'}),
        VacanteCerrada.fromJson,
      );

  @override
  Future<Resultado<VacanteFicha>> vacante(String slug) async => parsear(
    await _api.get('/negocio/vacantes/${_seg(slug)}'),
    VacanteFicha.fromJson,
  );

  @override
  Future<Resultado<Ranking>> ranking(String slug) async => parsear(
    await _api.get('/negocio/vacantes/${_seg(slug)}/ranking'),
    Ranking.fromJson,
  );

  @override
  Future<Resultado<Sucursales>> sucursales() async =>
      parsear(await _api.get('/negocio/sucursales'), Sucursales.fromJson);

  @override
  Future<Resultado<FichaCandidato>> candidato(String postulacionId) async =>
      parsear(
        await _api.get('/negocio/postulaciones/${_seg(postulacionId)}'),
        FichaCandidato.fromJson,
      );
}
