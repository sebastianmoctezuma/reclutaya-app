import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reclutaya_app/funciones/acceso/pantalla_entrar.dart';
import 'package:reclutaya_app/funciones/arranque/pantalla_arranque.dart';
import 'package:reclutaya_app/funciones/cascaron/pantalla_cascaron.dart';
import 'package:reclutaya_app/funciones/cuenta/pantalla_cuenta.dart';
import 'package:reclutaya_app/funciones/negocio/candidato/pantalla_candidato.dart';
import 'package:reclutaya_app/funciones/negocio/inicio/pantalla_inicio.dart';
import 'package:reclutaya_app/funciones/negocio/vacantes/pantalla_vacante.dart';
import 'package:reclutaya_app/funciones/negocio/vacantes/pantalla_vacantes.dart';
import 'package:reclutaya_app/nucleo/rutas/guardas.dart';
import 'package:reclutaya_app/nucleo/sesion/providers.dart';

/// Avisa a go_router cuando la sesión cambia (entrar, salir, vencer).
class _Escucha extends ChangeNotifier {
  _Escucha(Stream<bool> s) {
    _sub = s.listen((_) => notifyListeners());
  }

  late final StreamSubscription<bool> _sub;

  @override
  void dispose() {
    unawaited(_sub.cancel());
    super.dispose();
  }
}

/// Las rutas de la app. Las pestañas van en un `StatefulShellRoute` con
/// `IndexedStack`: cada pestaña conserva su estado y su scroll, y el vidrio
/// nativo de la barra no se recrea al cambiar de pestaña.
final routerProvider = Provider<GoRouter>((ref) {
  final sesion = ref.watch(sesionProvider);
  final escucha = _Escucha(sesion.cambios);
  ref.onDispose(escucha.dispose);
  return GoRouter(
    initialLocation: '/arranque',
    refreshListenable: escucha,
    redirect: (_, estado) => redirigir(
      autenticado: sesion.autenticado,
      ruta: estado.matchedLocation,
    ),
    routes: [
      GoRoute(path: '/arranque', builder: (_, _) => const PantallaArranque()),
      GoRoute(path: '/entrar', builder: (_, _) => const PantallaEntrar()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => PantallaCascaron(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inicio',
                builder: (_, _) => const PantallaInicio(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/vacantes',
                builder: (_, _) => const PantallaVacantes(),
                routes: [
                  GoRoute(
                    path: ':slug',
                    builder: (_, s) =>
                        PantallaVacante(slug: s.pathParameters['slug']!),
                    routes: [
                      // El ranking vive dentro de la ficha (como en la web):
                      // esta ruta solo existe para la ficha del candidato.
                      GoRoute(
                        path: 'ranking',
                        redirect: (_, s) =>
                            s.fullPath == '/vacantes/:slug/ranking'
                            ? '/vacantes/${s.pathParameters['slug']}'
                            : null,
                        routes: [
                          GoRoute(
                            path: ':id',
                            builder: (_, s) => PantallaCandidato(
                              postulacionId: s.pathParameters['id']!,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cuenta',
                builder: (_, _) => const PantallaCuenta(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
