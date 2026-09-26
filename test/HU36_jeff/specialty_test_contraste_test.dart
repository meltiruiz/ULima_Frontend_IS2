// test/HU36_jeff/specialty_test_contraste_test.dart
//
// Pruebas unitarias de HU36, el test de especialidad, sobre el modo oscuro y
// el contraste (RF-TEST-12).
// Tokens:  lib/configs/themes.dart
// Lógica:  lib/pages/specialty_test/specialty_test_logic.dart
//
// Las cifras son las de las tablas de RF-TEST-12, redondeadas a dos
// decimales. Las mezclas (tarjeta encendida, tarjeta del resultado e
// insignia «IA») se redondean a 8 bits por canal, como las pinta la pantalla.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_logic.dart';

const Brightness _claro = Brightness.light;
const Brightness _oscuro = Brightness.dark;
const Color _blanco = Color(0xFFFFFFFF);

Matcher _cifra(double valor) => closeTo(valor, 0.006);

double _c(Color a, Color b) => razonDeContraste(a, b);

/// Los colores de las especialidades en la versión 2026-09-25.4.
const Map<String, (String, String)> _colores = {
  'sw': ('#1E3A8A', '#A5C0F7'),
  'ti': ('#0F7A45', '#7EE8BE'),
  'si': ('#9333EA', '#B98AF8'),
  'vj': ('#76164A', '#EC7FB3'),
};

void main() {
  group('UNITARIA · Tokens del test en los dos temas (RF-TEST-12)', () {
    test('caso 1: cada token tiene el valor de la tabla', () {
      final tabla = <String, (Color Function(Brightness), int, int)>{
        'testInk2': (MaterialTheme.testInk2, 0xFF334155, 0xFFCFCFDB),
        'testMuted': (MaterialTheme.testMuted, 0xFF556070, 0xFFA5A5B5),
        'testLine': (MaterialTheme.testLine, 0xFFE2E8F0, 0xFF30303A),
        'testChipBg': (MaterialTheme.testChipBg, 0xFFEEF2F7, 0xFF24242C),
        'testAccent': (MaterialTheme.testAccent, 0xFFFF6600, 0xFFFF8C42),
        'testAccentHi': (MaterialTheme.testAccentHi, 0xFFFF7F24, 0xFFFF9D5C),
        'testAccentInk': (MaterialTheme.testAccentInk, 0xFF1A0E05, 0xFF16161C),
        'testAccentText': (
          MaterialTheme.testAccentText,
          0xFFB84A00,
          0xFFFF9A57,
        ),
        'testAccentDeep': (
          MaterialTheme.testAccentDeep,
          0xFF7A3300,
          0xFFFFC49A,
        ),
        'testAccentSoft': (
          MaterialTheme.testAccentSoft,
          0xFFFFF1E6,
          0xFF3A2A22,
        ),
        'testHeartOff': (MaterialTheme.testHeartOff, 0xFF64748B, 0xFF9A9AAC),
        'testTrack': (MaterialTheme.testTrack, 0xFFE8EDF3, 0xFF2C2C36),
        'testFeatherOn': (MaterialTheme.testFeatherOn, 0xFFD45500, 0xFFFF8C42),
        'testFeatherOff': (
          MaterialTheme.testFeatherOff,
          0xFFCBD5E1,
          0xFF3A3A46,
        ),
        'testTaskTileBg': (
          MaterialTheme.testTaskTileBg,
          0xFFF1F5F9,
          0xFF25252D,
        ),
        'testTaskIconInk': (
          MaterialTheme.testTaskIconInk,
          0xFF64748B,
          0xFF8A8A9C,
        ),
        'testAiBadgeBg': (MaterialTheme.testAiBadgeBg, 0x61140A50, 0xFF16161C),
      };
      for (final fila in tabla.entries) {
        final (token, claro, oscuro) = fila.value;
        expect(token(_claro), Color(claro), reason: '${fila.key} en claro');
        expect(token(_oscuro), Color(oscuro), reason: '${fila.key} en oscuro');
      }
    });

    test('caso 2: los pares del test llegan a las cifras de la tabla', () {
      final pagina = MaterialTheme.pageBg;
      final tarjeta = MaterialTheme.cardBg;
      final texto = MaterialTheme.textPrimary;
      // (par, claro, oscuro)
      final pares = <(String, double, double, double, double)>[
        (
          'texto sobre página',
          _c(texto(_claro), pagina(_claro)),
          17.06,
          _c(texto(_oscuro), pagina(_oscuro)),
          15.45,
        ),
        (
          'texto sobre tarjeta',
          _c(texto(_claro), tarjeta(_claro)),
          17.85,
          _c(texto(_oscuro), tarjeta(_oscuro)),
          14.22,
        ),
        (
          'testInk2 sobre tarjeta',
          _c(MaterialTheme.testInk2(_claro), tarjeta(_claro)),
          10.35,
          _c(MaterialTheme.testInk2(_oscuro), tarjeta(_oscuro)),
          10.74,
        ),
        (
          'testMuted sobre página',
          _c(MaterialTheme.testMuted(_claro), pagina(_claro)),
          6.09,
          _c(MaterialTheme.testMuted(_oscuro), pagina(_oscuro)),
          7.42,
        ),
        (
          'testMuted sobre tarjeta',
          _c(MaterialTheme.testMuted(_claro), tarjeta(_claro)),
          6.38,
          _c(MaterialTheme.testMuted(_oscuro), tarjeta(_oscuro)),
          6.83,
        ),
        (
          'testAccentText sobre página',
          _c(MaterialTheme.testAccentText(_claro), pagina(_claro)),
          5.00,
          _c(MaterialTheme.testAccentText(_oscuro), pagina(_oscuro)),
          8.59,
        ),
        (
          'testAccentInk sobre testAccent',
          _c(
            MaterialTheme.testAccentInk(_claro),
            MaterialTheme.testAccent(_claro),
          ),
          6.45,
          _c(
            MaterialTheme.testAccentInk(_oscuro),
            MaterialTheme.testAccent(_oscuro),
          ),
          7.79,
        ),
        (
          'testAccentInk sobre testAccentHi',
          _c(
            MaterialTheme.testAccentInk(_claro),
            MaterialTheme.testAccentHi(_claro),
          ),
          7.50,
          _c(
            MaterialTheme.testAccentInk(_oscuro),
            MaterialTheme.testAccentHi(_oscuro),
          ),
          8.78,
        ),
        (
          'testAccentDeep sobre testAccentSoft',
          _c(
            MaterialTheme.testAccentDeep(_claro),
            MaterialTheme.testAccentSoft(_claro),
          ),
          8.25,
          _c(
            MaterialTheme.testAccentDeep(_oscuro),
            MaterialTheme.testAccentSoft(_oscuro),
          ),
          8.87,
        ),
        (
          'ícono testAccentText sobre testAccentSoft',
          _c(
            MaterialTheme.testAccentText(_claro),
            MaterialTheme.testAccentSoft(_claro),
          ),
          4.72,
          _c(
            MaterialTheme.testAccentText(_oscuro),
            MaterialTheme.testAccentSoft(_oscuro),
          ),
          6.53,
        ),
        (
          'testMuted sobre testChipBg',
          _c(MaterialTheme.testMuted(_claro), MaterialTheme.testChipBg(_claro)),
          5.67,
          _c(
            MaterialTheme.testMuted(_oscuro),
            MaterialTheme.testChipBg(_oscuro),
          ),
          6.34,
        ),
        (
          'testFeatherOn sobre página',
          _c(MaterialTheme.testFeatherOn(_claro), pagina(_claro)),
          3.94,
          _c(MaterialTheme.testFeatherOn(_oscuro), pagina(_oscuro)),
          7.79,
        ),
        (
          'testHeartOff sobre página',
          _c(MaterialTheme.testHeartOff(_claro), pagina(_claro)),
          4.55,
          _c(MaterialTheme.testHeartOff(_oscuro), pagina(_oscuro)),
          6.51,
        ),
      ];
      for (final (nombre, claro, cifraClaro, oscuro, cifraOscuro) in pares) {
        expect(claro, _cifra(cifraClaro), reason: '$nombre en claro');
        expect(oscuro, _cifra(cifraOscuro), reason: '$nombre en oscuro');
      }
    });

    test('caso 3: el héroe, la pastilla de afinidad y los avisos de error', () {
      const tinta = Color(0xFF1A0E05);
      expect(_c(tinta, const Color(0xFFFF6600)), _cifra(6.45));
      expect(_c(tinta, const Color(0xFFFFB020)), _cifra(10.36));
      for (final b in Brightness.values) {
        expect(_c(_blanco, MaterialTheme.errorBg(b)), _cifra(6.54));
        // Estrella y «Tu principal» en testAccentText sobre la página.
        expect(
          _c(MaterialTheme.testAccentText(b), MaterialTheme.pageBg(b)),
          greaterThanOrEqualTo(kContrasteTexto),
        );
      }
    });

    test('caso 4: la cabecera del asistente en claro es la única excepción '
        'al 4,5:1', () {
      expect(_c(_blanco, MaterialTheme.headerColor(_claro)), _cifra(2.94));
      expect(
        _c(_blanco, MaterialTheme.headerColor(_claro)),
        lessThan(kContrasteTexto),
      );
      expect(_c(_blanco, MaterialTheme.headerColor(_oscuro)), _cifra(16.58));
    });
  });

  group('UNITARIA · Colores de las especialidades (RF-TEST-12)', () {
    test('caso 5: cada color del contenido da las cifras de la tabla', () {
      // Por clave, sobre blanco, sobre #F8FAFC, tinta sobre tarjeta encendida,
      //         oscuro sobre #1E1E24, oscuro sobre #16161C,
      //         tinta sobre la tarjeta del resultado, color sobre ella)
      const cifras = <String, List<double>>{
        'sw': [10.36, 9.90, 14.45, 9.07, 9.85, 9.57, 6.10],
        'ti': [5.40, 5.16, 15.10, 11.19, 12.16, 9.12, 7.18],
        'si': [5.38, 5.14, 14.97, 6.36, 6.91, 10.48, 4.69],
        'vj': [10.58, 10.12, 14.31, 6.52, 7.08, 10.50, 4.81],
      };
      for (final clave in _colores.keys) {
        final claro = colorDeHex(_colores[clave]!.$1)!;
        final oscuro = colorDeHex(_colores[clave]!.$2)!;
        final encendida = tinte(claro, MaterialTheme.cardBg(_claro), 0.12);
        final resultado = tinte(oscuro, MaterialTheme.cardBg(_oscuro), 0.18);
        final c = cifras[clave]!;
        expect(_c(claro, _blanco), _cifra(c[0]), reason: '$clave sobre blanco');
        expect(
          _c(claro, MaterialTheme.pageBg(_claro)),
          _cifra(c[1]),
          reason: '$clave sobre la página',
        );
        expect(
          _c(MaterialTheme.textPrimary(_claro), encendida),
          _cifra(c[2]),
          reason: '$clave tarjeta encendida',
        );
        expect(
          _c(oscuro, MaterialTheme.cardBg(_oscuro)),
          _cifra(c[3]),
          reason: '$clave oscuro sobre la tarjeta',
        );
        expect(
          _c(oscuro, MaterialTheme.pageBg(_oscuro)),
          _cifra(c[4]),
          reason: '$clave oscuro sobre la página',
        );
        expect(
          _c(MaterialTheme.textPrimary(_oscuro), resultado),
          _cifra(c[5]),
          reason: '$clave tinta sobre el resultado',
        );
        expect(
          _c(oscuro, resultado),
          _cifra(c[6]),
          reason: '$clave título sobre el resultado',
        );
        // En claro, el extremo oscuro del degradado solo sube el contraste
        // del blanco.
        expect(_c(_blanco, oscurecido(claro)), greaterThan(_c(_blanco, claro)));
      }
    });

    test('caso 6: la insignia «IA» llega a su cifra en los dos temas', () {
      final claro = <double>[];
      final oscuro = <double>[];
      for (final par in _colores.values) {
        final insignia = MaterialTheme.testAiBadgeBg(_claro);
        final fondoClaro = tinte(
          insignia.withValues(alpha: 1),
          colorDeHex(par.$1)!,
          insignia.a,
        );
        claro.add(_c(_blanco, fondoClaro));
        oscuro.add(
          _c(colorDeHex(par.$2)!, MaterialTheme.testAiBadgeBg(_oscuro)),
        );
      }
      claro.sort();
      oscuro.sort();
      expect(claro.first, _cifra(8.79));
      expect(claro.last, _cifra(13.69));
      expect(oscuro.first, _cifra(6.91));
      expect(oscuro.last, _cifra(12.16));
    });
  });

  group('UNITARIA · Guarda en tiempo de ejecución (RF-TEST-12)', () {
    test('caso 7: un color que llega al mínimo se usa tal cual', () {
      final sw = colorDeHex('#1E3A8A');
      expect(colorQueSeLee(sw, fondo: _blanco, respaldo: Colors.black), sw);
    });

    test('caso 8: un color que no llega cae al respaldo como texto, y como '
        'ícono solo si baja de 3:1', () {
      // #FF9900 sobre blanco da 2,14:1; #D97706 da 3,19:1.
      const flojo = Color(0xFFFF9900);
      const justo = Color(0xFFD97706);
      final respaldo = MaterialTheme.textPrimary(_claro);
      expect(
        colorQueSeLee(flojo, fondo: _blanco, respaldo: respaldo),
        respaldo,
      );
      expect(
        colorQueSeLee(
          flojo,
          fondo: _blanco,
          respaldo: respaldo,
          esTexto: false,
        ),
        respaldo,
      );
      expect(
        colorQueSeLee(justo, fondo: _blanco, respaldo: respaldo),
        respaldo,
      );
      expect(
        colorQueSeLee(
          justo,
          fondo: _blanco,
          respaldo: respaldo,
          esTexto: false,
        ),
        justo,
      );
    });

    test('caso 9: un hex roto cuenta como neutro y cae al respaldo', () {
      for (final roto in <String?>['naranja', '#12345', '#GGGGGG', '', null]) {
        expect(colorDeHex(roto), isNull, reason: '$roto');
        expect(
          colorQueSeLee(
            colorDeHex(roto),
            fondo: _blanco,
            respaldo: Colors.black,
          ),
          Colors.black,
        );
      }
      expect(colorDeHex(' #1e3a8a '), const Color(0xFF1E3A8A));
    });
  });
}
