// test/HU35_jeff/time_blocks_horas_test.dart
//
// UNITARIA + WIDGET — HU35 (bloques de horario propios): la línea con las
// horas que los bloques propios ocupan en la semana del día activo (RF-BLQ-6).
// - El texto de las horas: HorarioPage.textoDeHoras
//   (lib/pages/horario/horario.dart).
// - Qué total le toca al día activo: HorarioController.horasDeLaSemanaActiva
//   (lib/pages/horario/horario_controller.dart).
// - La línea en las dos vistas, la de día y la semanal:
//   lib/pages/horario/horario.dart.
//
// El número lo calcula el servidor (RS-BE-34) y la app solo lo muestra. Por
// eso la única ocurrencia sembrada suma a propósito OTRA cifra (4 h) que la
// que manda `weeks` para su semana (12 h): si alguien sumara en la app, las
// pruebas lo delatan.
//
// Todos los datos son inventados; el repo es público. La alumna 20230001 no
// existe, el bloque "Prácticas de prueba" tampoco, y nada sale de un horario
// real ni de test/HU31_jeff/fixtures.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/horario/horario.dart';
import 'package:ulima_plus/pages/horario/horario_controller.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/time_blocks_service.dart';

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

/// La regla, con la forma de `GET /time-blocks/me`. Aquí solo importa que
/// exista: la línea aparece cuando la alumna tiene al menos un bloque.
Map<String, dynamic> _regla() => <String, dynamic>{
      'id': 7,
      'title': 'Prácticas de prueba',
      'colorHex': '#27AE60',
      'daysOfWeek': <dynamic>[1, 3],
      'startTime': '14:00',
      'endTime': '18:00',
      'startDate': '2026-09-01',
      'endDate': '2026-12-15',
      'exceptions': <dynamic>[],
    };

/// Una sola ocurrencia, de cuatro horas, el lunes 21. Sumada en la app, la
/// semana del 21 daría 4 h y no las 12 que dice el servidor.
Map<String, dynamic> _ocurrencia() => <String, dynamic>{
      'blockId': 7,
      'title': 'Prácticas de prueba',
      'colorHex': '#27AE60',
      'date': '2026-09-21',
      'dayOfWeek': 1,
      'startTime': '14:00',
      'endTime': '18:00',
      'moved': false,
    };

/// `weeks` de la ventana del 14 de septiembre al 11 de octubre de 2026, con la
/// forma de `GET /time-blocks/me/occurrences` (RS-BE-34): una entrada por
/// semana, con su lunes. Las cifras son inventadas y no cuadran a propósito con
/// las ocurrencias (ver la cabecera). La del 5 de octubre llega sin horas: el
/// backend siempre manda un número (0 si la semana no tiene nada), pero si
/// llegara null la app no lo convierte en 0.
List<Map<String, dynamic>> _semanas() => <Map<String, dynamic>>[
      <String, dynamic>{'weekStart': '2026-09-14', 'hours': 6},
      <String, dynamic>{'weekStart': '2026-09-21', 'hours': 12},
      <String, dynamic>{'weekStart': '2026-09-28', 'hours': 12.5},
      <String, dynamic>{'weekStart': '2026-10-05', 'hours': null},
    ];

const List<String> _nombres = <String>[
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

/// Cuatro semanas seguidas de lunes a domingo desde el lunes 21 de septiembre
/// de 2026, con lo que arma el backend para cada día ("21 de Septiembre",
/// `isoDate` "2026-09-21"), como llegan de `/schedule/me/sessions`. La cuarta
/// (del 12 de octubre) no está en `weeks`: cae fuera de la ventana.
List<DaySchedule> _cuatroSemanas() => <DaySchedule>[
      for (var i = 0; i < 28; i++) _diaNumero(i),
    ];

/// El día [i] contado desde el lunes 21 de septiembre de 2026.
DaySchedule _diaNumero(int i) {
  final fecha = DateTime.utc(2026, 9, 21 + i);
  final mes = fecha.month == 9 ? 'Septiembre' : 'Octubre';
  return DaySchedule(
    _nombres[fecha.weekday - 1],
    '${fecha.day} de $mes',
    'Semana ${5 + i ~/ 7} del ciclo',
    isoDate: '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-'
        '${fecha.day.toString().padLeft(2, '0')}',
  );
}

// Posiciones en [_cuatroSemanas].
const int _lunes21 = 0;
const int _miercoles23 = 2;
const int _domingo27 = 6;
const int _lunes28 = 7;
const int _lunes5Oct = 14;
const int _lunes12Oct = 21;

// --- Dobles --------------------------------------------------------------------

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

/// Doble del cliente HTTP de [TimeBlocksService]: contesta las dos llamadas de
/// `load` con lo sembrado.
class _FakeBloquesApi extends ApiClient {
  _FakeBloquesApi({required this.reglas, required this.semanas})
      : super(configuredBaseUrl: 'http://test');

  final List<Map<String, dynamic>> reglas;
  final List<Map<String, dynamic>> semanas;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    String? token,
    Map<String, String?> query = const {},
    bool suppressSessionExpiry = false,
  }) async {
    if (path == '/time-blocks/me/occurrences') {
      return <String, dynamic>{
        'occurrences': <dynamic>[_ocurrencia()],
        'weeks': semanas,
      };
    }
    return <String, dynamic>{'blocks': reglas};
  }
}

/// El controller del horario sin su carga remota: días sembrados y el reloj
/// fijo. `horasDeLaSemanaActiva` NO se sobreescribe: es lo que se prueba.
class _HorarioDePrueba extends HorarioController {
  _HorarioDePrueba(
    List<DaySchedule> dias, {
    int diaActivo = 0,
    DateTime? hoy,
  }) {
    daysList.assignAll(dias);
    currentDayIndex.value = diaActivo;
    // Por omisión el 1 de septiembre: fuera de las cuatro semanas, así la
    // vista de día no pinta la línea roja de "ahora".
    currentLimaTime.value = hoy ?? DateTime.utc(2026, 9, 1, 10);
  }

  @override
  // ignore: must_call_super
  void onInit() {
    // Sin el onInit real: arranca un Timer.periodic de un minuto y pide el
    // horario con un ApiClient propio que no se puede inyectar. Mismo recurso
    // que test/HU35_jeff/time_blocks_grilla_test.dart.
  }
}

/// Registra la sesión de la alumna y un [TimeBlocksService] con lo sembrado.
/// Si [cargar], carga una ventana fija de cuatro semanas, no la que pediría el
/// horario (ver la nota de las pruebas).
Future<TimeBlocksService> _registrarBloques({
  List<Map<String, dynamic>>? reglas,
  List<Map<String, dynamic>>? semanas,
  bool cargar = true,
}) async {
  Get.put<AuthService>(_FakeAuthService(_alumna()));
  final servicio = TimeBlocksService(
    apiClient: _FakeBloquesApi(
      reglas: reglas ?? <Map<String, dynamic>>[_regla()],
      semanas: semanas ?? _semanas(),
    ),
  );
  Get.put<TimeBlocksService>(servicio);
  if (cargar) await servicio.load(from: '2026-09-14', to: '2026-10-11');
  return servicio;
}

/// Vertical y más ancho que un teléfono, como en time_blocks_grilla_test.dart:
/// la fuente de las pruebas dibuja cada letra como un cuadrado de su tamaño, y
/// "Miércoles, 23 de Septiembre" a 18 px con sus dos flechas necesita ~620 px
/// (la franja del día desborda en la prueba, no en la app). El horizontal es
/// el de time_blocks_grilla_test.dart.
const Size _vertical = Size(700, 1000);
const Size _horizontal = Size(1000, 500);

/// Monta [HorarioPage] sobre [_cuatroSemanas], en vertical si no se pide otra
/// pantalla. El `Get.put(HorarioController())` del `build` encuentra el
/// doble ya registrado y lo reusa.
Future<TimeBlocksService> _montar(
  WidgetTester tester, {
  List<Map<String, dynamic>>? reglas,
  List<Map<String, dynamic>>? semanas,
  int diaActivo = _lunes21,
  bool cargarAntes = true,
  Size pantalla = _vertical,
}) async {
  tester.view.physicalSize = pantalla;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final servicio = await _registrarBloques(
    reglas: reglas,
    semanas: semanas,
    cargar: cargarAntes,
  );
  Get.put<HorarioController>(
    _HorarioDePrueba(_cuatroSemanas(), diaActivo: diaActivo),
  );

  await tester.pumpWidget(const GetMaterialApp(home: HorarioPage()));
  await tester.pump();
  return servicio;
}

/// Toca la flecha de "día siguiente" de la franja del día.
Future<void> _diaSiguiente(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UNITARIA · el texto de las horas (HorarioPage.textoDeHoras)', () {
    test('una cifra entera va sin decimal', () {
      expect(HorarioPage.textoDeHoras(12), '12 h');
      expect(HorarioPage.textoDeHoras(8.0), '8 h');
      expect(HorarioPage.textoDeHoras(0), '0 h');
    });

    test('una cifra con fracción va con un decimal', () {
      expect(HorarioPage.textoDeHoras(12.5), '12.5 h');
      expect(HorarioPage.textoDeHoras(0.5), '0.5 h');
    });

    test('se redondea a un decimal', () {
      // Una hora y 45 minutos; dos horas y 10 minutos.
      expect(HorarioPage.textoDeHoras(1.75), '1.8 h');
      expect(HorarioPage.textoDeHoras(2 + 10 / 60), '2.2 h');
    });

    test('si al redondear queda entera, va sin decimal: nunca "13.0 h"', () {
      expect(HorarioPage.textoDeHoras(12.96), '13 h');
    });
  });

  group('UNITARIA · el total de la semana del día activo (RF-BLQ-6)', () {
    setUp(() {
      Get.testMode = true;
      Get.reset();
    });
    tearDown(Get.reset);

    test('con bloques, es el hours que manda el servidor para esa semana',
        () async {
      await _registrarBloques();
      final horario = _HorarioDePrueba(_cuatroSemanas(), diaActivo: _miercoles23);

      expect(
        horario.horasDeLaSemanaActiva,
        12,
        reason: 'sale de weeks; la ocurrencia sembrada suma 4 h',
      );
    });

    test('de lunes a domingo, todos los días de la semana dan el mismo total',
        () async {
      await _registrarBloques();
      final horario = _HorarioDePrueba(_cuatroSemanas());

      for (var i = _lunes21; i <= _domingo27; i++) {
        horario.currentDayIndex.value = i;
        expect(
          horario.horasDeLaSemanaActiva,
          12,
          reason: horario.currentDay!.dateText,
        );
      }
    });

    test('del domingo al lunes siguiente, pasa al total de la otra semana',
        () async {
      await _registrarBloques();
      final horario = _HorarioDePrueba(_cuatroSemanas(), diaActivo: _domingo27);
      expect(horario.horasDeLaSemanaActiva, 12);

      horario.nextDay();

      expect(horario.currentDay!.dateText, '28 de Septiembre');
      expect(horario.horasDeLaSemanaActiva, 12.5);
    });

    test('sin bloques no hay total, aunque la semana traiga horas', () async {
      // La spec: sin bloques, la línea no aparece. Sin bloques el servidor
      // manda sus semanas en 0 (RS-BE-34), que ya se ocultan por D3; la
      // prueba siembra 12 h a propósito para fijar esta condición por sí
      // sola.
      await _registrarBloques(reglas: const <Map<String, dynamic>>[]);
      final horario = _HorarioDePrueba(_cuatroSemanas());

      expect(horario.horasDeLaSemanaActiva, isNull);
    });

    test('con hours en null no hay total: no se convierte en 0', () async {
      await _registrarBloques();
      final horario = _HorarioDePrueba(_cuatroSemanas(), diaActivo: _lunes5Oct);

      expect(horario.currentDay!.isoDate, '2026-10-05');
      expect(horario.horasDeLaSemanaActiva, isNull);
    });

    test('si la semana del día activo no vino en weeks, no hay total',
        () async {
      // Una semana no viene cuando cae fuera de la ventana pedida (una semana
      // sin ocurrencias, en cambio, sí viene, con 0: RS-BE-34). Es un dato que
      // falta, y la app no pone un 0 en su lugar.
      await _registrarBloques();
      final horario = _HorarioDePrueba(_cuatroSemanas(), diaActivo: _lunes12Oct);

      expect(horario.currentDay!.isoDate, '2026-10-12');
      expect(horario.horasDeLaSemanaActiva, isNull);
    });

    test('con bloques, una semana en 0 no tiene total: la línea se oculta',
        () async {
      // Pasa de verdad: una semana con todos sus días cancelados, o fuera de
      // las fechas del bloque, llega con hours: 0 (RS-BE-34). La línea solo
      // sale con horas mayores que 0 (D3).
      await _registrarBloques(
        semanas: <Map<String, dynamic>>[
          <String, dynamic>{'weekStart': '2026-09-21', 'hours': 0},
        ],
      );
      final horario = _HorarioDePrueba(_cuatroSemanas());

      expect(horario.horasDeLaSemanaActiva, isNull);
    });

    test('con bloques, una semana que redondeada a un decimal da 0 no tiene total',
        () async {
      // Un bloque de 14:00 a 14:02 en un solo día de la semana llega con
      // hours de 0.033 (el servidor no redondea) y el formulario lo acepta.
      // Pintado saldría "0 h", así que la línea se oculta igual que con 0
      // (D3). Tres minutos (0.05) ya redondean a 0.1 y sí tienen línea.
      await _registrarBloques(
        semanas: <Map<String, dynamic>>[
          <String, dynamic>{'weekStart': '2026-09-21', 'hours': 0.03},
          <String, dynamic>{'weekStart': '2026-09-28', 'hours': 3 / 60},
        ],
      );
      final horario = _HorarioDePrueba(_cuatroSemanas());

      expect(horario.horasDeLaSemanaActiva, isNull);

      horario.currentDayIndex.value = _lunes28;

      expect(horario.horasDeLaSemanaActiva, 3 / 60);
      expect(HorarioPage.textoDeHoras(horario.horasDeLaSemanaActiva!), '0.1 h');
    });

    test('ciclo sin semanas (isoDate null): cuenta la semana de hoy',
        () async {
      await _registrarBloques();
      // Lo que manda el backend cuando el ciclo no tiene semanas: los siete
      // días sin fecha (isoDate null). Hoy es el miércoles 23, así que es la
      // semana del 21.
      final horario = _HorarioDePrueba(
        <DaySchedule>[
          for (final nombre in _nombres) DaySchedule(nombre, '', 'Semana actual'),
        ],
        diaActivo: 4,
        hoy: DateTime.utc(2026, 9, 23, 10),
      );

      expect(horario.horasDeLaSemanaActiva, 12);
    });

    test('sin el service registrado no hay total y nada se cae', () {
      Get.put<AuthService>(_FakeAuthService(_alumna()));
      final horario = _HorarioDePrueba(_cuatroSemanas());

      expect(horario.horasDeLaSemanaActiva, isNull);
    });
  });

  group('WIDGET · la línea en la pantalla de horario (RF-BLQ-6)', () {
    setUp(() {
      Get.testMode = true;
      Get.reset();
    });
    tearDown(Get.reset);

    testWidgets('con bloques, la línea dice el total de la semana del día activo',
        (tester) async {
      await _montar(tester, diaActivo: _miercoles23);

      expect(find.text('Miércoles, 23 de Septiembre'), findsOneWidget);
      expect(find.text('Tus bloques: 12 h esta semana'), findsOneWidget);
      expect(find.byKey(HorarioPage.horasSemanaKey), findsOneWidget);
      // La línea acompaña a la semana del ciclo, no la reemplaza.
      expect(find.text('Semana 5 del ciclo'), findsOneWidget);
    });

    testWidgets('al pasar de día dentro de la misma semana, no cambia',
        (tester) async {
      await _montar(tester, diaActivo: _lunes21);

      for (var i = 0; i < 6; i++) {
        await _diaSiguiente(tester);
      }

      expect(find.text('Domingo, 27 de Septiembre'), findsOneWidget);
      expect(find.text('Tus bloques: 12 h esta semana'), findsOneWidget);
    });

    testWidgets('al saltar a la semana siguiente, cambia', (tester) async {
      await _montar(tester, diaActivo: _domingo27);
      expect(find.text('Tus bloques: 12 h esta semana'), findsOneWidget);

      await _diaSiguiente(tester);

      expect(find.text('Lunes, 28 de Septiembre'), findsOneWidget);
      expect(find.text('Tus bloques: 12.5 h esta semana'), findsOneWidget);
      expect(find.text('Tus bloques: 12 h esta semana'), findsNothing);
    });

    testWidgets('sin bloques la línea no aparece', (tester) async {
      // Con las semanas de siempre (12 h la del 21): lo que la oculta es que
      // no hay bloques.
      await _montar(tester, reglas: const <Map<String, dynamic>>[]);

      expect(find.byKey(HorarioPage.horasSemanaKey), findsNothing);
      expect(find.textContaining('Tus bloques'), findsNothing);
      expect(find.text('Semana 5 del ciclo'), findsOneWidget);
    });

    testWidgets('con hours en null la línea no aparece, ni como 0',
        (tester) async {
      await _montar(tester, diaActivo: _lunes5Oct);

      expect(find.text('Lunes, 5 de Octubre'), findsOneWidget);
      expect(find.byKey(HorarioPage.horasSemanaKey), findsNothing);
      expect(find.textContaining('Tus bloques'), findsNothing);
      expect(find.textContaining('0 h'), findsNothing);
    });

    testWidgets('con bloques y la semana en 0, la línea no aparece',
        (tester) async {
      // RS-BE-34 manda todas las semanas de la ventana, con hours: 0 cuando
      // no tienen ocurrencias (por ejemplo, todos sus días cancelados). La
      // línea solo sale con horas mayores que 0 (D3): nunca "0 h".
      await _montar(
        tester,
        semanas: <Map<String, dynamic>>[
          <String, dynamic>{'weekStart': '2026-09-21', 'hours': 0},
        ],
      );

      expect(find.byKey(HorarioPage.horasSemanaKey), findsNothing);
      expect(find.textContaining('Tus bloques'), findsNothing);
      expect(find.textContaining('0 h'), findsNothing);
      expect(find.text('Semana 5 del ciclo'), findsOneWidget);
    });

    testWidgets('con bloques y una semana de menos de 3 minutos, la línea no aparece',
        (tester) async {
      // 0.03 h redondeado a un decimal es 0: pintada, la línea diría "0 h".
      await _montar(
        tester,
        semanas: <Map<String, dynamic>>[
          <String, dynamic>{'weekStart': '2026-09-21', 'hours': 0.03},
        ],
      );

      expect(find.byKey(HorarioPage.horasSemanaKey), findsNothing);
      expect(find.textContaining('Tus bloques'), findsNothing);
      expect(find.textContaining('0 h'), findsNothing);
      expect(find.text('Semana 5 del ciclo'), findsOneWidget);
    });

    testWidgets('en horizontal la línea también sale, con la semana del día activo',
        (tester) async {
      // La vista semanal pinta los bloques de la semana del día activo
      // (Tarea 4); la línea dice las horas de esa misma semana, en la franja
      // de abajo, junto al ciclo. Con el lunes 28 activo es la semana del 28,
      // la de 12.5 h, y no la de las columnas (la primera, de 12 h).
      await _montar(tester, pantalla: _horizontal, diaActivo: _lunes28);

      expect(find.text('Tus bloques: 12.5 h esta semana'), findsOneWidget);
      expect(find.byKey(HorarioPage.horasSemanaKey), findsOneWidget);
      expect(find.text('2026-2'), findsOneWidget);
    });

    testWidgets('si los bloques llegan después de pintar el horario, la línea aparece sola',
        (tester) async {
      final servicio = await _montar(tester, cargarAntes: false);
      expect(find.byKey(HorarioPage.horasSemanaKey), findsNothing);

      // Es lo que pasa en la app: el horario pinta sus días antes de que
      // vuelvan los bloques, y el service recarga su ventana después de cada
      // escritura. La pantalla no hace nada y tiene que enterarse.
      await servicio.load(from: '2026-09-14', to: '2026-10-11');
      await tester.pump();

      expect(find.text('Tus bloques: 12 h esta semana'), findsOneWidget);
    });
  });
}
