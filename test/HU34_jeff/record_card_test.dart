import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/academic_record/record_format.dart';
import 'package:ulima_plus/pages/academic_record/record_position_badge.dart';
import 'package:ulima_plus/pages/academic_record/record_profile_card.dart';
import 'package:ulima_plus/pages/perfil/perfil.dart';
import 'package:ulima_plus/services/academic_record_service.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/auth_service.dart';

/// Récord académico: formato puro de la tarjeta del Perfil (RF-REC-1) y del
/// encabezado de la pantalla (RF-REC-2).
///
/// La barra de la tarjeta y el anillo de la pantalla usan la misma
/// `creditsProgress`, así que sus guardas se prueban una sola vez aquí: si
/// falta un dato o los requeridos son 0 o menos, no se dibuja nada; y un 0
/// acumulado es un dato real, no un dato que falta. Todos los valores son
/// inventados.
///
/// El grupo WIDGET monta además la tarjeta del Perfil (RF-REC-1) y comprueba
/// que tras borrar o recargar nunca se ve el récord anterior (RF-REC-5).
void main() {
  // Get.put de un GetxService agenda onReady con
  // Get.engine.addPostFrameCallback, que necesita el binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UNITARIA · creditsProgress (RF-REC-1)', () {
    test('164 de 200 da la proporción exacta, sin redondear', () {
      expect(creditsProgress(164, 200), closeTo(164 / 200, 1e-12));
    });

    test('sin un dato o con requeridos en 0 o menos da null: no hay barra ni anillo', () {
      expect(creditsProgress(null, 200), isNull);
      expect(creditsProgress(164, null), isNull);
      expect(creditsProgress(null, null), isNull);
      expect(creditsProgress(164, 0), isNull);
      expect(creditsProgress(164, -5), isNull);
    });

    test('0 créditos acumulados es un dato real: da 0.0, no null', () {
      expect(creditsProgress(0, 200), 0.0);
    });

    test('acumulados mayores que requeridos se recortan a 1.0', () {
      expect(creditsProgress(230, 200), 1.0);
    });

    test('los decimales entran tal cual: 1.5 de 3 es 0.5', () {
      expect(creditsProgress(1.5, 3), 0.5);
    });

    test('un acumulado negativo se recorta a 0.0', () {
      expect(creditsProgress(-3, 200), 0.0);
    });
  });

  group('UNITARIA · formatDecimal y créditos', () {
    test('un valor entero se muestra sin ".0"', () {
      expect(formatDecimal(3.0), '3');
      expect(formatDecimal(164.0), '164');
      expect(formatDecimal(0.0), '0');
    });

    test('un decimal se muestra tal cual, sin redondear', () {
      expect(formatDecimal(1.5), '1.5');
      expect(formatDecimal(14.62), '14.62');
    });

    test('creditsShortLabel: "1.5 créd." y "3 créd."', () {
      expect(creditsShortLabel(1.5), '1.5 créd.');
      expect(creditsShortLabel(3.0), '3 créd.');
    });

    test('creditsOfRequiredLabel arma "N de M créditos" con los valores sin recortar', () {
      expect(creditsOfRequiredLabel(164, 200), '164 de 200 créditos');
      expect(creditsOfRequiredLabel(164.5, 200), '164.5 de 200 créditos');
      expect(creditsOfRequiredLabel(230, 200), '230 de 200 créditos');
    });

    test('creditsOfRequiredLabel tiene las mismas guardas que la barra', () {
      expect(creditsOfRequiredLabel(null, 200), isNull);
      expect(creditsOfRequiredLabel(168, null), isNull);
      expect(creditsOfRequiredLabel(168, 0), isNull);
      expect(creditsOfRequiredLabel(168, -5), isNull);
    });
  });

  group('UNITARIA · formatRelativePosition', () {
    test('las mayúsculas del portal pasan a tipo oración', () {
      expect(formatRelativePosition('TERCIO SUPERIOR'), 'Tercio superior');
    });

    test('los espacios de más se recortan', () {
      expect(formatRelativePosition('medio  superior'), 'Medio superior');
      expect(formatRelativePosition('  TERCIO SUPERIOR  '), 'Tercio superior');
    });

    test('sin dato o en blanco da null: no hay insignia', () {
      expect(formatRelativePosition(null), isNull);
      expect(formatRelativePosition(''), isNull);
      expect(formatRelativePosition('   '), isNull);
    });
  });

  group('UNITARIA · progressPercentLabel', () {
    test('el porcentaje del anillo se redondea al entero', () {
      expect(progressPercentLabel(0.8195), '82%');
      expect(progressPercentLabel(1.0), '100%');
      expect(progressPercentLabel(0.0), '0%');
    });

    test('el anillo sale de creditsProgress: 164 de 200 muestra 82%', () {
      expect(progressPercentLabel(creditsProgress(164, 200)!), '82%');
    });
  });

  group('WIDGET · RecordProfileCard (RF-REC-1, RF-REC-5)', () {
    setUp(() {
      Get.testMode = true;
      Get.reset();
    });

    tearDown(Get.reset);

    testWidgets('con récord muestra PPA, insignia, créditos y el enlace', (
      tester,
    ) async {
      await _montarTarjeta(tester, [_syncedJson()]);

      expect(find.text(RecordProfileCard.ppaLabel), findsOneWidget);
      expect(find.text('14.62'), findsOneWidget);
      expect(find.byType(RecordPositionBadge), findsOneWidget);
      expect(find.text('Tercio superior'), findsOneWidget);
      expect(find.text('164 de 200 créditos'), findsOneWidget);
      expect(find.text(RecordProfileCard.linkText), findsOneWidget);

      final barra = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(barra.value, closeTo(164 / 200, 1e-9));
    });

    testWidgets('sin PPA no se pinta ni la etiqueta ni un 0', (tester) async {
      await _montarTarjeta(tester, [_syncedJson(ppa: null)]);

      expect(find.text(RecordProfileCard.ppaLabel), findsNothing);
      expect(find.text('0'), findsNothing);
      // La insignia y los créditos sí siguen: solo se omite el dato que falta.
      expect(find.text('Tercio superior'), findsOneWidget);
      expect(find.text('164 de 200 créditos'), findsOneWidget);
    });

    testWidgets('sin créditos requeridos no hay barra ni texto de créditos', (
      tester,
    ) async {
      await _montarTarjeta(tester, [_syncedJson(creditsRequired: null)]);

      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.textContaining('créditos'), findsNothing);
      expect(find.text('14.62'), findsOneWidget);
    });

    testWidgets('con créditos requeridos en 0 tampoco hay barra ni texto', (
      tester,
    ) async {
      await _montarTarjeta(tester, [_syncedJson(creditsRequired: 0)]);

      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.textContaining('créditos'), findsNothing);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('con más acumulados que requeridos la barra va al tope y el '
        'texto muestra el número real', (tester) async {
      await _montarTarjeta(tester, [_syncedJson(creditsAccumulated: 230)]);

      expect(find.text('230 de 200 créditos'), findsOneWidget);
      final barra = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(barra.value, 1.0);
    });

    testWidgets('si nunca sincronizó muestra el aviso y ninguna cifra', (
      tester,
    ) async {
      await _montarTarjeta(tester, [_neverSyncedJson()]);

      expect(find.text(RecordProfileCard.neverSyncedText), findsOneWidget);
      expect(find.text(RecordProfileCard.ppaLabel), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byType(RecordPositionBadge), findsNothing);
    });

    testWidgets('tocar la tarjeta con récord lleva a /mi-record', (
      tester,
    ) async {
      await _montarTarjeta(tester, [_syncedJson()]);

      await tester.tap(find.byType(RecordProfileCard));
      await tester.pumpAndSettle();

      expect(Get.currentRoute, '/mi-record');
      expect(find.text('RECORD'), findsOneWidget);
    });

    testWidgets('tocar la tarjeta sin sincronizar también lleva a /mi-record', (
      tester,
    ) async {
      await _montarTarjeta(tester, [_neverSyncedJson()]);

      await tester.tap(find.byType(RecordProfileCard));
      await tester.pumpAndSettle();

      expect(Get.currentRoute, '/mi-record');
      expect(find.text('RECORD'), findsOneWidget);
    });

    testWidgets('mientras carga se ve el skeleton y ningún 0', (tester) async {
      final pendiente = Completer<Map<String, dynamic>>();
      await _montarTarjeta(tester, [pendiente]);

      // SkeletonPulse anima sin fin: aquí se usa pump(), nunca pumpAndSettle.
      expect(find.byKey(RecordProfileCard.skeletonKey), findsOneWidget);
      expect(find.text('0'), findsNothing);
      expect(find.text(RecordProfileCard.ppaLabel), findsNothing);

      // Se completa antes de terminar para que el Timer de loadTimeout se
      // cancele: uno pendiente hace fallar al test con "A Timer is still
      // pending even after the widget tree was disposed".
      pendiente.complete(_syncedJson());
      await tester.pump();
      await tester.pump();
      expect(find.byKey(RecordProfileCard.skeletonKey), findsNothing);
      expect(find.text('14.62'), findsOneWidget);
    });

    testWidgets('si la carga falla se ve el título del récord y el enlace, '
        'sin cifras', (tester) async {
      await _montarTarjeta(tester, [Exception('socket')]);

      expect(find.text(RecordProfileCard.errorTitle), findsOneWidget);
      expect(find.text(RecordProfileCard.linkText), findsOneWidget);
      expect(find.text(RecordProfileCard.ppaLabel), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byKey(RecordProfileCard.skeletonKey), findsNothing);
    });

    testWidgets('en el Perfil va entre "Configurar carnet" y "Carrera"', (
      tester,
    ) async {
      Get.put<AuthService>(_FakeAuthService(_student()));
      Get.put<AcademicRecordService>(
        AcademicRecordService(apiClient: _FakeRecordApi([_syncedJson()])),
      );

      await tester.pumpWidget(const GetMaterialApp(home: ProfilePage()));
      await tester.pump();
      await tester.pump();

      expect(find.byType(RecordProfileCard), findsOneWidget);

      final carnet = tester.getTopLeft(find.text('Configurar carnet')).dy;
      final tarjeta = tester.getTopLeft(find.byType(RecordProfileCard)).dy;
      final carrera = tester.getTopLeft(find.text('Carrera').first).dy;

      expect(tarjeta, greaterThan(carnet));
      expect(carrera, greaterThan(tarjeta));
    });

    testWidgets('un docente no ve la tarjeta ni dispara el GET', (
      tester,
    ) async {
      final api = _FakeRecordApi([_syncedJson()]);
      Get.put<AuthService>(_FakeAuthService(_teacher()));
      Get.put<AcademicRecordService>(AcademicRecordService(apiClient: api));

      await tester.pumpWidget(const GetMaterialApp(home: ProfilePage()));
      await tester.pump();
      await tester.pump();

      expect(find.byType(RecordProfileCard), findsNothing);
      expect(api.getCalls, 0);
      expect(AcademicRecordService.to.record, isNull);
    });

    testWidgets('después de borrar, la tarjeta pasa al aviso y no muestra el '
        'PPA anterior', (tester) async {
      final api = await _montarTarjeta(tester, [
        _syncedJson(),
        _neverSyncedJson(),
      ]);
      expect(find.text('14.62'), findsOneWidget);

      await AcademicRecordService.to.deleteRecord();
      await tester.pump();
      await tester.pump();

      expect(api.deleteCalls, 1);
      expect(api.lastDeletePath, '/academic-record/me');
      expect(api.getCalls, 2);
      expect(find.text(RecordProfileCard.neverSyncedText), findsOneWidget);
      expect(find.text('14.62'), findsNothing);
    });

    testWidgets('durante una recarga no se ve el PPA anterior', (tester) async {
      final recarga = Completer<Map<String, dynamic>>();
      final api = await _montarTarjeta(tester, [_syncedJson(), recarga]);
      expect(find.text('14.62'), findsOneWidget);

      unawaited(AcademicRecordService.to.reload());
      await tester.pump();

      expect(find.byKey(RecordProfileCard.skeletonKey), findsOneWidget);
      expect(find.text('14.62'), findsNothing);

      recarga.complete(_syncedJson(ppa: 16.02));
      await tester.pump();
      await tester.pump();

      expect(find.text('16.02'), findsOneWidget);
      expect(api.getCalls, 2);
    });
  });
}

// ── Dobles y datos del grupo WIDGET ──────────────────────────────────────────
//
// Escritos a mano, sin mockito ni mocktail. Son copias de los de
// test/HU34_jeff/academic_record_service_test.dart: allá son privados de ese
// archivo, así que no se pueden importar.

UserModel _student() => UserModel(
  code: '20230001',
  firstName: 'Alumna',
  lastName: 'De Prueba',
  email: 'test@aloe.ulima.edu.pe',
  role: 'student',
  currentCycle: '2026-1',
  setupComplete: true,
);

UserModel _teacher() => UserModel(
  code: 'docente.test',
  firstName: 'Docente',
  lastName: 'De Prueba',
  email: 'docente.test@ulima.edu.pe',
  role: 'teacher',
  currentCycle: '2026-1',
  setupComplete: true,
);

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

class _FakeRecordApi extends ApiClient {
  _FakeRecordApi(this.getResponses) : super(configuredBaseUrl: 'http://test');

  /// Respuestas del GET, en orden; la última se repite. Un Map se devuelve,
  /// un Completer se espera y cualquier otra cosa se lanza.
  final List<Object> getResponses;
  Object? deleteError;
  int getCalls = 0;
  int deleteCalls = 0;
  String? lastGetPath;
  String? lastDeletePath;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    String? token,
    Map<String, String?> query = const {},
    bool suppressSessionExpiry = false,
  }) async {
    lastGetPath = path;
    final i = getCalls < getResponses.length
        ? getCalls
        : getResponses.length - 1;
    final r = getResponses[i];
    getCalls++;
    if (r is Completer<Map<String, dynamic>>) return r.future;
    if (r is Map<String, dynamic>) return r;
    throw r;
  }

  @override
  Future<Map<String, dynamic>> deleteJson(String path, {String? token}) async {
    deleteCalls++;
    lastDeletePath = path;
    if (deleteError != null) throw deleteError!;
    return <String, dynamic>{'ok': true};
  }
}

/// Récord inventado. Cada campo del snapshot se puede volver null para probar
/// que el dato que falta se omite y nunca se pinta como 0 (RF-REC-1).
Map<String, dynamic> _syncedJson({
  Object? ppa = 14.62,
  Object? relativePosition = 'TERCIO SUPERIOR',
  Object? creditsAccumulated = 164,
  Object? creditsRequired = 200,
}) => <String, dynamic>{
  'syncedAt': '2026-09-18T15:00:00Z',
  'snapshot': <String, dynamic>{
    'ppa': ppa,
    'relativePosition': relativePosition,
    'creditsAccumulated': creditsAccumulated,
    'creditsRequired': creditsRequired,
    'approved': <String, dynamic>{'courses': 50, 'credits': 164},
    'convalidated': <String, dynamic>{'courses': 0, 'credits': 0},
  },
  'periods': <dynamic>[],
  'record': <dynamic>[
    <String, dynamic>{
      'periodCode': '2026-1',
      'courses': <dynamic>[
        <String, dynamic>{
          'code': '100001',
          'name': 'CURSO DE PRUEBA A',
          'attempt': 1,
          'credits': 3,
          'grade': null,
          'gradeRaw': null,
          'section': '917',
          'observation': null,
        },
      ],
    },
  ],
};

Map<String, dynamic> _neverSyncedJson() => <String, dynamic>{
  'syncedAt': null,
  'snapshot': null,
  'periods': <dynamic>[],
  'record': <dynamic>[],
};

/// App mínima con la ruta destino: '/mi-record' todavía no está en main.dart
/// (la registra la tarea 6).
Widget _cardApp() => GetMaterialApp(
  initialRoute: '/',
  getPages: [
    GetPage(
      name: '/',
      page: () => const Scaffold(
        body: Padding(padding: EdgeInsets.all(16), child: RecordProfileCard()),
      ),
    ),
    GetPage(
      name: '/mi-record',
      page: () => const Scaffold(body: Text('RECORD')),
    ),
  ],
);

/// Monta la tarjeta suelta. El postFrameCallback de `initState` ya corrió al
/// final del frame de `pumpWidget`, así que `load()` está en vuelo: el primer
/// pump() vacía las microtareas y resuelve el Future del doble, y el segundo
/// pinta el frame que el Obx agendó al cambiar el Rx.
Future<_FakeRecordApi> _montarTarjeta(
  WidgetTester tester,
  List<Object> getResponses, {
  UserModel? user,
}) async {
  final api = _FakeRecordApi(getResponses);
  Get.put<AuthService>(_FakeAuthService(user ?? _student()));
  Get.put<AcademicRecordService>(AcademicRecordService(apiClient: api));
  await tester.pumpWidget(_cardApp());
  await tester.pump();
  await tester.pump();
  return api;
}
