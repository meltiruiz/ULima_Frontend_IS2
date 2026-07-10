import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/message.dart';
import 'package:ulima_plus/pages/chat/chat_page.dart';
import 'package:ulima_plus/services/chat_repository.dart';

/// Repo de chat falso: sin FlutterFire, controla sesión/error/mensajes y
/// captura lo enviado. Inyectado en `ChatPage` vía `ChatRepositoryContract`.
class _FakeChatRepo implements ChatRepositoryContract {
  _FakeChatRepo({this.session, this.error, this.messages = const []});

  final ChatSession? session;
  final Object? error;
  final List<ChatMessage> messages;
  final List<String> sent = [];

  @override
  Future<ChatSession> signInWithCustomToken(String sectionId) async {
    if (error != null) throw error!;
    return session!;
  }

  @override
  Stream<List<ChatMessage>> getMessages(String sectionId) =>
      Stream.value(messages);

  @override
  Future<void> sendMessage(String sectionId, String text, ChatSession s) async {
    sent.add(text);
  }
}

const _teacher = ChatSession(
  uid: '292',
  displayName: 'Quintana Cruz, Hernan',
  role: 'teacher',
  roleLabel: 'Profesor',
  isModerator: true,
  weight: 100,
);

ChatMessage _msg(String id, String senderId, String body, {String role = 'student'}) =>
    ChatMessage.fromMap(id, {
      'senderId': senderId,
      'senderName': senderId == '292' ? 'Quintana Cruz, Hernan' : 'Alumno X',
      'senderRole': role,
      'body': body,
      'createdAt': int.parse(id),
    });

Widget _wrap(_FakeChatRepo repo) => GetMaterialApp(
      home: ChatPage(
        sectionId: '1',
        courseName: 'INGENIERÍA DE SOFTWARE II',
        repository: repo,
      ),
    );

void main() {
  // GetX usa estado global (snackbars/controllers); se resetea entre tests
  // para aislarlos y no arrastrar tickers de un snackbar al siguiente.
  tearDown(Get.reset);

  testWidgets('muestra spinner mientras conecta y luego los mensajes', (tester) async {
    final repo = _FakeChatRepo(
      session: _teacher,
      messages: [
        _msg('100', '6', 'Hola profe!'),
        _msg('200', '292', 'Buen día alumnos', role: 'teacher'),
      ],
    );
    await tester.pumpWidget(_wrap(repo));

    // Primer frame: aún cargando el token.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Hola profe!'), findsOneWidget);
    expect(find.text('Buen día alumnos'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('error al conectar → placeholder "chat no disponible"', (tester) async {
    final repo = _FakeChatRepo(error: Exception('403'));
    await tester.pumpWidget(_wrap(repo));
    await tester.pump(); // resuelve el future con error
    await tester.pump(const Duration(milliseconds: 300));

    // Texto exacto del placeholder (con punto); el snackbar de GetX usa otro
    // sin punto, por eso no se filtra con textContaining.
    expect(find.text('No se pudo conectar al chat.'), findsOneWidget);
    expect(
      find.textContaining('Solo los miembros de esta sección'),
      findsOneWidget,
    );
    // No se renderiza la caja de input cuando no hay sesión.
    expect(find.byType(TextField), findsNothing);

    // Cierra el snackbar para no dejar un Ticker activo al finalizar el test.
    Get.closeAllSnackbars();
    await tester.pumpAndSettle();
  });

  testWidgets('sesión sin mensajes → aviso de grupo protegido', (tester) async {
    final repo = _FakeChatRepo(session: _teacher, messages: const []);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    expect(find.textContaining('protegidos'), findsOneWidget);
    // Con sesión válida sí hay caja de input.
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('enviar mensaje → el repo lo recibe y el campo se limpia', (tester) async {
    final repo = _FakeChatRepo(session: _teacher, messages: const []);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Hola equipo');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    expect(repo.sent, ['Hola equipo']);
    expect(find.text('Hola equipo'), findsNothing); // campo limpiado
  });

  testWidgets('no envía mensajes vacíos', (tester) async {
    final repo = _FakeChatRepo(session: _teacher, messages: const []);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    expect(repo.sent, isEmpty);
  });

  testWidgets('un mensaje de moderador muestra su etiqueta de rol', (tester) async {
    final repo = _FakeChatRepo(
      session: _teacher,
      messages: [_msg('100', '292', 'Bienvenidos', role: 'teacher')],
    );
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    // La burbuja del profesor muestra el badge "Profesor".
    expect(find.text('Profesor'), findsOneWidget);
  });
}
