// test/HU34_jeff/record_page_test.dart
//
// WIDGET + UNITARIA — HU34 (récord académico): la pantalla "Mi récord
// académico" (RF-REC-2 y RF-REC-4): ruta, estados y encabezado.
// Pantalla: lib/pages/academic_record/academic_record_page.dart
//
// Todos los datos son inventados; el repo es público. Ningún valor sale del
// récord real: ni la ubicación relativa ni los créditos requeridos.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/error_retry.dart';
import 'package:ulima_plus/components/skeleton.dart';
import 'package:ulima_plus/main.dart';
import 'package:ulima_plus/models/academic_record_model.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/academic_record/academic_record_binding.dart';
import 'package:ulima_plus/pages/academic_record/academic_record_controller.dart';
import 'package:ulima_plus/pages/academic_record/academic_record_page.dart';
import 'package:ulima_plus/pages/academic_record/record_course_row.dart';
import 'package:ulima_plus/pages/academic_record/record_profile_card.dart';
import 'package:ulima_plus/services/academic_record_service.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/auth_service.dart';

UserModel _student() => UserModel(
      code: '20230001',
      firstName: 'Alumna',
      lastName: 'De Prueba',
      email: 'test@aloe.ulima.edu.pe',
      role: 'student',
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

/// Doble del cliente HTTP. `getResponses` se consume en orden y el último se
/// repite: un `Map` se devuelve, un `Completer` se espera (deja la pantalla
/// cargando) y cualquier otra cosa se lanza.
class _FakeRecordApi extends ApiClient {
  _FakeRecordApi(this.getResponses) : super(configuredBaseUrl: 'http://test');

  final List<Object> getResponses;
  Object? deleteError;
  int getCalls = 0;
  int deleteCalls = 0;
  String? lastDeletePath;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    String? token,
    Map<String, String?> query = const {},
    bool suppressSessionExpiry = false,
  }) async {
    final r = getResponses[
        getCalls < getResponses.length ? getCalls : getResponses.length - 1];
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

/// Récord inventado de punta a punta. Ninguna cifra ni etiqueta de aquí sale
/// de un récord real: si hay que cambiarlas, se cambian por otras inventadas,
/// nunca por las que devuelve el portal.
Map<String, dynamic> _syncedJson({Object? creditsRequired = 240}) =>
    <String, dynamic>{
      'syncedAt': '2026-09-18T15:00:00Z',
      'snapshot': <String, dynamic>{
        'ppa': 14.62,
        'relativePosition': 'TERCIO SUPERIOR',
        'creditsAccumulated': 197,
        'creditsRequired': creditsRequired,
        'approved': <String, dynamic>{'courses': 58, 'credits': 197},
        'convalidated': <String, dynamic>{'courses': 0, 'credits': 0},
      },
      'periods': <dynamic>[
        <String, dynamic>{
          'periodCode': '2025-2',
          'average': 17.3,
          'relativePosition': 'MEDIO SUPERIOR',
          'level': 8,
          'convalidated': <String, dynamic>{'courses': 0, 'credits': 0},
          'enrolled': <String, dynamic>{'courses': 2, 'credits': 3.5},
          'approved': <String, dynamic>{'courses': 2, 'credits': 3.5},
          'failed': <String, dynamic>{'courses': 0, 'credits': 0},
        },
        <String, dynamic>{
          'periodCode': '2025-1',
          'average': null,
          'relativePosition': null,
          'level': null,
          'convalidated': <String, dynamic>{'courses': null, 'credits': null},
          'enrolled': <String, dynamic>{'courses': null, 'credits': null},
          'approved': <String, dynamic>{'courses': null, 'credits': null},
          'failed': <String, dynamic>{'courses': null, 'credits': null},
        },
      ],
      'record': <dynamic>[
        <String, dynamic>{
          'periodCode': '2026-1',
          'courses': <dynamic>[
            <String, dynamic>{
              'code': '100001',
              'name': 'CURSO EN CURSO',
              'attempt': 1,
              'credits': 3,
              'grade': null,
              'gradeRaw': null,
              'section': '801',
              'observation': null,
            },
          ],
        },
        <String, dynamic>{
          'periodCode': '2025-2',
          'courses': <dynamic>[
            <String, dynamic>{
              'code': '100002',
              'name': 'CURSO APROBADO',
              'attempt': 2,
              'credits': 1.5,
              'grade': 17,
              'gradeRaw': '17',
              'section': '802',
              'observation': null,
            },
            <String, dynamic>{
              'code': '100003',
              'name': 'CURSO CONVALIDADO',
              'attempt': 1,
              'credits': 2,
              'grade': null,
              'gradeRaw': 'CONV',
              'section': null,
              'observation': 'Convalidado por examen',
            },
          ],
        },
        <String, dynamic>{
          'periodCode': '2025-1',
          'courses': <dynamic>[
            <String, dynamic>{
              'code': '100004',
              'name': 'CURSO SIN NOTA ANTIGUO',
              'attempt': 1,
              'credits': 4,
              'grade': null,
              'gradeRaw': null,
              'section': null,
              'observation': null,
            },
            <String, dynamic>{
              'code': '100005',
              'name': 'CURSO JALADO',
              'attempt': 1,
              'credits': 4,
              'grade': 8,
              'gradeRaw': '08',
              'section': '803',
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

/// Reloj fijo: tres días de calendario después del `syncedAt` de `_syncedJson`.
DateTime _now() => DateTime.utc(2026, 9, 21, 16);

Widget _app() => GetMaterialApp(
      initialRoute: '/mi-record',
      getPages: [
        GetPage(name: '/mi-record', page: () => const AcademicRecordPage()),
        GetPage(
          name: '/portal-sync',
          page: () => const Scaffold(body: Text('PORTAL SYNC')),
        ),
      ],
    );

/// Monta la pantalla con su tabla de rutas propia. Al final del frame de
/// `pumpWidget` GetX dispara el `onReady` del controller → `load()`; el primer
/// `pump` pinta ya la respuesta resuelta y el segundo deja el árbol estable.
Future<_FakeRecordApi> _mountPage(
  WidgetTester tester, {
  required List<Object> getResponses,
  UserModel? user,
}) async {
  final api = _FakeRecordApi(getResponses);
  Get.put<AuthService>(_FakeAuthService(user ?? _student()));
  Get.put<AcademicRecordService>(AcademicRecordService(apiClient: api));
  Get.put<AcademicRecordController>(
    AcademicRecordController(service: AcademicRecordService.to, now: _now),
  );
  await tester.pumpWidget(_app());
  await tester.pump();
  await tester.pump();
  return api;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  group('WIDGET · AcademicRecordPage (RF-REC-2, RF-REC-4)', () {
    testWidgets('la ruta /mi-record vive en main.dart con su binding',
        (tester) async {
      // Monta la app REAL: lo que hay que blindar es la cadena entre el
      // GetPage de main.dart, el AcademicRecordBinding y la pantalla. Con una
      // tabla de rutas escrita en el test, la ruta podría faltar y nadie se
      // enteraría hasta ejecutar la app.
      final api = _FakeRecordApi(<Object>[_syncedJson()]);
      Get.put<AuthService>(_FakeAuthService(_student()));
      Get.put<AcademicRecordService>(AcademicRecordService(apiClient: api));

      await tester.pumpWidget(const MyApp(initialRoute: '/mi-record'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(AcademicRecordPage), findsOneWidget);
      expect(Get.currentRoute, equals('/mi-record'));
      expect(find.text('Mi récord académico'), findsOneWidget);
      expect(api.getCalls, 1);
    });

    testWidgets('mientras carga muestra el skeleton, no el error',
        (tester) async {
      // Respuesta que nunca completa: la pantalla queda cargando. Sin
      // pumpAndSettle: SkeletonPulse anima sin fin y colgaría el test.
      final pendiente = Completer<Map<String, dynamic>>();
      await _mountPage(tester, getResponses: <Object>[pendiente]);

      expect(find.byKey(AcademicRecordPage.skeletonKey), findsOneWidget);
      expect(find.byType(SkeletonPulse), findsOneWidget);
      expect(find.byType(ErrorRetry), findsNothing);
      expect(find.byKey(AcademicRecordPage.successViewKey), findsNothing);

      // Cerrar la carga antes de terminar. `AcademicRecordService.load()`
      // aplica `.timeout(loadTimeout)`, y ese Timer de 15 s seguiría vivo al
      // desmontarse el árbol: el binding haría fallar el test con "A Timer is
      // still pending even after the widget tree was disposed."
      pendiente.complete(_syncedJson());
      await tester.pump();
      await tester.pump();
      expect(find.byKey(AcademicRecordPage.successViewKey), findsOneWidget);
    });

    testWidgets('si la carga falla, ErrorRetry y "Reintentar" vuelve a pedir',
        (tester) async {
      final api = await _mountPage(
        tester,
        getResponses: <Object>[Exception('socket'), _syncedJson()],
      );

      expect(find.byType(ErrorRetry), findsOneWidget);
      expect(find.text('No se pudo cargar tu récord'), findsOneWidget);
      // El mensaje no culpa a la conexión del alumno: si el que falla es el
      // backend (o la app sale antes que él), no es su wifi.
      expect(find.text(AcademicRecordPage.loadErrorMessage), findsOneWidget);
      expect(AcademicRecordPage.loadErrorMessage, isNot(contains('conexión')));

      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      await tester.pump();

      expect(api.getCalls, 2);
      expect(find.byType(ErrorRetry), findsNothing);
      expect(find.text('14.62'), findsOneWidget);
    });

    testWidgets('RF-REC-4: sin sincronizar, estado vacío y botón a /portal-sync',
        (tester) async {
      await _mountPage(tester, getResponses: <Object>[_neverSyncedJson()]);

      expect(find.text('Aún no tienes tu récord'), findsOneWidget);
      expect(
        find.textContaining('tus notas de toda la carrera, tu PPA y tus créditos'),
        findsOneWidget,
      );
      expect(find.text('Sincronizar con el portal'), findsOneWidget);
      expect(find.byKey(AcademicRecordPage.ringKey), findsNothing);
      expect(find.byKey(AcademicRecordPage.successViewKey), findsNothing);

      await tester.tap(find.text('Sincronizar con el portal'));
      await tester.pumpAndSettle();

      expect(Get.currentRoute, equals('/portal-sync'));
    });

    testWidgets('el encabezado trae anillo, porcentaje, PPA y ubicación',
        (tester) async {
      await _mountPage(tester, getResponses: <Object>[_syncedJson()]);

      expect(find.byKey(AcademicRecordPage.successViewKey), findsOneWidget);
      expect(find.byKey(AcademicRecordPage.ringKey), findsOneWidget);
      expect(find.text('82%'), findsOneWidget); // 197 de 240
      expect(find.text('14.62'), findsOneWidget);
      expect(find.text('Tercio superior'), findsOneWidget);
    });

    testWidgets('sin créditos requeridos no hay anillo ni porcentaje',
        (tester) async {
      // RF-REC-1/RF-REC-2: un dato que falta se omite; nunca se pinta un 0.
      await _mountPage(
        tester,
        getResponses: <Object>[_syncedJson(creditsRequired: null)],
      );

      expect(find.byKey(AcademicRecordPage.successViewKey), findsOneWidget);
      expect(find.byKey(AcademicRecordPage.ringKey), findsNothing);
      expect(find.textContaining('%'), findsNothing);
      expect(find.text('14.62'), findsOneWidget);
    });

    testWidgets('la línea de sincronización cuenta días de Lima',
        (tester) async {
      await _mountPage(tester, getResponses: <Object>[_syncedJson()]);

      expect(find.text('Sincronizado hace 3 días'), findsOneWidget);
    });

    testWidgets('la pantalla nunca se llama "notas oficiales"',
        (tester) async {
      await _mountPage(tester, getResponses: <Object>[_syncedJson()]);

      expect(find.text('Mi récord académico'), findsOneWidget);
      expect(find.textContaining('notas oficiales'), findsNothing);
      expect(find.textContaining('Notas oficiales'), findsNothing);
    });

    testWidgets('un docente no ve el récord ni se queda cargando',
        (tester) async {
      // "Qué NO entra: mostrar el récord a otros roles" (spec:195). El
      // servicio no dispara el GET para un docente, así que 'record' queda
      // null: sin la guarda del controller, la pantalla se quedaría en el
      // skeleton para siempre y sin salida.
      final api = await _mountPage(
        tester,
        getResponses: <Object>[_syncedJson()],
        user: UserModel(
          code: 'docente.test',
          firstName: 'Docente',
          lastName: 'De Prueba',
          email: 'docente.test@ulima.edu.pe',
          role: 'teacher',
          currentCycle: '2026-1',
          setupComplete: true,
        ),
      );

      expect(api.getCalls, 0);
      expect(find.byKey(AcademicRecordPage.skeletonKey), findsNothing);
      expect(find.byKey(AcademicRecordPage.successViewKey), findsNothing);
      expect(find.byType(ErrorRetry), findsOneWidget);
    });
  });

  group('WIDGET · Chips de ciclo y cursos (RF-REC-2, RF-REC-3)', () {
    // El chip y el encabezado de la tarjeta dicen lo mismo ('2025-2'), así que
    // find.text encontraría dos. Para tocar se usa la key del chip; para mirar
    // la lista, solo lo que está dentro de la tarjeta.
    Finder chip(String periodCode) =>
        find.byKey(AcademicRecordPage.periodChipKey(periodCode));

    Finder enLaTarjeta(Finder matching) => find.descendant(
      of: find.byKey(AcademicRecordPage.coursesCardKey),
      matching: matching,
    );

    Future<void> tocarChip(WidgetTester tester, String periodCode) async {
      await tester.tap(chip(periodCode));
      await tester.pump();
    }

    testWidgets('los chips van del más reciente al más viejo', (tester) async {
      await _mountPage(tester, getResponses: [_syncedJson()]);

      expect(chip('2026-1'), findsOneWidget);
      expect(chip('2025-2'), findsOneWidget);
      expect(chip('2025-1'), findsOneWidget);

      // El orden es el del backend (RS-BE-26): el cliente no reordena.
      final x2026 = tester.getTopLeft(chip('2026-1')).dx;
      final x20252 = tester.getTopLeft(chip('2025-2')).dx;
      final x20251 = tester.getTopLeft(chip('2025-1')).dx;
      expect(x2026, lessThan(x20252));
      expect(x20252, lessThan(x20251));
    });

    testWidgets('viene seleccionado el ciclo más reciente', (tester) async {
      await _mountPage(tester, getResponses: [_syncedJson()]);

      expect(enLaTarjeta(find.text('2026-1')), findsOneWidget);
      expect(enLaTarjeta(find.text('CURSO EN CURSO')), findsOneWidget);
      expect(enLaTarjeta(find.text('CURSO APROBADO')), findsNothing);
      expect(find.byType(RecordCourseRow), findsOneWidget);
    });

    testWidgets('tocar otro chip cambia la lista: un ciclo a la vez', (
      tester,
    ) async {
      await _mountPage(tester, getResponses: [_syncedJson()]);
      await tocarChip(tester, '2025-2');

      expect(enLaTarjeta(find.text('CURSO APROBADO')), findsOneWidget);
      expect(enLaTarjeta(find.text('CURSO CONVALIDADO')), findsOneWidget);
      expect(enLaTarjeta(find.text('CURSO EN CURSO')), findsNothing);
      expect(find.byType(RecordCourseRow), findsNWidgets(2));

      // Y se puede volver: sigue habiendo un solo ciclo a la vista.
      await tocarChip(tester, '2026-1');
      expect(enLaTarjeta(find.text('CURSO EN CURSO')), findsOneWidget);
      expect(enLaTarjeta(find.text('CURSO APROBADO')), findsNothing);
      expect(find.byType(RecordCourseRow), findsOneWidget);
    });

    testWidgets('el promedio sale de periods, y solo si el backend lo tiene', (
      tester,
    ) async {
      await _mountPage(tester, getResponses: [_syncedJson()]);

      // '2026-1' no está en 'periods': no hay promedio que mostrar.
      expect(find.textContaining('prom.'), findsNothing);

      await tocarChip(tester, '2025-2');
      expect(enLaTarjeta(find.text('prom. 17.3')), findsOneWidget);

      // '2025-1' sí está en 'periods', pero con average null: tampoco se
      // pinta nada, y mucho menos un 0.
      await tocarChip(tester, '2025-1');
      expect(find.textContaining('prom.'), findsNothing);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('"En curso" solo en el ciclo más reciente del récord', (
      tester,
    ) async {
      await _mountPage(tester, getResponses: [_syncedJson()]);

      expect(
        enLaTarjeta(find.text(RecordCourseRow.inProgressLabel)),
        findsOneWidget,
      );

      await tocarChip(tester, '2025-1');
      expect(enLaTarjeta(find.text('CURSO SIN NOTA ANTIGUO')), findsOneWidget);
      expect(
        enLaTarjeta(find.text(RecordCourseRow.noGradeLabel)),
        findsOneWidget,
      );
      expect(find.text(RecordCourseRow.inProgressLabel), findsNothing);
      expect(enLaTarjeta(find.text('08')), findsOneWidget);
    });

    testWidgets('cada curso del ciclo elegido se pinta como pide RF-REC-3', (
      tester,
    ) async {
      await _mountPage(tester, getResponses: [_syncedJson()]);
      await tocarChip(tester, '2025-2');

      expect(enLaTarjeta(find.text('2.ª vez')), findsOneWidget);
      expect(enLaTarjeta(find.text('100002 · 1.5 créd.')), findsOneWidget);
      expect(enLaTarjeta(find.text('17')), findsOneWidget);
      expect(enLaTarjeta(find.text('CONV')), findsOneWidget);
      expect(enLaTarjeta(find.text('Convalidado por examen')), findsOneWidget);

      // Qué NO entra: el resumen completo del ciclo. De 'periods' sale el
      // promedio y nada más, aunque el '2025-2' de la respuesta traiga
      // relativePosition 'MEDIO SUPERIOR', level 8 y los cuatro grupos de
      // cursos y créditos. ('Tercio superior' SÍ está en pantalla, pero en el
      // encabezado: es la ubicación del snapshot, que pide RF-REC-2; por eso
      // lo de la ubicación se mira solo dentro de la tarjeta.)
      expect(find.textContaining('MEDIO'), findsNothing);
      expect(find.textContaining('Medio'), findsNothing);
      expect(enLaTarjeta(find.textContaining('superior')), findsNothing);
      expect(enLaTarjeta(find.textContaining('créditos')), findsNothing);
    });
  });

  group('UNITARIA · periodoSeleccionado y periodAverage (RF-REC-2)', () {
    const ciclos = ['2026-1', '2025-2'];

    AcademicPeriodSummary resumen(String periodCode, double? average) =>
        AcademicPeriodSummary(
          periodCode: periodCode,
          average: average,
          relativePosition: null,
          level: null,
          convalidated: AcademicTotals.none,
          enrolled: AcademicTotals.none,
          approved: AcademicTotals.none,
          failed: AcademicTotals.none,
        );

    test('sin elección previa manda el más reciente, que es el primero', () {
      expect(
        AcademicRecordController.periodoSeleccionado(ciclos, null),
        '2026-1',
      );
    });

    test('un ciclo elegido que existe se respeta', () {
      expect(
        AcademicRecordController.periodoSeleccionado(ciclos, '2025-2'),
        '2025-2',
      );
    });

    test('un ciclo que ya no está en el récord cae al más reciente', () {
      // Pasa al volver a sincronizar: el récord nuevo puede no traer el ciclo
      // que estaba elegido.
      expect(
        AcademicRecordController.periodoSeleccionado(ciclos, '2024-1'),
        '2026-1',
      );
    });

    test('sin ciclos no hay nada que elegir', () {
      expect(
        AcademicRecordController.periodoSeleccionado(
          const <String>[],
          '2025-2',
        ),
        isNull,
      );
    });

    test('periodAverage solo devuelve el promedio que el backend tiene', () {
      final periods = [resumen('2025-2', 17.3), resumen('2025-1', null)];

      expect(AcademicRecordController.periodAverage(periods, '2025-2'), 17.3);
      // El ciclo no está en 'periods'.
      expect(AcademicRecordController.periodAverage(periods, '2026-1'), isNull);
      // El ciclo está, pero sin promedio.
      expect(AcademicRecordController.periodAverage(periods, '2025-1'), isNull);
    });
  });

  group('UNITARIA · syncedAgoLabel en hora de Lima (RF-REC-2)', () {
    test('tres días de calendario', () {
      expect(
        AcademicRecordController.syncedAgoLabel(
          DateTime.utc(2026, 9, 18, 15),
          DateTime.utc(2026, 9, 21, 16),
        ),
        'Sincronizado hace 3 días',
      );
    });

    test('el mismo día en Lima', () {
      expect(
        AcademicRecordController.syncedAgoLabel(
          DateTime.utc(2026, 9, 18, 15),
          DateTime.utc(2026, 9, 18, 23),
        ),
        'Sincronizado hoy',
      );
    });

    test('una hora antes puede ser "hace 1 día"', () {
      // En Lima son el 17 a las 23:30 y el 18 a las 00:30: son fechas de
      // calendario distintas aunque haya pasado una sola hora.
      expect(
        AcademicRecordController.syncedAgoLabel(
          DateTime.utc(2026, 9, 18, 4, 30),
          DateTime.utc(2026, 9, 18, 5, 30),
        ),
        'Sincronizado hace 1 día',
      );
    });

    test('en UTC ya es otro día, en Lima todavía no', () {
      expect(
        AcademicRecordController.syncedAgoLabel(
          DateTime.utc(2026, 9, 18, 15),
          DateTime.utc(2026, 9, 19, 4),
        ),
        'Sincronizado hoy',
      );
    });

    test('un syncedAt futuro no produce días negativos', () {
      expect(
        AcademicRecordController.syncedAgoLabel(
          DateTime.utc(2026, 9, 22, 15),
          DateTime.utc(2026, 9, 21, 16),
        ),
        'Sincronizado hoy',
      );
    });
  });

  group('WIDGET · Borrar mi récord (RF-REC-5)', () {
    Future<_FakeRecordApi> montarConRecord(
      WidgetTester tester, {
      List<Object>? getResponses,
    }) =>
        _mountPage(
          tester,
          getResponses: getResponses ?? <Object>[_syncedJson()],
        );

    // El botón es el último hijo de una pantalla scrolleable: antes de tocarlo
    // hay que asegurarse de que esté a la vista. En el estado de éxito no hay
    // ningún SkeletonPulse, así que acá pumpAndSettle sí se puede usar.
    Future<void> traerBotonALaVista(WidgetTester tester) async {
      await tester.ensureVisible(
        find.byKey(AcademicRecordPage.deleteButtonKey),
      );
      await tester.pumpAndSettle();
    }

    Future<void> abrirDialogo(WidgetTester tester) async {
      await traerBotonALaVista(tester);
      await tester.tap(find.byKey(AcademicRecordPage.deleteButtonKey));
      await tester.pumpAndSettle();
    }

    testWidgets('el botón va al final, después de la tarjeta de cursos',
        (tester) async {
      await montarConRecord(tester);

      expect(find.text(AcademicRecordPage.deleteButtonLabel), findsOneWidget);

      await traerBotonALaVista(tester);

      // "Al final de la pantalla" (RF-REC-5): debajo de la tarjeta de cursos.
      // Las dos posiciones se miden después del mismo scroll, así que lo que
      // se compara es el orden dentro del Column.
      expect(
        tester.getTopLeft(find.byKey(AcademicRecordPage.deleteButtonKey)).dy,
        greaterThan(
          tester.getTopLeft(find.byKey(AcademicRecordPage.coursesCardKey)).dy,
        ),
      );
    });

    testWidgets('el diálogo explica qué se borra y qué no', (tester) async {
      await montarConRecord(tester);
      await abrirDialogo(tester);

      // find.text es exacto: 'Borrar mi récord' no choca con el botón
      // 'Borrar mi récord de ULima++', que sigue montado detrás del diálogo.
      expect(find.text(AcademicRecordPage.deleteDialogTitle), findsOneWidget);
      expect(find.text(AcademicRecordPage.deleteDialogBody), findsOneWidget);
      expect(find.text(AcademicRecordPage.deleteCancelLabel), findsOneWidget);
      expect(find.text(AcademicRecordPage.deleteConfirmLabel), findsOneWidget);
    });

    testWidgets('cancelar no borra nada', (tester) async {
      final api = await montarConRecord(tester);
      await abrirDialogo(tester);

      await tester.tap(find.text(AcademicRecordPage.deleteCancelLabel));
      await tester.pumpAndSettle();

      expect(api.deleteCalls, 0);
      expect(find.text(AcademicRecordPage.deleteDialogTitle), findsNothing);
      expect(find.byKey(AcademicRecordPage.successViewKey), findsOneWidget);
      expect(find.text('14.62'), findsOneWidget);
    });

    testWidgets('confirmar llama al DELETE y la pantalla pasa al estado vacío',
        (tester) async {
      final api = await montarConRecord(
        tester,
        getResponses: <Object>[_syncedJson(), _neverSyncedJson()],
      );
      final controller = Get.find<AcademicRecordController>();

      // Un ciclo elegido a mano: después de borrar tiene que volver a null,
      // porque ese ciclo ya no existe. Los chips están arriba del todo, así
      // que se tocan antes de bajar al botón.
      await tester.tap(find.byKey(AcademicRecordPage.periodChipKey('2025-2')));
      await tester.pump();
      expect(controller.selectedPeriodCode.value, '2025-2');

      await abrirDialogo(tester);
      await tester.tap(find.text(AcademicRecordPage.deleteConfirmLabel));
      await tester.pumpAndSettle();

      expect(api.deleteCalls, 1);
      expect(api.lastDeletePath, '/academic-record/me');
      expect(api.getCalls, 2); // la recarga que confirma el borrado
      expect(find.text(AcademicRecordPage.emptyTitle), findsOneWidget);
      expect(find.byKey(AcademicRecordPage.successViewKey), findsNothing);
      expect(find.text('14.62'), findsNothing);
      // Ya no hay copia: el botón de borrar desaparece con ella.
      expect(find.byKey(AcademicRecordPage.deleteButtonKey), findsNothing);
      expect(controller.selectedPeriodCode.value, isNull);
      expect(controller.deleting.value, isFalse);
    });

    testWidgets('si el DELETE falla, aviso explícito y el récord sigue ahí',
        (tester) async {
      final api = await montarConRecord(tester);
      final controller = Get.find<AcademicRecordController>();
      api.deleteError = ApiException(
        statusCode: 500,
        code: 'HTTP_ERROR',
        message: 'x',
      );
      await abrirDialogo(tester);

      await tester.tap(find.text(AcademicRecordPage.deleteConfirmLabel));
      await tester.pumpAndSettle();

      expect(api.deleteCalls, 1);
      expect(api.getCalls, 1); // no recargó: no se borró nada
      expect(
        find.text(AcademicRecordService.deleteErrorMessage),
        findsOneWidget,
      );
      expect(find.text('14.62'), findsOneWidget);
      expect(find.byKey(AcademicRecordPage.deleteButtonKey), findsOneWidget);
      // El finally del controller corre también cuando el DELETE falla.
      expect(controller.deleting.value, isFalse);

      // El SnackBar se cierra solo a los 4 s con un Timer. Si el test termina
      // antes, el binding falla con "A Timer is still pending even after the
      // widget tree was disposed".
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('mientras borra, el botón no acepta otro toque',
        (tester) async {
      final api = await montarConRecord(tester);
      final controller = Get.find<AcademicRecordController>();

      // El doble resuelve el DELETE al instante, así que no hay forma de
      // dejarlo colgado desde la UI: se pone la bandera a mano, que es
      // exactamente el estado en el que queda el controller mientras el
      // DELETE va en camino.
      controller.deleting.value = true;
      await tester.pump();

      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(AcademicRecordPage.deleteButtonKey),
            )
            .onPressed,
        isNull,
      );
      // Deshabilitado y nada más: sin indicador animado, que colgaría los
      // pumpAndSettle del resto del archivo.
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Y el guardia del controller impide un segundo DELETE aunque se llame
      // al método directamente.
      await controller.deleteRecord();
      expect(api.deleteCalls, 0);

      controller.deleting.value = false;
      await tester.pump();
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(AcademicRecordPage.deleteButtonKey),
            )
            .onPressed,
        isNotNull,
      );
    });

    testWidgets(
        'RF-REC-5: al volver con back, la tarjeta del Perfil ya no muestra el '
        'PPA ni los créditos borrados', (tester) async {
      // Integración con la tarjeta real y el binding real: lo que se prueba
      // es que las dos pantallas leen el MISMO AcademicRecordService.
      final api = _FakeRecordApi(<Object>[_syncedJson(), _neverSyncedJson()]);
      Get.put<AuthService>(_FakeAuthService(_student()));
      Get.put<AcademicRecordService>(AcademicRecordService(apiClient: api));

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/',
          getPages: [
            GetPage(
              name: '/',
              page: () => const Scaffold(
                body: Padding(
                  padding: EdgeInsets.all(16),
                  child: RecordProfileCard(),
                ),
              ),
            ),
            GetPage(
              name: '/mi-record',
              page: () => const AcademicRecordPage(),
              binding: AcademicRecordBinding(),
            ),
            GetPage(
              name: '/portal-sync',
              page: () => const Scaffold(body: Text('PORTAL SYNC')),
            ),
          ],
        ),
      );
      await tester.pump(); // el postFrameCallback de la tarjeta → load()
      await tester.pump();

      expect(find.text('14.62'), findsOneWidget);
      expect(find.text('197 de 240 créditos'), findsOneWidget);

      await tester.tap(find.byType(RecordProfileCard));
      await tester.pumpAndSettle();

      expect(find.byType(AcademicRecordPage), findsOneWidget);
      expect(api.getCalls, 1); // la pantalla usa la caché del servicio

      await abrirDialogo(tester);
      await tester.tap(find.text(AcademicRecordPage.deleteConfirmLabel));
      await tester.pumpAndSettle();

      expect(api.deleteCalls, 1);
      expect(find.text(AcademicRecordPage.emptyTitle), findsOneWidget);

      Get.back<void>();
      await tester.pumpAndSettle();

      expect(find.text(RecordProfileCard.neverSyncedText), findsOneWidget);
      expect(find.text('14.62'), findsNothing);
      expect(find.text('197 de 240 créditos'), findsNothing);
    });
  });
}
