import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reclutaya_app/funciones/acceso/controlador_acceso.dart';
import 'package:reclutaya_app/funciones/arranque/isotipo_liquido.dart';
import 'package:reclutaya_app/funciones/arranque/nivel_espera.dart';
import 'package:reclutaya_app/funciones/cuentas/gestor_cuentas.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/funciones/negocio/novedades/controlador_avisos.dart';
import 'package:reclutaya_app/nucleo/sesion/arranque_core.dart';
import 'package:reclutaya_app/nucleo/sesion/providers.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/util/resultado.dart';
import 'package:reclutaya_app/nucleo/vidrio/vidrio.dart';

const _cierre = Duration(milliseconds: 380);

/// Al abrir: papel blanco y el isotipo llenándose mientras se restaura la
/// sesión y llega `/yo`. El nivel sigue la espera real; al tener respuesta,
/// se termina de llenar y entra. Con «Reducir movimiento», lleno y quieto.
class PantallaArranque extends ConsumerStatefulWidget {
  const PantallaArranque({super.key});

  @override
  ConsumerState<PantallaArranque> createState() => _PantallaArranqueState();
}

class _PantallaArranqueState extends ConsumerState<PantallaArranque>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _inicio = Stopwatch()..start();
  double _nivel = 0;
  double _fase = 0;
  Duration? _cerrandoDesde;
  double _nivelAlCerrar = 0;
  String? _destino;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tic)..start();
    // Tras el primer cuadro: `_ir` lee MediaQuery y eso no se puede en initState.
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_decidir()));
  }

  void _tic(Duration t) {
    final s = _inicio.elapsedMilliseconds / 1000;
    var nivel = nivelEspera(s);
    if (_cerrandoDesde != null) {
      final k = ((t - _cerrandoDesde!).inMilliseconds / _cierre.inMilliseconds)
          .clamp(0.0, 1.0);
      final suave = 1 - (1 - k) * (1 - k) * (1 - k);
      nivel = _nivelAlCerrar + (1 - _nivelAlCerrar) * suave;
      if (k >= 1 && _destino != null && mounted) {
        _ticker.stop();
        context.go(_destino!);
        return;
      }
    }
    setState(() {
      _nivel = nivel > _nivel ? nivel : _nivel;
      _fase = s * 2.2;
    });
  }

  Future<void> _decidir() async {
    final sesion = ref.read(sesionProvider);
    String? tipo;
    if (sesion.autenticado) {
      final r = await ref.read(repositorioProvider).yo();
      if (r case Exito(:final valor)) {
        tipo = valor.tipo;
        if (valor.esNegocio) {
          await ref.read(gestorCuentasProvider.notifier).recordarActiva(valor);
        }
      }
    }
    if (!mounted) return;
    final destino = destinoArranque(
      haySesion: sesion.autenticado,
      tipoYo: tipo,
    );
    switch (destino) {
      case DestinoArranque.entrar:
        _ir('/entrar');
      case DestinoArranque.negocio:
        _ir('/inicio');
      case DestinoArranque.candidatoNoSoportado:
        ref.read(avisoAccesoProvider.notifier).aviso = avisoSoloNegocios;
        await ref.read(cerrarSesionProvider)();
        if (mounted) _ir('/entrar');
    }
  }

  void _ir(String ruta) {
    if (vidrioSolido(context)) {
      _ticker.stop();
      context.go(ruta);
      return;
    }
    _destino = ruta;
    _nivelAlCerrar = _nivel;
    _cerrandoDesde = Duration(milliseconds: _inicio.elapsedMilliseconds);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quieto = vidrioSolido(context);
    return Scaffold(
      backgroundColor: context.t.tarjeta,
      body: Center(
        child: Semantics(
          label: 'Cargando',
          liveRegion: true,
          child: IsotipoLiquido(nivel: quieto ? 1 : _nivel, fase: _fase),
        ),
      ),
    );
  }
}
