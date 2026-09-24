// test/HU23_jeff/chat_repo_falso.dart
//
// Apoyo de las pruebas de widget de ChatPage (HU23), sin pruebas propias.
// El repositorio de chat falso implementa ChatRepositoryContract sin
// FlutterFire, controla la sesión, los errores y los mensajes, y guarda lo que
// ChatPage envía o borra. Lo comparten chat_page_test, chat_identidad_test y
// chat_moderacion_test.
//
// Todos los datos son inventados; el repo es público.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/message.dart';
import 'package:ulima_plus/models/networking_model.dart';
import 'package:ulima_plus/pages/chat/chat_page.dart';
import 'package:ulima_plus/services/chat_repository.dart';

class ChatRepoFalso implements ChatRepositoryContract {
  ChatRepoFalso({
    this.session,
    this.error,
    this.messages = const [],
    this.streamError,
    this.sendError,
    this.fetchCardError,
    this.deleteError,
  });

  /// Sesión que devuelve el token; con [error] el token falla.
  final ChatSession? session;
  final Object? error;
  final List<ChatMessage> messages;

  /// Si no es nulo, el stream de mensajes falla con este error.
  final Object? streamError;

  /// Si no es nulo, enviar un mensaje falla con este error.
  final Object? sendError;

  /// Si no es nulo, pedir un carnet falla con este error.
  final Object? fetchCardError;

  /// Si no es nulo, borrar un mensaje falla con este error.
  final Object? deleteError;

  final List<String> sent = [];
  final List<String> sentNetworking = [];
  final List<String> deleted = [];

  @override
  Future<ChatSession> signInWithCustomToken(String sectionId) async {
    if (error != null) throw error!;
    return session!;
  }

  @override
  Stream<List<ChatMessage>> getMessages(String sectionId) =>
      streamError != null ? Stream.error(streamError!) : Stream.value(messages);

  @override
  Future<void> sendMessage(String sectionId, String text, ChatSession s) async {
    if (sendError != null) throw sendError!;
    sent.add(text);
  }

  @override
  Future<void> sendNetworkingCard(String sectionId, ChatSession session) async {
    sentNetworking.add(sectionId);
  }

  @override
  Future<PublicNetworkingCardDto> fetchNetworkingCard(int userId) async {
    if (fetchCardError != null) throw fetchCardError!;
    return carnetPublico(userId);
  }

  @override
  Future<void> deleteMessage(String sectionId, String messageId) async {
    if (deleteError != null) throw deleteError!;
    deleted.add(messageId);
  }
}

/// Un carnet visible e inventado.
PublicNetworkingCardDto carnetPublico(int userId) => PublicNetworkingCardDto(
  owner: NetworkingOwnerDto(
    userId: userId,
    fullName: 'Alumno X',
    primaryDetail: 'Ingenieria de Sistemas',
    secondaryDetail: '$userId - Alumno',
    roleLabel: 'Alumno',
  ),
  card: const NetworkingCardDto(
    optIn: true,
    links: [
      SocialLinkDto(platform: 'github', url: 'https://github.com/alumno'),
    ],
  ),
);

/// Sesión del profesor de la sección.
const sesionDocente = ChatSession(
  uid: '601',
  displayName: 'Docente De Prueba',
  role: 'teacher',
  roleLabel: 'Profesor',
  isModerator: true,
  weight: 100,
);

/// Sesión del Jefe de Práctica de la sección: moderador que solo borra sus
/// propios mensajes (RF-CHAT-4).
const sesionJp = ChatSession(
  uid: '602',
  displayName: 'Jefe De Prueba',
  role: 'jp',
  roleLabel: 'Jefe de Práctica',
  isModerator: true,
  weight: 90,
);

/// Sesión del delegado de la sección, un alumno sintético.
const sesionDelegado = ChatSession(
  uid: '20230001',
  displayName: 'Alumno De Prueba',
  role: 'delegate',
  roleLabel: 'Delegado',
  isModerator: true,
  weight: 70,
);

/// Sesión del subdelegado de la sección, el mismo alumno sintético.
const sesionSubdelegado = ChatSession(
  uid: '20230001',
  displayName: 'Alumno De Prueba',
  role: 'subdelegate',
  roleLabel: 'Subdelegado',
  isModerator: true,
  weight: 60,
);

/// Sesión de un alumno de la sección, el mismo alumno sintético, sin
/// representación.
const sesionAlumno = ChatSession(
  uid: '20230001',
  displayName: 'Alumno De Prueba',
  role: 'student',
  roleLabel: 'Alumno',
  isModerator: false,
  weight: 10,
);

/// ChatPage dentro de una app de GetX con el tema real de la app, claro u
/// oscuro según [brillo].
Widget chatEnApp(
  ChatRepoFalso repo, {
  Brightness brillo = Brightness.light,
  String sectionId = '1',
  String courseName = 'INGENIERÍA DE SOFTWARE II',
  String? sectionCode,
  Color? courseColor,
}) {
  const tema = MaterialTheme(TextTheme());
  return GetMaterialApp(
    theme: brillo == Brightness.light ? tema.light() : tema.dark(),
    home: ChatPage(
      sectionId: sectionId,
      courseName: courseName,
      sectionCode: sectionCode,
      courseColor: courseColor,
      repository: repo,
    ),
  );
}
