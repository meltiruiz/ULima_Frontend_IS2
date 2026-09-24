// test/HU23_jeff/chat_moderacion_test.dart
//
// WIDGET — HU23 (chat de sección): borrar mensajes (RF-CHAT-4, ajustada el
// 2026-09-23) con los colores de RF-CHAT-8.
// - Con cualquier rol (alumno, delegado, subdelegado, JP y profesor), un toque
//   largo sobre un mensaje propio no borrado abre «¿Eliminar mensaje?» y, al
//   confirmar, lo borra por su id.
// - En un mensaje ajeno, solo el profesor titular (rol teacher) ve la acción.
// - Ninguna lápida abre el borrado, ni la propia ni la ajena.
// - El cuerpo del diálogo dice «Se eliminará para todos.» en un mensaje propio,
//   con cualquier rol, y «Se eliminará para todos y verán que lo eliminaste
//   tú.» cuando el profesor titular borra uno ajeno, decidido por senderId y
//   sin comillas rectas.
// - Un 403 muestra el texto del servidor en el aviso de error y cualquier otro
//   fallo, el texto de siempre. «Eliminar» y los avisos de error van en blanco
//   sobre errorBg.
// Archivo: lib/pages/chat/chat_page.dart.
//
// Todos los datos son inventados; el repo es público.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/message.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/chat_repository.dart';

import 'chat_repo_falso.dart';

const _blanco = Color(0xFFFFFFFF);

const _ajeno = 'Mensaje a moderar';
const _propio = 'Mi mensaje';

/// El cuerpo del diálogo sobre un mensaje propio, con cualquier rol.
const _cuerpoPropio = 'Se eliminará para todos.';

/// El cuerpo del diálogo cuando el profesor titular borra uno ajeno.
const _cuerpoAjeno = 'Se eliminará para todos y verán que lo eliminaste tú.';

/// El texto del cuerpo del diálogo abierto, que es su `content`.
String _textoDelCuerpo(WidgetTester tester) =>
    (tester.widget<AlertDialog>(find.byType(AlertDialog)).content! as Text)
        .data!;

ChatMessage _mensaje(
  String id,
  String body, {
  String senderId = '502',
  String senderName = 'Compañero De Prueba',
  bool deleted = false,
  String? deletedBy,
  String? deletedByUid,
}) => ChatMessage.fromMap(id, {
  'senderId': senderId,
  'senderName': senderName,
  'senderRole': 'student',
  'body': body,
  'createdAt': DateTime.utc(2026, 9, 15, 15).millisecondsSinceEpoch,
  if (deleted) 'deleted': true,
  'deletedBy': ?deletedBy,
  'deletedByUid': ?deletedByUid,
});

/// Abre el chat de [sesion] con un mensaje ajeno, una lápida ajena que borró
/// el profesor, un mensaje propio y una lápida propia que borró su autor.
Future<ChatRepoFalso> _abrir(
  WidgetTester tester,
  ChatSession sesion, {
  Brightness brillo = Brightness.light,
  Object? deleteError,
}) async {
  final repo = ChatRepoFalso(
    session: sesion,
    deleteError: deleteError,
    messages: [
      _mensaje('m1', _ajeno),
      _mensaje(
        'm2',
        'texto borrado',
        deleted: true,
        deletedBy: 'Docente De Prueba',
        deletedByUid: '601',
      ),
      _mensaje(
        'm3',
        _propio,
        senderId: sesion.uid,
        senderName: sesion.displayName,
      ),
      _mensaje(
        'm4',
        'texto propio borrado',
        senderId: sesion.uid,
        senderName: sesion.displayName,
        deleted: true,
        deletedBy: sesion.displayName,
        deletedByUid: sesion.uid,
      ),
    ],
  );
  await tester.pumpWidget(chatEnApp(repo, brillo: brillo));
  await tester.pumpAndSettle();
  return repo;
}

/// Toque largo sobre [texto], confirma con «Eliminar» y deja ver el aviso.
Future<void> _borrar(WidgetTester tester, String texto) async {
  await tester.longPress(find.text(texto));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Eliminar'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

GetSnackBar _aviso(WidgetTester tester) =>
    tester.widget<GetSnackBar>(find.byType(GetSnackBar));

Future<void> _cerrarAvisos(WidgetTester tester) async {
  Get.closeAllSnackbars();
  await tester.pumpAndSettle();
}

void main() {
  tearDown(Get.reset);

  group('RF-CHAT-4 · el autor borra sus mensajes, con cualquier rol', () {
    for (final sesion in [
      sesionAlumno,
      sesionDelegado,
      sesionSubdelegado,
      sesionJp,
      sesionDocente,
    ]) {
      testWidgets('${sesion.roleLabel} abre «¿Eliminar mensaje?» sobre un '
          'mensaje propio y lo borra por su id', (tester) async {
        final repo = await _abrir(tester, sesion);

        await tester.longPress(find.text(_propio));
        await tester.pumpAndSettle();

        expect(find.text('¿Eliminar mensaje?'), findsOneWidget);
        expect(find.text('Cancelar'), findsOneWidget);
        expect(find.text('Eliminar'), findsOneWidget);

        await tester.tap(find.text('Eliminar'));
        await tester.pumpAndSettle();

        expect(repo.deleted, ['m3']);
      });

      testWidgets('${sesion.roleLabel}: su propia lápida no abre el borrado', (
        tester,
      ) async {
        final repo = await _abrir(tester, sesion);

        await tester.longPress(
          find.text('Eliminaste este mensaje'),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        expect(find.text('¿Eliminar mensaje?'), findsNothing);
        expect(repo.deleted, isEmpty);
      });
    }

    for (final sesion in [
      sesionAlumno,
      sesionDelegado,
      sesionSubdelegado,
      sesionJp,
    ]) {
      testWidgets('${sesion.roleLabel} no ve «¿Eliminar mensaje?» en un '
          'mensaje ajeno', (tester) async {
        final repo = await _abrir(tester, sesion);

        await tester.longPress(find.text(_ajeno));
        await tester.pumpAndSettle();

        expect(find.text('¿Eliminar mensaje?'), findsNothing);
        expect(repo.deleted, isEmpty);
      });
    }

    testWidgets('al cancelar, el autor no borra nada', (tester) async {
      final repo = await _abrir(tester, sesionAlumno);

      await tester.longPress(find.text(_propio));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('¿Eliminar mensaje?'), findsNothing);
      expect(repo.deleted, isEmpty);
    });
  });

  group('RF-CHAT-4 · el profesor titular borra cualquiera', () {
    testWidgets('el profesor abre «¿Eliminar mensaje?» sobre uno ajeno', (
      tester,
    ) async {
      await _abrir(tester, sesionDocente);

      await tester.longPress(find.text(_ajeno));
      await tester.pumpAndSettle();

      expect(find.text('¿Eliminar mensaje?'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Eliminar'), findsOneWidget);
    });

    testWidgets('al confirmar, el profesor borra el ajeno por su id', (
      tester,
    ) async {
      final repo = await _abrir(tester, sesionDocente);

      await tester.longPress(find.text(_ajeno));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(repo.deleted, ['m1']);
    });

    testWidgets('al cancelar, no borra nada', (tester) async {
      final repo = await _abrir(tester, sesionDocente);

      await tester.longPress(find.text(_ajeno));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('¿Eliminar mensaje?'), findsNothing);
      expect(repo.deleted, isEmpty);
    });

    testWidgets('una lápida ajena no abre el borrado, ni para el profesor', (
      tester,
    ) async {
      await _abrir(tester, sesionDocente);

      await tester.longPress(
        find.text('Mensaje eliminado por Docente De Prueba'),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(find.text('¿Eliminar mensaje?'), findsNothing);
    });
  });

  group('RF-CHAT-4 · el cuerpo del diálogo', () {
    for (final sesion in [
      sesionAlumno,
      sesionDelegado,
      sesionSubdelegado,
      sesionJp,
      sesionDocente,
    ]) {
      testWidgets(
        '${sesion.roleLabel}: en un mensaje propio dice «$_cuerpoPropio»',
        (tester) async {
          await _abrir(tester, sesion);

          await tester.longPress(find.text(_propio));
          await tester.pumpAndSettle();

          expect(find.text(_cuerpoPropio), findsOneWidget);
          expect(_textoDelCuerpo(tester), _cuerpoPropio);
        },
      );
    }

    testWidgets('en uno ajeno, el profesor lee «$_cuerpoAjeno»', (
      tester,
    ) async {
      await _abrir(tester, sesionDocente);

      await tester.longPress(find.text(_ajeno));
      await tester.pumpAndSettle();

      expect(find.text(_cuerpoAjeno), findsOneWidget);
      expect(_textoDelCuerpo(tester), _cuerpoAjeno);
    });

    testWidgets('lo propio se decide por senderId y no por el nombre', (
      tester,
    ) async {
      // Otro remitente con el mismo nombre que el profesor sigue siendo ajeno.
      final repo = ChatRepoFalso(
        session: sesionDocente,
        messages: [
          _mensaje('m5', 'Mismo nombre', senderName: sesionDocente.displayName),
        ],
      );
      await tester.pumpWidget(chatEnApp(repo));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Mismo nombre'));
      await tester.pumpAndSettle();

      expect(_textoDelCuerpo(tester), _cuerpoAjeno);
      expect(find.text(_cuerpoPropio), findsNothing);
    });

    testWidgets('ningún texto del diálogo lleva comillas rectas', (
      tester,
    ) async {
      await _abrir(tester, sesionDocente);

      for (final mensaje in [_propio, _ajeno]) {
        await tester.longPress(find.text(mensaje));
        await tester.pumpAndSettle();

        final textos = tester
            .widgetList<Text>(
              find.descendant(
                of: find.byType(AlertDialog),
                matching: find.byType(Text),
              ),
            )
            .map((t) => t.data ?? '')
            .toList();
        expect(textos, isNotEmpty, reason: mensaje);
        for (final texto in textos) {
          expect(texto, isNot(contains('"')), reason: texto);
          expect(texto, isNot(contains("'")), reason: texto);
        }

        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
      }
    });
  });

  for (final brillo in Brightness.values) {
    final tema = brillo == Brightness.light ? 'claro' : 'oscuro';

    testWidgets('«Eliminar» va en blanco sobre errorBg, en $tema', (
      tester,
    ) async {
      await _abrir(tester, sesionDocente, brillo: brillo);

      await tester.longPress(find.text(_ajeno));
      await tester.pumpAndSettle();

      final eliminar = find.text('Eliminar');
      final pintado = tester
          .widget<RichText>(
            find.descendant(of: eliminar, matching: find.byType(RichText)),
          )
          .text
          .style!
          .color;
      expect(pintado, _blanco);
      final boton = tester.widget<Material>(
        find.ancestor(of: eliminar, matching: find.byType(Material)).first,
      );
      expect(boton.color, MaterialTheme.errorBg(brillo));
    });

    testWidgets('el aviso de un borrado fallido va en blanco sobre errorBg, '
        'en $tema', (tester) async {
      await _abrir(
        tester,
        sesionDocente,
        brillo: brillo,
        deleteError: Exception('fallo de red'),
      );

      await _borrar(tester, _ajeno);

      final aviso = _aviso(tester);
      expect((aviso.titleText! as Text).data, 'No se pudo eliminar');
      expect(
        (aviso.messageText! as Text).data,
        'Inténtalo de nuevo en unos segundos.',
      );
      expect(aviso.backgroundColor, MaterialTheme.errorBg(brillo));
      expect((aviso.titleText! as Text).style!.color, _blanco);
      expect((aviso.messageText! as Text).style!.color, _blanco);

      await _cerrarAvisos(tester);
    });

    testWidgets('un 403 muestra el texto del servidor en blanco sobre '
        'errorBg, en $tema', (tester) async {
      await _abrir(
        tester,
        sesionAlumno,
        brillo: brillo,
        deleteError: ApiException(
          statusCode: 403,
          code: 'CHAT_DELETE_FORBIDDEN',
          message: 'Solo puedes eliminar tus propios mensajes.',
        ),
      );

      await _borrar(tester, _propio);

      final aviso = _aviso(tester);
      expect((aviso.titleText! as Text).data, 'No se pudo eliminar');
      expect(
        (aviso.messageText! as Text).data,
        'Solo puedes eliminar tus propios mensajes.',
      );
      expect(aviso.backgroundColor, MaterialTheme.errorBg(brillo));
      expect((aviso.titleText! as Text).style!.color, _blanco);
      expect((aviso.messageText! as Text).style!.color, _blanco);

      await _cerrarAvisos(tester);
    });
  }

  testWidgets('otro error del servidor sigue con el texto de siempre', (
    tester,
  ) async {
    await _abrir(
      tester,
      sesionAlumno,
      deleteError: ApiException(
        statusCode: 500,
        code: 'HTTP_ERROR',
        message: 'Error del servidor',
      ),
    );

    await _borrar(tester, _propio);

    expect(
      (_aviso(tester).messageText! as Text).data,
      'Inténtalo de nuevo en unos segundos.',
    );

    await _cerrarAvisos(tester);
  });
}
