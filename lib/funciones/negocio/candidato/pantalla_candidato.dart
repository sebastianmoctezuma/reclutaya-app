import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reclutaya_app/funciones/negocio/candidato/bloque_test.dart';
import 'package:reclutaya_app/funciones/negocio/candidato/bloque_video.dart';
import 'package:reclutaya_app/funciones/negocio/candidato/controlador_ficha.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/ficha_candidato.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/funciones/negocio/comun/revalidar_al_entrar.dart';
import 'package:reclutaya_app/nucleo/plataforma/adaptativos.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/ui/chip.dart';
import 'package:reclutaya_app/nucleo/ui/esqueleto.dart';
import 'package:reclutaya_app/nucleo/ui/estados.dart';
import 'package:reclutaya_app/nucleo/ui/tarjeta.dart';
import 'package:reclutaya_app/nucleo/ui/tesela.dart';
import 'package:reclutaya_app/nucleo/util/formato.dart';
import 'package:url_launcher/url_launcher.dart';

const _lados = EdgeInsets.symmetric(horizontal: 16);

/// La ficha del candidato, la misma del panel lateral de la web. Sin contactar
/// llega parcial (nombre corto, sin teléfono ni archivos) y así se pinta. Las
/// URLs firmadas vencen: si una falla, se pide la ficha otra vez, una sola vez.
class PantallaCandidato extends ConsumerStatefulWidget {
  const PantallaCandidato({required this.postulacionId, super.key});

  final String postulacionId;

  @override
  ConsumerState<PantallaCandidato> createState() => _PantallaCandidatoState();
}

class _PantallaCandidatoState extends ConsumerState<PantallaCandidato> {
  final _control = ControladorFicha();

  void _urlFallo() {
    if (_control.puedeReintentarUrl()) {
      ref.invalidate(candidatoProvider(widget.postulacionId));
    }
  }

  Future<void> _abrir(String url) async {
    // Dentro de la app (Safari View / Custom Tabs): la URL firmada no queda en
    // el historial del navegador.
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.inAppBrowserView,
    );
    if (!ok) _urlFallo();
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.postulacionId;
    final ficha = ref.watch(candidatoProvider(id));
    return RevalidarAlEntrar(
      alEntrar: (ref) {
        if (ref.exists(candidatoProvider(id)) &&
            ref.read(candidatoProvider(id)).hasValue) {
          ref.invalidate(candidatoProvider(id));
        }
      },
      child: PaginaConTitulo(
        // El nombre va UNA vez, en el encabezado de la ficha.
        titulo: 'Candidato',
        alRefrescar: () async {
          ref.invalidate(candidatoProvider(id));
          try {
            await ref.read(candidatoProvider(id).future);
          } on ErrorApi {
            // La pantalla ya muestra el error.
          }
        },
        slivers: [
          if (ficha.hasValue && ficha.error is SinRed)
            const SliverToBoxAdapter(child: BannerSinRed()),
          ...ficha.when(
            skipError: ficha.hasValue,
            data: (f) => [
              SliverPadding(
                padding: _lados,
                sliver: SliverList.list(children: _cuerpo(context, f)),
              ),
            ],
            loading: () => const [
              SliverPadding(
                padding: _lados,
                sliver: SliverToBoxAdapter(child: _Cargando()),
              ),
            ],
            error: (e, _) => [
              SliverToBoxAdapter(
                child: EstadoError(
                  error: e is ErrorApi ? e : const Servidor(),
                  alReintentar: () => e is NoEncontrado
                      ? context.pop()
                      : ref.invalidate(candidatoProvider(id)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _cuerpo(BuildContext context, FichaCandidato f) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final fase = switch (f.fase) {
      'contratado' => const ChipRY('Contratado', tono: TonoChip.verde),
      'no_respondio' => const ChipRY('No respondió', tono: TonoChip.naranja),
      'en_proceso' => const ChipRY('En proceso', tono: TonoChip.azul),
      'sin_iniciar' when f.contactado => const ChipRY(
        'Contactado',
        tono: TonoChip.azul,
      ),
      null when f.contratado => const ChipRY(
        'Contratado',
        tono: TonoChip.verde,
      ),
      null when f.noRespondio => const ChipRY(
        'No respondió',
        tono: TonoChip.naranja,
      ),
      null when f.contactado => const ChipRY('Contactado', tono: TonoChip.azul),
      _ => null,
    };
    final chips = <Widget>[
      ?fase,
      if (f.fechaLimite != null && !f.contratado && f.fase != 'no_respondio')
        ChipRY('Vence ${fechaCorta(f.fechaLimite!)}'),
      if (f.entregaFallo == 'sin_whatsapp')
        const ChipRY('Sin WhatsApp', tono: TonoChip.rojo),
    ];
    final razones = f.razones.isNotEmpty
        ? f.razones
        : [if (f.resumen != null && f.resumen!.trim().isNotEmpty) f.resumen!];
    final datos = <Widget>[
      if (f.whatsapp != null)
        _Dato(
          tesela: Tesela(icono: Icons.phone_rounded, color: t.verde),
          etiqueta: 'WhatsApp',
          valor: f.whatsapp!,
          extra: _Copiar(f.whatsapp!),
        ),
      if (f.zona != null)
        _Dato(
          tesela: Tesela(icono: Icons.place_rounded, color: t.azul),
          etiqueta: 'Zona',
          valor: f.zona!,
        ),
      if (f.minutosTraslado != null)
        _Dato(
          tesela: Tesela(icono: Icons.directions_car_rounded, color: t.azul),
          etiqueta: 'Traslado',
          valor: '~${f.minutosTraslado} min en auto',
        ),
      _Dato(
        tesela: Tesela(icono: Icons.work_rounded, color: t.naranja),
        etiqueta: 'Experiencia',
        valor: experiencia(f.experienciaMeses),
      ),
      if (f.turnoDisponible != null)
        _Dato(
          tesela: Tesela(icono: Icons.schedule_rounded, color: t.verdeProfundo),
          etiqueta: 'Turno',
          valor: f.turnoDisponible!,
        ),
      if (f.sueldoEsperado != null)
        _Dato(
          tesela: Tesela(icono: Icons.payments_rounded, color: t.verde),
          etiqueta: 'Sueldo esperado',
          valor: f.sueldoEsperado!,
        ),
    ];
    String estadoDe(Entregable e) => e.recibido
        ? 'Recibido'
        : e.solicitado
        ? 'Pedido'
        : 'Sin pedir';
    final estadoTest = switch (f.test.estado) {
      'RESPONDIDA' => 'Respondido',
      'NO_ENVIADA' => 'Sin enviar',
      _ => 'Enviado',
    };
    return [
      // Encabezado como el de Contactos de iOS: iniciales, nombre una vez, puntos y fase.
      Column(
        children: [
          Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: t.sobreVerde,
              boxShadow: sombraMd(t),
            ),
            child: Text(
              _iniciales(f.nombre),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 28,
                color: t.verdeProfundo,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Directo sobre el verde del fondo: en blanco.
          Text(
            f.nombre,
            textAlign: TextAlign.center,
            style: tt.headlineSmall!.copyWith(color: t.sobreVerde),
          ),
          if (f.score != null) ...[
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${f.score!.round()}',
                    style: tt.titleLarge!.copyWith(color: t.sobreVerde),
                  ),
                  TextSpan(
                    text: ' pts',
                    style: tt.bodySmall!.copyWith(
                      color: t.sobreVerde.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: chips,
            ),
          ],
        ],
      ),
      const SizedBox(height: 22),
      if (razones.isNotEmpty) ...[
        _Seccion(
          titulo: 'Por qué está en el ranking',
          tesela: Tesela(icono: Icons.auto_awesome_rounded, color: t.verde),
          hijo: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final r in razones)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: t.verde,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(r, style: tt.bodyMedium)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
      _Grupo(renglones: datos),
      const SizedBox(height: 12),
      _Seccion(
        titulo: 'Video',
        tesela: Tesela(icono: Icons.videocam_rounded, color: t.azul),
        estado: estadoDe(f.video),
        recibido: f.video.recibido,
        hijo: BloqueVideo(video: f.video, alFallarUrl: _urlFallo),
      ),
      const SizedBox(height: 12),
      _Seccion(
        titulo: 'Documento',
        tesela: Tesela(
          icono: Icons.description_rounded,
          color: t.verdeProfundo,
        ),
        estado: estadoDe(f.documento),
        recibido: f.documento.recibido,
        hijo: f.documento.url != null
            ? Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: () => _abrir(f.documento.url!),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Abrir documento'),
                  style: FilledButton.styleFrom(
                    backgroundColor: t.verdeBrillo,
                    foregroundColor: t.verdeProfundo,
                    shape: const StadiumBorder(),
                  ),
                ),
              )
            : Text(
                f.documento.solicitado
                    ? 'Pedido, aún no llega'
                    : 'Sin documento',
                style: tt.bodySmall,
              ),
      ),
      const SizedBox(height: 12),
      _Seccion(
        titulo: 'Test de compatibilidad',
        tesela: Tesela(icono: Icons.donut_large_rounded, color: t.naranja),
        estado: estadoTest,
        recibido: f.test.estado == 'RESPONDIDA',
        hijo: BloqueTest(test: f.test),
      ),
      if (f.respuestas.isNotEmpty) ...[
        const SizedBox(height: 12),
        _Seccion(
          titulo: 'Respuestas del formulario',
          tesela: Tesela(
            icono: Icons.checklist_rounded,
            color: t.verdeProfundo,
          ),
          hijo: _Respuestas(f.respuestas),
        ),
      ],
      if (f.extras.isNotEmpty) ...[
        const SizedBox(height: 12),
        _Seccion(
          titulo: 'Datos adicionales',
          tesela: Tesela(icono: Icons.badge_rounded, color: t.azul),
          hijo: _Respuestas(f.extras),
        ),
      ],
    ];
  }

  static String _iniciales(String nombre) {
    final partes = nombre
        .split(' ')
        .where((p) => p.isNotEmpty && p != '·')
        .toList();
    if (partes.isEmpty) return '';
    final a = partes.first.characters.first;
    final b = partes.length > 1 ? partes[1].characters.first : '';
    return (a + b).toUpperCase();
  }
}

/// Una tarjeta de la ficha: el cuadro de ícono, el título y, a la derecha, en qué va
/// (Recibido · Pedido · Sin pedir).
class _Seccion extends StatelessWidget {
  const _Seccion({
    required this.titulo,
    required this.tesela,
    required this.hijo,
    this.estado,
    this.recibido = false,
  });

  final String titulo;
  final Widget tesela;
  final Widget hijo;
  final String? estado;
  final bool recibido;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    return Tarjeta(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              tesela,
              const SizedBox(width: 10),
              Expanded(child: Text(titulo, style: tt.titleMedium)),
              if (estado != null)
                Text(
                  estado!,
                  style: tt.labelMedium!.copyWith(
                    color: recibido ? t.verdeProfundo : t.tintaSuave,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          hijo,
        ],
      ),
    );
  }
}

/// Los datos del candidato como lista agrupada de iOS: ícono, etiqueta chica y el
/// valor debajo (las zonas largas no se amontonan a la derecha).
class _Grupo extends StatelessWidget {
  const _Grupo({required this.renglones});

  final List<Widget> renglones;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Tarjeta(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (final (i, r) in renglones.indexed) ...[
            if (i > 0) Divider(height: 1, indent: 58, color: t.linea),
            r,
          ],
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({
    required this.tesela,
    required this.etiqueta,
    required this.valor,
    this.extra,
  });

  final Widget tesela;
  final String etiqueta;
  final String valor;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 11, 14, 11),
      child: Row(
        children: [
          tesela,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta, style: tt.bodySmall),
                const SizedBox(height: 1),
                Text(valor, style: tt.labelLarge),
              ],
            ),
          ),
          if (extra != null) ...[const SizedBox(width: 8), extra!],
        ],
      ),
    );
  }
}

/// Copia el WhatsApp. Abrir WhatsApp es acción: eso es la v2.
class _Copiar extends StatelessWidget {
  const _Copiar(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: texto));
        hapticoLigero();
        if (context.mounted) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            const SnackBar(
              content: Text('Número copiado'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: t.verdeBrillo,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          'Copiar',
          style: Theme.of(context).textTheme.labelSmall!
              .copyWith(color: t.verdeProfundo),
        ),
      ),
    );
  }
}

/// Las respuestas del formulario como en la web: la pregunta en chico, la respuesta
/// debajo y «No cumple» solo en la que le costó puntos. Todas a todo el ancho.
class _Respuestas extends StatelessWidget {
  const _Respuestas(this.lista);

  final List<Respuesta> lista;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, r) in lista.indexed)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: i == 0 ? null : Border(top: BorderSide(color: t.linea)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.texto, style: tt.bodySmall),
                const SizedBox(height: 3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        r.respuesta,
                        style: r.abierta ? tt.bodyMedium : tt.labelLarge,
                      ),
                    ),
                    if (r.incumple) ...[
                      const SizedBox(width: 8),
                      const ChipRY('No cumple', tono: TonoChip.rojo),
                    ],
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Esqueleto(alto: 52, ancho: 52, radio: 26),
            SizedBox(width: 12),
            Expanded(child: Esqueleto(alto: 20)),
          ],
        ),
        SizedBox(height: 16),
        Tarjeta(
          child: Column(
            children: [
              Esqueleto(alto: 14),
              SizedBox(height: 12),
              Esqueleto(alto: 14),
              SizedBox(height: 12),
              Esqueleto(alto: 14),
            ],
          ),
        ),
      ],
    );
  }
}
