import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/services/avatar_service.dart';

/// El motivo real de que falle una subida.
///
/// El 2026-09-07 la app dijo "No se pudo subir la foto" y ese texto era
/// compatible con cuatro causas distintas: credencial mal puesta, firma
/// inválida, cuenta de Cloudinary equivocada y caída de red. Sin el mensaje que
/// Cloudinary sí devuelve, el diagnóstico costó leer los logs de Vercel para
/// descartar el backend. El motivo tiene que llegar a la pantalla.
void main() {
  group('el mensaje incluye lo que dijo Cloudinary', () {
    test('una firma inválida se muestra tal cual, con su código', () {
      final msg = mensajeDeFalloDeCloudinary(
        401,
        '{"error":{"message":"Invalid Signature 0a1b2c. String to sign - '
            "'invalidate=true&overwrite=true&public_id=avatars/7&timestamp=1788792000'\"}}",
      );
      expect(msg, contains('Invalid Signature'));
      expect(msg, contains('401'));
    });

    test('una cuenta inexistente también llega con su motivo', () {
      final msg = mensajeDeFalloDeCloudinary(404, '{"error":{"message":"cloud_name mismatch"}}');
      expect(msg, contains('cloud_name mismatch'));
      expect(msg, contains('404'));
    });
  });

  group('cuando no hay motivo utilizable, al menos queda el código', () {
    test('un cuerpo que no es JSON no rompe nada', () {
      // Un 502 del CDN de Cloudinary llega como HTML, no como JSON.
      final msg = mensajeDeFalloDeCloudinary(502, '<html><body>Bad Gateway</body></html>');
      expect(msg, contains('502'));
      expect(msg, isNot(contains('html')));
    });

    test('un JSON sin campo error cae al genérico', () {
      expect(mensajeDeFalloDeCloudinary(400, '{"algo":"otra cosa"}'), contains('400'));
    });

    test('un message vacío o de solo espacios no deja el mensaje colgando', () {
      final msg = mensajeDeFalloDeCloudinary(400, '{"error":{"message":"   "}}');
      expect(msg, contains('400'));
      expect(msg.trim(), isNot(endsWith(':')));
    });

    test('un cuerpo vacío tampoco', () {
      expect(mensajeDeFalloDeCloudinary(500, ''), contains('500'));
    });
  });

  test('siempre empieza diciendo qué falló, para que se entienda en pantalla', () {
    for (final cuerpo in ['', '{"error":{"message":"Invalid Signature"}}', 'no json']) {
      expect(mensajeDeFalloDeCloudinary(401, cuerpo), startsWith('No se pudo subir la foto'));
    }
  });
}
