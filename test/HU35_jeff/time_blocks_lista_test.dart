// test/HU35_jeff/time_blocks_lista_test.dart
//
// WIDGET + UNITARIA — HU35 (bloques de horario propios): la lista «Mis
// bloques» (RF-BLQ-8). Todos los bloques guardados, también los que la grilla
// no pinta; su orden y sus avisos; editar y borrar desde la lista con el
// código de la hoja de RF-BLQ-5; los estados de carga, error y vacío; y el
// botón que la abre desde el horario, solo para alumnos.
// Pantallas: lib/pages/time_blocks/time_block_list_page.dart y el botón de
// lib/pages/horario/horario.dart.
//
// Todos los datos son inventados; el repo es público. La alumna es la
// 20230001, el docente es "docente.test" (el mismo de test/HU34_jeff) y
// ninguno de los bloques existe.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/main.dart';
import 'package:ulima_plus/models/time_block_model.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/horario/horario.dart';
import 'package:ulima_plus/pages/horario/horario_controller.dart';
import 'package:ulima_plus/pages/time_blocks/time_block_actions_sheet.dart';
import 'package:ulima_plus/pages/time_blocks/time_block_form_controller.dart';
import 'package:ulima_plus/pages/time_blocks/time_block_list_binding.dart';
import 'package:ulima_plus/pages/time_blocks/time_block_list_controller.dart';
import 'package:ulima_plus/pages/time_blocks/time_block_list_page.dart';
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

/// El reloj de la lista: miércoles 23 de septiembre de 2026, 10:00 en Lima
/// (15:00 UTC).
final DateTime _ahora = DateTime.utc(2026, 9, 23, 15);

/// Vigente: lunes y miércoles de 14:00 a 18:00, de septiembre a diciembre. Los
/// días vienen desordenados a propósito.
const TimeBlockRule _practicas = TimeBlockRule(
  id: 7,
  title: 'Prácticas de prueba',
  colorHex: '#27AE60',
  daysOfWeek: <int>[3, 1],
  startTime: '14:00',
  endTime: '18:00',
  startDate: '2026-09-01',
  endDate: '2026-12-15',
  exceptions: <TimeBlockException>[],
);

/// Vigente y todavía sin empezar: martes y jueves de 8:00 a 10:00, en
/// octubre y noviembre.
const TimeBlockRule _voluntariado = TimeBlockRule(
  id: 9,
  title: 'Voluntariado de prueba',
  colorHex: '#2F80ED',
  daysOfWeek: <int>[2, 4],
  startTime: '08:00',
  endTime: '10:00',
  startDate: '2026-10-05',
  endDate: '2026-11-30',
  exceptions: <TimeBlockException>[],
);

/// Como el del bug, con otro nombre: martes y sábado del miércoles 23 al
/// miércoles 23. No tiene ningún día real. Termina hoy, así que sigue
/// vigente.
const TimeBlockRule _sinDias = TimeBlockRule(
  id: 11,
  title: 'Bloque sin días de prueba',
  colorHex: '#9B51E0',
  daysOfWeek: <int>[2, 6],
  startTime: '19:00',
  endTime: '20:00',
  startDate: '2026-09-23',
  endDate: '2026-09-23',
  exceptions: <TimeBlockException>[],
);

/// Ya terminó: viernes de 9:00 a 11:00, de marzo a julio. Empieza antes que
/// todos: si la lista ordenara solo por fecha de inicio, iría primero.
const TimeBlockRule _taller = TimeBlockRule(
  id: 5,
  title: 'Taller de prueba',
  colorHex: '#EB5757',
  daysOfWeek: <int>[5],
  startTime: '09:00',
  endTime: '11:00',
  startDate: '2026-03-02',
  endDate: '2026-07-10',
  exceptions: <TimeBlockException>[],
);

/// Por id, como podría mandarlos el servidor: no es el orden de la lista.
const List<TimeBlockRule> _todos = <TimeBlockRule>[
  _taller,
  _practicas,
  _voluntariado,
  _sinDias,
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

/// Cliente que no sale a la red: si algo de la lista lo llamara, la prueba
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
      throw StateError('La lista no debe pedir $path');
}

/// Doble del service. Su estado es reactivo, como el del real: la pantalla es
/// un `Obx` y tiene que enterarse sola de cada cambio. Anota en [llamadas] lo
/// que le piden, sin HTTP.
class _FakeTimeBlocksService extends TimeBlocksService {
  _FakeTimeBlocksService({
    List<TimeBlockRule> bloques = const <TimeBlockRule>[],
    bool cargado = true,
  }) : super(apiClient: _ApiSinRed()) {
    reglas.assignAll(bloques);
    if (cargado) foto.value = _fotoVacia;
  }

  static const TimeBlocksSnapshot _fotoVacia = TimeBlocksSnapshot(
    occurrences: <TimeBlockOccurrence>[],
    weeks: <TimeBlockWeek>[],
  );

  final reglas = <TimeBlockRule>[].obs;

  /// La ventana de ocurrencias. null mientras no haya llegado ninguna carga.
  final foto = Rxn<TimeBlocksSnapshot>();
  final cargando = false.obs;
  final conError = false.obs;

  /// Cada cosa que le pidieron, en orden.
  final llamadas = <String>[];

  /// Si no es null, `remove` lo lanza.
  Object? falla;

  /// Termina una carga que salió bien: llegan [bloques].
  void terminarCarga(List<TimeBlockRule> bloques) {
    reglas.assignAll(bloques);
    foto.value = _fotoVacia;
    cargando.value = false;
  }

  @override
  List<TimeBlockRule> get blocks => reglas.toList(growable: false);

  @override
  TimeBlocksSnapshot? get snapshot => foto.value;

  @override
  bool get isLoading => cargando.value;

  @override
  bool get hasError => conError.value;

  /// El horario pide su ventana al montarse; aquí no sale a la red.
  @override
  Future<void> load({
    required String from,
    required String to,
    bool force = false,
  }) async {
    llamadas.add('load');
  }

  @override
  Future<void> reload() async {
    llamadas.add('reload');
  }

  /// Como el real, que recarga después de borrar: el bloque ya no vuelve.
  @override
  Future<void> remove(int id) async {
    if (falla != null) throw falla!;
    llamadas.add('remove $id');
    reglas.removeWhere((r) => r.id == id);
  }
}

// --- Montaje ------------------------------------------------------------------

/// Lo que la app le pidió a `SystemChrome.setPreferredOrientations`, en orden.
final _orientaciones = <List<Object?>>[];

/// Lo que recibió la ruta /bloque en `Get.arguments`.
Object? _argumentoDelFormulario;

/// La rotación del horario, la que se devuelve al volver de otra pantalla.
const List<String> _rotacionDelHorario = <String>[
  'DeviceOrientation.portraitUp',
  'DeviceOrientation.landscapeLeft',
  'DeviceOrientation.landscapeRight',
];

/// Un iPhone SE en vertical (375 x 667). La superficie por defecto de las
/// pruebas es 800 x 600, horizontal, y ahí el horario esconde sus botones.
void _telefonoVertical(WidgetTester tester) {
  tester.view.physicalSize = const Size(750, 1334);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

/// El tema real de la app, claro u oscuro (`main.dart` usa los dos).
ThemeData _temaDeLaApp(Brightness brillo) {
  const tema = MaterialTheme(TextTheme());
  return brillo == Brightness.light ? tema.light() : tema.dark();
}

/// Contraste de WCAG 2.x entre dos colores opacos: (L1 + 0,05) / (L2 + 0,05),
/// con L1 la luminancia relativa del más claro.
double _contraste(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return la > lb ? (la + 0.05) / (lb + 0.05) : (lb + 0.05) / (la + 0.05);
}

/// El color con que se pinta de verdad lo que encuentra [finder]: el de su
/// `RichText`, que ya mezcla el estilo propio con el que hereda.
Color _colorPintado(WidgetTester tester, Finder finder) => tester
    .widget<RichText>(
      find.descendant(of: finder, matching: find.byType(RichText)).first,
    )
    .text
    .style!
    .color!;

/// App mínima: una pantalla de partida, la ruta /mis-bloques con su binding
/// REAL y la ruta /bloque, que anota el argumento con que se abrió. Sin
/// [tema], el de Flutter por omisión.
Widget _app({ThemeData? tema}) => GetMaterialApp(
      theme: tema,
      initialRoute: '/inicio',
      getPages: [
        GetPage(
          name: '/inicio',
          page: () => const Scaffold(body: Text('INICIO')),
        ),
        GetPage(
          name: '/mis-bloques',
          page: () => const TimeBlockListPage(),
          binding: TimeBlockListBinding(),
        ),
        GetPage(
          name: '/bloque',
          page: () {
            _argumentoDelFormulario = Get.arguments;
            return const Scaffold(body: Text('FORMULARIO'));
          },
        ),
      ],
    );

/// Registra el service con [bloques] y abre /mis-bloques con el reloj fijo en
/// [_ahora]. Sin [cargado], ninguna carga ha llegado todavía.
Future<_FakeTimeBlocksService> _abrirLista(
  WidgetTester tester, {
  List<TimeBlockRule> bloques = _todos,
  bool cargado = true,
  bool cargando = false,
  bool conError = false,
  ThemeData? tema,
}) async {
  _telefonoVertical(tester);
  final service = _FakeTimeBlocksService(bloques: bloques, cargado: cargado);
  service.cargando.value = cargando;
  service.conError.value = conError;
  Get.put<TimeBlocksService>(service);
  // El binding usa `lazyPut`, que no pisa lo ya registrado: la ruta se queda
  // con este controller y su reloj fijo.
  Get.put<TimeBlockListController>(
    TimeBlockListController(ahora: () => _ahora),
  );
  await tester.pumpWidget(_app(tema: tema));
  await tester.pumpAndSettle();
  Get.toNamed<dynamic>('/mis-bloques');
  // Sin pumpAndSettle: el indicador de carga gira sin fin.
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  return service;
}

Finder _fila(int id) => find.byKey(TimeBlockListPage.filaKey(id));

Finder _enLaFila(int id, String texto) =>
    find.descendant(of: _fila(id), matching: find.text(texto));

/// Toca la fila del bloque [id] y espera a que suba su hoja.
Future<void> _tocarFila(WidgetTester tester, int id) async {
  await tester.ensureVisible(_fila(id));
  await tester.tap(_fila(id));
  await tester.pumpAndSettle();
}

/// `HorarioPage` hace `Get.put(HorarioController())` dentro de `build`, y ese
/// controller arranca un `Timer.periodic` de un minuto. Hay que desmontar el
/// árbol y borrarlo antes de que termine la prueba.
Future<void> _desmontarHorario(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await Get.delete<HorarioController>(force: true);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.reset();
    _orientaciones.clear();
    _argumentoDelFormulario = null;
    // Doble del canal de plataforma: sin él, `setPreferredOrientations`
    // espera una respuesta que en la prueba no llega nunca. Responde al toque
    // y anota las orientaciones pedidas.
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

  group('UNITARIA · orden y avisos de «Mis bloques» (RF-BLQ-8)', () {
    test('hoy es la fecha de Lima, no la de UTC', () {
      // Las 22:00 del 23 en Lima ya son el 24 en UTC.
      expect(fechaEnLima(DateTime.utc(2026, 9, 24, 3)), '2026-09-23');
      expect(fechaEnLima(DateTime.utc(2026, 9, 24, 5)), '2026-09-24');
      expect(fechaEnLima(_ahora), '2026-09-23');
    });

    test('un bloque termina el día después de su fecha de fin', () {
      expect(bloqueTerminado(_sinDias, '2026-09-23'), isFalse);
      expect(bloqueTerminado(_sinDias, '2026-09-24'), isTrue);
      expect(bloqueTerminado(_taller, '2026-09-23'), isTrue);
      expect(bloqueTerminado(_practicas, '2026-09-23'), isFalse);
    });

    test('una fecha de fin que no se lee no inventa un «Terminó»', () {
      const ilegible = TimeBlockRule(
        id: 1,
        title: 'Ilegible de prueba',
        colorHex: '#27AE60',
        daysOfWeek: <int>[1],
        startTime: '14:00',
        endTime: '18:00',
        startDate: '2026-01-01',
        endDate: 'pronto',
        exceptions: <TimeBlockException>[],
      );
      expect(bloqueTerminado(ilegible, '2026-09-23'), isFalse);
    });

    test('sin días reales: la misma regla que valida el formulario', () {
      expect(bloqueSinDiasReales(_sinDias), isTrue);
      expect(bloqueSinDiasReales(_practicas), isFalse);
      for (final b in _todos) {
        expect(
          bloqueSinDiasReales(b),
          validarDiasEnElRango(b.daysOfWeek.toSet(), b.startDate, b.endDate) !=
              null,
          reason: b.title,
        );
      }
    });

    test('primero los vigentes por fecha de inicio, después los terminados', () {
      expect(
        ordenarMisBloques(_todos, '2026-09-23').map((b) => b.id),
        <int>[7, 11, 9, 5],
      );
      // Al día siguiente el del 23 ya terminó y pasa al grupo de abajo, que
      // también va por fecha de inicio.
      expect(
        ordenarMisBloques(_todos, '2026-09-24').map((b) => b.id),
        <int>[7, 9, 5, 11],
      );
    });

    test('a igual inicio va primero el que termina antes, y después el de id '
        'menor', () {
      TimeBlockRule bloque(int id, String fin) => TimeBlockRule(
            id: id,
            title: 'Empate $id de prueba',
            colorHex: '#27AE60',
            daysOfWeek: const <int>[1],
            startTime: '14:00',
            endTime: '18:00',
            startDate: '2026-09-01',
            endDate: fin,
            exceptions: const <TimeBlockException>[],
          );
      expect(
        ordenarMisBloques(
          [
            bloque(4, '2026-12-15'),
            bloque(3, '2026-12-15'),
            bloque(8, '2026-10-01'),
          ],
          '2026-09-23',
        ).map((b) => b.id),
        <int>[8, 3, 4],
      );
    });

    test('ordenar no toca la lista del service', () {
      final deLlegada = List<TimeBlockRule>.unmodifiable(_todos);
      ordenarMisBloques(deLlegada, '2026-09-23');
      expect(deLlegada.map((b) => b.id), <int>[5, 7, 9, 11]);
    });

    test('días, horas y fechas como los muestra la fila', () {
      // Los días en orden de la semana aunque lleguen desordenados, y las
      // horas con la misma función que la hoja de RF-BLQ-5.
      expect(TimeBlockListPage.diasYHoras(_practicas), 'Lu, Mi · 14:00 a 18:00');
      expect(rangoDeHoras('14:00', '18:00'), '14:00 a 18:00');
      expect(TimeBlockListPage.diasYHoras(_sinDias), 'Ma, Sá · 19:00 a 20:00');
      expect(
        TimeBlockListPage.fechasDelBloque(_practicas),
        'Del 01/09/2026 al 15/12/2026',
      );
      expect(TimeBlockListPage.fechaCorta('2026-03-02'), '02/03/2026');
      // Una fecha que no se lee se muestra tal cual: no se inventa otra.
      expect(TimeBlockListPage.fechaCorta('pronto'), 'pronto');
    });
  });

  group('WIDGET · la lista «Mis bloques» (RF-BLQ-8)', () {
    testWidgets(
        'muestra todos los bloques: los vigentes por fecha de inicio y '
        'después los terminados', (tester) async {
      await _abrirLista(tester);

      expect(find.text(TimeBlockListPage.titulo), findsOneWidget);
      final orden = <int>[7, 11, 9, 5];
      for (final id in orden) {
        expect(_fila(id), findsOneWidget, reason: 'bloque $id');
      }
      final alturas = [for (final id in orden) tester.getTopLeft(_fila(id)).dy];
      for (var i = 1; i < alturas.length; i++) {
        expect(
          alturas[i],
          greaterThan(alturas[i - 1]),
          reason: 'el bloque ${orden[i]} va debajo del ${orden[i - 1]}',
        );
      }
    });

    testWidgets('cada fila muestra el color, el nombre, los días, las horas y '
        'las fechas', (tester) async {
      await _abrirLista(tester);

      expect(_enLaFila(7, 'Prácticas de prueba'), findsOneWidget);
      expect(_enLaFila(7, 'Lu, Mi · 14:00 a 18:00'), findsOneWidget);
      expect(_enLaFila(7, 'Del 01/09/2026 al 15/12/2026'), findsOneWidget);
      final circulo =
          tester.widget<Container>(find.byKey(TimeBlockListPage.colorKey(7)));
      expect(
        (circulo.decoration! as BoxDecoration).color,
        const Color(0xFF27AE60),
      );

      await tester.ensureVisible(_fila(5));
      expect(_enLaFila(5, 'Taller de prueba'), findsOneWidget);
      expect(_enLaFila(5, 'Vi · 09:00 a 11:00'), findsOneWidget);
      expect(_enLaFila(5, 'Del 02/03/2026 al 10/07/2026'), findsOneWidget);
    });

    testWidgets('el bloque sin días reales lo dice, y solo él', (tester) async {
      await _abrirLista(tester);

      await tester.ensureVisible(_fila(11));
      expect(_enLaFila(11, TimeBlockListPage.sinDiasReales), findsOneWidget);
      expect(
        TimeBlockListPage.sinDiasReales,
        'Ningún día marcado cae entre sus fechas',
      );
      expect(find.text(TimeBlockListPage.sinDiasReales), findsOneWidget);
      // Termina hoy: todavía no terminó.
      expect(_enLaFila(11, TimeBlockListPage.terminado), findsNothing);
    });

    testWidgets('el bloque que ya terminó dice «Terminó», y solo él',
        (tester) async {
      await _abrirLista(tester);

      await tester.ensureVisible(_fila(5));
      expect(TimeBlockListPage.terminado, 'Terminó');
      expect(_enLaFila(5, TimeBlockListPage.terminado), findsOneWidget);
      expect(find.text(TimeBlockListPage.terminado), findsOneWidget);
    });

    testWidgets('un bloque terminado y sin días reales lleva los dos avisos',
        (tester) async {
      // Un martes del jueves 3 al jueves 3 de septiembre.
      const viejoSinDias = TimeBlockRule(
        id: 13,
        title: 'Viejo sin días de prueba',
        colorHex: '#F2994A',
        daysOfWeek: <int>[2],
        startTime: '07:00',
        endTime: '08:00',
        startDate: '2026-09-03',
        endDate: '2026-09-03',
        exceptions: <TimeBlockException>[],
      );
      await _abrirLista(tester, bloques: const <TimeBlockRule>[viejoSinDias]);

      expect(_enLaFila(13, TimeBlockListPage.terminado), findsOneWidget);
      expect(_enLaFila(13, TimeBlockListPage.sinDiasReales), findsOneWidget);
    });

    // Los avisos van en 12 px w700, que para WCAG no es texto grande: piden
    // 4,5:1 contra el fondo de la fila, en los dos temas de la app.
    for (final brillo in Brightness.values) {
      testWidgets(
          'los avisos de la fila llegan a 4,5:1 contra su fondo '
          '(tema ${brillo == Brightness.light ? 'claro' : 'oscuro'})',
          (tester) async {
        await _abrirLista(tester, tema: _temaDeLaApp(brillo));

        for (final (id, aviso) in const [
          (11, TimeBlockListPage.sinDiasReales),
          (5, TimeBlockListPage.terminado),
        ]) {
          await tester.ensureVisible(_fila(id));
          final fondo = tester.widget<ListTile>(_fila(id)).tileColor!;
          expect(fondo, MaterialTheme.cardBg(brillo), reason: aviso);
          final color = _colorPintado(tester, _enLaFila(id, aviso));
          // Opacos los dos: con transparencia, el contraste dependería de lo
          // que haya debajo.
          expect(fondo.a, 1.0, reason: aviso);
          expect(color.a, 1.0, reason: aviso);
          expect(
            _contraste(color, fondo),
            greaterThanOrEqualTo(4.5),
            reason: '$aviso: $color sobre $fondo',
          );
        }
      });
    }

    testWidgets(
        'tocar una fila ofrece editar y borrar el bloque, nada de un día '
        'suelto', (tester) async {
      final service = await _abrirLista(tester);

      await _tocarFila(tester, 7);

      expect(find.text(TimeBlockActionsSheet.editar), findsOneWidget);
      expect(find.text(TimeBlockActionsSheet.borrar), findsOneWidget);
      for (final texto in const [
        TimeBlockActionsSheet.cancelarDia,
        TimeBlockActionsSheet.cambiarHora,
        TimeBlockActionsSheet.volverAlPatron,
      ]) {
        expect(find.text(texto), findsNothing, reason: texto);
      }
      expect(service.llamadas, isEmpty);
    });

    testWidgets(
        '«Editar el bloque» abre /bloque con la regla, sin tocar la rotación',
        (tester) async {
      final service = await _abrirLista(tester);

      await _tocarFila(tester, 9);
      await tester.tap(find.text(TimeBlockActionsSheet.editar));
      await tester.pumpAndSettle();

      expect(Get.currentRoute, '/bloque');
      expect(find.text('FORMULARIO'), findsOneWidget);
      expect(_argumentoDelFormulario, same(_voluntariado));
      // La lista ya es vertical, igual que el formulario: no hay rotación que
      // fijar ni que devolver.
      expect(_orientaciones, isEmpty);

      Get.back<dynamic>();
      await tester.pumpAndSettle();
      expect(Get.currentRoute, '/mis-bloques');
      expect(_orientaciones, isEmpty);
      // Editar lo guarda el formulario, no la lista.
      expect(service.llamadas, isEmpty);
    });

    testWidgets(
        'editar no abre /bloque mientras el formulario anterior sigue '
        'cerrándose', (tester) async {
      // La misma guarda que la hoja de RF-BLQ-5 y el botón de agregar.
      await _abrirLista(tester);
      Get.put<TimeBlockFormController>(TimeBlockFormController());

      await _tocarFila(tester, 7);
      await tester.tap(find.text(TimeBlockActionsSheet.editar));
      await tester.pumpAndSettle();

      expect(Get.currentRoute, '/mis-bloques');
      expect(find.text('FORMULARIO'), findsNothing);
      expect(_argumentoDelFormulario, isNull);
    });

    testWidgets(
        '«Borrar el bloque» pide confirmación sin «no solo este», y '
        '«Cancelar» no borra', (tester) async {
      final service = await _abrirLista(tester);

      await _tocarFila(tester, 7);
      await tester.tap(find.text(TimeBlockActionsSheet.borrar));
      await tester.pumpAndSettle();

      // El mismo diálogo que la hoja de un día, con su título y sus botones.
      expect(
        find.byKey(TimeBlockActionsSheet.confirmarBorradoKey),
        findsOneWidget,
      );
      expect(find.text(TimeBlockActionsSheet.borrarTitulo), findsOneWidget);
      // Pero desde la lista no se tocó ningún día: «no solo este» no tendría
      // a qué referirse.
      expect(
        find.text('Se borra "Prácticas de prueba" con todos sus días.'),
        findsOneWidget,
      );
      expect(find.textContaining('no solo este'), findsNothing);
      // La hoja de un día sigue diciéndolo: ahí sí se tocó un día.
      expect(
        TimeBlockActionsSheet.borrarCuerpo('Prácticas de prueba'),
        'Se borra "Prácticas de prueba" con todos sus días, no solo este.',
      );

      await tester.tap(find.text(TimeBlockActionsSheet.cancelarLabel));
      await tester.pumpAndSettle();

      expect(service.llamadas, isEmpty);
      expect(_fila(7), findsOneWidget);
    });

    testWidgets('al confirmar el borrado llama a remove y la fila se va',
        (tester) async {
      final service = await _abrirLista(tester);

      await _tocarFila(tester, 11);
      await tester.tap(find.text(TimeBlockActionsSheet.borrar));
      await tester.pumpAndSettle();
      await tester.tap(find.text(TimeBlockActionsSheet.borrarConfirmar));
      await tester.pumpAndSettle();

      expect(service.llamadas, ['remove 11']);
      expect(_fila(11), findsNothing);
      expect(find.text(TimeBlockListPage.sinDiasReales), findsNothing);
      expect(_fila(7), findsOneWidget);
      expect(Get.currentRoute, '/mis-bloques');
    });

    testWidgets('un error del servidor al borrar se muestra tal cual llega',
        (tester) async {
      final service = await _abrirLista(tester);
      service.falla = const TimeBlocksFailure('Mensaje inventado del servidor.');

      await _tocarFila(tester, 7);
      await tester.tap(find.text(TimeBlockActionsSheet.borrar));
      await tester.pumpAndSettle();
      await tester.tap(find.text(TimeBlockActionsSheet.borrarConfirmar));
      await tester.pumpAndSettle();

      expect(find.text('Mensaje inventado del servidor.'), findsOneWidget);
      expect(_fila(7), findsOneWidget);
      expect(service.llamadas, isEmpty);
    });

    testWidgets('mientras carga y no hay bloques, un indicador',
        (tester) async {
      await _abrirLista(
        tester,
        bloques: const <TimeBlockRule>[],
        cargado: false,
        cargando: true,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(TimeBlockListPage.sinBloques), findsNothing);
      expect(find.text(TimeBlockListPage.errorDeCarga), findsNothing);
    });

    testWidgets('antes de la primera carga tampoco dice que no hay bloques',
        (tester) async {
      // El horario pide los bloques después de sus días: si la alumna abre la
      // lista en ese rato, el service todavía no cargó nada y tampoco está
      // cargando. Eso no es una lista vacía.
      await _abrirLista(
        tester,
        bloques: const <TimeBlockRule>[],
        cargado: false,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(TimeBlockListPage.sinBloques), findsNothing);
    });

    testWidgets('cuando llega la carga, la lista aparece sola',
        (tester) async {
      final service = await _abrirLista(
        tester,
        bloques: const <TimeBlockRule>[],
        cargado: false,
        cargando: true,
      );

      service.terminarCarga(const <TimeBlockRule>[_practicas]);
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(_fila(7), findsOneWidget);
    });

    testWidgets('recargando con bloques en pantalla, la lista se queda',
        (tester) async {
      // Después de cada escritura el service recarga sin vaciar: la lista no
      // parpadea a un indicador.
      await _abrirLista(tester, cargando: true);

      expect(_fila(7), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('si la carga falló, lo dice y «Reintentar» recarga',
        (tester) async {
      final service = await _abrirLista(
        tester,
        bloques: const <TimeBlockRule>[],
        cargado: false,
        conError: true,
      );

      expect(
        TimeBlockListPage.errorDeCarga,
        'No se pudieron cargar tus bloques.',
      );
      expect(find.text(TimeBlockListPage.errorDeCarga), findsOneWidget);
      expect(find.text(TimeBlockListPage.sinBloques), findsNothing);

      await tester.tap(find.text(TimeBlockListPage.reintentar));
      await tester.pump();

      expect(service.llamadas, ['reload']);
    });

    testWidgets('el error manda aunque queden bloques de antes',
        (tester) async {
      // Borrar no quita el bloque de la lista hasta que llega la recarga: si
      // la recarga falla, lo que queda puede estar viejo.
      await _abrirLista(tester, conError: true);

      expect(find.text(TimeBlockListPage.errorDeCarga), findsOneWidget);
      expect(_fila(7), findsNothing);
    });

    testWidgets('sin bloques guardados lo dice', (tester) async {
      await _abrirLista(tester, bloques: const <TimeBlockRule>[]);

      expect(
        TimeBlockListPage.sinBloques,
        'Todavía no tienes bloques propios.',
      );
      expect(find.text(TimeBlockListPage.sinBloques), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text(TimeBlockListPage.errorDeCarga), findsNothing);
    });
  });

  group('WIDGET · ruta /mis-bloques (RF-BLQ-8)', () {
    testWidgets('la ruta /mis-bloques vive en main.dart con su binding',
        (tester) async {
      // Monta la app REAL: lo que se blinda es la cadena GetPage → binding →
      // pantalla.
      _telefonoVertical(tester);
      Get.put<AuthService>(_FakeAuthService(_alumna()));
      Get.put<TimeBlocksService>(_FakeTimeBlocksService(bloques: _todos));

      await tester.pumpWidget(const MyApp(initialRoute: '/mis-bloques'));
      await tester.pumpAndSettle();

      expect(find.byType(TimeBlockListPage), findsOneWidget);
      expect(Get.currentRoute, '/mis-bloques');
      expect(Get.isRegistered<TimeBlockListController>(), isTrue);
      expect(_fila(7), findsOneWidget);
    });
  });

  group('WIDGET · botón «Mis bloques» en el horario (RF-BLQ-8)', () {
    Widget horario({ThemeData? tema}) => GetMaterialApp(
          theme: tema,
          home: const HorarioPage(),
          getPages: [
            GetPage(
              name: '/mis-bloques',
              page: () => const TimeBlockListPage(),
              binding: TimeBlockListBinding(),
            ),
          ],
        );

    testWidgets(
        'la alumna en vertical lo ve junto al de agregar, con su etiqueta '
        'accesible', (tester) async {
      final semantica = tester.ensureSemantics();
      _telefonoVertical(tester);
      Get.put<AuthService>(_FakeAuthService(_alumna()));
      await tester.pumpWidget(horario());
      // Sin pumpAndSettle: sin datos, el horario pinta un SkeletonPulse que
      // anima sin fin.
      await tester.pump();

      final misBloques = find.byKey(HorarioPage.misBloquesKey);
      final agregar = find.byKey(HorarioPage.agregarBloqueKey);
      expect(misBloques, findsOneWidget);
      expect(agregar, findsOneWidget);
      expect(find.byTooltip(TimeBlockListPage.titulo), findsOneWidget);
      expect(
        tester.getSemantics(misBloques),
        isSemantics(
          tooltip: 'Mis bloques',
          isButton: true,
          hasTapAction: true,
        ),
      );
      // Junto al de agregar: en la misma columna, justo encima.
      expect(
        tester.getCenter(misBloques).dx,
        moreOrLessEquals(tester.getCenter(agregar).dx, epsilon: 1),
      );
      expect(
        tester.getBottomLeft(misBloques).dy,
        lessThanOrEqualTo(tester.getTopLeft(agregar).dy),
      );
      expect(
        tester.getTopLeft(agregar).dy - tester.getBottomLeft(misBloques).dy,
        lessThan(24),
      );

      semantica.dispose();
      await _desmontarHorario(tester);
    });

    testWidgets(
        'abre /mis-bloques en vertical, al volver el horario rota y no reabre '
        'una lista que sigue cerrándose', (tester) async {
      _telefonoVertical(tester);
      Get.put<AuthService>(_FakeAuthService(_alumna()));
      Get.put<TimeBlocksService>(_FakeTimeBlocksService(bloques: _todos));
      await tester.pumpWidget(horario());
      await tester.pump();

      await tester.tap(find.byKey(HorarioPage.misBloquesKey));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(Get.currentRoute, '/mis-bloques');
      expect(find.byType(TimeBlockListPage), findsOneWidget);
      expect(_fila(7), findsOneWidget);
      // Solo el horario rota: la lista se abre fijada en vertical.
      expect(_orientaciones, [
        ['DeviceOrientation.portraitUp'],
      ]);
      expect(Get.isRegistered<TimeBlockListController>(), isTrue);

      Get.back<dynamic>();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(_orientaciones, hasLength(2));
      expect(_orientaciones.last, _rotacionDelHorario);
      // La premisa de la guarda: terminada la salida, GetX ya borró el
      // controller de la lista.
      expect(Get.isRegistered<TimeBlockListController>(), isFalse);

      // Mientras el de antes siga registrado, el binding se lo daría a la
      // ruta nueva y la salida de la anterior lo borraría debajo de ella.
      Get.put<TimeBlockListController>(TimeBlockListController());
      await tester.tap(find.byKey(HorarioPage.misBloquesKey));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(TimeBlockListPage), findsNothing);
      expect(_orientaciones, hasLength(2));

      await _desmontarHorario(tester);
    });

    // Un ícono es un componente para WCAG: pide 3:1 contra el botón. En claro
    // va en el naranja oscuro del tema; en oscuro sigue el naranja de marca.
    for (final (brillo, icono) in const [
      (Brightness.light, MaterialTheme.primaryDark),
      (Brightness.dark, MaterialTheme.primaryColor),
    ]) {
      testWidgets(
          'su ícono llega a 3:1 contra el botón '
          '(tema ${brillo == Brightness.light ? 'claro' : 'oscuro'})',
          (tester) async {
        _telefonoVertical(tester);
        Get.put<AuthService>(_FakeAuthService(_alumna()));
        await tester.pumpWidget(horario(tema: _temaDeLaApp(brillo)));
        await tester.pump();

        final boton = find.byKey(HorarioPage.misBloquesKey);
        final fondo = tester
            .widget<Material>(
              find.descendant(of: boton, matching: find.byType(Material)).first,
            )
            .color!;
        final color = _colorPintado(tester, boton);
        expect(fondo.a, 1.0);
        expect(
          _contraste(color, fondo),
          greaterThanOrEqualTo(3.0),
          reason: '$color sobre $fondo',
        );
        expect(color, icono);

        await _desmontarHorario(tester);
      });
    }

    testWidgets('un docente no lo ve', (tester) async {
      // En vertical, donde la alumna sí lo ve: la única diferencia es el rol.
      _telefonoVertical(tester);
      Get.put<AuthService>(_FakeAuthService(_docente()));
      await tester.pumpWidget(horario());
      await tester.pump();

      expect(find.byKey(HorarioPage.misBloquesKey), findsNothing);

      await _desmontarHorario(tester);
    });

    testWidgets('en horizontal no aparece', (tester) async {
      // 800 x 600, la superficie por defecto: horizontal.
      Get.put<AuthService>(_FakeAuthService(_alumna()));
      await tester.pumpWidget(horario());
      await tester.pump();

      expect(find.byKey(HorarioPage.misBloquesKey), findsNothing);

      await _desmontarHorario(tester);
    });
  });
}
