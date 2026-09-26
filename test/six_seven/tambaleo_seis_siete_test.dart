// test/six_seven/tambaleo_seis_siete_test.dart
//
// WIDGET · Truco del 67 (specs/features/six-seven/six-seven.spec.md).
// RF-67-2 fija el tambaleo, RF-67-3 que haya uno a la vez, RF-67-4 el
// movimiento reducido y RF-67-7 el rótulo de los chats de sección.
// Archivo probado lib/components/seis_siete/tambaleo_seis_siete.dart.
//
// Todos los datos son inventados; el repo es público.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/components/seis_siete/tambaleo_seis_siete.dart';
import 'package:ulima_plus/configs/themes.dart';

/// 3° en radianes.
const _tresGrados = 3 * math.pi / 180;

/// El envoltorio dentro de una app con el tema real, con un [MediaQuery]
/// que [ajustar] puede cambiar (movimiento reducido, teclado, letra).
///
/// Va en el `builder` de la app y no en `home`, porque la ruta inicial no
/// se reconstruye cuando cambia `home` y el envoltorio no vería el contador
/// nuevo. El `MediaQuery` va siempre, para que cambiar [ajustar] no vuelva a
/// montar el envoltorio.
Widget _banco({
  required int disparos,
  bool conRotulo = false,
  Widget? hijo,
  Brightness brillo = Brightness.light,
  MediaQueryData Function(MediaQueryData)? ajustar,
}) {
  const tema = MaterialTheme(TextTheme());
  return MaterialApp(
    theme: brillo == Brightness.light ? tema.light() : tema.dark(),
    home: const SizedBox.shrink(),
    builder: (context, _) => MediaQuery(
      data: (ajustar ?? (d) => d)(MediaQuery.of(context)),
      child: TambaleoSeisSiete(
        disparos: disparos,
        conRotulo: conRotulo,
        child: hijo ?? const Scaffold(body: Center(child: Text('chat'))),
      ),
    ),
  );
}

/// Ángulo en radianes del `Transform` del envoltorio.
double _angulo(WidgetTester tester) {
  final m = tester.widget<Transform>(find.byKey(claveGiroSeisSiete)).transform;
  return math.atan2(m.entry(1, 0), m.entry(0, 0));
}

final _rotulo = find.byKey(claveRotuloSeisSiete);

/// Monta con [base] y dispara una vez, subiendo a [base] + 1.
Future<void> _disparar(
  WidgetTester tester, {
  int base = 5,
  bool conRotulo = false,
  Widget? hijo,
  MediaQueryData Function(MediaQueryData)? ajustar,
}) async {
  await tester.pumpWidget(
    _banco(disparos: base, conRotulo: conRotulo, hijo: hijo, ajustar: ajustar),
  );
  await tester.pumpWidget(
    _banco(
      disparos: base + 1,
      conRotulo: conRotulo,
      hijo: hijo,
      ajustar: ajustar,
    ),
  );
}

/// Hijo con estado que cuenta cuántas veces se monta.
class _HijoConEstado extends StatefulWidget {
  const _HijoConEstado();

  static int montajes = 0;

  @override
  State<_HijoConEstado> createState() => _HijoConEstadoState();
}

class _HijoConEstadoState extends State<_HijoConEstado> {
  @override
  void initState() {
    super.initState();
    _HijoConEstado.montajes++;
  }

  @override
  Widget build(BuildContext context) => const Text('con estado');
}

void main() {
  testWidgets('montado con 5 no gira ni muestra el rótulo, y reconstruido '
      'con 5 tampoco', (tester) async {
    await tester.pumpWidget(_banco(disparos: 5, conRotulo: true));
    expect(_angulo(tester), 0);
    expect(_rotulo, findsNothing);

    await tester.pumpWidget(_banco(disparos: 5, conRotulo: true));
    await tester.pump(const Duration(milliseconds: 125));
    expect(_angulo(tester), 0);
    expect(_rotulo, findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('con 6 gira −3° a los 125 ms, vuelve a 0° a los 1000 ms y a '
      'los 2000 ms queda quieto', (tester) async {
    await _disparar(tester);

    await tester.pump(const Duration(milliseconds: 125));
    expect(_angulo(tester), closeTo(-_tresGrados, 1e-6));

    await tester.pump(const Duration(milliseconds: 250));
    expect(_angulo(tester), closeTo(_tresGrados, 1e-6));

    await tester.pump(const Duration(milliseconds: 625));
    expect(_angulo(tester), closeTo(0, 1e-6));

    await tester.pump(const Duration(milliseconds: 1000));
    expect(_angulo(tester), 0);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('subir a 7 a los 500 ms no reinicia el tambaleo y subir a 8 '
      'después de terminar dispara otro (RF-67-3)', (tester) async {
    await _disparar(tester);
    await tester.pump(const Duration(milliseconds: 500));

    await tester.pumpWidget(_banco(disparos: 7));
    await tester.pump(const Duration(milliseconds: 1500));
    expect(_angulo(tester), 0);
    expect(tester.hasRunningAnimations, isFalse);

    await tester.pumpWidget(_banco(disparos: 8));
    await tester.pump(const Duration(milliseconds: 125));
    expect(_angulo(tester), closeTo(-_tresGrados, 1e-6));
    await tester.pump(const Duration(milliseconds: 1875));
  });

  testWidgets('un hijo con estado no se vuelve a montar al empezar ni al '
      'terminar el tambaleo', (tester) async {
    _HijoConEstado.montajes = 0;
    const hijo = Scaffold(body: _HijoConEstado());
    await tester.pumpWidget(_banco(disparos: 5, hijo: hijo));
    final estado = tester.state(find.byType(_HijoConEstado));

    await tester.pumpWidget(_banco(disparos: 6, hijo: hijo));
    await tester.pump(const Duration(milliseconds: 125));
    expect(tester.state(find.byType(_HijoConEstado)), same(estado));

    await tester.pump(const Duration(milliseconds: 1875));
    expect(tester.state(find.byType(_HijoConEstado)), same(estado));
    expect(_HijoConEstado.montajes, 1);
  });

  for (final brillo in Brightness.values) {
    testWidgets('en ${brillo.name}, el área va dentro de un ClipRect, su hijo '
        'dentro de un RepaintBoundary y el fondo descubierto es pageBg', (
      tester,
    ) async {
      await tester.pumpWidget(_banco(disparos: 0, brillo: brillo));
      final giro = find.byKey(claveGiroSeisSiete);
      expect(
        find.ancestor(of: giro, matching: find.byType(ClipRect)),
        findsWidgets,
      );
      expect(tester.widget<Transform>(giro).child, isA<RepaintBoundary>());
      final fondo = tester.widget<ColoredBox>(
        find.ancestor(of: giro, matching: find.byType(ColoredBox)).first,
      );
      expect(fondo.color, MaterialTheme.pageBg(brillo));
    });
  }

  testWidgets('con el teclado abierto gira alrededor del centro de lo que '
      'queda a la vista y el rótulo se centra ahí', (tester) async {
    tester.view.physicalSize = const Size(750, 1334);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await _disparar(
      tester,
      conRotulo: true,
      ajustar: (d) =>
          d.copyWith(viewInsets: const EdgeInsets.only(bottom: 260)),
    );
    await tester.pump(const Duration(milliseconds: 125));

    expect(
      tester.widget<Transform>(find.byKey(claveGiroSeisSiete)).origin,
      const Offset(0, -130),
    );
    final centro = tester.getCenter(_rotulo);
    expect(centro.dx, closeTo(187.5, 0.01));
    expect(centro.dy, closeTo((667 - 260) / 2, 0.01));
    await tester.pump(const Duration(milliseconds: 1875));
  });

  testWidgets('con disableAnimations en el MediaQuery no gira (RF-67-4)', (
    tester,
  ) async {
    await _disparar(
      tester,
      ajustar: (d) => d.copyWith(disableAnimations: true),
    );
    for (var ms = 0; ms < 2000; ms += 125) {
      expect(_angulo(tester), 0, reason: '$ms ms');
      await tester.pump(const Duration(milliseconds: 125));
    }
  });

  testWidgets('con reduceMotion en las funciones de accesibilidad no gira '
      '(RF-67-4)', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(reduceMotion: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await _disparar(tester);
    for (var ms = 0; ms < 2000; ms += 125) {
      expect(_angulo(tester), 0, reason: '$ms ms');
      await tester.pump(const Duration(milliseconds: 125));
    }
  });

  testWidgets('el rótulo se ve sin girar durante el tambaleo, no está a los '
      '2000 ms y deja pasar el toque (RF-67-7)', (tester) async {
    var toques = 0;
    final hijo = Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => toques++,
          child: const Text('debajo'),
        ),
      ),
    );
    await _disparar(tester, conRotulo: true, hijo: hijo);
    await tester.pump(const Duration(milliseconds: 125));

    expect(find.text('SIX SEVEN!!!'), findsOneWidget);
    expect(
      find.ancestor(of: _rotulo, matching: find.byKey(claveGiroSeisSiete)),
      findsNothing,
    );

    await tester.tap(find.text('debajo'), warnIfMissed: false);
    expect(toques, 1);

    await tester.pump(const Duration(milliseconds: 1875));
    expect(find.text('SIX SEVEN!!!'), findsNothing);
  });

  testWidgets('con movimiento reducido el rótulo aparece sin giro ni '
      'animación, sigue a los 1900 ms y no está a los 2000 ms', (tester) async {
    // Esta marca también acorta al 5 % los AnimationController normales.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await _disparar(tester, conRotulo: true);
    await tester.pump();
    expect(_rotulo, findsOneWidget);
    expect(_angulo(tester), 0);
    expect(
      find.ancestor(of: _rotulo, matching: find.byType(Opacity)),
      findsNothing,
    );

    await tester.pump(const Duration(milliseconds: 1900));
    expect(_rotulo, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    expect(_rotulo, findsNothing);
  });

  testWidgets('con movimiento reducido, subir el contador a los 1000 ms no '
      'suma ni alarga el rótulo, y después de 2000 ms lo muestra de nuevo', (
    tester,
  ) async {
    MediaQueryData reducido(MediaQueryData d) =>
        d.copyWith(disableAnimations: true);
    await _disparar(tester, conRotulo: true, ajustar: reducido);
    await tester.pump(const Duration(milliseconds: 1000));

    await tester.pumpWidget(
      _banco(disparos: 7, conRotulo: true, ajustar: reducido),
    );
    expect(_rotulo, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(_rotulo, findsNothing);

    await tester.pumpWidget(
      _banco(disparos: 8, conRotulo: true, ajustar: reducido),
    );
    expect(_rotulo, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2000));
    expect(_rotulo, findsNothing);
  });

  testWidgets('cambiar disableAnimations en medio de un tambaleo no lo '
      'cambia (RF-67-4)', (tester) async {
    MediaQueryData reducido(MediaQueryData d) =>
        d.copyWith(disableAnimations: true);

    // Encenderlo a los 500 ms no corta el giro, y el siguiente ya no gira.
    await _disparar(tester);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpWidget(_banco(disparos: 6, ajustar: reducido));
    await tester.pump(const Duration(milliseconds: 125));
    expect(_angulo(tester), closeTo(-_tresGrados, 1e-6));
    await tester.pump(const Duration(milliseconds: 1375));
    expect(_angulo(tester), 0);
    expect(tester.hasRunningAnimations, isFalse);

    await tester.pumpWidget(_banco(disparos: 7, ajustar: reducido));
    await tester.pump(const Duration(milliseconds: 125));
    expect(_angulo(tester), 0);

    // Apagarlo a los 500 ms de un disparo reducido no agrega giro.
    await tester.pump(const Duration(milliseconds: 375));
    await tester.pumpWidget(_banco(disparos: 7));
    await tester.pump(const Duration(milliseconds: 125));
    expect(_angulo(tester), 0);
    await tester.pump(const Duration(milliseconds: 1375));
  });

  testWidgets('con el texto del sistema al doble, el rótulo cabe en 375 de '
      'ancho sin desborde', (tester) async {
    tester.view.physicalSize = const Size(750, 1334);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await _disparar(
      tester,
      conRotulo: true,
      ajustar: (d) => d.copyWith(textScaler: const TextScaler.linear(2)),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    expect(tester.getSize(_rotulo).width, lessThanOrEqualTo(375 - 32));
    await tester.pump(const Duration(milliseconds: 1500));
  });

  testWidgets('el rótulo es una región viva con la etiqueta «SIX SEVEN!!!»', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await _disparar(tester, conRotulo: true);
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      tester.getSemantics(_rotulo),
      isSemantics(label: 'SIX SEVEN!!!', isLiveRegion: true),
    );
    await tester.pump(const Duration(milliseconds: 1500));
    semantica.dispose();
  });

  testWidgets('quitarlo del árbol a los 500 ms no deja errores ni '
      'animaciones pendientes', (tester) async {
    await _disparar(tester, conRotulo: true);
    await tester.pump(const Duration(milliseconds: 500));

    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
