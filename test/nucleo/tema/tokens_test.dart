import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclutaya_app/nucleo/tema/tema.dart';
import 'package:reclutaya_app/nucleo/tema/tokens.dart';

void main() {
  test('los tokens claros son los de la web', () {
    expect(Tokens.claro.papel, const Color(0xFFF7F7F4));
    expect(Tokens.claro.verde, const Color(0xFF146A43));
    expect(Tokens.claro.naranja, const Color(0xFFFF8A00));
    expect(Tokens.claro.tinta, const Color(0xFF1F2937));
  });

  test('el tema se deriva de los tokens', () {
    expect(temaClaro().scaffoldBackgroundColor, Tokens.claro.papel);
    expect(temaOscuro().scaffoldBackgroundColor, Tokens.oscuro.papel);
    expect(temaClaro().textTheme.headlineMedium!.fontFamily, 'Poppins');
    expect(temaClaro().textTheme.bodyMedium!.fontFamily, 'HankenGrotesk');
  });
}
