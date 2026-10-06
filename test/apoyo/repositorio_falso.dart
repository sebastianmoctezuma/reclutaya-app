import 'package:reclutaya_app/funciones/negocio/comun/modelos/ficha_candidato.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/inicio.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/ranking.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/sucursales.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/vacantes.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/yo.dart';
import 'package:reclutaya_app/funciones/negocio/comun/repositorio_negocio.dart';
import 'package:reclutaya_app/nucleo/util/resultado.dart';

import 'datos.dart';

/// El servidor de mentira de las pantallas: cada método contesta lo que se
/// le ponga en su campo `…R`, con una demora opcional para probar «cargando».
class RepositorioFalso implements RepositorioNegocio {
  Resultado<Yo> yoR = const Exito(yoNegocio);
  Resultado<Inicio> inicioR = const Exito(inicioEjemplo);
  Resultado<List<VacanteResumen>> activasR = const Exito([vacanteActiva]);
  Resultado<List<VacanteCerrada>> cerradasR = Exito([vacanteCerradaEjemplo]);
  Resultado<VacanteFicha> vacanteR = const Exito(fichaVacante);
  Resultado<Ranking> rankingR = const Exito(rankingEjemplo);
  Resultado<FichaCandidato> candidatoR = const Exito(fichaCandidatoContactada);
  Resultado<Sucursales> sucursalesR = const Exito(
    Sucursales(multisucursal: false),
  );
  int llamadasCandidato = 0;
  int llamadasYo = 0;
  int llamadasInicio = 0;
  Duration demora = Duration.zero;

  Future<T> _r<T>(T v) async {
    if (demora > Duration.zero) await Future<void>.delayed(demora);
    return v;
  }

  @override
  Future<Resultado<Yo>> yo() {
    llamadasYo++;
    return _r(yoR);
  }

  @override
  Future<Resultado<Inicio>> inicio() {
    llamadasInicio++;
    return _r(inicioR);
  }

  @override
  Future<Resultado<List<VacanteResumen>>> vacantesActivas() => _r(activasR);

  @override
  Future<Resultado<List<VacanteCerrada>>> vacantesCerradas() => _r(cerradasR);

  @override
  Future<Resultado<VacanteFicha>> vacante(String slug) => _r(vacanteR);

  @override
  Future<Resultado<Ranking>> ranking(String slug) => _r(rankingR);

  @override
  Future<Resultado<Sucursales>> sucursales() => _r(sucursalesR);

  @override
  Future<Resultado<FichaCandidato>> candidato(String postulacionId) {
    llamadasCandidato++;
    return _r(candidatoR);
  }
}
