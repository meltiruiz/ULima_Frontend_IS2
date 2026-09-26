// test/six_seven/chat_seccion_seis_siete_test.dart
//
// WIDGET · Truco del 67 en los chats de sección
// (specs/features/six-seven/six-seven.spec.md, RF-67-6 y RF-67-7) y el
// stream creado una sola vez por página (RF-CHAT-2 de
// specs/features/chat/chat.spec.md). Monta ChatPage con ChatRepoFalso y le
// empuja listas en vivo por un StreamController que no es broadcast, como
// el stream de Firebase.
//
// Todos los datos son inventados; el repo es público. Los remitentes usan
// los ids ficticios de las series 5xx y 6xx de las pruebas de HU23, y el
// alumno sintético 20230001.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/seis_siete/tambaleo_seis_siete.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/message.dart';
import 'package:ulima_plus/pages/chat/chat_page.dart';
import 'package:ulima_plus/services/chat_repository.dart';

import '../HU23_jeff/chat_repo_falso.dart';

/// Un mensaje de texto armado como los que llegan de Firebase. El `id` hace
/// de milisegundos, así que los ids crecientes quedan en orden.
ChatMessage _msg(String id, String senderId, String cuerpo) =>
    ChatMessage.fromMap(id, {
      'senderId': senderId,
      'senderName': senderId == '601' ? 'Docente De Prueba' : 'Alumno X',
      'senderRole': senderId == '601' ? 'teacher' : 'student',
      'body': cuerpo,
      'createdAt': int.parse(id),
    });

/// ChatPage dentro de un padre que se reconstruye cada vez que [pulso] sube.
Widget _chatReconstruible(ChatRepoFalso repo, ValueNotifier<int> pulso) {
  const tema = MaterialTheme(TextTheme());
  return GetMaterialApp(
    theme: tema.light(),
    home: ValueListenableBuilder<int>(
      valueListenable: pulso,
      builder: (context, _, _) => ChatPage(
        sectionId: '1',
        courseName: 'CURSO DE PRUEBA A',
        repository: repo,
      ),
    ),
  );
}

/// Monta [app] y deja que el token resuelva, así la página crea su stream.
Future<void> _abrir(WidgetTester tester, Widget app) async {
  await tester.pumpWidget(app);
  await tester.pump();
}

/// Empuja [lista] por el stream y dibuja el cuadro en que llega.
Future<void> _entregar(
  WidgetTester tester,
  StreamController<List<ChatMessage>> vivo,
  List<ChatMessage> lista,
) async {
  vivo.add(lista);
  await tester.pump(Duration.zero);
}

/// 3° en radianes.
const _tresGrados = 3 * math.pi / 180;

/// Ángulo en radianes del `Transform` del tambaleo.
double _angulo(WidgetTester tester) {
  final m = tester.widget<Transform>(find.byKey(claveGiroSeisSiete)).transform;
  return math.atan2(m.entry(1, 0), m.entry(0, 0));
}

/// Abre el chat de [sesion] con un stream en vivo y le entrega [historial]
/// como primera lista. Devuelve el stream y el repositorio falso.
Future<(StreamController<List<ChatMessage>>, ChatRepoFalso)> _abrirEnVivo(
  WidgetTester tester, {
  ChatSession sesion = sesionAlumno,
  List<ChatMessage> historial = const [],
}) async {
  final vivo = StreamController<List<ChatMessage>>();
  final repo = ChatRepoFalso(session: sesion, enVivo: vivo);
  await _abrir(tester, chatEnApp(repo, courseName: 'CURSO DE PRUEBA A'));
  await _entregar(tester, vivo, historial);
  await tester.pumpAndSettle();
  return (vivo, repo);
}

final _rotulo = find.text('SIX SEVEN!!!');

/// El `Scrollable` de la lista de mensajes (el campo de texto tiene otro).
final _scrollDeLaLista = find
    .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
    .first;

/// Lleva la app a segundo plano con las transiciones que acepta Flutter.
void _aSegundoPlano(WidgetTester tester) {
  for (final estado in [
    AppLifecycleState.resumed,
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(estado);
  }
}

/// Devuelve la app al primer plano con las transiciones que acepta Flutter.
void _aPrimerPlano(WidgetTester tester) {
  for (final estado in [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(estado);
  }
}

void main() {
  tearDown(Get.reset);

  group('un solo stream por página (RF-CHAT-2 y RF-67-6)', () {
    testWidgets('reconstruir ChatPage desde su padre no vuelve a pedir el '
        'stream, no muestra la carga y conserva la lista', (tester) async {
      final vivo = StreamController<List<ChatMessage>>();
      final repo = ChatRepoFalso(session: sesionAlumno, enVivo: vivo);
      final pulso = ValueNotifier<int>(0);
      addTearDown(pulso.dispose);

      await _abrir(tester, _chatReconstruible(repo, pulso));
      await _entregar(tester, vivo, [_msg('100', '502', 'Hola')]);
      expect(find.text('Hola'), findsOneWidget);

      pulso.value++;
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(repo.llamadasAGetMessages, 1);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Hola'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('los mensajes que llegan después de reconstruir se siguen '
        'viendo', (tester) async {
      final vivo = StreamController<List<ChatMessage>>();
      final repo = ChatRepoFalso(session: sesionAlumno, enVivo: vivo);
      final pulso = ValueNotifier<int>(0);
      addTearDown(pulso.dispose);

      await _abrir(tester, _chatReconstruible(repo, pulso));
      await _entregar(tester, vivo, [_msg('100', '502', 'Hola')]);
      pulso.value++;
      await tester.pump();
      await _entregar(tester, vivo, [
        _msg('100', '502', 'Hola'),
        _msg('200', '503', 'Buenas'),
      ]);

      expect(find.text('Buenas'), findsOneWidget);
      expect(repo.llamadasAGetMessages, 1);
      await tester.pumpAndSettle();
    });
  });

  group('el truco del 67 (RF-67-6 y RF-67-7)', () {
    final hola = _msg('100', '502', 'Hola');

    testWidgets('un historial con «67» no inclina ni muestra el rótulo', (
      tester,
    ) async {
      await _abrirEnVivo(tester, historial: [hola, _msg('200', '503', '67')]);

      await tester.pump(const Duration(milliseconds: 125));
      expect(_angulo(tester), 0);
      expect(_rotulo, findsNothing);
    });

    testWidgets('un «67» ajeno en vivo inclina toda la pantalla, AppBar '
        'incluido, y muestra el rótulo, que a los 2000 ms ya no está', (
      tester,
    ) async {
      final (vivo, _) = await _abrirEnVivo(tester, historial: [hola]);

      await _entregar(tester, vivo, [hola, _msg('200', '503', '67')]);
      await tester.pump(const Duration(milliseconds: 125));

      expect(_angulo(tester), closeTo(-_tresGrados, 1e-6));
      expect(
        find.ancestor(
          of: find.text('CURSO DE PRUEBA A'),
          matching: find.byKey(claveGiroSeisSiete),
        ),
        findsOneWidget,
      );
      expect(_rotulo, findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1875));
      expect(_angulo(tester), 0);
      expect(_rotulo, findsNothing);
      await tester.pumpAndSettle();
    });

    testWidgets('con la sesión del docente, un «67» ajeno en vivo también '
        'inclina y muestra el rótulo (D9)', (tester) async {
      final (vivo, _) = await _abrirEnVivo(
        tester,
        sesion: sesionDocente,
        historial: [hola],
      );

      await _entregar(tester, vivo, [hola, _msg('200', '503', '67')]);
      await tester.pump(const Duration(milliseconds: 125));

      expect(_angulo(tester), closeTo(-_tresGrados, 1e-6));
      expect(_rotulo, findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('si el autor borra su «67» a los 500 ms, el tambaleo y el '
        'rótulo siguen hasta los 2000 ms y no empieza otro', (tester) async {
      final (vivo, _) = await _abrirEnVivo(tester, historial: [hola]);
      final seisSiete = _msg('200', '503', '67');

      await _entregar(tester, vivo, [hola, seisSiete]);
      await tester.pump(const Duration(milliseconds: 500));
      final lapida = ChatMessage.fromMap('200', {
        ...seisSiete.toMap(),
        'deleted': true,
        'deletedBy': 'Alumno X',
        'deletedByUid': '503',
      });
      await _entregar(tester, vivo, [hola, lapida]);

      await tester.pump(const Duration(milliseconds: 1499));
      expect(_rotulo, findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1));
      expect(_rotulo, findsNothing);
      await tester.pump(const Duration(milliseconds: 125));
      expect(_angulo(tester), 0);
      await tester.pumpAndSettle();
    });

    testWidgets('enviar «67» lo entrega como mensaje normal, y cuando el '
        'stream lo trae como propio el chat se inclina', (tester) async {
      final (vivo, repo) = await _abrirEnVivo(tester, historial: [hola]);

      await tester.enterText(find.byType(TextField), '67');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();
      expect(repo.sent, ['67']);

      await _entregar(tester, vivo, [
        hola,
        _msg('200', sesionAlumno.uid, '67'),
      ]);
      await tester.pump(const Duration(milliseconds: 125));
      expect(_angulo(tester), closeTo(-_tresGrados, 1e-6));
      await tester.pumpAndSettle();
    });

    testWidgets('una lápida nueva con «67», un carnet nuevo y un «tengo 67 de '
        'nota» nuevo no disparan', (tester) async {
      final (vivo, _) = await _abrirEnVivo(tester, historial: [hola]);
      final lapida = ChatMessage.fromMap('200', {
        'senderId': '503',
        'senderName': 'Alumno X',
        'body': '67',
        'createdAt': 200,
        'deleted': true,
        'deletedBy': 'Alumno X',
        'deletedByUid': '503',
      });
      final carnet = ChatMessage.fromMap('300', {
        'senderId': '504',
        'senderName': 'Alumno X',
        'body': '67',
        'createdAt': 300,
        'messageType': 'networking_card',
      });

      await _entregar(tester, vivo, [
        hola,
        lapida,
        carnet,
        _msg('400', '505', 'tengo 67 de nota'),
      ]);
      await tester.pump(const Duration(milliseconds: 125));
      expect(_angulo(tester), 0);
      expect(_rotulo, findsNothing);
      await tester.pumpAndSettle();
    });

    testWidgets('reconstruir ChatPage desde su padre con un «67» en el '
        'historial no dispara', (tester) async {
      final vivo = StreamController<List<ChatMessage>>();
      final repo = ChatRepoFalso(session: sesionAlumno, enVivo: vivo);
      final pulso = ValueNotifier<int>(0);
      addTearDown(pulso.dispose);

      await _abrir(tester, _chatReconstruible(repo, pulso));
      await _entregar(tester, vivo, [hola, _msg('200', '503', '67')]);
      pulso.value++;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 125));

      expect(_angulo(tester), 0);
      expect(_rotulo, findsNothing);
      await tester.pumpAndSettle();
    });

    testWidgets('dos 67 nuevos en un mismo evento dan un tambaleo, y otro 67 '
        'durante ese tambaleo no lo reinicia', (tester) async {
      final (vivo, _) = await _abrirEnVivo(tester, historial: [hola]);
      final dos = [hola, _msg('200', '503', '67'), _msg('300', '504', '6 7')];

      await _entregar(tester, vivo, dos);
      await tester.pump(const Duration(milliseconds: 500));
      await _entregar(tester, vivo, [...dos, _msg('400', '505', 'six seven')]);
      await tester.pump(const Duration(milliseconds: 1500));

      expect(_angulo(tester), 0);
      expect(_rotulo, findsNothing);
      await tester.pump(const Duration(milliseconds: 125));
      expect(_angulo(tester), 0);
      await tester.pumpAndSettle();
    });

    testWidgets('durante el tambaleo el scroll no cambia y el StreamBuilder '
        'no se reconstruye', (tester) async {
      final historial = [
        for (var i = 1; i <= 30; i++) _msg('${i * 100}', '502', 'Mensaje $i'),
      ];
      final (vivo, _) = await _abrirEnVivo(tester, historial: historial);

      // Un 67 en vivo programa el desplazamiento al último mensaje
      // (_scrollToBottom, 100 ms de espera y 250 ms de animación).
      await _entregar(tester, vivo, [...historial, _msg('3100', '503', '67')]);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));

      final lista = tester.widget<ListView>(find.byType(ListView));
      final posicion = tester.state<ScrollableState>(_scrollDeLaLista).position;
      final pixeles = posicion.pixels;
      var volvioADesplazarse = false;
      void alDesplazarse() {
        if (posicion.isScrollingNotifier.value) volvioADesplazarse = true;
      }

      posicion.isScrollingNotifier.addListener(alDesplazarse);
      addTearDown(
        () => posicion.isScrollingNotifier.removeListener(alDesplazarse),
      );

      for (var ms = 400; ms < 2000; ms += 100) {
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.widget<ListView>(find.byType(ListView)), same(lista));
        expect(
          tester.state<ScrollableState>(_scrollDeLaLista).position,
          same(posicion),
        );
        expect(posicion.pixels, pixeles, reason: '${ms + 100} ms');
      }
      expect(volvioADesplazarse, isFalse);
      expect(_rotulo, findsNothing);
    });

    testWidgets('con el campo enfocado, el foco y el teclado siguen igual '
        'después del tambaleo', (tester) async {
      final (vivo, _) = await _abrirEnVivo(tester, historial: [hola]);
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(tester.testTextInput.isVisible, isTrue);

      await _entregar(tester, vivo, [hola, _msg('200', '503', '67')]);
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 1000));

      final campo = tester.widget<EditableText>(find.byType(EditableText));
      expect(campo.focusNode.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
      await tester.pumpAndSettle();
    });

    testWidgets('con movimiento reducido aparece el rótulo sin giro', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final (vivo, _) = await _abrirEnVivo(tester, historial: [hola]);

      await _entregar(tester, vivo, [hola, _msg('200', '503', '67')]);
      for (var ms = 0; ms < 2000; ms += 250) {
        expect(_rotulo, findsOneWidget, reason: '$ms ms');
        expect(_angulo(tester), 0, reason: '$ms ms');
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(_rotulo, findsNothing);
      await tester.pumpAndSettle();
    });

    testWidgets('con la app en paused un 67 en vivo no dispara, y al volver '
        'a resumed no aparece nada', (tester) async {
      final (vivo, _) = await _abrirEnVivo(tester, historial: [hola]);

      _aSegundoPlano(tester);
      await _entregar(tester, vivo, [hola, _msg('200', '503', '67')]);
      _aPrimerPlano(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 125));

      expect(find.text('67'), findsOneWidget);
      expect(_angulo(tester), 0);
      expect(_rotulo, findsNothing);
      await tester.pumpAndSettle();
    });

    testWidgets('de vuelta en resumed después de paused, un 67 que llega '
        'recién entonces dispara (D10)', (tester) async {
      final (vivo, _) = await _abrirEnVivo(tester, historial: [hola]);

      _aSegundoPlano(tester);
      _aPrimerPlano(tester);
      await tester.pump();
      await _entregar(tester, vivo, [hola, _msg('200', '503', '67')]);
      await tester.pump(const Duration(milliseconds: 125));

      expect(_angulo(tester), closeTo(-_tresGrados, 1e-6));
      expect(_rotulo, findsOneWidget);
      await tester.pumpAndSettle();
    });
  });
}
