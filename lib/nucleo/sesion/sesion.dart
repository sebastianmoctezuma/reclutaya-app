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

  // ── Varias cuentas en el mismo teléfono (8-oct) ──

  /// El token de renovación de la sesión activa (para guardarla al cambiar).
  String? get refreshToken;

  /// El correo de la sesión activa.
  String? get correo;

  /// Cambia la sesión activa a otra cuenta guardada, SIN cerrar la actual (cerrarla la
  /// invalidaría). false = ese token ya no vale; sin red lanza `SinRed`.
  Future<bool> usarCuenta(String refreshToken);

  /// Renueva una cuenta que NO es la activa, sin tocar la activa. null = ya no vale;
  /// sin red lanza `SinRed`.
  Future<({String acceso, String refresh})?> renovarAparte(String refreshToken);

  /// Revoca en el servidor la sesión de ese token de acceso (al quitar una cuenta).
  /// Sin red no pasa nada.
  Future<void> revocar(String accesoToken);

  /// Quién decide qué hacer cuando la sesión activa vence sin rescate (con varias
  /// cuentas, pasar a otra). Sin él, se cierra la sesión como siempre.
  Future<void> Function()? get alVencer;
  set alVencer(Future<void> Function()? decide);

  /// Cierra la sesión marcándola como vencida (el aviso «Tu sesión terminó»).
  Future<void> salirPorVencimiento();
}
