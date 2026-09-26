// test/six_seven/seis_siete_test.dart
//
// UNITARIA · Truco del 67 (specs/features/six-seven/six-seven.spec.md).
// RF-67-1 fija qué texto es un 67 y RF-67-2 la curva del tambaleo.
// Archivo probado lib/domain/seis_siete/seis_siete.dart.

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/domain/seis_siete/seis_siete.dart';

/// 3° en radianes.
const _tresGrados = 3 * math.pi / 180;

void main() {
  group('esSeisSiete (RF-67-1)', () {
    const disparan = [
      '67',
      '6 7',
      '6-7',
      'six seven',
      'six-seven',
      'SIX SEVEN',
      'Six-Seven',
      'sIx sEvEn',
      '  67  ',
      '67\n',
      '67!!!',
      '¡67!',
      '¡¡ 6 7 !!',
      '!six seven!',
      '6   7',
      'six\tseven',
      ' 67 ',
    ];
    const noDisparan = [
      '667',
      '1967',
      '676',
      '6767',
      '67 soles',
      'tengo 67 de nota',
      'el 67',
      '6.7',
      '6,7',
      '6/7',
      '67%',
      '67?',
      '6 - 7',
      '6–7',
      '6!7',
      'sixseven',
      'six 7',
      '6 seven',
      'seis siete',
      '67 🙌',
      '"67"',
      '(67)',
      '',
      '   ',
      '!!!',
    ];

    for (final texto in disparan) {
      test('«$texto» dispara', () => expect(esSeisSiete(texto), isTrue));
    }
    for (final texto in noDisparan) {
      test('«$texto» no dispara', () => expect(esSeisSiete(texto), isFalse));
    }
  });

  group('anguloSeisSiete (RF-67-2)', () {
    test('la amplitud es 3° y el tambaleo dura 2000 ms en 4 ciclos', () {
      expect(amplitudSeisSiete, closeTo(0.05236, 1e-5));
      expect(ciclosSeisSiete, 4);
      expect(duracionSeisSiete, const Duration(milliseconds: 2000));
    });

    test('da 0 al empezar, a mitad de un ciclo, a la mitad y al terminar', () {
      for (final progreso in [0.0, 0.125, 0.5, 1.0]) {
        expect(
          anguloSeisSiete(progreso),
          closeTo(0, 1e-9),
          reason: '$progreso',
        );
      }
    });

    test(
      'el primer vaivén va a la izquierda (−3°) y el segundo a la derecha',
      () {
        expect(anguloSeisSiete(0.0625), closeTo(-_tresGrados, 1e-9));
        expect(anguloSeisSiete(0.1875), closeTo(_tresGrados, 1e-9));
      },
    );

    test('nunca pasa de 3° en 1001 puntos entre 0 y 1', () {
      for (var i = 0; i <= 1000; i++) {
        expect(
          anguloSeisSiete(i / 1000).abs(),
          lessThanOrEqualTo(_tresGrados + 1e-12),
        );
      }
    });

    test('fuera de 0 a 1 da 0', () {
      expect(anguloSeisSiete(-0.1), 0);
      expect(anguloSeisSiete(1.1), 0);
    });
  });
}
