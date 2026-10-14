import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/sucursales.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/yo.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/funciones/negocio/sucursales/pantalla_sucursales.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/tema/tema.dart';
import 'package:reclutaya_app/nucleo/util/resultado.dart';

import '../../../apoyo/datos.dart';
import '../../../apoyo/repositorio_falso.dart';
import '../../../apoyo/telefono.dart';

const _yoMulti = Yo(
  tipo: 'negocio',
  nombre: 'Antonio',
  iniciales: 'AP',
  rol: 'owner',
  veDinero: true,
  variasSucursales: true,
  empresa: EmpresaYo(nombre: 'Grupo Yaqui'),
);

Future<void> _abrir(
  WidgetTester tester, {
  Resultado<Sucursales> sucursales = const Exito(sucursalesMulti),
  String? abrirSucursal,
}) async {
  comoTelefono(tester);
  final r = RepositorioFalso()
    ..yoR = const Exito(_yoMulti)
    ..sucursalesR = sucursales;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [repositorioProvider.overrideWithValue(r)],
      retry: sinReintentos,
      child: MaterialApp(
        theme: temaClaro(),
        home: PantallaSucursales(abrirSucursal: abrirSucursal, visita: '1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('es_MX'));

  testWidgets('tarjetas como en la web, sin acciones', (tester) async {
    await _abrir(tester);
    expect(find.text('Sucursales'), findsWidgets);
    expect(find.text('Yaqui Parrilla Sonorense'), findsOneWidget);
    expect(find.text('Principal'), findsOneWidget);
    expect(find.text('Privada Ninguno 447, Reynosa'), findsOneWidget);
    expect(find.text('1 vacante · 1 miembro'), findsOneWidget);
    expect(find.text('ST'), findsWidgets);
    expect(find.text('Altomar'), findsOneWidget);
    expect(find.text('Tu equipo'), findsOneWidget);
    expect(find.text('2 personas'), findsOneWidget);
    expect(find.text('2 candidatos nuevos esta semana'), findsOneWidget);
    for (final accion in ['Crear sucursal', 'Invitar', 'Agregar sucursal']) {
      expect(find.text(accion), findsNothing, reason: accion);
    }
  });

  testWidgets(
    'tocar una sucursal abre su ventana: números y vacantes, sin acciones',
    (tester) async {
      await _abrir(tester);
      await tester.tap(find.text('Altomar'));
      await tester.pumpAndSettle();
      expect(find.text('1 vacante en esta sucursal'), findsOneWidget);
      expect(find.text('Nuevos esta semana'), findsOneWidget);
      expect(find.text('Contactos usados'), findsOneWidget);
      expect(find.text('Mesero'), findsOneWidget);
      expect(find.text('2 nuevos esta semana'), findsOneWidget);
      for (final accion in ['Crear vacante', 'Finalizar', 'Administrar']) {
        expect(find.text(accion), findsNothing, reason: accion);
      }
    },
  );

  testWidgets('Ver equipo: el dueño y cada miembro con su rol', (tester) async {
    await _abrir(tester);
    await tester.tap(find.text('Tu equipo'));
    await tester.pumpAndSettle();
    expect(find.text('Antonio Pimentel'), findsOneWidget);
    expect(find.text('Dueño'), findsOneWidget);
    expect(find.text('Miembro'), findsOneWidget);
    expect(find.text('Invitar'), findsNothing);
  });

  testWidgets('llegar desde una sucursal del Inicio abre su ventana', (
    tester,
  ) async {
    final id = sucursalesMulti.items
        .firstWhere((s) => s.nombre == 'Altomar')
        .id;
    await _abrir(tester, abrirSucursal: id);
    expect(find.text('1 vacante en esta sucursal'), findsOneWidget);
  });

  testWidgets('con un servidor anterior, un aviso en vez de la lista', (
    tester,
  ) async {
    await _abrir(tester, sucursales: const Falla(NoEncontrado()));
    expect(find.text('Aún no hay sucursales'), findsOneWidget);
  });
}
