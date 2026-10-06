import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/inicio.dart';
import 'package:reclutaya_app/funciones/negocio/comun/presentacion.dart';
import 'package:reclutaya_app/funciones/negocio/inicio/inicio_core.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/ui/tarjeta.dart';
import 'package:reclutaya_app/nucleo/util/formato.dart';

/// «Consumo de contactos por sucursal»: la dona con el total al centro y, abajo, cada
/// sucursal con su barra, cuántos usó y su porcentaje. Los números son del servidor.
class ConsumoSucursales extends StatelessWidget {
  const ConsumoSucursales({
    required this.sucursales,
    required this.resto,
    required this.ilimitada,
    this.disponibles,
    super.key,
  });

  final List<SucursalInicio> sucursales;
  final int? resto;
  final int? disponibles;
  final bool ilimitada;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final r = rebanadasConsumo(sucursales, resto);
    Color colorDe(Rebanada x) => x.colorIdx == null
        ? t.lineaFuerte
        : colorSucursal(x.colorIdx!, oscuro: t.esOscuro);
    final pie = ilimitada
        ? 'Sin límite'
        : disponibles == null
        ? ''
        : '${numero(disponibles!)} disponibles';
    return Tarjeta(
      child: Column(
        children: [
          SizedBox(
            width: 190,
            height: 190,
            child: CustomPaint(
              painter: _Dona(
                partes: [for (final x in r.rebanadas) (x.gastados, colorDe(x))],
                pista: t.linea,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      numero(r.total),
                      style: tt.headlineMedium!.copyWith(fontSize: 34),
                    ),
                    Text('usados', style: tt.labelMedium),
                    if (pie.isNotEmpty) Text(pie, style: tt.labelSmall),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          for (final x in r.rebanadas)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colorDe(x),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 5,
                    child: Text(
                      x.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.labelLarge,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        height: 6,
                        child: Stack(
                          children: [
                            ColoredBox(
                              color: t.linea,
                              child: const SizedBox.expand(),
                            ),
                            FractionallySizedBox(
                              widthFactor: x.pct / 100,
                              child: ColoredBox(
                                color: colorDe(x),
                                child: const SizedBox.expand(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text(
                      numero(x.gastados),
                      textAlign: TextAlign.right,
                      style: tt.labelLarge,
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${x.pct}%',
                      textAlign: TextAlign.right,
                      style: tt.labelSmall,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// La dona: arcos proporcionales sobre una pista, con un respiro entre rebanadas.
class _Dona extends CustomPainter {
  const _Dona({required this.partes, required this.pista});

  final List<(int, Color)> partes;
  final Color pista;

  @override
  void paint(Canvas canvas, Size size) {
    const grosor = 22.0;
    final rect = Offset.zero & size;
    final arco = rect.deflate(grosor / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor
      ..color = pista;
    canvas.drawArc(arco, 0, math.pi * 2, false, base);
    final total = partes.fold<int>(0, (a, p) => a + p.$1);
    if (total == 0) return;
    const hueco = 0.025;
    var inicio = -math.pi / 2;
    for (final (valor, color) in partes) {
      if (valor <= 0) continue;
      final barrido = valor / total * math.pi * 2;
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = grosor
        ..strokeCap = StrokeCap.butt
        ..color = color;
      final visible = partes.where((x) => x.$1 > 0).length > 1
          ? math.max(barrido - hueco, 0.001)
          : barrido;
      canvas.drawArc(arco, inicio, visible, false, p);
      inicio += barrido;
    }
  }

  @override
  bool shouldRepaint(_Dona old) => old.partes != partes || old.pista != pista;
}
