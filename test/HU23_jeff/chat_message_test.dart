import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/models/message.dart';

void main() {
  test('parsea mensajes nuevos con nombre completo y rol moderador', () {
    final message = ChatMessage.fromMap('m1', {
      'senderId': '603',
      'senderName': 'Docente De Prueba',
      'senderRole': 'teacher',
      'senderRoleLabel': 'Profesor',
      'moderator': true,
      'weight': 100,
      'body': 'Bienvenidos al chat',
      'createdAt': 1783573983742,
    });

    expect(message.senderName, 'Docente De Prueba');
    expect(message.senderRole, 'teacher');
    expect(message.senderRoleLabel, 'Profesor');
    expect(message.isModerator, isTrue);
    expect(message.weight, 100);
    expect(message.text, 'Bienvenidos al chat');
  });

  test('mantiene compatibilidad con mensajes antiguos text/timestamp', () {
    final message = ChatMessage.fromMap('m2', {
      'senderId': '0',
      'senderName': 'Alumno',
      'text': 'Mensaje antiguo',
      'timestamp': 1783573983742,
    });

    expect(message.senderName, 'Alumno');
    expect(message.senderRole, 'student');
    expect(message.senderRoleLabel, 'Alumno');
    expect(message.isModerator, isFalse);
    expect(message.text, 'Mensaje antiguo');
  });

  test('parsea mensaje especial de carnet de networking', () {
    final message = ChatMessage.fromMap('m3', {
      'senderId': '505',
      'senderName': 'Alumna De Prueba',
      'body': '${ChatMessage.networkingBodyPrefix}505',
      'createdAt': 1783573983742,
    });

    expect(message.isNetworkingCard, isTrue);
    expect(message.networkingOwnerId, 505);
    expect(message.messageType, 'networking_card');
  });

  test(
    'deriva label/peso/moderador de cada rol cuando no vienen en el mapa',
    () {
      ChatMessage soloRol(String role) =>
          ChatMessage.fromMap('x', {'senderRole': role, 'body': 'hola'});

      expect(soloRol('teacher').senderRoleLabel, 'Profesor');
      expect(soloRol('teacher').weight, 100);
      expect(soloRol('jp').weight, 90);
      expect(soloRol('jp').isModerator, isTrue);
      expect(soloRol('delegate').weight, 70);
      expect(soloRol('subdelegate').weight, 60);
      expect(soloRol('subdelegate').isModerator, isTrue);
      expect(soloRol('student').weight, 10);
      expect(soloRol('student').isModerator, isFalse);
    },
  );

  test('el flag moderator explícito manda aunque el rol sea alumno', () {
    final m = ChatMessage.fromMap('x', {
      'senderRole': 'student',
      'moderator': true,
      'body': 'promovido',
    });
    expect(m.senderRole, 'student');
    expect(m.isModerator, isTrue);
  });

  test('rol desconocido cae a alumno (peso 10, no moderador)', () {
    final m = ChatMessage.fromMap('x', {'senderRole': 'rey', 'body': 'x'});
    expect(m.weight, 10);
    expect(m.isModerator, isFalse);
    expect(m.senderRoleLabel, 'Alumno');
  });

  test(
    'createdAt: acepta epoch millis, ISO string y cae a "ahora" si falta',
    () {
      final ms = ChatMessage.fromMap('a', {
        'body': 'x',
        'createdAt': 1783573983742,
      });
      expect(ms.createdAt, DateTime.fromMillisecondsSinceEpoch(1783573983742));

      final iso = ChatMessage.fromMap('b', {
        'body': 'x',
        'createdAt': '2026-07-09T12:00:00.000Z',
      });
      expect(iso.createdAt, DateTime.parse('2026-07-09T12:00:00.000Z'));

      final antes = DateTime.now();
      final sinFecha = ChatMessage.fromMap('c', {'body': 'x'});
      expect(
        sinFecha.createdAt.isBefore(antes.subtract(const Duration(seconds: 1))),
        isFalse,
      );
    },
  );

  test(
    'campos ausentes usan defaults seguros (senderName, body, senderId)',
    () {
      final m = ChatMessage.fromMap('vacio', {});
      expect(m.senderName, 'Participante');
      expect(m.body, '');
      expect(m.senderId, '');
      expect(m.senderRole, 'student');
    },
  );

  test('los mensajes se ordenan cronológicamente por timestamp', () {
    final msgs = [
      ChatMessage.fromMap('c', {'body': '3', 'createdAt': 300}),
      ChatMessage.fromMap('a', {'body': '1', 'createdAt': 100}),
      ChatMessage.fromMap('b', {'body': '2', 'createdAt': 200}),
    ]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    expect(msgs.map((m) => m.body).toList(), ['1', '2', '3']);
  });

  test('HU23: parsea el borrado suave (deleted + deletedBy)', () {
    final m = ChatMessage.fromMap('x', {
      'senderId': '502',
      'body': 'texto original',
      'deleted': true,
      'deletedBy': 'Docente De Prueba',
      'deletedByRole': 'teacher',
    });
    expect(m.deleted, isTrue);
    expect(m.deletedBy, 'Docente De Prueba');
    expect(m.deletedByRole, 'teacher');
  });

  test('HU23: sin campos de borrado ⇒ deleted=false', () {
    final m = ChatMessage.fromMap('y', {'body': 'hola'});
    expect(m.deleted, isFalse);
    expect(m.deletedBy, isNull);
    expect(m.deletedByUid, isNull);
    expect(m.deletedBySender, isFalse);
  });

  group('RF-CHAT-4 · quién borró', () {
    ChatMessage lapida({String senderId = '502', Object? deletedByUid}) =>
        ChatMessage.fromMap('z', {
          'senderId': senderId,
          'body': 'texto original',
          'deleted': true,
          'deletedBy': 'Compañero De Prueba',
          'deletedByRole': 'student',
          'deletedByUid': ?deletedByUid,
        });

    test('lee deletedByUid tal como llega', () {
      expect(lapida(deletedByUid: '502').deletedByUid, '502');
      expect(lapida(deletedByUid: '601').deletedByUid, '601');
    });

    test('sin deletedByUid queda nulo, sin inventar un valor', () {
      expect(lapida().deletedByUid, isNull);
    });

    test('lo borró su autor si deletedByUid es su senderId', () {
      expect(lapida(deletedByUid: '502').deletedBySender, isTrue);
    });

    test('lo borró otra persona si deletedByUid es otro uid', () {
      expect(lapida(deletedByUid: '601').deletedBySender, isFalse);
    });

    test('sin deletedByUid, o vacío, cuenta como borrado por otra persona', () {
      expect(lapida().deletedBySender, isFalse);
      expect(lapida(deletedByUid: '').deletedBySender, isFalse);
      expect(lapida(senderId: '', deletedByUid: '').deletedBySender, isFalse);
    });
  });
}
