import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Lo poco que la app guarda en el teléfono fuera de la sesión (p. ej. hasta cuándo
/// vio las novedades). Una interfaz para poder probarlo sin el llavero.
abstract class AlmacenLocal {
  Future<String?> leer(String llave);
  Future<void> guardar(String llave, String valor);
  Future<void> borrar(String llave);
}

class AlmacenLlavero implements AlmacenLocal {
  static const _s = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  @override
  Future<String?> leer(String llave) => _s.read(key: llave);

  @override
  Future<void> guardar(String llave, String valor) =>
      _s.write(key: llave, value: valor);

  @override
  Future<void> borrar(String llave) => _s.delete(key: llave);
}

/// En memoria (pruebas).
class AlmacenMemoria implements AlmacenLocal {
  final Map<String, String> datos = {};

  @override
  Future<String?> leer(String llave) async => datos[llave];

  @override
  Future<void> guardar(String llave, String valor) async =>
      datos[llave] = valor;

  @override
  Future<void> borrar(String llave) async => datos.remove(llave);
}

final almacenLocalProvider = Provider<AlmacenLocal>((_) => AlmacenLlavero());
