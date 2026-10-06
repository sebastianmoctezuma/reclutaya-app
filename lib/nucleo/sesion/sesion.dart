import 'package:reclutaya_app/nucleo/red/cliente_api.dart';
import 'package:reclutaya_app/nucleo/util/resultado.dart';

/// La sesión de la persona. La implementación real envuelve a Supabase; las
/// pruebas usan una falsa.
abstract class Sesion implements ProveedorToken {
  bool get autenticado;

  /// true cuando hay sesión, false cuando no; sin repetidos.
  Stream<bool> get cambios;

  Future<Resultado<void>> entrar(String correo, String contrasena);

  Future<void> salir();

  /// true UNA vez si la última salida fue por sesión vencida (401 sin
  /// rescate), para avisarlo en Entrar; después vuelve a false.
  bool consumirVencimiento();
}
