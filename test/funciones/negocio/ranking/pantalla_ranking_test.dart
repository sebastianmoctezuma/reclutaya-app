import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/ranking.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/funciones/negocio/ranking/pantalla_ranking.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/tema/tema.dart';
import 'package:reclutaya_app/nucleo/util/resultado.dart';

import '../../../apoyo/repositorio_falso.dart';
import '../../../apoyo/telefono.dart';

Widget _app(RepositorioFalso r) => ProviderScope(
  overrides: [repositorioProvider.overrideWithValue(r)],
  retry: sinReintentos,
  child: MaterialApp(
    theme: temaClaro(),
    home: const PantallaRanking(slug: 'mesero-abc'),
  ),
);

void main() {
  setUpAll(() => initializeDateFormatting('es_MX'));

  testWidgets('pinta las filas visibles y la bloqueada', (tester) async {
    comoTelefono(tester);
    await tester.pumpWidget(_app(RepositorioFalso()));
    await tester.pumpAndSettle();
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Luis Pérez'), findsOneWidget);
    expect(find.text('Marta Ruiz'), findsOneWidget);
    expect(find.textContaining('Bloqueado'), findsOneWidget);
    expect(find.textContaining('13 candidatos'), findsOneWidget);
  });

  testWidgets('sin ranking: manda a la web', (tester) async {
    comoTelefono(tester);
    final r = RepositorioFalso()
      ..rankingR = const Exito(Ranking(visibles: [], total: 0));
    await tester.pumpWidget(_app(r));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Genera el ranking desde la web'),
      findsOneWidget,
    );
  });

  testWidgets('con error, Reintentar', (tester) async {
    comoTelefono(tester);
    final r = RepositorioFalso()..rankingR = const Falla(Servidor());
    await tester.pumpWidget(_app(r));
    await tester.pumpAndSettle();
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
