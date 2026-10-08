import 'dart:convert';

import 'package:meta/meta.dart';

/// Varias cuentas en el mismo teléfono (8-oct), lógica PURA: la lista de cuentas
/// guardadas, el tope, cuál sigue al quitar una y qué hacer al tocar un aviso de otra
/// cuenta. Diseño: docs/superpowers/specs/2026-10-07-multicuenta-design.md.

/// Hasta 5 cuentas por teléfono (decisión del dueño).
const maxCuentas = 5;

/// Una cuenta guardada en el teléfono. `usuarioId` es el id de ReclutaYa (`/yo`), el
/// mismo que traen los avisos. El `refreshToken` vive solo en el llavero.
@immutable
class CuentaGuardada {
  const CuentaGuardada({
    required this.usuarioId,
    required this.negocio,
    required this.refreshToken,
    this.correo,
    this.logoUrl,
    this.logoFit,
    this.avisos = true,
  });

  final String usuarioId;
  final String negocio;
  final String? correo;
  final String? logoUrl;
  final String? logoFit;
  final String refreshToken;

  /// El interruptor de avisos de ESTA cuenta en este teléfono (decisión del dueño).
  final bool avisos;

  CuentaGuardada con({String? refreshToken, bool? avisos}) => CuentaGuardada(
    usuarioId: usuarioId,
    negocio: negocio,
    correo: correo,
    logoUrl: logoUrl,
    logoFit: logoFit,
    refreshToken: refreshToken ?? this.refreshToken,
    avisos: avisos ?? this.avisos,
  );

  Map<String, Object?> aJson() => {
    'usuarioId': usuarioId,
    'negocio': negocio,
    'correo': correo,
    'logoUrl': logoUrl,
    'logoFit': logoFit,
    'refreshToken': refreshToken,
    'avisos': avisos,
  };

  static CuentaGuardada? desdeJson(Object? j) {
    if (j is! Map) return null;
    final id = j['usuarioId'];
    final negocio = j['negocio'];
    final refresh = j['refreshToken'];
    if (id is! String || negocio is! String || refresh is! String) return null;
    String? texto(Object? v) => v is String ? v : null;
    return CuentaGuardada(
      usuarioId: id,
      negocio: negocio,
      refreshToken: refresh,
      correo: texto(j['correo']),
      logoUrl: texto(j['logoUrl']),
      logoFit: texto(j['logoFit']),
      avisos: j['avisos'] != false,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CuentaGuardada &&
      other.usuarioId == usuarioId &&
      other.negocio == negocio &&
      other.correo == correo &&
      other.logoUrl == logoUrl &&
      other.logoFit == logoFit &&
      other.refreshToken == refreshToken &&
      other.avisos == avisos;

  @override
  int get hashCode => Object.hash(
    usuarioId,
    negocio,
    correo,
    logoUrl,
    logoFit,
    refreshToken,
    avisos,
  );
}

/// La cuenta va primero (la más reciente). Si ya estaba, se actualiza; si es nueva y
/// ya hay [maxCuentas], no entra (`lleno`).
({List<CuentaGuardada> lista, bool lleno}) agregarCuenta(
  List<CuentaGuardada> lista,
  CuentaGuardada cuenta,
) {
  final ya = lista.any((c) => c.usuarioId == cuenta.usuarioId);
  if (!ya && lista.length >= maxCuentas) return (lista: lista, lleno: true);
  return (
    lista: [cuenta, ...lista.where((c) => c.usuarioId != cuenta.usuarioId)],
    lleno: false,
  );
}

List<CuentaGuardada> quitarCuenta(List<CuentaGuardada> lista, String id) =>
    lista.where((c) => c.usuarioId != id).toList();

/// La que toma su lugar al quitar `id`: la más reciente de las demás.
CuentaGuardada? siguienteCuenta(List<CuentaGuardada> lista, String id) {
  for (final c in lista) {
    if (c.usuarioId != id) return c;
  }
  return null;
}

enum AccionAviso { abrir, cambiarYAbrir, inicio }

/// Al tocar un aviso: de la cuenta activa (o sin cuenta, servidor anterior) se abre; de
/// otra cuenta guardada, se cambia a ella y se abre; de una que ya no está, al Inicio.
AccionAviso accionAviso({
  required String? activa,
  required String? usuarioIdAviso,
  required List<CuentaGuardada> cuentas,
}) {
  if (usuarioIdAviso == null || usuarioIdAviso == activa) {
    return AccionAviso.abrir;
  }
  return cuentas.any((c) => c.usuarioId == usuarioIdAviso)
      ? AccionAviso.cambiarYAbrir
      : AccionAviso.inicio;
}

String cuentasAJson(List<CuentaGuardada> l) =>
    jsonEncode([for (final c in l) c.aJson()]);

List<CuentaGuardada> cuentasDesdeJson(String? s) {
  if (s == null) return const [];
  try {
    final j = jsonDecode(s);
    if (j is! List) return const [];
    final r = <CuentaGuardada>[];
    for (final e in j) {
      final c = CuentaGuardada.desdeJson(e);
      if (c != null) r.add(c);
    }
    return r;
  } on FormatException {
    return const [];
  }
}
