import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../domain/seis_siete/seis_siete.dart';
import '../../models/chatbot_models.dart';
import '../../services/chatbot_service.dart';
import '../../services/notas_service.dart';

class ChatbotController extends GetxController {
  /// [service] se inyecta en las pruebas, como el repositorio de `ChatPage`.
  /// Sin él usa el servicio real, así que `ChatbotPage` no cambia (RF-67-5).
  ChatbotController({ChatbotService? service})
    : _service = service ?? ChatbotService();

  final ChatbotService _service;
  final NotasService _notasService = NotasService();

  final RxList<ChatbotSession> sessions = <ChatbotSession>[].obs;
  final RxList<ChatbotMessage> messages = <ChatbotMessage>[].obs;

  final Rx<String?> activeSessionId = Rx<String?>(null);
  final RxBool loadingSessions = false.obs;
  final RxBool loadingMessages = false.obs;
  final RxBool sendingQuestion = false.obs;

  final RxBool isTyping = false.obs;

  /// Contador de disparos del truco del 67. Solo sube, y lo lee el
  /// `TambaleoSeisSiete` de `ChatbotPage` (RF-67-5).
  final RxInt disparosSeisSiete = 0.obs;

  /// Cuenta las burbujas locales del 67 para que cada una tenga su id.
  int _burbujasSeisSiete = 0;

  @override
  void onInit() {
    super.onInit();
    loadSessions();
  }

  Future<void> loadSessions() async {
    loadingSessions.value = true;
    try {
      final result = await _service.listSessions();
      sessions.assignAll(result);
      if (result.isNotEmpty && activeSessionId.value == null) {
        activeSessionId.value = result.first.id;
        await loadMessages(result.first.id);
      }
    } catch (e) {
      debugPrint('Error loading sessions: $e');
    } finally {
      loadingSessions.value = false;
    }
  }

  Future<void> loadMessages(String sessionId) async {
    loadingMessages.value = true;
    try {
      final data = await _service.getSession(sessionId);
      final List<dynamic> msgsRaw = data['messages'] ?? [];
      final List<ChatbotMessage> msgs = msgsRaw
          .map(
            (item) =>
                ChatbotMessage.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
      messages.assignAll(msgs);
    } catch (e) {
      debugPrint('Error loading messages: $e');
    } finally {
      loadingMessages.value = false;
    }
  }

  Future<void> selectSession(String sessionId) async {
    activeSessionId.value = sessionId;
    await loadMessages(sessionId);
  }

  Future<void> createSession() async {
    try {
      final session = await _service.createSession();
      sessions.insert(0, session);
      activeSessionId.value = session.id;
      messages.clear();
    } catch (e) {
      debugPrint('Error creating session: $e');
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      await _service.deleteSession(sessionId);
      sessions.removeWhere((s) => s.id == sessionId);
      if (activeSessionId.value == sessionId) {
        if (sessions.isNotEmpty) {
          await selectSession(sessions.first.id);
        } else {
          activeSessionId.value = null;
          messages.clear();
        }
      }
    } catch (e) {
      debugPrint('Error deleting session: $e');
    }
  }

  Future<void> sendQuestion(String question) async {
    final sessionId = activeSessionId.value;
    if (sessionId == null || question.trim().isEmpty) return;

    // Un 67 no llega al backend ni gasta el límite de preguntas (RF-67-5).
    if (esSeisSiete(question)) {
      _responderSeisSiete(question);
      return;
    }

    // Optimista: el mensaje del usuario aparece de INMEDIATO (antes se agregaba
    // recién al llegar la respuesta, así que desaparecía mientras el bot pensaba).
    final now = DateTime.now();
    messages.add(
      ChatbotMessage(
        id: now.millisecondsSinceEpoch.toString(),
        role: 'user',
        content: question,
        createdAt: now,
      ),
    );
    isTyping.value = true;

    try {
      final localGrades = await _loadLocalGrades();
      final answer = await _service.ask(
        sessionId,
        question,
        localGrades: localGrades,
      );

      messages.add(
        ChatbotMessage(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          role: 'assistant',
          content: answer,
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint('Error sending question: $e');
      final msg = _extractErrorMessage(e);
      Get.snackbar('Error', msg, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isTyping.value = false;
    }

    // Refresco SILENCIOSO de la lista de sesiones (el backend autogenera el
    // título con la 1ª pregunta y actualiza `updatedAt`). NO usamos loadSessions()
    // aquí porque pone loadingSessions=true → el Obx de _buildBody reemplaza toda
    // la pantalla por un spinner y reinicia el área de chat (scroll + input). Este
    // sync no toca loadingSessions ni activeSessionId, así que solo se actualiza
    // la barra de conversaciones y los mensajes se quedan quietos abajo.
    await _syncSessionsQuietly();
  }

  /// Agrega en el mismo instante la burbuja del alumno y la de Ulises con
  /// «SIX SEVEN!!!», las dos solo en memoria, y sube el contador del
  /// tambaleo. No enciende «escribiendo…» ni llama a ningún endpoint.
  void _responderSeisSiete(String pregunta) {
    final ahora = DateTime.now();
    messages.addAll([
      ChatbotMessage(
        id: 'local-seis-siete-${_burbujasSeisSiete++}',
        role: 'user',
        content: pregunta,
        createdAt: ahora,
      ),
      ChatbotMessage(
        id: 'local-seis-siete-${_burbujasSeisSiete++}',
        role: 'assistant',
        content: textoSeisSiete,
        createdAt: ahora,
      ),
    ]);
    disparosSeisSiete.value++;
  }

  /// Actualiza la lista de sesiones en segundo plano sin flags de carga, para no
  /// re-renderizar la pantalla del chat mientras se conversa.
  Future<void> _syncSessionsQuietly() async {
    try {
      final result = await _service.listSessions();
      sessions.assignAll(result);
    } catch (e) {
      debugPrint('Error syncing sessions: $e');
    }
  }

  Future<List<Map<String, dynamic>>?> _loadLocalGrades() async {
    try {
      final studentId = await _notasService.obtenerIdEstudianteActual();
      if (studentId == null) return null;
      final notas = await _notasService.cargarNotas(studentId);
      if (notas.isEmpty) return null;

      return notas.map((curso) {
        return {
          'id': curso['id']?.toString() ?? '',
          'nombre': curso['nombre']?.toString() ?? '',
          'notas':
              (curso['notas'] as List?)?.map((nota) {
                return {
                  'titulo': nota['titulo']?.toString() ?? '',
                  'peso': (nota['peso'] is int)
                      ? nota['peso']
                      : int.tryParse(nota['peso']?.toString() ?? '0') ?? 0,
                  'valor': (nota['valor'] is double)
                      ? nota['valor']
                      : double.tryParse(nota['valor']?.toString() ?? '0') ??
                            0.0,
                };
              }).toList() ??
              [],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error loading local grades: $e');
      return null;
    }
  }

  String _extractErrorMessage(dynamic e) {
    if (e is Map && e.containsKey('error')) {
      return e['error']?['message']?.toString() ??
          'No se pudo obtener respuesta. Intenta de nuevo.';
    }
    return 'No se pudo obtener respuesta. Intenta de nuevo.';
  }
}
