// test/HU35_jeff/time_blocks_form_test.dart
//
// WIDGET — HU35 (bloques de horario propios): el formulario de un bloque
// (RF-BLQ-2), su aviso de cruce antes de guardar (RF-BLQ-3) y el botón que lo
// abre desde el horario, solo para alumnos (RF-BLQ-1).
// Pantallas: lib/pages/time_blocks/time_block_form_page.dart y el botón de
// lib/pages/horario/horario.dart.
//
// Todos los datos son inventados; el repo es público. La alumna es la
// 20230001, el docente es "docente.test" (el mismo de test/HU34_jeff) y el
// curso es "CURSO DE PRUEBA A", sección 801: nada sale del portal.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/main.dart';
import 'package:ulima_plus/models/time_block_model.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/horario/horario.dart';
import 'package:ulima_plus/pages/horario/horario_controller.dart';
import 'package:ulima_plus/pages/time_blocks/time_block_conflicts.dart';
import 'package:ulima_plus/pages/time_blocks/time_block_form_binding.dart';
import 'package:ulima_plus/pages/time_blocks/time_block_form_controller.dart';
import 'package:ulima_plus/pages/time_blocks/time_block_form_page.dart';
import 'package:ulima_plus/pages/time_blocks/time_block_validators.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/time_blocks_service.dart';

UserModel _alumna() => UserModel(
      code: '20230001',
      firstName: 'Alumna',
      lastName: 'De Prueba',
      email: 'test@aloe.ulima.edu.pe',
      role: 'student',
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

/// Cliente que no sale a la red: si algo del formulario lo llamara, la prueba
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
      throw StateError('El formulario no debe pedir $path');
}

/// Doble del service: guarda lo que le piden y responde sin HTTP.
class _FakeTimeBlocksService extends TimeBlocksService {
  _FakeTimeBlocksService({List<TimeBlockRule> bloques = const []})
      : _bloques = bloques,
        super(apiClient: _ApiSinRed());

  final List<TimeBlockRule> _bloques;
  final creados = <TimeBlockInput>[];
  final editados = <({int id, TimeBlockInput input})>[];

  /// Si no es null, `create` y `update` lo lanzan.
  Object? falla;

  /// Si no es null, `create` se queda esperando a que la prueba lo complete:
  /// así se ve el formulario A MITAD del guardado.
  Completer<void>? espera;

  @override
  List<TimeBlockRule> get blocks => _bloques;

  @override
  Future<TimeBlockRule> create(TimeBlockInput input) async {
    if (espera != null) await espera!.future;
    if (falla != null) throw falla!;
    creados.add(input);
    return _reglaDe(99, input);
  }

  @override
  Future<TimeBlockRule> update(int id, TimeBlockInput input) async {
    if (falla != null) throw falla!;
    editados.add((id: id, input: input));
    return _reglaDe(id, input);
  }
}

TimeBlockRule _reglaDe(int id, TimeBlockInput i) => TimeBlockRule(
      id: id,
      title: i.title,
      colorHex: i.colorHex,
      daysOfWeek: i.daysOfWeek,
      startTime: i.startTime,
      endTime: i.endTime,
      startDate: i.startDate,
      endDate: i.endDate,
      exceptions: const <TimeBlockException>[],
    );

/// Bloque inventado: lunes y miércoles de 14:00 a 18:00.
TimeBlockRule _practicas() => const TimeBlockRule(
      id: 12,
      title: 'Prácticas',
      colorHex: '#27AE60',
      daysOfWeek: <int>[1, 3],
      startTime: '14:00',
      endTime: '18:00',
      startDate: '2026-09-01',
      endDate: '2026-12-15',
      exceptions: <TimeBlockException>[],
    );

/// Una clase inventada con la forma de `/schedule/me/sessions`: martes de
/// 4:00 pm a 6:00 pm.
Map<String, dynamic> _claseDelMartes() => <String, dynamic>{
      'idSeccion': '801',
      'codigoSeccion': '801',
      'curso': 'CURSO DE PRUEBA A',
      'horarios': <dynamic>[
        <String, dynamic>{
          'dia': 'Martes',
          'inicio': '16:00:00',
          'hora_inicio': '4:00 pm',
          'fin': '18:00:00',
          'hora_fin': '6:00 pm',
          'salon': 'A-101',
          'color': '#2F80ED',
        },
      ],
    };

/// El horario en pantalla, con las clases que se le pasen. Es lo único que
/// une el formulario con las clases de verdad: `seccionesDelHorario()` lee
/// `uniqueEnrolledCourses` del `HorarioController` registrado. Sin su
/// `onInit` (reloj y carga remota), como en las pruebas de la grilla.
class _HorarioConClases extends HorarioController {
  _HorarioConClases(this.clases);

  final List<Map<String, dynamic>> clases;

  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  List<Map<String, dynamic>> get uniqueEnrolledCourses => clases;
}

/// App mínima: una pantalla de partida y la ruta /bloque con su binding REAL.
Widget _app() => GetMaterialApp(
      initialRoute: '/inicio',
      getPages: [
        GetPage(
          name: '/inicio',
          page: () => const Scaffold(body: Text('INICIO')),
        ),
        GetPage(
          name: '/bloque',
          page: () => const TimeBlockFormPage(),
          binding: TimeBlockFormBinding(),
        ),
      ],
    );

/// Lo mínimo de /bloque para las pruebas del botón del horario. Resuelve el
/// controller en su `build`, como `TimeBlockFormPage`: así el binding REAL lo
/// crea y GetX lo ata a la ruta, y al cerrarla lo borra como en la app. Dice
/// "FORMULARIO" si abre para crear, que es lo que pide el botón.
class _FormularioDePrueba extends StatelessWidget {
  const _FormularioDePrueba();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TimeBlockFormController>();
    return Scaffold(body: Text(c.editando ? 'EDITANDO' : 'FORMULARIO'));
  }
}

/// Pantalla de un iPhone SE en vertical (375 x 667). La superficie por defecto
/// de las pruebas es 800 x 600, o sea HORIZONTAL, y ahí el horario esconde el
/// botón de agregar: una prueba de "el docente no lo ve" pasaría por la razón
/// equivocada. El ancho chico, además, pone a prueba los siete días en fila.
void _telefonoVertical(WidgetTester tester) {
  tester.view.physicalSize = const Size(750, 1334);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

/// Registra los dobles, monta la app y abre el formulario (con o sin bloque).
Future<_FakeTimeBlocksService> _abrirFormulario(
  WidgetTester tester, {
  TimeBlockRule? bloque,
  List<TimeBlockRule> bloques = const [],
  List<Map<String, dynamic>> secciones = const [],
}) async {
  _telefonoVertical(tester);
  Get.put<AuthService>(_FakeAuthService(_alumna()));
  final service = _FakeTimeBlocksService(bloques: bloques);
  Get.put<TimeBlocksService>(service);
  await tester.pumpWidget(_app());
  await tester.pumpAndSettle();
  // Si la prueba pide clases, el controller se registra antes de navegar con
  // esas clases: el binding usa `lazyPut`, que no pisa lo ya registrado. Sin
  // bloque en los argumentos, crear así es idéntico a crear desde la ruta.
  if (secciones.isNotEmpty) {
    Get.put<TimeBlockFormController>(
      TimeBlockFormController(secciones: () => secciones),
    );
  }
  Get.toNamed<dynamic>('/bloque', arguments: bloque);
  await tester.pumpAndSettle();
  return service;
}

TimeBlockFormController get _c => Get.find<TimeBlockFormController>();

/// Llena lo que el alumno escribe o toca en widgets PROPIOS (nombre, color y
/// días). Las horas y las fechas se fijan en el controller: los pickers son de
/// Flutter (`showTimePicker`, `showDatePicker`) y su dial no es lo que se prueba.
Future<void> _llenar(
  WidgetTester tester, {
  String nombre = 'Prácticas',
  List<String> dias = const ['Ma'],
  TimeOfDay inicio = const TimeOfDay(hour: 14, minute: 0),
  TimeOfDay fin = const TimeOfDay(hour: 18, minute: 0),
}) async {
  await tester.enterText(find.byKey(TimeBlockFormPage.nombreKey), nombre);
  await tester.tap(find.byKey(TimeBlockFormPage.colorKey('#EB5757')));
  for (final d in dias) {
    // Un pump por toque: el SegmentedButton entrega el conjunto COMPLETO y
    // tiene que haberse repintado con el anterior antes del siguiente toque.
    await tester.tap(find.text(d));
    await tester.pump();
  }
  _c.inicio.value = inicio;
  _c.fin.value = fin;
  _c.desde.value = DateTime(2026, 9, 1);
  _c.hasta.value = DateTime(2026, 12, 15);
  await tester.pump();
}

Future<void> _guardar(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(TimeBlockFormPage.guardarKey));
  await tester.tap(find.byKey(TimeBlockFormPage.guardarKey));
  await tester.pumpAndSettle();
}

/// `HorarioPage` hace `Get.put(HorarioController())` dentro de `build`, y ese
/// controller arranca un `Timer.periodic` de un minuto. Hay que desmontar el
/// árbol y borrarlo ANTES de que termine la prueba o el binding falla con
/// "A Timer is still pending even after the widget tree was disposed".
Future<void> _desmontarHorario(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await Get.delete<HorarioController>(force: true);
}

/// Lo que la app le pidió a `SystemChrome.setPreferredOrientations`, en orden.
final _orientaciones = <List<Object?>>[];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.reset();
    // Doble del canal de plataforma. Sin él, `setPreferredOrientations` espera
    // una respuesta que en la prueba no llega nunca y el botón del horario se
    // queda sin navegar. Responde al toque y anota las orientaciones pedidas.
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
    Get.reset();
  });

  group('WIDGET · ruta /bloque (RF-BLQ-1)', () {
    testWidgets('la ruta /bloque vive en main.dart con su binding',
        (tester) async {
      // Monta la app REAL: lo que se blinda es la cadena GetPage → binding →
      // pantalla. Con una tabla de rutas escrita en la prueba, la ruta podría
      // faltar en main.dart y nadie se enteraría hasta abrir la app.
      Get.put<AuthService>(_FakeAuthService(_alumna()));
      Get.put<TimeBlocksService>(_FakeTimeBlocksService());

      await tester.pumpWidget(const MyApp(initialRoute: '/bloque'));
      await tester.pumpAndSettle();

      expect(find.byType(TimeBlockFormPage), findsOneWidget);
      expect(Get.currentRoute, '/bloque');
      expect(find.text(TimeBlockFormPage.tituloCrear), findsOneWidget);
    });
  });

  group('WIDGET · formulario de un bloque (RF-BLQ-2)', () {
    testWidgets('se abre vacío, en orden, y crea el bloque con el contrato',
        (tester) async {
      final service = await _abrirFormulario(tester);

      expect(find.text(TimeBlockFormPage.tituloCrear), findsOneWidget);
      expect(_c.nombre.text, isEmpty);
      expect(_c.dias, isEmpty);
      expect(_c.inicio.value, isNull);
      expect(_c.desde.value, isNull);
      // Los doce colores de la paleta de cursos, como círculos.
      for (final color in const [
        '#2F80ED', '#27AE60', '#EB5757', '#9B51E0', '#EC4899', '#F2994A',
        '#00B8A9', '#F2C94C', '#00A2C7', '#7CB518', '#8B6D5C', '#5B5BD6',
      ]) {
        expect(find.byKey(TimeBlockFormPage.colorKey(color)), findsOneWidget);
      }
      // Los siete días, de lunes a domingo.
      for (final d in TimeBlockFormPage.diasLabels) {
        expect(find.text(d), findsOneWidget);
      }
      // Orden de la spec: nombre, color, días, horas, desde y hasta.
      final ys = [
        TimeBlockFormPage.nombreKey,
        TimeBlockFormPage.colorKey('#2F80ED'),
        TimeBlockFormPage.diasKey,
        TimeBlockFormPage.horaInicioKey,
        TimeBlockFormPage.desdeKey,
      ].map((k) => tester.getTopLeft(find.byKey(k)).dy).toList();
      expect(ys, orderedEquals([...ys]..sort()));

      await _llenar(tester, nombre: '  Prácticas  ', dias: const ['Mi', 'Lu']);
      await _guardar(tester);

      expect(service.creados, hasLength(1));
      final enviado = service.creados.single;
      expect(enviado.title, 'Prácticas');
      expect(enviado.colorHex, '#EB5757');
      expect(enviado.daysOfWeek, [1, 3]); // 1 es lunes, como en el servidor
      expect(enviado.startTime, '14:00');
      expect(enviado.endTime, '18:00');
      expect(enviado.startDate, '2026-09-01');
      expect(enviado.endDate, '2026-12-15');
      expect(service.editados, isEmpty);
      // Guardó y volvió al horario.
      expect(Get.currentRoute, '/inicio');
    });

    testWidgets('se abre con un bloque, trae sus valores y edita ese id',
        (tester) async {
      final service = await _abrirFormulario(
        tester,
        bloque: _practicas(),
        // El mismo bloque está en la lista del service: al editar no puede
        // cruzarse consigo mismo, así que NO debe salir el aviso.
        bloques: [_practicas()],
      );

      expect(find.text(TimeBlockFormPage.tituloEditar), findsOneWidget);
      expect(_c.nombre.text, 'Prácticas');
      expect(_c.colorHex.value, '#27AE60');
      expect(_c.dias, {1, 3});
      expect(_c.inicioTexto, '14:00');
      expect(_c.finTexto, '18:00');
      expect(_c.desdeTexto, '2026-09-01');
      expect(_c.hastaTexto, '2026-12-15');
      expect(find.text('14:00'), findsOneWidget);
      expect(find.text('2026-12-15'), findsOneWidget);

      _c.fin.value = const TimeOfDay(hour: 19, minute: 0);
      await tester.pump();
      await _guardar(tester);

      expect(find.byKey(TimeBlockFormPage.avisoCruceKey), findsNothing);
      expect(service.creados, isEmpty);
      expect(service.editados, hasLength(1));
      expect(service.editados.single.id, 12);
      expect(service.editados.single.input.endTime, '19:00');
      expect(Get.currentRoute, '/inicio');
    });

    testWidgets('sin días marcados no guarda y dice por qué', (tester) async {
      final service = await _abrirFormulario(tester);
      await _llenar(tester, dias: const []);
      await _guardar(tester);

      expect(find.text(validarDias(<int>{})!), findsOneWidget);
      expect(service.creados, isEmpty);
      expect(Get.currentRoute, '/bloque');
    });

    testWidgets('hora de fin antes de la de inicio: no guarda y dice por qué',
        (tester) async {
      final service = await _abrirFormulario(tester);
      await _llenar(
        tester,
        inicio: const TimeOfDay(hour: 18, minute: 0),
        fin: const TimeOfDay(hour: 16, minute: 0),
      );
      await _guardar(tester);

      expect(find.text(validarHoras('18:00', '16:00')!), findsOneWidget);
      expect(service.creados, isEmpty);
      expect(Get.currentRoute, '/bloque');
    });

    testWidgets('fuera de 7 am–10 pm: no guarda y dice por qué', (tester) async {
      final service = await _abrirFormulario(tester);
      await _llenar(
        tester,
        inicio: const TimeOfDay(hour: 6, minute: 0),
        fin: const TimeOfDay(hour: 8, minute: 0),
      );
      await _guardar(tester);

      expect(find.text(validarHoras('06:00', '08:00')!), findsOneWidget);
      expect(service.creados, isEmpty);

      // Y por arriba: terminar a las 22:30 tampoco entra en la grilla.
      _c.inicio.value = const TimeOfDay(hour: 20, minute: 0);
      _c.fin.value = const TimeOfDay(hour: 22, minute: 30);
      await tester.pump();
      await _guardar(tester);

      expect(find.text(validarHoras('20:00', '22:30')!), findsOneWidget);
      expect(service.creados, isEmpty);
      expect(Get.currentRoute, '/bloque');
    });

    testWidgets('un error del servidor se muestra tal cual llega',
        (tester) async {
      final service = await _abrirFormulario(tester);
      service.falla = TimeBlocksFailure('Mensaje inventado del servidor.');
      await _llenar(tester);
      await _guardar(tester);

      expect(find.text('Mensaje inventado del servidor.'), findsOneWidget);
      expect(Get.currentRoute, '/bloque');
    });

    testWidgets('un fallo sin mensaje del servidor no deja el botón mudo',
        (tester) async {
      final service = await _abrirFormulario(tester);
      service.falla = StateError('inesperado');
      await _llenar(tester);
      await _guardar(tester);

      expect(find.text(TimeBlockFormController.errorGenerico), findsOneWidget);
      expect(Get.currentRoute, '/bloque');
      // El botón vuelve a estar disponible para reintentar.
      final boton = tester.widget<ElevatedButton>(
        find.byKey(TimeBlockFormPage.guardarKey),
      );
      expect(boton.onPressed, isNotNull);
    });

    testWidgets('mientras guarda no deja salir, y al terminar vuelve solo',
        (tester) async {
      final service = await _abrirFormulario(tester);
      service.espera = Completer<void>();
      await _llenar(tester);
      await tester.ensureVisible(find.byKey(TimeBlockFormPage.guardarKey));
      await tester.tap(find.byKey(TimeBlockFormPage.guardarKey));
      // Sin pumpAndSettle: el indicador de "guardando" gira sin fin.
      await tester.pump();

      final boton = tester.widget<ElevatedButton>(
        find.byKey(TimeBlockFormPage.guardarKey),
      );
      expect(boton.onPressed, isNull); // no se puede tocar dos veces

      // La flecha de la barra intenta salir a mitad del guardado: no sale.
      await tester.tap(find.byType(BackButton));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(Get.currentRoute, '/bloque');

      service.espera!.complete();
      await tester.pumpAndSettle();

      expect(service.creados, hasLength(1));
      expect(Get.currentRoute, '/inicio');
    });

    testWidgets('las horas y las fechas se eligen con los pickers de Flutter',
        (tester) async {
      await _abrirFormulario(tester);

      await tester.tap(find.byKey(TimeBlockFormPage.horaInicioKey));
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsOneWidget);
      // El título y los botones van en español (D7), no los de Flutter.
      expect(find.text(TimeBlockFormPage.pickerHoraTitulo), findsOneWidget);
      expect(find.text(TimeBlockFormPage.pickerCancelar), findsOneWidget);
      expect(find.text('OK'), findsNothing);
      // Aceptar sin mover el dial deja la hora que el picker propone.
      await tester.tap(find.text(TimeBlockFormPage.pickerAceptar));
      await tester.pumpAndSettle();
      expect(_c.inicioTexto, '14:00');
      expect(find.text('14:00'), findsOneWidget);

      await tester.ensureVisible(find.byKey(TimeBlockFormPage.desdeKey));
      await tester.tap(find.byKey(TimeBlockFormPage.desdeKey));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(find.text(TimeBlockFormPage.pickerFechaTitulo), findsOneWidget);
      await tester.tap(find.text(TimeBlockFormPage.pickerAceptar));
      await tester.pumpAndSettle();
      // La fecha propuesta es la de hoy: basta con que haya llegado.
      expect(_c.desde.value, isNotNull);
      expect(find.text(_c.desdeTexto!), findsOneWidget);
    });
  });

  group('WIDGET · aviso de cruce antes de guardar (RF-BLQ-3)', () {
    testWidgets('con cruce muestra el aviso y, al confirmar, guarda',
        (tester) async {
      final clase = _claseDelMartes();
      final service = await _abrirFormulario(tester, secciones: [clase]);
      // Martes de 14:00 a 18:00 contra la clase del martes de 4 a 6 pm.
      await _llenar(tester, dias: const ['Ma']);
      await _guardar(tester);

      final esperado = mensajeDeCruce(
        crucesDeBloque(
          dias: {2},
          inicio: '14:00',
          fin: '18:00',
          secciones: [clase],
          bloques: const [],
        ),
      );
      // Nombra con qué choca (la forma exacta del texto es de la Tarea 2).
      expect(esperado.toLowerCase(), contains('curso de prueba a'));
      expect(find.byKey(TimeBlockFormPage.avisoCruceKey), findsOneWidget);
      expect(find.text(esperado), findsOneWidget);
      expect(service.creados, isEmpty); // el aviso llega ANTES de enviar

      await tester.tap(find.text(TimeBlockFormPage.cruceGuardar));
      await tester.pumpAndSettle();

      expect(service.creados, hasLength(1));
      expect(Get.currentRoute, '/inicio');
    });

    testWidgets('"Volver a editar" cierra el aviso y no guarda',
        (tester) async {
      final service = await _abrirFormulario(
        tester,
        secciones: [_claseDelMartes()],
      );
      await _llenar(tester, dias: const ['Ma']);
      await _guardar(tester);

      await tester.tap(find.text(TimeBlockFormPage.cruceVolver));
      await tester.pumpAndSettle();

      expect(find.byKey(TimeBlockFormPage.avisoCruceKey), findsNothing);
      expect(service.creados, isEmpty);
      expect(Get.currentRoute, '/bloque');
      expect(_c.nombre.text, 'Prácticas'); // no se pierde lo escrito
    });

    testWidgets('también avisa del cruce con otro bloque propio',
        (tester) async {
      final service = await _abrirFormulario(tester, bloques: [_practicas()]);
      // Miércoles de 16:00 a 20:00 contra Prácticas del miércoles 14-18.
      await _llenar(
        tester,
        nombre: 'Voluntariado',
        dias: const ['Mi'],
        inicio: const TimeOfDay(hour: 16, minute: 0),
        fin: const TimeOfDay(hour: 20, minute: 0),
      );
      await _guardar(tester);

      final esperado = mensajeDeCruce(
        crucesDeBloque(
          dias: {3},
          inicio: '16:00',
          fin: '20:00',
          secciones: const [],
          bloques: [_practicas()],
        ),
      );
      expect(esperado.toLowerCase(), contains('prácticas'));
      expect(find.byKey(TimeBlockFormPage.avisoCruceKey), findsOneWidget);
      expect(find.text(esperado), findsOneWidget);
      expect(service.creados, isEmpty);
    });

    testWidgets('tocarse en el borde no es cruce: guarda sin aviso',
        (tester) async {
      final service = await _abrirFormulario(
        tester,
        secciones: [_claseDelMartes()],
      );
      // Martes de 18:00 a 20:00: empieza justo cuando termina la clase.
      await _llenar(
        tester,
        dias: const ['Ma'],
        inicio: const TimeOfDay(hour: 18, minute: 0),
        fin: const TimeOfDay(hour: 20, minute: 0),
      );
      await _guardar(tester);

      expect(find.byKey(TimeBlockFormPage.avisoCruceKey), findsNothing);
      expect(service.creados, hasLength(1));
    });

    testWidgets(
        'sin clases inyectadas, compara contra las del horario en pantalla',
        (tester) async {
      // Aquí no se inyecta nada: el binding REAL crea el controller, y la
      // única fuente de clases es seccionesDelHorario() → el
      // HorarioController registrado. Si esa pieza devolviera siempre [],
      // las demás pruebas del aviso seguirían en verde y esta no.
      Get.put<HorarioController>(_HorarioConClases([_claseDelMartes()]));
      final service = await _abrirFormulario(tester);
      // Martes de 14:00 a 18:00 contra la clase del martes de 4 a 6 pm.
      await _llenar(tester, dias: const ['Ma']);
      await _guardar(tester);

      final esperado = mensajeDeCruce(
        crucesDeBloque(
          dias: {2},
          inicio: '14:00',
          fin: '18:00',
          secciones: [_claseDelMartes()],
          bloques: const [],
        ),
      );
      expect(find.byKey(TimeBlockFormPage.avisoCruceKey), findsOneWidget);
      expect(find.text(esperado), findsOneWidget);
      expect(service.creados, isEmpty);
    });
  });

  group('UNITARIA · de dónde salen las clases del aviso (RF-BLQ-3)', () {
    test('sin el horario registrado no hay clases contra las que cruzar', () {
      expect(Get.isRegistered<HorarioController>(), isFalse);
      expect(TimeBlockFormController.seccionesDelHorario(), isEmpty);
    });
  });

  group('WIDGET · botón de agregar en el horario (RF-BLQ-1)', () {
    Widget horario() => GetMaterialApp(
          home: const HorarioPage(),
          getPages: [
            GetPage(
              name: '/bloque',
              page: () => const _FormularioDePrueba(),
              binding: TimeBlockFormBinding(),
            ),
          ],
        );

    testWidgets('la alumna ve el botón y la lleva a /bloque', (tester) async {
      _telefonoVertical(tester);
      Get.put<AuthService>(_FakeAuthService(_alumna()));
      await tester.pumpWidget(horario());
      // Sin pumpAndSettle: sin datos, el horario pinta un SkeletonPulse que
      // anima sin fin.
      await tester.pump();

      expect(find.byKey(HorarioPage.agregarBloqueKey), findsOneWidget);

      await tester.tap(find.byKey(HorarioPage.agregarBloqueKey));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(Get.currentRoute, '/bloque');
      expect(find.text('FORMULARIO'), findsOneWidget);

      await _desmontarHorario(tester);
    });

    testWidgets(
        'abre el formulario en vertical, al volver el horario rota y no '
        'reabre un formulario que sigue cerrándose', (tester) async {
      // Solo el horario puede girar (schedule.spec.md, "Schedule-only
      // rotation"): el formulario se abre fijado en vertical, igual que el
      // detalle de un curso, y al volver se devuelve la rotación del horario.
      _telefonoVertical(tester);
      Get.put<AuthService>(_FakeAuthService(_alumna()));
      await tester.pumpWidget(horario());
      await tester.pump();

      await tester.tap(find.byKey(HorarioPage.agregarBloqueKey));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(Get.currentRoute, '/bloque');
      expect(_orientaciones, [
        ['DeviceOrientation.portraitUp'],
      ]);
      // El binding de la ruta creó el controller del formulario.
      expect(Get.isRegistered<TimeBlockFormController>(), isTrue);

      Get.back<dynamic>();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(_orientaciones, hasLength(2));
      expect(_orientaciones.last, [
        'DeviceOrientation.portraitUp',
        'DeviceOrientation.landscapeLeft',
        'DeviceOrientation.landscapeRight',
      ]);
      // La premisa de la guarda del botón: terminada la salida, GetX ya borró
      // el controller. Si una versión de get lo dejara vivo, el botón quedaría
      // inerte para siempre.
      expect(Get.isRegistered<TimeBlockFormController>(), isFalse);

      // get 4.7.3 borra el controller del formulario recién al terminar la
      // animación de salida. Un toque en esa ventana no reabre /bloque, porque
      // el binding le daría el controller viejo, con lo escrito y por liberar.
      Get.put<TimeBlockFormController>(TimeBlockFormController());
      await tester.tap(find.byKey(HorarioPage.agregarBloqueKey));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('FORMULARIO'), findsNothing);
      expect(_orientaciones, hasLength(2));

      await _desmontarHorario(tester);
    });

    testWidgets('un docente no ve el botón', (tester) async {
      // En vertical, donde la alumna SÍ lo ve: la única diferencia es el rol.
      _telefonoVertical(tester);
      Get.put<AuthService>(_FakeAuthService(_docente()));
      await tester.pumpWidget(horario());
      await tester.pump();

      expect(find.byKey(HorarioPage.agregarBloqueKey), findsNothing);

      await _desmontarHorario(tester);
    });

    testWidgets('en la lista de chats no aparece', (tester) async {
      _telefonoVertical(tester);
      Get.put<AuthService>(_FakeAuthService(_alumna()));
      await tester.pumpWidget(horario());
      await tester.pump();
      expect(find.byKey(HorarioPage.agregarBloqueKey), findsOneWidget);

      Get.find<HorarioController>().toggleListView();
      await tester.pump();

      expect(find.text('Mis chats'), findsOneWidget);
      expect(find.byKey(HorarioPage.agregarBloqueKey), findsNothing);

      await _desmontarHorario(tester);
    });

    testWidgets('en horizontal el botón no tapa la grilla semanal',
        (tester) async {
      // 800 x 600, la superficie por defecto: horizontal.
      Get.put<AuthService>(_FakeAuthService(_alumna()));
      await tester.pumpWidget(horario());
      await tester.pump();

      expect(find.byKey(HorarioPage.agregarBloqueKey), findsNothing);

      await _desmontarHorario(tester);
    });
  });
}
