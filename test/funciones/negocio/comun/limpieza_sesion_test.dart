import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/nucleo/almacen/almacen_local.dart';
import 'package:reclutaya_app/nucleo/sesion/providers.dart';

import '../../../apoyo/repositorio_falso.dart';
import '../../../apoyo/sesion_falsa.dart';

void main() {
  test('al cerrar sesión se olvida todo: la siguiente cuenta no ve datos de la anterior', () async {
    final repo = RepositorioFalso();
    final sesion = SesionFalsa();
    final c = ProviderContainer(
      overrides: [
        repositorioProvider.overrideWithValue(repo),
        sesionProvider.overrideWithValue(sesion),
        almacenLocalProvider.overrideWithValue(AlmacenMemoria()),
      ],
      retry: sinReintentos,
    );
    addTearDown(c.dispose);
    final guardia = c.listen(limpiezaSesionProvider, (_, _) {});
    addTearDown(guardia.close);
    final sub = c.listen(yoProvider, (_, _) {});
    addTearDown(sub.close);
    await c.read(yoProvider.future);
    expect(repo.llamadasYo, 1);
    await sesion.entrar('a', 'b');
    await sesion.salir();
    await Future<void>.delayed(Duration.zero);
    await c.read(yoProvider.future);
    expect(repo.llamadasYo, 2, reason: 'tras salir se vuelve a pedir');
  });

  test('al ENTRAR con otra cuenta se vuelve a pedir todo (nada de lo pedido sin sesión)', () async {
    // El error del 6-oct: al salir, la pantalla aún montada volvía a pedir /yo SIN
    // sesión; ese «sesión terminó» (o los datos viejos) se quedaba guardado y la
    // cuenta siguiente lo heredaba.
    final repo = RepositorioFalso();
    final sesion = SesionFalsa();
    final c = ProviderContainer(
      overrides: [
        repositorioProvider.overrideWithValue(repo),
        sesionProvider.overrideWithValue(sesion),
        almacenLocalProvider.overrideWithValue(AlmacenMemoria()),
      ],
      retry: sinReintentos,
    );
    addTearDown(c.dispose);
    final guardia = c.listen(limpiezaSesionProvider, (_, _) {});
    addTearDown(guardia.close);
    final sub = c.listen(yoProvider, (_, _) {});
    addTearDown(sub.close);
    await sesion.entrar('a', 'b');
    await c.read(yoProvider.future);
    await sesion.salir();
    await Future<void>.delayed(Duration.zero);
    await c.read(yoProvider.future);
    final antes = repo.llamadasYo;
    await sesion.entrar('c', 'd');
    await Future<void>.delayed(Duration.zero);
    await c.read(yoProvider.future);
    expect(
      repo.llamadasYo,
      antes + 1,
      reason: 'la cuenta nueva pide su propio /yo',
    );
  });

  test('si la sesión venció, el aviso de Entrar lo dice', () async {
    final sesion = SesionFalsa();
    final c = ProviderContainer(
      overrides: [
        repositorioProvider.overrideWithValue(RepositorioFalso()),
        sesionProvider.overrideWithValue(sesion),
        almacenLocalProvider.overrideWithValue(AlmacenMemoria()),
      ],
      retry: sinReintentos,
    );
    addTearDown(c.dispose);
    final guardia = c.listen(limpiezaSesionProvider, (_, _) {});
    addTearDown(guardia.close);
    await sesion.entrar('a', 'b');
    await sesion.sesionVencida();
    await Future<void>.delayed(Duration.zero);
    expect(c.read(avisoAccesoProvider), 'Tu sesión terminó. Vuelve a entrar.');
  });

  test(
    'las fichas se sueltan sin oyentes: al volver se piden de nuevo',
    () async {
      final repo = RepositorioFalso();
      final c = ProviderContainer(
        overrides: [repositorioProvider.overrideWithValue(repo)],
        retry: sinReintentos,
      );
      addTearDown(c.dispose);
      var sub = c.listen(candidatoProvider('p1'), (_, _) {});
      await c.read(candidatoProvider('p1').future);
      sub.close();
      await Future<void>.delayed(Duration.zero);
      sub = c.listen(candidatoProvider('p1'), (_, _) {});
      addTearDown(sub.close);
      await c.read(candidatoProvider('p1').future);
      expect(repo.llamadasCandidato, 2);
    },
  );
}
