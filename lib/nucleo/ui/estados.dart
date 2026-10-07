import 'package:flutter/material.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';

/// Los cuatro estados de toda pantalla, en el tono de la web: texto claro,
/// sin ilustraciones genéricas, siempre una salida.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({required this.titulo, this.texto, super.key});

  final String titulo;
  final String? texto;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final tinta = context.t.tinta;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        children: [
          Text(
            titulo,
            style: tt.titleLarge!.copyWith(color: tinta),
            textAlign: TextAlign.center,
          ),
          if (texto != null) ...[
            const SizedBox(height: 8),
            Text(texto!, style: tt.bodySmall, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

class EstadoError extends StatelessWidget {
  const EstadoError({
    required this.error,
    required this.alReintentar,
    super.key,
  });

  final ErrorApi error;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final esSalida = error is NoEncontrado;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        children: [
          Icon(
            esSalida ? Icons.search_off_rounded : Icons.cloud_off_rounded,
            size: 36,
            color: t.tintaTenue,
          ),
          const SizedBox(height: 12),
          Text(error.mensaje, style: tt.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: alReintentar,
            style: FilledButton.styleFrom(
              backgroundColor: t.verde,
              foregroundColor: t.tarjeta,
              minimumSize: const Size(160, 46),
              shape: const StadiumBorder(),
              textStyle: tt.labelLarge,
            ),
            child: Text(esSalida ? 'Volver' : 'Reintentar'),
          ),
        ],
      ),
    );
  }
}

/// Banda arriba de la lista cuando la última carga no tuvo red y se muestra
/// lo que ya había en memoria.
class BannerSinRed extends StatelessWidget {
  const BannerSinRed({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: t.naranjaBrillo,
        borderRadius: BorderRadius.circular(radio),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 18, color: t.naranjaProfundo),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sin conexión. Esto es lo último que se cargó.',
              style: Theme.of(context).textTheme.labelMedium!
                  .copyWith(color: t.naranjaProfundo),
            ),
          ),
        ],
      ),
    );
  }
}
