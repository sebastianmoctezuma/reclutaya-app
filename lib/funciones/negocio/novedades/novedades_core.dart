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
