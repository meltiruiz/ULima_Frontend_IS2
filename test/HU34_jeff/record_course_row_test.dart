import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/academic_record_model.dart';
import 'package:ulima_plus/pages/academic_record/record_course_row.dart';

/// Récord académico: la fila de un curso (RF-REC-3).
///
/// El chip es la única parte del récord donde un error de lógica cambia lo que
/// el alumno cree de su historia académica: pintar de azul —el color de las
/// marcas del portal, como una convalidación— un curso del ciclo en curso que
/// todavía no tiene nota le diría que ya no lo lleva. Por eso la decisión vive
/// en funciones puras, probadas caso por caso, y el widget solo las llama.
///
/// Todos los cursos, códigos, notas y observaciones son inventados.
void main() {
  RecordCourse curso({
    String code = '100001',
    String name = 'CURSO DE PRUEBA UNO',
    int? attempt = 1,
    double? credits = 3,
    int? grade,
    String? gradeRaw,
    String? section = '917',
    String? observation,
  }) => RecordCourse(
    code: code,
    name: name,
    attempt: attempt,
    credits: credits,
    grade: grade,
    gradeRaw: gradeRaw,
    section: section,
    observation: observation,
  );

  Widget montar(RecordCourse course, {bool isMostRecentPeriod = false}) =>
      MaterialApp(
        home: Scaffold(
          body: RecordCourseRow(
            course: course,
            isMostRecentPeriod: isMostRecentPeriod,
          ),
        ),
      );

  group('UNITARIA · recordChipFor: los seis casos de RF-REC-3', () {
    RecordChip chip(int? grade, String? gradeRaw, {bool reciente = false}) =>
        recordChipFor(
          grade: grade,
          gradeRaw: gradeRaw,
          isMostRecentPeriod: reciente,
        );

    test('de 14 para arriba: verde, con la nota', () {
      expect(chip(20, null), (tone: RecordChipTone.green, label: '20'));
      expect(chip(17, null), (tone: RecordChipTone.green, label: '17'));
      expect(chip(14, null), (tone: RecordChipTone.green, label: '14'));
    });

    test('de 11 a 13: ámbar', () {
      expect(chip(13, null), (tone: RecordChipTone.amber, label: '13'));
      expect(chip(11, null), (tone: RecordChipTone.amber, label: '11'));
    });

    test('por debajo de 11: rojo, y las de un dígito con cero delante', () {
      expect(chip(10, null), (tone: RecordChipTone.red, label: '10'));
      expect(chip(8, null), (tone: RecordChipTone.red, label: '08'));
      expect(chip(0, null), (tone: RecordChipTone.red, label: '00'));
    });

    test('sin nota pero con marca del portal: azul, con el texto tal cual', () {
      expect(chip(null, 'CONV'), (tone: RecordChipTone.blue, label: 'CONV'));
      expect(chip(null, 'RET'), (tone: RecordChipTone.blue, label: 'RET'));
      // Una marca del portal es azul también en el ciclo más reciente.
      expect(
        chip(null, 'CONV', reciente: true),
        (tone: RecordChipTone.blue, label: 'CONV'),
      );
    });

    test('sin nota en el ciclo más reciente: neutro, "En curso"', () {
      expect(
        chip(null, null, reciente: true),
        (tone: RecordChipTone.neutral, label: 'En curso'),
      );
      // Un gradeRaw en blanco no es una marca: es un dato que no vino.
      expect(
        chip(null, '   ', reciente: true),
        (tone: RecordChipTone.neutral, label: 'En curso'),
      );
    });

    test('sin nota en un ciclo viejo: neutro, una raya', () {
      expect(chip(null, null), (tone: RecordChipTone.neutral, label: '—'));
      expect(chip(null, '   '), (tone: RecordChipTone.neutral, label: '—'));
    });

    test('un curso sin nota del ciclo en curso NUNCA se pinta de azul', () {
      // El caso que la spec marca aparte (spec:100-101): el ciclo en curso
      // viene seleccionado, así que sus cursos sin nota son lo primero que ve
      // el alumno. En azul parecerían convalidados o retirados.
      expect(chip(null, null, reciente: true).tone, isNot(RecordChipTone.blue));
    });

    test('la nota manda sobre el ciclo: un 15 del ciclo en curso va en verde', () {
      expect(chip(15, null, reciente: true), (
        tone: RecordChipTone.green,
        label: '15',
      ));
    });

    test('la nota numérica manda sobre gradeRaw cuando ambas vienen pobladas', () {
      // Caso aprobado: nota y su texto coinciden, en verde.
      expect(chip(15, '15'), (tone: RecordChipTone.green, label: '15'));
      // Caso desaprobado: nota y su texto son distintos, pero la nota decide.
      expect(chip(8, '08'), (tone: RecordChipTone.red, label: '08'));
    });

    test('los rótulos neutros son las constantes de la fila', () {
      expect(RecordCourseRow.inProgressLabel, 'En curso');
      expect(RecordCourseRow.noGradeLabel, '—');
    });
  });

  group('UNITARIA · attemptLabel y courseSubtitle', () {
    test('la etiqueta aparece recién desde la segunda vez', () {
      expect(attemptLabel(null), isNull);
      expect(attemptLabel(0), isNull);
      expect(attemptLabel(1), isNull);
      expect(attemptLabel(2), '2.ª vez');
      expect(attemptLabel(3), '3.ª vez');
    });

    test('el subtítulo junta el código y los créditos con " · "', () {
      expect(
        courseSubtitle(code: '100002', credits: 1.5),
        '100002 · 1.5 créd.',
      );
      // Un valor entero va sin ".0".
      expect(courseSubtitle(code: '100002', credits: 3), '100002 · 3 créd.');
    });

    test('sin créditos queda solo el código: nunca "0 créd."', () {
      expect(courseSubtitle(code: '100002', credits: null), '100002');
    });
  });

  group('UNITARIA · recordChipColors', () {
    test('verde, ámbar y rojo son los colores que el repo ya usa', () {
      expect(
        recordChipColors(RecordChipTone.green, Brightness.light).foreground,
        const Color(0xFF16A34A),
      );
      expect(
        recordChipColors(RecordChipTone.amber, Brightness.light).foreground,
        const Color(0xFFD97706),
      );
      expect(
        recordChipColors(RecordChipTone.red, Brightness.light).foreground,
        const Color(0xFFDC2626),
      );
    });

    test('el fondo de la nota es su mismo color con alfa, no un color nuevo', () {
      expect(
        recordChipColors(RecordChipTone.green, Brightness.light).background,
        const Color(0xFF16A34A).withValues(alpha: 0.12),
      );
      expect(
        recordChipColors(RecordChipTone.red, Brightness.light).background,
        const Color(0xFFDC2626).withValues(alpha: 0.12),
      );
      expect(
        recordChipColors(RecordChipTone.amber, Brightness.light).background,
        const Color(0xFFF59E0B).withValues(alpha: 0.15),
      );
    });

    test('los tres colores de nota no cambian con el modo oscuro', () {
      for (final tono in [
        RecordChipTone.green,
        RecordChipTone.amber,
        RecordChipTone.red,
      ]) {
        expect(
          recordChipColors(tono, Brightness.dark).foreground,
          recordChipColors(tono, Brightness.light).foreground,
          reason: 'la nota se lee igual en los dos modos',
        );
      }
    });

    test('el azul sí cambia con el modo, como el chip de interés del Perfil', () {
      expect(
        recordChipColors(RecordChipTone.blue, Brightness.light).foreground,
        const Color(0xFF0369A1),
      );
      expect(
        recordChipColors(RecordChipTone.blue, Brightness.dark).foreground,
        const Color(0xFF38BDF8),
      );
      for (final b in [Brightness.light, Brightness.dark]) {
        expect(
          recordChipColors(RecordChipTone.blue, b).background,
          MaterialTheme.espInteresBg(b),
        );
      }
    });

    test('el neutro sale del tema, como la insignia "Fija" del Perfil', () {
      for (final b in [Brightness.light, Brightness.dark]) {
        final colores = recordChipColors(RecordChipTone.neutral, b);
        expect(colores.foreground, MaterialTheme.labelColor(b));
        expect(colores.background, MaterialTheme.tagBg(b));
      }
    });
  });

  group('WIDGET · RecordCourseRow', () {
    testWidgets('un curso repetido con nota y observación muestra las cinco cosas', (
      tester,
    ) async {
      await tester.pumpWidget(
        montar(
          curso(
            code: '100002',
            name: 'CURSO DE PRUEBA DOS',
            attempt: 2,
            credits: 1.5,
            grade: 17,
            observation: 'Convalidado por examen',
          ),
        ),
      );

      expect(find.text('CURSO DE PRUEBA DOS'), findsOneWidget);
      expect(find.text('2.ª vez'), findsOneWidget);
      expect(find.text('100002 · 1.5 créd.'), findsOneWidget);
      expect(find.text('17'), findsOneWidget);
      expect(find.text('Convalidado por examen'), findsOneWidget);

      // "debajo del código, en texto pequeño" (spec:104-105): la observación
      // se lee más chica que el subtítulo, no igual.
      final tamanoCodigo = tester
          .widget<Text>(find.text('100002 · 1.5 créd.'))
          .style
          ?.fontSize;
      final tamanoObservacion = tester
          .widget<Text>(find.text('Convalidado por examen'))
          .style
          ?.fontSize;
      expect(tamanoCodigo, isNotNull);
      expect(tamanoObservacion, lessThan(tamanoCodigo!));
    });

    testWidgets('en la primera vez no aparece ninguna etiqueta', (tester) async {
      await tester.pumpWidget(montar(curso(attempt: 1, grade: 13)));
      expect(find.textContaining('vez'), findsNothing);
    });

    testWidgets('el chip usa el color de su tono, no uno propio', (tester) async {
      await tester.pumpWidget(montar(curso(grade: 17)));
      expect(
        tester.widget<Text>(find.text('17')).style?.color,
        const Color(0xFF16A34A),
      );

      await tester.pumpWidget(montar(curso(grade: 8)));
      expect(
        tester.widget<Text>(find.text('08')).style?.color,
        const Color(0xFFDC2626),
      );
    });

    testWidgets('un curso de una malla anterior conserva su código y su nombre', (
      tester,
    ) async {
      await tester.pumpWidget(
        montar(
          curso(
            code: '1234',
            name: 'CURSO ANTIGUO DE PRUEBA',
            credits: 2,
            grade: 12,
          ),
        ),
      );
      expect(find.text('CURSO ANTIGUO DE PRUEBA'), findsOneWidget);
      expect(find.text('1234 · 2 créd.'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('sin nota: "En curso" en el ciclo reciente y una raya en otro', (
      tester,
    ) async {
      await tester.pumpWidget(montar(curso(), isMostRecentPeriod: true));
      expect(find.text('En curso'), findsOneWidget);
      expect(find.text('—'), findsNothing);

      await tester.pumpWidget(montar(curso()));
      expect(find.text('—'), findsOneWidget);
      expect(find.text('En curso'), findsNothing);
    });

    testWidgets('sin créditos el subtítulo es solo el código', (tester) async {
      await tester.pumpWidget(
        montar(curso(code: '100004', credits: null, gradeRaw: 'CONV')),
      );
      expect(find.text('100004'), findsOneWidget);
      expect(find.text('CONV'), findsOneWidget);
    });
  });
}
