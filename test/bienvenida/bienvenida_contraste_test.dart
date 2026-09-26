// test/bienvenida/bienvenida_contraste_test.dart
//
// UNITARIA · Bienvenida con Ulises (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-14. Los tokens nuevos en los dos temas y cada par de la tabla de
// contraste, con las dos excepciones de la spec.
// Archivo probado lib/configs/themes.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_logic.dart';

typedef _Token = Color Function(Brightness);

const _claro = Brightness.light;
const _oscuro = Brightness.dark;

void main() {
  group('los tokens nuevos (RF-BIEN-14)', () {
    final tabla = <String, (_Token, int, int)>{
      'bienvenidaFranja': (
        MaterialTheme.bienvenidaFranja,
        0xFFFF6600,
        0xFF262626,
      ),
      'bienvenidaPropia': (
        MaterialTheme.bienvenidaPropia,
        0xFFFFE7D4,
        0xFF3A2A22,
      ),
      'bienvenidaPropiaTinta': (
        MaterialTheme.bienvenidaPropiaTinta,
        0xFF6B2D00,
        0xFFFFC49A,
      ),
      'bienvenidaSaludo': (
        MaterialTheme.bienvenidaSaludo,
        0xFFFFFFFF,
        0xFF33333B,
      ),
      'bienvenidaSaludoTinta': (
        MaterialTheme.bienvenidaSaludoTinta,
        0xFF1A0E05,
        0xFFF5F5F7,
      ),
      'bienvenidaSaludoSub': (
        MaterialTheme.bienvenidaSaludoSub,
        0xFF7A3300,
        0xFFFFC49A,
      ),
      'bienvenidaEntrarFondo': (
        MaterialTheme.bienvenidaEntrarFondo,
        0xFFFFFFFF,
        0xFFFF8C42,
      ),
      'bienvenidaEntrarTinta': (
        MaterialTheme.bienvenidaEntrarTinta,
        0xFF1A0E05,
        0xFF16161C,
      ),
      'bienvenidaNuevoFondo': (
        MaterialTheme.bienvenidaNuevoFondo,
        0xFFB84A00,
        0x00000000,
      ),
      'bienvenidaNuevoBorde': (
        MaterialTheme.bienvenidaNuevoBorde,
        0xFFFFFFFF,
        0xFF5A5A66,
      ),
      'bienvenidaNuevoTinta': (
        MaterialTheme.bienvenidaNuevoTinta,
        0xFFFFFFFF,
        0xFFEDEDF3,
      ),
      'bienvenidaPildora': (
        MaterialTheme.bienvenidaPildora,
        0xFF0F172A,
        0xFF33333B,
      ),
      'bienvenidaPildoraLista': (
        MaterialTheme.bienvenidaPildoraLista,
        0xFF15803D,
        0xFF15803D,
      ),
      'bienvenidaGoogleFondo': (
        MaterialTheme.bienvenidaGoogleFondo,
        0xFFFFFFFF,
        0xFF131314,
      ),
      'bienvenidaGoogleBorde': (
        MaterialTheme.bienvenidaGoogleBorde,
        0xFF747775,
        0xFF8E918F,
      ),
      'bienvenidaGoogleTinta': (
        MaterialTheme.bienvenidaGoogleTinta,
        0xFF1F1F1F,
        0xFFE3E3E3,
      ),
      'bienvenidaFoco': (MaterialTheme.bienvenidaFoco, 0xFFD45500, 0xFFFF8C42),
    };

    for (final MapEntry(key: nombre, value: (token, claro, oscuro))
        in tabla.entries) {
      test('$nombre en claro y en oscuro', () {
        expect(token(_claro).toARGB32(), claro, reason: '$nombre claro');
        expect(token(_oscuro).toARGB32(), oscuro, reason: '$nombre oscuro');
      });
    }
  });

  group('la tabla de contraste (RF-BIEN-14)', () {
    void par(String nombre, Color texto, Color fondo, double esperado) {
      final razon = razonDeContraste(texto, fondo);
      expect(razon, closeTo(esperado, 0.01), reason: nombre);
    }

    for (final b in [_claro, _oscuro]) {
      final claro = b == _claro;
      test('cada par de la tabla en ${b.name}', () {
        par(
          'burbujas',
          MaterialTheme.textPrimary(b),
          MaterialTheme.cardBg(b),
          claro ? 17.85 : 14.22,
        );
        par(
          'nombre Ulises',
          MaterialTheme.testMuted(b),
          MaterialTheme.pageBg(b),
          claro ? 6.09 : 7.42,
        );
        par(
          'respuesta del alumno',
          MaterialTheme.bienvenidaPropiaTinta(b),
          MaterialTheme.bienvenidaPropia(b),
          claro ? 8.81 : 8.87,
        );
        par(
          'pregunta',
          MaterialTheme.bienvenidaSaludoTinta(b),
          MaterialTheme.bienvenidaSaludo(b),
          claro ? 18.94 : 11.50,
        );
        par(
          'saludo',
          MaterialTheme.bienvenidaSaludoSub(b),
          MaterialTheme.bienvenidaSaludo(b),
          claro ? 9.13 : 8.12,
        );
        par(
          'Sí, entrar',
          MaterialTheme.bienvenidaEntrarTinta(b),
          MaterialTheme.bienvenidaEntrarFondo(b),
          claro ? 18.94 : 7.79,
        );
        // Soy nuevo en oscuro es transparente sobre la franja.
        par(
          'Soy nuevo',
          MaterialTheme.bienvenidaNuevoTinta(b),
          claro
              ? MaterialTheme.bienvenidaNuevoFondo(b)
              : MaterialTheme.bienvenidaFranja(b),
          claro ? 5.23 : 12.98,
        );
        par(
          'pista',
          MaterialTheme.testMuted(b),
          MaterialTheme.testChipBg(b),
          claro ? 5.67 : 6.34,
        );
        par(
          'enlaces',
          MaterialTheme.testAccentText(b),
          MaterialTheme.cardBg(b),
          claro ? 5.23 : 7.91,
        );
        par(
          'rellenos',
          MaterialTheme.testAccentInk(b),
          MaterialTheme.testAccent(b),
          claro ? 6.45 : 7.79,
        );
        par(
          'píldora',
          Colors.white,
          MaterialTheme.bienvenidaPildora(b),
          claro ? 17.85 : 12.52,
        );
        par(
          'píldora lista',
          Colors.white,
          MaterialTheme.bienvenidaPildoraLista(b),
          5.02,
        );
        par(
          'Google',
          MaterialTheme.bienvenidaGoogleTinta(b),
          MaterialTheme.bienvenidaGoogleFondo(b),
          claro ? 16.48 : 14.47,
        );
        par(
          'borde de Google',
          MaterialTheme.bienvenidaGoogleBorde(b),
          claro
              ? MaterialTheme.bienvenidaGoogleFondo(b)
              : MaterialTheme.cardBg(b),
          claro ? 4.53 : 5.21,
        );
        par(
          'foco',
          MaterialTheme.bienvenidaFoco(b),
          MaterialTheme.cardBg(b),
          claro ? 4.12 : 7.17,
        );
        par(
          'sello',
          Colors.white,
          MaterialTheme.bienvenidaFranja(b),
          claro ? 2.94 : 15.13,
        );
      });
    }

    test('las dos excepciones son las de la spec', () {
      // El blanco sobre #FF6600 del sello es el de la cabecera de toda la app.
      expect(
        razonDeContraste(Colors.white, MaterialTheme.bienvenidaFranja(_claro)),
        lessThan(4.5),
      );
      // El logo del primer cuadro es un dibujo sin texto.
      expect(
        razonDeContraste(Colors.white, const Color(0xFFE77330)),
        closeTo(3.05, 0.01),
      );
    });
  });
}
