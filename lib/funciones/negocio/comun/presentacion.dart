import 'package:flutter/widgets.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/vacantes.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/util/formato.dart';

/// Reglas de PRESENTACIÓN del negocio: puras, sin widgets. La app no calcula
/// nada del producto; solo decide cómo se lee lo que el servidor ya resolvió.
String? textoCumple(int incumplidos, int total) =>
    total <= 0 ? null : 'Cumple ${total - incumplidos} de $total';

String? textoDiasRestantes(int? dias) => switch (dias) {
  null => null,
  0 => 'Vence hoy',
  1 => '1 día restante',
  final d => '$d días restantes',
};

/// Sin «Hubo contratación»: eso va en su propio chip verde.
String textoCerrada(VacanteCerrada v) {
  final partes = <String>[
    if (v.cerradaAt != null) 'Cerrada el ${fechaCorta(v.cerradaAt!)}',
    if (v.purgada)
      'Datos purgados'
    else if (v.diasParaArchivar != null)
      'Se archiva en ${v.diasParaArchivar} días',
  ];
  return partes.join(' · ');
}

String etiquetaRol(String? rol) => switch (rol) {
  'owner' => 'Dueño',
  'admin' => 'Administrador',
  _ => 'Miembro',
};

enum TonoDelta { sube, baja, neutro }

({String texto, TonoDelta tono}) delta(num? d, String unidad) {
  if (d == null) return (texto: '—', tono: TonoDelta.neutro);
  if (d == 0) return (texto: 'Sin cambio', tono: TonoDelta.neutro);
  final n = d % 1 == 0 ? d.toInt().toString() : d.toStringAsFixed(1);
  return d > 0
      ? (texto: '+$n$unidad', tono: TonoDelta.sube)
      : (texto: '$n$unidad', tono: TonoDelta.baja);
}

Color colorSucursal(int colorIdx, {required bool oscuro}) {
  final c = coloresSucursal[colorIdx % coloresSucursal.length];
  return oscuro ? c.oscuro : c.luz;
}

String? textoMaterial({required bool solicitado, required bool recibido}) =>
    recibido ? 'Recibido' : (solicitado ? 'Pedido' : null);

String textoEstadoVacante(String estado) => switch (estado) {
  'ACTIVA' => 'Activa',
  'PAUSADA' => 'En pausa',
  'BORRADOR' => 'Borrador',
  'CERRADA' => 'Cerrada',
  _ => estado,
};

BoxFit ajusteLogo(String? logoFit) =>
    logoFit == 'cover' ? BoxFit.cover : BoxFit.contain;

String textoTraslado(int? min) => min == null ? '' : 'a $min min';
