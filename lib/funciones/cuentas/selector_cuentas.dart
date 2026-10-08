import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reclutaya_app/funciones/cuentas/gestor_cuentas.dart';
import 'package:reclutaya_app/nucleo/plataforma/adaptativos.dart';
import 'package:reclutaya_app/nucleo/plataforma/plataforma.dart';
import 'package:reclutaya_app/nucleo/sesion/cuentas_core.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/ui/logo_negocio.dart';
import 'package:reclutaya_app/nucleo/ui/tarjeta.dart';
import 'package:reclutaya_app/nucleo/vidrio/hoja.dart';

/// La hoja para cambiar de cuenta (como Instagram en iOS, 8-oct): cada cuenta del
/// teléfono con su logo, negocio y correo; palomita en la activa; «Agregar cuenta» al
/// final (hasta 5). Cambiar es un toque.
Future<void> mostrarSelectorCuentas(BuildContext context) {
  hapticoSeleccion();
  return mostrarHojaVidrio(context, builder: (_) => const _Selector());
}

class _Selector extends ConsumerWidget {
  const _Selector();

  Future<void> _cambiar(
    BuildContext context,
    WidgetRef ref,
    CuentaGuardada c,
  ) async {
    hapticoSeleccion();
    final nav = Navigator.of(context);
    final mensajes = ScaffoldMessenger.maybeOf(context);
    final router = GoRouter.of(context);
    final negocio = await ref
        .read(gestorCuentasProvider.notifier)
        .cambiarA(c.usuarioId);
    nav.pop();
    if (negocio == null) {
      mensajes?.showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo cambiar a ${c.negocio}. Revisa tu conexión o vuelve a entrar.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    router.go('/inicio');
    mensajes?.showSnackBar(
      SnackBar(
        content: Text('Cambiaste a $negocio'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _agregar(BuildContext context, WidgetRef ref) async {
    final nav = Navigator.of(context);
    final router = GoRouter.of(context);
    await ref.read(gestorCuentasProvider.notifier).prepararAgregar();
    nav.pop();
    unawaited(router.push('/entrar'));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final cuentas = ref.watch(gestorCuentasProvider).value ?? const [];
    final lleno = cuentas.length >= maxCuentas;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 5,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: t.lineaFuerte,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text('Cuentas', style: tt.titleLarge),
            ),
            Tarjeta(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (i, c) in cuentas.indexed) ...[
                    if (i > 0) Divider(height: 1, indent: 72, color: t.linea),
                    _Fila(
                      cuenta: c,
                      activa: i == 0,
                      alTocar: i == 0
                          ? () => Navigator.of(context).pop()
                          : () => _cambiar(context, ref, c),
                    ),
                  ],
                  if (cuentas.isNotEmpty)
                    Divider(height: 1, indent: 72, color: t.linea),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    enabled: !lleno,
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: t.lineaFuerte),
                      ),
                      child: Icon(
                        Plataforma.esIOS ? CupertinoIcons.add : Icons.add,
                        color: lleno ? t.tintaTenue : t.verdeProfundo,
                      ),
                    ),
                    title: Text('Agregar cuenta', style: tt.bodyLarge),
                    subtitle: lleno
                        ? Text(
                            'Hasta $maxCuentas cuentas. Quita una para agregar otra.',
                            style: tt.bodySmall,
                          )
                        : null,
                    onTap: lleno ? null : () => _agregar(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.cuenta,
    required this.activa,
    required this.alTocar,
  });

  final CuentaGuardada cuenta;
  final bool activa;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: LogoNegocio(
        nombre: cuenta.negocio,
        url: cuenta.logoUrl,
        logoFit: cuenta.logoFit,
      ),
      title: Text(
        cuenta.negocio,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: tt.bodyLarge!.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: cuenta.correo == null
          ? null
          : Text(
              cuenta.correo!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.bodySmall,
            ),
      trailing: activa
          ? Icon(
              Plataforma.esIOS
                  ? CupertinoIcons.check_mark_circled_solid
                  : Icons.check_circle_rounded,
              color: t.verde,
            )
          : null,
      onTap: alTocar,
    );
  }
}
