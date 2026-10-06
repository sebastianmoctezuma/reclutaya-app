import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/vacantes.dart';
import 'package:reclutaya_app/funciones/negocio/comun/presentacion.dart';
import 'package:reclutaya_app/nucleo/plataforma/plataforma.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/ui/chip.dart';
import 'package:reclutaya_app/nucleo/ui/esqueleto.dart';
import 'package:reclutaya_app/nucleo/ui/tarjeta.dart';

/// Una vacante en la lista: puesto, sucursal con su color, ubicación y
/// sueldo, candidatos, «N sin rankear» y los días que le quedan (o cómo
/// cerró). Superficie sólida: nunca vidrio dentro de una lista.
class FilaVacante extends StatelessWidget {
  FilaVacante.activa(VacanteResumen v, {required this.alTocar, super.key})
    : puesto = v.puesto,
      sucursal = v.sucursal,
      detalle = _detalle(v.ubicacion, v.sueldoTexto),
      candidatos = v.candidatos,
      sinRankear = v.sinRankear,
      pie = textoDiasRestantes(v.diasRestantes),
      resumenCierre = null,
      estado = v.estado == 'ACTIVA' ? null : textoEstadoVacante(v.estado),
      contratacion = false;

  FilaVacante.cerrada(VacanteCerrada v, {required this.alTocar, super.key})
    : puesto = v.puesto,
      sucursal = v.sucursal,
      detalle = _detalle(v.ubicacion, v.sueldoTexto),
      candidatos = v.candidatos,
      sinRankear = 0,
      pie = null,
      resumenCierre = textoCerrada(v),
      estado = null,
      contratacion = v.huboContratacion;

  final String puesto;
  final SucursalRef? sucursal;
  final String? detalle;
  final int candidatos;
  final int sinRankear;
  final String? pie;

  /// Solo en cerradas: «Cerrada el … · Se archiva en N días», como texto.
  final String? resumenCierre;
  final bool contratacion;
  final String? estado;
  final VoidCallback alTocar;

  static String? _detalle(String? ubicacion, String? sueldo) {
    final partes = [ubicacion, sueldo].whereType<String>().toList();
    return partes.isEmpty ? null : partes.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    return Tarjeta(
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      alTocar: alTocar,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  puesto,
                  style: tt.titleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (sucursal != null || estado != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (sucursal != null) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colorSucursal(
                              sucursal!.colorIdx,
                              oscuro: t.esOscuro,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            sucursal!.nombre,
                            style: tt.labelMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (estado != null) ...[
                        if (sucursal != null) const SizedBox(width: 8),
                        ChipRY(estado!, tono: TonoChip.naranja),
                      ],
                    ],
                  ),
                ],
                if (detalle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    detalle!,
                    style: tt.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      candidatos == 1
                          ? '1 candidato'
                          : '$candidatos candidatos',
                      style: tt.labelMedium!.copyWith(color: t.tinta),
                    ),
                    if (sinRankear > 0)
                      ChipRY('$sinRankear sin rankear', tono: TonoChip.naranja),
                    if (pie != null && pie!.isNotEmpty) ChipRY(pie!),
                    if (contratacion)
                      const ChipRY('Hubo contratación', tono: TonoChip.verde),
                  ],
                ),
                if (resumenCierre != null && resumenCierre!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    resumenCierre!,
                    style: tt.labelSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (Plataforma.esIOS) ...[
            const SizedBox(width: 8),
            Icon(CupertinoIcons.chevron_right, size: 16, color: t.tintaTenue),
          ],
        ],
      ),
    );
  }
}

class EsqueletoFilaVacante extends StatelessWidget {
  const EsqueletoFilaVacante({super.key});

  @override
  Widget build(BuildContext context) {
    return const Tarjeta(
      padding: EdgeInsets.fromLTRB(18, 16, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Esqueleto(alto: 18, ancho: 180),
          SizedBox(height: 8),
          Esqueleto(alto: 12, ancho: 120),
          SizedBox(height: 12),
          Esqueleto(alto: 20, ancho: 220, radio: 999),
        ],
      ),
    );
  }
}
