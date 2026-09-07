import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/components/avatar/avatar_usuario.dart';

/// El respaldo a iniciales es lo que hace que esta feature no cambie nada para
/// quien no sube foto: 9 pantallas pintan iniciales hoy y deben verse igual.
void main() {
  Widget montar(Widget hijo) => MaterialApp(home: Scaffold(body: hijo));
  const url = 'https://res.cloudinary.com/x/image/upload/v1/y';

  testWidgets('sin avatarUrl muestra las iniciales', (tester) async {
    await tester.pumpWidget(montar(const AvatarUsuario(iniciales: 'JS')));
    expect(find.text('JS'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('una URL vacía o de solo espacios cuenta como sin foto', (tester) async {
    await tester.pumpWidget(montar(const AvatarUsuario(iniciales: 'JS', avatarUrl: '')));
    expect(find.text('JS'), findsOneWidget);
    await tester.pumpWidget(montar(const AvatarUsuario(iniciales: 'JS', avatarUrl: '   ')));
    expect(find.text('JS'), findsOneWidget);
  });

  testWidgets('con avatarUrl intenta pintar la imagen', (tester) async {
    await tester.pumpWidget(montar(const AvatarUsuario(iniciales: 'JS', avatarUrl: url)));
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('si la imagen falla vuelve a las iniciales, no a un icono roto', (tester) async {
    // En los tests toda petición de red devuelve 400, así que el errorBuilder se
    // ejercita de verdad: es el camino que protege a la lista de contactos
    // cuando la red va mal.
    await tester.pumpWidget(montar(const AvatarUsuario(iniciales: 'JS', avatarUrl: url)));
    await tester.pumpAndSettle();
    expect(find.text('JS'), findsOneWidget);
  });

  testWidgets('sin borderRadius es un círculo; con él respeta la forma de la pantalla', (tester) async {
    // El perfil usa un rectángulo redondeado. Si el widget impusiera círculo,
    // cambiaría cómo se ve hoy para quien NO tiene foto, que es justo lo que
    // esta feature no debe tocar.
    await tester.pumpWidget(montar(const AvatarUsuario(iniciales: 'JS')));
    final circulo = tester.widget<Container>(find.descendant(
      of: find.byType(AvatarUsuario), matching: find.byType(Container)).first);
    expect((circulo.decoration as BoxDecoration).shape, BoxShape.circle);

    await tester.pumpWidget(montar(AvatarUsuario(
      iniciales: 'JS', borderRadius: BorderRadius.circular(14))));
    final rect = tester.widget<Container>(find.descendant(
      of: find.byType(AvatarUsuario), matching: find.byType(Container)).first);
    expect((rect.decoration as BoxDecoration).shape, BoxShape.rectangle);
  });

  testWidgets('respeta el tamaño pedido', (tester) async {
    await tester.pumpWidget(montar(const AvatarUsuario(iniciales: 'JS', size: 80)));
    final caja = tester.getSize(find.byType(AvatarUsuario));
    expect(caja.width, 80);
    expect(caja.height, 80);
  });
}
