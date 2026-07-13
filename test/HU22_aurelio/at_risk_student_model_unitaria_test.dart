// test/HU22_aurelio/at_risk_student_model_unitaria_test.dart
//
// UNITARIA — HU22 (lista de impedidos): AtRiskStudent.fromJson() y statusLabel.
// Modelo: lib/models/at_risk_student_model.dart
//
// El modelo parsea el payload de GET /attendance-risk/sections/:id/attendance-risk
// y produce la etiqueta de estado que ve el docente. Sin dependencias: no
// requiere mocks (aislamiento total).
//
// PARTICIÓN DE EQUIVALENCIA:
// | status (backend)      | Etiqueta esperada          | Flags                |
// |-----------------------|----------------------------|----------------------|
// | 'impedido'            | 'Impedido'                 | isImpedido           |
// | 'en_riesgo' + faltas  | 'En Riesgo: a N faltas'    | isEnRiesgo           |
// | 'en_riesgo' sin faltas| status crudo ('en_riesgo') | isEnRiesgo           |
// | 'normal'              | 'Normal'                   | isNormal             |
// | desconocido/ausente   | status crudo               | ningún flag          |
// Campos numéricos ausentes o null -> valores por defecto sin lanzar.

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/models/at_risk_student_model.dart';

Map<String, dynamic> payload({String? status, int? missingFaltas}) => {
      'code': '20230001',
      'firstName': 'Maria',
      'lastName': 'Garcia Lopez',
      'currentLevel': 5,
      'cycle': 3,
      'absentHours': 30,
      'totalHours': 100,
      'absencePercentage': 30.0,
      'status': status,
      'missingFaltas': missingFaltas,
    };

void main() {
  group('UNITARIA · AtRiskStudent.fromJson + statusLabel (HU22)', () {
    test('impedido: flags y etiqueta "Impedido"', () {
      final s = AtRiskStudent.fromJson(payload(status: 'impedido'));

      expect(s.isImpedido, isTrue);
      expect(s.isEnRiesgo, isFalse);
      expect(s.isNormal, isFalse);
      expect(s.statusLabel, 'Impedido');
      expect(s.fullName, 'Maria Garcia Lopez');
    });

    test('en_riesgo con missingFaltas 2: etiqueta con el conteo de faltas', () {
      final s = AtRiskStudent.fromJson(payload(status: 'en_riesgo', missingFaltas: 2));

      expect(s.isEnRiesgo, isTrue);
      expect(s.statusLabel, 'En Riesgo: a 2 faltas');
      expect(s.missingFaltas, 2);
    });

    test('en_riesgo SIN missingFaltas: cae al status crudo (sin inventar conteo)', () {
      final s = AtRiskStudent.fromJson(payload(status: 'en_riesgo'));

      expect(s.isEnRiesgo, isTrue);
      expect(s.statusLabel, 'en_riesgo');
    });

    test('normal: etiqueta "Normal"', () {
      final s = AtRiskStudent.fromJson(payload(status: 'normal'));

      expect(s.isNormal, isTrue);
      expect(s.statusLabel, 'Normal');
    });

    test('payload con campos ausentes o null: valores por defecto sin lanzar', () {
      final s = AtRiskStudent.fromJson(const {});

      expect(s.code, '');
      expect(s.firstName, '');
      expect(s.lastName, '');
      expect(s.currentLevel, isNull);
      expect(s.cycle, isNull);
      expect(s.absentHours, 0);
      expect(s.totalHours, 0);
      expect(s.absencePercentage, 0);
      expect(s.missingFaltas, isNull);
      expect(s.isImpedido, isFalse);
      expect(s.isEnRiesgo, isFalse);
      expect(s.isNormal, isFalse);
    });

    test('valores numéricos llegan como num (int o double) y se normalizan', () {
      final s = AtRiskStudent.fromJson({
        ...payload(status: 'impedido'),
        'absencePercentage': 33, // entero desde el JSON
        'absentHours': 10.0, // double desde el JSON
      });

      expect(s.absencePercentage, 33.0);
      expect(s.absentHours, 10);
    });
  });
}
