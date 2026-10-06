import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reclutaya_app/nucleo/config.dart';
import 'package:reclutaya_app/nucleo/red/cliente_api.dart';
import 'package:reclutaya_app/nucleo/sesion/sesion.dart';

/// Se sobreescribe en `main` con la sesión real (y en pruebas con una falsa).
final sesionProvider = Provider<Sesion>(
  (_) => throw UnimplementedError('sesionProvider sin override'),
);

final autenticadoProvider = StreamProvider<bool>(
  (ref) => ref.watch(sesionProvider).cambios,
);

final clienteApiProvider = Provider<ClienteApi>(
  (ref) => ClienteApi(base: Config.apiBase, tokens: ref.watch(sesionProvider)),
);

/// Un aviso para la pantalla de Entrar (p. ej. «Esta versión es para
/// negocios»). Se consume al mostrarse.
class AvisoAcceso extends Notifier<String?> {
  @override
  String? build() => null;

  String? get aviso => state;
  set aviso(String? aviso) => state = aviso;
}

final avisoAccesoProvider = NotifierProvider<AvisoAcceso, String?>(
  AvisoAcceso.new,
);
