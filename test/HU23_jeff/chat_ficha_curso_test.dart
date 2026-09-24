// test/HU23_jeff/chat_ficha_curso_test.dart
//
// WIDGET — HU23 (chat de sección): «Chat del curso» en la ficha del curso
// (RF-CHAT-7).
// - La franja de la sección pasa a una fila con «Sección: N» a la izquierda,
//   sin cambiar, y a la derecha el botón «Chat del curso» con
//   LucideIcons.messagesSquare. La franja crece solo hasta el blanco táctil de
//   48 px y el resto de la ficha no cambia de orden.
// - El botón es de contorno, con el fondo y el borde de tarjeta, el texto en
//   textPrimary y el ícono en el naranja de un ícono (primaryDark en claro y
//   primaryColor en oscuro), con 4,5:1 para el texto y 3:1 para el ícono en
//   los dos temas.
// - El botón abre ChatPage con seccion.curso, seccion.codigoSeccion y el color
//   que recibe la ficha; sin color, ChatPage usa su respaldo. Al volver, la
//   ficha sigue igual y en la misma pestaña.
// - La grilla del horario le pasa a la ficha colorPorCurso[idSeccion].
// Archivos: lib/pages/descripcion_cursos/descrip_cursos.dart y
// lib/pages/horario/horario.dart.
//
// Todos los datos son inventados; el repo es público. La alumna es la
// 20230001 y el curso es «CURSO DE PRUEBA A», sección 801.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ulima_plus/configs/course_colors.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/seccion_model.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/chat/chat_linea_tiempo.dart';
import 'package:ulima_plus/pages/chat/chat_page.dart';
import 'package:ulima_plus/pages/chat/curso_avatar.dart';
import 'package:ulima_plus/pages/descripcion_cursos/asesoria_tab.dart';
import 'package:ulima_plus/pages/descripcion_cursos/contactos_tab.dart';
import 'package:ulima_plus/pages/descripcion_cursos/descrip_cursos.dart';
import 'package:ulima_plus/pages/descripcion_cursos/descrip_cursos_controller.dart';
import 'package:ulima_plus/pages/horario/horario.dart';
import 'package:ulima_plus/pages/horario/horario_controller.dart';
import 'package:ulima_plus/services/auth_service.dart';

import 'chat_repo_falso.dart';

// --- Datos inventados ---------------------------------------------------------

UserModel _alumna() => UserModel(
  code: '20230001',
  firstName: 'Alumna',
  lastName: 'De Prueba',
  email: 'test@aloe.ulima.edu.pe',
  role: 'student',
  currentCycle: '2026-2',
  setupComplete: true,
);

const String _curso = 'CURSO DE PRUEBA A';

/// La sección de la ficha, con id 301, código 801 y sin asistencia cargada.
Seccion _seccion() => Seccion.fromJson(<String, dynamic>{
  'idSeccion': '301',
  'codigoSeccion': '801',
  'curso': _curso,
  'asistenciaDisponible': false,
});

/// Un morado de la paleta, distinto del acento de la sección 301, para que el
/// color recibido y el respaldo de ChatPage no se confundan.
const Color _morado = Color(0xFF9B51E0);

// --- Dobles -------------------------------------------------------------------

class _FakeAuthService extends AuthService {
  _FakeAuthService(UserModel? user) : userRx = Rx<UserModel?>(user);

  final Rx<UserModel?> userRx;

  @override
  UserModel? get currentUser => userRx.value;

  @override
  Rx<UserModel?> get currentUserRx => userRx;

  @override
  Future<void> refreshCurrentUser() async {}
}

/// El controller de la ficha sin red. `DescripCursosPage` hace
/// `Get.put(DescripCursosController())` al construirse y GetX no reemplaza
/// una instancia ya registrada, así que usa esta. La carga pone la sección
/// fija y cuenta cuántas veces la piden; las pestañas no piden nada.
class _FichaSinRed extends DescripCursosController {
  _FichaSinRed({this.conSeccion = true});

  final bool conSeccion;
  int cargas = 0;

  @override
  Future<void> cargarDatosCurso(String idSeccion) async {
    cargas++;
    if (!conSeccion) return;
    final seccion = _seccion();
    seccionActual.value = seccion;
    secciones.value = <Seccion>[seccion];
  }

  @override
  Future<void> fetchAnuncios(String idSeccion) async {}

  @override
  Future<void> fetchAsesorias(String idSeccion) async {}

  @override
  Future<void> fetchContactos(String idSeccion) async {}
}

/// El controller del horario sin su carga remota, con una clase el lunes de
/// cada sección de [clases] y [colores] en lugar del reparto de la paleta.
class _HorarioDePrueba extends HorarioController {
  _HorarioDePrueba({required this.clases, required this.colores}) {
    // La semana del lunes 21 al domingo 27 de septiembre de 2026, como la
    // arma el backend; la grilla abre en el lunes.
    daysList.assignAll(<DaySchedule>[
      for (final (nombre, dia) in const <(String, int)>[
        ('Lunes', 21),
        ('Martes', 22),
        ('Miércoles', 23),
        ('Jueves', 24),
        ('Viernes', 25),
        ('Sábado', 26),
        ('Domingo', 27),
      ])
        DaySchedule(
          nombre,
          '$dia de Septiembre',
          'Semana 5 del ciclo',
          isoDate: '2026-09-$dia',
        ),
    ]);
    currentLimaTime.value = DateTime.utc(2026, 9, 1, 10);
  }

  final List<Map<String, dynamic>> clases;
  final Map<String, Color> colores;

  @override
  // ignore: must_call_super
  void onInit() {
    // Sin el onInit real, que arranca un Timer.periodic y pide el horario con
    // un ApiClient propio.
  }

  @override
  Map<String, Color> get colorPorCurso => colores;

  @override
  List<Map<String, dynamic>> coursesForDay(DaySchedule activeDay) =>
      activeDay.dayName == 'Lunes' ? clases : const <Map<String, dynamic>>[];
}

/// Una clase como la devuelve `coursesForDay`, con las horas en 12 h como
/// las manda `/schedule/me/sessions`.
Map<String, dynamic> _clase(
  String idSeccion,
  String curso,
  String inicio,
  String fin,
) => <String, dynamic>{
  'idSeccion': idSeccion,
  'codigoSeccion': '801',
  'curso': curso,
  'hora_inicio': inicio,
  'hora_fin': fin,
  'salon': 'AULA 801',
  'color': '#2F80ED',
  'isEvaluation': false,
  'isAdvising': false,
};

// --- Montaje ------------------------------------------------------------------

ThemeData _temaDeLaApp(Brightness brillo) {
  const tema = MaterialTheme(TextTheme());
  return brillo == Brightness.light ? tema.light() : tema.dark();
}

/// El ancho de un iPhone SE (375), con alto de sobra, porque con la fuente
/// de pruebas cada letra mide 1 em, los textos de la asistencia se parten en
/// muchas líneas y la ficha entera no cabe en 667 de alto. Lo que se mide es
/// el ancho de la franja.
void _anchoDelSE(WidgetTester tester) {
  tester.view.physicalSize = const Size(750, 2800);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

/// Monta la ficha de la sección 301 con [color], como la abre la grilla. Por
/// omisión la pantalla es la de las pruebas (800 x 600), donde «Sección: 801»
/// cabe en una línea con la fuente de pruebas, en la que cada letra mide 1 em.
Future<_FichaSinRed> _abrirFicha(
  WidgetTester tester, {
  Brightness brillo = Brightness.light,
  Color? color,
  ChatRepoFalso? repo,
}) async {
  final control = Get.put<DescripCursosController>(_FichaSinRed());
  await tester.pumpWidget(
    GetMaterialApp(
      theme: _temaDeLaApp(brillo),
      home: DescripCursosPage(
        idSeccion: '301',
        courseColor: color,
        chatRepository: repo ?? ChatRepoFalso(session: sesionDelegado),
      ),
    ),
  );
  await tester.pump();
  return control as _FichaSinRed;
}

/// Toca «Chat del curso» y deja que ChatPage entre y conecte.
Future<void> _abrirChat(WidgetTester tester) async {
  await tester.tap(_boton());
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

/// El botón «Chat del curso».
Finder _boton() =>
    find.ancestor(of: find.text('Chat del curso'), matching: _botonDeContorno);

final Finder _botonDeContorno = find.byWidgetPredicate(
  (w) => w is OutlinedButton,
);

/// La franja de la sección, que es la caja del color `bloqueSeccion` que
/// envuelve a «Sección: 801». Un `Container` con color también pinta con un
/// `ColoredBox`.
Finder _franja(Brightness brillo) => find.ancestor(
  of: find.text('Sección: 801'),
  matching: find.byWidgetPredicate(
    (w) => w is ColoredBox && w.color == MaterialTheme.bloqueSeccion(brillo),
  ),
);

/// Dónde empiezan, en la pantalla, las letras que pinta [texto].
double _inicioDeLasLetras(WidgetTester tester, Finder texto) {
  final parrafo = tester.renderObject<RenderParagraph>(
    find.descendant(of: texto, matching: find.byType(RichText)).first,
  );
  final cajas = parrafo.getBoxesForSelection(
    TextSelection(
      baseOffset: 0,
      extentOffset: parrafo.text.toPlainText().length,
    ),
  );
  return parrafo.localToGlobal(Offset(cajas.first.left, 0)).dx;
}

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

  group('WIDGET · la franja de la sección (RF-CHAT-7)', () {
    testWidgets('«Sección: N» va a la izquierda, sin cambiar, y el botón «Chat '
        'del curso» con LucideIcons.messagesSquare a la derecha', (
      tester,
    ) async {
      await _abrirFicha(tester);
      const brillo = Brightness.light;

      final franja = _franja(brillo);
      expect(franja, findsOneWidget);
      final seccion = find.text('Sección: 801');
      expect(seccion, findsOneWidget);
      expect(_boton(), findsOneWidget);
      expect(find.descendant(of: franja, matching: _boton()), findsOneWidget);
      expect(
        find.descendant(
          of: _boton(),
          matching: find.byIcon(LucideIcons.messagesSquare),
        ),
        findsOneWidget,
      );

      // El texto se corre a la izquierda, con el mismo margen que el título y
      // la asistencia, y el botón queda al otro extremo. Se mide donde se
      // pintan las letras y no la caja del texto, que puede ocupar todo el
      // ancho libre y llevar las letras centradas. La primera letra deja
      // además un margen propio de la fuente, menor que 1 px.
      final izquierda = tester.getTopLeft(franja).dx;
      final derecha = tester.getTopRight(franja).dx;
      expect(
        _inicioDeLasLetras(tester, seccion) - izquierda,
        moreOrLessEquals(20, epsilon: 1),
      );
      expect(derecha - tester.getTopRight(_boton()).dx, moreOrLessEquals(20));
      expect(
        tester.getCenter(seccion).dy,
        moreOrLessEquals(tester.getCenter(_boton()).dy),
      );

      // Sin cambiar quiere decir el mismo texto, en onSurface y seminegrita.
      final estilo = _estiloPintado(tester, seccion);
      expect(estilo.color, _temaDeLaApp(brillo).colorScheme.onSurface);
      expect(estilo.fontWeight, FontWeight.w600);
    });

    testWidgets('el botón es un blanco táctil de 48 px y la franja crece solo '
        'hasta ahí', (tester) async {
      final semantica = tester.ensureSemantics();
      await _abrirFicha(tester);

      expect(tester.getSize(_boton()).height, 48);
      expect(tester.getSize(_franja(Brightness.light)).height, 48);

      final nodo = find.bySemanticsLabel('Chat del curso');
      expect(
        tester.getSemantics(nodo),
        isSemantics(
          label: 'Chat del curso',
          isButton: true,
          hasTapAction: true,
        ),
      );
      final area = tester.getSemantics(nodo).rect;
      expect(area.height, greaterThanOrEqualTo(48));
      expect(area.width, greaterThanOrEqualTo(48));

      semantica.dispose();
    });

    testWidgets('el resto de la ficha no cambia de orden: título, franja, '
        'asistencia y pestañas', (tester) async {
      await _abrirFicha(tester);

      final alturas = [
        tester.getCenter(find.text(_curso)).dy,
        tester.getCenter(find.text('Sección: 801')).dy,
        tester.getCenter(find.text('Asistencia')).dy,
        tester.getCenter(find.text('Anuncios')).dy,
      ];
      for (var i = 1; i < alturas.length; i++) {
        expect(alturas[i], greaterThan(alturas[i - 1]));
      }
      // La asistencia empieza justo debajo de la franja.
      expect(
        tester.getTopLeft(find.text('Asistencia')).dy -
            tester.getBottomLeft(_franja(Brightness.light)).dy,
        moreOrLessEquals(20),
      );
    });

    testWidgets('en el ancho de un iPhone SE la franja entra sin desborde y el '
        'botón se lee completo', (tester) async {
      _anchoDelSE(tester);
      await _abrirFicha(tester);

      expect(tester.takeException(), isNull);
      expect(tester.getTopRight(_boton()).dx, lessThanOrEqualTo(375));
      final texto = tester.widget<Text>(find.text('Chat del curso'));
      expect(texto.overflow, isNot(TextOverflow.ellipsis));
      expect(texto.maxLines, isNull);
    });

    testWidgets('mientras la sección no carga, la ficha no muestra el botón', (
      tester,
    ) async {
      Get.put<DescripCursosController>(_FichaSinRed(conSeccion: false));
      await tester.pumpWidget(
        GetMaterialApp(
          theme: _temaDeLaApp(Brightness.light),
          home: DescripCursosPage(idSeccion: '301'),
        ),
      );
      // Sin pumpAndSettle, porque el esqueleto de carga anima sin fin.
      await tester.pump();

      expect(find.text('Chat del curso'), findsNothing);
    });
  });

  group('WIDGET · colores del botón (RF-CHAT-7)', () {
    for (final brillo in Brightness.values) {
      final tema = brillo == Brightness.light ? 'claro' : 'oscuro';
      // Las cifras de la spec contra el fondo del botón, cardBg.
      final cifras = brillo == Brightness.light
          ? (texto: 17.85, icono: 4.12)
          : (texto: 14.22, icono: 5.65);
      final naranja = brillo == Brightness.light
          ? MaterialTheme.primaryDark
          : MaterialTheme.primaryColor;

      testWidgets('en $tema: botón de contorno con el fondo y el borde de '
          'tarjeta, texto en textPrimary e ícono naranja, con su contraste', (
        tester,
      ) async {
        await _abrirFicha(tester, brillo: brillo);
        final tarjeta = MaterialTheme.cardBg(brillo);

        final material = tester.widget<Material>(
          find.descendant(of: _boton(), matching: find.byType(Material)).first,
        );
        expect(material.color, tarjeta);
        final forma = material.shape! as OutlinedBorder;
        expect(forma.side.color, MaterialTheme.borderColor(brillo));
        expect(forma.side.style, BorderStyle.solid);

        final texto = _estiloPintado(tester, find.text('Chat del curso'));
        expect(texto.color, MaterialTheme.textPrimary(brillo));
        expect(
          contrasteWcag(texto.color!, tarjeta),
          moreOrLessEquals(cifras.texto, epsilon: 0.01),
        );
        expect(contrasteWcag(texto.color!, tarjeta), greaterThanOrEqualTo(4.5));

        final icono = _estiloPintado(
          tester,
          find.byIcon(LucideIcons.messagesSquare),
        );
        expect(icono.color, naranja);
        expect(
          contrasteWcag(icono.color!, tarjeta),
          moreOrLessEquals(cifras.icono, epsilon: 0.01),
        );
        expect(contrasteWcag(icono.color!, tarjeta), greaterThanOrEqualTo(3));
      });
    }
  });

  group('WIDGET · abrir el chat desde la ficha (RF-CHAT-7)', () {
    testWidgets('abre ChatPage con seccion.curso, seccion.codigoSeccion y el '
        'color que recibe la ficha', (tester) async {
      await _abrirFicha(tester, color: _morado);

      await _abrirChat(tester);

      final chat = tester.widget<ChatPage>(find.byType(ChatPage));
      expect(chat.sectionId, '301');
      expect(chat.courseName, _curso);
      expect(chat.sectionCode, '801');
      expect(chat.courseColor, _morado);
      final circulo = tester.widget<CursoAvatar>(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(CursoAvatar),
        ),
      );
      expect(circulo.color, _morado);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Sección 801'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('sin color, ChatPage usa su respaldo, el acento de la '
        'sección', (tester) async {
      // La premisa es que el respaldo no es el morado de la otra prueba.
      expect(courseAccentColor(301), isNot(_morado));
      await _abrirFicha(tester);

      await _abrirChat(tester);

      final chat = tester.widget<ChatPage>(find.byType(ChatPage));
      expect(chat.courseColor, isNull);
      final circulo = tester.widget<CursoAvatar>(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(CursoAvatar),
        ),
      );
      expect(circulo.color, courseAccentColor(301));
    });

    for (final (pestana, indice, vista) in <(String, int, Type)>[
      ('Asesorías', 1, AsesoriasTab),
      ('Contactos', 2, ContactosTab),
    ]) {
      testWidgets('al volver del chat, la ficha sigue igual y en $pestana', (
        tester,
      ) async {
        final control = await _abrirFicha(tester, color: _morado);
        await tester.tap(find.text(pestana));
        await tester.pump();
        expect(control.selectedTab.value, indice);

        await _abrirChat(tester);
        expect(find.byType(ChatPage), findsOneWidget);

        await tester.tap(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.byIcon(Icons.arrow_back),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(ChatPage), findsNothing);
        expect(find.byType(DescripCursosPage), findsOneWidget);
        expect(control.selectedTab.value, indice);
        expect(find.byType(vista), findsOneWidget);
        expect(find.text('Chat del curso'), findsOneWidget);
        // La ficha no se vuelve a cargar al volver.
        expect(control.cargas, 1);
        expect(Get.find<DescripCursosController>(), same(control));
      });
    }
  });

  group('WIDGET · la grilla le pasa el color a la ficha (RF-CHAT-7)', () {
    final orientaciones = <Object?>[];

    setUp(() {
      orientaciones.clear();
      // Sin este doble, `setPreferredOrientations` espera una respuesta que
      // en la prueba no llega.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (llamada) async {
            orientaciones.add(llamada.method);
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    /// Monta el horario de la alumna con [clases] y [colores], y toca la clase
    /// de [curso].
    Future<DescripCursosPage> tocarClase(
      WidgetTester tester, {
      required List<Map<String, dynamic>> clases,
      required Map<String, Color> colores,
      required String curso,
    }) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      Get.put<AuthService>(_FakeAuthService(_alumna()));
      Get.put<HorarioController>(
        _HorarioDePrueba(clases: clases, colores: colores),
      );
      Get.put<DescripCursosController>(_FichaSinRed(conSeccion: false));
      await tester.pumpWidget(const GetMaterialApp(home: HorarioPage()));
      await tester.pump();

      await tester.tap(
        find.ancestor(of: find.text(curso), matching: find.byType(InkWell)),
      );
      await tester.pump();
      // Sin pumpAndSettle, porque la ficha sin datos pinta un esqueleto que
      // anima sin fin.
      await tester.pump(const Duration(seconds: 1));

      return tester.widget<DescripCursosPage>(find.byType(DescripCursosPage));
    }

    testWidgets('tocar una clase abre la ficha con colorPorCurso[idSeccion], '
        'el mismo color de su bloque', (tester) async {
      final ficha = await tocarClase(
        tester,
        clases: [
          _clase('301', _curso, '08:00 am', '10:00 am'),
          _clase('303', 'CURSO DE PRUEBA B', '11:00 am', '01:00 pm'),
        ],
        colores: const <String, Color>{
          '301': _morado,
          '303': Color(0xFF27AE60),
        },
        curso: _curso,
      );

      expect(ficha.idSeccion, '301');
      expect(ficha.courseColor, _morado);
    });

    testWidgets('una clase sin color en colorPorCurso abre la ficha sin color, '
        'para que ChatPage use su respaldo', (tester) async {
      final ficha = await tocarClase(
        tester,
        clases: [_clase('301', _curso, '08:00 am', '10:00 am')],
        colores: const <String, Color>{'303': Color(0xFF27AE60)},
        curso: _curso,
      );

      expect(ficha.idSeccion, '301');
      expect(ficha.courseColor, isNull);
    });
  });
}
