// test/HU35_jeff/time_blocks_conflicto_test.dart
//
// UNITARIA — HU35 (bloques de horario propios): los validadores puros del
// formulario (RF-BLQ-2) y la detección de cruces contra las clases del horario
// y contra los demás bloques del alumno (RF-BLQ-3).
// Prueba: lib/pages/time_blocks/time_block_validators.dart
//         lib/pages/time_blocks/time_block_conflicts.dart
//
// Todos los valores son inventados: cursos "CURSO DE PRUEBA …" y secciones
// 80x. El repo es público: nada sale de un horario real, ni se reutilizan los
// fixtures del backend (test/HU31_jeff/fixtures) ni los del spike del portal.

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/models/time_block_model.dart';
import 'package:ulima_plus/pages/time_blocks/time_block_conflicts.dart';
import 'package:ulima_plus/pages/time_blocks/time_block_validators.dart';

void main() {
  // --- Datos inventados ----------------------------------------------------

  /// Una sección del horario con la forma que tiene `_todasLasSecciones`: la
  /// sección con su lista de `horarios`, y cada horario con `dia`,
  /// `hora_inicio` y `hora_fin` en 12 h.
  Map<String, dynamic> seccion(
    String curso,
    String codigo,
    List<Map<String, String>> horarios,
  ) => <String, dynamic>{
    'idSeccion': codigo,
    'codigoSeccion': codigo,
    'curso': curso,
    'horarios': horarios,
  };

  Map<String, String> clase(String dia, String inicio, String fin) =>
      <String, String>{'dia': dia, 'hora_inicio': inicio, 'hora_fin': fin};

  /// Un bloque propio ya guardado. Recibe los valores por parámetro para no
  /// repetir los siete campos del constructor en cada prueba.
  TimeBlockRule bloquePropio({
    required int id,
    required String titulo,
    required List<int> dias,
    required String inicio,
    required String fin,
  }) => TimeBlockRule(
    id: id,
    title: titulo,
    colorHex: '#F94B3F',
    daysOfWeek: dias,
    startTime: inicio,
    endTime: fin,
    startDate: '2026-09-01',
    endDate: '2026-12-15',
    exceptions: const <TimeBlockException>[],
  );

  const sinSecciones = <Map<String, dynamic>>[];
  const sinBloques = <TimeBlockRule>[];

  // --- Validadores (RF-BLQ-2) ----------------------------------------------

  group('validarNombre', () {
    test('vacío → error', () => expect(validarNombre(''), isNotNull));
    test('solo espacios → error', () => expect(validarNombre('   '), isNotNull));
    test('60 caracteres → ok', () => expect(validarNombre('a' * 60), isNull));
    test('61 caracteres → error', () => expect(validarNombre('a' * 61), isNotNull));
    test('un nombre normal → ok', () => expect(validarNombre('Prácticas'), isNull));
  });

  group('validarDias', () {
    test('ninguno → error', () => expect(validarDias(<int>{}), isNotNull));
    test('0 no es un día → error', () => expect(validarDias(<int>{0}), isNotNull));
    test('8 no es un día → error', () => expect(validarDias(<int>{8}), isNotNull));
    test('solo lunes → ok', () => expect(validarDias(<int>{1}), isNull));
    test('lunes, miércoles y domingo → ok',
        () => expect(validarDias(<int>{1, 3, 7}), isNull));
  });

  group('validarHoras', () {
    test('sin horas → error', () => expect(validarHoras(null, null), isNotNull));
    test('solo la de inicio → error', () => expect(validarHoras('14:00', null), isNotNull));
    test('formato de 12 h → error: el formulario entrega HH:MM',
        () => expect(validarHoras('2 pm', '6 pm'), isNotNull));
    test('fin antes que inicio → error', () => expect(validarHoras('18:00', '16:00'), isNotNull));
    test('iguales → error', () => expect(validarHoras('16:00', '16:00'), isNotNull));
    test('antes de las 7 am → error', () => expect(validarHoras('06:30', '09:00'), isNotNull));
    test('después de las 10 pm → error', () => expect(validarHoras('20:00', '22:30'), isNotNull));
    test('los bordes de la grilla sí entran',
        () => expect(validarHoras('07:00', '22:00'), isNull));
    test('un rango normal → ok', () => expect(validarHoras('14:00', '18:00'), isNull));
  });

  group('validarFechas', () {
    test('sin fechas → error', () => expect(validarFechas(null, '2026-12-15'), isNotNull));
    test('hasta antes que desde → error',
        () => expect(validarFechas('2026-12-15', '2026-09-01'), isNotNull));
    test('un solo día → ok', () => expect(validarFechas('2026-09-01', '2026-09-01'), isNull));
    test('texto que no es fecha → error',
        () => expect(validarFechas('mañana', '2026-09-02'), isNotNull));
    test('un ciclo entero → ok',
        () => expect(validarFechas('2026-09-01', '2026-12-15'), isNull));
  });

  group('validarFormulario', () {
    test('todo correcto → null', () {
      expect(
        validarFormulario(
          nombre: 'Prácticas',
          dias: <int>{1, 3},
          inicio: '14:00',
          fin: '18:00',
          desde: '2026-09-01',
          hasta: '2026-12-15',
        ),
        isNull,
      );
    });

    test('sin días marcados devuelve el mensaje de validarDias', () {
      expect(
        validarFormulario(
          nombre: 'Prácticas',
          dias: <int>{},
          inicio: '14:00',
          fin: '18:00',
          desde: '2026-09-01',
          hasta: '2026-12-15',
        ),
        validarDias(<int>{}),
      );
    });

    test('el nombre manda sobre los días: se reporta el primer problema', () {
      expect(
        validarFormulario(
          nombre: '  ',
          dias: <int>{},
          inicio: '18:00',
          fin: '14:00',
          desde: '2026-12-15',
          hasta: '2026-09-01',
        ),
        validarNombre('  '),
      );
    });
  });

  // --- Lectura de la hora del horario (las dos formas que circulan) --------

  group('horaAMinutos', () {
    test('12 h con am', () {
      expect(horaAMinutos('8:00 am'), 480);
    });
    test('12 h con pm, como lo manda el horario', () {
      expect(horaAMinutos('04:00 pm'), 960);
    });
    test('24 h con segundos', () => expect(horaAMinutos('14:00:00'), 840));
    test('24 h sin segundos', () => expect(horaAMinutos('14:30'), 870));
    test('medianoche y mediodía no se confunden', () {
      expect(horaAMinutos('12:00 am'), 0);
      expect(horaAMinutos('12:00 pm'), 720);
    });
    test('texto ilegible → null, no las 7 en silencio', () {
      expect(horaAMinutos('a las ocho'), isNull);
    });
    test('vacío → null', () => expect(horaAMinutos(''), isNull));
  });

  // --- Cruce entre dos rangos (RF-BLQ-3) -----------------------------------

  group('seCruzan', () {
    test('tocarse en el borde NO es cruce',
        () => expect(seCruzan('16:00', '18:00', '18:00', '20:00'), isFalse));
    test('tocarse en el borde tampoco al revés',
        () => expect(seCruzan('18:00', '20:00', '16:00', '18:00'), isFalse));
    test('solaparse a medias es cruce',
        () => expect(seCruzan('16:00', '18:00', '17:00', '19:00'), isTrue));
    test('uno contenido en el otro es cruce',
        () => expect(seCruzan('14:00', '18:00', '15:00', '16:00'), isTrue));
    test('compara bien los dos formatos mezclados',
        () => expect(seCruzan('14:00', '18:00', '4:00 pm', '6:00 pm'), isTrue));
    test('una hora ilegible no inventa un cruce',
        () => expect(seCruzan('14:00', '18:00', 'por confirmar', '18:00'), isFalse));
  });

  // --- Cruces del bloque contra el horario (RF-BLQ-3) ----------------------

  group('crucesDeBloque', () {
    final martes4a6 = <Map<String, dynamic>>[
      seccion('CURSO DE PRUEBA A', '801', <Map<String, String>>[
        clase('Martes', '04:00 pm', '06:00 pm'),
      ]),
    ];

    test('una clase el mismo día y a la misma hora es un cruce', () {
      final cruces = crucesDeBloque(
        dias: <int>{2},
        inicio: '14:00',
        fin: '18:00',
        secciones: martes4a6,
        bloques: sinBloques,
      );
      expect(cruces, hasLength(1));
      expect(cruces.first.conQue, 'CURSO DE PRUEBA A');
      expect(cruces.first.dia, 2);
      expect(cruces.first.inicio, '16:00');
      expect(cruces.first.fin, '18:00');
    });

    test('la misma clase en otro día no cruza', () {
      expect(
        crucesDeBloque(
          dias: <int>{3},
          inicio: '14:00',
          fin: '18:00',
          secciones: martes4a6,
          bloques: sinBloques,
        ),
        isEmpty,
      );
    });

    test('empezar justo cuando la clase termina no cruza', () {
      expect(
        crucesDeBloque(
          dias: <int>{2},
          inicio: '18:00',
          fin: '20:00',
          secciones: martes4a6,
          bloques: sinBloques,
        ),
        isEmpty,
      );
    });

    test('se listan todas las clases cruzadas, ordenadas por hora', () {
      final cruces = crucesDeBloque(
        dias: <int>{1},
        inicio: '08:00',
        fin: '12:00',
        secciones: <Map<String, dynamic>>[
          seccion('CURSO DE PRUEBA B', '802', <Map<String, String>>[
            clase('Lunes', '09:00 am', '11:00 am'),
          ]),
          seccion('CURSO DE PRUEBA A', '801', <Map<String, String>>[
            clase('Lunes', '08:00 am', '10:00 am'),
          ]),
        ],
        bloques: sinBloques,
      );
      expect(cruces.map((c) => c.conQue).toList(),
          <String>['CURSO DE PRUEBA A', 'CURSO DE PRUEBA B']);
    });

    test('el día sin tilde del horario también se reconoce', () {
      final cruces = crucesDeBloque(
        dias: <int>{3},
        inicio: '14:00',
        fin: '18:00',
        secciones: <Map<String, dynamic>>[
          seccion('CURSO DE PRUEBA C', '803', <Map<String, String>>[
            clase('Miercoles', '03:00 pm', '05:00 pm'),
          ]),
        ],
        bloques: sinBloques,
      );
      expect(cruces, hasLength(1));
      expect(cruces.first.dia, 3);
    });

    test('una hora ilegible del horario no genera un aviso', () {
      expect(
        crucesDeBloque(
          dias: <int>{2},
          inicio: '14:00',
          fin: '18:00',
          secciones: <Map<String, dynamic>>[
            seccion('CURSO DE PRUEBA A', '801', <Map<String, String>>[
              clase('Martes', 'por confirmar', 'por confirmar'),
            ]),
          ],
          bloques: sinBloques,
        ),
        isEmpty,
      );
    });

    test('cruza con otro bloque propio', () {
      final cruces = crucesDeBloque(
        dias: <int>{3},
        inicio: '16:00',
        fin: '19:00',
        secciones: sinSecciones,
        bloques: <TimeBlockRule>[
          bloquePropio(
            id: 7,
            titulo: 'Prácticas',
            dias: <int>[1, 3],
            inicio: '14:00',
            fin: '18:00',
          ),
        ],
      );
      expect(cruces, hasLength(1));
      expect(cruces.first.conQue, 'Prácticas');
      expect(cruces.first.dia, 3);
      expect(cruces.first.inicio, '14:00');
      expect(cruces.first.fin, '18:00');
    });

    test('al editar, un bloque no se cruza consigo mismo', () {
      expect(
        crucesDeBloque(
          dias: <int>{3},
          inicio: '16:00',
          fin: '19:00',
          secciones: sinSecciones,
          bloques: <TimeBlockRule>[
            bloquePropio(
              id: 7,
              titulo: 'Prácticas',
              dias: <int>[1, 3],
              inicio: '14:00',
              fin: '18:00',
            ),
          ],
          ignorarBloqueId: 7,
        ),
        isEmpty,
      );
    });

    test('un bloque propio de otro rango de fechas no cruza', () {
      // Prácticas va del 1 de septiembre al 15 de diciembre; el bloque nuevo,
      // de enero a febrero. Mismo día y misma hora, pero nunca coinciden.
      final practicas = <TimeBlockRule>[
        bloquePropio(
          id: 7,
          titulo: 'Prácticas',
          dias: <int>[1, 3],
          inicio: '14:00',
          fin: '18:00',
        ),
      ];
      expect(
        crucesDeBloque(
          dias: <int>{3},
          inicio: '16:00',
          fin: '19:00',
          desde: '2027-01-04',
          hasta: '2027-02-26',
          secciones: sinSecciones,
          bloques: practicas,
        ),
        isEmpty,
      );
      // Con los rangos solapados (del miércoles 9 al 15 de diciembre) sí cruza.
      expect(
        crucesDeBloque(
          dias: <int>{3},
          inicio: '16:00',
          fin: '19:00',
          desde: '2026-12-09',
          hasta: '2027-02-26',
          secciones: sinSecciones,
          bloques: practicas,
        ),
        hasLength(1),
      );
    });

    test('el domingo cruza como cualquier otro día', () {
      final cruces = crucesDeBloque(
        dias: <int>{7},
        inicio: '09:00',
        fin: '11:00',
        secciones: sinSecciones,
        bloques: <TimeBlockRule>[
          bloquePropio(
            id: 9,
            titulo: 'Voluntariado',
            dias: <int>[7],
            inicio: '10:00',
            fin: '13:00',
          ),
        ],
      );
      expect(cruces, hasLength(1));
      expect(cruces.first.dia, 7);
    });

    test('sin clases ni bloques no hay nada que avisar', () {
      expect(
        crucesDeBloque(
          dias: <int>{1, 2, 3, 4, 5, 6, 7},
          inicio: '07:00',
          fin: '22:00',
          secciones: sinSecciones,
          bloques: sinBloques,
        ),
        isEmpty,
      );
    });
  });

  // --- El texto del aviso (RF-BLQ-3) ---------------------------------------

  group('mensajeDeCruce', () {
    test('sin cruces no hay mensaje', () => expect(mensajeDeCruce(const <Cruce>[]), ''));

    test('un cruce se nombra con curso, día y horas, en el formato de la spec', () {
      final cruces = crucesDeBloque(
        dias: <int>{2},
        inicio: '14:00',
        fin: '18:00',
        secciones: <Map<String, dynamic>>[
          seccion('CURSO DE PRUEBA A', '801', <Map<String, String>>[
            clase('Martes', '04:00 pm', '06:00 pm'),
          ]),
        ],
        bloques: sinBloques,
      );
      expect(
        mensajeDeCruce(cruces),
        'Se cruza con CURSO DE PRUEBA A, martes de 4:00 pm a 6:00 pm.',
      );
    });

    test('varios cruces se listan uno por línea, en el orden recibido', () {
      expect(
        mensajeDeCruce(const <Cruce>[
          Cruce(conQue: 'CURSO DE PRUEBA A', dia: 1, inicio: '08:00', fin: '10:00'),
          Cruce(conQue: 'CURSO DE PRUEBA B', dia: 1, inicio: '09:00', fin: '11:00'),
        ]),
        'Se cruza con:\n'
        '• CURSO DE PRUEBA A, lunes de 8:00 am a 10:00 am\n'
        '• CURSO DE PRUEBA B, lunes de 9:00 am a 11:00 am',
      );
    });

    test('el mediodía se escribe 12 pm, no 0 pm', () {
      expect(
        mensajeDeCruce(const <Cruce>[
          Cruce(conQue: 'Prácticas', dia: 6, inicio: '12:00', fin: '13:30'),
        ]),
        'Se cruza con Prácticas, sábado de 12:00 pm a 1:30 pm.',
      );
    });
  });
}
