import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/funciones/negocio/candidato/bloque_video.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/ficha_candidato.dart';
import 'package:reclutaya_app/nucleo/tema/tema.dart';

void main() {
  testWidgets(
    'una URL nueva reinicia el reproductor (no se queda en «falló»)',
    (tester) async {
      Widget app(String url) => MaterialApp(
        theme: temaClaro(),
        home: Scaffold(
          body: BloqueVideo(
            video: Entregable(solicitado: true, recibido: true, url: url),
            alFallarUrl: () {},
          ),
        ),
      );
      await tester.pumpWidget(app('https://x.test/a.mp4'));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('https://x.test/a.mp4')),
        findsOneWidget,
      );
      await tester.pumpWidget(app('https://x.test/b.mp4'));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('https://x.test/b.mp4')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('https://x.test/a.mp4')), findsNothing);
    },
  );
}
