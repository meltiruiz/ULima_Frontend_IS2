// test/splash/home_pestana_inicial_test.dart
//
// UNITARIA + WIDGET · Splash animado (specs/features/splash/splash.spec.md).
// RF-SPL-20 y BR-SHELL-F-02 de app-shell. Con el argumento
// {'pestana': 'horario'}, /home abre en Horario para todos los roles, sin él
// abre en la primera pestaña, y mientras la capa del arranque cubre la
// pantalla la app sigue en vertical.
// Archivo probado lib/pages/home/home_page.dart.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/footer/app_footer.dart';
import 'package:ulima_plus/models/advising_models.dart';
import 'package:ulima_plus/models/curso_delegado_model.dart';
import 'package:ulima_plus/models/portal_sync_models.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/delegado/delegado_cursos/delegado_cursos_controller.dart';
import 'package:ulima_plus/pages/home/home_controller.dart';
import 'package:ulima_plus/pages/home/home_page.dart';
import 'package:ulima_plus/pages/horario/horario.dart';
import 'package:ulima_plus/pages/horario/horario_controller.dart';
import 'package:ulima_plus/pages/malla/malla_list_controller.dart';
import 'package:ulima_plus/pages/malla/malla_list_page.dart';
import 'package:ulima_plus/pages/splash/estado_de_la_capa.dart';
import 'package:ulima_plus/pages/teacher/teacher_home_controller.dart';
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

UserModel _usuario(String rol, {String? etiqueta}) => UserModel(
  code: rol == 'teacher' ? 'docente.test' : '20230001',
  firstName: 'Persona',
  lastName: 'De Prueba',
  email: 'test@aloe.ulima.edu.pe',
  role: rol,
  teacherLabel: etiqueta,
  currentCycle: '2026-2',
  setupComplete: true,
);

const List<String> _soloVertical = <String>['DeviceOrientation.portraitUp'];
const List<String> _rotacionDelHorario = <String>[
  'DeviceOrientation.portraitUp',
  'DeviceOrientation.landscapeLeft',
  'DeviceOrientation.landscapeRight',
];

// --- Dobles -------------------------------------------------------------------

class _FakeAuthService extends AuthService {
  _FakeAuthService(UserModel user, {this.califica = false})
    : userRx = Rx<UserModel?>(user);

  final Rx<UserModel?> userRx;
  final bool califica;

  @override
  UserModel? get currentUser => userRx.value;

  @override
  Rx<UserModel?> get currentUserRx => userRx;

  @override
  bool get canGrade => califica;

  @override
  Future<void> refreshCurrentUser() async {}
}

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

class _PortalSinRed extends PortalSyncService {
  @override
  Future<PortalSyncStatus> status() async => PortalSyncStatus.desconocido;
}

class _MallaSinRed extends MallaService {
  @override
  Future<void> load() async => throw StateError('sin red');
}

class _AlertasSinRed extends AlertService {
  @override
  Future<void> fetchAlerts() async {}
}

class _DelegadoSinRed extends DelegateService {
  @override
  Future<List<CursoDelegado>> fetchDelegateSections() async =>
      <CursoDelegado>[];
}

class _AsesoriasSinRed extends AdvisingService {
  @override
  Future<List<TeacherSectionOption>> fetchSections() async =>
      <TeacherSectionOption>[];
}

// --- Montaje ------------------------------------------------------------------

final _orientaciones = <List<Object?>>[];

void _registrarDobles(UserModel usuario, {bool califica = false}) {
  Get.put<AuthService>(_FakeAuthService(usuario, califica: califica));
  Get.put<HomeController>(HomeController(portalSync: _PortalSinRed()));
  Get.put<HorarioController>(HorarioController(apiClient: _ApiSinRed()));
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

/// Abre /home como la intro, con Get.offAll, sin transición y con
/// [argumentos].
Future<void> _abrirHome(
  WidgetTester tester,
  UserModel usuario, {
  Object? argumentos,
  bool califica = false,
}) async {
  tester.view.physicalSize = const Size(800, 2800);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  _registrarDobles(usuario, califica: califica);
  await tester.pumpWidget(const GetMaterialApp(home: SizedBox.shrink()));
  Get.offAll<void>(
    () => const HomePage(),
    routeName: '/home',
    arguments: argumentos,
    transition: Transition.noTransition,
  );
  await tester.pump();
  await tester.pump();
}

Future<void> _desmontar(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  if (Get.isRegistered<HorarioController>()) {
    await Get.delete<HorarioController>(force: true);
  }
}

int _pestanaActual(WidgetTester tester) =>
    tester.widget<AppFooter>(find.byType(AppFooter)).currentIndex;

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
    EstadoDeLaCapa.cubre.value = false;
    _orientaciones.clear();
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
    EstadoDeLaCapa.cubre.value = false;
    Get.reset();
  });

  group('indiceDePestanaInicial (RF-SPL-20)', () {
    const alumno = ['Malla', 'Notas', 'Horario', 'Chats', 'Perfil'];
    const jefeDePractica = ['Secciones', 'Horario', 'Asesorias', 'Perfil'];

    test('con el argumento, la pestaña Horario por su etiqueta', () {
      expect(indiceDePestanaInicial(abrirEnHorario, alumno), 2);
      expect(indiceDePestanaInicial(abrirEnHorario, jefeDePractica), 1);
    });

    test('sin argumento o con otro valor, la primera', () {
      expect(indiceDePestanaInicial(null, alumno), 0);
      expect(indiceDePestanaInicial({'pestana': 'malla'}, alumno), 0);
      expect(indiceDePestanaInicial('horario', alumno), 0);
      expect(indiceDePestanaInicial(abrirEnHorario, ['Malla']), 0);
    });
  });

  group('WIDGET · la pestaña inicial (RF-SPL-20 y S-24)', () {
    final casos = <(String, UserModel, bool, int)>[
      ('el alumno', _usuario('student'), false, 2),
      ('el delegado', _usuario('delegado'), false, 2),
      ('el subdelegado', _usuario('subdelegado'), false, 2),
      (
        'el profesor titular',
        _usuario('teacher', etiqueta: 'Profesor'),
        true,
        2,
      ),
      ('el jefe de práctica', _usuario('teacher', etiqueta: 'JP'), false, 1),
    ];
    for (final (nombre, usuario, califica, indice) in casos) {
      testWidgets('$nombre abre en Horario con el argumento', (tester) async {
        await _abrirHome(
          tester,
          usuario,
          argumentos: abrirEnHorario,
          califica: califica,
        );
        expect(find.byType(HorarioPage), findsOneWidget);
        expect(_pestanaActual(tester), indice);
        expect(_orientaciones.last, _rotacionDelHorario);
        await _desmontar(tester);
      });
    }

    testWidgets('sin argumento abre en la primera pestaña, como hoy', (
      tester,
    ) async {
      await _abrirHome(tester, _usuario('student'));
      expect(find.byType(MallaListPage), findsOneWidget);
      expect(_pestanaActual(tester), 0);
      expect(_orientaciones.last, _soloVertical);
      await _desmontar(tester);
    });

    testWidgets('el docente sin argumento abre en Secciones', (tester) async {
      await _abrirHome(tester, _usuario('teacher', etiqueta: 'JP'));
      expect(find.byType(TeacherSectionsPage), findsOneWidget);
      await _desmontar(tester);
    });
  });

  group('WIDGET · la orientación bajo la capa (RF-SPL-20 y S-26)', () {
    testWidgets('abierta en Horario bajo la capa sigue en vertical y pide la '
        'rotación del horario cuando la capa se retira', (tester) async {
      EstadoDeLaCapa.cubre.value = true;
      await _abrirHome(tester, _usuario('student'), argumentos: abrirEnHorario);
      expect(find.byType(HorarioPage), findsOneWidget);
      expect(_orientaciones, isEmpty);

      EstadoDeLaCapa.cubre.value = false;
      await tester.pump();
      expect(_orientaciones.last, _rotacionDelHorario);
      await _desmontar(tester);
    });

    testWidgets('fuera de Horario bajo la capa pide la vertical al retirarse', (
      tester,
    ) async {
      EstadoDeLaCapa.cubre.value = true;
      await _abrirHome(tester, _usuario('student'));
      expect(_orientaciones, isEmpty);
      EstadoDeLaCapa.cubre.value = false;
      await tester.pump();
      expect(_orientaciones.last, _soloVertical);
      await _desmontar(tester);
    });
  });
}
