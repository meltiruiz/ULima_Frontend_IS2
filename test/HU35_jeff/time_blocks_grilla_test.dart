// test/HU35_jeff/time_blocks_grilla_test.dart
//
// UNITARIA + WIDGET — HU35 (bloques de horario propios): la grilla del
// horario con los bloques propios (RF-BLQ-4).
// - El reparto en columnas de lo que coincide en el mismo tramo de un día.
//   Función: lib/pages/horario/horario_layout.dart
// - Qué bloques propios y qué días cancelados caen en cada día, y qué
//   ventana pide el horario (la del ciclo visible).
//   Controller: lib/pages/horario/horario_controller.dart
// - El pintado en las dos vistas, el reparto aplicado, el domingo, los días
//   cancelados y los márgenes de siempre. Pantalla:
//   lib/pages/horario/horario.dart
//
// Todos los datos son inventados; el repo es público. La alumna 20230001 no
// existe, los cursos se llaman "CURSO DE PRUEBA", las secciones son 80x y
// nada sale de un horario real ni de test/HU31_jeff/fixtures.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/horario/horario.dart';
import 'package:ulima_plus/pages/horario/horario_controller.dart';
import 'package:ulima_plus/pages/horario/horario_layout.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/time_blocks_service.dart';

/// "14:30" → minutos desde medianoche.
///
/// Local a la prueba a propósito: la función bajo prueba recibe minutos y no
/// depende de ningún parseo, así que un fallo acá es un fallo del reparto y
/// nunca de la conversión de hora de la Tarea 2.
int minutos(String hhmm) {
  final partes = hhmm.split(':');
  return int.parse(partes[0]) * 60 + int.parse(partes[1]);
}

({int inicio, int fin}) tramo(String inicio, String fin) =>
    (inicio: minutos(inicio), fin: minutos(fin));

/// El reparto como pares `(columna, columnas)`. Los registros de Dart se
/// comparan por valor, así que la lista entera se puede afirmar de un tirón.
List<(int columna, int columnas)> reparto(List<({int inicio, int fin})> bloques) =>
    repartirEnColumnas(bloques).map((SlotColumna s) => (s.columna, s.columnas)).toList();

// --- La grilla con los bloques propios (Tarea 4) ----------------------------
//
// La semana de prueba es la del lunes 21 al domingo 27 de septiembre de 2026,
// la de los ejemplos de la spec. "PRÁCTICAS DE PRUEBA" es un bloque inventado.

UserModel _alumna({String role = 'student'}) => UserModel(
      code: '20230001',
      firstName: 'Alumna',
      lastName: 'De Prueba',
      email: 'test@aloe.ulima.edu.pe',
      role: role,
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

/// Doble del cliente HTTP de [TimeBlocksService]: contesta las dos llamadas de
/// `load` con lo sembrado y anota cada ventana que se le pide. Como el
/// servidor, de las ocurrencias sembradas devuelve solo las que caen dentro
/// de la ventana pedida: así una prueba ve si la ventana alcanza.
class _FakeBloquesApi extends ApiClient {
  _FakeBloquesApi({
    this.reglas = const <Map<String, dynamic>>[],
    this.ocurrencias = const <Map<String, dynamic>>[],
  }) : super(configuredBaseUrl: 'http://test');

  final List<Map<String, dynamic>> reglas;
  final List<Map<String, dynamic>> ocurrencias;
  final List<Map<String, String?>> ventanasPedidas = <Map<String, String?>>[];

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    String? token,
    Map<String, String?> query = const {},
    bool suppressSessionExpiry = false,
  }) async {
    if (path == '/time-blocks/me/occurrences') {
      ventanasPedidas.add(query);
      final desde = query['from'] ?? '';
      final hasta = query['to'] ?? '';
      return <String, dynamic>{
        'occurrences': <Map<String, dynamic>>[
          for (final o in ocurrencias)
            if ((o['date'] as String).compareTo(desde) >= 0 &&
                (o['date'] as String).compareTo(hasta) <= 0)
              o,
        ],
        'weeks': <dynamic>[], // Vacío porque estas pruebas no miran horas.
      };
    }
    return <String, dynamic>{'blocks': reglas};
  }
}

const List<String> _nombresDeDia = <String>[
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

const List<String> _nombresDeMes = <String>[
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];

/// Un ciclo de [semanas] semanas seguidas de lunes a domingo desde el lunes
/// [desde] (por omisión el 24 de agosto de 2026), con lo que arma el backend
/// para cada día: `dateText` ("24 de Agosto"), `weekText` ("Semana 1 del
/// ciclo") e `isoDate` ("2026-08-24").
List<DaySchedule> _ciclo({required int semanas, DateTime? desde}) {
  final lunes = desde ?? DateTime.utc(2026, 8, 24);
  return <DaySchedule>[
    for (var i = 0; i < semanas * 7; i++)
      _diaDelCiclo(lunes.add(Duration(days: i)), 1 + i ~/ 7),
  ];
}

DaySchedule _diaDelCiclo(DateTime fecha, int semana) => DaySchedule(
      _nombresDeDia[fecha.weekday - 1],
      '${fecha.day} de ${_nombresDeMes[fecha.month - 1]}',
      'Semana $semana del ciclo',
      isoDate: _iso(fecha),
    );

/// La fecha como la manda `isoDate`: "2026-09-21".
String _iso(DateTime fecha) =>
    '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-'
    '${fecha.day.toString().padLeft(2, '0')}';

/// La regla "Prácticas de prueba" con la forma de `GET /time-blocks/me`:
/// lunes y miércoles de 14:00 a 18:00, del 1 de septiembre al 15 de
/// diciembre de 2026, con las excepciones que se le pasen.
Map<String, dynamic> _reglaConExcepciones(
  List<Map<String, dynamic>> excepciones,
) =>
    <String, dynamic>{
      'id': 7,
      'title': 'Prácticas de prueba',
      'colorHex': '#27AE60',
      'daysOfWeek': <dynamic>[1, 3],
      'startTime': '14:00',
      'endTime': '18:00',
      'startDate': '2026-09-01',
      'endDate': '2026-12-15',
      'exceptions': excepciones,
    };

/// La semana de prueba con lo que arma el backend para cada día
/// ("21 de Septiembre", `isoDate` "2026-09-21"), de lunes a domingo.
List<DaySchedule> _semana({bool conDomingo = true}) => <DaySchedule>[
      for (final (nombre, dia) in const <(String, int)>[
        ('Lunes', 21),
        ('Martes', 22),
        ('Miércoles', 23),
        ('Jueves', 24),
        ('Viernes', 25),
        ('Sábado', 26),
        ('Domingo', 27),
      ])
        if (conDomingo || nombre != 'Domingo')
          DaySchedule(
            nombre,
            '$dia de Septiembre',
            'Semana 5 del ciclo',
            isoDate: '2026-09-$dia',
          ),
    ];

/// Una ocurrencia con la forma exacta del contrato
/// (`GET /time-blocks/me/occurrences`).
Map<String, dynamic> _ocurrencia({
  required String fecha,
  required int diaDeLaSemana,
  required String inicio,
  required String fin,
  String titulo = 'Prácticas de prueba',
  bool movida = false,
}) =>
    <String, dynamic>{
      'blockId': 7,
      'title': titulo,
      'colorHex': '#27AE60',
      'date': fecha,
      'dayOfWeek': diaDeLaSemana,
      'startTime': inicio,
      'endTime': fin,
      'moved': movida,
    };

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

/// El controller del horario sin su carga remota: días y clases sembrados, y
/// el reloj fijo en el 1 de septiembre, que no es ningún día de la semana de
/// prueba (así no se pinta la línea roja de "ahora").
///
/// `bloquesDelDia` y `ventanaVisible` NO se sobreescriben: son lo que se prueba.
class _HorarioDePrueba extends HorarioController {
  _HorarioDePrueba({
    required List<DaySchedule> dias,
    this.clasesPorDia = const <String, List<Map<String, dynamic>>>{},
  }) {
    daysList.assignAll(dias);
    currentLimaTime.value = DateTime.utc(2026, 9, 1, 10);
  }

  /// Las clases de cada día, por `dayName`.
  final Map<String, List<Map<String, dynamic>>> clasesPorDia;

  @override
  // ignore: must_call_super
  void onInit() {
    // Sin el onInit real: arranca un Timer.periodic de un minuto, que quedaría
    // pendiente al terminar la prueba, y pide el horario con un ApiClient
    // propio que no se puede inyectar. Mismo recurso que
    // test/HU07_sam/calculadora_flujo_cajanegra_test.dart.
  }

  @override
  List<Map<String, dynamic>> coursesForDay(DaySchedule activeDay) =>
      clasesPorDia[activeDay.dayName] ?? const <Map<String, dynamic>>[];
}

/// Vertical y horizontal. El vertical es más ancho que un teléfono a
/// propósito: la fuente de las pruebas dibuja cada letra como un cuadrado de
/// su tamaño, y "Domingo, 27 de Septiembre" a 18 px no entra en la franja del
/// día con menos de ~580 px (la fila desborda en la prueba, no en la app).
const Size _vertical = Size(600, 1000);
const Size _horizontal = Size(1000, 500);

/// Registra la sesión, el service de bloques y el controller, y monta
/// [HorarioPage]. `Get.put(HorarioController())` del `build` encuentra el
/// doble ya registrado y lo reusa: GetX no reemplaza una instancia viva.
Future<TimeBlocksService> _montar(
  WidgetTester tester, {
  required Size pantalla,
  List<Map<String, dynamic>> ocurrencias = const <Map<String, dynamic>>[],
  List<Map<String, dynamic>> reglas = const <Map<String, dynamic>>[],
  Map<String, List<Map<String, dynamic>>> clasesPorDia =
      const <String, List<Map<String, dynamic>>>{},
  List<DaySchedule>? dias,
  bool conDomingo = true,
  int diaActivo = 0,
  bool cargarAntes = true,
}) async {
  tester.view.physicalSize = pantalla;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  Get.put<AuthService>(_FakeAuthService(_alumna()));
  final servicio = TimeBlocksService(
    apiClient: _FakeBloquesApi(reglas: reglas, ocurrencias: ocurrencias),
  );
  Get.put<TimeBlocksService>(servicio);
  if (cargarAntes) await servicio.load(from: '2026-09-14', to: '2026-10-11');

  final horario = _HorarioDePrueba(
    dias: dias ?? _semana(conDomingo: conDomingo),
    clasesPorDia: clasesPorDia,
  );
  horario.currentDayIndex.value = diaActivo;
  Get.put<HorarioController>(horario);

  await tester.pumpWidget(const GetMaterialApp(home: HorarioPage()));
  await tester.pump();
  return servicio;
}

/// El bloque que lleva ese título: su [InkWell], que es lo que se toca.
Finder _bloque(String titulo) =>
    find.ancestor(of: find.text(titulo), matching: find.byType(InkWell));

/// Si un toque en el centro del bloque le llega a él y no a otro que lo tape.
/// El Stack entrega el toque al primer hijo que lo acepta, de arriba abajo, así
/// que un bloque tapado nunca aparece en el camino del toque.
bool _recibeElToque(WidgetTester tester, Finder bloque) {
  final objetivo = tester.renderObject(bloque);
  final camino = tester.hitTestOnBinding(tester.getCenter(bloque)).path;
  return camino.any((entrada) => entrada.target == objetivo);
}

/// La franja de un día en la vista semanal: la celda naranja de su nombre,
/// que mide lo mismo que la columna de la grilla debajo.
Rect _columnaDe(WidgetTester tester, String dia) => tester.getRect(
      find.ancestor(of: find.text(dia), matching: find.byType(Container)).first,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('reparto en columnas de un día', () {
    test('sin bloques no hay nada que repartir', () {
      expect(reparto(const <({int inicio, int fin})>[]), isEmpty);
    });

    test('un bloque solo se queda con todo el ancho: columna 0 de 1', () {
      expect(reparto([tramo('14:00', '18:00')]), [(0, 1)]);
    });

    test('dos simultáneos se parten el ancho: 0 y 1 de 2', () {
      // Una clase de 4 a 6 y una práctica de 2 a 6. Sin reparto, la práctica
      // taparía la clase entera y se comería sus toques (`_courseBlock` con
      // `left`/`right` fijos por vista); con el reparto las dos quedan
      // visibles.
      expect(
        reparto([tramo('16:00', '18:00'), tramo('14:00', '18:00')]),
        [(1, 2), (0, 2)],
      );
    });

    test('tres simultáneos: tres columnas, una para cada uno', () {
      expect(
        reparto([tramo('14:00', '18:00'), tramo('15:00', '17:00'), tramo('16:00', '19:00')]),
        [(0, 3), (1, 3), (2, 3)],
      );
    });

    test('uno contenido en otro también se reparte', () {
      // El corto está dentro del largo: sin reparto desaparecería debajo.
      expect(reparto([tramo('14:00', '20:00'), tramo('16:00', '17:00')]), [(0, 2), (1, 2)]);
    });

    test('tocarse en el borde no es solaparse: los dos a ancho completo', () {
      // Mismo criterio que `seCruzan` de la Tarea 2: una termina 18:00 y la
      // otra empieza 18:00, así que no chocan y ninguna cede la mitad.
      expect(reparto([tramo('16:00', '18:00'), tramo('18:00', '20:00')]), [(0, 1), (0, 1)]);
    });

    test('dos racimos separados del mismo día se cuentan por separado', () {
      // 8-10 y 9-11 chocan entre ellos; 14-16 está solo y no tiene por qué
      // encogerse por lo que pasó en la mañana.
      expect(
        reparto([tramo('08:00', '10:00'), tramo('09:00', '11:00'), tramo('14:00', '16:00')]),
        [(0, 2), (1, 2), (0, 1)],
      );
    });

    test('en un racimo encadenado todos miden lo mismo', () {
      // A 8-10 y C 10-12 no se tocan, pero B 9-11 los encadena: es un solo
      // racimo de dos columnas, así que C reusa la columna 0 y los tres salen
      // del mismo ancho. Si `columnas` se calculara bloque a bloque, C saldría
      // "0 de 1" y el ancho cambiaría a mitad de la mañana.
      expect(
        reparto([tramo('08:00', '10:00'), tramo('09:00', '11:00'), tramo('10:00', '12:00')]),
        [(0, 2), (1, 2), (0, 2)],
      );
    });

    test('la salida respeta el orden de entrada aunque venga desordenada', () {
      // La vista entrega los bloques en el orden en que los va a pintar, que es
      // el del JSON y no el de la hora: resultado[i] tiene que ser el slot de
      // bloques[i].
      expect(
        reparto([tramo('18:00', '20:00'), tramo('07:00', '09:00'), tramo('07:30', '08:30')]),
        [(0, 1), (0, 2), (1, 2)],
      );
    });

    test('dos bloques idénticos no se tapan: uno a cada lado', () {
      expect(reparto([tramo('14:00', '16:00'), tramo('14:00', '16:00')]), [(0, 2), (1, 2)]);
    });

    test('la columna cae dentro de la cuenta y dos que se cruzan no la comparten', () {
      // Invariante que la vista da por hecho al calcular el ancho: si
      // `columna >= columnas`, el bloque se dibujaría fuera de su día.
      final bloques = [
        tramo('07:00', '22:00'),
        tramo('08:00', '09:00'),
        tramo('08:30', '10:00'),
        tramo('12:00', '13:00'),
      ];
      final slots = repartirEnColumnas(bloques);
      // Y dos bloques que se cruzan caen en el mismo racimo: columnas distintas
      // y la misma cuenta. Es el corte contra `finDelRacimo` (punto 2 de «Tres
      // cosas que parecen detalle», Tarea 3 del plan): si el racimo se cortara
      // contra el fin del bloque anterior, 12-13 abriría racimo propio detrás
      // de 8:30-10, saldría "0 de 1" y se dibujaría a ancho completo encima de
      // 7-22.
      for (var i = 0; i < slots.length; i++) {
        for (var j = i + 1; j < slots.length; j++) {
          if (bloques[i].inicio < bloques[j].fin && bloques[j].inicio < bloques[i].fin) {
            expect(slots[i].columna, isNot(slots[j].columna),
                reason: 'los bloques $i y $j se cruzan: no pueden compartir columna');
            expect(slots[i].columnas, slots[j].columnas,
                reason: 'los bloques $i y $j se cruzan: tienen que medir lo mismo');
          }
        }
      }
      expect(slots, hasLength(4));
      for (final s in slots) {
        expect(s.columna, greaterThanOrEqualTo(0));
        expect(s.columna, lessThan(s.columnas));
      }
    });
  });

  group('UNITARIA · la ventana de bloques que pide el horario (RF-BLQ-7)', () {
    setUp(() {
      Get.testMode = true;
      Get.reset();
    });
    tearDown(Get.reset);

    /// La ventana que pediría el horario con [dias] cargados y el día
    /// [diaActivo] a la vista. El controller se crea sin registrar, así que
    /// su onInit no corre.
    ({String from, String to}) ventanaDelCiclo(
      List<DaySchedule> dias, {
      int diaActivo = 0,
      DateTime? hoy,
    }) {
      final horario = HorarioController();
      horario.daysList.assignAll(dias);
      horario.currentDayIndex.value = diaActivo;
      if (hoy != null) horario.currentLimaTime.value = hoy;
      return horario.ventanaVisible();
    }

    /// Cuántos días cubre una ventana contando los dos extremos, como el
    /// tope de 120 del servidor.
    int diasDe(({String from, String to}) ventana) =>
        DateTime.parse('${ventana.to}T00:00:00Z')
            .difference(DateTime.parse('${ventana.from}T00:00:00Z'))
            .inDays +
        1;

    test('es la del ciclo: del primer al último isoDate de los días', () {
      final ciclo = _ciclo(semanas: 16);
      const esperada = (from: '2026-08-24', to: '2026-12-13');
      expect(ventanaDelCiclo(ciclo), esperada);
      expect(diasDe(esperada), 112);
      // No depende del día activo: navegar dentro del ciclo no pide otra.
      expect(ventanaDelCiclo(ciclo, diaActivo: 7 * 15 + 6), esperada);
    });

    test('un ciclo de más de 120 días pide 120 desde el lunes de la semana del día activo',
        () {
      // 18 semanas son 126 días: no entran en una ventana
      // (TIME_BLOCK_WINDOW_TOO_WIDE).
      final ciclo = _ciclo(semanas: 18);
      final primera = ventanaDelCiclo(ciclo);
      expect(primera, (from: '2026-08-24', to: '2026-12-21'));
      expect(diasDe(primera), 120);
      // El jueves de esa semana pide lo mismo que su lunes.
      expect(ventanaDelCiclo(ciclo, diaActivo: 3), primera);
      // El miércoles 23 de diciembre (semana 18) pide desde su lunes, el 21,
      // aunque la ventana pase del final del ciclo: el servidor la acepta.
      final ultima = ventanaDelCiclo(ciclo, diaActivo: 7 * 17 + 2);
      expect(ultima, (from: '2026-12-21', to: '2027-04-19'));
      expect(diasDe(ultima), 120);
    });

    test('el año sale de isoDate: un ciclo que cruza de diciembre a enero no se adivina',
        () {
      // Seis semanas desde el lunes 14 de diciembre de 2026. dateText no trae
      // año ("24 de Enero"); isoDate sí ("2027-01-24").
      expect(
        ventanaDelCiclo(_ciclo(semanas: 6, desde: DateTime.utc(2026, 12, 14))),
        (from: '2026-12-14', to: '2027-01-24'),
      );
    });

    test('un ciclo sin semanas (isoDate null) pide las cuatro semanas alrededor de hoy',
        () {
      // Lo que manda el backend cuando el ciclo no tiene semanas: los siete
      // días con isoDate null, dateText vacío y "Semana actual".
      expect(
        ventanaDelCiclo(
          <DaySchedule>[
            for (final nombre in _nombresDeDia)
              DaySchedule(nombre, '', 'Semana actual'),
          ],
          hoy: DateTime.utc(2026, 9, 23, 10),
        ),
        (from: '2026-09-14', to: '2026-10-11'),
      );
    });

    test('en un ciclo largo, cambiar de semana pide la ventana de la semana nueva, y dentro de ella no',
        () async {
      // El controller REAL: lo que se prueba es el `ever` de su onInit sobre
      // currentDayIndex. Sus otras cargas fallan en silencio sin
      // StorageService registrado; no tocan a este doble.
      Get.put<AuthService>(_FakeAuthService(_alumna()));
      final api = _FakeBloquesApi();
      Get.put<TimeBlocksService>(TimeBlocksService(apiClient: api));
      final horario = Get.put<HorarioController>(HorarioController());
      await pumpEventQueue();
      // La del onInit: sin días todavía, es la de respaldo. No es lo que se
      // prueba aquí.
      api.ventanasPedidas.clear();

      horario.daysList.assignAll(_ciclo(semanas: 18));
      horario.currentDayIndex.value = 7 * 16; // lunes 14 de diciembre
      await pumpEventQueue();
      horario.currentDayIndex.value = 7 * 16 + 3; // jueves de esa semana
      await pumpEventQueue();
      horario.currentDayIndex.value = 7 * 17; // lunes 21 de diciembre
      await pumpEventQueue();

      expect(api.ventanasPedidas, <Map<String, String?>>[
        <String, String?>{'from': '2026-12-14', 'to': '2027-04-12'},
        <String, String?>{'from': '2026-12-21', 'to': '2027-04-19'},
      ]);
      // Borrarlo llama a su onClose, que apaga el reloj y el `ever`.
      Get.delete<HorarioController>();
    });

    /// La ventana que pediría el horario, sin días cargados, si hoy en Lima
    /// fuera [hoy]. El controller se crea sin registrar, así que su onInit no
    /// corre.
    ({String from, String to}) ventanaSiHoyEs(DateTime hoy) {
      final horario = HorarioController();
      horario.currentLimaTime.value = hoy;
      return horario.ventanaVisible();
    }

    test('sin ciclo con fechas, son las cuatro semanas alrededor de hoy, de lunes a domingo',
        () {
      // Miércoles 23: la semana pasada, esta y las dos siguientes.
      final ventana = ventanaSiHoyEs(DateTime.utc(2026, 9, 23, 10));
      expect(ventana, (from: '2026-09-14', to: '2026-10-11'));
      // En UTC: con la hora local, una máquina con cambio de hora dentro de la
      // ventana (Sídney lo tiene el 4 de octubre) contaría 26 días y 23 horas.
      final desde = DateTime.parse('${ventana.from}T00:00:00Z');
      final hasta = DateTime.parse('${ventana.to}T00:00:00Z');
      expect(
        hasta.difference(desde).inDays,
        27,
        reason: '28 días, lejos del tope de 120 del servidor',
      );
    });

    test('sin ciclo, el lunes y el domingo de una misma semana piden la misma ventana',
        () {
      const esperada = (from: '2026-09-14', to: '2026-10-11');
      expect(ventanaSiHoyEs(DateTime.utc(2026, 9, 21, 7)), esperada);
      expect(ventanaSiHoyEs(DateTime.utc(2026, 9, 27, 21, 59)), esperada);
    });

    test('sin ciclo, cruza el año sin romperse', () {
      // El 1 de enero de 2026 es jueves: su lunes es el 29 de diciembre.
      expect(
        ventanaSiHoyEs(DateTime.utc(2026, 1, 1, 10)),
        (from: '2025-12-22', to: '2026-01-18'),
      );
    });

    test('al crearse, el horario de una alumna pide sus bloques de esa ventana',
        () async {
      Get.put<AuthService>(_FakeAuthService(_alumna()));
      final api = _FakeBloquesApi();
      Get.put<TimeBlocksService>(TimeBlocksService(apiClient: api));

      // El controller REAL: lo que se prueba es su onInit. El resto de sus
      // cargas (días, secciones, evaluaciones, carga semanal) sale por su
      // propio ApiClient y falla en silencio sin StorageService registrado;
      // no toca a este doble. Los bloques se piden después de los días, que
      // aquí no llegan: la ventana es la de respaldo, una sola vez.
      final horario = Get.put<HorarioController>(HorarioController());
      await pumpEventQueue();

      final esperada = horario.ventanaVisible();
      expect(api.ventanasPedidas, <Map<String, String?>>[
        <String, String?>{'from': esperada.from, 'to': esperada.to},
      ]);
      // Borrarlo llama a su onClose, que apaga el reloj de un minuto.
      Get.delete<HorarioController>();
    });

    test('un docente no pide bloques propios', () async {
      Get.put<AuthService>(_FakeAuthService(_alumna(role: 'teacher')));
      final api = _FakeBloquesApi();
      Get.put<TimeBlocksService>(TimeBlocksService(apiClient: api));

      Get.put<HorarioController>(HorarioController());
      await pumpEventQueue();

      expect(api.ventanasPedidas, isEmpty);
      Get.delete<HorarioController>();
    });

    test('sin ciclo, al volver a la pestaña reload pide la ventana solo si cambió la semana',
        () async {
      // HomePage llama a reload() cada vez que se vuelve al horario, y el
      // controller vive mientras la app siga abierta: sin ciclo con fechas, es
      // lo único que corre la ventana de respaldo cuando pasa la semana.
      Get.put<AuthService>(_FakeAuthService(_alumna()));
      final api = _FakeBloquesApi();
      Get.put<TimeBlocksService>(TimeBlocksService(apiClient: api));
      // Sin registrar: su onInit no corre, así que las únicas peticiones son
      // las de cada reload. Sus otras cargas fallan en silencio, como arriba.
      final horario = HorarioController();

      horario.currentLimaTime.value = DateTime.utc(2026, 9, 23, 10);
      await horario.reload();
      await horario.reload(); // la misma semana: el service no vuelve a pedir
      horario.currentLimaTime.value = DateTime.utc(2026, 9, 30, 10);
      await horario.reload(); // la semana siguiente: ventana nueva

      expect(api.ventanasPedidas, <Map<String, String?>>[
        <String, String?>{'from': '2026-09-14', 'to': '2026-10-11'},
        <String, String?>{'from': '2026-09-21', 'to': '2026-10-18'},
      ]);
    });
  });

  group('UNITARIA · la fecha de cada día del horario (isoDate, D1)', () {
    test('DaySchedule.fromJson conserva isoDate y deja en null lo que no es una fecha',
        () {
      Map<String, dynamic> dia(Object? iso, {bool conClave = true}) =>
          <String, dynamic>{
            'dayName': 'Lunes',
            'dateText': '21 de Septiembre',
            'weekText': 'Semana 5 del ciclo',
            if (conClave) 'isoDate': iso,
          };

      final conFecha = DaySchedule.fromJson(dia('2026-09-21'));
      expect(conFecha.dayName, 'Lunes');
      expect(conFecha.dateText, '21 de Septiembre');
      expect(conFecha.weekText, 'Semana 5 del ciclo');
      expect(conFecha.isoDate, '2026-09-21');
      // Ciclo sin semanas: el backend manda null.
      expect(DaySchedule.fromJson(dia(null)).isoDate, isNull);
      // Un backend anterior no manda la clave: el campo es aditivo.
      expect(DaySchedule.fromJson(dia(null, conClave: false)).isoDate, isNull);
      // Lo que no es una fecha YYYY-MM-DD que existe no se cuela: ni el texto
      // del día, ni una fecha sin ceros, ni el 30 de febrero (DateTime lo
      // correría al 2 de marzo), ni un número. (Una fecha sin guiones no va
      // aquí: el script de cierre la tomaría por un código de alumno.)
      for (final malo in <Object>[
        '',
        '21 de Septiembre',
        '2026-9-21',
        '2026-02-30',
        21,
      ]) {
        expect(DaySchedule.fromJson(dia(malo)).isoDate, isNull, reason: '$malo');
      }
    });
  });

  group('UNITARIA · qué bloques propios caen en cada día (RF-BLQ-4)', () {
    setUp(() {
      Get.testMode = true;
      Get.reset();
    });
    tearDown(Get.reset);

    /// Un horario con el service ya cargado con [ocurrencias] y [reglas]. El
    /// controller se crea sin registrar: su onInit no corre y no pide nada.
    Future<HorarioController> horarioCon(
      List<Map<String, dynamic>> ocurrencias, {
      List<Map<String, dynamic>> reglas = const <Map<String, dynamic>>[],
    }) async {
      Get.put<AuthService>(_FakeAuthService(_alumna()));
      final servicio = TimeBlocksService(
        apiClient: _FakeBloquesApi(reglas: reglas, ocurrencias: ocurrencias),
      );
      Get.put<TimeBlocksService>(servicio);
      await servicio.load(from: '2026-09-14', to: '2026-10-11');
      return HorarioController();
    }

    test('filtra por fecha y no por nombre: el lunes 21 no es el lunes 28',
        () async {
      final horario = await horarioCon([
        _ocurrencia(fecha: '2026-09-21', diaDeLaSemana: 1, inicio: '14:00', fin: '18:00'),
      ]);
      // daysList trae los siete días de CADA semana del ciclo: por nombre,
      // la práctica del 21 saldría también el 28.
      final lunes21 = DaySchedule('Lunes', '21 de Septiembre', 'Semana 5 del ciclo',
          isoDate: '2026-09-21');
      final lunes28 = DaySchedule('Lunes', '28 de Septiembre', 'Semana 6 del ciclo',
          isoDate: '2026-09-28');

      expect(horario.bloquesDelDia(lunes21).map((o) => o.date), ['2026-09-21']);
      expect(horario.bloquesDelDia(lunes28), isEmpty);
    });

    test('la fecha del día es su isoDate, no su dateText', () async {
      final horario = await horarioCon([
        _ocurrencia(fecha: '2026-09-21', diaDeLaSemana: 1, inicio: '14:00', fin: '18:00'),
      ]);
      // Un dateText que no coincide con su isoDate: manda isoDate. Ninguna
      // fecha se lee de dateText (D1).
      expect(
        horario
            .bloquesDelDia(DaySchedule('Lunes', '28 de Septiembre', 'Semana 6 del ciclo',
                isoDate: '2026-09-21'))
            .map((o) => o.date),
        ['2026-09-21'],
      );
      expect(
        horario.bloquesDelDia(DaySchedule('Lunes', '21 de Septiembre', 'Semana 5 del ciclo',
            isoDate: '2026-09-28')),
        isEmpty,
      );
    });

    test('un ciclo sin semanas (isoDate null) toma ese día en la semana de hoy, '
        'y con más de una semana sin isoDate, ninguno', () async {
      final horario = await horarioCon([
        _ocurrencia(fecha: '2026-09-23', diaDeLaSemana: 3, inicio: '14:00', fin: '18:00'),
        _ocurrencia(fecha: '2026-09-30', diaDeLaSemana: 3, inicio: '14:00', fin: '18:00'),
      ]);
      horario.currentLimaTime.value = DateTime.utc(2026, 9, 22, 10); // martes
      // Sin semanas el backend manda los siete días con isoDate null,
      // dateText "" y weekText "Semana actual" (schedule.service.ts): no hay
      // fecha contra la que comparar, y por nombre saldrían los cuatro
      // miércoles de la ventana uno al lado del otro. Se toma el miércoles de
      // esta semana.
      final soloEste = ['2026-09-23'];
      expect(
        horario.bloquesDelDia(DaySchedule('Miércoles', '', 'Semana actual')).map((o) => o.date),
        soloEste,
      );
      expect(
        horario.bloquesDelDia(DaySchedule('Miercoles', '', 'Semana actual')).map((o) => o.date),
        soloEste,
      );
      expect(horario.bloquesDelDia(DaySchedule('Jueves', '', 'Semana actual')), isEmpty);

      // Lo mismo con daysList como lo llena el backend en ese caso: los siete
      // días sin isoDate. Siete no pasa el borde de la guarda (más de siete),
      // así que el miércoles sigue siendo el de esta semana.
      horario.daysList.assignAll([
        for (final nombre in const [
          'Lunes',
          'Martes',
          'Miércoles',
          'Jueves',
          'Viernes',
          'Sábado',
          'Domingo',
        ])
          DaySchedule(nombre, '', 'Semana actual'),
      ]);
      expect(
        horario.bloquesDelDia(DaySchedule('Miércoles', '', 'Semana actual')).map((o) => o.date),
        soloEste,
        reason: 'el ciclo sin semanas llega con siete días y sí tiene fecha',
      );

      // Un ciclo con semanas sin isoDate (un backend sin RS-BE-36): el
      // miércoles 23 no se distingue del 30, y la semana de hoy saldría en
      // cada semana del ciclo. No hay fecha, así que no se pinta nada.
      horario.daysList.assignAll([
        for (final d in _ciclo(semanas: 2, desde: DateTime.utc(2026, 9, 21)))
          DaySchedule(d.dayName, d.dateText, d.weekText),
      ]);
      expect(
        horario.bloquesDelDia(
            DaySchedule('Miércoles', '23 de Septiembre', 'Semana 1 del ciclo')),
        isEmpty,
      );
    });

    test('sin el service de bloques registrado no hay bloques, y nada se cae', () {
      expect(
        HorarioController().bloquesDelDia(
          DaySchedule('Lunes', '21 de Septiembre', 'Semana 5 del ciclo',
              isoDate: '2026-09-21'),
        ),
        isEmpty,
      );
    });

    test('los bloques propios no se cuelan en las clases ni en sus colores',
        () async {
      // Si vivieran en _todasLasSecciones, coursesForDay los devolvería como
      // clases (y podría marcarlos como evaluación por el nombre) y
      // colorPorCurso les daría un color de la paleta de doce, quitándoselo a
      // un curso real.
      final horario = await horarioCon([
        _ocurrencia(fecha: '2026-09-21', diaDeLaSemana: 1, inicio: '14:00', fin: '18:00'),
      ]);
      final lunes = DaySchedule('Lunes', '21 de Septiembre', 'Semana 5 del ciclo',
          isoDate: '2026-09-21');

      expect(horario.bloquesDelDia(lunes), hasLength(1));
      expect(horario.coursesForDay(lunes), isEmpty);
      expect(horario.colorPorCurso, isEmpty);
    });

    test('un día cancelado sale aparte, con las horas de su regla, y no entre las ocurrencias',
        () async {
      // El servidor no manda el miércoles 23 cancelado (RS-BE-33); la regla
      // sí trae la excepción, y de ahí sale para pintarlo tenue (RF-BLQ-5).
      final horario = await horarioCon(
        [
          _ocurrencia(fecha: '2026-09-21', diaDeLaSemana: 1, inicio: '14:00', fin: '18:00'),
        ],
        reglas: [
          _reglaConExcepciones([
            <String, dynamic>{'date': '2026-09-23', 'status': 'cancelled'},
          ]),
        ],
      );
      final lunes21 = DaySchedule('Lunes', '21 de Septiembre', 'Semana 5 del ciclo',
          isoDate: '2026-09-21');
      final miercoles23 = DaySchedule('Miércoles', '23 de Septiembre', 'Semana 5 del ciclo',
          isoDate: '2026-09-23');

      expect(horario.bloquesDelDia(miercoles23), isEmpty);
      final cancelados = horario.bloquesCanceladosDelDia(miercoles23);
      expect(cancelados, hasLength(1));
      expect(cancelados.single.blockId, 7);
      expect(cancelados.single.date, '2026-09-23');
      expect(cancelados.single.dayOfWeek, 3);
      expect(cancelados.single.startTime, '14:00');
      expect(cancelados.single.endTime, '18:00');
      expect(horario.bloquesCanceladosDelDia(lunes21), isEmpty);
    });

    test('una excepción cancelada que quedó fuera del patrón no se pinta', () async {
      // Tras editar la regla, una excepción puede quedar en un día que el
      // patrón ya no genera: el servidor la ignora al expandir, y la grilla
      // también.
      final horario = await horarioCon(
        const <Map<String, dynamic>>[],
        reglas: [
          _reglaConExcepciones([
            // Jueves: la regla es de lunes y miércoles.
            <String, dynamic>{'date': '2026-09-24', 'status': 'cancelled'},
            // Miércoles, pero después del 15 de diciembre.
            <String, dynamic>{'date': '2027-01-06', 'status': 'cancelled'},
          ]),
        ],
      );

      expect(
        horario.bloquesCanceladosDelDia(
          DaySchedule('Jueves', '24 de Septiembre', 'Semana 5 del ciclo',
              isoDate: '2026-09-24'),
        ),
        isEmpty,
      );
      expect(
        horario.bloquesCanceladosDelDia(
          DaySchedule('Miércoles', '6 de Enero', 'Semana 19 del ciclo',
              isoDate: '2027-01-06'),
        ),
        isEmpty,
      );
    });
  });

  group('WIDGET · bloques propios en la grilla del horario (RF-BLQ-4)', () {
    setUp(() {
      Get.testMode = true;
      Get.reset();
    });
    tearDown(Get.reset);

    testWidgets(
        'vista de día: el bloque propio lleva su nombre y su color, sin salón ni sección',
        (tester) async {
      await _montar(tester, pantalla: _vertical, ocurrencias: [
        _ocurrencia(fecha: '2026-09-21', diaDeLaSemana: 1, inicio: '14:00', fin: '18:00'),
      ]);

      expect(find.text('PRÁCTICAS DE PRUEBA'), findsOneWidget);
      expect(find.text('Sin salón'), findsNothing);
      expect(find.textContaining('Sección'), findsNothing);

      // El color es el que eligió la alumna (#27AE60), no uno de la paleta
      // que colorPorCurso reparte entre las secciones.
      final caja = tester.widget<Container>(
        find
            .descendant(of: _bloque('PRÁCTICAS DE PRUEBA'), matching: find.byType(Container))
            .first,
      );
      expect((caja.decoration as BoxDecoration).color, const Color(0xFF27AE60));
    });

    testWidgets('el nombre de un bloque propio va entero aunque lleve una barra',
        (tester) async {
      // La barra corta el nombre bilingüe que manda el portal ("CURSO /
      // COURSE"); el nombre de un bloque lo escribió la alumna.
      await _montar(tester, pantalla: _vertical, ocurrencias: [
        _ocurrencia(
          fecha: '2026-09-21',
          diaDeLaSemana: 1,
          inicio: '14:00',
          fin: '18:00',
          titulo: 'Prácticas / Taller de prueba',
        ),
      ]);

      expect(find.text('PRÁCTICAS / TALLER DE PRUEBA'), findsOneWidget);
    });

    testWidgets('vista semanal: el bloque propio sale en la columna de su día y solo ahí',
        (tester) async {
      await _montar(tester, pantalla: _horizontal, ocurrencias: [
        _ocurrencia(fecha: '2026-09-23', diaDeLaSemana: 3, inicio: '14:00', fin: '18:00'),
      ]);

      expect(find.text('PRÁCTICAS DE PRUEBA'), findsOneWidget);
      expect(find.textContaining('Sección'), findsNothing);
      final miercoles = _columnaDe(tester, 'Miércoles');
      final bloque = tester.getRect(_bloque('PRÁCTICAS DE PRUEBA'));
      expect(bloque.left, greaterThanOrEqualTo(miercoles.left));
      expect(bloque.right, lessThanOrEqualTo(miercoles.right));
    });

    testWidgets('vista semanal: los bloques son los de la semana del día activo',
        (tester) async {
      // La vista semanal arma sus columnas con la primera semana del ciclo
      // (_weekDays), y a las clases les da igual. A los bloques no: cada
      // semana tiene los suyos. Con el martes 29 activo, la semana es la del
      // 28 de septiembre al 4 de octubre.
      final dosSemanas = <DaySchedule>[
        ..._semana(),
        for (var i = 0; i < 7; i++) _diaDelCiclo(DateTime.utc(2026, 9, 28 + i), 6),
      ];
      await _montar(
        tester,
        pantalla: _horizontal,
        dias: dosSemanas,
        diaActivo: 8,
        ocurrencias: [
          _ocurrencia(fecha: '2026-09-21', diaDeLaSemana: 1, inicio: '14:00', fin: '18:00'),
          _ocurrencia(
            fecha: '2026-09-28',
            diaDeLaSemana: 1,
            inicio: '14:00',
            fin: '18:00',
            titulo: 'Voluntariado de prueba',
          ),
        ],
      );

      expect(find.text('VOLUNTARIADO DE PRUEBA'), findsOneWidget);
      expect(find.text('PRÁCTICAS DE PRUEBA'), findsNothing);
    });

    testWidgets('la vista semanal suma el domingo: siete columnas y su bloque se ve',
        (tester) async {
      await _montar(tester, pantalla: _horizontal, ocurrencias: [
        _ocurrencia(fecha: '2026-09-27', diaDeLaSemana: 7, inicio: '09:00', fin: '13:00'),
      ]);

      for (final dia in const [
        'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo',
      ]) {
        expect(find.text(dia), findsOneWidget, reason: dia);
      }
      final domingo = _columnaDe(tester, 'Domingo');
      final bloque = tester.getRect(_bloque('PRÁCTICAS DE PRUEBA'));
      expect(bloque.left, greaterThanOrEqualTo(domingo.left));
      expect(bloque.right, lessThanOrEqualTo(domingo.right));
    });

    testWidgets('vista de día: el bloque del domingo también se ve', (tester) async {
      await _montar(tester, pantalla: _vertical, diaActivo: 6, ocurrencias: [
        _ocurrencia(fecha: '2026-09-27', diaDeLaSemana: 7, inicio: '09:00', fin: '13:00'),
      ]);

      expect(find.text('Domingo, 27 de Septiembre'), findsOneWidget);
      expect(find.text('PRÁCTICAS DE PRUEBA'), findsOneWidget);
    });

    testWidgets('un horario sin domingo sigue con sus seis columnas, como hoy',
        (tester) async {
      await _montar(tester, pantalla: _horizontal, conDomingo: false, clasesPorDia: {
        'Sábado': [_clase('CURSO DE PRUEBA A', '08:00 am', '10:00 am')],
      });

      for (final dia in const ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado']) {
        expect(find.text(dia), findsOneWidget, reason: dia);
      }
      expect(find.text('Domingo'), findsNothing);
      // Seis columnas iguales: el ancho menos los 34 de la columna de horas.
      expect(_columnaDe(tester, 'Sábado').width, closeTo((1000 - 34) / 6, 0.01));
      expect(find.text('CURSO DE PRUEBA A'), findsOneWidget);
    });

    testWidgets(
        'vista de día: una clase y un bloque a la misma hora se parten el ancho y los dos reciben toques',
        (tester) async {
      await _montar(
        tester,
        pantalla: _vertical,
        clasesPorDia: {
          'Lunes': [_clase('CURSO DE PRUEBA A', '04:00 pm', '06:00 pm')],
        },
        ocurrencias: [
          _ocurrencia(fecha: '2026-09-21', diaDeLaSemana: 1, inicio: '14:00', fin: '18:00'),
        ],
      );

      final clase = tester.getRect(_bloque('CURSO DE PRUEBA A'));
      final propio = tester.getRect(_bloque('PRÁCTICAS DE PRUEBA'));
      // La pista de la vista de día va de 66 a 600 - 14 = 586: 520 de ancho.
      // El bloque propio empieza antes (14:00) y se queda con la columna 0.
      expect(propio.left, 66);
      expect(propio.width, closeTo(260, 0.01));
      expect(clase.left, closeTo(326, 0.01));
      expect(clase.right, closeTo(586, 0.01));
      expect(propio.overlaps(clase), isFalse);
      expect(_recibeElToque(tester, _bloque('CURSO DE PRUEBA A')), isTrue);
      expect(_recibeElToque(tester, _bloque('PRÁCTICAS DE PRUEBA')), isTrue);
    });

    testWidgets('vista semanal: también se parten la columna de su día',
        (tester) async {
      await _montar(
        tester,
        pantalla: _horizontal,
        clasesPorDia: {
          'Lunes': [_clase('CURSO DE PRUEBA A', '04:00 pm', '06:00 pm')],
        },
        ocurrencias: [
          _ocurrencia(fecha: '2026-09-21', diaDeLaSemana: 1, inicio: '14:00', fin: '18:00'),
        ],
      );

      final lunes = _columnaDe(tester, 'Lunes');
      final clase = tester.getRect(_bloque('CURSO DE PRUEBA A'));
      final propio = tester.getRect(_bloque('PRÁCTICAS DE PRUEBA'));
      // La pista: 1 px del borde izquierdo de la columna y 2 de margen a cada
      // lado. Cada uno se queda con la mitad.
      final pista = lunes.width - 1 - 2 - 2;
      expect(propio.left, closeTo(lunes.left + 1 + 2, 0.01));
      expect(propio.width, closeTo(pista / 2, 0.01));
      expect(clase.right, closeTo(lunes.right - 2, 0.01));
      expect(propio.overlaps(clase), isFalse);
      expect(_recibeElToque(tester, _bloque('CURSO DE PRUEBA A')), isTrue);
      expect(_recibeElToque(tester, _bloque('PRÁCTICAS DE PRUEBA')), isTrue);
    });

    testWidgets('sin cruces, un bloque ocupa lo mismo que hoy en la vista de día (66 y 14)',
        (tester) async {
      await _montar(tester, pantalla: _vertical, clasesPorDia: {
        'Lunes': [_clase('CURSO DE PRUEBA A', '08:00 am', '10:00 am')],
      });

      final clase = tester.getRect(_bloque('CURSO DE PRUEBA A'));
      expect(clase.left, 66);
      expect(clase.right, 600 - 14);
    });

    testWidgets('sin cruces, un bloque ocupa lo mismo que hoy en la vista semanal (2 y 2)',
        (tester) async {
      await _montar(tester, pantalla: _horizontal, clasesPorDia: {
        'Lunes': [_clase('CURSO DE PRUEBA A', '08:00 am', '10:00 am')],
      });

      final lunes = _columnaDe(tester, 'Lunes');
      final clase = tester.getRect(_bloque('CURSO DE PRUEBA A'));
      expect(clase.left, closeTo(lunes.left + 1 + 2, 0.01));
      expect(clase.right, closeTo(lunes.right - 2, 0.01));
    });

    testWidgets('un día movido se pinta en su hora nueva, no en la del patrón',
        (tester) async {
      // El patrón es de 14:00 a 18:00 y ese lunes el servidor lo manda movido
      // a 15:00-19:00. Dos clases hacen de regla: una termina a las 3 pm y la
      // otra empieza a las 7 pm; ninguna se cruza con el bloque, solo se tocan.
      await _montar(
        tester,
        pantalla: _vertical,
        clasesPorDia: {
          'Lunes': [
            _clase('CURSO DE PRUEBA A', '01:00 pm', '03:00 pm'),
            _clase('CURSO DE PRUEBA B', '07:00 pm', '08:00 pm'),
          ],
        },
        ocurrencias: [
          _ocurrencia(
            fecha: '2026-09-21',
            diaDeLaSemana: 1,
            inicio: '15:00',
            fin: '19:00',
            movida: true,
          ),
        ],
      );

      final antes = tester.getRect(_bloque('CURSO DE PRUEBA A'));
      final movido = tester.getRect(_bloque('PRÁCTICAS DE PRUEBA'));
      final despues = tester.getRect(_bloque('CURSO DE PRUEBA B'));
      // Entre dos bloques seguidos queda justo el pelo de separación.
      expect(movido.top - antes.bottom, closeTo(HorarioPage.blockHairline, 0.01));
      expect(despues.top - movido.bottom, closeTo(HorarioPage.blockHairline, 0.01));
      // Tocarse en el borde no reparte: los tres van a ancho completo.
      expect(antes.left, 66);
      expect(movido.left, 66);
      expect(despues.left, 66);
    });

    testWidgets(
        'un día cancelado se pinta tenue y lo dice, con las horas de la regla, y no como ocurrencia',
        (tester) async {
      // La regla dice lunes y miércoles de 14:00 a 18:00, y el miércoles 23
      // está cancelado. El servidor no manda esa ocurrencia (RS-BE-33): la
      // grilla lo pinta desde la excepción de la regla, tenue y con "Este día
      // está cancelado" (D2), para que la alumna pueda tocarlo y devolverlo al
      // patrón (RF-BLQ-5, Tarea 6).
      await _montar(
        tester,
        pantalla: _horizontal,
        reglas: [
          _reglaConExcepciones([
            <String, dynamic>{'date': '2026-09-23', 'status': 'cancelled'},
          ]),
        ],
        ocurrencias: [
          _ocurrencia(fecha: '2026-09-21', diaDeLaSemana: 1, inicio: '14:00', fin: '18:00'),
        ],
      );

      final lunes = _columnaDe(tester, 'Lunes');
      final miercoles = _columnaDe(tester, 'Miércoles');
      final bloques = _bloque('PRÁCTICAS DE PRUEBA');
      expect(bloques, findsNWidgets(2));
      Rect? delLunes;
      Rect? delMiercoles;
      for (var i = 0; i < 2; i++) {
        final rect = tester.getRect(bloques.at(i));
        final tenue = find.ancestor(
          of: bloques.at(i),
          matching: find.byWidgetPredicate((w) => w is Opacity && w.opacity < 1),
        );
        final aviso = find.descendant(
          of: bloques.at(i),
          matching: find.text('Este día está cancelado'),
        );
        if (rect.center.dx >= miercoles.left && rect.center.dx <= miercoles.right) {
          delMiercoles = rect;
          expect(tenue, findsOneWidget, reason: 'el cancelado va tenue');
          expect(aviso, findsOneWidget, reason: 'y lo dice debajo del nombre');
        } else {
          expect(rect.center.dx, inInclusiveRange(lunes.left, lunes.right));
          delLunes = rect;
          expect(tenue, findsNothing, reason: 'el lunes es una ocurrencia normal');
          expect(aviso, findsNothing);
        }
      }
      // Las horas de la regla: el mismo tramo que la ocurrencia del lunes.
      expect(delLunes, isNotNull);
      expect(delMiercoles, isNotNull);
      expect(delMiercoles!.top, closeTo(delLunes!.top, 0.01));
      expect(delMiercoles.height, closeTo(delLunes.height, 0.01));
    });

    testWidgets('un bloque de la semana 10 del ciclo se ve al navegar hasta ella',
        (tester) async {
      // La ventana es la del ciclo (RF-BLQ-7): 16 semanas, no las cuatro
      // alrededor de hoy. El doble del API solo devuelve lo que cae dentro
      // de la ventana pedida, como el servidor.
      final servicio = await _montar(
        tester,
        pantalla: _vertical,
        dias: _ciclo(semanas: 16),
        cargarAntes: false,
        ocurrencias: [
          _ocurrencia(fecha: '2026-10-26', diaDeLaSemana: 1, inicio: '14:00', fin: '18:00'),
        ],
      );
      final horario = Get.find<HorarioController>();
      final ventana = horario.ventanaVisible();
      await servicio.load(from: ventana.from, to: ventana.to);
      await tester.pump();
      expect(find.text('PRÁCTICAS DE PRUEBA'), findsNothing); // lunes 24 de agosto

      horario.currentDayIndex.value = 7 * 9; // lunes de la semana 10
      await tester.pump();

      expect(find.text('Lunes, 26 de Octubre'), findsOneWidget);
      expect(find.text('PRÁCTICAS DE PRUEBA'), findsOneWidget);
    });

    testWidgets('si los bloques llegan después de pintar el horario, aparecen solos',
        (tester) async {
      final servicio = await _montar(
        tester,
        pantalla: _vertical,
        cargarAntes: false,
        ocurrencias: [
          _ocurrencia(fecha: '2026-09-21', diaDeLaSemana: 1, inicio: '14:00', fin: '18:00'),
        ],
      );
      expect(find.text('PRÁCTICAS DE PRUEBA'), findsNothing);

      // Es lo que pasa en la app: el horario pinta sus días antes de que
      // vuelvan los bloques, y el service recarga su ventana después de
      // crear, editar o borrar. La grilla no hace nada y tiene que enterarse.
      await servicio.load(from: '2026-09-14', to: '2026-10-11');
      await tester.pump();

      expect(find.text('PRÁCTICAS DE PRUEBA'), findsOneWidget);
    });

    testWidgets('vista semanal: si los bloques llegan después, también aparecen solos',
        (tester) async {
      // La vista semanal tiene su propio LayoutBuilder y su propia lectura de
      // los bloques propios (propiosPorDia): la prueba de arriba no la cubre.
      final servicio = await _montar(
        tester,
        pantalla: _horizontal,
        cargarAntes: false,
        ocurrencias: [
          _ocurrencia(fecha: '2026-09-23', diaDeLaSemana: 3, inicio: '14:00', fin: '18:00'),
        ],
      );
      expect(find.text('PRÁCTICAS DE PRUEBA'), findsNothing);

      await servicio.load(from: '2026-09-14', to: '2026-10-11');
      await tester.pump();

      expect(find.text('PRÁCTICAS DE PRUEBA'), findsOneWidget);
    });
  });
}
