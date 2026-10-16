import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/sucursales.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/funciones/negocio/sucursales/sucursales_vista.dart';
import 'package:reclutaya_app/funciones/negocio/vacantes/por_sucursal.dart';
import 'package:reclutaya_app/nucleo/plataforma/adaptativos.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/ui/estados.dart';

/// La pestaña «Sucursales» (14-oct, como el menú de la web): «Tu equipo» y una tarjeta
/// por sucursal; tocarla abre su ventana con sus números y sus vacantes. Solo existe
/// con varias sucursales. Antes vivía dentro de «Vacantes».
class PantallaSucursales extends ConsumerStatefulWidget {
  const PantallaSucursales({this.abrirSucursal, this.visita, super.key});

  /// Llegar desde una sucursal del Inicio (8-oct): abre la ventana de ESA sucursal.
  /// `visita` distingue un toque de otro a la misma sucursal.
  final String? abrirSucursal;
  final String? visita;

  @override
  ConsumerState<PantallaSucursales> createState() => _PantallaSucursalesState();
}

class _PantallaSucursalesState extends ConsumerState<PantallaSucursales> {
  /// La visita ya atendida: la ventana se abre UNA vez por toque, no al volver.
  String? _atendida;

  void _abrirSiToca(Sucursales? datos) {
    final id = widget.abrirSucursal;
    final visita = '$id·${widget.visita}';
    if (id == null || datos == null || _atendida == visita) return;
    _atendida = visita;
    final s = datos.items.where((x) => x.id == id).firstOrNull;
    if (s != null) unawaited(mostrarSucursal(context, s));
  }

  Future<void> _refrescar() async {
    ref.invalidate(sucursalesProvider);
    try {
      await ref.read(sucursalesProvider.future);
    } on ErrorApi {
      // La lista ya muestra el error.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.abrirSucursal != null) {
      final datos = ref.watch(sucursalesProvider).vigente;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _abrirSiToca(datos);
      });
    }
    return PaginaConTitulo(
      titulo: 'Sucursales',
      alRefrescar: _refrescar,
      slivers: const [
        VacantesPorSucursal(
          alternativa: SliverToBoxAdapter(
            child: EstadoVacio(
              titulo: 'Aún no hay sucursales',
              texto: 'Cuando tu negocio tenga sucursales, aquí las verás con sus vacantes.',
            ),
          ),
        ),
      ],
    );
  }
}
