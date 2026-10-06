import 'dart:async';

import 'package:reclutaya_app/nucleo/sesion/sesion.dart';
import 'package:reclutaya_app/nucleo/util/resultado.dart';

/// La sesión de mentira de las pruebas de pantallas.
class SesionFalsa extends Sesion {
  Resultado<void> entrarR = const Exito(null);
  int salidas = 0;
  bool _autenticado = false;
  final _cambios = StreamController<bool>.broadcast();

  @override
  bool get autenticado => _autenticado;

  @override
  Stream<bool> get cambios => _cambios.stream;

  @override
  String? get token => _autenticado ? 't' : null;

  @override
  Future<String?> renovar() async => token;

  bool _vencio = false;

  @override
  bool consumirVencimiento() {
    final v = _vencio;
    _vencio = false;
    return v;
  }

  @override
  Future<void> sesionVencida() {
    _vencio = true;
    return salir();
  }

  @override
  Future<Resultado<void>> entrar(String correo, String contrasena) async {
    if (entrarR is Exito) {
      _autenticado = true;
      _cambios.add(true);
    }
    return entrarR;
  }

  @override
  Future<void> salir() async {
    salidas++;
    _autenticado = false;
    _cambios.add(false);
  }
}
