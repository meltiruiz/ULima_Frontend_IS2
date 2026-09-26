// test/HU36_jeff/specialty_test_logic_test.dart
//
// Pruebas unitarias de HU36, el test de especialidad, sobre las funciones
// puras de lib/pages/specialty_test/specialty_test_logic.dart, que son el mapa
// de íconos (RF-TEST-5), las líneas de Ulises, el sello, el historial y el
// cuerpo de la evaluación (RF-TEST-4) y la selección oficial, los corazones
// (RF-TEST-9 y RF-TEST-14) y la fecha en Lima (RF-TEST-10).
//
// Datos inventados (datos_de_prueba.dart).

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ulima_plus/models/specialty_test_models.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_logic.dart';

import 'datos_de_prueba.dart';

void main() {
  _iconos();
  _conversacion();
  _seleccion();
}

void _iconos() {
  group('UNITARIA · Mapa de íconos (RF-TEST-5, decisión 8)', () {
    // Los 52 nombres de la versión 2026-09-25.4 con la constante que da su
    // camelCase. Es la misma lista que el mapa de la app, escrita aparte para
    // que un nombre cambiado de constante se note.
    const esperado = <String, IconData>{
      // Las cuatro especialidades.
      'code-xml': LucideIcons.codeXml,
      'server-cog': LucideIcons.serverCog,
      'chart-column-big': LucideIcons.chartColumnBig,
      'gamepad-2': LucideIcons.gamepad2,
      // Las 48 tareas, 24 de las preguntas y 24 de los desempates.
      'shopping-cart': LucideIcons.shoppingCart,
      'shelving-unit': LucideIcons.shelvingUnit,
      'refrigerator': LucideIcons.refrigerator,
      'mountain': LucideIcons.mountain,
      'eye': LucideIcons.eye,
      'store': LucideIcons.store,
      'drumstick': LucideIcons.drumstick,
      'rabbit': LucideIcons.rabbit,
      'camera': LucideIcons.camera,
      'folder-search': LucideIcons.folderSearch,
      'school': LucideIcons.school,
      'drafting-compass': LucideIcons.draftingCompass,
      'rocket': LucideIcons.rocket,
      'smartphone': LucideIcons.smartphone,
      'hand-coins': LucideIcons.handCoins,
      'clipboard-pen-line': LucideIcons.clipboardPenLine,
      'ticket': LucideIcons.ticket,
      'clock-arrow-up': LucideIcons.clockArrowUp,
      'route': LucideIcons.route,
      'messages-square': LucideIcons.messagesSquare,
      'user-minus': LucideIcons.userMinus,
      'pencil': LucideIcons.pencil,
      'footprints': LucideIcons.footprints,
      'bus': LucideIcons.bus,
      'calendar-clock': LucideIcons.calendarClock,
      'hospital': LucideIcons.hospital,
      'key-round': LucideIcons.keyRound,
      'receipt': LucideIcons.receipt,
      'blocks': LucideIcons.blocks,
      'goal': LucideIcons.goal,
      'database': LucideIcons.database,
      'rocking-chair': LucideIcons.rockingChair,
      'land-plot': LucideIcons.landPlot,
      'dices': LucideIcons.dices,
      'ghost': LucideIcons.ghost,
      'headphones': LucideIcons.headphones,
      'siren': LucideIcons.siren,
      'badge-percent': LucideIcons.badgePercent,
      'stamp': LucideIcons.stamp,
      'graduation-cap': LucideIcons.graduationCap,
      'house-wifi': LucideIcons.houseWifi,
      'drama': LucideIcons.drama,
      'droplet': LucideIcons.droplet,
      'radio-tower': LucideIcons.radioTower,
      'soup': LucideIcons.soup,
      'map-pinned': LucideIcons.mapPinned,
      'split': LucideIcons.split,
      'pill-bottle': LucideIcons.pillBottle,
    };

    test('caso 1: el mapa trae los 52 nombres y ningún otro', () {
      expect(kIconosDelTest.length, 52);
      expect(kIconosDelTest.keys.toSet(), esperado.keys.toSet());
      for (final nombre in esperado.keys) {
        expect(kIconosDelTest[nombre], esperado[nombre], reason: nombre);
      }
    });

    test('caso 2: cada nombre da un ícono distinto y ninguno es el neutro', () {
      final puntos = kIconosDelTest.values.map((i) => i.codePoint).toSet();
      expect(puntos, hasLength(52));
      expect(puntos, isNot(contains(kIconoNeutro.codePoint)));
      expect(kIconoNeutro, LucideIcons.sparkles);
    });

    test('caso 3: un nombre fuera del mapa o ausente cae al neutro', () {
      expect(iconoDelTest('shopping-cart'), LucideIcons.shoppingCart);
      expect(iconoDelTest('gamepad-2'), LucideIcons.gamepad2);
      expect(iconoDelTest('icono-que-no-existe'), LucideIcons.sparkles);
      expect(iconoDelTest('ShoppingCart'), LucideIcons.sparkles);
      expect(iconoDelTest(''), LucideIcons.sparkles);
      expect(iconoDelTest(null), LucideIcons.sparkles);
    });
  });
}

SpecialtyTestContent _contenido([Map<String, dynamic>? json]) =>
    SpecialtyTestContent.tryParse(json ?? contenidoJson())!;

TiebreakRecord _desempate(int order, {String? respuesta}) => TiebreakRecord(
  tiebreak:
      (EvaluationStep.tryParse(
                desempateJson(order: order, id: 'tb-si-vj-$order'),
              )!
              as TiebreakStep)
          .tiebreak,
  ulisesLine: 'Línea del desempate $order.',
  answer: respuesta,
);

void _conversacion() {
  group('UNITARIA · Líneas de Ulises y sello (RF-TEST-4)', () {
    final c = _contenido();
    final r = respuestasCompletas();

    test('caso 4: antes de la pregunta 1 va duelHelp', () {
      final turno = turnoAntesDePregunta(c, 0, const {});
      expect(turno.lineas, [kDuelHelp]);
      expect(turno.sello, isNull);
    });

    test('caso 5: un duelo con reacción propia la usa, sin importar la '
        'respuesta', () {
      expect(turnoAntesDePregunta(c, 1, {'q01': 'none'}).lineas, [
        'Reacción propia de la pregunta uno.',
      ]);
    });

    test('caso 6: sin reacción propia rota pick, both y none con el índice '
        'N − 1 módulo el largo', () {
      // Antes de la pregunta 3 (N = 3) la respondida es la 2, con índice 2.
      // Además la 3 es la primera escala, así que va scaleHelp.
      expect(turnoAntesDePregunta(c, 2, {'q02': 'top'}).lineas, [
        kPick[2],
        kScaleHelp,
      ]);
      expect(turnoAntesDePregunta(c, 2, {'q02': 'bottom'}).lineas, [
        kPick[2],
        kScaleHelp,
      ]);
      expect(turnoAntesDePregunta(c, 2, {'q02': 'both'}).lineas, [
        kBoth[0],
        kScaleHelp,
      ]);
      expect(turnoAntesDePregunta(c, 2, {'q02': 'none'}).lineas, [
        kNone[0],
        kScaleHelp,
      ]);
      final sinReacciones = contenidoJson();
      for (final q in sinReacciones['questions'] as List) {
        (q as Map).remove('reaction');
      }
      final otra = _contenido(sinReacciones);
      expect(turnoAntesDePregunta(otra, 1, {'q01': 'top'}).lineas, [kPick[1]]);
      expect(turnoAntesDePregunta(otra, 4, {'q04': 'both'}).lineas, [kBoth[0]]);
      expect(turnoAntesDePregunta(otra, 4, {'q04': 'top'}).lineas, [kPick[4]]);
    });

    test('caso 7: una escala con blockClose lo usa y trae el sello k de B', () {
      final turno = turnoAntesDePregunta(c, 3, r);
      expect(turno.lineas, ['Cierre de prueba del bloque uno.']);
      expect(turno.sello, const SelloDeBloque(1, 2));
      expect(turno.sello!.texto, 'Cierra el bloque 1 de 2');
    });

    test('caso 8: una escala sin blockClose rota la lista de scale y no trae '
        'sello', () {
      final json = contenidoJson();
      ((json['questions'] as List)[2] as Map).remove('blockClose');
      final otra = _contenido(json);
      final turno = turnoAntesDePregunta(otra, 3, r);
      // N − 1 = 3, y 3 módulo 3 es 0.
      expect(turno.lineas, [kScale[0]]);
      expect(turno.sello, isNull);
      // Con un solo blockClose en el contenido, el que queda es el 1 de 1.
      expect(selloDe(otra, 4), const SelloDeBloque(1, 1));
    });

    test('caso 9: una lista vacía no inventa ninguna línea', () {
      final json = contenidoJson();
      final reacciones = (json['ulises'] as Map)['reactions'] as Map;
      reacciones['both'] = <String>[];
      ((json['questions'] as List)[0] as Map).remove('reaction');
      final otra = _contenido(json);
      expect(turnoAntesDePregunta(otra, 1, {'q01': 'both'}).lineas, isEmpty);
    });

    test('caso 10: el desempate usa la línea del servidor y la espera, el '
        'cierre de la última y la línea de espera', () {
      expect(turnoAntesDeDesempate(_desempate(1)).lineas, [
        'Línea del desempate 1.',
      ]);
      final espera = turnoDeEspera(c, trasDesempate: false);
      expect(espera.lineas, ['Cierre de prueba del bloque dos.', kLoading]);
      expect(espera.sello, const SelloDeBloque(2, 2));
      final trasDesempate = turnoDeEspera(c, trasDesempate: true);
      expect(trasDesempate.lineas, [kLoading]);
      expect(trasDesempate.sello, isNull);
    });

    test('caso 11: el subtítulo cuenta las preguntas del contenido y nombra '
        'los desempates', () {
      expect(subtituloDelPaso(c, 0), 'Pregunta 1 de 5');
      expect(subtituloDelPaso(c, 4), 'Pregunta 5 de 5');
      expect(subtituloDelPaso(c, 5), 'Desempate 1');
      expect(subtituloDelPaso(c, 6), 'Desempate 2');
    });
  });

  group('UNITARIA · Historial y desempates (RF-TEST-4)', () {
    final c = _contenido();

    test('caso 12: el historial lista lo respondido antes del paso, sin '
        'colores', () {
      final filas = historial(c, respuestasCompletas(), const [], 5);
      expect(filas.map((f) => f.etiqueta), ['1', '2', '3', '4', '5']);
      expect(filas.map((f) => f.respuesta), [
        'Tarea de prueba uno arriba',
        'Me gustan las dos',
        'Bastante · Tarea de prueba tres en escala',
        'Ninguna me llama',
        'Nada · Tarea de prueba cinco en escala',
      ]);
      expect(historial(c, respuestasCompletas(), const [], 2), hasLength(2));
    });

    test('caso 13: los desempates van como «Desempate 1» y «Desempate 2»', () {
      final filas = historial(c, respuestasCompletas(), [
        _desempate(1, respuesta: 'bottom'),
        _desempate(2),
      ], 6);
      expect(filas, hasLength(6));
      expect(filas.last.etiqueta, 'Desempate 1');
      expect(filas.last.respuesta, 'Tarea de desempate 1 abajo');
    });

    test('caso 14: la pastilla dice N respuestas o 1 respuesta, y su '
        'etiqueta dice ver u ocultar', () {
      expect(textoDeLaPastilla(1), '1 respuesta anterior');
      expect(textoDeLaPastilla(4), '4 respuestas anteriores');
      expect(
        etiquetaDeLaPastilla(4, desplegada: false),
        'Ver tus 4 respuestas anteriores',
      );
      expect(
        etiquetaDeLaPastilla(1, desplegada: false),
        'Ver tu respuesta anterior',
      );
      expect(
        etiquetaDeLaPastilla(4, desplegada: true),
        'Ocultar tus respuestas anteriores',
      );
    });

    test('caso 15: responder una pregunta borra todos los desempates, y '
        'responder el 1 borra el 2', () {
      final dos = [
        _desempate(1, respuesta: 'top'),
        _desempate(2, respuesta: 'bottom'),
      ];
      expect(
        desempatesTrasResponder(
          totalPreguntas: 5,
          desempates: dos,
          paso: 3,
          respuesta: 'top',
        ),
        isEmpty,
      );
      final trasElPrimero = desempatesTrasResponder(
        totalPreguntas: 5,
        desempates: dos,
        paso: 5,
        respuesta: 'both',
      );
      expect(trasElPrimero, hasLength(1));
      expect(trasElPrimero.single.answer, 'both');
      final trasElSegundo = desempatesTrasResponder(
        totalPreguntas: 5,
        desempates: dos,
        paso: 6,
        respuesta: 'none',
      );
      expect(trasElSegundo.map((d) => d.answer), ['top', 'none']);
    });

    test(
      'caso 16: el primer paso sin responder y las preguntas respondidas',
      () {
        expect(primerPasoSinResponder(c, const {}, const []), 0);
        expect(
          primerPasoSinResponder(c, {'q01': 'top', 'q02': 'none'}, const []),
          2,
        );
        expect(
          primerPasoSinResponder(c, respuestasCompletas(), [_desempate(1)]),
          5,
        );
        expect(
          primerPasoSinResponder(c, respuestasCompletas(), const []),
          isNull,
        );
        expect(preguntasRespondidas(c, {'q01': 'top', 'q03': 'nada'}), 2);
      },
    );

    test('caso 17: el cuerpo de la evaluación es exactamente version, '
        'answers y tiebreakAnswers', () {
      final cuerpo = cuerpoDeEvaluacion(
        version: kVersionDePrueba,
        respuestas: respuestasCompletas(),
        desempates: [
          _desempate(1, respuesta: 'bottom'),
          _desempate(2),
        ],
      );
      expect(cuerpo, {
        'version': kVersionDePrueba,
        'answers': respuestasCompletas(),
        'tiebreakAnswers': [
          {'id': 'tb-si-vj-1', 'answer': 'bottom'},
        ],
      });
      expect(
        cuerpoDeEvaluacion(
          version: kVersionDePrueba,
          respuestas: respuestasCompletas(),
          desempates: const [],
        )['tiebreakAnswers'],
        isEmpty,
      );
    });
  });
}

void _seleccion() {
  // El ranking de prueba es vj (7), si (6), ti (5) y sw (1).
  const ranking = <int>[kIdVj, kIdSi, kIdTi, kIdSw];

  group(
    'UNITARIA · Selección oficial y corazones (RF-TEST-9 y RF-TEST-14)',
    () {
      test('caso 18: la selección oficial saca los ids antiguos y la principal '
          'de los intereses', () {
        expect(
          seleccionOficial(
            principal: 3,
            intereses: [kIdSi, 3, 99, kIdSi, kIdTi],
            oficiales: {kIdSw, kIdTi, kIdSi, kIdVj},
          ),
          const SeleccionDeEspecialidades(intereses: [kIdSi, kIdTi]),
        );
        expect(
          seleccionOficial(
            principal: kIdSi,
            intereses: [kIdSi, kIdVj],
            oficiales: {kIdSw, kIdTi, kIdSi, kIdVj},
          ),
          const SeleccionDeEspecialidades(principal: kIdSi, intereses: [kIdVj]),
        );
      });

      test('caso 19: al abrir, los corazones son los intereses que están en '
          'el ranking', () {
        expect(
          corazonesIniciales(intereses: [kIdSi, 3], idsDelRanking: ranking),
          {kIdSi},
        );
      });

      test('caso 20: elegir la ganadora manda los corazones sin ella', () {
        expect(
          seleccionAlElegir(
            elegida: kIdVj,
            principalActual: null,
            corazones: {kIdTi, kIdVj},
            idsDelRanking: ranking,
          ),
          const SeleccionDeEspecialidades(principal: kIdVj, intereses: [kIdTi]),
        );
      });

      test('caso 21: una principal anterior del ranking pasa a interés; una '
          'antigua no viaja', () {
        expect(
          seleccionAlElegir(
            elegida: kIdVj,
            principalActual: kIdSw,
            corazones: {kIdTi},
            idsDelRanking: ranking,
          ),
          const SeleccionDeEspecialidades(
            principal: kIdVj,
            intereses: [kIdTi, kIdSw],
          ),
        );
        expect(
          seleccionAlElegir(
            elegida: kIdVj,
            principalActual: 3,
            corazones: const {},
            idsDelRanking: ranking,
          ),
          const SeleccionDeEspecialidades(principal: kIdVj),
        );
      });

      test(
        'caso 22: con empate, la ganadora que no se elige pasa a interés',
        () {
          expect(
            seleccionAlElegir(
              elegida: kIdSi,
              principalActual: null,
              corazones: const {},
              idsDelRanking: [kIdSi, kIdVj, kIdTi, kIdSw],
              otraGanadora: kIdVj,
            ),
            const SeleccionDeEspecialidades(
              principal: kIdSi,
              intereses: [kIdVj],
            ),
          );
        },
      );

      test('caso 23: un corazón deja la principal como está y manda los '
          'corazones en el orden del ranking', () {
        expect(
          seleccionConCorazones(
            principalActual: kIdSw,
            corazones: {kIdTi, kIdSi},
            idsDelRanking: ranking,
          ),
          const SeleccionDeEspecialidades(
            principal: kIdSw,
            intereses: [kIdSi, kIdTi],
          ),
        );
        // Una principal antigua no viaja (decisión abierta 26).
        expect(
          seleccionConCorazones(
            principalActual: 3,
            corazones: {kIdTi},
            idsDelRanking: ranking,
          ),
          const SeleccionDeEspecialidades(intereses: [kIdTi]),
        );
      });
    },
  );

  group('UNITARIA · Fecha en hora de Lima (RF-TEST-10)', () {
    test(
      'caso 24: la fecha sale en UTC−5 sin importar la zona del teléfono',
      () {
        expect(fechaEnLima(DateTime.utc(2026, 9, 26, 3, 30)), '25/09/2026');
        expect(fechaEnLima(DateTime.utc(2026, 9, 25, 20, 15)), '25/09/2026');
        expect(fechaEnLima(DateTime.utc(2026, 9, 26, 4, 59)), '25/09/2026');
        expect(fechaEnLima(DateTime.utc(2026, 9, 26, 5)), '26/09/2026');
        expect(fechaEnLima(DateTime.utc(2027, 1, 1, 2)), '31/12/2026');
        expect(
          fechaEnLima(DateTime.utc(2026, 3, 5, 12).toLocal()),
          '05/03/2026',
        );
      },
    );
  });
}
