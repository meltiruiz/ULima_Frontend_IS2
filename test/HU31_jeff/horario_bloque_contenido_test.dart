import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/pages/horario/horario.dart';

/// Qué texto lleva un bloque del horario debajo del nombre del curso.
///
/// La vista de día a día tiene que decir solo NOMBRE DEL CURSO y el salón donde
/// se dicta, nada más. Antes metía además "Sección: XXX", que no le sirve al
/// alumno: ya está matriculado en una sola sección y la ve en el detalle del
/// curso. El salón sí cambia de semana a semana y es lo que se va a buscar.
///
/// La vista semanal horizontal es otra cosa y NO cambia: ahí cada día es una
/// columna angosta donde el salón no entra, y la sección solo aparece si el
/// bloque tiene alto suficiente.
void main() {
  const alto = HorarioPage.compactMetaMinHeight;

  List<String> lineas({
    required bool vistaDia,
    bool compact = false,
    double height = 90,
    String seccionLabel = 'Sección: 855',
    String aula = 'A-501',
  }) => HorarioPage.blockMetaLines(
    vistaDia: vistaDia,
    compact: compact,
    height: height,
    seccionLabel: seccionLabel,
    aula: aula,
  );

  group('vista de día a día', () {
    test('muestra el salón y nada más', () {
      expect(lineas(vistaDia: true), ['A-501']);
    });

    test('nunca muestra la sección', () {
      expect(lineas(vistaDia: true), isNot(contains('Sección: 855')));
    });

    test('SIGUE mostrando el salón aunque el bloque salga compacto', () {
      // Regresión del 2026-09-07, vista en un iPhone SE: la vista de día calcula
      // `compact: dynamicHourHeight < 35`, y al comprimir las 15 horas del día en
      // una pantalla chica el alto de hora baja a ~25 px, así que compact es TRUE
      // también aquí. La primera versión decidía por `compact` y por eso el
      // teléfono seguía mostrando "Sección: 952". La vista manda, no el tamaño.
      expect(lineas(vistaDia: true, compact: true, height: 50), ['A-501']);
    });

    test('si el backend no manda salón, se muestra el marcador y no la sección', () {
      expect(lineas(vistaDia: true, aula: 'Sin salón'), ['Sin salón']);
    });
  });

  group('vista semanal horizontal: no cambia', () {
    test('muestra la sección cuando el bloque tiene alto suficiente', () {
      expect(lineas(vistaDia: false, compact: true, height: alto), ['Sección: 855']);
    });

    test('no muestra nada cuando el bloque es demasiado bajo', () {
      expect(lineas(vistaDia: false, compact: true, height: alto - 1), isEmpty);
    });

    test('nunca muestra el salón, que no entra en una columna de día', () {
      expect(lineas(vistaDia: false, compact: true, height: 90), isNot(contains('A-501')));
    });

    test('una asesoría lleva su propia etiqueta, no el prefijo "Sección:"', () {
      expect(
        lineas(vistaDia: false, compact: true, height: alto, seccionLabel: 'Asesoría'),
        ['Asesoría'],
      );
    });
  });

  group('el umbral de alto sigue protegiendo a los bloques diminutos', () {
    test('un bloque bajísimo no pinta texto en ninguna de las dos vistas', () {
      expect(lineas(vistaDia: true, compact: true, height: alto - 1), isEmpty);
      expect(lineas(vistaDia: false, compact: true, height: alto - 1), isEmpty);
    });
  });
}
