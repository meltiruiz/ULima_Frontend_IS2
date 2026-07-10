import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/message.dart';
import 'api_client.dart';

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
}

class ChatRepository implements ChatRepositoryContract {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final ApiClient _apiClient = ApiClient();

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
}
