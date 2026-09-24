// test/HU23_jeff/chats_pestana_test.dart
//
// UNITARIA + WIDGET — HU23 (chat de sección): la pestaña Chats del alumno
// (RF-CHAT-5 y BR-SHELL-F-02 de app-shell).
// - El footer del alumno (Malla, Notas, Horario, Chats y Perfil), el del
//   delegado (con Delegado justo antes de Perfil) y el del docente, que no
//   cambia.
// - El shell: abre en Malla, Chats es vertical, «Horario» y «Asesorias» se
//   siguen encontrando por su etiqueta, entrar a Chats recarga el horario solo
//   si su controller ya existe, y la burbuja de Ulises sigue flotando sobre
//   Chats.
// - El tamaño de las etiquetas del footer: con las seis pestañas del
//   delegado, la activa va a 13 px y las demás a 12; con cinco o menos, la
//   activa sigue en 14 y las demás en 12.
// - El footer del delegado en 360 x 640 y en 375 x 667, medido con Roboto: las
//   seis etiquetas se leen completas y sin desborde con cualquiera de ellas
//   activa.
// Archivos: lib/pages/home/home_shell_config.dart,
// lib/pages/home/home_page.dart y lib/components/footer/app_footer.dart.
//
// Las etiquetas del footer se miden con Roboto, la fuente del tema en la
// plataforma de las pruebas, que se carga del propio SDK de Flutter (la ruta
// sale de FLUTTER_ROOT, que fija `flutter test`). Con la fuente de pruebas por
// omisión cada letra mide 1 em y ninguna medida de ancho significaría nada.
//
// El verde de estas pruebas vale para Android en 360 y en 375 dp. Con Roboto a
// 13 px, «Delegado» ocupa unos 56,6 dp y recibe 60 en un Android de 360 dp. La
// fuente del iPhone (SF) no viene con el SDK; en una medida local con SF a
// 13 px «Delegado» ocupa unos 60,4 pt de los 62,5 que recibe en el iPhone SE,
// y esa pantalla la confirma la revisión manual de «Verificación».
//
// Todos los datos son inventados; el repo es público. La alumna y el delegado
// usan el código sintético 20230001 y el docente es "docente.test".

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ulima_plus/components/chatbot_bubble.dart';
import 'package:ulima_plus/components/footer/app_footer.dart';
import 'package:ulima_plus/components/header/app_header.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/advising_models.dart';
import 'package:ulima_plus/models/curso_delegado_model.dart';
import 'package:ulima_plus/models/portal_sync_models.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/calculadora/calculadora_page.dart';
import 'package:ulima_plus/pages/chat/chats_inbox_page.dart';
import 'package:ulima_plus/pages/delegado/delegado_cursos/delegado_cursos_controller.dart';
import 'package:ulima_plus/pages/delegado/delegado_cursos/delegado_cursos_page.dart';
import 'package:ulima_plus/pages/home/home_controller.dart';
import 'package:ulima_plus/pages/home/home_page.dart';
import 'package:ulima_plus/pages/home/home_shell_config.dart';
import 'package:ulima_plus/pages/horario/horario.dart';
import 'package:ulima_plus/pages/horario/horario_controller.dart';
import 'package:ulima_plus/pages/malla/malla_list_controller.dart';
import 'package:ulima_plus/pages/malla/malla_list_page.dart';
import 'package:ulima_plus/pages/perfil/perfil.dart';
import 'package:ulima_plus/pages/teacher/teacher_home_controller.dart';
import 'package:ulima_plus/pages/teacher/teacher_home_page.dart';
import 'package:ulima_plus/pages/teacher/teacher_sections_controller.dart';
import 'package:ulima_plus/pages/teacher/teacher_sections_page.dart';
import 'package:ulima_plus/services/advising_service.dart';
import 'package:ulima_plus/services/alert_service.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/delegate_service.dart';
import 'package:ulima_plus/services/malla_service.dart';
import 'package:ulima_plus/services/portal_sync_service.dart';

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

UserModel _delegado() => UserModel(
  code: '20230001',
  firstName: 'Delegado',
  lastName: 'De Prueba',
  email: 'delegado.test@aloe.ulima.edu.pe',
  role: 'delegado',
  currentCycle: '2026-2',
  setupComplete: true,
);

UserModel _docente() => UserModel(
  code: 'docente.test',
  firstName: 'Docente',
  lastName: 'De Prueba',
  email: 'docente.test@ulima.edu.pe',
  role: 'teacher',
  teacherLabel: 'Profesor',
  currentCycle: '2026-2',
  setupComplete: true,
);

const List<String> _pestanasAlumno = <String>[
  'Malla',
  'Notas',
  'Horario',
  'Chats',
  'Perfil',
];

const List<String> _pestanasDelegado = <String>[
  'Malla',
  'Notas',
  'Horario',
  'Chats',
  'Delegado',
  'Perfil',
];

/// Lo que `SystemChrome.setPreferredOrientations` recibe en cada caso.
const List<String> _soloVertical = <String>['DeviceOrientation.portraitUp'];
const List<String> _rotacionDelHorario = <String>[
  'DeviceOrientation.portraitUp',
  'DeviceOrientation.landscapeLeft',
  'DeviceOrientation.landscapeRight',
];

// --- Dobles -------------------------------------------------------------------

class _FakeAuthService extends AuthService {
  _FakeAuthService(UserModel? user) : userRx = Rx<UserModel?>(user);

  final Rx<UserModel?> userRx;

  @override
  UserModel? get currentUser => userRx.value;

  @override
  Rx<UserModel?> get currentUserRx => userRx;

  /// Sin secciones de Profesor titular: el docente de estas pruebas no ve
  /// Calificar, y Asesorias queda en el índice 2.
  @override
  bool get canGrade => false;

  @override
  Future<void> refreshCurrentUser() async {}
}

/// Cliente sin red: responde un cuerpo vacío a todo.
class _ApiSinRed extends ApiClient {
  _ApiSinRed() : super(configuredBaseUrl: 'http://test');

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    String? token,
    Map<String, String?> query = const {},
    bool suppressSessionExpiry = false,
  }) async => <String, dynamic>{};
}

/// El controller del horario, con un contador de recargas.
class _HorarioEspia extends HorarioController {
  _HorarioEspia() : super(apiClient: _ApiSinRed());

  int recargas = 0;

  @override
  Future<void> reload() {
    recargas++;
    return super.reload();
  }
}

class _PortalSinRed extends PortalSyncService {
  @override
  Future<PortalSyncStatus> status() async => PortalSyncStatus.desconocido;
}

/// La malla no carga: su pantalla muestra el error, que para estas pruebas
/// basta.
class _MallaSinRed extends MallaService {
  @override
  Future<void> load() async => throw StateError('sin red');
}

/// Alertas sin red. En la app siempre están registradas, y la campana del
/// header las lee dentro de un `Obx`.
class _AlertasSinRed extends AlertService {
  @override
  Future<void> fetchAlerts() async {}
}

class _DelegadoSinRed extends DelegateService {
  @override
  Future<List<CursoDelegado>> fetchDelegateSections() async =>
      <CursoDelegado>[];
}

/// Las secciones del docente, sin red. TeacherHomeController crea su propio
/// AdvisingService y su carga falla sin romper nada.
class _AsesoriasSinRed extends AdvisingService {
  @override
  Future<List<TeacherSectionOption>> fetchSections() async =>
      <TeacherSectionOption>[];
}

// --- Montaje ------------------------------------------------------------------

/// Lo que la app le pidió a `SystemChrome.setPreferredOrientations`, en orden.
final _orientaciones = <List<Object?>>[];

/// Un iPhone SE en vertical (375 x 667).
void _telefonoVertical(WidgetTester tester) => _telefono(tester, 375, 667);

/// Un teléfono en vertical de [ancho] x [alto] puntos, a 2x.
void _telefono(WidgetTester tester, double ancho, double alto) {
  tester.view.physicalSize = Size(ancho * 2, alto * 2);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

/// Los anchos en que se mide el footer del delegado: un Android de 360 dp
/// (360 x 640) y el iPhone SE (375 x 667).
const List<(double, double)> _pantallasDelFooter = <(double, double)>[
  (360, 640),
  (375, 667),
];

/// Un teléfono en vertical más alto que el SE (400 x 1400), para el shell
/// entero. Con la fuente de pruebas, en la que cada letra mide 1 em, el aviso
/// de error de la malla no cabe en el alto que el SE le deja entre el header y
/// el footer, y lo que estas pruebas miran es la navegación, no ese aviso.
void _telefonoAlto(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2800);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

ThemeData _temaDeLaApp(Brightness brillo) {
  const tema = MaterialTheme(TextTheme());
  return brillo == Brightness.light ? tema.light() : tema.dark();
}

/// Registra lo que el shell y sus pestañas buscan con `Get.find`, cada cosa
/// sin red, para [usuario].
void _registrarDobles(UserModel usuario) {
  Get.put<AuthService>(_FakeAuthService(usuario));
  Get.put<HomeController>(HomeController(portalSync: _PortalSinRed()));
  if (usuario.isTeacher) {
    Get.put<TeacherSectionsController>(
      TeacherSectionsController(service: _AsesoriasSinRed()),
    );
    Get.put<TeacherHomeController>(TeacherHomeController());
  } else {
    Get.put<AlertService>(_AlertasSinRed());
    Get.put<MallaService>(_MallaSinRed());
    Get.put<MallaListController>(MallaListController());
    if (usuario.isDelegate) {
      Get.put<DelegadoCursosController>(
        DelegadoCursosController(delegateService: _DelegadoSinRed()),
      );
    }
  }
}

/// Monta el shell real de [usuario], con [horario] ya registrado si llega.
/// Sin `pumpAndSettle`: la burbuja de Ulises late sin fin.
Future<void> _abrirShell(
  WidgetTester tester,
  UserModel usuario, {
  HorarioController? horario,
}) async {
  _telefonoAlto(tester);
  _registrarDobles(usuario);
  if (horario != null) Get.put<HorarioController>(horario);
  await tester.pumpWidget(
    GetMaterialApp(
      theme: _temaDeLaApp(Brightness.light),
      home: const HomePage(),
    ),
  );
  await tester.pump();
}

Finder _pestana(String etiqueta) =>
    find.descendant(of: find.byType(AppFooter), matching: find.text(etiqueta));

Future<void> _tocarPestana(WidgetTester tester, String etiqueta) async {
  await tester.tap(_pestana(etiqueta));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Desmonta el árbol y borra el controller del horario, que arranca un
/// `Timer.periodic`.
Future<void> _desmontar(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  if (Get.isRegistered<HorarioController>()) {
    await Get.delete<HorarioController>(force: true);
  }
}

/// Carga Roboto del SDK de Flutter con el nombre de familia del tema.
Future<void> _cargarRoboto() async {
  final raiz = Platform.environment['FLUTTER_ROOT'];
  expect(
    raiz,
    isNotNull,
    reason: 'flutter test fija FLUTTER_ROOT; sin él no hay Roboto que medir',
  );
  final archivo = File(
    '$raiz/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
  );
  expect(archivo.existsSync(), isTrue, reason: archivo.path);
  final cargador = FontLoader('Roboto')
    ..addFont(
      Future<ByteData>.value(ByteData.sublistView(archivo.readAsBytesSync())),
    );
  await cargador.load();
}

/// Las seis pestañas del footer del delegado, como las arma el shell.
List<AppFooterItem> _footerDelDelegado() {
  Get.put<DelegadoCursosController>(
    DelegadoCursosController(delegateService: _DelegadoSinRed()),
  );
  return HomeShellConfig.student(_delegado()).footerItems;
}

/// Monta solo el footer con [items] y [activa] como pestaña activa. Si
/// [conTamano], antes fija el iPhone SE.
Future<void> _montarFooter(
  WidgetTester tester,
  List<AppFooterItem> items, {
  required int activa,
  bool conTamano = true,
}) async {
  if (conTamano) _telefonoVertical(tester);
  await tester.pumpWidget(
    GetMaterialApp(
      theme: _temaDeLaApp(Brightness.light),
      home: Scaffold(
        bottomNavigationBar: AppFooter(
          currentIndex: activa,
          items: items,
          onTap: (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// El tamaño con que se ve la etiqueta [etiqueta] del footer. El footer
/// compone cada etiqueta con el tamaño de la activa y achica las demás con
/// una transformación, así que el tamaño visible es el del texto por la escala
/// de esa transformación.
double _tamanoPintado(WidgetTester tester, String etiqueta) {
  final texto = _pestana(etiqueta);
  final estilo = tester
      .widget<RichText>(
        find.descendant(of: texto, matching: find.byType(RichText)),
      )
      .text
      .style!;
  final escala = tester
      .widget<Transform>(
        find.ancestor(of: texto, matching: find.byType(Transform)).first,
      )
      .transform
      .getMaxScaleOnAxis();
  return estilo.fontSize! * escala;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.reset();
    _orientaciones.clear();
    // Doble del canal de plataforma: responde a `setPreferredOrientations` y
    // anota lo pedido.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (llamada) async {
          if (llamada.method == 'SystemChrome.setPreferredOrientations') {
            _orientaciones.add(llamada.arguments as List<Object?>);
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    Get.reset();
  });

  group('UNITARIA · pestañas del footer (RF-CHAT-5, BR-SHELL-F-02)', () {
    test('el alumno ve Malla, Notas, Horario, Chats y Perfil', () {
      final config = HomeShellConfig.student(_alumna());

      expect(config.footerItems.map((i) => i.label), _pestanasAlumno);
      expect(config.pages, hasLength(_pestanasAlumno.length));
      expect(config.pages[0], isA<MallaListPage>());
      expect(config.pages[1], isA<CalculadoraPage>());
      expect(config.pages[2], isA<HorarioPage>());
      expect(config.pages[3], isA<ChatsInboxPage>());
      expect(config.pages[4], isA<ProfilePage>());
    });

    test('Chats lleva el ícono de conversación de Lucide', () {
      final config = HomeShellConfig.student(_alumna());
      final chats = config.footerItems.singleWhere((i) => i.label == 'Chats');

      expect(chats.icon, LucideIcons.messagesSquare);
    });

    test('el delegado ve Malla, Notas, Horario, Chats, Delegado y Perfil', () {
      Get.put<DelegadoCursosController>(
        DelegadoCursosController(delegateService: _DelegadoSinRed()),
      );
      final config = HomeShellConfig.student(_delegado());

      expect(config.footerItems.map((i) => i.label), _pestanasDelegado);
      expect(config.pages, hasLength(_pestanasDelegado.length));
      expect(config.pages[3], isA<ChatsInboxPage>());
      expect(config.pages[4], isA<DelegadoCursosPage>());
      expect(config.pages[5], isA<ProfilePage>());
    });

    test('el footer del docente no cambia y no tiene Chats', () {
      final conCalificar = HomeShellConfig.teacher(canGrade: true);
      expect(conCalificar.footerItems.map((i) => i.label), <String>[
        'Secciones',
        'Calificar',
        'Horario',
        'Asesorias',
        'Perfil',
      ]);
      expect(conCalificar.pages[0], isA<TeacherSectionsPage>());

      final sinCalificar = HomeShellConfig.teacher(canGrade: false);
      expect(sinCalificar.footerItems.map((i) => i.label), <String>[
        'Secciones',
        'Horario',
        'Asesorias',
        'Perfil',
      ]);
      expect(sinCalificar.pages.whereType<ChatsInboxPage>(), isEmpty);
      expect(conCalificar.pages.whereType<ChatsInboxPage>(), isEmpty);
    });
  });

  group('WIDGET · el shell con la pestaña Chats (RF-CHAT-5)', () {
    testWidgets('la app abre en Malla, en vertical', (tester) async {
      await _abrirShell(tester, _alumna());

      expect(find.byType(MallaListPage), findsOneWidget);
      expect(find.byType(ChatsInboxPage), findsNothing);
      expect(tester.widget<AppFooter>(find.byType(AppFooter)).currentIndex, 0);
      expect(
        tester
            .widget<AppFooter>(find.byType(AppFooter))
            .items
            .map((i) => i.label),
        _pestanasAlumno,
      );
      expect(_orientaciones.last, _soloVertical);

      await _desmontar(tester);
    });

    testWidgets('Chats muestra la bandeja y es vertical, aun viniendo de '
        'Horario', (tester) async {
      await _abrirShell(tester, _alumna());

      await _tocarPestana(tester, 'Horario');
      expect(find.byType(HorarioPage), findsOneWidget);
      expect(_orientaciones.last, _rotacionDelHorario);

      await _tocarPestana(tester, 'Chats');
      expect(find.byType(ChatsInboxPage), findsOneWidget);
      expect(find.byType(HorarioPage), findsNothing);
      expect(tester.widget<AppFooter>(find.byType(AppFooter)).currentIndex, 3);
      expect(_orientaciones.last, _soloVertical);

      await _desmontar(tester);
    });

    testWidgets('Horario no ofrece la vista de lista ni «Mis chats», y el '
        'header del alumno en Horario solo muestra la campana '
        '(schedule.spec.md)', (tester) async {
      await _abrirShell(tester, _alumna());

      await _tocarPestana(tester, 'Horario');
      expect(find.byType(HorarioPage), findsOneWidget);

      // Ni el texto de la lista ni los dos íconos del toggle que la
      // alternaba, en ninguna parte de la pantalla.
      expect(find.text('Mis chats'), findsNothing);
      expect(find.byIcon(Icons.format_list_bulleted), findsNothing);
      expect(find.byIcon(Icons.calendar_today), findsNothing);

      // En el header, la campana es el único ícono.
      final header = find.byType(AppHeader);
      expect(header, findsOneWidget);
      expect(
        find.descendant(
          of: header,
          matching: find.byIcon(Icons.notifications_none),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: header, matching: find.byType(Icon)),
        findsOneWidget,
      );

      await _desmontar(tester);
    });

    testWidgets('el shell sigue encontrando «Horario» por su etiqueta con '
        'Chats en el footer', (tester) async {
      final horario = _HorarioEspia();
      await _abrirShell(tester, _alumna(), horario: horario);

      await _tocarPestana(tester, 'Horario');

      // Horario es la tercera pestaña y Chats la cuarta: la rotación y la
      // recarga siguen siendo del horario.
      expect(find.byType(HorarioPage), findsOneWidget);
      expect(_orientaciones.last, _rotacionDelHorario);
      expect(horario.recargas, 1);

      await _desmontar(tester);
    });

    testWidgets('el shell del docente sigue encontrando «Asesorias» y '
        '«Horario» por su etiqueta', (tester) async {
      final horario = _HorarioEspia();
      await _abrirShell(tester, _docente(), horario: horario);

      expect(_pestana('Chats'), findsNothing);
      expect(find.byType(TeacherSectionsPage), findsOneWidget);

      await _tocarPestana(tester, 'Asesorias');
      expect(find.byType(TeacherHomePage), findsOneWidget);
      expect(horario.recargas, 0);

      // Volver de Asesorías recarga el horario del docente.
      await _tocarPestana(tester, 'Secciones');
      expect(horario.recargas, 1);

      await _tocarPestana(tester, 'Horario');
      expect(horario.recargas, 2);
      expect(_orientaciones.last, _rotacionDelHorario);

      await _desmontar(tester);
    });

    testWidgets('entrar a Chats llama a reload() si el controller ya está '
        'registrado', (tester) async {
      final horario = _HorarioEspia();
      await _abrirShell(tester, _alumna(), horario: horario);
      expect(horario.recargas, 0);

      await _tocarPestana(tester, 'Chats');

      expect(horario.recargas, 1);
      expect(find.byType(ChatsInboxPage), findsOneWidget);

      await _desmontar(tester);
    });

    testWidgets('la primera entrada a Chats no llama a reload(): el onInit '
        'del controller hace la carga', (tester) async {
      await _abrirShell(tester, _alumna());
      expect(Get.isRegistered<HorarioController>(), isFalse);

      // El toque llega a _onTabTap en el acto; la bandeja se construye en el
      // cuadro siguiente. Registrar el espía entre los dos lo deja como el
      // controller que la bandeja encuentra con Get.put.
      await tester.tap(_pestana('Chats'));
      expect(Get.isRegistered<HorarioController>(), isFalse);
      final horario = _HorarioEspia();
      Get.put<HorarioController>(horario);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ChatsInboxPage), findsOneWidget);
      expect(Get.find<HorarioController>(), same(horario));
      expect(horario.recargas, 0);

      await _desmontar(tester);
    });

    testWidgets('la burbuja de Ulises sigue flotando sobre Chats, fuera de la '
        'bandeja', (tester) async {
      await _abrirShell(tester, _alumna());

      await _tocarPestana(tester, 'Chats');

      expect(find.byType(ChatbotBubble), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ChatsInboxPage),
          matching: find.byType(ChatbotBubble),
        ),
        findsNothing,
      );

      await _desmontar(tester);
    });

    testWidgets('el delegado entra a Chats y a Delegado desde su footer', (
      tester,
    ) async {
      await _abrirShell(tester, _delegado());
      expect(
        tester
            .widget<AppFooter>(find.byType(AppFooter))
            .items
            .map((i) => i.label),
        _pestanasDelegado,
      );

      await _tocarPestana(tester, 'Chats');
      expect(find.byType(ChatsInboxPage), findsOneWidget);

      await _tocarPestana(tester, 'Delegado');
      expect(find.byType(DelegadoCursosPage), findsOneWidget);

      await _desmontar(tester);
    });
  });

  group('WIDGET · el tamaño de las etiquetas del footer (RF-CHAT-5)', () {
    testWidgets('con las seis pestañas del delegado, la activa va a 13 px y '
        'las demás a 12', (tester) async {
      await _montarFooter(tester, _footerDelDelegado(), activa: 4);

      final barra = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(barra.selectedFontSize, 13);
      expect(barra.unselectedFontSize, 12);
      for (final etiqueta in _pestanasDelegado) {
        expect(
          _tamanoPintado(tester, etiqueta),
          moreOrLessEquals(etiqueta == 'Delegado' ? 13 : 12),
          reason: etiqueta,
        );
      }
    });

    testWidgets('con las cinco pestañas del alumno, la activa sigue en 14 y '
        'las demás en 12', (tester) async {
      await _montarFooter(
        tester,
        HomeShellConfig.student(_alumna()).footerItems,
        activa: 3,
      );

      final barra = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(barra.selectedFontSize, 14);
      expect(barra.unselectedFontSize, 12);
      for (final etiqueta in _pestanasAlumno) {
        expect(
          _tamanoPintado(tester, etiqueta),
          moreOrLessEquals(etiqueta == 'Chats' ? 14 : 12),
          reason: etiqueta,
        );
      }
    });

    testWidgets('el footer del docente, con cinco o cuatro pestañas, también '
        'queda en 14 y 12', (tester) async {
      for (final canGrade in <bool>[true, false]) {
        final items = HomeShellConfig.teacher(canGrade: canGrade).footerItems;
        await _montarFooter(tester, items, activa: 0);

        final barra = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(barra.selectedFontSize, 14, reason: '${items.length} pestañas');
        expect(barra.unselectedFontSize, 12, reason: '${items.length}');
        expect(_tamanoPintado(tester, 'Secciones'), moreOrLessEquals(14));
        expect(_tamanoPintado(tester, 'Perfil'), moreOrLessEquals(12));
      }
    });
  });

  group('WIDGET · el footer del delegado en 360 x 640 y en 375 x 667, medido '
      'con Roboto (RF-CHAT-5)', () {
    // Solo Roboto: este verde vale para Android y no mide el iPhone SE, que
    // usa SF (ver el encabezado).
    setUpAll(_cargarRoboto);

    for (final (ancho, alto) in _pantallasDelFooter) {
      for (var activa = 0; activa < _pestanasDelegado.length; activa++) {
        testWidgets('a ${ancho.toInt()} de ancho, con '
            '«${_pestanasDelegado[activa]}» activa, las seis etiquetas se leen '
            'completas y sin desborde', (tester) async {
          _telefono(tester, ancho, alto);
          await _montarFooter(
            tester,
            _footerDelDelegado(),
            activa: activa,
            conTamano: false,
          );

          expect(tester.takeException(), isNull);
          expect(tester.getSize(find.byType(AppFooter)).width, ancho);
          expect(
            _tamanoPintado(tester, _pestanasDelegado[activa]),
            moreOrLessEquals(13),
          );

          for (final etiqueta in _pestanasDelegado) {
            final texto = _pestana(etiqueta);
            expect(texto, findsOneWidget, reason: etiqueta);
            final parrafo = tester.renderObject<RenderParagraph>(
              find.descendant(of: texto, matching: find.byType(RichText)),
            );

            // Cada pestaña recibe la sexta parte del ancho: 60 dp en 360 y
            // unos 62 en 375.
            expect(
              parrafo.constraints.maxWidth,
              moreOrLessEquals(ancho / 6, epsilon: 0.01),
              reason: etiqueta,
            );
            // La etiqueta entera, en una línea, cabe en ese ancho: ni se parte
            // ni lleva puntos suspensivos.
            final natural = TextPainter(
              text: parrafo.text,
              textDirection: TextDirection.ltr,
              textScaler: parrafo.textScaler,
            )..layout();
            expect(
              natural.width,
              lessThanOrEqualTo(parrafo.constraints.maxWidth),
              reason: '«$etiqueta» mide ${natural.width} px',
            );
            expect(parrafo.didExceedMaxLines, isFalse, reason: etiqueta);
            expect(
              parrafo.size.height,
              moreOrLessEquals(natural.height, epsilon: 0.5),
              reason: '«$etiqueta» ocupa una sola línea',
            );
            natural.dispose();

            // Y se pinta dentro de la pantalla.
            final caja = tester.getRect(texto);
            expect(caja.left, greaterThanOrEqualTo(0), reason: etiqueta);
            expect(caja.right, lessThanOrEqualTo(ancho), reason: etiqueta);
          }
        });
      }
    }
  });
}
