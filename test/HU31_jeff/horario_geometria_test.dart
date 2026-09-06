import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/pages/horario/horario.dart';

/// Geometría de los bloques del horario.
///
/// El bug (reportado el 2026-09-06 con una captura): DevOps de 7 a 9 no llegaba
/// a la línea de las 9. El bloque se bajaba 10 px y se le restaban 14 de alto,
/// así que mentía sobre su duración — y cuanto más corto el curso, más grande
/// era la mentira en proporción.
void main() {
  const h = HorarioPage.hourHeight;      // 85
  const off = HorarioPage.vertLineOffset; // 9, donde cae la línea de la hora

  ({double top, double height}) geom(double a, double b, {double lineOffset = off}) =>
      HorarioPage.blockGeometry(startVal: a, endVal: b, hourHeight: h, lineOffset: lineOffset);

  group('el bloque ocupa exactamente su duración', () {
    test('un curso de 7 a 9 llega a la línea de las 9', () {
      final g = geom(7, 9);
      // La línea de la hora N está en (N - 7) * alto + offset.
      const lineaDeLas9 = (9 - HorarioPage.startHour) * h + off;
      expect(g.top, (7 - HorarioPage.startHour) * h + off);
      expect(g.top + g.height, closeTo(lineaDeLas9, HorarioPage.blockHairline));
    });

    test('dura dos horas: el alto es dos veces el alto de hora, menos el pelo de separación', () {
      expect(geom(7, 9).height, 2 * h - HorarioPage.blockHairline);
    });

    test('el error viejo habría dejado el bloque 13 px corto', () {
      // Regresión explícita: 10 arriba + 14 de alto = 24 px de deuda, de los que
      // 13 se veían como hueco antes de la línea de fin.
      final g = geom(7, 9);
      expect(g.height, greaterThan(2 * h - 14));
    });

    test('una hora suelta y una hora y media también cuadran', () {
      expect(geom(9, 10).height, h - HorarioPage.blockHairline);
      expect(geom(20, 21.5).height, 1.5 * h - HorarioPage.blockHairline);
    });

    test('dos bloques seguidos no se solapan y quedan pegados por el pelo', () {
      final a = geom(7, 9), b = geom(9, 11);
      expect(a.top + a.height, lessThanOrEqualTo(b.top));
      expect(b.top - (a.top + a.height), HorarioPage.blockHairline);
    });
  });

  group('alineación con las líneas de hora', () {
    test('vertical: el bloque arranca en la línea de su hora (offset 9)', () {
      expect(geom(12, 13).top, (12 - HorarioPage.startHour) * h + 9);
    });

    test('horizontal: allí las líneas van en i*alto + labelPad, así que el offset es otro', () {
      // Antes el bloque usaba +10 fijo también en horizontal, donde las líneas
      // no llevan ese desplazamiento: quedaba descuadrado contra su propia hora.
      expect(geom(12, 13, lineOffset: 8).top, (12 - HorarioPage.startHour) * h + 8);
    });
  });

  group('bordes', () {
    test('un bloque degenerado no desaparece ni se vuelve negativo', () {
      expect(geom(9, 9).height, 8.0);
      expect(geom(9, 9.02).height, greaterThanOrEqualTo(8.0));
    });
    test('el primer y el último bloque del rango caen dentro', () {
      expect(geom(HorarioPage.startHour, HorarioPage.startHour + 1).top, off);
      final ultimo = geom(HorarioPage.endHour - 1, HorarioPage.endHour);
      expect(ultimo.top + ultimo.height,
          closeTo((HorarioPage.endHour - HorarioPage.startHour) * h + off, HorarioPage.blockHairline));
    });
  });
}
