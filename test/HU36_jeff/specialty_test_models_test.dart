// test/HU36_jeff/specialty_test_models_test.dart
//
// Pruebas unitarias de HU36, el test de especialidad, sobre los modelos del
// contrato (RF-TEST-2).
// Modelo: lib/models/specialty_test_models.dart
//
// Datos inventados (datos_de_prueba.dart). Las líneas de Ulises son las de la
// versión 2026-09-25.4.

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/models/specialty_test_models.dart';

import 'datos_de_prueba.dart';

/// Un contenido nuevo en cada llamada, para romperlo sin tocar otro.
Map<String, dynamic> _contenido() => contenidoJson();

List<dynamic> _preguntas(Map<String, dynamic> c) => c['questions'] as List;

Map<String, dynamic> _especialidad(Map<String, dynamic> c, int i) =>
    (c['specialties'] as List)[i] as Map<String, dynamic>;

void main() {
  group('UNITARIA · Contenido del test (RF-TEST-2)', () {
    test('caso 1: el contenido completo se lee tal como llega', () {
      final c = SpecialtyTestContent.tryParse(_contenido())!;
      expect(c.version, kVersionDePrueba);
      expect(c.specialties.map((s) => s.key), ['sw', 'ti', 'si', 'vj']);
      final sw = c.specialtyByKey('sw')!;
      expect(sw.specialtyId, kIdSw);
      expect(sw.name, 'Ingeniería de Software');
      expect(sw.colorLight, '#1E3A8A');
      expect(sw.colorDark, '#A5C0F7');
      expect(sw.icon, 'code-xml');
      expect(sw.totalCredits, 21);
      expect(sw.electives, hasLength(3));
      expect(sw.electives.first.code, '900101');
      expect(sw.electives.first.displayName, 'Electivo A');
      expect(sw.electives.first.credits, 3);
      expect(sw.electives.first.prerequisite, 'Haber culminado el V ciclo');
      expect(c.ulises.welcome, kBienvenida);
      expect(c.ulises.duelHelp, kDuelHelp);
      expect(c.ulises.scaleHelp, kScaleHelp);
      expect(c.ulises.reactions.pick, kPick);
      expect(c.ulises.reactions.both, kBoth);
      expect(c.ulises.reactions.none, kNone);
      expect(c.ulises.reactions.scale, kScale);
      expect(c.ulises.loading, kLoading);
      expect(c.optionLabel('both'), 'Me gustan las dos');
      expect(c.optionLabel('none'), 'Ninguna me llama');
      expect(c.scaleOptions.map((o) => o.id), [
        'nada',
        'un_poco',
        'bastante',
        'me_encantaria',
      ]);
      expect(c.totalQuestions, 5);
      final q1 = c.questions.first;
      expect(q1.id, 'q01');
      expect(q1.n, 1);
      expect(q1.isDuel, isTrue);
      expect(q1.top!.id, 'q01.top');
      expect(q1.top!.specialty, 'sw');
      expect(q1.top!.icon, 'shopping-cart');
      expect(q1.bottom!.specialty, 'si');
      expect(q1.reaction, 'Reacción propia de la pregunta uno.');
      final q3 = c.questions[2];
      expect(q3.type, TestQuestionType.scale);
      expect(q3.task!.id, 'q03.task');
      expect(q3.tasks, hasLength(1));
      expect(q3.blockClose, 'Cierre de prueba del bloque uno.');
    });

    test('caso 2: los null se conservan y no se inventan textos ni ceros', () {
      final json = _contenido();
      final sw = _especialidad(json, 0);
      sw.remove('tagline');
      sw.remove('totalCredits');
      ((sw['electives'] as List).first as Map).remove('credits');
      final c = SpecialtyTestContent.tryParse(json)!;
      expect(c.questions[1].reaction, isNull);
      expect(c.questions[1].blockClose, isNull);
      expect(c.specialties.first.tagline, isNull);
      expect(c.specialties.first.totalCredits, isNull);
      expect(c.specialties.first.electives.first.credits, isNull);
    });

    test('caso 3: un contenido roto se rechaza entero', () {
      final rotos = <String, Map<String, dynamic>>{
        'sin versión': _contenido()..remove('version'),
        'tipo desconocido': _contenido()
          ..update('questions', (q) => q..[0]['type'] = 'ranking'),
        'duelo sin bottom': _contenido()
          ..update('questions', (q) => q..[0].remove('bottom')),
        'escala sin task': _contenido()
          ..update('questions', (q) => q..[2].remove('task')),
        'tarea sin id': _contenido()
          ..update('questions', (q) => q..[0]['top'].remove('id')),
        'tarea sin texto': _contenido()
          ..update('questions', (q) => q..[0]['top'].remove('text')),
        'clave fuera de las especialidades': _contenido()
          ..update('questions', (q) => q..[0]['top']['specialty'] = 'xx'),
        'especialidad sin specialtyId': _contenido()
          ..update('specialties', (s) => s..[0].remove('specialtyId')),
        'especialidad sin nombre': _contenido()
          ..update('specialties', (s) => s..[1].remove('name')),
        'especialidad sin color oscuro': _contenido()
          ..update('specialties', (s) => s..[2]['color'].remove('dark')),
        'tres opciones de escala': _contenido()
          ..update('scaleOptions', (o) => (o as List).sublist(0, 3)),
        'duelo sin none': _contenido()
          ..update('duelOptions', (o) => (o as List).sublist(0, 3)),
        'sin preguntas': _contenido()..['questions'] = <dynamic>[],
      };
      for (final caso in rotos.entries) {
        expect(
          SpecialtyTestContent.tryParse(caso.value),
          isNull,
          reason: caso.key,
        );
      }
      expect(SpecialtyTestContent.tryParse(null), isNull);
      expect(SpecialtyTestContent.tryParse('texto'), isNull);
    });

    test('caso 4: un hex que no se puede leer no invalida el contenido', () {
      final json = _contenido();
      (_especialidad(json, 0)['color'] as Map)['light'] = 'naranja';
      final c = SpecialtyTestContent.tryParse(json)!;
      expect(c.specialties.first.colorLight, 'naranja');
    });

    test(
      'caso 5: un icon ausente o fuera del mapa no invalida el contenido',
      () {
        final sinIcono = SpecialtyTestContent.tryParse(
          contenidoJson(iconoDeLaPrimera: null),
        )!;
        expect(sinIcono.questions.first.top!.icon, isNull);
        final desconocido = SpecialtyTestContent.tryParse(
          contenidoJson(iconoDeLaPrimera: 'icono-que-no-existe'),
        )!;
        expect(desconocido.questions.first.top!.icon, 'icono-que-no-existe');
        final json = _contenido();
        _especialidad(json, 3).remove('icon');
        expect(
          SpecialtyTestContent.tryParse(json)!.specialties.last.icon,
          isNull,
        );
      },
    );

    test('caso 6: la app no fija el número de preguntas ni la versión', () {
      final json = contenidoJson(version: '2027-01-10.1');
      _preguntas(json).removeLast();
      final c = SpecialtyTestContent.tryParse(json)!;
      expect(c.version, '2027-01-10.1');
      expect(c.totalQuestions, 4);
    });
  });

  group('UNITARIA · Paso de la evaluación (RF-TEST-2)', () {
    test('caso 7: un desempate se lee con su orden, sus tareas y la línea', () {
      final paso = EvaluationStep.tryParse(desempateJson(order: 2));
      expect(paso, isA<TiebreakStep>());
      final d = (paso! as TiebreakStep).tiebreak;
      expect(d.id, 'tb-si-vj-1');
      expect(d.order, 2);
      expect(d.top.id, 'tb-si-vj-1.top');
      expect(d.top.icon, 'soup');
      expect(d.bottom.specialty, 'vj');
      expect(
        (paso as TiebreakStep).ulisesLine,
        'Sigue reñido. Una última y listo.',
      );
    });

    test('caso 8: un resultado se lee entero y tiebreakOutcome sigue null', () {
      final paso = EvaluationStep.tryParse(resultadoJson());
      expect(paso, isA<ResultStep>());
      final r = (paso! as ResultStep).result;
      expect(r.version, kVersionDePrueba);
      expect(r.completedAt, DateTime.utc(2026, 9, 25, 20, 15));
      expect(r.tie, isFalse);
      expect(r.ranking.map((e) => e.key), ['vj', 'si', 'ti', 'sw']);
      expect(r.ranking.first.specialtyId, kIdVj);
      expect(r.ranking.first.affinity, 75);
      expect(r.reason, kMotivoLargo);
      expect(r.reasonSource, 'templates');
      expect(r.reasonByAi, isFalse);
      expect(
        r.headline,
        'Lo tuyo apunta a Desarrollo de Videojuegos, con 75 % de afinidad.',
      );
      expect(r.tiebreakOutcome, isNull);
      expect(r.winners.map((e) => e.key), ['vj']);
      expect(r.others.map((e) => e.key), ['si', 'ti', 'sw']);
    });

    test('caso 9: con empate, las ganadoras son las dos primeras', () {
      final r =
          (EvaluationStep.tryParse(
                    resultadoJson(empate: true, reasonSource: 'ai'),
                  )!
                  as ResultStep)
              .result;
      expect(r.tie, isTrue);
      expect(r.reasonByAi, isTrue);
      expect(r.winners.map((e) => e.key), ['si', 'vj']);
      expect(r.others.map((e) => e.key), ['ti', 'sw']);
    });

    test('caso 10: un paso roto no se lee', () {
      expect(EvaluationStep.tryParse({'status': 'otro'}), isNull);
      final sinAfinidad = resultadoJson();
      ((sinAfinidad['result'] as Map)['ranking'] as List).first.remove(
        'affinity',
      );
      expect(EvaluationStep.tryParse(sinAfinidad), isNull);
      final fueraDeRango = resultadoJson();
      ((fueraDeRango['result'] as Map)['ranking'] as List).first['affinity'] =
          101;
      expect(EvaluationStep.tryParse(fueraDeRango), isNull);
      final sinTie = resultadoJson();
      (sinTie['result'] as Map).remove('tie');
      expect(EvaluationStep.tryParse(sinTie), isNull);
      final desempateSinTop = desempateJson();
      (desempateSinTop['tiebreak'] as Map).remove('top');
      expect(EvaluationStep.tryParse(desempateSinTop), isNull);
    });

    test('caso 11: el desempate respondido viaja como {id, answer}', () {
      expect(
        const TiebreakAnswer(id: 'tb-si-vj-1', answer: 'bottom').toJson(),
        {'id': 'tb-si-vj-1', 'answer': 'bottom'},
      );
    });

    test('caso 11b: un desempate en memoria cambia de respuesta sin perder '
        'su tarea ni su línea', () {
      final paso = EvaluationStep.tryParse(desempateJson())! as TiebreakStep;
      final registro = TiebreakRecord(
        tiebreak: paso.tiebreak,
        ulisesLine: paso.ulisesLine,
      );
      expect(registro.answer, isNull);
      final respondido = registro.withAnswer('top');
      expect(respondido.answer, 'top');
      expect(respondido.tiebreak.id, 'tb-si-vj-1');
      expect(respondido.ulisesLine, paso.ulisesLine);
    });
  });

  group('UNITARIA · Último resultado (RF-TEST-2 y RF-TEST-10)', () {
    test('caso 12: se lee con su versión, su fecha y su ranking', () {
      final r = LastSpecialtyTestResult.tryParse(
        ultimoResultadoJson()['result'],
      )!;
      expect(r.version, kVersionDePrueba);
      expect(r.isCurrentVersion, isTrue);
      expect(r.completedAt, DateTime.utc(2026, 9, 26, 3, 30));
      expect(r.tie, isFalse);
      expect(r.winners.single.key, 'vj');
      expect(r.others, hasLength(3));
    });

    test('caso 13: isCurrentVersion ausente queda null, no false', () {
      final r = LastSpecialtyTestResult.tryParse(
        ultimoResultadoJson(isCurrentVersion: null)['result'],
      )!;
      expect(r.isCurrentVersion, isNull);
      final viejo = LastSpecialtyTestResult.tryParse(
        ultimoResultadoJson(isCurrentVersion: false)['result'],
      )!;
      expect(viejo.isCurrentVersion, isFalse);
    });

    test('caso 14: un resultado sin ranking no se lee', () {
      final json = ultimoResultadoJson()['result'] as Map<String, dynamic>;
      json['ranking'] = <dynamic>[];
      expect(LastSpecialtyTestResult.tryParse(json), isNull);
    });
  });
}
