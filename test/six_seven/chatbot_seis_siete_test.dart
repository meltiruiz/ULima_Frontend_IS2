// test/six_seven/chatbot_seis_siete_test.dart
//
// UNITARIA y WIDGET · Truco del 67 en el chat de Ulises
// (specs/features/six-seven/six-seven.spec.md, RF-67-5, con RF-67-2 y
// RF-67-4). Monta ChatbotPage con un ChatbotService falso que devuelve una
// conversación y anota cada llamada. Salvo que el caso diga otra cosa, usa la
// superficie de 800 × 600 de flutter_test, que ChatbotPage trata como ancha.
//
// Todos los datos son inventados; el repo es público.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ulima_plus/components/seis_siete/tambaleo_seis_siete.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/chatbot_models.dart';
import 'package:ulima_plus/pages/chatbot/chatbot_controller.dart';
import 'package:ulima_plus/pages/chatbot/chatbot_page.dart';
import 'package:ulima_plus/services/chatbot_service.dart';

/// Título de la única conversación del servicio falso.
const _titulo = 'Conversación de prueba';

/// ChatbotService sin red. Devuelve una conversación con [historial] y anota
/// el nombre de cada método que se llama.
class ChatbotServiceFalso implements ChatbotService {
  ChatbotServiceFalso({this.historial = const []});

  final List<Map<String, dynamic>> historial;
  final List<String> llamadas = [];
  final List<String> preguntas = [];

  static final DateTime _fecha = DateTime.utc(2026, 9, 25, 15);
  static final ChatbotSession sesion = ChatbotSession(
    id: 'sesion-1',
    title: _titulo,
    createdAt: _fecha,
    updatedAt: _fecha,
  );

  @override
  Future<List<ChatbotSession>> listSessions() async {
    llamadas.add('listSessions');
    return [sesion];
  }

  @override
  Future<Map<String, dynamic>> getSession(String sessionId) async {
    llamadas.add('getSession');
    return {'messages': historial};
  }

  @override
  Future<ChatbotSession> createSession() async {
    llamadas.add('createSession');
    return sesion;
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    llamadas.add('deleteSession');
  }

  @override
  Future<String> ask(
    String sessionId,
    String question, {
    List<Map<String, dynamic>>? localGrades,
  }) async {
    llamadas.add('ask');
    preguntas.add(question);
    return 'Respuesta de prueba';
  }
}

/// Un mensaje del historial tal como lo devuelve el backend.
Map<String, dynamic> _delHistorial(String id, String rol, String texto) => {
  'id': id,
  'role': rol,
  'content': texto,
  'createdAt': '2026-09-25T15:00:00Z',
};

/// 3° en radianes.
const _tresGrados = 3 * math.pi / 180;

/// Ángulo en radianes del `Transform` del tambaleo.
double _angulo(WidgetTester tester) {
  final m = tester.widget<Transform>(find.byKey(claveGiroSeisSiete)).transform;
  return math.atan2(m.entry(1, 0), m.entry(0, 0));
}

/// Superficie de un iPhone SE en puntos, que ChatbotPage trata como teléfono.
const _telefono = Size(375, 667);

/// Superficie de un iPad en vertical en puntos, que ChatbotPage trata como
/// ancha.
const _iPad = Size(820, 1180);

/// Registra el controller con el servicio falso, monta ChatbotPage y espera
/// la carga. Con [superficie] la vista pasa a esa medida en puntos, con dos
/// píxeles por punto.
Future<ChatbotServiceFalso> _abrirUlises(
  WidgetTester tester, {
  List<Map<String, dynamic>> historial = const [],
  Size? superficie,
}) async {
  if (superficie != null) {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = superficie * 2;
    addTearDown(tester.view.reset);
  }
  final falso = ChatbotServiceFalso(historial: historial);
  // ChatbotPage hace Get.put(ChatbotController()), que conserva esta
  // instancia ya registrada (RF-67-5, «Inyección para pruebas»).
  Get.put(ChatbotController(service: falso));
  const tema = MaterialTheme(TextTheme());
  await tester.pumpWidget(
    GetMaterialApp(theme: tema.light(), home: const ChatbotPage()),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return falso;
}

/// Escribe [texto] y lo envía con el botón.
Future<void> _enviarConBoton(WidgetTester tester, String texto) async {
  await tester.enterText(find.byType(TextField), texto);
  await tester.tap(find.byIcon(LucideIcons.send));
  await tester.pump();
}

/// Si el `Transform` del tambaleo es ancestro de [finder].
bool _seInclina(Finder finder) => find
    .ancestor(of: finder, matching: find.byKey(claveGiroSeisSiete))
    .evaluate()
    .isNotEmpty;

/// Abre el teclado con [alto] puntos, o lo cierra con 0.
void _teclado(WidgetTester tester, double alto) {
  tester.view.viewInsets = FakeViewPadding(
    bottom: alto * tester.view.devicePixelRatio,
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(Get.reset);

  group('ChatbotController (RF-67-5)', () {
    Future<(ChatbotController, ChatbotServiceFalso)> cargado() async {
      final falso = ChatbotServiceFalso();
      final controller = ChatbotController(service: falso);
      await controller.loadSessions();
      falso.llamadas.clear();
      return (controller, falso);
    }

    test('un 67 agrega la burbuja del alumno y la de Ulises, sube el contador '
        'y no llama al servicio', () async {
      final (controller, falso) = await cargado();

      await controller.sendQuestion('¡67!');

      expect(controller.messages.map((m) => m.role), ['user', 'assistant']);
      expect(controller.messages.map((m) => m.content), [
        '¡67!',
        'SIX SEVEN!!!',
      ]);
      expect(
        controller.messages.every((m) => m.id.startsWith('local-')),
        isTrue,
      );
      expect(controller.messages.first.id, isNot(controller.messages.last.id));
      expect(controller.disparosSeisSiete.value, 1);
      expect(controller.isTyping.value, isFalse);
      expect(falso.llamadas, isEmpty);
    });

    test('cada 67 recibe su par de burbujas con ids distintos', () async {
      final (controller, _) = await cargado();

      await controller.sendQuestion('67');
      await controller.sendQuestion('six seven');

      expect(controller.messages, hasLength(4));
      expect(controller.messages.map((m) => m.id).toSet(), hasLength(4));
      expect(controller.disparosSeisSiete.value, 2);
    });

    test('un texto que no es un 67 sigue el camino de hoy', () async {
      final (controller, falso) = await cargado();

      await controller.sendQuestion('tengo 67 de nota');

      expect(falso.preguntas, ['tengo 67 de nota']);
      expect(falso.llamadas, ['ask', 'listSessions']);
      expect(controller.disparosSeisSiete.value, 0);
    });

    test('sin conversación activa un 67 no hace nada', () async {
      final controller = ChatbotController(service: ChatbotServiceFalso());

      await controller.sendQuestion('67');

      expect(controller.messages, isEmpty);
      expect(controller.disparosSeisSiete.value, 0);
    });
  });

  group('ChatbotPage (RF-67-5)', () {
    testWidgets('enviar «67» con el botón muestra las dos burbujas, sin '
        '«escribiendo…» ni avisos, inclina el panel del chat con su barra y '
        'no la lista, y no llama al servicio', (tester) async {
      final falso = await _abrirUlises(tester);
      falso.llamadas.clear();

      await _enviarConBoton(tester, '67');
      await tester.pump(const Duration(milliseconds: 125));

      expect(find.text('67'), findsOneWidget);
      expect(find.text('SIX SEVEN!!!'), findsOneWidget);
      expect(Get.find<ChatbotController>().isTyping.value, isFalse);
      expect(Get.isSnackbarOpen, isFalse);
      expect(_angulo(tester), closeTo(-_tresGrados, 1e-6));
      expect(_seInclina(find.text('ULimaBot')), isTrue);
      expect(_seInclina(find.byIcon(LucideIcons.plus)), isTrue);
      expect(_seInclina(find.byType(TextField)), isTrue);
      expect(_seInclina(find.text(_titulo)), isFalse);
      expect(_seInclina(find.byIcon(LucideIcons.arrowLeft)), isFalse);

      await tester.pump(const Duration(milliseconds: 1875));
      expect(_angulo(tester), 0);
      expect(falso.llamadas, isEmpty);
    });

    testWidgets('enviar «¡Six-Seven!» con la tecla del teclado hace lo mismo '
        'y deja el campo sin foco, como hoy (D15)', (tester) async {
      final falso = await _abrirUlises(tester);
      falso.llamadas.clear();

      await tester.enterText(find.byType(TextField), '¡Six-Seven!');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 125));

      expect(find.text('¡Six-Seven!'), findsOneWidget);
      expect(find.text('SIX SEVEN!!!'), findsOneWidget);
      expect(_angulo(tester), closeTo(-_tresGrados, 1e-6));
      final campo = tester.widget<EditableText>(find.byType(EditableText));
      expect(campo.focusNode.hasFocus, isFalse);
      expect(falso.llamadas, isEmpty);
      await tester.pump(const Duration(milliseconds: 1875));
    });

    testWidgets('enviar «tengo 67 de nota» llama a ask una vez y no inclina '
        'nada', (tester) async {
      final falso = await _abrirUlises(tester);

      await _enviarConBoton(tester, 'tengo 67 de nota');
      await tester.pump(const Duration(milliseconds: 125));

      expect(falso.preguntas, ['tengo 67 de nota']);
      expect(_angulo(tester), 0);
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('una conversación cuyo historial trae «67» no inclina nada al '
        'abrirse', (tester) async {
      await _abrirUlises(
        tester,
        historial: [
          _delHistorial('m1', 'user', '67'),
          _delHistorial('m2', 'assistant', 'Hola'),
        ],
      );

      expect(find.text('67'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 125));
      expect(_angulo(tester), 0);
    });

    testWidgets('dos «67» seguidos dan dos pares de burbujas y un solo '
        'tambaleo', (tester) async {
      await _abrirUlises(tester);

      await _enviarConBoton(tester, '67');
      await tester.pump(const Duration(milliseconds: 500));
      await _enviarConBoton(tester, '67');
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.text('SIX SEVEN!!!'), findsNWidgets(2));
      expect(find.text('67'), findsNWidgets(2));
      expect(_angulo(tester), 0);
      await tester.pump(const Duration(milliseconds: 125));
      expect(_angulo(tester), 0);
    });

    testWidgets('con el campo enfocado, enviar «67» con el botón deja el foco '
        'y el teclado durante y después del tambaleo', (tester) async {
      await _abrirUlises(tester);
      await tester.tap(find.byType(TextField));
      await tester.pump();

      await _enviarConBoton(tester, '67');
      final campo = tester.widget<EditableText>(find.byType(EditableText));
      await tester.pump(const Duration(milliseconds: 1000));
      expect(campo.focusNode.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
      await tester.pump(const Duration(milliseconds: 1000));
      expect(campo.focusNode.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
    });

    testWidgets('volver a cargar la conversación quita las dos burbujas '
        'locales', (tester) async {
      await _abrirUlises(tester);
      await _enviarConBoton(tester, '67');
      await tester.pump(const Duration(milliseconds: 2000));
      expect(find.text('SIX SEVEN!!!'), findsOneWidget);

      await Get.find<ChatbotController>().selectSession('sesion-1');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('SIX SEVEN!!!'), findsNothing);
      expect(find.text('67'), findsNothing);
    });

    testWidgets('con movimiento reducido aparecen las dos burbujas y no hay '
        'giro', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await _abrirUlises(tester);

      await _enviarConBoton(tester, '67');
      for (var ms = 0; ms < 2000; ms += 250) {
        expect(find.text('SIX SEVEN!!!'), findsOneWidget);
        expect(_angulo(tester), 0, reason: '$ms ms');
        await tester.pump(const Duration(milliseconds: 250));
      }
    });

    testWidgets('en un teléfono se inclina toda la pantalla, AppBar incluido, '
        'y volver a la lista y abrir de nuevo la conversación no inclina '
        'nada', (tester) async {
      await _abrirUlises(tester, superficie: _telefono);

      await _enviarConBoton(tester, '67');
      await tester.pump(const Duration(milliseconds: 125));
      expect(_angulo(tester), closeTo(-_tresGrados, 1e-6));
      expect(_seInclina(find.text('ULimaBot')), isTrue);
      expect(_seInclina(find.byIcon(LucideIcons.arrowLeft)), isTrue);
      await tester.pump(const Duration(milliseconds: 1875));

      await tester.tap(find.byIcon(LucideIcons.arrowLeft));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.text(_titulo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(TextField), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 125));
      expect(_angulo(tester), 0);
    });
  });

  group('ChatbotPage en pantalla ancha con el teclado (D4)', () {
    testWidgets('bajo su tramo de barra, la lista de conversaciones y el chat '
        'no ven el teclado que el Scaffold ya descuenta ni la barra de '
        'estado', (tester) async {
      await _abrirUlises(tester, superficie: _iPad);
      tester.view.padding = const FakeViewPadding(top: 48);

      _teclado(tester, 300);
      await tester.pump();

      // Encima del Scaffold el teclado sí se ve, así que la prueba no pasa
      // por falta de teclado.
      final encima = tester.element(find.byType(Scaffold));
      expect(MediaQuery.viewInsetsOf(encima).bottom, 300);
      expect(MediaQuery.paddingOf(encima).top, 24);
      for (final dentro in [find.text(_titulo), find.byType(TextField)]) {
        final contexto = tester.element(dentro);
        expect(MediaQuery.viewInsetsOf(contexto).bottom, 0);
        expect(MediaQuery.paddingOf(contexto).top, 0);
      }
    });

    testWidgets('abrir el teclado cuadro a cuadro no reconstruye lo que '
        'ChatbotPage arma sobre el Scaffold', (tester) async {
      await _abrirUlises(tester, superficie: _iPad);
      final antes = tester.widget<Scaffold>(find.byType(Scaffold));

      // Cada build del LayoutBuilder de ChatbotPage arma un Scaffold nuevo,
      // así que la misma instancia muestra que ese build no vuelve a correr.
      for (final alto in [100.0, 200.0, 300.0]) {
        _teclado(tester, alto);
        await tester.pump();
      }

      expect(tester.widget<Scaffold>(find.byType(Scaffold)), same(antes));
    });
  });
}
