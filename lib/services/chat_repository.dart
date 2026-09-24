import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/message.dart';
import '../models/networking_model.dart';
import 'api_client.dart';
import 'networking_service.dart';

class ChatSession {
  const ChatSession({
    required this.uid,
    required this.displayName,
    required this.role,
    required this.roleLabel,
    required this.isModerator,
    required this.weight,
  });

  final String uid;
  final String displayName;
  final String role;
  final String roleLabel;
  final bool isModerator;
  final int weight;

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      uid: json['uid']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? 'Participante',
      role: json['role']?.toString() ?? 'student',
      roleLabel: json['roleLabel']?.toString() ?? 'Alumno',
      isModerator: json['isModerator'] == true,
      weight: _parseInt(json['weight']) ?? 10,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

/// Contrato del repositorio de chat que consume `ChatPage`. Permite inyectar
/// una implementación falsa en tests sin tocar FlutterFire.
abstract class ChatRepositoryContract {
  Future<ChatSession> signInWithCustomToken(String sectionId);
  Stream<List<ChatMessage>> getMessages(String sectionId);
  Future<void> sendMessage(String sectionId, String text, ChatSession session);
  Future<void> sendNetworkingCard(String sectionId, ChatSession session);
  Future<PublicNetworkingCardDto> fetchNetworkingCard(int userId);

  /// HU23: elimina (borrado suave) un mensaje. Va por el backend, que escribe la
  /// lápida con Admin SDK; las reglas RTDB no permiten borrar desde el cliente.
  /// Autorización real (R-CHAT-4 del backend): cada participante borra sus
  /// propios mensajes y el profesor titular, cualquiera. Un mensaje ajeno sin
  /// ese permiso responde 403 `CHAT_DELETE_FORBIDDEN`.
  Future<void> deleteMessage(String sectionId, String messageId);
}

class ChatRepository implements ChatRepositoryContract {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final ApiClient _apiClient = ApiClient();
  final NetworkingService _networkingService = NetworkingService();

  @override
  Future<ChatSession> signInWithCustomToken(String sectionId) async {
    try {
      final response = await _apiClient.postJson(
        '/chat/token',
        body: {'sectionId': sectionId},
      );

      final firebaseToken = response['token']?.toString();
      final session = ChatSession.fromJson(response);
      if (firebaseToken == null ||
          firebaseToken.isEmpty ||
          session.uid.isEmpty) {
        throw Exception("Failed to get custom token from response.");
      }

      if (_auth.currentUser?.uid != session.uid) {
        await _auth.signOut();
        await _auth.signInWithCustomToken(firebaseToken);
      }

      return session;
    } catch (e) {
      debugPrint("Error signing in to Firebase: $e");
      rethrow;
    }
  }

  @override
  Stream<List<ChatMessage>> getMessages(String sectionId) {
    return _database
        .ref('sections/$sectionId/messages')
        .orderByKey()
        .limitToLast(80)
        .onValue
        .map((event) {
          final data = event.snapshot.value as Map<dynamic, dynamic>?;
          if (data == null) return [];

          final messages = data.entries.map((e) {
            return ChatMessage.fromMap(
              e.key.toString(),
              e.value as Map<dynamic, dynamic>,
            );
          }).toList();

          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return messages;
        });
  }

  @override
  Future<void> sendMessage(
    String sectionId,
    String text,
    ChatSession session,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.uid != session.uid) {
        throw Exception("No authenticated Firebase chat user.");
      }

      final ref = _database.ref('sections/$sectionId/messages').push();
      await ref.set({
        'senderId': user.uid,
        'senderName': session.displayName,
        'senderRole': session.role,
        'senderRoleLabel': session.roleLabel,
        'moderator': session.isModerator,
        'weight': session.weight,
        'body': text,
        'createdAt': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint("Error sending message: $e");
      rethrow;
    }
  }

  @override
  Future<void> sendNetworkingCard(String sectionId, ChatSession session) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.uid != session.uid) {
        throw Exception("No authenticated Firebase chat user.");
      }

      final ownerId = int.tryParse(session.uid);
      if (ownerId == null) {
        throw Exception("Invalid networking owner.");
      }

      final ref = _database.ref('sections/$sectionId/messages').push();
      await ref.set({
        'senderId': user.uid,
        'senderName': session.displayName,
        'senderRole': session.role,
        'senderRoleLabel': session.roleLabel,
        'moderator': session.isModerator,
        'weight': session.weight,
        'body': '${ChatMessage.networkingBodyPrefix}$ownerId',
        'createdAt': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint("Error sending networking card: $e");
      rethrow;
    }
  }

  @override
  Future<PublicNetworkingCardDto> fetchNetworkingCard(int userId) {
    return _networkingService.fetchVisibleByUserId(userId);
  }

  @override
  Future<void> deleteMessage(String sectionId, String messageId) async {
    // El borrado lo hace el backend (verifica la autoría o que sea el profesor
    // titular y escribe la lápida con Admin SDK). El stream de RTDB refleja el
    // cambio.
    await _apiClient.deleteJson(
      '/chat/sections/$sectionId/messages/$messageId',
    );
  }
}
