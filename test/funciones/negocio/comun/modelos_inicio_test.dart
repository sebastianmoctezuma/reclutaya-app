import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/inicio.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/sucursales.dart';

const _ind = <String, Object>{
  'velocidad': 3.2,
  'velocidadDelta': -36,
  'cumplenPct': 80,
  'cumplenN': 12,
  'cumplenTotal': 15,
  'cumplenDelta': -4,
  'respuestaPct': 49,
  'respuestaDelta': -5,
  'tiempoDias': 60,
  'tiempoDelta': 0,
};

void main() {
  test(
    'el Inicio de la primera versión (sin campos nuevos) se sigue leyendo',
    () {
      final i = Inicio.fromJson({'indicadores': _ind, 'saldo': null});
      expect(i.negocio, isNull);
      expect(i.resumen, isNull);
      expect(i.sucursales, isNull);
      expect(i.pendientes, isNull);
    },
  );

  test('el Inicio completo se lee entero', () {
    final i = Inicio.fromJson({
      'indicadores': _ind,
      'saldo': {'plan': 0, 'extra': 5, 'total': 5},
      'negocio': {
        'nombre': 'Grupo Yaqui',
        'meta': 'Restaurante o bar · Reynosa, Tamaulipas',
        'logoUrl': null,
        'logoFit': 'cover',
      },
      'resumen': {
        'vacantesAbiertas': 15,
        'candidatosNuevos': 3,
        'contactos': null,
        'ilimitada': true,
        'contratacionesMes': 1,
      },
      'indicadoresPorSucursal': {'s1': _ind},
      'sucursales': [
        {
          'id': 's1',
          'nombre': 'Yaqui',
          'colorIdx': 0,
          'imagenUrl': null,
          'principal': true,
          'vacantesActivas': 12,
          'candidatosSemana': 9,
          'gastados': 285,
          'sinRanking': 3,
        },
      ],
      'consumo': {'resto': null, 'disponibles': null},
      'pendientes': [
        {
          'id': 'r',
          'tipo': 'ranking',
          'titulo': 'Supervisor',
          'sub': '1 candidato sin ranking',
          'slug': 'sup',
        },
        {
          'id': 's',
          'tipo': 'solicitud',
          'titulo': 'Ana pidió',
          'sub': 'x',
          'slug': null,
        },
      ],
      'proceso': {
        'total': {
          'postulaciones': 96,
          'cumplenRequisitos': 12,
          'conRequisitos': 15,
          'contactados': 72,
          'contratados': 1,
        },
        'porSucursal': null,
      },
      'actividad': [
        {
          'postulacionId': 'p',
          'tipo': 'documento',
          'candidato': 'Lizeth',
          'accion': 'envió su documento',
          'puesto': 'Hostess',
          'slug': 'hostess',
          'sucursalId': 's1',
          'sucursal': 'Yaqui',
          'hace': 'hace 1 día',
        },
      ],
      'vacantes': [
        {
          'id': 'v1',
          'puesto': 'Cocinero/a',
          'estado': 'ACTIVA',
          'slug': 'cocinero',
          'candidatos': 1,
          'sinRankear': 0,
          'siguientePaso': 'Revisar candidatos',
        },
      ],
    });
    expect(i.negocio!.meta, 'Restaurante o bar · Reynosa, Tamaulipas');
    expect(i.resumen!.ilimitada, isTrue);
    expect(i.resumen!.contactos, isNull);
    expect(i.indicadoresPorSucursal!['s1']!.velocidad, 3.2);
    expect(i.sucursales!.single.gastados, 285);
    expect(i.pendientes!.last.slug, isNull);
    expect(i.proceso!.total.contactados, 72);
    expect(i.actividad!.single.accion, 'envió su documento');
    expect(i.vacantes!.single.siguientePaso, 'Revisar candidatos');
  });

  test('sucursales: multisucursal con sus vacantes', () {
    final s = Sucursales.fromJson({
      'multisucursal': true,
      'items': [
        {
          'id': 's1',
          'nombre': 'Yaqui',
          'colorIdx': 0,
          'imagenUrl': null,
          'principal': true,
          'vacantesActivas': 1,
          'vacantes': [
            {
              'slug': 'c',
              'puesto': 'Cocinero',
              'estado': 'ACTIVA',
              'candidatos': 1,
              'sinRankear': 0,
            },
          ],
        },
      ],
      'cursor': null,
    });
    expect(s.multisucursal, isTrue);
    expect(s.items.single.vacantes.single.puesto, 'Cocinero');
  });
}
