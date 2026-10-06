import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/util/resultado.dart';

import '../../../apoyo/datos.dart';
import '../../../apoyo/repositorio_falso.dart';

void main() {
  test(
    'el provider entrega el valor y conserva el ErrorApi al fallar',
    () async {
      final repo = RepositorioFalso();
      final c = ProviderContainer(
        overrides: [repositorioProvider.overrideWithValue(repo)],
        retry: sinReintentos,
      );
      addTearDown(c.dispose);
      // Riverpod 3 desecha un provider sin oyentes; en la app siempre hay un
      // widget escuchando. Aquí lo escucha la prueba.
      final sub = c.listen(yoProvider, (_, _) {});
      addTearDown(sub.close);
      expect((await c.read(yoProvider.future)).nombre, yoNegocio.nombre);
      repo.yoR = const Falla(Servidor());
      // `invalidate` es perezoso en Riverpod 3; `refresh` invalida y lee.
      await expectLater(c.refresh(yoProvider.future), throwsA(isA<Servidor>()));
    },
  );
}
