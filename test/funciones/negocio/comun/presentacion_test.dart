import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/funciones/negocio/comun/presentacion.dart';

void main() {
  test('«Cumple X de Y» solo cuando la vacante pide requisitos', () {
    expect(textoCumple(1, 4), 'Cumple 3 de 4');
    expect(textoCumple(0, 0), isNull);
  });

  test('días restantes en singular, plural y hoy', () {
    expect(textoDiasRestantes(40), '40 días restantes');
    expect(textoDiasRestantes(1), '1 día restante');
    expect(textoDiasRestantes(0), 'Vence hoy');
    expect(textoDiasRestantes(null), isNull);
  });

  test('rol traducido; desconocido no truena', () {
    expect(etiquetaRol('owner'), 'Dueño');
    expect(etiquetaRol('admin'), 'Administrador');
    expect(etiquetaRol('member'), 'Miembro');
    expect(etiquetaRol(null), 'Miembro');
  });

  test('delta con signo, unidad y tono', () {
    expect(delta(10, '%'), (texto: '+10%', tono: TonoDelta.sube));
    expect(delta(-3, '%'), (texto: '-3%', tono: TonoDelta.baja));
    expect(delta(0, ' días'), (texto: 'Sin cambio', tono: TonoDelta.neutro));
    expect(delta(null, '%'), (texto: '—', tono: TonoDelta.neutro));
  });

  test('la paleta de sucursales es la de la web y da la vuelta', () {
    expect(colorSucursal(0, oscuro: false), const Color(0xFF1F5E3A));
    expect(colorSucursal(5, oscuro: false), const Color(0xFF1F5E3A));
    expect(colorSucursal(1, oscuro: true), const Color(0xFFEDA04F));
  });

  test('material: pedido, recibido o nada', () {
    expect(textoMaterial(solicitado: true, recibido: true), 'Recibido');
    expect(textoMaterial(solicitado: true, recibido: false), 'Pedido');
    expect(textoMaterial(solicitado: false, recibido: false), isNull);
  });

  test('estado de la vacante en palabras y ajuste del logo', () {
    expect(textoEstadoVacante('ACTIVA'), 'Activa');
    expect(textoEstadoVacante('PAUSADA'), 'En pausa');
    expect(ajusteLogo('cover'), BoxFit.cover);
    expect(ajusteLogo(null), BoxFit.contain);
    expect(textoTraslado(20), 'a 20 min');
    expect(textoTraslado(null), '');
  });
}
