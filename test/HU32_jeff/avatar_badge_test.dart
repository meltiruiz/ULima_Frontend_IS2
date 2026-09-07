import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/components/avatar/avatar_perfil.dart';
import 'package:ulima_plus/components/avatar/avatar_usuario.dart';

/// La insignia que avisa que el avatar del perfil se puede tocar.
///
/// Sin ella el cuadro de iniciales se ve idéntico al de las pantallas que NO
/// dejan cambiar la foto, y la función queda escondida: el 2026-09-07, con la
/// app ya instalada, el propio usuario no encontró dónde cambiarse la foto.
void main() {
  Widget montar(Widget hijo) => MaterialApp(home: Scaffold(body: hijo));

  group('la insignia marca el avatar como tocable', () {
    testWidgets('lleva un icono de cámara', (tester) async {
      await tester.pumpWidget(montar(const AvatarEditBadge(avatarSize: 48)));
      expect(find.byIcon(Icons.photo_camera_rounded), findsOneWidget);
    });

    testWidgets('crece con el avatar', (tester) async {
      double diametro(double size) => AvatarEditBadge(avatarSize: size).diameter;
      expect(diametro(96), greaterThan(diametro(48)));
    });

    testWidgets('en un avatar chico no se hace ilegible ni tapa las iniciales', (tester) async {
      // Cotas duras: por debajo de 14 px el icono no se distingue, y por encima
      // de 28 la insignia empieza a comerse el cuadro de 48 del perfil.
      expect(const AvatarEditBadge(avatarSize: 20).diameter, 14.0);
      expect(const AvatarEditBadge(avatarSize: 200).diameter, 28.0);
    });
  });

  group('las pantallas de solo lectura no cambian', () {
    testWidgets('AvatarUsuario NO lleva insignia', (tester) async {
      // Regresión: AvatarUsuario pinta las iniciales en 9 pantallas donde la
      // foto no se puede cambiar (contactos, chat, anuncios). Una insignia ahí
      // prometería algo que no se puede hacer.
      await tester.pumpWidget(montar(const AvatarUsuario(iniciales: 'JS')));
      expect(find.byType(AvatarEditBadge), findsNothing);
      expect(find.byIcon(Icons.photo_camera_rounded), findsNothing);
    });
  });
}
