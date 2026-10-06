import 'package:reclutaya_app/funciones/negocio/comun/modelos/vacantes.dart';

/// Una sucursal con lo que tiene activo hoy.
class ResumenSucursal {
  const ResumenSucursal({
    required this.sucursal,
    required this.vacantes,
    required this.candidatos,
  });

  final SucursalRef sucursal;
  final int vacantes;
  final int candidatos;
}

/// Agrupa las vacantes activas por sucursal (pura). La API v1 no tiene ruta
/// de sucursales: cada vacante ya trae la suya, así que se agrupa aquí sin
/// pedir nada más. Las vacantes sin sucursal no cuentan; orden: más vacantes
/// primero, empate por nombre.
List<ResumenSucursal> resumenSucursales(List<VacanteResumen> vs) {
  final porId = <String, ({SucursalRef s, int v, int c})>{};
  for (final v in vs) {
    final s = v.sucursal;
    if (s == null) continue;
    final previo = porId[s.id];
    porId[s.id] = (
      s: s,
      v: (previo?.v ?? 0) + 1,
      c: (previo?.c ?? 0) + v.candidatos,
    );
  }
  final lista =
      [
        for (final x in porId.values)
          ResumenSucursal(sucursal: x.s, vacantes: x.v, candidatos: x.c),
      ]..sort((a, b) {
        final porVacantes = b.vacantes.compareTo(a.vacantes);
        return porVacantes != 0
            ? porVacantes
            : a.sucursal.nombre.compareTo(b.sucursal.nombre);
      });
  return lista;
}
