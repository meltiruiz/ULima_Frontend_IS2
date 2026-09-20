// test/HU34_jeff/academic_record_model_test.dart
//
// UNITARIA — HU34 (récord académico): AcademicRecord.fromJson().
// Modelo: lib/models/academic_record_model.dart
//
// Contrato de GET /academic-record/me: spec del frontend ("Contrato que se
// consume") y spec del backend (RS-BE-26). Un dato sin valor queda null y
// nunca 0 (RF-REC-1). Los créditos con decimal no se redondean. El récord
// conserva el orden del backend, del ciclo más reciente al más viejo.
//
// Todos los valores son inventados: cursos "CURSO …", códigos 1000xx y
// secciones 9xx. No se reutilizan los fixtures del backend
// (test/HU31_jeff/fixtures) ni los del spike del portal.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/models/academic_record_model.dart';

/// Pasa el mapa por `jsonEncode`/`jsonDecode` para que los tipos sean los
/// mismos que entrega `ApiClient.getJson` (`Map<String, dynamic>` y
/// `List<dynamic>`), y para que el test pueda poner null en cualquier campo.
Map<String, dynamic> _comoJson(Map<String, dynamic> valor) =>
    jsonDecode(jsonEncode(valor)) as Map<String, dynamic>;

/// Respuesta completa inventada, con la forma exacta del contrato. Cada grupo
/// de totales tiene números distintos: leer un grupo con la clave de otro falla.
Map<String, dynamic> _completo() => _comoJson(<String, dynamic>{
      'syncedAt': '2026-09-18T15:00:00Z',
      'snapshot': {
        'ppa': 14.62,
        'relativePosition': 'TERCIO SUPERIOR',
        'creditsAccumulated': 120,
        'creditsRequired': 200,
        'approved': {'courses': 40, 'credits': 118},
        'convalidated': {'courses': 1, 'credits': 2},
      },
      'periods': [
        {
          'periodCode': '2026-0',
          'average': 15.5,
          'relativePosition': 'MEDIO SUPERIOR',
          'level': 6,
          'convalidated': {'courses': 0, 'credits': 0},
          'enrolled': {'courses': 3, 'credits': 10},
          'approved': {'courses': 2, 'credits': 7},
          'failed': {'courses': 1, 'credits': 3},
        },
      ],
      'record': [
        {
          'periodCode': '2026-1',
          'courses': [
            {
              'code': '100001',
              'name': 'CURSO DE PRUEBA A',
              'attempt': 1,
              'credits': 1.5,
              'grade': 17,
              'gradeRaw': '17',
              'section': '917',
              'observation': null,
            },
          ],
        },
        {
          'periodCode': '2025-2',
          'courses': [
            {
              'code': '100002',
              'name': 'CURSO DE PRUEBA B',
              'attempt': 2,
              'credits': 3,
              'grade': null,
              'gradeRaw': 'CONV',
              'section': null,
              'observation': 'Convalidado por examen',
            },
          ],
        },
      ],
    });

Map<String, dynamic> _snapshotDe(Map<String, dynamic> json) =>
    json['snapshot'] as Map<String, dynamic>;

Map<String, dynamic> _resumenDe(Map<String, dynamic> json) =>
    (json['periods'] as List<dynamic>).first as Map<String, dynamic>;

/// El único curso del ciclo en la posición [ciclo] de `record`.
Map<String, dynamic> _cursoDe(Map<String, dynamic> json, int ciclo) {
  final periodo = (json['record'] as List<dynamic>)[ciclo] as Map<String, dynamic>;
  return (periodo['courses'] as List<dynamic>).first as Map<String, dynamic>;
}

void main() {
  group('UNITARIA · AcademicRecord.fromJson (HU34)', () {
    test('lee una respuesta completa con la forma del contrato', () {
      final r = AcademicRecord.fromJson(_completo());

      expect(r.hasRecord, isTrue);
      expect(r.syncedAt, DateTime.utc(2026, 9, 18, 15));
      expect(r.syncedAt!.isUtc, isTrue);

      final s = r.snapshot!;
      expect(s.ppa, 14.62);
      expect(s.relativePosition, 'TERCIO SUPERIOR');
      expect(s.creditsAccumulated, 120.0);
      expect(s.creditsRequired, 200.0);
      expect(s.approved.courses, 40);
      expect(s.approved.credits, 118.0);
      expect(s.convalidated.courses, 1);
      expect(s.convalidated.credits, 2.0);

      final resumen = r.periodSummaries.single;
      expect(resumen.periodCode, '2026-0');
      expect(resumen.average, 15.5);
      expect(resumen.relativePosition, 'MEDIO SUPERIOR');
      expect(resumen.level, 6);
      expect(resumen.convalidated.courses, 0);
      expect(resumen.convalidated.credits, 0.0);
      expect(resumen.enrolled.courses, 3);
      expect(resumen.enrolled.credits, 10.0);
      expect(resumen.approved.courses, 2);
      expect(resumen.approved.credits, 7.0);
      expect(resumen.failed.courses, 1);
      expect(resumen.failed.credits, 3.0);

      expect(
        r.coursesByPeriod.map((p) => p.periodCode).toList(),
        ['2026-1', '2025-2'],
      );

      final primero = r.coursesByPeriod.first.courses.single;
      expect(primero.code, '100001');
      expect(primero.name, 'CURSO DE PRUEBA A');
      expect(primero.attempt, 1);
      expect(primero.credits, 1.5);
      expect(primero.grade, 17);
      expect(primero.gradeRaw, '17');
      expect(primero.section, '917');
      expect(primero.observation, isNull);

      final convalidado = r.coursesByPeriod[1].courses.single;
      expect(convalidado.code, '100002');
      expect(convalidado.name, 'CURSO DE PRUEBA B');
      expect(convalidado.attempt, 2);
      expect(convalidado.credits, 3.0);
      expect(convalidado.grade, isNull);
      expect(convalidado.gradeRaw, 'CONV');
      expect(convalidado.section, isNull);
      expect(convalidado.observation, 'Convalidado por examen');
    });

    test('los créditos con decimal no se redondean', () {
      final json = _completo();
      _snapshotDe(json)['creditsAccumulated'] = 120.5;
      (_snapshotDe(json)['approved'] as Map<String, dynamic>)['credits'] = 118.5;
      (_resumenDe(json)['enrolled'] as Map<String, dynamic>)['credits'] = 10.5;

      final r = AcademicRecord.fromJson(json);

      expect(r.coursesByPeriod.first.courses.single.credits, 1.5);
      expect(r.coursesByPeriod[1].courses.single.credits, 3.0);
      expect(r.snapshot!.creditsAccumulated, 120.5);
      expect(r.snapshot!.approved.credits, 118.5);
      expect(r.periodSummaries.single.enrolled.credits, 10.5);
    });

    test('un número null queda null, nunca 0', () {
      final json = _completo();
      final snapshot = _snapshotDe(json);
      snapshot['ppa'] = null;
      snapshot['creditsRequired'] = null;
      snapshot.remove('creditsAccumulated');
      (snapshot['approved'] as Map<String, dynamic>)['courses'] = null;
      final resumen = _resumenDe(json);
      resumen['average'] = null;
      resumen['level'] = null;
      final curso = _cursoDe(json, 0);
      curso['attempt'] = null;
      curso['grade'] = null;
      curso['credits'] = null;

      final r = AcademicRecord.fromJson(json);

      expect(r.snapshot!.ppa, isNull);
      expect(r.snapshot!.creditsRequired, isNull);
      expect(r.snapshot!.creditsAccumulated, isNull);
      expect(r.snapshot!.approved.courses, isNull);
      // Cada número del grupo va por separado: el otro se conserva.
      expect(r.snapshot!.approved.credits, 118.0);
      expect(r.periodSummaries.single.average, isNull);
      expect(r.periodSummaries.single.level, isNull);
      final c = r.coursesByPeriod.first.courses.single;
      expect(c.attempt, isNull);
      expect(c.grade, isNull);
      expect(c.credits, isNull);
    });

    test('nunca sincronizó: hasRecord false, sin snapshot y listas vacías', () {
      final r = AcademicRecord.fromJson(_comoJson(<String, dynamic>{
        'syncedAt': null,
        'snapshot': null,
        'periods': <dynamic>[],
        'record': <dynamic>[],
      }));

      expect(r.hasRecord, isFalse);
      expect(r.syncedAt, isNull);
      expect(r.snapshot, isNull);
      expect(r.periodSummaries, isEmpty);
      expect(r.coursesByPeriod, isEmpty);
    });

    test('un número que llega como texto se lee igual', () {
      final json = _completo();
      _snapshotDe(json)['ppa'] = '14.62';
      _resumenDe(json)['average'] = 'abc';
      final curso = _cursoDe(json, 0);
      curso['grade'] = '17';
      curso['credits'] = '1.5';
      curso['attempt'] = '2';

      final r = AcademicRecord.fromJson(json);

      expect(r.snapshot!.ppa, 14.62);
      expect(r.periodSummaries.single.average, isNull);
      final c = r.coursesByPeriod.first.courses.single;
      expect(c.grade, 17);
      expect(c.credits, 1.5);
      expect(c.attempt, 2);
    });

    test('un texto vacío o en blanco queda null', () {
      final json = _completo();
      _cursoDe(json, 0)['gradeRaw'] = '';
      _cursoDe(json, 0)['section'] = '';
      _cursoDe(json, 1)['gradeRaw'] = '   ';
      _cursoDe(json, 1)['observation'] = '   ';

      final r = AcademicRecord.fromJson(json);

      expect(r.coursesByPeriod[0].courses.single.gradeRaw, isNull);
      expect(r.coursesByPeriod[0].courses.single.section, isNull);
      expect(r.coursesByPeriod[1].courses.single.gradeRaw, isNull);
      expect(r.coursesByPeriod[1].courses.single.observation, isNull);
    });

    test('un snapshot sin approved deja sus dos números en null', () {
      final json = _completo();
      _snapshotDe(json).remove('approved');

      final r = AcademicRecord.fromJson(json);

      expect(r.snapshot!.approved.courses, isNull);
      expect(r.snapshot!.approved.credits, isNull);
      expect(r.snapshot!.convalidated.courses, 1);
      expect(AcademicTotals.fromJson('no es un objeto').credits, isNull);
    });

    test('un ciclo del récord que no es objeto se descarta', () {
      final r = AcademicRecord.fromJson(_comoJson(<String, dynamic>{
        'syncedAt': '2026-09-18T15:00:00Z',
        'snapshot': null,
        'periods': <dynamic>[],
        'record': <dynamic>[
          'x',
          <String, dynamic>{
            'periodCode': '2026-1',
            'courses': <dynamic>[
              <String, dynamic>{
                'code': '100003',
                'name': 'CURSO DE PRUEBA C',
                'attempt': 1,
                'credits': 4,
                'grade': 12,
                'gradeRaw': '12',
                'section': '918',
                'observation': null,
              },
            ],
          },
        ],
      }));

      expect(r.coursesByPeriod, hasLength(1));
      expect(r.coursesByPeriod.single.periodCode, '2026-1');
      expect(r.coursesByPeriod.single.courses.single.code, '100003');
    });

    test('una nota con decimal no es un entero válido y queda null', () {
      final json = _completo();
      _cursoDe(json, 0)['grade'] = 15.5;
      _cursoDe(json, 1)['attempt'] = 2.0;

      final r = AcademicRecord.fromJson(json);

      expect(r.coursesByPeriod[0].courses.single.grade, isNull);
      expect(r.coursesByPeriod[1].courses.single.attempt, 2);
    });

    test('AcademicRecord.empty no tiene récord', () {
      expect(AcademicRecord.empty.hasRecord, isFalse);
      expect(AcademicRecord.empty.syncedAt, isNull);
      expect(AcademicRecord.empty.snapshot, isNull);
      expect(AcademicRecord.empty.periodSummaries, isEmpty);
      expect(AcademicRecord.empty.coursesByPeriod, isEmpty);
    });

    test('respeta el orden del backend y no reordena los ciclos', () {
      final json = _completo();
      json['record'] = (json['record'] as List<dynamic>).reversed.toList();

      final r = AcademicRecord.fromJson(json);

      expect(
        r.coursesByPeriod.map((p) => p.periodCode).toList(),
        ['2025-2', '2026-1'],
      );
    });
  });
}
