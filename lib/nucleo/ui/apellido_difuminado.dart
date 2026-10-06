import 'package:flutter/material.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';

/// El «apellido» de un candidato sin contactar: una pastilla con degradado
/// que se lee como texto difuminado. SIN filtros de desenfoque a propósito:
/// cuarenta filas con `ImageFiltered` cuestan un `saveLayer` cada una.
class ApellidoDifuminado extends StatelessWidget {
  const ApellidoDifuminado({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Semantics(
      label: 'Apellido oculto',
      child: Container(
        width: 56,
        height: 12,
        margin: const EdgeInsets.only(left: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: LinearGradient(
            colors: [
              t.tintaTenue.withValues(alpha: 0.38),
              t.tintaTenue.withValues(alpha: 0.12),
              t.tintaTenue.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
