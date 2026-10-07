import 'package:intl/intl.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/novedades.dart';

/// Las que llegaron después de la última vez que se abrió la campana (todas, si
/// nunca se ha abierto).
List<Novedad> nuevasDesde(List<Novedad> items, DateTime? vistoHasta) =>
    vistoHasta == null
    ? items
    : [
        for (final n in items)
          if (n.at.isAfter(vistoHasta)) n,
      ];

/// «hace 5 min», «hace 3 h», «ayer», «hace 4 días».
String haceCuanto(DateTime at, DateTime ahora) {
  final d = ahora.difference(at);
  if (d.inMinutes < 1) return 'ahora';
  if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
  if (d.inHours < 24) return 'hace ${d.inHours} h';
  if (d.inDays == 1) return 'ayer';
  return 'hace ${d.inDays} días';
}

/// La Actividad agrupada por día (como la de la web): «Hoy», «Ayer» y luego la fecha.
/// Conserva el orden (lo más reciente primero).
List<(String, List<Novedad>)> porDia(List<Novedad> items, DateTime ahora) {
  final hoy = DateTime(ahora.year, ahora.month, ahora.day);
  final grupos = <(String, List<Novedad>)>[];
  for (final n in items) {
    final local = n.at.toLocal();
    final dia = DateTime(local.year, local.month, local.day);
    final dias = hoy.difference(dia).inDays;
    final etiqueta = switch (dias) {
      0 => 'Hoy',
      1 => 'Ayer',
      _ => DateFormat("EEEE d 'de' MMMM", 'es_MX').format(dia),
    };
    if (grupos.isNotEmpty && grupos.last.$1 == etiqueta) {
      grupos.last.$2.add(n);
    } else {
      grupos.add((etiqueta, [n]));
    }
  }
  return grupos;
}

/// Cuántas hay de cada tipo (el resumen de arriba de la Actividad).
Map<String, int> conteoPorTipo(List<Novedad> items) {
  final c = <String, int>{};
  for (final n in items) {
    c[n.tipo] = (c[n.tipo] ?? 0) + 1;
  }
  return c;
}
