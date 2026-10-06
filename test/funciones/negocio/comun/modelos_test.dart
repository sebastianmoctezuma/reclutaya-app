import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/ranking.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/vacantes.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/yo.dart';
import 'package:reclutaya_app/funciones/negocio/comun/parsear.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/util/resultado.dart';

void main() {
  test('Yo de negocio y de candidato (campos desconocidos se ignoran)', () {
    final n = Yo.fromJson({
      'tipo': 'negocio',
      'nombre': 'Antonio',
      'iniciales': 'AP',
      'rol': 'owner',
      'veDinero': true,
      'empresa': {'nombre': 'Tacos', 'logoUrl': null, 'logoFit': 'cover'},
      'variasSucursales': false,
      'campoNuevo': 1,
    });
    expect(n.empresa!.nombre, 'Tacos');
    expect(n.esNegocio, isTrue);
    final c = Yo.fromJson({
      'tipo': 'candidato',
      'nombre': 'Ana',
      'iniciales': 'AP',
      'correo': 'a@b.c',
    });
    expect(c.empresa, isNull);
    expect(c.veDinero, isFalse);
  });

  test(
    'una fila del ranking sin contactar llega enmascarada y así se queda',
    () {
      final f = FilaRanking.fromJson({
        'postulacionId': 'p1',
        'ranking': 1,
        'nombre': 'Ana',
        'apellidoOculto': true,
        'whatsapp': null,
        'score': 87,
        'testEstado': 'NO_ENVIADA',
        'requisitosIncumplidos': 1,
        'requisitosTotal': 4,
      });
      expect(f.whatsapp, isNull);
      expect(f.apellidoOculto, isTrue);
      expect(f.contactado, isFalse);
      expect(f.score, 87);
    },
  );

  test('parsear devuelve respuestaInvalida si falta un campo obligatorio', () {
    final r = parsear(
      const Exito(<String, dynamic>{'id': 'v1'}),
      VacanteResumen.fromJson,
    );
    expect(r, isA<Falla<VacanteResumen>>());
    expect((r as Falla<VacanteResumen>).error, isA<RespuestaInvalida>());
  });

  test('parsearLista lee items y tolera cursor null', () {
    final r = parsearLista(
      const Exito(<String, dynamic>{
        'items': [
          {
            'id': 'v1',
            'puesto': 'Mesero',
            'estado': 'ACTIVA',
            'slug': 'mesero',
            'candidatos': 3,
            'sinRankear': 0,
          },
        ],
        'cursor': null,
      }),
      VacanteResumen.fromJson,
    );
    expect((r as Exito<List<VacanteResumen>>).valor.single.puesto, 'Mesero');
  });

  test('una Falla pasa tal cual', () {
    final r = parsear<VacanteResumen>(
      const Falla(SinRed()),
      VacanteResumen.fromJson,
    );
    expect((r as Falla<VacanteResumen>).error, isA<SinRed>());
  });

  test('un usuario sin nombre capturado (nombre: null) se lee igual', () {
    final y = Yo.fromJson({
      'tipo': 'negocio',
      'nombre': null,
      'iniciales': 'PC',
      'rol': 'owner',
      'veDinero': true,
      'empresa': {'nombre': 'Punto Chilango', 'logoUrl': null, 'logoFit': null},
      'variasSucursales': false,
    });
    expect(y.nombre, isNull);
    expect(y.empresa!.nombre, 'Punto Chilango');
  });
}
