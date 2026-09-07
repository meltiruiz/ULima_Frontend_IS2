import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/models/at_risk_student_model.dart';

/// RS-BE-10 en el cliente docente.
///
/// El backend ahora manda `status: "sin_datos"` y `absencePercentage: null`
/// para las matrículas que nunca recibieron horas. Antes esas filas llegaban
/// como `normal` con 0%, y toda la pantalla las pintaba de VERDE: el color de
/// "todo bien" para decir "no sabemos nada".
void main() {
  Map<String, dynamic> json({
    String status = 'sin_datos',
    num? absencePercentage,
    int? missingFaltas,
  }) => {
        'code': '20230001',   // sintetico: el repo es publico
        'firstName': 'Maria',
        'lastName': 'Garcia Lopez',
        'currentLevel': 8,
        'cycle': 8,
        'absentHours': 0,
        'totalHours': 0,
        'absencePercentage': absencePercentage,
        'status': status,
        'missingFaltas': missingFaltas,
      };

  group('AtRiskStudent sin datos', () {
    test('reconoce el estado sin_datos', () {
      expect(AtRiskStudent.fromJson(json()).isSinDatos, isTrue);
    });

    test('un porcentaje nulo NO se convierte en 0', () {
      // El `?? 0` anterior volvía indistinguible "sin medir" de "cero faltas".
      expect(AtRiskStudent.fromJson(json()).absencePercentage, isNull);
    });

    test('sin_datos no es normal', () {
      final s = AtRiskStudent.fromJson(json());
      expect(s.isNormal, isFalse);
      expect(s.isImpedido, isFalse);
      expect(s.isEnRiesgo, isFalse);
    });

    test('la etiqueta es legible, no el string crudo del backend', () {
      // El fallback anterior (`return status;`) habría impreso "sin_datos".
      expect(AtRiskStudent.fromJson(json()).statusLabel, 'Sin datos');
    });

    test('un impedido real sigue clasificando igual', () {
      final s = AtRiskStudent.fromJson(
        json(status: 'impedido', absencePercentage: 37.5),
      );
      expect(s.isImpedido, isTrue);
      expect(s.absencePercentage, closeTo(37.5, 1e-9));
      expect(s.statusLabel, 'Impedido');
    });
  });
}
