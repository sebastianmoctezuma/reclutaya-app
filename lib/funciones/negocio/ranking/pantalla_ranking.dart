import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reclutaya_app/funciones/negocio/comun/providers.dart';
import 'package:reclutaya_app/funciones/negocio/ranking/fila_candidato.dart';
import 'package:reclutaya_app/nucleo/plataforma/adaptativos.dart';
import 'package:reclutaya_app/nucleo/red/errores_api.dart';
import 'package:reclutaya_app/nucleo/ui/estados.dart';

const _lados = EdgeInsets.fromLTRB(16, 0, 16, 0);

/// El ranking, tal como lo manda el servidor: ordenado y enmascarado. Los
/// bloqueados (modelo viejo) van al final, difuminados.
class PantallaRanking extends ConsumerWidget {
  const PantallaRanking({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ranking = ref.watch(rankingProvider(slug));
    final tt = Theme.of(context).textTheme;
    return PaginaConTitulo(
      titulo: 'Ranking',
      alRefrescar: () async {
        ref.invalidate(rankingProvider(slug));
        try {
          await ref.read(rankingProvider(slug).future);
        } on ErrorApi {
          // La pantalla ya muestra el error.
        }
      },
      slivers: [
        if (ranking.hasValue && ranking.error is SinRed)
          const SliverToBoxAdapter(child: BannerSinRed()),
        ...ranking.when(
          skipError: ranking.hasValue,
          data: (r) {
            if (r.visibles.isEmpty && r.bloqueados.isEmpty) {
              return const [
                SliverToBoxAdapter(
                  child: EstadoVacio(
                    titulo: 'Aún no hay ranking',
                    texto: 'Genera el ranking desde la web y aquí verás a los candidatos ordenados.',
                  ),
                ),
              ];
            }
            final n = r.total;
            return [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    '$n ${n == 1 ? 'candidato, ordenado' : 'candidatos, ordenados'} por qué tan bien encajan',
                    style: tt.bodySmall,
                  ),
                ),
              ),
              SliverPadding(
                padding: _lados,
                sliver: SliverList.separated(
                  itemCount: r.visibles.length + r.bloqueados.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    if (i < r.visibles.length) {
                      final f = r.visibles[i];
                      return FilaCandidato(
                        fila: f,
                        alTocar: () => context.go(
                          '/vacantes/$slug/ranking/${f.postulacionId}',
                        ),
                      );
                    }
                    return FilaBloqueada(
                      bloqueado: r.bloqueados[i - r.visibles.length],
                    );
                  },
                ),
              ),
            ];
          },
          loading: () => [
            SliverPadding(
              padding: _lados,
              sliver: SliverList.separated(
                itemCount: 6,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, _) => const EsqueletoFilaCandidato(),
              ),
            ),
          ],
          error: (e, _) => [
            SliverToBoxAdapter(
              child: EstadoError(
                error: e is ErrorApi ? e : const Servidor(),
                alReintentar: () => ref.invalidate(rankingProvider(slug)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
