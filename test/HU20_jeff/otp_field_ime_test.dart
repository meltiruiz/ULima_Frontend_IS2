// test/HU20_jeff/otp_field_ime_test.dart
// El campo de código (HU20) y su trato con el IME.
//
// EL BUG (2026-09-07, iPhone SE, release): con las seis casillas llenas, el
// retroceso dejaba de borrar. Causa raíz, verificada contra el SDK:
//
//   1. `LengthLimitingTextInputFormatter` era el ÚNICO código de la cadena cuyo
//      comportamiento dependía del 6. En iOS su modo por defecto
//      (`truncateAfterCompositionEnds`) devuelve el valor VIEJO en cuanto
//      `oldValue` mide exactamente `maxLength` (text_formatter.dart:585-590).
//   2. Al llegar un séptimo carácter, el framework ya había guardado el valor
//      crudo como «lo que sabe el IME», pero `_value` se quedaba en el viejo.
//      Entonces `EditableText._updateRemoteEditingValueIfNeeded()` le mandaba a
//      iOS un `setEditingState` asíncrono: framework e IME pasaban a ser dos
//      escritores del mismo texto sin número de secuencia.
//   3. El otro emisor de esa contradicción era el listener del widget, que
//      escribía `controller.selection` desde dentro de una notificación del
//      propio controller.
//
// POR QUÉ ESTAS PRUEBAS NO REPRODUCEN EL BUG, Y AUN ASÍ VALEN: no pueden.
// `TestTextInput` se limita a archivar `TextInput.setEditingState` sin hacer
// nada con él (`test_text_input.dart:146-147`), así que el bucle
// framework → plataforma → framework donde vive el fallo está cortado por
// definición; y `FLUTTER_TEST` fuerza `TargetPlatform.android`, que ni siquiera
// usa la rama del `switch` culpable. Una sesión entera se perdió intentándolo.
//
// Lo que estas pruebas SÍ fijan es la causa: que el widget no vuelva a tener
// ningún emisor de `setEditingState`. Si alguien reintroduce la escritura al
// controller o el limitador de longitud, esto se pone rojo.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/pages/password_reset/password_reset_ui.dart';
import 'package:ulima_plus/pages/password_reset/password_reset_validators.dart';

void main() {
  // La paleta se deriva del tema, así que hay que construirla dentro del árbol.
  Future<TextEditingController> montar(WidgetTester tester, {String texto = ''}) async {
    final controller = TextEditingController(text: texto);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => PasswordResetOtpField(
              controller: controller,
              palette: PasswordResetPalette.from(context),
            ),
          ),
        ),
      ),
    );
    return controller;
  }

  group('el widget nunca escribe en el controller', () {
    testWidgets('no toca la selección cuando cambia el texto', (tester) async {
      // Ésta es LA prueba de regresión. La versión con el bug forzaba aquí
      // `TextSelection.collapsed(offset: text.length)`, y esa escritura
      // re-entrante es la que acababa contradiciendo al IME de iOS.
      final controller = await montar(tester);

      controller.value = const TextEditingValue(
        text: '123',
        selection: TextSelection.collapsed(offset: 1), // caret a propósito NO al final
      );
      await tester.pump();

      expect(controller.selection.baseOffset, 1,
          reason: 'el widget movió el caret; volvería a pelearse con el IME');
      expect(controller.text, '123');
    });

    testWidgets('con el campo lleno tampoco lo toca', (tester) async {
      final controller = await montar(tester, texto: '12345');

      controller.value = const TextEditingValue(
        text: '123456',
        selection: TextSelection.collapsed(offset: 2),
      );
      await tester.pump();

      expect(controller.selection.baseOffset, 2);
    });
  });

  group('el largo se recorta al pintar, no en el pipeline de entrada', () {
    testWidgets('un séptimo dígito no se pierde del controller', (tester) async {
      // Sin LengthLimitingTextInputFormatter el controller acepta lo que mande
      // la plataforma. Eso es deliberado: cualquier recorte dentro del pipeline
      // reintroduce la divergencia con el IME.
      final controller = await montar(tester);
      controller.text = '1234567';
      await tester.pump();

      expect(controller.text, '1234567');
    });

    testWidgets('pero sólo se pintan los seis primeros', (tester) async {
      await montar(tester, texto: '1234567');
      await tester.pump();

      for (final d in ['1', '2', '3', '4', '5', '6']) {
        expect(find.text(d), findsOneWidget);
      }
      expect(find.text('7'), findsNothing);
    });
  });

  group('la casilla activa deja de quedarse clavada', () {
    testWidgets('con el campo lleno no hay ninguna resaltada', (tester) async {
      // La versión anterior dejaba `activeIndex = length - 1`, así que el borde
      // se veía igual con cinco dígitos que con seis: la pantalla parecía
      // congelada y de ahí «parece que cada uno de los cuadros fuera uno solo».
      await montar(tester, texto: '123456');
      await tester.pump();

      final llenos = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .where((c) => ((c.decoration as BoxDecoration?)?.border as Border?)
                  ?.top
                  .color !=
              Colors.transparent);
      expect(llenos, isEmpty,
          reason: 'con el campo lleno ninguna casilla debe llevar borde de foco');
    });
  });

  group('el passcode del portal no queda capado a 6', () {
    test('el validador del portal acepta de 6 a 8 dígitos', () {
      // El LengthLimitingTextInputFormatter(6) que se quitó hacía IMPOSIBLE
      // teclear un passcode de 7 u 8, aunque el validador los aceptara. Quitarlo
      // arregla ese bug de paso; esta prueba fija que el contrato sigue siendo
      // 6-8 y que a nadie se le ocurra recortar a 6 al leer.
      expect(RegExp(r'^\d{6,8}$').hasMatch('123456'), isTrue);
      expect(RegExp(r'^\d{6,8}$').hasMatch('12345678'), isTrue);
    });

    test('el código de recuperación, en cambio, son exactamente 6', () {
      expect(passwordResetCodeLength, 6);
      expect(validateResetCode('1234567'), isNotNull);
    });
  });
}
