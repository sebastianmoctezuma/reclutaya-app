import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/nucleo/sesion/renovacion_core.dart';

void main() {
  group('clasificarFalloRenovacion (12-oct)', () {
    test('una falla de RED al renovar NO vence la sesión', () {
      expect(
        clasificarFalloRenovacion(
          reintentable: true,
          sinSesion: false,
          estado: null,
        ),
        FalloRenovacion.sinRed,
      );
    });

    test(
      'un error del servidor de Supabase (5xx) o un límite (429) tampoco',
      () {
        for (final estado in [500, 502, 503, 429]) {
          expect(
            clasificarFalloRenovacion(
              reintentable: false,
              sinSesion: false,
              estado: estado,
            ),
            FalloRenovacion.sinRed,
            reason: 'estado $estado',
          );
        }
      },
    );

    test('sin respuesta del servidor no se sabe: se queda la sesión', () {
      expect(
        clasificarFalloRenovacion(
          reintentable: false,
          sinSesion: false,
          estado: null,
        ),
        FalloRenovacion.sinRed,
      );
    });

    test(
      'un rechazo definitivo (token revocado, contraseña cambiada) sí la vence',
      () {
        for (final estado in [400, 401, 403, 404]) {
          expect(
            clasificarFalloRenovacion(
              reintentable: false,
              sinSesion: false,
              estado: estado,
            ),
            FalloRenovacion.vencida,
            reason: 'estado $estado',
          );
        }
      },
    );

    test('si no había sesión que renovar, está vencida', () {
      expect(
        clasificarFalloRenovacion(
          reintentable: false,
          sinSesion: true,
          estado: null,
        ),
        FalloRenovacion.vencida,
      );
    });
  });

  group('debeRenovarAntes', () {
    final ahora = DateTime.utc(2026, 10, 12, 18);
    int seg(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

    test('un token que vence en una hora se usa tal cual', () {
      expect(
        debeRenovarAntes(
          expiraEn: seg(ahora.add(const Duration(hours: 1))),
          ahora: ahora,
        ),
        isFalse,
      );
    });

    test('uno que vence dentro del margen se renueva antes de mandarlo', () {
      expect(
        debeRenovarAntes(
          expiraEn: seg(ahora.add(const Duration(seconds: 10))),
          ahora: ahora,
        ),
        isTrue,
      );
    });

    test(
      'uno ya vencido (la app estuvo horas en el fondo) se renueva antes',
      () {
        expect(
          debeRenovarAntes(
            expiraEn: seg(ahora.subtract(const Duration(hours: 3))),
            ahora: ahora,
          ),
          isTrue,
        );
      },
    );

    test('sin fecha de vencimiento no se toca', () {
      expect(debeRenovarAntes(expiraEn: null, ahora: ahora), isFalse);
    });
  });

  group('debeRefrescarAlVolver', () {
    test('tras más de un minuto fuera, sí', () {
      expect(
        debeRefrescarAlVolver(
          ausencia: const Duration(minutes: 5),
          hayError: false,
        ),
        isTrue,
      );
    });
    test('si apenas se salió unos segundos, no', () {
      expect(
        debeRefrescarAlVolver(
          ausencia: const Duration(seconds: 8),
          hayError: false,
        ),
        isFalse,
      );
    });
    test('si la pantalla se quedó en error, siempre', () {
      expect(
        debeRefrescarAlVolver(
          ausencia: const Duration(seconds: 2),
          hayError: true,
        ),
        isTrue,
      );
      expect(debeRefrescarAlVolver(ausencia: null, hayError: true), isTrue);
    });
  });
}
