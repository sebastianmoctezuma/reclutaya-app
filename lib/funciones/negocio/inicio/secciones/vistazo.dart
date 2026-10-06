import 'package:flutter/material.dart';
import 'package:reclutaya_app/funciones/negocio/comun/modelos/inicio.dart';
import 'package:reclutaya_app/funciones/negocio/inicio/secciones/comunes.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';
import 'package:reclutaya_app/nucleo/util/formato.dart';

/// «De un vistazo»: vacantes abiertas, candidatos nuevos, contactos disponibles y
/// contrataciones del mes, como renglones agrupados de iOS. Con un servidor anterior
/// (sin `resumen`) solo queda el renglón de contactos, si la cuenta ve el saldo.
class Vistazo extends StatelessWidget {
  const Vistazo({this.resumen, this.saldo, super.key});

  final ResumenInicio? resumen;
  final Saldo? saldo;

  static bool hayAlgo(ResumenInicio? r, Saldo? s) => r != null || s != null;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final r = resumen;
    final contactos = r != null && r.ilimitada
        ? '∞'
        : (r?.contactos ?? saldo?.total) == null
        ? null
        : numero((r?.contactos ?? saldo?.total)!);
    final renglones = <Widget>[
      if (r != null)
        _Dato(
          tesela: Tesela(
            icono: Icons.work_outline_rounded,
            color: t.verdeProfundo,
            fondo: t.verdeBrillo,
          ),
          valor: numero(r.vacantesAbiertas),
          etiqueta: 'Vacantes abiertas',
        ),
      if (r != null)
        _Dato(
          tesela: Tesela(
            icono: Icons.person_add_alt_1_outlined,
            color: t.azul,
            fondo: t.azulBrillo,
          ),
          valor: numero(r.candidatosNuevos),
          etiqueta: 'Candidatos nuevos',
        ),
      if (contactos != null)
        _Dato(
          tesela: Tesela(
            icono: Icons.contact_phone_outlined,
            color: t.verde,
            fondo: t.verdeSuave,
          ),
          valor: contactos,
          etiqueta: 'Contactos disponibles',
        ),
      if (r != null)
        _Dato(
          tesela: Tesela(
            icono: Icons.handshake_outlined,
            color: t.naranjaProfundo,
            fondo: t.naranjaBrillo,
          ),
          valor: numero(r.contratacionesMes),
          etiqueta: 'Contrataciones · mes',
        ),
    ];
    return Grupo(renglones: renglones);
  }
}

class _Dato extends StatelessWidget {
  const _Dato({
    required this.tesela,
    required this.valor,
    required this.etiqueta,
  });

  final Widget tesela;
  final String valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Renglon(
      inicio: tesela,
      hijo: Text(etiqueta, style: tt.bodyLarge),
      final_: Text(valor, style: tt.headlineSmall!.copyWith(fontSize: 22)),
    );
  }
}
