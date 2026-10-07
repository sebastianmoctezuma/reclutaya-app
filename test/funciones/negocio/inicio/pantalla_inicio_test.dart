import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/inicio.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/yo.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/funciones/negocio/inicio/pantalla_inicio.dart';
import 'package:reclutaya_app/nucleo/almacen/almacen_local.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/tema/tema.dart';
import 'package:reclutaya_app/nucleo/ui/estados.dart';
import 'package:reclutaya_app/nucleo/util/resultado.dart';

import '../../../apoyo/datos.dart';
import '../../../apoyo/repositorio_falso.dart';
import '../../../apoyo/telefono.dart';

Widget _app(RepositorioFalso r, {AlmacenMemoria? almacen}) => ProviderScope(
  overrides: [
    repositorioProvider.overrideWithValue(r),
    almacenLocalProvider.overrideWithValue(almacen ?? AlmacenMemoria()),
  ],
  retry: sinReintentos,
  child: MaterialApp(theme: temaClaro(), home: const PantallaInicio()),
);

final Finder _lista = find.byType(CustomScrollView);

Future<void> _bajarHasta(WidgetTester tester, Finder f) =>
    tester.dragUntilVisible(f, _lista, const Offset(0, -300));

void main() {
  testWidgets(
    'con el servidor nuevo: todas las secciones del Inicio web, sin acciones',
    (tester) async {
      comoTelefono(tester);
      final r = RepositorioFalso()..inicioR = const Exito(inicioCompleto);
      await tester.pumpWidget(_app(r));
      await tester.pumpAndSettle();
      expect(find.text('Grupo Yaqui'), findsOneWidget);
      expect(
        find.text('Restaurante o bar · Reynosa, Tamaulipas'),
        findsOneWidget,
      );
      expect(find.text('Vacantes abiertas'), findsOneWidget);
      expect(find.text('∞'), findsOneWidget);
      for (final titulo in [
        'Consumo de contactos por sucursal',
        'Tus sucursales',
        'Pendientes',
        'Tu proceso · 30 días',
        'Actividad reciente',
        'Vacantes en curso',
      ]) {
        await _bajarHasta(tester, find.text(titulo));
        expect(find.text(titulo), findsOneWidget, reason: titulo);
      }
      await _bajarHasta(tester, find.text('Revisar candidatos'));
      expect(find.text('Revisar candidatos'), findsOneWidget);
      for (final accion in [
        'Crear vacante',
        'Generar',
        'Agregar sucursal',
        'Abrir',
      ]) {
        expect(
          find.text(accion),
          findsNothing,
          reason: 'es pura vista: $accion',
        );
      }
    },
  );

  testWidgets('el filtro por sucursal cambia los indicadores', (tester) async {
    comoTelefono(tester);
    final r = RepositorioFalso()..inicioR = const Exito(inicioCompleto);
    await tester.pumpWidget(_app(r));
    await tester.pumpAndSettle();
    await _bajarHasta(tester, find.text('Todas las sucursales'));
    expect(find.text('3.2'), findsOneWidget);
    await tester.tap(find.text('Todas las sucursales'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yaqui Parrilla Sonorense').last);
    await tester.pumpAndSettle();
    expect(find.text('2.1'), findsOneWidget);
  });

  testWidgets('fuera de Pro no aparecen pendientes, proceso ni actividad', (
    tester,
  ) async {
    comoTelefono(tester);
    final r = RepositorioFalso()
      ..inicioR = Exito(
        Inicio(
          indicadores: inicioCompleto.indicadores,
          negocio: inicioCompleto.negocio,
          resumen: inicioCompleto.resumen,
          vacantes: inicioCompleto.vacantes,
        ),
      );
    await tester.pumpWidget(_app(r));
    await tester.pumpAndSettle();
    await _bajarHasta(tester, find.text('Vacantes en curso'));
    expect(find.text('Pendientes'), findsNothing);
    expect(find.text('Tu proceso · 30 días'), findsNothing);
    expect(find.text('Actividad reciente'), findsNothing);
    expect(find.text('Consumo de contactos por sucursal'), findsNothing);
  });

  testWidgets(
    'con el servidor anterior sigue funcionando (indicadores y saldo)',
    (tester) async {
      comoTelefono(tester);
      await tester.pumpWidget(_app(RepositorioFalso()));
      await tester.pumpAndSettle();
      expect(find.text(yoNegocio.empresa!.nombre), findsOneWidget);
      expect(find.text('Velocidad de postulaciones'), findsOneWidget);
      expect(find.text('Contactos disponibles'), findsOneWidget);
      await _bajarHasta(tester, find.text(vacanteActiva.puesto));
      expect(find.text(vacanteActiva.puesto), findsOneWidget);
    },
  );

  testWidgets('sin saldo no aparece «Contactos disponibles»', (tester) async {
    comoTelefono(tester);
    final r = RepositorioFalso()
      ..inicioR = const Exito(
        Inicio(indicadores: Indicadores(velocidad: 1, respuestaPct: 50)),
      );
    await tester.pumpWidget(_app(r));
    await tester.pumpAndSettle();
    expect(find.text('Aún no pides requisitos'), findsOneWidget);
    expect(find.text('Contactos disponibles'), findsNothing);
  });

  testWidgets('con error muestra Reintentar y vuelve a pedir', (tester) async {
    final r = RepositorioFalso()..inicioR = const Falla(Servidor());
    await tester.pumpWidget(_app(r));
    await tester.pumpAndSettle();
    expect(find.text('Reintentar'), findsOneWidget);
    r.inicioR = const Exito(inicioEjemplo);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Velocidad de postulaciones'), findsOneWidget);
  });

  testWidgets('sin red al refrescar: conserva lo anterior y pone el banner', (
    tester,
  ) async {
    comoTelefono(tester);
    final r = RepositorioFalso();
    await tester.pumpWidget(_app(r));
    await tester.pumpAndSettle();
    r.inicioR = const Falla(SinRed());
    await tester.drag(_lista, const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(find.text('Velocidad de postulaciones'), findsOneWidget);
    expect(find.byType(BannerSinRed), findsOneWidget);
  });

  testWidgets('con letra grande (1.5×) nada se desborda', (tester) async {
    comoTelefono(tester);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: _app(RepositorioFalso()..inicioR = const Exito(inicioCompleto)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Vacantes abiertas'), findsOneWidget);
  });

  testWidgets('sin vacantes activas invita a publicar desde la web', (
    tester,
  ) async {
    comoTelefono(tester);
    final r = RepositorioFalso()..activasR = const Exito([]);
    await tester.pumpWidget(_app(r));
    await tester.pumpAndSettle();
    await _bajarHasta(
      tester,
      find.textContaining('Publica tu primera vacante'),
    );
    expect(find.textContaining('Publica tu primera vacante'), findsOneWidget);
  });

  testWidgets('el encabezado muestra el negocio, sin saludo', (tester) async {
    comoTelefono(tester);
    final r = RepositorioFalso()
      ..yoR = const Exito(
        Yo(
          tipo: 'negocio',
          iniciales: 'PC',
          veDinero: true,
          empresa: EmpresaYo(nombre: 'Punto Chilango'),
        ),
      );
    await tester.pumpWidget(_app(r));
    await tester.pumpAndSettle();
    expect(find.text('Punto Chilango'), findsOneWidget);
    expect(find.textContaining('Hola'), findsNothing);
  });

  testWidgets(
    'la campana cuenta lo nuevo y, al abrirla, lo muestra y lo da por visto',
    (tester) async {
      comoTelefono(tester);
      final almacen = AlmacenMemoria();
      await tester.pumpWidget(_app(RepositorioFalso(), almacen: almacen));
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget, reason: 'insignia con las nuevas');
      await tester.tap(find.bySemanticsLabel(RegExp('Novedades')));
      await tester.pumpAndSettle();
      expect(find.text('Novedades'), findsOneWidget);
      expect(find.text('Luis P. mandó su video'), findsOneWidget);
      expect(find.text('Ana P. se postuló'), findsOneWidget);
      expect(almacen.datos.values, isNotEmpty, reason: 'guarda el visto hasta');
    },
  );
}
