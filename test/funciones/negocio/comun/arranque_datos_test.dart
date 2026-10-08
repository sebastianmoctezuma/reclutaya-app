import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/util/resultado.dart';

import '../../../apoyo/repositorio_falso.dart';

/// Al abrir la app con sesión (8-oct): mientras se confirma quién es, ya se piden el
/// Inicio y la campana, y el Inicio usa ese MISMO /yo (antes se pedía dos veces y el
/// Inicio esperaba a que terminara el arranque).
void main() {
  test('pide /yo una vez y, a la vez, el Inicio y la campana', () async {
    final repo = RepositorioFalso()..demora = const Duration(milliseconds: 20);
    final c = ProviderContainer(
      overrides: [repositorioProvider.overrideWithValue(repo)],
      retry: sinReintentos,
    );
    addTearDown(c.dispose);
    final yo = await yoAlArrancar(c.read);
    expect(yo, isNotNull);
    expect(repo.llamadasInicio, 1, reason: 'el Inicio sale junto con /yo');
    await c.read(yoProvider.future);
    await c.read(inicioProvider.future);
    expect(repo.llamadasYo, 1, reason: 'el Inicio no repite /yo');
    expect(repo.llamadasInicio, 1);
  });

  test(
    'si /yo falla devuelve null (el arranque decide igual que antes)',
    () async {
      final repo = RepositorioFalso()..yoR = const Falla(Servidor());
      final c = ProviderContainer(
        overrides: [repositorioProvider.overrideWithValue(repo)],
        retry: sinReintentos,
      );
      addTearDown(c.dispose);
      expect(await yoAlArrancar(c.read), isNull);
    },
  );
}
