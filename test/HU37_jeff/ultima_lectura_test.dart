// test/HU37_jeff/ultima_lectura_test.dart
//
// UNITARIA · Recarga desde la ULima (specs/features/recarga-portal/
// recarga-portal.spec.md), RF-RCG-9, la hora de la última lectura.
// Archivo probado lib/domain/recarga_ulima/ultima_lectura.dart.
//
// Las fechas van en UTC, y Lima está 5 horas atrás todo el año, así que las
// 15:42 UTC son las 10:42 de Lima.
//
// Dart no cambia la zona horaria dentro del proceso, así que el caso del
// teléfono en otra zona depende de la zona de la máquina que corre la prueba.
// La suite corre solo en una máquina local, porque
// `.github/workflows/build-apk.yml` no corre `flutter test`. En una máquina en
// UTC−5, `toLocal()` deja las dos fechas en la hora de Lima, y ese caso no
// distingue una hora calculada en la zona del teléfono. Con `TZ=UTC`, este
// archivo falla si `cuandoSeLeyo` usa `toLocal()` en lugar de `enHoraDeLima`,
// así que la verificación lo corre también con
// `TZ=UTC flutter test --no-pub test/HU37_jeff/ultima_lectura_test.dart`.

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/domain/recarga_ulima/ultima_lectura.dart';

void main() {
  group('UNITARIA · cuandoSeLeyo (RF-RCG-9)', () {
    final ahora = DateTime.utc(
      2026,
      9,
      25,
      20,
    ); // 25 de septiembre, 15:00 de Lima

    test('el mismo día de Lima da «hoy a las HH:mm»', () {
      expect(
        cuandoSeLeyo(DateTime.utc(2026, 9, 25, 15, 42), ahora),
        'hoy a las 10:42',
      );
    });

    test('el día anterior da «ayer a las HH:mm», con ceros a la izquierda', () {
      expect(
        cuandoSeLeyo(DateTime.utc(2026, 9, 24, 14, 5), ahora),
        'ayer a las 09:05',
      );
    });

    test('otro día del mismo año da el día y el mes en minúscula', () {
      expect(
        cuandoSeLeyo(DateTime.utc(2026, 9, 22, 15, 42), ahora),
        'el 22 de septiembre a las 10:42',
      );
    });

    test('otro año suma « de 2025» después del mes', () {
      expect(
        cuandoSeLeyo(DateTime.utc(2025, 9, 22, 15, 42), ahora),
        'el 22 de septiembre de 2025 a las 10:42',
      );
    });

    test('las 23:59 y las 00:00 de Lima caen en días distintos aunque el '
        'teléfono esté en otra zona', () {
      // 04:59 UTC del 26 son las 23:59 del 25 en Lima.
      final ultimoMinuto = DateTime.utc(2026, 9, 26, 4, 59);
      // 05:00 UTC del 26 son las 00:00 del 26 en Lima.
      final medianoche = DateTime.utc(2026, 9, 26, 5);
      final ahoraDia26 = DateTime.utc(2026, 9, 26, 12);

      expect(cuandoSeLeyo(ultimoMinuto, ahoraDia26), 'ayer a las 23:59');
      expect(cuandoSeLeyo(medianoche, ahoraDia26), 'hoy a las 00:00');
      // Las mismas fechas en la zona del proceso, que con `TZ=UTC` no es la de
      // Lima, dan el mismo texto.
      expect(
        cuandoSeLeyo(ultimoMinuto.toLocal(), ahoraDia26.toLocal()),
        'ayer a las 23:59',
      );
    });

    test('un leidoEn posterior a ahora, por un reloj atrasado, da «hoy»', () {
      expect(
        cuandoSeLeyo(DateTime.utc(2026, 9, 26, 15, 42), ahora),
        'hoy a las 10:42',
      );
    });

    test('los doce meses salen en minúscula', () {
      const meses = [
        'enero',
        'febrero',
        'marzo',
        'abril',
        'mayo',
        'junio',
        'julio',
        'agosto',
        'septiembre',
        'octubre',
        'noviembre',
        'diciembre',
      ];
      final fin = DateTime.utc(2026, 12, 31, 20);
      for (var m = 1; m <= 12; m++) {
        expect(
          cuandoSeLeyo(DateTime.utc(2026, m, 10, 15), fin),
          'el 10 de ${meses[m - 1]} a las 10:00',
        );
      }
    });

    test('los textos completos de la fila y del aviso', () {
      final leido = DateTime.utc(2026, 9, 25, 15, 42);
      expect(
        textoUltimaLectura(leido, ahora),
        'Última lectura hoy a las 10:42',
      );
      expect(
        textoNotasLeidas(leido, ahora),
        'Se muestran las notas leídas hoy a las 10:42.',
      );
    });
  });
}
