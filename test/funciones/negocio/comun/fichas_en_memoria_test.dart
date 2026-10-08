import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';

import '../../../apoyo/repositorio_falso.dart';

/// Volver a una ficha recién vista (de un candidato al ranking, o a la misma
/// vacante) no debe esperar otra vez al servidor (8-oct): la ficha se queda unos
/// minutos en memoria. Y al cambiar de cuenta se olvida igual que todo lo demás.
void main() {
  ProviderContainer contenedor(RepositorioFalso repo) {
    final c = ProviderContainer(
      overrides: [repositorioProvider.overrideWithValue(repo)],
      retry: sinReintentos,
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<void> abrirYSalir(
    ProviderContainer c,
    ProviderListenable<Object?> p,
    Future<Object?> Function() esperar,
  ) async {
    final sub = c.listen(p, (_, _) {});
    await esperar();
    sub.close();
    // Riverpod suelta lo que nadie escucha al terminar la vuelta del evento.
    await Future<void>.delayed(Duration.zero);
  }

  test(
    'volver a la vacante, a su ranking y al candidato no los pide otra vez',
    () async {
      final repo = RepositorioFalso();
      final c = contenedor(repo);
      for (var i = 0; i < 2; i++) {
        await abrirYSalir(
          c,
          vacanteProvider('mesero'),
          () => c.read(vacanteProvider('mesero').future),
        );
        await abrirYSalir(
          c,
          rankingProvider('mesero'),
          () => c.read(rankingProvider('mesero').future),
        );
        await abrirYSalir(
          c,
          candidatoProvider('p1'),
          () => c.read(candidatoProvider('p1').future),
        );
      }
      expect(repo.llamadasVacante, 1);
      expect(repo.llamadasRanking, 1);
      expect(repo.llamadasCandidato, 1);
    },
  );

  test('al cambiar de cuenta las fichas en memoria se olvidan', () async {
    final repo = RepositorioFalso();
    final c = contenedor(repo);
    await abrirYSalir(
      c,
      vacanteProvider('mesero'),
      () => c.read(vacanteProvider('mesero').future),
    );
    c.read(Provider(limpiarDatosDeCuenta));
    await abrirYSalir(
      c,
      vacanteProvider('mesero'),
      () => c.read(vacanteProvider('mesero').future),
    );
    expect(repo.llamadasVacante, 2);
  });
}
