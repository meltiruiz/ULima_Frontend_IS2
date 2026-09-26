// test/six_seven/detector_seis_siete_test.dart
//
// UNITARIA · Truco del 67 (specs/features/six-seven/six-seven.spec.md).
// RF-67-6 fija qué lista del stream de un chat de sección dispara el
// tambaleo. Archivo probado lib/pages/chat/chat_seis_siete.dart.
//
// Todos los datos son inventados; el repo es público. Los remitentes usan
// los ids ficticios de las series 5xx y 6xx de las pruebas de HU23.

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/models/message.dart';
import 'package:ulima_plus/pages/chat/chat_seis_siete.dart';

/// Un mensaje de texto de un alumno inventado.
ChatMessage _msg(
  String id,
  String cuerpo, {
  bool borrado = false,
  String tipo = 'text',
}) => ChatMessage(
  id: id,
  senderId: '502',
  senderName: 'Alumno X',
  senderRole: 'student',
  senderRoleLabel: 'Alumno',
  isModerator: false,
  weight: 10,
  body: cuerpo,
  createdAt: DateTime.utc(2026, 9, 25, 15),
  messageType: tipo,
  deleted: borrado,
);

void main() {
  test('una primera lista con dos 67 no dispara', () {
    final detector = DetectorSeisSiete();
    expect(
      detector.revisar([_msg('a', '67'), _msg('b', 'six seven')]),
      isFalse,
    );
  });

  test('una segunda lista con un 67 de id nuevo dispara, y repetida ya no', () {
    final detector = DetectorSeisSiete();
    final historial = [_msg('a', 'hola')];
    detector.revisar(historial);

    final conSeisSiete = [...historial, _msg('b', '67')];
    expect(detector.revisar(conSeisSiete), isTrue);
    expect(detector.revisar(conSeisSiete), isFalse);
  });

  test('una lápida nueva con cuerpo «67» no dispara, y un carnet nuevo '
      'tampoco', () {
    final detector = DetectorSeisSiete()..revisar([_msg('a', 'hola')]);
    expect(
      detector.revisar([_msg('a', 'hola'), _msg('b', '67', borrado: true)]),
      isFalse,
    );
    expect(
      detector.revisar([
        _msg('a', 'hola'),
        _msg('b', '67', borrado: true),
        _msg('c', '67', tipo: 'networking_card'),
      ]),
      isFalse,
    );
  });

  test('un 67 ya visto que vuelve como lápida con el mismo id no dispara', () {
    final detector = DetectorSeisSiete()..revisar([_msg('a', 'hola')]);
    expect(detector.revisar([_msg('a', 'hola'), _msg('b', '67')]), isTrue);
    expect(
      detector.revisar([_msg('a', 'hola'), _msg('b', '67', borrado: true)]),
      isFalse,
    );
  });

  test('un mensaje nuevo con «67 soles» no dispara', () {
    final detector = DetectorSeisSiete()..revisar([]);
    expect(detector.revisar([_msg('a', '67 soles')]), isFalse);
  });

  test('una lista con dos 67 nuevos da un solo verdadero', () {
    final detector = DetectorSeisSiete()..revisar([_msg('a', 'hola')]);
    final lista = [_msg('a', 'hola'), _msg('b', '67'), _msg('c', '6 7')];
    expect(detector.revisar(lista), isTrue);
    expect(detector.revisar(lista), isFalse);
  });

  test('una primera lista vacía también es la base, y un 67 que llega '
      'después dispara', () {
    final detector = DetectorSeisSiete();
    expect(detector.revisar([]), isFalse);
    expect(detector.revisar([_msg('a', '67')]), isTrue);
  });

  test('una lista que repite los ids vistos sin el más viejo no dispara', () {
    final detector = DetectorSeisSiete()
      ..revisar([_msg('a', '67'), _msg('b', 'hola'), _msg('c', '67')]);
    expect(detector.revisar([_msg('b', 'hola'), _msg('c', '67')]), isFalse);
  });
}
