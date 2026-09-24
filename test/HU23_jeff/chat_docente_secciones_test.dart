// test/HU23_jeff/chat_docente_secciones_test.dart
//
// WIDGET — HU23 (chat de sección): el docente entra al chat desde su pestaña
// Secciones (RF-CHAT-13).
// - Cada tarjeta es un InkWell con ripple dentro de un Material con cardBg y
//   la forma de la tarjeta (radio de 16 px y borde borderColor), sin un
//   GestureDetector ni un Container decorado por fuera que tape el ripple.
// - Su semántica es la de un botón «Abrir el chat de <curso>, sección <N>» (o
//   «…, sin sección»), como en la bandeja del alumno, porque la tarjeta es la
//   misma TarjetaDeChat de la bandeja con el nombre del curso y el código de
//   la sección. Así dos secciones del mismo curso se distinguen.
// - Bajo el nombre del curso, la línea de la sección dice «Sección <N>» con el
//   código recortado, o solo «Sin sección», con la misma etiquetaDeSeccion de
//   la fila de la bandeja, y nunca el código crudo.
// - La columna derecha lleva LucideIcons.messagesSquare bajo la insignia de
//   rol y, a su derecha en la misma fila, el texto visible «Chat».
// - «Chat» va en textSecondary (4,5:1) y el ícono en iconoNaranja, que es
//   primaryDark en claro y primaryColor en oscuro (3:1), contra la tarjeta en
//   los dos temas.
// - La línea de la sección y la insignia de rol llegan a 4,5:1 en los dos
//   temas: la línea en textSecondary sobre la tarjeta y la insignia en
//   textSecondary sobre su tinte.
// - La tarjeta abre ChatPage con el código de la sección y
//   courseAccentColor(sectionId) como color.
// Archivos: lib/pages/teacher/teacher_sections_page.dart y
// lib/pages/chat/chats_inbox_page.dart.
//
// Todos los datos son inventados; el repo es público. Las secciones y los
// cursos no existen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ulima_plus/configs/course_colors.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/advising_models.dart';
import 'package:ulima_plus/pages/chat/chat_linea_tiempo.dart';
import 'package:ulima_plus/pages/chat/chat_page.dart';
import 'package:ulima_plus/pages/chat/chats_inbox_page.dart';
import 'package:ulima_plus/pages/chat/curso_avatar.dart';
import 'package:ulima_plus/pages/teacher/teacher_sections_controller.dart';
import 'package:ulima_plus/pages/teacher/teacher_sections_page.dart';
import 'package:ulima_plus/services/advising_service.dart';

import 'chat_repo_falso.dart';

// --- Datos inventados ---------------------------------------------------------

const String _cursoA = 'CURSO DE PRUEBA A';
const String _cursoC = 'Taller De Prueba C';

/// La etiqueta accesible de la tarjeta de cada curso, con su sección.
const Map<String, String> _etiquetas = <String, String>{
  _cursoA: 'Abrir el chat de $_cursoA, sección 801',
  _cursoC: 'Abrir el chat de $_cursoC, sin sección',
};

/// La línea visible de la sección en la tarjeta de cada curso.
const Map<String, String> _lineas = <String, String>{
  _cursoA: 'Sección 801',
  _cursoC: 'Sin sección',
};

/// Dos secciones del docente, una de profesor con código y una de JP sin
/// código, que la tarjeta y ChatPage muestran como «Sin sección».
List<TeacherSectionOption> _secciones() => <TeacherSectionOption>[
  TeacherSectionOption(
    sectionId: 301,
    courseName: _cursoA,
    sectionCode: '801',
    rol: 'Profesor',
  ),
  TeacherSectionOption(
    sectionId: 305,
    courseName: _cursoC,
    sectionCode: '',
    rol: 'JP',
  ),
];

// --- Dobles -------------------------------------------------------------------

/// El service de asesorías sin red, que devuelve las secciones fijas, o
/// [secciones] si llegan.
class _SeccionesFijas extends AdvisingService {
  _SeccionesFijas([this.secciones]);

  final List<TeacherSectionOption>? secciones;

  @override
  Future<List<TeacherSectionOption>> fetchSections() async =>
      secciones ?? _secciones();
}

// --- Montaje ------------------------------------------------------------------

ThemeData _temaDeLaApp(Brightness brillo) {
  const tema = MaterialTheme(TextTheme());
  return brillo == Brightness.light ? tema.light() : tema.dark();
}

/// Un iPhone SE en vertical (375 x 667).
void _telefonoVertical(WidgetTester tester) {
  tester.view.physicalSize = const Size(750, 1334);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

/// Registra el controller con las secciones fijas y monta la pestaña
/// Secciones como la monta el shell del docente, dentro del cuerpo de un
/// `Scaffold`.
Future<void> _abrirSecciones(
  WidgetTester tester, {
  Brightness brillo = Brightness.light,
  ChatRepoFalso? repo,
  List<TeacherSectionOption>? secciones,
}) async {
  _telefonoVertical(tester);
  Get.put<TeacherSectionsController>(
    TeacherSectionsController(service: _SeccionesFijas(secciones)),
  );
  await tester.pumpWidget(
    GetMaterialApp(
      theme: _temaDeLaApp(brillo),
      home: Scaffold(
        body: TeacherSectionsPage(
          chatRepository: repo ?? ChatRepoFalso(session: sesionDocente),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

/// La tarjeta de [curso], que es el nodo con su etiqueta accesible.
Finder _tarjeta(String curso) => find.bySemanticsLabel(_etiquetas[curso]!);

Finder _enLaTarjeta(String curso, Finder finder) =>
    find.descendant(of: _tarjeta(curso), matching: finder);

/// El estilo con que se pinta de verdad un texto o un ícono, que es el de su
/// `RichText` y ya mezcla el estilo propio con el heredado.
TextStyle _estiloPintado(WidgetTester tester, Finder texto) => tester
    .widget<RichText>(
      find.descendant(of: texto, matching: find.byType(RichText)).first,
    )
    .text
    .style!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  tearDown(Get.reset);

  group('WIDGET · la tarjeta de una sección (RF-CHAT-13)', () {
    testWidgets('cada tarjeta es un botón «Abrir el chat de <curso>, sección '
        '<N>», o «…, sin sección», de al menos 48 px', (tester) async {
      final semantica = tester.ensureSemantics();
      await _abrirSecciones(tester);

      for (final curso in <String>[_cursoA, _cursoC]) {
        final tarjeta = _tarjeta(curso);
        expect(tarjeta, findsOneWidget, reason: curso);
        expect(
          tester.getSemantics(tarjeta),
          isSemantics(
            label: _etiquetas[curso],
            isButton: true,
            hasTapAction: true,
          ),
        );
        expect(tester.getSize(tarjeta).height, greaterThanOrEqualTo(48));
        // La etiqueta de antes, sin la sección, ya no existe.
        expect(find.bySemanticsLabel('Abrir el chat de $curso'), findsNothing);
      }

      semantica.dispose();
    });

    testWidgets('cada tarjeta es la TarjetaDeChat de la bandeja con el nombre '
        'del curso de su sección', (tester) async {
      final semantica = tester.ensureSemantics();
      await _abrirSecciones(tester);

      expect(find.byType(TarjetaDeChat), findsNWidgets(2));
      for (final curso in <String>[_cursoA, _cursoC]) {
        final tarjeta = find.ancestor(
          of: _enLaTarjeta(curso, find.text(curso)),
          matching: find.byType(TarjetaDeChat),
        );
        expect(tarjeta, findsOneWidget, reason: curso);
        final widget = tester.widget<TarjetaDeChat>(tarjeta);
        expect(widget.nombreDelCurso, curso);
        expect(widget.codigoDeSeccion, curso == _cursoA ? '801' : '');
        expect(widget.brillo, Brightness.light);
      }

      semantica.dispose();
    });

    testWidgets('la línea de la sección dice «Sección <N>» o «Sin sección», '
        'como la fila de la bandeja, y no el código crudo', (tester) async {
      final semantica = tester.ensureSemantics();
      await _abrirSecciones(tester);

      for (final curso in <String>[_cursoA, _cursoC]) {
        expect(
          _enLaTarjeta(curso, find.text(_lineas[curso]!)),
          findsOneWidget,
          reason: curso,
        );
      }
      expect(_enLaTarjeta(_cursoA, find.text('801')), findsNothing);
      // La misma función que la bandeja y el subtítulo del AppBar.
      expect(_lineas[_cursoA], etiquetaDeSeccion('801'));
      expect(_lineas[_cursoC], etiquetaDeSeccion(''));

      semantica.dispose();
    });

    testWidgets('la línea recorta el código y dice «Sin sección» si solo trae '
        'espacios', (tester) async {
      final semantica = tester.ensureSemantics();
      await _abrirSecciones(
        tester,
        secciones: <TeacherSectionOption>[
          TeacherSectionOption(
            sectionId: 321,
            courseName: _cursoA,
            sectionCode: '  803 ',
            rol: 'Profesor',
          ),
          TeacherSectionOption(
            sectionId: 322,
            courseName: _cursoC,
            sectionCode: '   ',
            rol: 'JP',
          ),
        ],
      );

      final conCodigo = find.bySemanticsLabel(
        'Abrir el chat de $_cursoA, sección 803',
      );
      final sinCodigo = find.bySemanticsLabel(
        'Abrir el chat de $_cursoC, sin sección',
      );
      expect(
        find.descendant(of: conCodigo, matching: find.text('Sección 803')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sinCodigo, matching: find.text('Sin sección')),
        findsOneWidget,
      );
      expect(find.text('  803 '), findsNothing);
      expect(find.text('   '), findsNothing);

      semantica.dispose();
    });

    testWidgets('dos secciones del mismo curso se distinguen por su etiqueta y '
        'cada una abre su chat', (tester) async {
      final semantica = tester.ensureSemantics();
      await _abrirSecciones(
        tester,
        secciones: <TeacherSectionOption>[
          TeacherSectionOption(
            sectionId: 311,
            courseName: _cursoA,
            sectionCode: '801',
            rol: 'Profesor',
          ),
          TeacherSectionOption(
            sectionId: 312,
            courseName: _cursoA,
            sectionCode: '802',
            rol: 'Profesor',
          ),
        ],
      );

      const primera = 'Abrir el chat de $_cursoA, sección 801';
      const segunda = 'Abrir el chat de $_cursoA, sección 802';
      expect(find.bySemanticsLabel(primera), findsOneWidget);
      expect(find.bySemanticsLabel(segunda), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(segunda));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final chat = tester.widget<ChatPage>(find.byType(ChatPage));
      expect(chat.sectionId, '312');
      expect(chat.sectionCode, '802');

      semantica.dispose();
    });

    testWidgets('la tarjeta entera es un InkWell con ripple dentro de un '
        'Material con cardBg y la forma de la tarjeta', (tester) async {
      final semantica = tester.ensureSemantics();
      await _abrirSecciones(tester);
      const brillo = Brightness.light;

      final nombre = _enLaTarjeta(_cursoA, find.text(_cursoA));
      final tinta = find.ancestor(of: nombre, matching: find.byType(InkWell));
      expect(tinta, findsOneWidget);
      // El InkWell cubre la tarjeta entera, no solo el texto.
      expect(tester.getSize(tinta), tester.getSize(_tarjeta(_cursoA)));
      expect(tester.widget<InkWell>(tinta).onTap, isNotNull);

      final material = tester.widget<Material>(
        find.ancestor(of: tinta, matching: find.byType(Material)).first,
      );
      expect(material.color, MaterialTheme.cardBg(brillo));
      final forma = material.shape! as RoundedRectangleBorder;
      expect(forma.borderRadius, BorderRadius.circular(16));
      expect(forma.side.color, MaterialTheme.borderColor(brillo));
      expect(tester.getSize(tinta), tester.getSize(find.byWidget(material)));

      // El toque es del InkWell, así que todo GestureDetector de la tarjeta
      // es el suyo, por dentro, y ninguno lo envuelve.
      final gestos = _enLaTarjeta(_cursoA, find.byType(GestureDetector));
      expect(
        find.descendant(of: tinta, matching: find.byType(GestureDetector)),
        findsNWidgets(gestos.evaluate().length),
      );

      // Ningún Container decorado del tamaño de la tarjeta tapa el ripple. Los
      // decorados que quedan, el recuadro del ícono del curso y la insignia de
      // rol, son más chicos que la tarjeta.
      final decorados = find.descendant(
        of: tinta,
        matching: find.byWidgetPredicate(
          (w) => w is Container && w.decoration != null,
        ),
      );
      final tamanoTarjeta = tester.getSize(tinta);
      for (final elemento in decorados.evaluate()) {
        final caja = elemento.renderObject! as RenderBox;
        expect(caja.size.height, lessThan(tamanoTarjeta.height));
        expect(caja.size.width, lessThan(tamanoTarjeta.width));
      }

      semantica.dispose();
    });

    testWidgets('la columna derecha lleva LucideIcons.messagesSquare bajo la '
        'insignia de rol y el texto «Chat» a su derecha, en la misma fila', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await _abrirSecciones(tester);

      expect(find.byIcon(Icons.forum_outlined), findsNothing);
      for (final (curso, rol) in <(String, String)>[
        (_cursoA, 'Profesor'),
        (_cursoC, 'JP'),
      ]) {
        final icono = _enLaTarjeta(
          curso,
          find.byIcon(LucideIcons.messagesSquare),
        );
        final chat = _enLaTarjeta(curso, find.text('Chat'));
        final insignia = _enLaTarjeta(curso, find.text(rol));
        expect(icono, findsOneWidget, reason: curso);
        expect(chat, findsOneWidget, reason: curso);
        expect(insignia, findsOneWidget, reason: curso);

        // Bajo la insignia de rol.
        expect(
          tester.getTopLeft(icono).dy,
          greaterThan(tester.getBottomLeft(insignia).dy),
        );
        // «Chat» a la derecha del ícono, en la misma fila.
        expect(
          tester.getTopLeft(chat).dx,
          greaterThanOrEqualTo(tester.getTopRight(icono).dx),
        );
        expect(
          tester.getCenter(chat).dy,
          moreOrLessEquals(tester.getCenter(icono).dy, epsilon: 1),
        );
        // La columna derecha queda más a la derecha que el nombre del curso.
        expect(
          tester.getTopLeft(icono).dx,
          greaterThan(
            tester.getTopLeft(_enLaTarjeta(curso, find.text(curso))).dx,
          ),
        );
      }
      expect(tester.takeException(), isNull);

      semantica.dispose();
    });
  });

  group('WIDGET · colores de «Chat» y su ícono (RF-CHAT-13)', () {
    for (final brillo in Brightness.values) {
      final tema = brillo == Brightness.light ? 'claro' : 'oscuro';
      // Las cifras de la spec contra la tarjeta, cardBg.
      final cifras = brillo == Brightness.light
          ? (texto: 10.35, icono: 4.12)
          : (texto: 6.44, icono: 5.65);
      final naranja = brillo == Brightness.light
          ? MaterialTheme.primaryDark
          : MaterialTheme.primaryColor;
      // La línea de la sección sobre la tarjeta y la insignia de rol sobre
      // su tinte, que es su propio color al 12 % sobre la tarjeta.
      final cifrasDeLaSeccion = brillo == Brightness.light
          ? (codigo: 10.35, insignia: 8.45)
          : (codigo: 6.44, insignia: 5.26);

      testWidgets('en $tema: «Chat» en textSecondary y el ícono en el naranja '
          'de un ícono, con su contraste contra la tarjeta', (tester) async {
        final semantica = tester.ensureSemantics();
        await _abrirSecciones(tester, brillo: brillo);
        final tarjeta = MaterialTheme.cardBg(brillo);

        final material = tester.widget<Material>(
          find
              .ancestor(
                of: _enLaTarjeta(_cursoA, find.text(_cursoA)),
                matching: find.byType(Material),
              )
              .first,
        );
        expect(material.color, tarjeta);

        final texto = _estiloPintado(
          tester,
          _enLaTarjeta(_cursoA, find.text('Chat')),
        );
        expect(texto.color, MaterialTheme.textSecondary(brillo));
        expect(
          contrasteWcag(texto.color!, tarjeta),
          moreOrLessEquals(cifras.texto, epsilon: 0.01),
        );
        expect(contrasteWcag(texto.color!, tarjeta), greaterThanOrEqualTo(4.5));

        final icono = _estiloPintado(
          tester,
          _enLaTarjeta(_cursoA, find.byIcon(LucideIcons.messagesSquare)),
        );
        expect(icono.color, naranja);
        expect(icono.color, MaterialTheme.iconoNaranja(brillo));
        expect(
          contrasteWcag(icono.color!, tarjeta),
          moreOrLessEquals(cifras.icono, epsilon: 0.01),
        );
        expect(contrasteWcag(icono.color!, tarjeta), greaterThanOrEqualTo(3));

        semantica.dispose();
      });

      testWidgets('en $tema: la línea de la sección y la insignia de rol van '
          'en textSecondary y llegan a 4,5:1', (tester) async {
        final semantica = tester.ensureSemantics();
        await _abrirSecciones(tester, brillo: brillo);
        final tarjeta = MaterialTheme.cardBg(brillo);

        for (final curso in <String>[_cursoA, _cursoC]) {
          final linea = _estiloPintado(
            tester,
            _enLaTarjeta(curso, find.text(_lineas[curso]!)),
          );
          expect(
            linea.color,
            MaterialTheme.textSecondary(brillo),
            reason: curso,
          );
          expect(
            contrasteWcag(linea.color!, tarjeta),
            moreOrLessEquals(cifrasDeLaSeccion.codigo, epsilon: 0.01),
            reason: curso,
          );
          expect(
            contrasteWcag(linea.color!, tarjeta),
            greaterThanOrEqualTo(4.5),
            reason: curso,
          );
        }

        for (final (curso, rol) in <(String, String)>[
          (_cursoA, 'Profesor'),
          (_cursoC, 'JP'),
        ]) {
          final insignia = _enLaTarjeta(curso, find.text(rol));
          final texto = _estiloPintado(tester, insignia);
          expect(texto.color, MaterialTheme.textSecondary(brillo), reason: rol);
          final tinte =
              tester
                      .widget<Container>(
                        find
                            .ancestor(
                              of: insignia,
                              matching: find.byWidgetPredicate(
                                (w) => w is Container && w.decoration != null,
                              ),
                            )
                            .first,
                      )
                      .decoration!
                  as BoxDecoration;
          // El tinte es translúcido: lo que se ve es su mezcla con la tarjeta.
          final fondo = Color.alphaBlend(tinte.color!, tarjeta);
          expect(
            contrasteWcag(texto.color!, fondo),
            moreOrLessEquals(cifrasDeLaSeccion.insignia, epsilon: 0.01),
            reason: rol,
          );
          expect(
            contrasteWcag(texto.color!, fondo),
            greaterThanOrEqualTo(4.5),
            reason: rol,
          );
        }

        semantica.dispose();
      });
    }
  });

  group('WIDGET · tocar la tarjeta (RF-CHAT-13)', () {
    testWidgets('abre ChatPage con el código de la sección y '
        'courseAccentColor(sectionId) como color', (tester) async {
      final semantica = tester.ensureSemantics();
      await _abrirSecciones(tester);

      await tester.tap(_tarjeta(_cursoA));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final chat = tester.widget<ChatPage>(find.byType(ChatPage));
      expect(chat.sectionId, '301');
      expect(chat.courseName, _cursoA);
      expect(chat.sectionCode, '801');
      expect(chat.courseColor, courseAccentColor(301));
      expect(chat.courseColor, courseAccentColor(int.tryParse('301') ?? 0));
      final circulo = tester.widget<CursoAvatar>(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(CursoAvatar),
        ),
      );
      expect(circulo.color, courseAccentColor(301));
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Sección 801'),
        ),
        findsOneWidget,
      );

      semantica.dispose();
    });

    testWidgets('una sección sin código abre el chat con «Sin sección» y el '
        'acento de su id', (tester) async {
      final semantica = tester.ensureSemantics();
      // La premisa es que las dos secciones tienen acentos distintos.
      expect(courseAccentColor(305), isNot(courseAccentColor(301)));
      await _abrirSecciones(tester);

      await tester.tap(_tarjeta(_cursoC));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final chat = tester.widget<ChatPage>(find.byType(ChatPage));
      expect(chat.sectionId, '305');
      expect(chat.sectionCode, '');
      expect(chat.courseColor, courseAccentColor(305));
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Sin sección'),
        ),
        findsOneWidget,
      );

      semantica.dispose();
    });
  });
}
