import 'package:reclutaya_app/funciones/negocio/comun/modelos/inicio.dart';

/// Lógica PURA del Inicio (6-oct): cómo se LEE lo que el servidor ya calculó. Nada
/// del producto se recalcula aquí.

class Rebanada {
  const Rebanada({
    required this.id,
    required this.nombre,
    required this.gastados,
    required this.pct,
    required this.colorIdx,
  });

  final String? id;
  final String nombre;
  final int gastados;
  final int pct;

  /// null = «El resto» (gris).
  final int? colorIdx;
}

/// Las rebanadas de la dona «Consumo de contactos por sucursal»: una por sucursal y, si
/// hay sucursales ajenas (miembro), «El resto» al final. Porcentaje redondeado sobre el
/// total; sin consumo, todo en 0 (sin dividir entre cero).
({int total, List<Rebanada> rebanadas}) rebanadasConsumo(
  List<SucursalInicio> sucursales,
  int? resto,
) {
  final total =
      sucursales.fold<int>(0, (a, s) => a + s.gastados) + (resto ?? 0);
  int pct(int g) => total == 0 ? 0 : (g * 100 / total).round();
  return (
    total: total,
    rebanadas: [
      for (final s in sucursales)
        Rebanada(
          id: s.id,
          nombre: s.nombre,
          gastados: s.gastados,
          pct: pct(s.gastados),
          colorIdx: s.colorIdx,
        ),
      if (resto != null && resto > 0)
        Rebanada(
          id: null,
          nombre: 'El resto',
          gastados: resto,
          pct: pct(resto),
          colorIdx: null,
        ),
    ],
  );
}

String textoConversion(EmbudoInicio e) {
  if (e.postulaciones == 0) return 'Aún sin postulaciones en estos 30 días.';
  final pct = (e.contratados * 100 / e.postulaciones).round();
  final post = e.postulaciones == 1 ? 'postulación' : 'postulaciones';
  final contr = e.contratados == 1 ? 'contratación' : 'contrataciones';
  return 'Conversión total: $pct% — de ${e.postulaciones} $post, '
      '${e.contratados} $contr.';
}

/// Los indicadores de la sucursal elegida (precalculados por el servidor); sin
/// sucursal o sin dato, los de todo el negocio.
Indicadores indicadoresDe(Inicio i, String? sucursalId) {
  if (sucursalId == null) return i.indicadores;
  return i.indicadoresPorSucursal?[sucursalId] ?? i.indicadores;
}

EmbudoInicio? embudoDe(Inicio i, String? sucursalId) {
  final p = i.proceso;
  if (p == null) return null;
  if (sucursalId == null) return p.total;
  return p.porSucursal?[sucursalId] ?? p.total;
}

/// Como en la web: con varias sucursales, «Vacantes» pasa a llamarse «Sucursales».
String nombrePestanaVacantes({required bool variasSucursales}) =>
    variasSucursales ? 'Sucursales' : 'Vacantes';
