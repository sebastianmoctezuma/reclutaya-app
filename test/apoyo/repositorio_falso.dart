import 'package:reclutaya_app/funciones/negocio/comun/modelos/ficha_candidato.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/inicio.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/novedades.dart';
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
  Resultado<Novedades> novedadesR = Exito(
    Novedades(
      hasta: DateTime.utc(2026, 10, 6, 18),
      items: [
        Novedad(
          tipo: 'video',
          at: DateTime.utc(2026, 10, 6, 17),
          titulo: 'Video recibido',
          candidato: 'Luis P.',
          accion: 'envió su video',
          puesto: 'Mesero',
          sucursal: 'Centro',
          slug: 'mesero-abc',
          postulacionId: 'p2',
        ),
        Novedad(
          tipo: 'postulacion',
          at: DateTime.utc(2026, 10, 6, 12),
          titulo: 'Nuevo candidato',
          candidato: 'Ana P.',
          accion: 'se postuló',
          puesto: 'Mesero',
          sucursal: 'Centro',
          slug: 'mesero-abc',
          postulacionId: 'p1',
        ),
      ],
    ),
  );
  final registros = <(String, String, bool)>[];
  final cambios = <(String, bool)>[];
  final bajas = <String>[];

  /// Tras Google o Apple: true = el servidor dijo que ese acceso no tiene cuenta.
  Resultado<bool> sinCuentaR = const Exito(false);
  int llamadasSinCuenta = 0;
  int llamadasCandidato = 0;
  int llamadasVacante = 0;
  int llamadasRanking = 0;
  int llamadasYo = 0;
  int llamadasInicio = 0;
  Duration demora = Duration.zero;

  Future<T> _r<T>(T v) async {
    if (demora > Duration.zero) await Future<void>.delayed(demora);
    return v;
  }

  @override
  Future<Resultado<bool>> accesoSinCuenta() {
    llamadasSinCuenta++;
    return _r(sinCuentaR);
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
  Future<Resultado<VacanteFicha>> vacante(String slug) {
    llamadasVacante++;
    return _r(vacanteR);
  }

  @override
  Future<Resultado<Ranking>> ranking(String slug) {
    llamadasRanking++;
    return _r(rankingR);
  }

  @override
  Future<Resultado<Sucursales>> sucursales() => _r(sucursalesR);

  @override
  Future<Resultado<Novedades>> novedades({DateTime? desde}) => _r(novedadesR);

  @override
  Future<Resultado<FichaCandidato>> candidato(String postulacionId) {
    llamadasCandidato++;
    return _r(candidatoR);
  }

  @override
  Future<Resultado<void>> registrarDispositivo({
    required String token,
    required String plataforma,
    required bool activos,
  }) async {
    registros.add((token, plataforma, activos));
    return const Exito(null);
  }

  @override
  Future<Resultado<void>> cambiarAvisos({
    required String token,
    required String plataforma,
    required bool activos,
  }) async {
    cambios.add((token, activos));
    return const Exito(null);
  }

  @override
  Future<Resultado<void>> bajaDispositivo({
    required String token,
    required String plataforma,
  }) async {
    bajas.add(token);
    return const Exito(null);
  }
}
