import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:reclutaya_app/funciones/negocio/comun/presentacion.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/nucleo/config.dart';
import 'package:reclutaya_app/nucleo/plataforma/adaptativos.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/sesion/providers.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/ui/avatar_iniciales.dart';
import 'package:reclutaya_app/nucleo/ui/chip.dart';
import 'package:reclutaya_app/nucleo/ui/esqueleto.dart';
import 'package:reclutaya_app/nucleo/ui/estados.dart';
import 'package:reclutaya_app/nucleo/ui/logo_negocio.dart';
import 'package:reclutaya_app/nucleo/ui/tarjeta.dart';
import 'package:url_launcher/url_launcher.dart';

const _urlTerminos = 'https://reclutaya.com/terminos';
const _urlAviso = 'https://reclutaya.com/aviso-de-privacidad';
const _lados = EdgeInsets.symmetric(horizontal: 16);

/// Quién entró, su rol y su negocio; los legales (web) y «Cerrar sesión» con
/// confirmación nativa. Al salir no queda nada en memoria.
class PantallaCuenta extends ConsumerWidget {
  const PantallaCuenta({super.key});

  Future<void> _salir(BuildContext context, WidgetRef ref) async {
    final ok = await confirmar(
      context,
      titulo: 'Cerrar sesión',
      mensaje: '¿Quieres cerrar sesión en este dispositivo?',
      aceptar: 'Salir',
      destructivo: true,
    );
    if (!ok) return;
    // La limpieza de memoria la hace `limpiezaSesionProvider` al ver salir la
    // sesión: esta pantalla se desmonta antes de que `salir()` termine.
    await ref.read(sesionProvider).salir();
  }

  Future<void> _abrir(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final yo = ref.watch(yoProvider);
    return PaginaConTitulo(
      titulo: 'Cuenta',
      slivers: [
        SliverPadding(
          padding: _lados,
          sliver: SliverList.list(
            children: [
              yo.when(
                data: (y) => Tarjeta(
                  child: Row(
                    children: [
                      if (y.empresa != null)
                        LogoNegocio(
                          nombre: y.empresa!.nombre,
                          url: y.empresa!.logoUrl,
                          logoFit: y.empresa!.logoFit,
                          tam: 60,
                        )
                      else
                        AvatarIniciales(y.iniciales, tam: 60),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              y.empresa?.nombre ?? y.nombre ?? 'Tu cuenta',
                              style: tt.titleLarge,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              [
                                if (y.nombre != null) y.nombre!,
                                etiquetaRol(y.rol),
                              ].join(' · '),
                              style: tt.bodySmall,
                            ),
                            if (y.empresa?.plan != null) ...[
                              const SizedBox(height: 8),
                              ChipRY(
                                y.empresa!.plan == 'Ilimitada' ||
                                        y.empresa!.plan == 'Gratis'
                                    ? 'Cuenta ${y.empresa!.plan!.toLowerCase()}'
                                    : 'Plan ${y.empresa!.plan}',
                                tono: TonoChip.verde,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                loading: () => const Tarjeta(
                  child: Row(
                    children: [
                      Esqueleto(alto: 56, ancho: 56, radio: 28),
                      SizedBox(width: 14),
                      Expanded(child: Esqueleto(alto: 20)),
                    ],
                  ),
                ),
                error: (e, _) => EstadoError(
                  error: e is ErrorApi ? e : const Servidor(),
                  alReintentar: () => ref.invalidate(yoProvider),
                ),
              ),
              const SizedBox(height: 12),
              Tarjeta(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    _Enlace(
                      'Términos y condiciones',
                      () => _abrir(_urlTerminos),
                    ),
                    Divider(height: 1, color: t.linea),
                    _Enlace('Aviso de privacidad', () => _abrir(_urlAviso)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => _salir(context, ref),
                style: OutlinedButton.styleFrom(
                  foregroundColor: t.rojo,
                  side: BorderSide(color: t.rojo.withValues(alpha: 0.35)),
                  minimumSize: const Size.fromHeight(48),
                  shape: const StadiumBorder(),
                  textStyle: tt.labelLarge,
                ),
                child: const Text('Cerrar sesión'),
              ),
              const SizedBox(height: 20),
              const _Version(),
            ],
          ),
        ),
      ],
    );
  }
}

class _Enlace extends StatelessWidget {
  const _Enlace(this.texto, this.alTocar);

  final String texto;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return InkWell(
      onTap: alTocar,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(texto, style: Theme.of(context).textTheme.bodyMedium),
            ),
            Icon(Icons.open_in_new_rounded, size: 16, color: t.tintaTenue),
          ],
        ),
      ),
    );
  }
}

class _Version extends StatelessWidget {
  const _Version();

  Future<String> _texto() async {
    try {
      final p = await PackageInfo.fromPlatform();
      return 'Versión ${p.version} (${p.buildNumber}) · ${Config.sabor}';
    } on Object {
      return 'Versión — · ${Config.sabor}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _texto(),
      builder: (context, s) => Center(
        child: Text(
          s.data ?? '',
          style: Theme.of(context).textTheme.labelSmall!
              .copyWith(color: context.t.tintaSuave),
        ),
      ),
    );
  }
}
