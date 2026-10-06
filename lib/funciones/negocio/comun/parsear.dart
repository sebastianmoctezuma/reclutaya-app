import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/util/resultado.dart';

/// Del JSON del cliente al modelo, sin que nada truene: un campo obligatorio
/// ausente o con otro tipo es `RespuestaInvalida`, nunca un crash.
Resultado<T> parsear<T>(
  Resultado<Map<String, dynamic>> r,
  T Function(Map<String, dynamic>) fromJson,
) {
  return switch (r) {
    Falla(:final error) => Falla(error),
    Exito(:final valor) => _seguro(() => fromJson(valor)),
  };
}

/// Las listas del contrato vienen como `{ items: [...], cursor: null }`.
Resultado<List<T>> parsearLista<T>(
  Resultado<Map<String, dynamic>> r,
  T Function(Map<String, dynamic>) fromJson,
) {
  return switch (r) {
    Falla(:final error) => Falla(error),
    Exito(:final valor) => _seguro(() {
      final items = valor['items'];
      if (items is! List) throw const FormatException('falta items');
      return [for (final i in items) fromJson(i as Map<String, dynamic>)];
    }),
  };
}

Resultado<T> _seguro<T>(T Function() f) {
  try {
    return Exito(f());
  } on Object catch (e) {
    // Solo el tipo del error, nunca el cuerpo: podría traer datos de personas.
    return Falla(RespuestaInvalida(e.runtimeType.toString()));
  }
}
