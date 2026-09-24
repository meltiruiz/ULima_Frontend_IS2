// test/HU23_jeff/chat_page_test.dart
//
// WIDGET — HU23 (chat de sección): ChatPage con un repositorio falso.
// - RF-CHAT-1 a RF-CHAT-3: conexión, mensajes en vivo y envío de texto y de
//   carnet, como antes del rediseño.
// - RF-CHAT-4: la lápida según quién borró. El autor lee «Eliminaste este
//   mensaje», los demás «Se eliminó este mensaje» y, si lo borró el profesor,
//   todos leen «Mensaje eliminado por <profesor>».
// - RF-CHAT-8: el AppBar con el círculo del curso y «Sección N» o «Sin
//   sección».
// - RF-CHAT-9 y RF-CHAT-10: el nombre solo en el ajeno que abre grupo, con la
//   etiqueta de rol del moderador a su lado, y el margen de 8 o 2 px.
// - RF-CHAT-11: el separador de día antes del primer mensaje de cada día, con
//   la hora en hora de Lima.
// - RF-CHAT-12: la barra de escritura, con sus íconos, tooltips, colores y el
//   botón enviar deshabilitado con el campo vacío, que tampoco da la
//   respuesta de toque de la plataforma (el clic de Android).
//
// Todos los datos son inventados; el repo es público.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/message.dart';
import 'package:ulima_plus/pages/chat/curso_avatar.dart';
import 'package:ulima_plus/services/chat_repository.dart';

import 'chat_repo_falso.dart';

const _teacher = sesionDocente;

/// Mensaje armado con `ChatMessage.fromMap`, como los que llegan de Firebase.
///
/// [createdAt] va como en el mapa. Un entero son milisegundos, que `fromMap`
/// vuelve una fecha local, y un texto ISO 8601 con «Z» da una fecha en UTC.
/// Sin él, el `id` hace de milisegundos.
ChatMessage _msg(
  String id,
  String senderId,
  String body, {
  String role = 'student',
  Object? createdAt,
}) => ChatMessage.fromMap(id, {
  'senderId': senderId,
  'senderName': senderId == '601' ? 'Docente De Prueba' : 'Alumno X',
  'senderRole': role,
  'body': body,
  'createdAt': createdAt ?? int.parse(id),
});

Widget _wrap(ChatRepoFalso repo, {String? sectionCode}) =>
    chatEnApp(repo, sectionCode: sectionCode);

/// La burbuja o la lápida que contiene [texto]: el `Container` decorado más
/// cercano.
Container _burbujaDe(WidgetTester tester, String texto) =>
    tester.widget<Container>(
      find
          .ancestor(
            of: find.text(texto),
            matching: find.byWidgetPredicate(
              (w) => w is Container && w.decoration is BoxDecoration,
            ),
          )
          .first,
    );

double _margenArriba(WidgetTester tester, String texto) =>
    (_burbujaDe(tester, texto).margin! as EdgeInsets).top;

void main() {
  // GetX usa estado global (snackbars/controllers); se resetea entre tests
  // para aislarlos y no arrastrar tickers de un snackbar al siguiente.
  tearDown(Get.reset);

  testWidgets('muestra spinner mientras conecta y luego los mensajes', (
    tester,
  ) async {
    final repo = ChatRepoFalso(
      session: _teacher,
      messages: [
        _msg('100', '502', 'Hola profe!'),
        _msg('200', '601', 'Buen día alumnos', role: 'teacher'),
      ],
    );
    await tester.pumpWidget(_wrap(repo));

    // Primer frame: aún cargando el token.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Hola profe!'), findsOneWidget);
    expect(find.text('Buen día alumnos'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('error al conectar → placeholder "chat no disponible"', (
    tester,
  ) async {
    final repo = ChatRepoFalso(error: Exception('403'));
    await tester.pumpWidget(_wrap(repo));
    await tester.pump(); // resuelve el future con error
    await tester.pump(const Duration(milliseconds: 300));

    // Texto exacto del placeholder (con punto); el snackbar de GetX usa otro
    // sin punto, por eso no se filtra con textContaining.
    expect(find.text('No se pudo conectar al chat.'), findsOneWidget);
    expect(
      find.textContaining('Solo los miembros de esta sección'),
      findsOneWidget,
    );
    // No se renderiza la caja de input cuando no hay sesión.
    expect(find.byType(TextField), findsNothing);

    // Cierra el snackbar para no dejar un Ticker activo al finalizar el test.
    Get.closeAllSnackbars();
    await tester.pumpAndSettle();
  });

  testWidgets('sesión sin mensajes → aviso de grupo protegido', (tester) async {
    final repo = ChatRepoFalso(session: _teacher, messages: const []);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    expect(find.textContaining('miembros de esta sección'), findsOneWidget);
    // Con sesión válida sí hay caja de input.
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('enviar mensaje → el repo lo recibe y el campo se limpia', (
    tester,
  ) async {
    final repo = ChatRepoFalso(session: _teacher, messages: const []);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Hola equipo');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    expect(repo.sent, ['Hola equipo']);
    expect(find.text('Hola equipo'), findsNothing); // campo limpiado
  });

  testWidgets('no envía mensajes vacíos', (tester) async {
    final repo = ChatRepoFalso(session: _teacher, messages: const []);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    expect(repo.sent, isEmpty);
  });

  testWidgets('enviar carnet usa el mensaje especial del repo', (tester) async {
    final repo = ChatRepoFalso(session: _teacher, messages: const []);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    // RF-CHAT-12: el ícono de credencial reemplaza a contact_page_outlined.
    await tester.tap(find.byIcon(LucideIcons.idCard));
    await tester.pump();

    expect(repo.sentNetworking, ['1']);
    expect(repo.sent, isEmpty);
  });

  testWidgets('mensaje carnet se renderiza como burbuja especial', (
    tester,
  ) async {
    final repo = ChatRepoFalso(
      session: _teacher,
      messages: [
        ChatMessage.fromMap('400', {
          'senderId': '502',
          'senderName': 'Alumno X',
          'senderRole': 'student',
          'body': '${ChatMessage.networkingBodyPrefix}502',
          'createdAt': 400,
        }),
      ],
    );
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    expect(find.text('Envio su carnet de networking'), findsOneWidget);
    // RF-CHAT-8: el mismo ícono de credencial en la burbuja y en la barra.
    expect(find.byIcon(LucideIcons.idCard), findsNWidgets(2));
    expect(find.byIcon(Icons.contact_page_outlined), findsNothing);
  });

  testWidgets('un mensaje ajeno de moderador muestra su etiqueta de rol', (
    tester,
  ) async {
    // RF-CHAT-9 y RF-CHAT-10: la sesión es la del profesor ('601') y el
    // mensaje es del delegado, otro senderId, así que lleva nombre y etiqueta.
    final repo = ChatRepoFalso(
      session: _teacher,
      messages: [_msg('100', '503', 'Mañana hay práctica', role: 'delegate')],
    );
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    expect(find.text('Alumno X'), findsOneWidget);
    expect(find.text('Delegado'), findsOneWidget);
  });

  testWidgets('un mensaje propio de moderador no muestra nombre ni etiqueta', (
    tester,
  ) async {
    // La sesión es la del profesor ('601') y el mensaje también: es propio.
    final repo = ChatRepoFalso(
      session: _teacher,
      messages: [_msg('100', '601', 'Bienvenidos', role: 'teacher')],
    );
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    expect(find.text('Bienvenidos'), findsOneWidget);
    expect(find.text('Profesor'), findsNothing);
    expect(find.text('Docente De Prueba'), findsNothing);
  });

  testWidgets(
    'HU23: un mensaje eliminado muestra la lápida y oculta el cuerpo',
    (tester) async {
      final deletedMsg = ChatMessage.fromMap('300', {
        'senderId': '502',
        'senderName': 'Alumno X',
        'senderRole': 'student',
        'body': 'texto original que no debe verse',
        'createdAt': 300,
        'deleted': true,
        'deletedBy': 'Docente De Prueba',
        'deletedByRole': 'teacher',
      });
      final repo = ChatRepoFalso(session: _teacher, messages: [deletedMsg]);
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      expect(
        find.text('Mensaje eliminado por Docente De Prueba'),
        findsOneWidget,
      );
      // El cuerpo original no se renderiza.
      expect(find.text('texto original que no debe verse'), findsNothing);
    },
  );

  group('RF-CHAT-4 · la lápida según quién borró', () {
    /// Lápida del mensaje '300' de [senderId], borrado por [deletedByUid].
    ChatMessage lapida({
      required String senderId,
      required String senderName,
      String? deletedBy,
      String? deletedByUid,
      String deletedByRole = 'student',
    }) => ChatMessage.fromMap('300', {
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': 'student',
      'body': 'texto original que no debe verse',
      'createdAt': 300,
      'deleted': true,
      'deletedBy': ?deletedBy,
      'deletedByUid': ?deletedByUid,
      'deletedByRole': deletedByRole,
    });

    Future<void> abrir(
      WidgetTester tester,
      ChatSession sesion,
      ChatMessage mensaje,
    ) async {
      await tester.pumpWidget(
        _wrap(ChatRepoFalso(session: sesion, messages: [mensaje])),
      );
      await tester.pumpAndSettle();
    }

    /// Lo borró su autor, el alumno sintético.
    final borradoPorSuAutor = lapida(
      senderId: sesionAlumno.uid,
      senderName: sesionAlumno.displayName,
      deletedBy: sesionAlumno.displayName,
      deletedByUid: sesionAlumno.uid,
    );

    testWidgets('el autor lee «Eliminaste este mensaje»', (tester) async {
      await abrir(tester, sesionAlumno, borradoPorSuAutor);

      expect(find.text('Eliminaste este mensaje'), findsOneWidget);
      expect(find.text('Se eliminó este mensaje'), findsNothing);
      expect(find.textContaining('Mensaje eliminado por'), findsNothing);
      expect(find.text('texto original que no debe verse'), findsNothing);
      // Va del lado del autor, a la derecha.
      expect(
        tester.getCenter(find.text('Eliminaste este mensaje')).dx,
        greaterThan(tester.getSize(find.byType(Scaffold)).width / 2),
      );
    });

    for (final sesion in [sesionDocente, sesionJp]) {
      testWidgets('${sesion.roleLabel}, que no es su autor, lee «Se eliminó '
          'este mensaje»', (tester) async {
        await abrir(tester, sesion, borradoPorSuAutor);

        expect(find.text('Se eliminó este mensaje'), findsOneWidget);
        expect(find.text('Eliminaste este mensaje'), findsNothing);
        expect(find.textContaining('Mensaje eliminado por'), findsNothing);
        expect(find.text('texto original que no debe verse'), findsNothing);
      });
    }

    /// Lo borró el profesor titular, que no es su autor.
    final borradoPorElProfesor = lapida(
      senderId: sesionAlumno.uid,
      senderName: sesionAlumno.displayName,
      deletedBy: 'Docente De Prueba',
      deletedByUid: sesionDocente.uid,
      deletedByRole: 'teacher',
    );

    for (final sesion in [sesionAlumno, sesionJp, sesionDocente]) {
      testWidgets('si lo borró el profesor, ${sesion.roleLabel} lee «Mensaje '
          'eliminado por <profesor>»', (tester) async {
        await abrir(tester, sesion, borradoPorElProfesor);

        expect(
          find.text('Mensaje eliminado por Docente De Prueba'),
          findsOneWidget,
        );
        expect(find.text('Eliminaste este mensaje'), findsNothing);
        expect(find.text('Se eliminó este mensaje'), findsNothing);
      });
    }

    testWidgets('si lo borró el profesor sin nombre, dice «el profesor»', (
      tester,
    ) async {
      await abrir(
        tester,
        sesionAlumno,
        lapida(
          senderId: sesionAlumno.uid,
          senderName: sesionAlumno.displayName,
          deletedByUid: sesionDocente.uid,
          deletedByRole: 'teacher',
        ),
      );

      expect(find.text('Mensaje eliminado por el profesor'), findsOneWidget);
    });

    testWidgets('sin deletedByUid cuenta como borrado por otra persona', (
      tester,
    ) async {
      await abrir(
        tester,
        sesionAlumno,
        lapida(
          senderId: sesionAlumno.uid,
          senderName: sesionAlumno.displayName,
          deletedBy: 'Docente De Prueba',
        ),
      );

      expect(
        find.text('Mensaje eliminado por Docente De Prueba'),
        findsOneWidget,
      );
      expect(find.text('Eliminaste este mensaje'), findsNothing);
    });

    for (final brillo in Brightness.values) {
      final tema = brillo == Brightness.light ? 'claro' : 'oscuro';

      testWidgets('las dos lápidas nuevas llevan los estilos de RF-CHAT-8, en '
          '$tema', (tester) async {
        final otroAutor = lapida(
          senderId: '502',
          senderName: 'Alumno X',
          deletedBy: 'Alumno X',
          deletedByUid: '502',
        );
        final propia = ChatMessage.fromMap('400', {
          'senderId': sesionAlumno.uid,
          'senderName': sesionAlumno.displayName,
          'senderRole': 'student',
          'body': 'otro texto que no debe verse',
          'createdAt': 400,
          'deleted': true,
          'deletedBy': sesionAlumno.displayName,
          'deletedByUid': sesionAlumno.uid,
        });
        await tester.pumpWidget(
          chatEnApp(
            ChatRepoFalso(session: sesionAlumno, messages: [otroAutor, propia]),
            brillo: brillo,
          ),
        );
        await tester.pumpAndSettle();

        for (final texto in [
          'Se eliminó este mensaje',
          'Eliminaste este mensaje',
        ]) {
          final caja = _burbujaDe(tester, texto).decoration! as BoxDecoration;
          expect(caja.color, MaterialTheme.tagBg(brillo));
          expect(
            caja.border,
            Border.all(color: MaterialTheme.borderColor(brillo)),
          );
          expect(
            tester.widget<Text>(find.text(texto)).style!.color,
            MaterialTheme.textSecondary(brillo),
          );
          expect(_margenArriba(tester, texto), 8);
        }
      });
    }
  });

  group('RF-CHAT-8 · AppBar', () {
    testWidgets('lleva el círculo del curso, el curso y «Sección 801»', (
      tester,
    ) async {
      final repo = ChatRepoFalso(session: _teacher);
      await tester.pumpWidget(_wrap(repo, sectionCode: '801'));
      await tester.pumpAndSettle();

      final appBar = find.byType(AppBar);
      expect(
        find.descendant(of: appBar, matching: find.byType(CursoAvatar)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: appBar,
          matching: find.text('INGENIERÍA DE SOFTWARE II'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: appBar, matching: find.text('Sección 801')),
        findsOneWidget,
      );
      expect(find.text('Chat grupal'), findsNothing);
      expect(find.byIcon(Icons.group), findsNothing);
    });

    for (final codigo in <String?>[null, '', '   ']) {
      testWidgets('con el código ${codigo == null ? 'nulo' : '«$codigo»'} '
          'el subtítulo dice solo «Sin sección»', (tester) async {
        final repo = ChatRepoFalso(session: _teacher);
        await tester.pumpWidget(_wrap(repo, sectionCode: codigo));
        await tester.pumpAndSettle();

        expect(find.text('Sin sección'), findsOneWidget);
        expect(find.textContaining('Sección'), findsNothing);
      });
    }
  });

  group('RF-CHAT-9 · nombre del remitente e inicio de grupo', () {
    testWidgets('el nombre va solo en el ajeno que abre grupo, nunca en el '
        'propio', (tester) async {
      final repo = ChatRepoFalso(
        session: _teacher,
        messages: [
          _msg('100', '502', 'Primero del alumno'),
          _msg('200', '502', 'Segundo del alumno'),
          _msg('300', '601', 'Primero del profe', role: 'teacher'),
          _msg('400', '601', 'Segundo del profe', role: 'teacher'),
          _msg('500', '502', 'Tercero del alumno'),
        ],
      );
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      Finder nombreEn(String cuerpo) => find.descendant(
        of: find.byWidget(_burbujaDe(tester, cuerpo)),
        matching: find.text('Alumno X'),
      );

      expect(find.text('Alumno X'), findsNWidgets(2));
      expect(nombreEn('Primero del alumno'), findsOneWidget);
      expect(nombreEn('Segundo del alumno'), findsNothing);
      expect(nombreEn('Tercero del alumno'), findsOneWidget);
      // Los propios nunca llevan nombre ni etiqueta.
      expect(find.text('Docente De Prueba'), findsNothing);
      expect(find.text('Profesor'), findsNothing);
    });

    testWidgets('el que abre grupo lleva 8 px arriba y los demás, 2 px', (
      tester,
    ) async {
      final repo = ChatRepoFalso(
        session: _teacher,
        messages: [
          _msg('100', '502', 'Primero del alumno'),
          _msg('200', '502', 'Segundo del alumno'),
          _msg('300', '601', 'Primero del profe', role: 'teacher'),
          _msg('400', '601', 'Segundo del profe', role: 'teacher'),
        ],
      );
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      expect(_margenArriba(tester, 'Primero del alumno'), 8);
      expect(_margenArriba(tester, 'Segundo del alumno'), 2);
      // Un propio que sigue a un ajeno abre grupo, aunque no lleve nombre.
      expect(_margenArriba(tester, 'Primero del profe'), 8);
      expect(_margenArriba(tester, 'Segundo del profe'), 2);
    });

    testWidgets('tras una lápida, el ajeno del mismo remitente lleva nombre', (
      tester,
    ) async {
      final lapida = ChatMessage.fromMap('100', {
        'senderId': '502',
        'senderName': 'Alumno X',
        'senderRole': 'student',
        'body': 'texto borrado',
        'createdAt': 100,
        'deleted': true,
        'deletedBy': 'Docente De Prueba',
      });
      final repo = ChatRepoFalso(
        session: _teacher,
        messages: [lapida, _msg('200', '502', 'Después de la lápida')],
      );
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      // La lápida no lleva nombre; el mensaje que la sigue, sí.
      expect(find.text('Alumno X'), findsOneWidget);
      expect(_margenArriba(tester, 'Después de la lápida'), 8);
      expect(
        _margenArriba(tester, 'Mensaje eliminado por Docente De Prueba'),
        8,
      );
    });
  });

  group('RF-CHAT-11 · separadores de día', () {
    testWidgets('el separador va antes del primer mensaje de cada día, con la '
        'hora en Lima', (tester) async {
      // 03:30 UTC del 15 es 22:30 del lunes 14 en Lima; 05:10 UTC es 00:10
      // del martes 15, y 06:00 UTC es 01:00 del mismo martes. El tercero es
      // de otro remitente: abre grupo, pero no día.
      //
      // Los tres llegan como texto ISO con «Z», así que `fromMap` los deja en
      // UTC. Como milisegundos serían fechas locales, y en una máquina en
      // UTC−5 leer sus campos sin pasar a Lima ya daría 22:30 y el lunes 14,
      // con lo que la prueba no distinguiría la hora de Lima. En UTC, leerlos
      // sin convertir da 03:30 y el martes 15 en cualquier zona.
      final repo = ChatRepoFalso(
        session: _teacher,
        messages: [
          _msg(
            '1',
            '502',
            'Mensaje de la noche',
            createdAt: '2026-09-15T03:30:00Z',
          ),
          _msg(
            '2',
            '502',
            'Mensaje de la madrugada',
            createdAt: '2026-09-15T05:10:00Z',
          ),
          _msg(
            '3',
            '503',
            'Mensaje de la una',
            createdAt: '2026-09-15T06:00:00Z',
          ),
        ],
      );
      expect(repo.messages.map((m) => m.createdAt.isUtc), everyElement(isTrue));
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      final lunes = find.text('Lunes 14 de septiembre');
      final martes = find.text('Martes 15 de septiembre');
      expect(lunes, findsOneWidget);
      expect(martes, findsOneWidget);
      expect(find.text('22:30'), findsOneWidget);
      expect(find.text('00:10'), findsOneWidget);
      expect(find.text('01:00'), findsOneWidget);

      double y(Finder f) => tester.getTopLeft(f).dy;
      expect(y(lunes), lessThan(y(find.text('22:30'))));
      expect(y(find.text('22:30')), lessThan(y(martes)));
      expect(y(martes), lessThan(y(find.text('00:10'))));
      expect(y(find.text('00:10')), lessThan(y(find.text('01:00'))));
    });
  });

  group('RF-CHAT-12 · barra de escritura', () {
    testWidgets('«Enviar carnet» lleva el ícono de credencial y su tooltip', (
      tester,
    ) async {
      final repo = ChatRepoFalso(session: _teacher);
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      final carnet = find.byTooltip('Enviar carnet');
      expect(carnet, findsOneWidget);
      expect(
        find.descendant(of: carnet, matching: find.byIcon(LucideIcons.idCard)),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.contact_page_outlined), findsNothing);
    });

    testWidgets('el botón enviar lleva Icons.send y el tooltip «Enviar '
        'mensaje»', (tester) async {
      final repo = ChatRepoFalso(session: _teacher);
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      final enviar = find.byTooltip('Enviar mensaje');
      expect(enviar, findsOneWidget);
      expect(
        find.descendant(of: enviar, matching: find.byIcon(Icons.send)),
        findsOneWidget,
      );
    });

    testWidgets('con el campo vacío el botón enviar está deshabilitado y no '
        'envía; con texto se habilita y envía', (tester) async {
      final semantica = tester.ensureSemantics();
      final repo = ChatRepoFalso(session: _teacher);
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      final enviar = find.byTooltip('Enviar mensaje');
      expect(
        tester.getSemantics(enviar),
        isSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          hasTapAction: false,
        ),
      );
      await tester.tap(find.byIcon(Icons.send), warnIfMissed: false);
      await tester.pump();
      expect(repo.sent, isEmpty);

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      expect(
        tester.getSemantics(enviar),
        isSemantics(isButton: true, isEnabled: false),
      );

      await tester.enterText(find.byType(TextField), 'Hola equipo');
      await tester.pump();
      expect(
        tester.getSemantics(enviar),
        isSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();
      expect(repo.sent, ['Hola equipo']);

      semantica.dispose();
    });

    testWidgets('deshabilitado, el botón enviar no da la respuesta de toque de '
        'Android; habilitado, sí', (tester) async {
      // Las pruebas corren como Android, donde la respuesta de toque de un
      // InkWell es el clic del sistema, un SystemSound.play por el canal de
      // plataforma.
      expect(defaultTargetPlatform, TargetPlatform.android);
      final sonidos = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (llamada) async {
          if (llamada.method == 'SystemSound.play') {
            sonidos.add(llamada.arguments);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final repo = ChatRepoFalso(session: _teacher);
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      InkWell tinta() => tester.widget<InkWell>(
        find
            .ancestor(
              of: find.byIcon(Icons.send),
              matching: find.byType(InkWell),
            )
            .first,
      );

      // Con el campo vacío, el toque llega a enviar, que no manda nada, y no
      // suena.
      expect(tinta().enableFeedback, isFalse);
      await tester.tap(find.byIcon(Icons.send), warnIfMissed: false);
      await tester.pump();
      expect(sonidos, isEmpty);
      expect(repo.sent, isEmpty);

      await tester.enterText(find.byType(TextField), 'Hola equipo');
      await tester.pump();
      expect(tinta().enableFeedback, isTrue);
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();
      expect(sonidos, <Object?>['SystemSoundType.click']);
      expect(repo.sent, ['Hola equipo']);
    });

    testWidgets('la tecla de enviar del teclado sigue la misma regla', (
      tester,
    ) async {
      final repo = ChatRepoFalso(session: _teacher);
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '   ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(repo.sent, isEmpty);

      await tester.enterText(find.byType(TextField), 'Desde el teclado');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(repo.sent, ['Desde el teclado']);
    });

    for (final brillo in Brightness.values) {
      final tema = brillo == Brightness.light ? 'claro' : 'oscuro';

      testWidgets('los colores de la barra en $tema', (tester) async {
        final repo = ChatRepoFalso(session: _teacher);
        await tester.pumpWidget(chatEnApp(repo, brillo: brillo));
        await tester.pumpAndSettle();

        final decorados = find.ancestor(
          of: find.byType(TextField),
          matching: find.byWidgetPredicate(
            (w) => w is Container && w.decoration is BoxDecoration,
          ),
        );
        final campo =
            tester.widget<Container>(decorados.at(0)).decoration!
                as BoxDecoration;
        final barra =
            tester.widget<Container>(decorados.at(1)).decoration!
                as BoxDecoration;
        expect(campo.color, MaterialTheme.tagBg(brillo));
        expect(barra.color, MaterialTheme.cardBg(brillo));
        expect(
          (barra.border! as Border).top.color,
          MaterialTheme.borderColor(brillo),
        );

        final campoTexto = tester.widget<TextField>(find.byType(TextField));
        expect(campoTexto.style!.color, MaterialTheme.textPrimary(brillo));
        expect(
          campoTexto.decoration!.hintStyle!.color,
          MaterialTheme.textSecondary(brillo),
        );

        expect(
          tester.widget<Icon>(find.byIcon(LucideIcons.idCard)).color,
          brillo == Brightness.light
              ? MaterialTheme.primaryDark
              : MaterialTheme.primaryColor,
        );

        Material relleno() => tester.widget<Material>(
          find
              .ancestor(
                of: find.byIcon(Icons.send),
                matching: find.byType(Material),
              )
              .first,
        );
        Icon iconoEnviar() => tester.widget<Icon>(find.byIcon(Icons.send));

        // Deshabilitado: tagBg, textMuted y sin sombra.
        expect(relleno().color, MaterialTheme.tagBg(brillo));
        expect(relleno().elevation, 0);
        expect(iconoEnviar().color, MaterialTheme.textMuted(brillo));

        // Con texto: primaryDark en los dos temas, con el ícono en blanco.
        await tester.enterText(find.byType(TextField), 'Hola');
        await tester.pump();
        expect(relleno().color, MaterialTheme.primaryDark);
        expect(iconoEnviar().color, Colors.white);
      });
    }
  });
}
