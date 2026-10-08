import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reclutaya_app/funciones/acceso/controlador_acceso.dart';
import 'package:reclutaya_app/funciones/cuentas/gestor_cuentas.dart';
import 'package:reclutaya_app/nucleo/plataforma/adaptativos.dart';
import 'package:reclutaya_app/nucleo/plataforma/plataforma.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/sesion/providers.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/ui/tarjeta.dart';
import 'package:url_launcher/url_launcher.dart';

const _urlRecuperar = 'https://app.reclutaya.com/recuperar';
const _urlCrear = 'https://reclutaya.com/crear-cuenta';

/// Correo y contraseña sobre papel, en la tarjeta de la casa. Recuperar la
/// contraseña y crear cuenta viven en la web: la app no los reimplementa.
class PantallaEntrar extends ConsumerStatefulWidget {
  const PantallaEntrar({super.key});

  @override
  ConsumerState<PantallaEntrar> createState() => _PantallaEntrarState();
}

class _PantallaEntrarState extends ConsumerState<PantallaEntrar> {
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  bool _ver = false;

  @override
  void initState() {
    super.initState();
    _correo.addListener(_cambio);
    _contrasena.addListener(_cambio);
  }

  void _cambio() => setState(() {});

  @override
  void dispose() {
    _correo.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  bool get _listo =>
      _correo.text.trim().isNotEmpty && _contrasena.text.isNotEmpty;

  Future<void> _entrar() async {
    FocusScope.of(context).unfocus();
    await ref
        .read(accesoProvider.notifier)
        .entrar(_correo.text, _contrasena.text);
  }

  Future<void> _abrir(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    // A Inicio SOLO cuando el controlador confirmó que es un negocio.
    ref.listen(accesoProvider, (_, s) {
      if (s is AsyncData<void> && ref.read(sesionProvider).autenticado) {
        GoRouter.maybeOf(context)?.go('/inicio');
      }
    });
    final acceso = ref.watch(accesoProvider);
    // «Agregar cuenta» (varias cuentas, 8-oct): misma pantalla, con «Cancelar».
    final agregando = ref.watch(agregandoCuentaProvider);
    final cargando = acceso.isLoading;
    final aviso = ref.watch(avisoAccesoProvider);
    final error = acceso.hasError ? acceso.error : null;
    final mensaje = switch (error) {
      ErrorApi() => error.mensaje,
      null => aviso,
      _ => 'No se pudo entrar. Intenta de nuevo.',
    };

    return Scaffold(
      backgroundColor: t.papel,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Tarjeta(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (agregando)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            key: const Key('cancelarAgregar'),
                            onPressed: cargando
                                ? null
                                : () async {
                                    final router = GoRouter.of(context);
                                    await ref
                                        .read(gestorCuentasProvider.notifier)
                                        .cancelarAgregar(sesionNueva: false);
                                    if (router.canPop()) {
                                      router.pop();
                                    } else {
                                      router.go('/inicio');
                                    }
                                  },
                            child: const Text('Cancelar'),
                          ),
                        ),
                      const _Marca(),
                      const SizedBox(height: 22),
                      Text(
                        agregando ? 'Agregar cuenta' : 'Bienvenido de vuelta',
                        style: tt.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        agregando
                            ? 'Entra con el correo y la contraseña de la otra cuenta.'
                            : 'Entra con tu correo y contraseña.',
                        style: tt.bodySmall,
                      ),
                      const SizedBox(height: 22),
                      _Campo(
                        llave: const Key('correo'),
                        controlador: _correo,
                        etiqueta: 'Correo',
                        teclado: TextInputType.emailAddress,
                        autofill: const [AutofillHints.username],
                        accion: TextInputAction.next,
                        autofocus: true,
                      ),
                      const SizedBox(height: 12),
                      _Campo(
                        llave: const Key('contrasena'),
                        controlador: _contrasena,
                        etiqueta: 'Contraseña',
                        oculto: !_ver,
                        autofill: const [AutofillHints.password],
                        accion: TextInputAction.done,
                        alEnviar: _listo && !cargando ? _entrar : null,
                        sufijo: IconButton(
                          onPressed: () => setState(() => _ver = !_ver),
                          icon: Icon(
                            _ver
                                ? CupertinoIcons.eye_slash
                                : CupertinoIcons.eye,
                            size: 20,
                            color: t.tintaTenue,
                          ),
                          tooltip: _ver ? 'Ocultar' : 'Ver',
                        ),
                      ),
                      if (mensaje != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          mensaje,
                          key: const Key('mensaje'),
                          style: tt.bodySmall!.copyWith(
                            color: error == null ? t.naranjaProfundo : t.rojo,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: _listo && !cargando ? _entrar : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: t.verde,
                          foregroundColor: t.tarjeta,
                          disabledBackgroundColor: t.verde.withValues(
                            alpha: 0.45,
                          ),
                          disabledForegroundColor: t.tarjeta,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(radio),
                          ),
                          textStyle: tt.labelLarge!.copyWith(fontSize: 15),
                        ),
                        child: cargando
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: Plataforma.esIOS
                                    ? const CupertinoActivityIndicator(
                                        color: CupertinoColors.white,
                                      )
                                    : CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: t.tarjeta,
                                      ),
                              )
                            : const Text('Entrar'),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 6,
                        children: [
                          _Enlace(
                            '¿Olvidaste tu contraseña?',
                            () => _abrir(_urlRecuperar),
                          ),
                          Text('·', style: tt.bodySmall),
                          _Enlace('Crear cuenta', () => _abrir(_urlCrear)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Marca extends StatelessWidget {
  const _Marca();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/imagenes/isotipo.png', width: 44, height: 44),
        const SizedBox(width: 10),
        Text.rich(
          TextSpan(
            text: 'Recluta',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              fontSize: 26,
              letterSpacing: -0.8,
              color: t.verde,
            ),
            children: [
              TextSpan(
                text: 'Ya',
                style: TextStyle(color: t.naranja),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Campo extends StatelessWidget {
  const _Campo({
    required this.llave,
    required this.controlador,
    required this.etiqueta,
    required this.autofill,
    required this.accion,
    this.teclado,
    this.oculto = false,
    this.autofocus = false,
    this.sufijo,
    this.alEnviar,
  });

  final Key llave;
  final TextEditingController controlador;
  final String etiqueta;
  final List<String> autofill;
  final TextInputAction accion;
  final TextInputType? teclado;
  final bool oculto;
  final bool autofocus;
  final Widget? sufijo;
  final VoidCallback? alEnviar;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    OutlineInputBorder borde(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(radio),
      borderSide: BorderSide(color: c, width: w),
    );
    return TextField(
      key: llave,
      controller: controlador,
      keyboardType: teclado,
      obscureText: oculto,
      autofocus: autofocus,
      autocorrect: false,
      enableSuggestions: !oculto,
      autofillHints: autofill,
      textInputAction: accion,
      onSubmitted: alEnviar == null ? null : (_) => alEnviar!(),
      style: tt.bodyLarge,
      decoration: InputDecoration(
        labelText: etiqueta,
        labelStyle: tt.bodyMedium!.copyWith(color: t.tintaSuave),
        floatingLabelStyle: tt.labelMedium!.copyWith(color: t.verde),
        filled: true,
        fillColor: t.papel,
        suffixIcon: sufijo,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        enabledBorder: borde(t.linea),
        focusedBorder: borde(t.verde, 1.5),
        border: borde(t.linea),
      ),
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
    return GestureDetector(
      onTap: () {
        hapticoLigero();
        alTocar();
      },
      child: Text(
        texto,
        style: Theme.of(context).textTheme.labelMedium!
            .copyWith(color: t.verdeProfundo),
      ),
    );
  }
}
