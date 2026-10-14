import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';

/// Pide la ficha en cuanto el dedo TOCA la fila, no cuando se suelta (14-oct): entre
/// apoyar y soltar pasan ~100 ms que antes se esperaban sin hacer nada. Lo pedido queda
/// guardado como cualquier ficha abierta (`_conservarAlSalir`, 5 min): si el toque era
/// para desplazar la lista y no se abre, se suelta solo.
class PrecargaAlTocar extends ConsumerWidget {
  const PrecargaAlTocar.vacante(
    String this.slug, {
    required this.child,
    super.key,
  }) : postulacionId = null;

  const PrecargaAlTocar.candidato(
    String this.postulacionId, {
    required this.child,
    super.key,
  }) : slug = null;

  final String? slug;
  final String? postulacionId;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Listener(
    onPointerDown: (_) {
      if (slug case final s?) precargarVacante(ref, s);
      if (postulacionId case final id?) _pedir(ref, candidatoProvider(id));
    },
    child: child,
  );
}

/// La ficha Y el ranking de una vacante, a la vez.
void precargarVacante(WidgetRef ref, String slug) {
  _pedir(ref, vacanteProvider(slug));
  _pedir(ref, rankingProvider(slug));
}

/// Escuchar y soltar de inmediato: arranca la petición y deja corriendo el reloj de
/// `_conservarAlSalir`. Un dato ya en memoria no se vuelve a pedir.
void _pedir(WidgetRef ref, ProviderListenable<Object?> p) =>
    ref.listenManual(p, (_, _) {}).close();
