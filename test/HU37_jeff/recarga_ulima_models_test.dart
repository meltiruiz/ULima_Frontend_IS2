// test/HU37_jeff/recarga_ulima_models_test.dart
//
// UNITARIA · Recarga desde la ULima (specs/features/recarga-portal/
// recarga-portal.spec.md), RF-RCG-1, modelos.
// Archivo probado lib/models/recarga_ulima_models.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/models/recarga_ulima_models.dart';

import 'recarga_dobles.dart';

void main() {
  group('UNITARIA · VistaUlima (RF-RCG-1)', () {
    test('lee entera la vista del ejemplo del contrato, con courses en '
        'vista.cursos y assessments en evaluaciones', () {
      final vista = VistaUlima.fromJson(vistaJson());

      expect(vista.lastReadAt, DateTime.utc(2025, 9, 22, 15, 42, 10));
      expect(vista.cursos, hasLength(1));
      final curso = vista.cursos.single;
      expect(curso.sectionId, 81);
      expect(curso.courseCode, '690417');
      expect(curso.courseName, 'TALLER DE PROTOTIPADO');
      expect(curso.sectionCode, '812');
      expect(curso.lastReadAt, DateTime.utc(2025, 9, 22, 15, 42, 10));
      expect(curso.evaluaciones, hasLength(2));

      final primera = curso.evaluaciones.first;
      expect(primera.key, '07.13');
      expect(primera.group, 'EVC');
      expect(primera.name, 'Examen escrito 1');
      expect(primera.week, 3);
      expect(primera.weight, 15);
      expect(primera.value, 14.5);
      expect(primera.mark, MarcaUlima.graded);
      expect(primera.assessmentId, 5011);
      expect(primera.match, ParejaUlima.exact);
      expect(primera.tienePareja, isTrue);
      expect(primera.publicada, isTrue);

      final segunda = curso.evaluaciones.last;
      expect(segunda.value, isNull);
      expect(segunda.mark, MarcaUlima.pending);
      expect(segunda.match, ParejaUlima.weekShift);
      expect(segunda.publicada, isFalse);
    });

    test('un número que llega como texto se convierte', () {
      final vista = VistaUlima.fromJson(
        vistaJson(
          courses: [
            cursoJson(
              sectionId: '81',
              assessments: [
                evaluacionJson(
                  week: '3',
                  weight: '12.5',
                  value: '14.25',
                  assessmentId: '5011',
                ),
              ],
            ),
          ],
        ),
      );

      final e = vista.cursos.single.evaluaciones.single;
      expect(vista.cursos.single.sectionId, 81);
      expect(e.week, 3);
      expect(e.weight, 12.5);
      expect(e.value, 14.25);
      expect(e.assessmentId, 5011);
    });

    test('un mark o un match desconocidos se tratan como pending y none', () {
      final vista = VistaUlima.fromJson(
        vistaJson(
          courses: [
            cursoJson(
              assessments: [
                evaluacionJson(mark: 'otra_cosa', match: 'parecida'),
              ],
            ),
          ],
        ),
      );

      final e = vista.cursos.single.evaluaciones.single;
      expect(e.mark, MarcaUlima.pending);
      expect(e.value, isNull);
      expect(e.match, ParejaUlima.none);
      expect(e.tienePareja, isFalse);
    });

    test('np, exact_other_name y una evaluación sin semana', () {
      final vista = VistaUlima.fromJson(
        vistaJson(
          courses: [
            cursoJson(
              assessments: [
                evaluacionJson(
                  mark: 'np',
                  value: null,
                  match: 'exact_other_name',
                  week: null,
                ),
              ],
            ),
          ],
        ),
      );

      final e = vista.cursos.single.evaluaciones.single;
      expect(e.mark, MarcaUlima.np);
      expect(e.value, isNull);
      expect(e.publicada, isTrue);
      expect(e.match, ParejaUlima.exactOtherName);
      expect(e.week, isNull);
    });

    test('un graded sin valor se lee como pending y un match sin '
        'assessmentId como none', () {
      final vista = VistaUlima.fromJson(
        vistaJson(
          courses: [
            cursoJson(
              assessments: [
                evaluacionJson(value: null),
                evaluacionJson(assessmentId: null, match: 'exact'),
              ],
            ),
          ],
        ),
      );

      final evaluaciones = vista.cursos.single.evaluaciones;
      expect(evaluaciones.first.mark, MarcaUlima.pending);
      expect(evaluaciones.last.match, ParejaUlima.none);
    });

    test('una fecha ilegible queda null', () {
      final vista = VistaUlima.fromJson(
        vistaJson(
          lastReadAt: 'ayer por la tarde',
          courses: [cursoJson(lastReadAt: 42)],
        ),
      );

      expect(vista.lastReadAt, isNull);
      expect(vista.cursos.single.lastReadAt, isNull);
    });

    test('sin período activo la vista llega vacía, y un cuerpo que no es un '
        'mapa también', () {
      final vacia = VistaUlima.fromJson(<String, dynamic>{
        'lastReadAt': null,
        'courses': <dynamic>[],
      });
      expect(vacia.lastReadAt, isNull);
      expect(vacia.cursos, isEmpty);

      expect(VistaUlima.fromJson(null).cursos, isEmpty);
    });
  });

  group('UNITARIA · ResultadoRecarga (RF-RCG-1)', () {
    test('el resultado de la recarga trae sus estados por curso y su view', () {
      final r = ResultadoRecarga.fromJson(
        resultadoJson(
          courses: [
            {
              'sectionId': 81,
              'courseCode': '690417',
              'sectionCode': '812',
              'attendance': 'updated',
              'grades': 'read',
            },
            {
              'sectionId': '82',
              'courseCode': '690418',
              'sectionCode': '813',
              'attendance': 'missing',
              'grades': 'failed',
            },
          ],
        ),
      );

      expect(r.readAt, DateTime.utc(2025, 9, 22, 15, 42, 10));
      expect(r.estados, hasLength(2));
      expect(r.estados.first.sectionId, 81);
      expect(r.estados.first.attendance, 'updated');
      expect(r.estados.first.grades, 'read');
      expect(r.estados.last.sectionId, 82);
      expect(r.estados.last.attendance, 'missing');
      expect(r.estados.last.grades, 'failed');
      expect(r.view.cursos.single.courseName, 'TALLER DE PROTOTIPADO');
    });
  });
}
