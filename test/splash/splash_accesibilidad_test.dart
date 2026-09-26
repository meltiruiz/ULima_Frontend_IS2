// test/splash/splash_accesibilidad_test.dart
//
// WIDGET · Splash animado (specs/features/splash/splash.spec.md).
// RF-SPL-15. Durante la intro la capa es un solo nodo de semántica con la
// etiqueta fija «ULIMA++, cargando», sin región viva ni anuncios, y el
// lector no ve la página de debajo. Inactiva, queda fuera de la semántica.

import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/pages/splash/capa_de_arranque.dart';
import 'package:ulima_plus/services/splash_variante_service.dart';

import 'apoyo_splash.dart';

void main() {
  final anuncios = <Object?>[];

  setUp(() {
    reiniciarArranque();
    anuncios.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockDecodedMessageHandler<Object?>(SystemChannels.accessibility, (
          mensaje,
        ) async {
          anuncios.add(mensaje);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockDecodedMessageHandler<Object?>(
          SystemChannels.accessibility,
          null,
        );
    reiniciarArranque();
  });

  testWidgets('durante la intro hay un solo nodo «ULIMA++, cargando», fijo, '
      'sin región viva, y la página de debajo no se ve', (tester) async {
    final semantica = tester.ensureSemantics();
    telefono(tester);
    await tester.pumpWidget(
      appConCapa(
        intro: IntroDelArranque(
          carga: CargaFalsa().call,
          variantes: VariantesFijas(VarianteSplash.incremento),
          random: Random(1),
        ),
      ),
    );
    // El texto exacto de la spec (RF-SPL-15).
    expect(etiquetaDeLaIntro, 'ULIMA++, cargando');
    for (var ms = 0; ms <= 1500; ms += 250) {
      await tester.pump(const Duration(milliseconds: 250));
      final nodo = find.bySemanticsLabel(etiquetaDeLaIntro);
      expect(nodo, findsOneWidget, reason: 'a los $ms ms');
      expect(
        tester.getSemantics(nodo),
        isSemantics(label: etiquetaDeLaIntro, isLiveRegion: false),
      );
    }
    // La página de debajo queda fuera de la semántica.
    final excluida = tester.widget<ExcludeSemantics>(
      find
          .descendant(
            of: find.byType(CapaDeArranque),
            matching: find.byType(ExcludeSemantics),
          )
          .first,
    );
    expect(excluida.excluding, isTrue);
    expect(anuncios, isEmpty);
    semantica.dispose();
  });

  testWidgets('sin intro la capa queda fuera de la semántica y la página se '
      'lee', (tester) async {
    final semantica = tester.ensureSemantics();
    telefono(tester);
    await tester.pumpWidget(appConCapa());
    await tester.pump();
    expect(find.bySemanticsLabel(etiquetaDeLaIntro), findsNothing);
    expect(find.bySemanticsLabel('bienvenida'), findsOneWidget);
    semantica.dispose();
  });
}
