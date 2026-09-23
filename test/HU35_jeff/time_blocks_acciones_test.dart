// test/HU35_jeff/time_blocks_acciones_test.dart
//
// WIDGET + UNITARIA — HU35 (bloques de horario propios): tocar un bloque
// propio (RF-BLQ-5). La hoja de acciones, lo que cada acción le pide al
// service, y la rama nueva del toque en el horario: un bloque propio abre su
// hoja y una clase sigue yendo al detalle de su curso.
// Pantallas: lib/pages/time_blocks/time_block_actions_sheet.dart y el toque de
// lib/pages/horario/horario.dart.
//
// Todos los datos son inventados; el repo es público. La alumna es la
// 20230001, el bloque "Prácticas de prueba" no existe y el curso es "CURSO DE
// PRUEBA A", sección 801: nada sale del portal ni de test/HU31_jeff/fixtures.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/time_block_model.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/descripcion_cursos/descrip_cursos.dart';
import 'package:ulima_plus/pages/descripcion_cursos/descrip_cursos_controller.dart';
import 'package:ulima_plus/pages/horario/horario.dart';
import 'package:ulima_plus/pages/horario/horario_controller.dart';
import 'package:ulima_plus/pages/time_blocks/time_block_actions_sheet.dart';
import 'package:ulima_plus/pages/time_blocks/time_block_form_controller.dart';
import 'package:ulima_plus/pages/time_blocks/time_block_form_page.dart';
import 'package:ulima_plus/pages/time_blocks/time_block_validators.dart';
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

/// El bloque: lunes y miércoles de 14:00 a 18:00. El miércoles 23 ya se
/// movió a 15:00-19:00.
const TimeBlockRule _regla = TimeBlockRule(
  id: 7,
  title: 'Prácticas de prueba',
  colorHex: '#27AE60',
  daysOfWeek: <int>[1, 3],
  startTime: '14:00',
  endTime: '18:00',
  startDate: '2026-09-01',
  endDate: '2026-12-15',
  exceptions: <TimeBlockException>[
    TimeBlockException(
      date: '2026-09-23',
      status: 'moved',
      startTime: '15:00',
      endTime: '19:00',
    ),
  ],
);

/// El lunes 21: un día como cualquier otro del patrón.
const TimeBlockOccurrence _lunes21 = TimeBlockOccurrence(
  blockId: 7,
  title: 'Prácticas de prueba',
  colorHex: '#27AE60',
  date: '2026-09-21',
  dayOfWeek: 1,
  startTime: '14:00',
  endTime: '18:00',
  moved: false,
);

/// El miércoles 23, tal como lo manda el servidor: con sus horas nuevas y
/// `moved: true`.
const TimeBlockOccurrence _miercoles23Movido = TimeBlockOccurrence(
  blockId: 7,
  title: 'Prácticas de prueba',
  colorHex: '#27AE60',
  date: '2026-09-23',
  dayOfWeek: 3,
  startTime: '15:00',
  endTime: '19:00',
  moved: true,
);

/// El mismo bloque con el lunes 21 cancelado: el servidor no manda esa
/// ocurrencia, y la grilla lo pinta tenue desde la excepción de la regla
/// (Tarea 4).
const TimeBlockRule _reglaConLunes21Cancelado = TimeBlockRule(
  id: 7,
  title: 'Prácticas de prueba',
  colorHex: '#27AE60',
  daysOfWeek: <int>[1, 3],
  startTime: '14:00',
  endTime: '18:00',
  startDate: '2026-09-01',
  endDate: '2026-12-15',
  exceptions: <TimeBlockException>[
    TimeBlockException(
      date: '2026-09-21',
      status: 'cancelled',
      startTime: null,
      endTime: null,
    ),
  ],
);

/// Una clase como la devuelve `coursesForDay`: sección y horario aplanados,
/// con las horas en 12 h como las manda `/schedule/me/sessions`.
Map<String, dynamic> _clase(String curso, String inicio, String fin) =>
    <String, dynamic>{
      'idSeccion': '801',
      'codigoSeccion': '801',
      'curso': curso,
      'hora_inicio': inicio,
      'hora_fin': fin,
      'salon': 'AULA 801',
      'color': '#2F80ED',
      'isEvaluation': false,
      'isAdvising': false,
    };

/// La semana del lunes 21 al domingo 27 de septiembre de 2026, con lo que
/// arma el backend para cada día ("21 de Septiembre", `isoDate`
/// "2026-09-21"). La grilla ubica los bloques por `isoDate` (Tarea 4).
List<DaySchedule> _semana() => <DaySchedule>[
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
    ];

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

/// Cliente que no sale a la red: si algo de la hoja lo llamara, la prueba
/// revienta en vez de pegarle a un backend.
class _ApiSinRed extends ApiClient {
  _ApiSinRed() : super(configuredBaseUrl: 'http://test');

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    String? token,
    Map<String, String?> query = const {},
    bool suppressSessionExpiry = false,
  }) =>
      throw StateError('La hoja no debe pedir $path');
}

/// Doble del service: sirve reglas y ocurrencias fijas y anota cada
/// escritura en [llamadas], sin HTTP. La recarga que el service real hace
/// después de escribir no se simula: la hoja no depende de ella.
class _FakeTimeBlocksService extends TimeBlocksService {
  _FakeTimeBlocksService({
    this.reglas = const <TimeBlockRule>[_regla],
    List<TimeBlockOccurrence> ocurrencias = const <TimeBlockOccurrence>[],
  })  : _snapshot = TimeBlocksSnapshot(
          occurrences: ocurrencias,
          weeks: const <TimeBlockWeek>[],
        ),
        super(apiClient: _ApiSinRed());

  final List<TimeBlockRule> reglas;
  final TimeBlocksSnapshot _snapshot;

  /// Cada escritura, como "método id fecha …", en orden.
  final llamadas = <String>[];

  /// Si no es null, toda escritura lo lanza.
  Object? falla;

  /// Si no es null, toda escritura queda en vuelo, ya anotada, hasta que se
  /// complete: como el service real con el backend en frío.
  Completer<void>? espera;

  @override
  List<TimeBlockRule> get blocks => reglas;

  @override
  TimeBlocksSnapshot? get snapshot => _snapshot;

  Future<void> _anotar(String llamada) async {
    if (falla != null) throw falla!;
    llamadas.add(llamada);
    final enVuelo = espera;
    if (enVuelo != null) await enVuelo.future;
  }

  @override
  Future<void> setException(
    int id,
    String date, {
    required String status,
    String? startTime,
    String? endTime,
  }) =>
      _anotar('setException $id $date $status $startTime $endTime');

  @override
  Future<void> clearException(int id, String date) =>
      _anotar('clearException $id $date');

  @override
  Future<void> remove(int id) => _anotar('remove $id');
}

/// El controller del horario sin su carga remota: días y clases sembrados, y
/// el reloj fijo en el 1 de septiembre (así no se pinta la línea de "ahora").
/// `bloquesDelDia` es el real de la Tarea 4: lee el service.
class _HorarioDePrueba extends HorarioController {
  _HorarioDePrueba({required this.clasesDelLunes}) {
    daysList.assignAll(_semana());
    currentLimaTime.value = DateTime.utc(2026, 9, 1, 10);
  }

  final List<Map<String, dynamic>> clasesDelLunes;

  @override
  // ignore: must_call_super
  void onInit() {
    // Sin el onInit real: arranca un Timer.periodic de un minuto y pide el
    // horario con un ApiClient propio. Mismo recurso que la Tarea 4.
  }

  @override
  List<Map<String, dynamic>> coursesForDay(DaySchedule activeDay) =>
      activeDay.dayName == 'Lunes'
          ? clasesDelLunes
          : const <Map<String, dynamic>>[];
}

/// El detalle del curso sin su carga: `DescripCursosPage` hace
/// `Get.put(DescripCursosController())` al construirse y GetX no reemplaza
/// una instancia ya registrada, así que usa esta y no pide nada.
class _DetalleSinCarga extends DescripCursosController {
  @override
  Future<void> cargarDatosCurso(String idSeccion) async {}
}

// --- Montaje ------------------------------------------------------------------

/// Lo que la app le pidió a `SystemChrome.setPreferredOrientations`, en orden.
final _orientaciones = <List<Object?>>[];

/// Lo que recibió la ruta /bloque en `Get.arguments`.
Object? _argumentoDelFormulario;

/// Vertical y horizontal, como en la Tarea 4: el vertical es más ancho que un
/// teléfono porque la fuente de las pruebas dibuja cada letra como un
/// cuadrado y la franja del día desbordaría.
const Size _vertical = Size(600, 1000);
const Size _horizontal = Size(1000, 500);

/// Un iPhone SE (375 x 667), en píxeles físicos con `devicePixelRatio` 2: en
/// vertical para la hoja, y en horizontal (375 de alto) como queda al tocar un
/// bloque desde la vista semanal.
const Size _seVertical = Size(750, 1334);
const Size _seHorizontal = Size(1334, 750);

/// Monta el horario de una alumna con el lunes 21 activo: por omisión, el
/// bloque propio de 14:00 a 18:00 y, si se pide, una clase.
Future<_FakeTimeBlocksService> _montarHorario(
  WidgetTester tester, {
  required Size pantalla,
  List<Map<String, dynamic>> clases = const <Map<String, dynamic>>[],
  List<TimeBlockRule> reglas = const <TimeBlockRule>[_regla],
  List<TimeBlockOccurrence> ocurrencias = const <TimeBlockOccurrence>[_lunes21],
}) async {
  tester.view.physicalSize = pantalla;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  Get.put<AuthService>(_FakeAuthService(_alumna()));
  final service = _FakeTimeBlocksService(
    reglas: reglas,
    ocurrencias: ocurrencias,
  );
  Get.put<TimeBlocksService>(service);
  Get.put<HorarioController>(_HorarioDePrueba(clasesDelLunes: clases));

  await tester.pumpWidget(const GetMaterialApp(home: HorarioPage()));
  await tester.pump();
  return service;
}

/// El bloque del horario que lleva ese título: su [InkWell], que es lo que
/// se toca.
Finder _bloque(String titulo) =>
    find.ancestor(of: find.text(titulo), matching: find.byType(InkWell));

/// App mínima: un botón que abre la hoja como lo hace el toque del horario,
/// y la ruta /bloque, que anota el argumento con que se abrió.
Widget _app(TimeBlockOccurrence ocurrencia, {bool cancelado = false}) =>
    GetMaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => mostrarAccionesDeBloque(
                context,
                ocurrencia,
                cancelado: cancelado,
              ),
              child: const Text('ABRIR'),
            ),
          ),
        ),
      ),
      getPages: [
        GetPage(
          name: '/bloque',
          page: () {
            _argumentoDelFormulario = Get.arguments;
            return const Scaffold(body: Text('FORMULARIO'));
          },
        ),
      ],
    );

/// Pantalla de un iPhone SE (en vertical, si no se pide otra), registra el
/// service y abre la hoja de [ocurrencia] (de un día cancelado, si
/// [cancelado]).
Future<_FakeTimeBlocksService> _abrirHoja(
  WidgetTester tester, {
  required TimeBlockOccurrence ocurrencia,
  List<TimeBlockRule> reglas = const <TimeBlockRule>[_regla],
  Size pantalla = _seVertical,
  bool cancelado = false,
}) async {
  tester.view.physicalSize = pantalla;
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  final service = _FakeTimeBlocksService(reglas: reglas);
  Get.put<TimeBlocksService>(service);
  await tester.pumpWidget(_app(ocurrencia, cancelado: cancelado));
  await tester.tap(find.text('ABRIR'));
  await tester.pumpAndSettle();
  return service;
}

/// Toca una acción de la hoja; si la hoja scrollea, primero la trae a la
/// vista.
Future<void> _tocar(WidgetTester tester, String texto) async {
  await tester.ensureVisible(find.text(texto));
  await tester.tap(find.text(texto));
  await tester.pumpAndSettle();
}

/// Elige una hora con el picker de Flutter. El dial no es lo que se prueba:
/// se pasa a escribirla, en 24 h. Si el diálogo scrollea, primero trae el
/// campo a la vista.
Future<void> _elegirHora(
  WidgetTester tester,
  Key campo, {
  required String hora,
  required String minuto,
}) async {
  await tester.ensureVisible(find.byKey(campo));
  await tester.tap(find.byKey(campo));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.keyboard_outlined));
  await tester.pumpAndSettle();
  final campos = find.descendant(
    of: find.byType(TimePickerDialog),
    matching: find.byType(TextField),
  );
  await tester.enterText(campos.at(0), hora);
  await tester.enterText(campos.at(1), minuto);
  // El botón de aceptar va en español, como en el formulario (D7).
  await tester.tap(find.text(TimeBlockFormPage.pickerAceptar));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.reset();
    _orientaciones.clear();
    _argumentoDelFormulario = null;
    // Doble del canal de plataforma, como en la Tarea 5: sin él,
    // `setPreferredOrientations` espera una respuesta que en la prueba no
    // llega nunca. Responde al toque y anota las orientaciones pedidas.
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

  group('UNITARIA · el resumen del día en la hoja (RF-BLQ-5)', () {
    test('nombra el día, la fecha y las horas', () {
      expect(
        resumenDelDia(_lunes21),
        'Lunes 21 de septiembre, 14:00 a 18:00',
      );
    });

    test('un día movido se resume con sus horas nuevas', () {
      expect(
        resumenDelDia(_miercoles23Movido),
        'Miércoles 23 de septiembre, 15:00 a 19:00',
      );
    });

    test('una fecha ilegible no inventa un día: quedan las horas', () {
      const sinFecha = TimeBlockOccurrence(
        blockId: 7,
        title: 'Prácticas de prueba',
        colorHex: '#27AE60',
        date: '',
        dayOfWeek: 0,
        startTime: '14:00',
        endTime: '18:00',
        moved: false,
      );
      expect(resumenDelDia(sinFecha), '14:00 a 18:00');
    });
  });

  group('WIDGET · tocar un bloque en el horario (RF-BLQ-5)', () {
    testWidgets('tocar un bloque propio abre su hoja, no el detalle de un curso',
        (tester) async {
      await _montarHorario(
        tester,
        pantalla: _vertical,
        clases: [_clase('CURSO DE PRUEBA A', '08:00 am', '10:00 am')],
      );

      await tester.tap(_bloque('PRÁCTICAS DE PRUEBA'));
      await tester.pumpAndSettle();

      expect(find.byType(TimeBlockActionsSheet), findsOneWidget);
      // El nombre como lo escribió la alumna, y qué día es.
      expect(find.text('Prácticas de prueba'), findsOneWidget);
      expect(find.text(resumenDelDia(_lunes21)), findsOneWidget);
      expect(find.byType(DescripCursosPage), findsNothing);
      // Abrir la hoja no toca la orientación: solo el formulario la fija.
      expect(_orientaciones, isEmpty);
    });

    testWidgets('en la vista semanal también abre la hoja, y la hoja cabe',
        (tester) async {
      // 500 px de alto: la hoja modal mide como mucho 9/16 de eso y sus
      // acciones no entran sin scroll. Un desborde haría fallar la prueba.
      await _montarHorario(tester, pantalla: _horizontal);

      await tester.tap(_bloque('PRÁCTICAS DE PRUEBA'));
      await tester.pumpAndSettle();

      expect(find.byType(TimeBlockActionsSheet), findsOneWidget);
      await tester.ensureVisible(find.text(TimeBlockActionsSheet.borrar));
      expect(find.text(TimeBlockActionsSheet.borrar), findsOneWidget);
    });

    testWidgets('tocar una clase sigue llevando al detalle del curso, sin hoja',
        (tester) async {
      Get.put<DescripCursosController>(_DetalleSinCarga());
      await _montarHorario(
        tester,
        pantalla: _vertical,
        clases: [_clase('CURSO DE PRUEBA A', '08:00 am', '10:00 am')],
      );

      await tester.tap(_bloque('CURSO DE PRUEBA A'));
      await tester.pump();
      // Sin pumpAndSettle: el detalle sin datos pinta un SkeletonPulse que
      // anima sin fin.
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(TimeBlockActionsSheet), findsNothing);
      expect(find.byType(DescripCursosPage), findsOneWidget);
      expect(_orientaciones, [
        ['DeviceOrientation.portraitUp'],
      ]);
    });

    testWidgets('tocar un día cancelado abre su hoja, solo con volver al patrón',
        (tester) async {
      // RF-BLQ-5: «si el día está cancelado o movido, la hoja ofrece volver
      // al patrón». El lunes 21 está cancelado: no llega como ocurrencia, y la
      // grilla lo pinta tenue desde la regla (Tarea 4).
      final service = await _montarHorario(
        tester,
        pantalla: _vertical,
        reglas: const <TimeBlockRule>[_reglaConLunes21Cancelado],
        ocurrencias: const <TimeBlockOccurrence>[],
      );

      await tester.tap(_bloque('PRÁCTICAS DE PRUEBA'));
      await tester.pumpAndSettle();

      expect(find.byType(TimeBlockActionsSheet), findsOneWidget);
      expect(find.text(TimeBlockActionsSheet.volverAlPatron), findsOneWidget);
      expect(find.text(TimeBlockActionsSheet.cancelarDia), findsNothing);
      await _tocar(tester, TimeBlockActionsSheet.volverAlPatron);

      expect(service.llamadas, ['clearException 7 2026-09-21']);
    });
  });

  group('WIDGET · la hoja de acciones de un bloque propio (RF-BLQ-5)', () {
    testWidgets(
        'un día normal ofrece editar, cancelar, cambiar la hora y borrar, sin volver al patrón',
        (tester) async {
      final service = await _abrirHoja(tester, ocurrencia: _lunes21);

      for (final texto in const [
        TimeBlockActionsSheet.editar,
        TimeBlockActionsSheet.editarDetalle,
        TimeBlockActionsSheet.cancelarDia,
        TimeBlockActionsSheet.cambiarHora,
        TimeBlockActionsSheet.borrar,
      ]) {
        expect(find.text(texto), findsOneWidget, reason: texto);
      }
      expect(find.text(TimeBlockActionsSheet.volverAlPatron), findsNothing);
      // Abrir la hoja no escribe nada.
      expect(service.llamadas, isEmpty);
    });

    testWidgets('un día movido ofrece volver al patrón, y lo devuelve',
        (tester) async {
      final service = await _abrirHoja(tester, ocurrencia: _miercoles23Movido);

      expect(find.text(TimeBlockActionsSheet.volverAlPatron), findsOneWidget);
      await _tocar(tester, TimeBlockActionsSheet.volverAlPatron);

      expect(find.byType(TimeBlockActionsSheet), findsNothing);
      expect(service.llamadas, ['clearException 7 2026-09-23']);
    });

    testWidgets(
        'la hoja de un día cancelado ofrece solo volver al patrón, y llama a clearException con su fecha',
        (tester) async {
      final service = await _abrirHoja(
        tester,
        ocurrencia: _lunes21,
        cancelado: true,
      );

      expect(find.text(TimeBlockActionsSheet.volverAlPatron), findsOneWidget);
      expect(
        find.text(TimeBlockActionsSheet.diaCanceladoDetalle),
        findsOneWidget,
      );
      for (final texto in const [
        TimeBlockActionsSheet.editar,
        TimeBlockActionsSheet.cancelarDia,
        TimeBlockActionsSheet.cambiarHora,
        TimeBlockActionsSheet.borrar,
      ]) {
        expect(find.text(texto), findsNothing, reason: texto);
      }

      await _tocar(tester, TimeBlockActionsSheet.volverAlPatron);

      expect(find.byType(TimeBlockActionsSheet), findsNothing);
      expect(service.llamadas, ['clearException 7 2026-09-21']);
    });

    testWidgets('editar abre /bloque con la regla del bloque, en vertical',
        (tester) async {
      final service = await _abrirHoja(tester, ocurrencia: _miercoles23Movido);

      await _tocar(tester, TimeBlockActionsSheet.editar);

      expect(Get.currentRoute, '/bloque');
      // La REGLA, no la ocurrencia: el formulario edita todas las semanas.
      expect(_argumentoDelFormulario, same(_regla));
      expect(_orientaciones, [
        ['DeviceOrientation.portraitUp'],
      ]);

      Get.back<dynamic>();
      await tester.pumpAndSettle();
      // Al volver, el horario recupera su rotación.
      expect(_orientaciones.last, [
        'DeviceOrientation.portraitUp',
        'DeviceOrientation.landscapeLeft',
        'DeviceOrientation.landscapeRight',
      ]);
      // Editar lo guarda el formulario, no la hoja.
      expect(service.llamadas, isEmpty);
    });

    testWidgets(
        'editar no abre /bloque mientras el formulario anterior sigue '
        'cerrándose', (tester) async {
      // get 4.7.3 borra el controller del formulario recién al terminar la
      // animación de salida de /bloque. Mientras siga registrado, el binding
      // se lo daría a la ruta nueva, que ignoraría esta regla y quedaría con
      // un controller por liberar. La hoja no navega, igual que el botón de
      // agregar del horario.
      final service = await _abrirHoja(tester, ocurrencia: _miercoles23Movido);
      Get.put<TimeBlockFormController>(TimeBlockFormController());

      await _tocar(tester, TimeBlockActionsSheet.editar);

      expect(find.byType(TimeBlockActionsSheet), findsNothing);
      expect(Get.currentRoute, isNot('/bloque'));
      expect(find.text('FORMULARIO'), findsNothing);
      expect(_argumentoDelFormulario, isNull);
      // Tampoco fija la orientación: no hay formulario al que volver.
      expect(_orientaciones, isEmpty);
      expect(service.llamadas, isEmpty);
    });

    testWidgets('sin la regla del bloque a mano no ofrece editar',
        (tester) async {
      await _abrirHoja(
        tester,
        ocurrencia: _lunes21,
        reglas: const <TimeBlockRule>[],
      );

      expect(find.text(TimeBlockActionsSheet.editar), findsNothing);
      expect(find.text(TimeBlockActionsSheet.cancelarDia), findsOneWidget);
    });

    testWidgets('cancelar solo este día manda la fecha de ese día',
        (tester) async {
      final service = await _abrirHoja(tester, ocurrencia: _lunes21);

      await _tocar(tester, TimeBlockActionsSheet.cancelarDia);

      expect(service.llamadas, ['setException 7 2026-09-21 cancelled null null']);
      expect(find.text(TimeBlockActionsSheet.diaCancelado), findsOneWidget);
    });

    testWidgets('la cancelación se deshace desde el aviso: el día vuelve al patrón',
        (tester) async {
      // Un atajo: el día cancelado también se devuelve desde su hoja (se
      // pinta tenue), pero justo después de cancelarlo basta con Deshacer.
      final service = await _abrirHoja(tester, ocurrencia: _lunes21);
      await _tocar(tester, TimeBlockActionsSheet.cancelarDia);

      await tester.tap(find.text(TimeBlockActionsSheet.deshacer));
      await tester.pumpAndSettle();

      expect(service.llamadas, [
        'setException 7 2026-09-21 cancelled null null',
        'clearException 7 2026-09-21',
      ]);
    });

    testWidgets(
        'deshacer la cancelación de un día movido lo devuelve a sus horas movidas',
        (tester) async {
      // Deshacer deja el día como estaba, no en el patrón: el miércoles 23 ya
      // iba de 15:00 a 19:00.
      final service = await _abrirHoja(tester, ocurrencia: _miercoles23Movido);
      await _tocar(tester, TimeBlockActionsSheet.cancelarDia);

      await tester.tap(find.text(TimeBlockActionsSheet.deshacer));
      await tester.pumpAndSettle();

      expect(service.llamadas, [
        'setException 7 2026-09-23 cancelled null null',
        'setException 7 2026-09-23 moved 15:00 19:00',
      ]);
    });

    testWidgets('un error del servidor se muestra tal cual llega',
        (tester) async {
      final service = await _abrirHoja(tester, ocurrencia: _lunes21);
      service.falla = const TimeBlocksFailure('Mensaje inventado del servidor.');

      await _tocar(tester, TimeBlockActionsSheet.cancelarDia);

      expect(find.text('Mensaje inventado del servidor.'), findsOneWidget);
      expect(find.text(TimeBlockActionsSheet.diaCancelado), findsNothing);
      expect(service.llamadas, isEmpty);
    });

    testWidgets('un fallo sin mensaje del servidor también avisa',
        (tester) async {
      final service = await _abrirHoja(tester, ocurrencia: _lunes21);
      service.falla = StateError('inesperado');

      await _tocar(tester, TimeBlockActionsSheet.borrar);
      await tester.tap(find.text(TimeBlockActionsSheet.borrarConfirmar));
      await tester.pumpAndSettle();

      expect(find.text(TimeBlocksService.genericErrorMessage), findsOneWidget);
      expect(service.llamadas, isEmpty);
    });

    testWidgets('el aviso con "Deshacer" se cierra solo: no queda de pantalla en pantalla',
        (tester) async {
      // Desde Flutter 3.38 un SnackBar con botón se queda por omisión hasta
      // que lo tocan, y deja en cola los avisos de las otras pantallas. El de
      // Deshacer lleva persist: false y se va a los 4 s.
      await _abrirHoja(tester, ocurrencia: _lunes21);
      await _tocar(tester, TimeBlockActionsSheet.cancelarDia);
      expect(find.text(TimeBlockActionsSheet.diaCancelado), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(find.text(TimeBlockActionsSheet.diaCancelado), findsNothing);
    });

    testWidgets('un aviso nuevo reemplaza al de "Deshacer"', (tester) async {
      // Mientras un aviso está en pantalla, el messenger pone en cola lo que
      // llega después: sin reemplazarlo, este error esperaría a que el de
      // Deshacer se fuera.
      final service = await _abrirHoja(tester, ocurrencia: _lunes21);
      await _tocar(tester, TimeBlockActionsSheet.cancelarDia);
      expect(find.text(TimeBlockActionsSheet.diaCancelado), findsOneWidget);

      service.falla = const TimeBlocksFailure('Mensaje inventado del servidor.');
      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle();
      await _tocar(tester, TimeBlockActionsSheet.borrar);
      await tester.tap(find.text(TimeBlockActionsSheet.borrarConfirmar));
      await tester.pumpAndSettle();

      expect(find.text('Mensaje inventado del servidor.'), findsOneWidget);
      expect(find.text(TimeBlockActionsSheet.diaCancelado), findsNothing);
    });

    testWidgets(
        'elegir otra acción quita el "Deshacer" de la cancelación anterior',
        (tester) async {
      // El miércoles 23 estaba movido: se cancela y después se devuelve al
      // patrón, que sale bien y no muestra aviso propio. Un «Deshacer» que
      // siguiera en pantalla volvería a moverlo y desharía la última
      // elección de la alumna.
      final service = await _abrirHoja(tester, ocurrencia: _miercoles23Movido);
      await _tocar(tester, TimeBlockActionsSheet.cancelarDia);
      expect(find.text(TimeBlockActionsSheet.deshacer), findsOneWidget);

      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle();
      await _tocar(tester, TimeBlockActionsSheet.volverAlPatron);

      expect(find.text(TimeBlockActionsSheet.deshacer), findsNothing);
      expect(find.text(TimeBlockActionsSheet.diaCancelado), findsNothing);
      expect(service.llamadas, [
        'setException 7 2026-09-23 cancelled null null',
        'clearException 7 2026-09-23',
      ]);
    });

    testWidgets(
        'cambiar la hora usa los pickers del formulario y los mismos validadores',
        (tester) async {
      tester.platformDispatcher.alwaysUse24HourFormatTestValue = true;
      addTearDown(tester.platformDispatcher.clearAlwaysUse24HourTestValue);
      final service = await _abrirHoja(tester, ocurrencia: _lunes21);

      await _tocar(tester, TimeBlockActionsSheet.cambiarHora);

      // Arranca con las horas de ese día.
      expect(find.byKey(TimeBlockActionsSheet.cambiarHoraKey), findsOneWidget);
      expect(find.text('14:00'), findsOneWidget);
      expect(find.text('18:00'), findsOneWidget);

      // Terminar a la 1 pm, antes de empezar: no guarda y dice por qué.
      await _elegirHora(
        tester,
        TimeBlockActionsSheet.horaFinKey,
        hora: '13',
        minuto: '00',
      );
      expect(find.text('13:00'), findsOneWidget);
      await tester.tap(find.text(TimeBlockActionsSheet.guardarLabel));
      await tester.pumpAndSettle();
      expect(find.text(validarHoras('14:00', '13:00')!), findsOneWidget);
      expect(service.llamadas, isEmpty);

      // Hasta las 7:30 pm sí: ese día queda movido y el patrón no cambia.
      await _elegirHora(
        tester,
        TimeBlockActionsSheet.horaFinKey,
        hora: '19',
        minuto: '30',
      );
      await tester.tap(find.text(TimeBlockActionsSheet.guardarLabel));
      await tester.pumpAndSettle();

      expect(find.byKey(TimeBlockActionsSheet.cambiarHoraKey), findsNothing);
      expect(service.llamadas, ['setException 7 2026-09-21 moved 14:00 19:30']);
    });

    testWidgets('cambiar la hora cabe en un iPhone SE en horizontal',
        (tester) async {
      // Desde la vista semanal también se toca un bloque, y ahí quedan 375 px
      // de alto. Un desborde haría fallar la prueba.
      tester.platformDispatcher.alwaysUse24HourFormatTestValue = true;
      addTearDown(tester.platformDispatcher.clearAlwaysUse24HourTestValue);
      final service = await _abrirHoja(
        tester,
        ocurrencia: _lunes21,
        pantalla: _seHorizontal,
      );

      await _tocar(tester, TimeBlockActionsSheet.cambiarHora);
      await _elegirHora(
        tester,
        TimeBlockActionsSheet.horaFinKey,
        hora: '13',
        minuto: '00',
      );
      await tester.tap(find.text(TimeBlockActionsSheet.guardarLabel));
      await tester.pumpAndSettle();

      // El porqué se ve: no queda escondido debajo del borde.
      expect(
        find.text(validarHoras('14:00', '13:00')!).hitTestable(),
        findsOneWidget,
      );
      expect(service.llamadas, isEmpty);
    });

    testWidgets('borrar pide confirmación, y "Cancelar" no borra',
        (tester) async {
      final service = await _abrirHoja(tester, ocurrencia: _lunes21);

      await _tocar(tester, TimeBlockActionsSheet.borrar);

      expect(find.byKey(TimeBlockActionsSheet.confirmarBorradoKey), findsOneWidget);
      expect(find.text(TimeBlockActionsSheet.borrarTitulo), findsOneWidget);
      // Dice que se va el bloque entero, con todos sus días.
      final cuerpo = TimeBlockActionsSheet.borrarCuerpo('Prácticas de prueba');
      expect(cuerpo, contains('todos sus días'));
      expect(find.text(cuerpo), findsOneWidget);

      await tester.tap(find.text(TimeBlockActionsSheet.cancelarLabel));
      await tester.pumpAndSettle();

      expect(find.byKey(TimeBlockActionsSheet.confirmarBorradoKey), findsNothing);
      expect(service.llamadas, isEmpty);
    });

    testWidgets(
        'confirmar el borrado borra el bloque entero y espera con un '
        'indicador que tapa el horario', (tester) async {
      final service = await _abrirHoja(tester, ocurrencia: _lunes21);

      await _tocar(tester, TimeBlockActionsSheet.borrar);
      // El borrado queda en vuelo: con el backend en frío, la escritura y la
      // recarga que la sigue pueden tardar hasta 30 s.
      service.espera = Completer<void>();
      await tester.tap(find.text(TimeBlockActionsSheet.borrarConfirmar));
      // Sin pumpAndSettle: el indicador gira sin fin.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(service.llamadas, ['remove 7']);

      // Mientras tanto, tocar el horario no reabre la hoja: el botón hace aquí
      // el papel del bloque, y la espera lo tapa.
      await tester.tap(find.text('ABRIR'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(TimeBlockActionsSheet.borrar), findsNothing);

      // El botón atrás tampoco lo quita.
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      service.espera!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(service.llamadas, ['remove 7']);
    });
  });
}
