import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/nucleo/red/cliente_api.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/util/resultado.dart';

class _Tokens implements ProveedorToken {
  _Tokens(this.token);

  @override
  String? token;
  int renovaciones = 0;
  bool cerrada = false;

  @override
  Future<String?> renovar() async {
    renovaciones++;
    return token = 'nuevo';
  }

  @override
  Future<void> sesionVencida() async {
    cerrada = true;
  }
}

/// Un servidor de mentira: contesta en orden lo que se le encola y recuerda
/// cada petición (así se cuentan los intentos y se ve el Bearer que llegó).
class _Servidor implements HttpClientAdapter {
  final List<(int, Object)> respuestas = [];
  final List<RequestOptions> peticiones = [];

  void responde(int status, Object cuerpo) => respuestas.add((status, cuerpo));

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    peticiones.add(options);
    final (status, cuerpo) = respuestas.removeAt(0);
    if (cuerpo is DioException) throw cuerpo;
    return ResponseBody.fromString(
      jsonEncode(cuerpo),
      status,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late _Servidor servidor;
  const base = 'https://x.test/api/movil/v1';
  const sinSesion = {
    'error': {'codigo': 'no_autenticado', 'mensaje': 'x'},
  };

  setUp(() {
    servidor = _Servidor();
    dio = Dio(BaseOptions(baseUrl: base))..httpClientAdapter = servidor;
  });

  test('manda el Bearer y devuelve el JSON', () async {
    servidor.responde(200, {'tipo': 'negocio'});
    final c = ClienteApi(base: base, tokens: _Tokens('abc'), dio: dio);
    final r = await c.get('/yo');
    expect((r as Exito<Map<String, dynamic>>).valor['tipo'], 'negocio');
    expect(servidor.peticiones.single.headers['Authorization'], 'Bearer abc');
  });

  test('tras un 401 renueva y reintenta UNA vez con el token nuevo; '
      'si vuelve 401, cierra sesión y no hay tercer intento', () async {
    servidor
      ..responde(401, sinSesion)
      ..responde(401, sinSesion);
    final t = _Tokens('viejo');
    final r = await ClienteApi(base: base, tokens: t, dio: dio).get('/yo');
    expect((r as Falla<Map<String, dynamic>>).error, isA<SesionVencida>());
    expect(servidor.peticiones.length, 2);
    expect(servidor.peticiones[1].headers['Authorization'], 'Bearer nuevo');
    expect(t.renovaciones, 1);
    expect(t.cerrada, isTrue);
  });

  test('tras un 401, si renovar funciona y el reintento sale bien, no cierra sesión', () async {
    servidor
      ..responde(401, sinSesion)
      ..responde(200, {'tipo': 'negocio'});
    final t = _Tokens('viejo');
    final r = await ClienteApi(base: base, tokens: t, dio: dio).get('/yo');
    expect(r, isA<Exito<Map<String, dynamic>>>());
    expect(t.cerrada, isFalse);
  });

  test('un 500 no cierra la sesión', () async {
    servidor.responde(500, {
      'error': {'codigo': 'interno', 'mensaje': 'x'},
    });
    final t = _Tokens('abc');
    final r = await ClienteApi(base: base, tokens: t, dio: dio).get('/yo');
    expect((r as Falla<Map<String, dynamic>>).error, isA<Servidor>());
    expect(t.cerrada, isFalse);
    expect(servidor.peticiones.length, 1);
  });

  test('si renovar falla por RED, no se cierra la sesión: es SinRed', () async {
    servidor.responde(401, sinSesion);
    final t = _TokensSinRed();
    final r = await ClienteApi(base: base, tokens: t, dio: dio).get('/yo');
    expect((r as Falla<Map<String, dynamic>>).error, isA<SinRed>());
    expect(t.cerrada, isFalse);
  });

  test('sin red → SinRed', () async {
    servidor.responde(
      0,
      DioException.connectionError(
        requestOptions: RequestOptions(path: '/yo'),
        reason: 'off',
      ),
    );
    final r = await ClienteApi(
      base: base,
      tokens: _Tokens('abc'),
      dio: dio,
    ).get('/yo');
    expect((r as Falla<Map<String, dynamic>>).error, isA<SinRed>());
  });
}

class _TokensSinRed extends _Tokens {
  _TokensSinRed() : super('viejo');

  @override
  Future<String?> renovar() async => throw const SinRed();
}
