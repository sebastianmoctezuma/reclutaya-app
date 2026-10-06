import 'package:intl/intl.dart';

/// «2 oct 2026»: intl pone «oct.» con punto en es_MX; se quita.
String fechaCorta(DateTime d) =>
    DateFormat('d MMM y', 'es_MX').format(d.toLocal()).replaceAll('.', '');

String numero(num n) => NumberFormat.decimalPattern('es_MX').format(n);

String experiencia(int? meses) {
  if (meses == null || meses <= 0) return 'Sin experiencia';
  final a = meses ~/ 12;
  final m = meses % 12;
  final partes = <String>[
    if (a == 1) '1 año' else if (a > 1) '$a años',
    if (m == 1) '1 mes' else if (m > 1) '$m meses',
  ];
  return partes.join(' ');
}
