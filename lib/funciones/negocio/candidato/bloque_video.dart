import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/ficha_candidato.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:video_player/video_player.dart';

/// El video del candidato, dentro de la app. Si la URL firmada falla, avisa
/// (`alFallarUrl`) para que la pantalla pida la ficha otra vez.
class BloqueVideo extends StatelessWidget {
  const BloqueVideo({
    required this.video,
    required this.alFallarUrl,
    super.key,
  });

  final Entregable video;
  final VoidCallback alFallarUrl;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    if (video.url != null) {
      // Llave por URL: una URL nueva (ficha repedida) reinicia el reproductor.
      return _Reproductor(
        key: ValueKey(video.url!),
        url: video.url!,
        alFallar: alFallarUrl,
      );
    }
    if (video.solicitado) {
      return Text('Pedido, aún no llega', style: tt.bodySmall);
    }
    return Text('Sin video', style: tt.bodySmall);
  }
}

class _Reproductor extends StatefulWidget {
  const _Reproductor({required this.url, required this.alFallar, super.key});

  final String url;
  final VoidCallback alFallar;

  @override
  State<_Reproductor> createState() => _ReproductorState();
}

class _ReproductorState extends State<_Reproductor> {
  VideoPlayerController? _video;
  ChewieController? _chewie;
  bool _fallo = false;

  @override
  void initState() {
    super.initState();
    unawaited(_preparar());
  }

  Future<void> _preparar() async {
    try {
      final v = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await v.initialize();
      if (!mounted) {
        await v.dispose();
        return;
      }
      setState(() {
        _video = v;
        _chewie = ChewieController(
          videoPlayerController: v,
          aspectRatio: v.value.aspectRatio == 0 ? 16 / 9 : v.value.aspectRatio,
          showOptions: false,
          materialProgressColors: ChewieProgressColors(
            playedColor: context.t.verde,
            handleColor: context.t.verde,
          ),
        );
      });
    } on Object {
      if (!mounted) return;
      setState(() => _fallo = true);
      widget.alFallar();
    }
  }

  @override
  void dispose() {
    _chewie?.dispose();
    unawaited(_video?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    if (_fallo) {
      return Text(
        'El video ya no está disponible. Vuelve a abrir la ficha.',
        style: tt.bodySmall,
      );
    }
    final chewie = _chewie;
    if (chewie == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: t.papel,
            borderRadius: BorderRadius.circular(radio),
          ),
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radio),
      child: AspectRatio(
        aspectRatio: chewie.aspectRatio ?? 16 / 9,
        child: Chewie(controller: chewie),
      ),
    );
  }
}
