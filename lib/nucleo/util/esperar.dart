/// Pregunta hasta que haya valor: `intentos` veces, con `pausa` entre una y otra. Un
/// intento que truena cuenta como «todavía no». Da null si nunca apareció.
///
/// Para lo que el sistema entrega «un poco después» (el token de APNs en iPhone: al
/// abrir la app por primera vez no está listo, y pedir el de Firebase sin él no sirve).
Future<T?> esperarValor<T>(
  Future<T?> Function() intento, {
  int intentos = 10,
  Duration pausa = const Duration(milliseconds: 500),
}) async {
  for (var i = 0; i < intentos; i++) {
    try {
      final v = await intento();
      if (v != null) return v;
    } on Object {
      // Todavía no: se vuelve a intentar.
    }
    if (i < intentos - 1) await Future<void>.delayed(pausa);
  }
  return null;
}
