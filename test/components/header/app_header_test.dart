import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/header/app_header.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/alertas/alertas_page.dart';
import 'package:ulima_plus/pages/horario/horario_controller.dart';
import 'package:ulima_plus/services/alert_service.dart';
import 'package:ulima_plus/services/auth_service.dart';

UserModel _docente() => UserModel(
  code: 'docente.test',
  firstName: 'Docente',
  lastName: 'De Prueba',
  email: 'docente.test@ulima.edu.pe',
  role: 'teacher',
  currentCycle: '2026-1',
  setupComplete: true,
);

/// Alumna sintética; el repo es público.
UserModel _alumna() => UserModel(
  code: '20230001',
  firstName: 'Alumna',
  lastName: 'De Prueba',
  email: 'test@aloe.ulima.edu.pe',
  role: 'student',
  currentCycle: '2026-1',
  setupComplete: true,
);

class _FakeAuthService extends AuthService {
  _FakeAuthService(this.usuario);

  final UserModel usuario;

  @override
  UserModel? get currentUser => usuario;
}

/// Alertas sin red: la lista queda vacía.
class _AlertasSinRed extends AlertService {
  @override
  Future<void> fetchAlerts() async {}
}

/// Los dos íconos del toggle lista/calendario que tenía Horario.
final _iconosDelToggle = <IconData>[
  Icons.format_list_bulleted,
  Icons.calendar_today,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Lo que el header le pidió a `SystemChrome.setPreferredOrientations`.
  final orientaciones = <List<Object?>>[];

  setUp(() {
    Get.testMode = true;
    Get.reset();
    orientaciones.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (llamada) async {
          if (llamada.method == 'SystemChrome.setPreferredOrientations') {
            orientaciones.add(llamada.arguments as List<Object?>);
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    Get.reset();
  });

  testWidgets(
    'al pulsar ULIMA++ solicita abrir la promoción exacta fuera de la app',
    (tester) async {
      Get.put<AuthService>(_FakeAuthService(_docente()));
      Uri? launchedUri;
      var launchCalls = 0;

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: AppHeader(
              linkLauncher: (uri) async {
                launchCalls++;
                launchedUri = uri;
                return true;
              },
            ),
          ),
        ),
      );

      // El test pulsa el mismo texto que ve el usuario; el launcher inyectado
      // captura la URI y evita abrir un navegador real durante la prueba.
      await tester.tap(find.text('ULIMA++'));
      await tester.pump();

      expect(launchCalls, 1);
      expect(
        launchedUri.toString(),
        'https://www.donbelisario.com.pe/clasico-combo-contundente?'
        'gsImpressionId=01KXPTTES6C5C0S9FKJG902C2G&'
        'gsListName=Recomendaciones%20-%20Promociones&gsIndex=3',
      );
      expect(
        find.bySemanticsLabel('Abrir promoción de Don Belisario'),
        findsOneWidget,
      );
    },
  );

  group('BR-SHELL-F-03 · controles del header', () {
    for (final enHorario in <bool>[true, false]) {
      testWidgets('el header del alumno solo muestra la campana '
          '${enHorario ? 'en Horario' : 'fuera de Horario'}, sin el toggle '
          'lista/calendario', (tester) async {
        Get.put<AuthService>(_FakeAuthService(_alumna()));
        // En la app siempre están registradas: la campana las lee dentro de
        // un Obx.
        Get.put<AlertService>(_AlertasSinRed());

        await tester.pumpWidget(
          GetMaterialApp(
            home: Scaffold(body: AppHeader(isScheduleTab: enHorario)),
          ),
        );
        await tester.pump();

        for (final icono in _iconosDelToggle) {
          expect(find.byIcon(icono), findsNothing, reason: '$icono');
        }
        expect(find.byIcon(Icons.notifications_none), findsOneWidget);
        // El header ya no registra el controller del horario para el toggle.
        expect(Get.isRegistered<HorarioController>(), isFalse);
      });
    }

    testWidgets('el header del docente sigue sin controles a la derecha', (
      tester,
    ) async {
      Get.put<AuthService>(_FakeAuthService(_docente()));

      await tester.pumpWidget(
        GetMaterialApp(home: Scaffold(body: AppHeader(isScheduleTab: true))),
      );
      await tester.pump();

      for (final icono in _iconosDelToggle) {
        expect(find.byIcon(icono), findsNothing, reason: '$icono');
      }
      expect(find.byIcon(Icons.notifications_none), findsNothing);
      expect(Get.isRegistered<HorarioController>(), isFalse);
    });

    testWidgets('en Horario, al volver de las alertas devuelve la rotación del '
        'horario', (tester) async {
      Get.put<AuthService>(_FakeAuthService(_alumna()));
      Get.put<AlertService>(_AlertasSinRed());

      await tester.pumpWidget(
        GetMaterialApp(home: Scaffold(body: AppHeader(isScheduleTab: true))),
      );
      await tester.tap(find.byIcon(Icons.notifications_none));
      await tester.pumpAndSettle();

      expect(find.byType(AlertasPage), findsOneWidget);
      expect(orientaciones, <List<Object?>>[
        <String>['DeviceOrientation.portraitUp'],
      ]);

      Get.back<void>();
      await tester.pumpAndSettle();

      expect(orientaciones.last, <String>[
        'DeviceOrientation.portraitUp',
        'DeviceOrientation.landscapeLeft',
        'DeviceOrientation.landscapeRight',
      ]);
    });

    testWidgets('fuera de Horario, al volver de las alertas sigue en '
        'vertical', (tester) async {
      Get.put<AuthService>(_FakeAuthService(_alumna()));
      Get.put<AlertService>(_AlertasSinRed());

      await tester.pumpWidget(
        GetMaterialApp(home: Scaffold(body: AppHeader())),
      );
      await tester.tap(find.byIcon(Icons.notifications_none));
      await tester.pumpAndSettle();
      Get.back<void>();
      await tester.pumpAndSettle();

      expect(orientaciones, <List<Object?>>[
        <String>['DeviceOrientation.portraitUp'],
      ]);
    });
  });
}
