import 'package:reclutaya_app/funciones/negocio/comun/modelos/ficha_candidato.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/inicio.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/novedades.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/ranking.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/sucursales.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/vacantes.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/yo.dart';
import 'package:reclutaya_app/funciones/negocio/comun/parsear.dart';
import 'package:reclutaya_app/nucleo/config.dart';
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
  Future<Resultado<Novedades>> novedades({DateTime? desde});

  // API v2 (7-oct): lo ÚNICO que la app escribe — su teléfono para los avisos.
  /// Tras entrar con Google o Apple (8-oct): si ese acceso no tiene cuenta, el
  /// servidor lo borra y responde true (la app entonces cierra su sesión local).
  Future<Resultado<bool>> accesoSinCuenta();

  Future<Resultado<void>> registrarDispositivo({
    required String token,
    required String plataforma,
    required bool activos,
  });
  Future<Resultado<void>> cambiarAvisos({
    required String token,
    required String plataforma,
    required bool activos,
  });
  Future<Resultado<void>> bajaDispositivo({
    required String token,
    required String plataforma,
  });
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

  String get _dispositivos => '${Config.apiBaseV2}/dispositivos';

  Resultado<void> _sinDatos(Resultado<Map<String, dynamic>> r) => switch (r) {
    Exito() => const Exito(null),
    Falla(:final error) => Falla(error),
  };

  @override
  Future<Resultado<bool>> accesoSinCuenta() async {
    final r = await _api.escribir(
      'POST',
      '${Config.apiBaseV2}/acceso/sin-cuenta',
      const {},
    );
    return switch (r) {
      Exito(:final valor) => Exito(valor['borrado'] == true),
      Falla(:final error) => Falla(error),
    };
  }

  @override
  Future<Resultado<void>> registrarDispositivo({
    required String token,
    required String plataforma,
    required bool activos,
  }) async => _sinDatos(
    await _api.escribir('POST', _dispositivos, {
      'token': token,
      'plataforma': plataforma,
      'activo': activos,
    }),
  );

  @override
  Future<Resultado<void>> cambiarAvisos({
    required String token,
    required String plataforma,
    required bool activos,
  }) async => _sinDatos(
    await _api.escribir('PATCH', _dispositivos, {
      'token': token,
      'plataforma': plataforma,
      'activo': activos,
    }),
  );

  @override
  Future<Resultado<void>> bajaDispositivo({
    required String token,
    required String plataforma,
  }) async => _sinDatos(
    await _api.escribir('DELETE', _dispositivos, {
      'token': token,
      'plataforma': plataforma,
    }),
  );

  @override
  Future<Resultado<Novedades>> novedades({DateTime? desde}) async => parsear(
    await _api.get(
      '/negocio/novedades',
      query: {if (desde != null) 'desde': desde.toUtc().toIso8601String()},
    ),
    Novedades.fromJson,
  );

  @override
  Future<Resultado<FichaCandidato>> candidato(String postulacionId) async =>
      parsear(
        await _api.get('/negocio/postulaciones/${_seg(postulacionId)}'),
        FichaCandidato.fromJson,
      );
}
