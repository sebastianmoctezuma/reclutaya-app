import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/ranking.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/vacantes.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/funciones/negocio/vacantes/pantalla_vacante.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/tema/tema.dart';
import 'package:reclutaya_app/nucleo/util/resultado.dart';

import '../../../apoyo/datos.dart';
import '../../../apoyo/repositorio_falso.dart';
import '../../../apoyo/telefono.dart';

Widget _app(RepositorioFalso r) => ProviderScope(
  overrides: [repositorioProvider.overrideWithValue(r)],
  retry: sinReintentos,
  child: MaterialApp(
    theme: temaClaro(),
    home: const PantallaVacante(slug: 'mesero-abc'),
  ),
);

void main() {
  setUpAll(() => initializeDateFormatting('es_MX'));

  final lista = find.byType(CustomScrollView);

  testWidgets(
    'la ficha y, debajo, el ranking: sin botón aparte y sin acciones',
    (tester) async {
      comoTelefono(tester);
      await tester.pumpWidget(_app(RepositorioFalso()));
      await tester.pumpAndSettle();
      expect(find.text(fichaVacante.puesto), findsWidgets);
      expect(find.text('Activa'), findsOneWidget);
      expect(find.text('Matutino'), findsOneWidget);
      expect(find.text('Reynosa'), findsOneWidget);
      await tester.dragUntilVisible(
        find.text('Ana'),
        lista,
        const Offset(0, -300),
      );
      expect(find.text('Ana'), findsOneWidget);
      await tester.dragUntilVisible(
        find.text('Marta Ruiz'),
        lista,
        const Offset(0, -300),
      );
      expect(find.text('Marta Ruiz'), findsOneWidget);
      for (final accion in [
        'Ver ranking',
        'Finalizar',
        'Administrar',
        'Contactar',
        'Generar ranking',
      ]) {
        expect(
          find.text(accion),
          findsNothing,
          reason: 'es pura vista: $accion',
        );
      }
    },
  );

  testWidgets('filtrar por material recibido deja solo a quien lo entregó', (
    tester,
  ) async {
    comoTelefono(tester);
    await tester.pumpWidget(_app(RepositorioFalso()));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('Video · 1'),
      lista,
      const Offset(0, -300),
    );
    // Los tres siempre, como en la web, con cuántos lo tienen.
    expect(find.text('Documento · 0'), findsOneWidget);
    expect(find.text('Test · 1'), findsOneWidget);
    await tester.tap(find.text('Video · 1'));
    await tester.pumpAndSettle();
    expect(find.text('Luis Pérez'), findsOneWidget);
    expect(find.text('Ana'), findsNothing);
    expect(find.text('Marta Ruiz'), findsNothing);
    await tester.tap(find.text('Video · 1'));
    await tester.pumpAndSettle();
    expect(find.text('Ana'), findsOneWidget);
    await tester.tap(find.text('Documento · 0'));
    await tester.pumpAndSettle();
    expect(find.text('Nadie con ese material todavía'), findsOneWidget);
  });

  testWidgets('la descripción va plegada y se abre al tocarla', (tester) async {
    comoTelefono(tester);
    await tester.pumpWidget(_app(RepositorioFalso()));
    await tester.pumpAndSettle();
    expect(find.text('Atender mesas en turno matutino.'), findsNothing);
    await tester.tap(find.text('Descripción de la vacante'));
    await tester.pumpAndSettle();
    expect(find.text('Atender mesas en turno matutino.'), findsOneWidget);
  });

  group('vacante en varias sucursales (14-oct)', () {
    const enGrupo = VacanteFicha(
      id: 'v1',
      puesto: 'Mesero',
      estado: 'ACTIVA',
      slug: 'mesero-abc',
      sucursal: 'Centro',
      diasParaResponder: 3,
      conteos: Conteos(
        total: 0,
        rankeados: 0,
        sinRankear: 0,
        cumplenRequisitos: 0,
      ),
      grupo: GrupoVacante(
        slug: 'mesero-grp',
        hermanas: [
          HermanaGrupo(
            slug: 'mesero-abc',
            sucursal: 'Centro',
            estado: 'ACTIVA',
            esta: true,
          ),
          HermanaGrupo(
            slug: 'mesero-def',
            sucursal: 'Norte',
            estado: 'CERRADA',
          ),
          HermanaGrupo(sucursal: 'Sur', estado: 'ACTIVA'),
        ],
      ),
    );

    testWidgets('«En N sucursales» va plegado y lista las hermanas', (
      tester,
    ) async {
      comoTelefono(tester);
      final r = RepositorioFalso()..vacanteR = const Exito(enGrupo);
      await tester.pumpWidget(_app(r));
      await tester.pumpAndSettle();
      expect(find.text('Norte'), findsNothing);
      await tester.tap(find.text('En 3 sucursales'));
      await tester.pumpAndSettle();
      expect(find.text('Esta'), findsOneWidget);
      expect(find.text('Norte'), findsOneWidget);
      expect(find.text('Cerrada'), findsOneWidget);
      expect(find.text('Sur'), findsOneWidget);
      // Solo se abre la que quien mira puede ver y no es esta.
      expect(
        find.bySemanticsLabel('Abrir la vacante de Norte'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Abrir la vacante de Sur'), findsNothing);
    });

    testWidgets('una vacante suelta no lo muestra', (tester) async {
      comoTelefono(tester);
      await tester.pumpWidget(_app(RepositorioFalso()));
      await tester.pumpAndSettle();
      expect(find.textContaining('sucursales'), findsNothing);
    });

    test('lee `grupo` del servidor; sin él, null', () {
      final base = {
        'id': 'v1',
        'puesto': 'Mesero',
        'estado': 'ACTIVA',
        'slug': 'mesero-abc',
        'diasParaResponder': 3,
        'conteos': {
          'total': 0,
          'rankeados': 0,
          'sinRankear': 0,
          'cumplenRequisitos': 0,
        },
      };
      expect(VacanteFicha.fromJson(base).grupo, isNull);
      final v = VacanteFicha.fromJson({
        ...base,
        'grupo': {
          'slug': 'mesero-grp',
          'hermanas': [
            {
              'slug': null,
              'sucursal': 'Norte',
              'estado': 'ACTIVA',
              'esta': false,
            },
          ],
        },
      });
      expect(v.grupo!.slug, 'mesero-grp');
      expect(v.grupo!.hermanas.single.slug, isNull);
      expect(v.grupo!.hermanas.single.sucursal, 'Norte');
    });
  });

  testWidgets('con candidatos pero sin ranking, lo dice', (tester) async {
    comoTelefono(tester);
    final r = RepositorioFalso()
      ..rankingR = const Exito(Ranking(total: 0, visibles: []));
    await tester.pumpWidget(_app(r));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('Aún no hay ranking'),
      lista,
      const Offset(0, -300),
    );
    expect(find.text('Aún no hay ranking'), findsOneWidget);
  });

  testWidgets('sin candidatos lo dice', (tester) async {
    comoTelefono(tester);
    final r = RepositorioFalso()
      ..vacanteR = const Exito(
        VacanteFicha(
          id: 'v9',
          puesto: 'Cajero',
          estado: 'ACTIVA',
          slug: 'cajero',
          diasParaResponder: 3,
          conteos: Conteos(
            total: 0,
            rankeados: 0,
            sinRankear: 0,
            cumplenRequisitos: 0,
          ),
        ),
      );
    await tester.pumpWidget(_app(r));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('Aún no hay candidatos'),
      lista,
      const Offset(0, -300),
    );
    expect(find.text('Aún no hay candidatos'), findsOneWidget);
    expect(find.text('Cumplen requisitos'), findsNothing);
    // Llegó sin la lista (p. ej. por un aviso): el ranking sale junto con la ficha
    // (14-oct), una sola vez, en vez de esperar a saber si hay candidatos.
    expect(r.llamadasRanking, lessThanOrEqualTo(1));
  });

  testWidgets('si ya no existe, lo dice y ofrece Volver', (tester) async {
    comoTelefono(tester);
    final r = RepositorioFalso()..vacanteR = const Falla(NoEncontrado());
    await tester.pumpWidget(_app(r));
    await tester.pumpAndSettle();
    expect(find.text('Esto ya no está disponible.'), findsOneWidget);
    expect(find.text('Volver'), findsOneWidget);
  });
}
