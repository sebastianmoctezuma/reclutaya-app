import 'package:reclutaya_app/nucleo/red/errores_api.dart';

/// El resultado de toda lectura: el valor, o un error del contrato.
sealed class Resultado<T> {
  const Resultado();
}

final class Exito<T> extends Resultado<T> {
  const Exito(this.valor);

  final T valor;
}

final class Falla<T> extends Resultado<T> {
  const Falla(this.error);

  final ErrorApi error;
}

extension ResultadoX<T> on Resultado<T> {
  /// Para los providers de Riverpod: el valor, o lanza el `ErrorApi` (que
  /// `AsyncValue.error` conserva tal cual para que la UI lo traduzca).
  T get valorOLanza => switch (this) {
    Exito(:final valor) => valor,
    Falla(:final error) => throw error,
  };
}
