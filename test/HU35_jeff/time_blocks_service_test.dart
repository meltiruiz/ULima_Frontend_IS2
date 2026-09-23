// test/HU35_jeff/time_blocks_service_test.dart
//
// UNITARIA — HU35 (bloques de horario propios): modelo y capa de datos
// (RF-BLQ-7 y la sección "Contrato que se consume" de la spec).
// Modelo:   lib/models/time_block_model.dart
// Servicio: lib/services/time_blocks_service.dart
//
// Datos inventados: la alumna 20230001 no existe, el bloque "PRÁCTICAS DE
// PRUEBA" tampoco y las fechas son del ciclo de ejemplo de la spec. El
// repositorio es público: nada de esto sale de un horario real.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/time_block_model.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/malla_service.dart';
import 'package:ulima_plus/services/storage_service.dart';
import 'package:ulima_plus/services/time_blocks_service.dart';

/// Ventana de cuatro semanas: 2026-09-21 es lunes y 2026-10-18 domingo.
const String _desde = '2026-09-21';
const String _hasta = '2026-10-18';

UserModel _user({String code = '20230001', String role = 'student'}) =>
    UserModel(
      code: code,
      firstName: 'Alumna',
      lastName: 'De Prueba',
      email: 'test@aloe.ulima.edu.pe',
      role: role,
      currentCycle: '2026-2',
      setupComplete: true,
    );

/// La regla tal como la manda `GET /time-blocks/me`. Los dos días de
/// excepción (2026-10-07 y 2026-10-14) son miércoles, o sea que caen dentro
/// del patrón [1, 3].
Map<String, dynamic> _reglaJson({
  int id = 12,
  String titulo = 'PRÁCTICAS DE PRUEBA',
}) =>
    <String, dynamic>{
      'id': id,
      'title': titulo,
      'colorHex': '#EB5757',
      'daysOfWeek': <dynamic>[1, 3],
      'startTime': '14:00',
      'endTime': '18:00',
      'startDate': '2026-09-01',
      'endDate': '2026-12-15',
      'exceptions': <dynamic>[
        // Una excepción cancelada llega con las dos horas en null, como en el
        // contrato del backend.
        <String, dynamic>{
          'date': '2026-10-07',
          'status': 'cancelled',
          'startTime': null,
          'endTime': null,
        },
        <String, dynamic>{
          'date': '2026-10-14',
          'status': 'moved',
          'startTime': '15:00',
          'endTime': '19:00',
        },
      ],
    };

/// La lista de `GET /time-blocks/me`. La segunda entrada llega sin `id`: no
/// es una regla que se pueda editar ni borrar, y el service la descarta en
/// vez de guardarla con un id 0 (RF-BLQ-7).
Map<String, dynamic> _bloquesJson() => <String, dynamic>{
      'blocks': <dynamic>[
        _reglaJson(),
        Map<String, dynamic>.from(_reglaJson(id: 99))..remove('id'),
      ],
    };

Map<String, dynamic> _sinBloquesJson() =>
    <String, dynamic>{'blocks': <dynamic>[]};

/// La ventana ya expandida por el servidor, recortada a dos ocurrencias: el
/// lunes normal y el miércoles movido. `weeks` trae, como el backend, una
/// entrada por cada semana de lunes a domingo de la ventana, con el total de
/// la semana entera de la regla de [_reglaJson] (8 h; 4 h la del miércoles 7
/// cancelado). La segunda llega sin horas (`null`): el backend no lo manda
/// (una semana sin ocurrencias llega con 0), pero si llegara, el modelo lo
/// conserva en null y la línea de RF-BLQ-6 no lo pinta como 0.
Map<String, dynamic> _ocurrenciasJson() => <String, dynamic>{
      'occurrences': <dynamic>[
        <String, dynamic>{
          'blockId': 12,
          'title': 'PRÁCTICAS DE PRUEBA',
          'colorHex': '#EB5757',
          'date': '2026-09-21',
          'dayOfWeek': 1,
          'startTime': '14:00',
          'endTime': '18:00',
          'moved': false,
        },
        <String, dynamic>{
          'blockId': 12,
          'title': 'PRÁCTICAS DE PRUEBA',
          'colorHex': '#EB5757',
          'date': '2026-10-14',
          'dayOfWeek': 3,
          'startTime': '15:00',
          'endTime': '19:00',
          'moved': true,
        },
      ],
      'weeks': <dynamic>[
        <String, dynamic>{'weekStart': '2026-09-21', 'hours': 8},
        <String, dynamic>{'weekStart': '2026-09-28', 'hours': null},
        <String, dynamic>{'weekStart': '2026-10-05', 'hours': 4},
        <String, dynamic>{'weekStart': '2026-10-12', 'hours': 8},
      ],
    };

Map<String, dynamic> _sinOcurrenciasJson() => <String, dynamic>{
      'occurrences': <dynamic>[],
      'weeks': <dynamic>[],
    };

TimeBlockInput _entrada() => const TimeBlockInput(
      title: 'PRÁCTICAS DE PRUEBA',
      colorHex: '#EB5757',
      // Desordenados a propósito: toJson los manda ordenados.
      daysOfWeek: <int>[3, 1],
      startTime: '14:00',
      endTime: '18:00',
      startDate: '2026-09-01',
      endDate: '2026-12-15',
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

/// Lo mínimo para que `AuthService.logout()` corra en la prueba, como en
/// test/HU02_jeff/user_cache_reset_test.dart: no hay token guardado (no sale
/// el POST /auth/logout) y limpiar la sesión no hace nada.
class _SinSesionGuardada extends StorageService {
  @override
  Future<String?> get savedToken async => null;

  @override
  Future<void> clearSession() async {}
}

class _FakeBlocksApi extends ApiClient {
  _FakeBlocksApi({List<Object>? bloques, List<Object>? ocurrencias})
      : _bloques = bloques ?? <Object>[_bloquesJson()],
        _ocurrencias = ocurrencias ?? <Object>[_ocurrenciasJson()],
        super(configuredBaseUrl: 'http://test');

  /// Respuestas en orden; la última se repite. Un Map se devuelve, un
  /// Completer se espera y cualquier otra cosa se lanza.
  final List<Object> _bloques;
  final List<Object> _ocurrencias;

  int getBloques = 0;
  int getOcurrencias = 0;
  Map<String, String?> ultimaVentana = const <String, String?>{};

  /// "VERBO /ruta" de cada escritura, en orden.
  final List<String> escrituras = <String>[];
  final List<Map<String, dynamic>> cuerpos = <Map<String, dynamic>>[];
  Object? errorDeEscritura;

  Future<Map<String, dynamic>> _responder(List<Object> cola, int indice) {
    final r = cola[indice < cola.length ? indice : cola.length - 1];
    if (r is Completer<Map<String, dynamic>>) return r.future;
    if (r is Map<String, dynamic>) {
      return Future<Map<String, dynamic>>.value(r);
    }
    return Future<Map<String, dynamic>>.error(r);
  }

  Future<Map<String, dynamic>> _escribir(
    String llamada, {
    Map<String, dynamic>? body,
    required Map<String, dynamic> respuesta,
  }) {
    escrituras.add(llamada);
    if (body != null) cuerpos.add(body);
    if (errorDeEscritura != null) {
      return Future<Map<String, dynamic>>.error(errorDeEscritura!);
    }
    return Future<Map<String, dynamic>>.value(respuesta);
  }

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    String? token,
    Map<String, String?> query = const {},
    bool suppressSessionExpiry = false,
  }) {
    if (path == '/time-blocks/me/occurrences') {
      ultimaVentana = query;
      return _responder(_ocurrencias, getOcurrencias++);
    }
    return _responder(_bloques, getBloques++);
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) =>
      _escribir(
        'POST $path',
        body: body,
        respuesta: <String, dynamic>{'block': _reglaJson()},
      );

  @override
  Future<Map<String, dynamic>> patchJson(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) =>
      _escribir(
        'PATCH $path',
        body: body,
        respuesta: <String, dynamic>{
          'block': _reglaJson(titulo: 'PRÁCTICAS EDITADAS'),
        },
      );

  @override
  Future<Map<String, dynamic>> putJson(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) =>
      _escribir(
        'PUT $path',
        body: body,
        respuesta: <String, dynamic>{
          'exception': <String, dynamic>{
            'date': '2026-10-14',
            'status': 'moved',
            'startTime': '15:00',
            'endTime': '19:00',
          },
        },
      );

  @override
  Future<Map<String, dynamic>> deleteJson(String path, {String? token}) =>
      _escribir(
        'DELETE $path',
        respuesta: <String, dynamic>{'ok': true},
      );
}

_FakeAuthService _loguear(UserModel? user) {
  final auth = _FakeAuthService(user);
  Get.put<AuthService>(auth);
  return auth;
}

TimeBlocksService _servicio(_FakeBlocksApi api) =>
    Get.put<TimeBlocksService>(TimeBlocksService(apiClient: api));

void main() {
  // Get.put de un GetxService agenda onReady con
  // Get.engine.addPostFrameCallback, que necesita el binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(Get.reset);
  tearDown(Get.reset);

  group('UNITARIA · Modelo de los bloques de horario (HU35)', () {
    test('caso 1: el contrato completo se parsea tal como llega', () {
      final regla = TimeBlockRule.fromJson(
        (_bloquesJson()['blocks'] as List).first,
      );
      expect(regla.id, 12);
      expect(regla.title, 'PRÁCTICAS DE PRUEBA');
      expect(regla.colorHex, '#EB5757');
      expect(regla.daysOfWeek, <int>[1, 3]);
      expect(regla.startTime, '14:00');
      expect(regla.endTime, '18:00');
      expect(regla.startDate, '2026-09-01');
      expect(regla.endDate, '2026-12-15');
      expect(regla.exceptions, hasLength(2));
      expect(regla.exceptions.first.date, '2026-10-07');
      expect(regla.exceptions.first.status, 'cancelled');
      expect(regla.exceptions.first.startTime, isNull);
      expect(regla.exceptions.last.status, 'moved');
      expect(regla.exceptions.last.startTime, '15:00');
      expect(regla.exceptions.last.endTime, '19:00');

      final snapshot = TimeBlocksSnapshot.fromJson(_ocurrenciasJson());
      expect(snapshot.occurrences, hasLength(2));
      final primera = snapshot.occurrences.first;
      expect(primera.blockId, 12);
      expect(primera.title, 'PRÁCTICAS DE PRUEBA');
      expect(primera.colorHex, '#EB5757');
      expect(primera.date, '2026-09-21');
      expect(primera.dayOfWeek, 1);
      expect(primera.startTime, '14:00');
      expect(primera.endTime, '18:00');
      expect(primera.moved, isFalse);
      expect(snapshot.occurrences.last.moved, isTrue);
      expect(snapshot.occurrences.last.startTime, '15:00');
      expect(snapshot.weeks, hasLength(4));
      expect(snapshot.weeks.first.weekStart, '2026-09-21');
      expect(snapshot.weeks.first.hours, 8.0);
      expect(
        TimeBlockWeek.fromJson(
          <String, dynamic>{'weekStart': '2026-10-05', 'hours': 12.5},
        ).hours,
        12.5,
        reason: 'las horas pueden traer decimal y no se redondean',
      );
    });

    test('caso 2: un campo ausente queda en null y no se inventa ningún 0',
        () {
      expect(
        TimeBlockWeek.fromJson(
          <String, dynamic>{'weekStart': '2026-09-28'},
        ).hours,
        isNull,
      );
      expect(
        TimeBlocksSnapshot.fromJson(_ocurrenciasJson()).weeks[1].hours,
        isNull,
        reason: 'hours en null se conserva en null, nunca como 0',
      );

      final cancelado = TimeBlockException.fromJson(
        <String, dynamic>{'date': '2026-10-07', 'status': 'cancelled'},
      );
      expect(cancelado.startTime, isNull);
      expect(cancelado.endTime, isNull);

      final vacio = TimeBlocksSnapshot.fromJson(<String, dynamic>{});
      expect(vacio.occurrences, isEmpty);
      expect(vacio.weeks, isEmpty);

      final regla = TimeBlockRule.fromJson(<String, dynamic>{
        'id': 13,
        'title': 'BLOQUE DE PRUEBA',
        'colorHex': '#2F80ED',
        'daysOfWeek': <dynamic>[1, 0, 8, 'x', 3],
        'startTime': '07:00',
        'endTime': '09:00',
        'startDate': '2026-09-01',
        'endDate': '2026-09-30',
      });
      expect(
        regla.daysOfWeek,
        <int>[1, 3],
        reason: 'lo que no es un día de 1 a 7 se descarta, no se cuela como 0',
      );
      expect(regla.exceptions, isEmpty);

      final completa = <String, dynamic>{
        'blockId': 13,
        'title': 'BLOQUE DE PRUEBA',
        'colorHex': '#2F80ED',
        'date': '2026-09-21',
        'dayOfWeek': 1,
        'startTime': '07:00',
        'endTime': '09:00',
      };
      final sinMoved = TimeBlockOccurrence.fromJson(completa);
      expect(sinMoved.moved, isFalse);

      // Una ocurrencia sin lo imprescindible se descarta: no llega con un
      // blockId 0 (tocarla mandaría /time-blocks/me/0/…) ni con horas ''
      // (se pintaría a las 7:00, el respaldo de la grilla).
      final filtradas = TimeBlocksSnapshot.fromJson(<String, dynamic>{
        'occurrences': <dynamic>[
          Map<String, dynamic>.from(completa)..remove('blockId'),
          Map<String, dynamic>.from(completa)..remove('startTime'),
          Map<String, dynamic>.from(completa)..['date'] = 'mañana',
          completa,
        ],
      });
      expect(filtradas.occurrences, hasLength(1));
      expect(filtradas.occurrences.single.blockId, 13);
      expect(
        TimeBlockOccurrence.tryFromJson(<String, dynamic>{'blockId': 13}),
        isNull,
      );
      expect(
        TimeBlockOccurrence.tryFromJson(
          Map<String, dynamic>.from(completa)..remove('dayOfWeek'),
        )!.dayOfWeek,
        1,
        reason: 'sin dayOfWeek, sale de la fecha y no queda en 0',
      );

      // Una regla sin id no es una regla: no llega con id 0.
      expect(
        TimeBlockRule.tryFromJson(
          Map<String, dynamic>.from(_reglaJson())..remove('id'),
        ),
        isNull,
      );
      expect(
        () => TimeBlockRule.fromJson(<String, dynamic>{'title': 'SIN ID'}),
        throwsFormatException,
      );
    });

    test('caso 3: toJson devuelve el contrato y conserva los null', () {
      final cancelado = TimeBlockException.fromJson(
        <String, dynamic>{'date': '2026-10-07', 'status': 'cancelled'},
      );
      expect(cancelado.toJson(), <String, dynamic>{
        'date': '2026-10-07',
        'status': 'cancelled',
        'startTime': null,
        'endTime': null,
      });

      final regla = TimeBlockRule.fromJson(
        (_bloquesJson()['blocks'] as List).first,
      );
      final ida = TimeBlockRule.fromJson(regla.toJson());
      expect(ida.id, regla.id);
      expect(ida.title, regla.title);
      expect(ida.daysOfWeek, regla.daysOfWeek);
      expect(ida.startTime, regla.startTime);
      expect(ida.endDate, regla.endDate);
      expect(ida.exceptions, hasLength(2));
      expect(ida.exceptions.first.startTime, isNull);

      final movida = TimeBlocksSnapshot.fromJson(
        _ocurrenciasJson(),
      ).occurrences.last;
      expect(TimeBlockOccurrence.fromJson(movida.toJson()).moved, isTrue);
    });
  });

  group('UNITARIA · TimeBlocksService (HU35)', () {
    test('caso 4: load pide las dos rutas con la ventana y guarda todo',
        () async {
      _loguear(_user());
      final api = _FakeBlocksApi();
      final s = _servicio(api);

      await s.load(from: _desde, to: _hasta);

      expect(api.getBloques, 1);
      expect(api.getOcurrencias, 1);
      expect(api.ultimaVentana, <String, String?>{
        'from': _desde,
        'to': _hasta,
      });
      expect(
        s.blocks,
        hasLength(1),
        reason: 'la entrada sin id se descarta, no llega con id 0',
      );
      expect(s.blocks.single.title, 'PRÁCTICAS DE PRUEBA');
      expect(s.snapshot!.occurrences, hasLength(2));
      expect(s.snapshot!.weeks, hasLength(4));
      expect(s.isLoading, isFalse);
      expect(s.hasError, isFalse);
    });

    test('caso 5: sin force no repite la misma ventana; otra ventana sí',
        () async {
      _loguear(_user());
      final api = _FakeBlocksApi();
      final s = _servicio(api);

      await s.load(from: _desde, to: _hasta);
      await s.load(from: _desde, to: _hasta);
      expect(api.getOcurrencias, 1);

      await s.load(from: _desde, to: _hasta, force: true);
      expect(api.getOcurrencias, 2);

      await s.load(from: '2026-10-19', to: '2026-11-15');
      expect(api.getOcurrencias, 3);
      expect(api.ultimaVentana, <String, String?>{
        'from': '2026-10-19',
        'to': '2026-11-15',
      });
    });

    test('caso 6: dos load() simultáneos hacen una sola pareja de GET',
        () async {
      _loguear(_user());
      final reglas = Completer<Map<String, dynamic>>();
      final ocurrencias = Completer<Map<String, dynamic>>();
      final api = _FakeBlocksApi(
        bloques: <Object>[reglas],
        ocurrencias: <Object>[ocurrencias],
      );
      final s = _servicio(api);

      final a = s.load(from: _desde, to: _hasta);
      final b = s.load(from: _desde, to: _hasta);
      expect(s.isLoading, isTrue);

      reglas.complete(_bloquesJson());
      ocurrencias.complete(_ocurrenciasJson());
      await Future.wait(<Future<void>>[a, b]);

      expect(api.getBloques, 1);
      expect(api.getOcurrencias, 1);
      expect(s.isLoading, isFalse);
      expect(s.snapshot!.occurrences, hasLength(2));
    });

    test('caso 7: un docente o una sesión sin usuario nunca piden nada',
        () async {
      final auth = _loguear(_user(code: 'docente.test', role: 'teacher'));
      final api = _FakeBlocksApi();
      final s = _servicio(api);

      await s.load(from: _desde, to: _hasta);
      await s.load(from: _desde, to: _hasta, force: true);
      await s.reload();

      expect(api.getBloques, 0);
      expect(api.getOcurrencias, 0);
      expect(s.blocks, isEmpty);
      expect(s.snapshot, isNull);
      expect(s.isLoading, isFalse);

      auth.userRx.value = null;
      await s.load(from: _desde, to: _hasta, force: true);
      expect(api.getBloques, 0);
    });

    test('caso 8: otro usuario sin logout de por medio no ve lo anterior',
        () async {
      final auth = _loguear(_user());
      final api = _FakeBlocksApi(
        bloques: <Object>[_bloquesJson(), _sinBloquesJson()],
        ocurrencias: <Object>[_ocurrenciasJson(), _sinOcurrenciasJson()],
      );
      final s = _servicio(api);
      await s.load(from: _desde, to: _hasta);
      expect(s.blocks, hasLength(1));

      // Un código que no puede ser real: el repo es público.
      auth.userRx.value = _user(code: 'alumna.b.test');
      expect(s.blocks, isEmpty, reason: 'ni siquiera antes de llamar a load()');
      expect(s.snapshot, isNull);

      await s.load(from: _desde, to: _hasta);
      expect(api.getOcurrencias, 2);
      expect(s.blocks, isEmpty);
      expect(s.snapshot!.occurrences, isEmpty);
    });

    test('caso 9: un fallo no lanza: deja hasError y el siguiente reintenta',
        () async {
      _loguear(_user());
      final api = _FakeBlocksApi(
        bloques: <Object>[Exception('socket'), _bloquesJson()],
        ocurrencias: <Object>[Exception('socket'), _ocurrenciasJson()],
      );
      final s = _servicio(api);

      await expectLater(s.load(from: _desde, to: _hasta), completes);
      expect(s.hasError, isTrue);
      expect(s.blocks, isEmpty);
      expect(s.snapshot, isNull);
      expect(s.isLoading, isFalse);

      await s.load(from: _desde, to: _hasta);
      expect(
        api.getOcurrencias,
        2,
        reason: 'un fallo no deja la ventana marcada como cargada',
      );
      expect(s.hasError, isFalse);
      expect(s.snapshot!.occurrences, hasLength(2));
    });

    test('caso 10: create manda el body del contrato y recarga una sola vez',
        () async {
      _loguear(_user());
      final api = _FakeBlocksApi();
      final s = _servicio(api);
      await s.load(from: _desde, to: _hasta);

      final creado = await s.create(_entrada());

      expect(api.escrituras, <String>['POST /time-blocks/me']);
      expect(api.cuerpos.single, <String, dynamic>{
        'title': 'PRÁCTICAS DE PRUEBA',
        'colorHex': '#EB5757',
        'daysOfWeek': <int>[1, 3],
        'startTime': '14:00',
        'endTime': '18:00',
        'startDate': '2026-09-01',
        'endDate': '2026-12-15',
      });
      expect(creado.id, 12);
      expect(api.getBloques, 2, reason: 'una sola recarga de la ventana');
      expect(api.getOcurrencias, 2);
      expect(api.ultimaVentana, <String, String?>{
        'from': _desde,
        'to': _hasta,
      });
    });

    test('caso 11: update usa PATCH con el id y recarga', () async {
      _loguear(_user());
      final api = _FakeBlocksApi();
      final s = _servicio(api);
      await s.load(from: _desde, to: _hasta);

      final editado = await s.update(12, _entrada());

      expect(api.escrituras, <String>['PATCH /time-blocks/me/12']);
      expect(api.cuerpos.single['daysOfWeek'], <int>[1, 3]);
      expect(editado.title, 'PRÁCTICAS EDITADAS');
      expect(api.getOcurrencias, 2);
    });

    test('caso 12: remove borra el bloque y recarga', () async {
      _loguear(_user());
      final api = _FakeBlocksApi();
      final s = _servicio(api);
      await s.load(from: _desde, to: _hasta);

      await s.remove(12);

      expect(api.escrituras, <String>['DELETE /time-blocks/me/12']);
      expect(api.getOcurrencias, 2);
    });

    test('caso 13: cancelar un día no manda horas y moverlo sí', () async {
      _loguear(_user());
      final api = _FakeBlocksApi();
      final s = _servicio(api);
      await s.load(from: _desde, to: _hasta);

      await s.setException(12, '2026-10-07', status: 'cancelled');
      expect(
        api.escrituras.last,
        'PUT /time-blocks/me/12/occurrences/2026-10-07',
      );
      expect(api.cuerpos.last, <String, dynamic>{'status': 'cancelled'});

      await s.setException(
        12,
        '2026-10-14',
        status: 'moved',
        startTime: '15:00',
        endTime: '19:00',
      );
      expect(
        api.escrituras.last,
        'PUT /time-blocks/me/12/occurrences/2026-10-14',
      );
      expect(api.cuerpos.last, <String, dynamic>{
        'status': 'moved',
        'startTime': '15:00',
        'endTime': '19:00',
      });
      expect(api.getOcurrencias, 3, reason: 'una recarga por excepción');
    });

    test('caso 14: clearException devuelve el día al patrón y recarga',
        () async {
      _loguear(_user());
      final api = _FakeBlocksApi();
      final s = _servicio(api);
      await s.load(from: _desde, to: _hasta);

      await s.clearException(12, '2026-10-07');

      expect(
        api.escrituras,
        <String>['DELETE /time-blocks/me/12/occurrences/2026-10-07'],
      );
      expect(api.getOcurrencias, 2);
    });

    test('caso 15: un error del servidor sale con su mensaje y no recarga',
        () async {
      _loguear(_user());
      final api = _FakeBlocksApi()
        ..errorDeEscritura = ApiException(
          statusCode: 400,
          code: 'TIME_BLOCK_OUT_OF_GRID',
          message: 'El bloque tiene que empezar y terminar entre las 07:00 y las 22:00.',
        );
      final s = _servicio(api);
      await s.load(from: _desde, to: _hasta);

      await expectLater(
        s.create(_entrada()),
        throwsA(
          isA<TimeBlocksFailure>().having(
            (e) => e.message,
            'message',
            'El bloque tiene que empezar y terminar entre las 07:00 y las 22:00.',
          ),
        ),
      );
      expect(api.getOcurrencias, 1, reason: 'sin escritura no hay recarga');
    });

    test('caso 16: un fallo de red sale con el mensaje genérico y recarga, '
        'porque la escritura pudo quedar guardada', () async {
      _loguear(_user());
      final api = _FakeBlocksApi()..errorDeEscritura = Exception('socket');
      final s = _servicio(api);
      await s.load(from: _desde, to: _hasta);

      await expectLater(
        s.remove(12),
        throwsA(
          isA<TimeBlocksFailure>().having(
            (e) => e.message,
            'message',
            TimeBlocksService.genericErrorMessage,
          ),
        ),
      );
      // La recarga va sin esperar: se deja correr antes de contar.
      await Future<void>.delayed(Duration.zero);
      expect(
        api.getOcurrencias,
        2,
        reason: 'sin respuesta no se sabe si el servidor la guardó (un plazo '
            'vencido puede llegar después de guardar): se vuelve a pedir la '
            'ventana',
      );
      expect(api.ultimaVentana, <String, String?>{
        'from': _desde,
        'to': _hasta,
      });
    });

    test('caso 17: logout() vacía los bloques y el siguiente load vuelve a pedir',
        () async {
      // TT06: AuthService.logout() invalida las cachés por usuario, como ya
      // hace con el récord. El doble de sesión sigue devolviendo a la misma
      // alumna, así que lo único que puede vaciar el estado es el clear()
      // que llama logout(): sin ese enganche, blocks seguiría lleno.
      _loguear(_user());
      Get.put<StorageService>(_SinSesionGuardada());
      Get.put<MallaService>(MallaService());
      final api = _FakeBlocksApi();
      final s = _servicio(api);
      await s.load(from: _desde, to: _hasta);
      expect(s.blocks, hasLength(1));

      await AuthService.to.logout();

      expect(s.blocks, isEmpty);
      expect(s.snapshot, isNull);
      await s.load(from: _desde, to: _hasta);
      expect(
        api.getOcurrencias,
        2,
        reason: 'sin la copia anterior, la misma ventana se vuelve a pedir',
      );
    });

    test('caso 18: un fallo al cambiar de ventana no la deja marcada como '
        'cargada', () async {
      // El caso 9 lo prueba en la primera carga. Aquí ya hay una foto, la de
      // la ventana anterior, y esa foto no puede contar como la de la nueva.
      _loguear(_user());
      final api = _FakeBlocksApi(
        bloques: <Object>[_bloquesJson(), Exception('socket'), _bloquesJson()],
        ocurrencias: <Object>[
          _ocurrenciasJson(),
          Exception('socket'),
          _sinOcurrenciasJson(),
        ],
      );
      final s = _servicio(api);
      await s.load(from: _desde, to: _hasta);

      await s.load(from: '2026-10-19', to: '2026-11-15');
      expect(s.hasError, isTrue);

      await s.load(from: '2026-10-19', to: '2026-11-15');
      expect(
        api.getOcurrencias,
        3,
        reason: 'un fallo no deja la ventana marcada como cargada, tampoco '
            'cuando queda la foto de la ventana anterior',
      );
      expect(api.ultimaVentana, <String, String?>{
        'from': '2026-10-19',
        'to': '2026-11-15',
      });
      expect(s.hasError, isFalse);
      expect(s.snapshot!.occurrences, isEmpty);
    });

    test('caso 19: con la foto de otra ventana, un segundo load() espera la '
        'carga en vuelo', () async {
      _loguear(_user());
      final reglas = Completer<Map<String, dynamic>>();
      final ocurrencias = Completer<Map<String, dynamic>>();
      final api = _FakeBlocksApi(
        bloques: <Object>[_bloquesJson(), reglas],
        ocurrencias: <Object>[_ocurrenciasJson(), ocurrencias],
      );
      final s = _servicio(api);
      await s.load(from: _desde, to: _hasta);

      final primera = s.load(from: '2026-10-19', to: '2026-11-15');
      var segundaTermino = false;
      final segunda = s
          .load(from: '2026-10-19', to: '2026-11-15')
          .then((_) => segundaTermino = true);
      await Future<void>.delayed(Duration.zero);
      expect(
        segundaTermino,
        isFalse,
        reason: 'la foto que hay es la de la ventana anterior: quien espera '
            'tiene que esperar la carga en vuelo',
      );

      reglas.complete(_sinBloquesJson());
      ocurrencias.complete(_sinOcurrenciasJson());
      await Future.wait(<Future<void>>[primera, segunda]);

      expect(segundaTermino, isTrue);
      expect(api.getOcurrencias, 2, reason: 'una sola pareja de GET');
      expect(s.snapshot!.occurrences, isEmpty);
    });

    test('caso 20: una recarga fallida tras escribir no deja la ventana '
        'marcada como cargada', () async {
      // La escritura sale bien y su recarga falla: queda la foto de antes de
      // escribir. El siguiente load() sin force de la misma ventana (volver a
      // la pestaña, cambiar de día) la vuelve a pedir, en vez de quedarse con
      // esa foto hasta la próxima escritura o un reinicio.
      _loguear(_user());
      final api = _FakeBlocksApi(
        bloques: <Object>[
          _sinBloquesJson(),
          Exception('socket'),
          _bloquesJson(),
        ],
        ocurrencias: <Object>[
          _sinOcurrenciasJson(),
          Exception('socket'),
          _ocurrenciasJson(),
        ],
      );
      final s = _servicio(api);
      await s.load(from: _desde, to: _hasta);

      await s.create(_entrada());
      expect(s.hasError, isTrue, reason: 'la recarga falló');
      expect(s.snapshot!.occurrences, isEmpty);

      await s.load(from: _desde, to: _hasta);
      expect(
        api.getOcurrencias,
        3,
        reason: 'la foto que dejó la recarga fallida no cuenta como cargada',
      );
      expect(s.hasError, isFalse);
      expect(s.snapshot!.occurrences, hasLength(2));
    });

    test('caso 21: create y update dejan en blocks la regla que devuelve el '
        'servidor, aunque la recarga falle', () async {
      // El aviso de cruce del formulario compara contra blocks. Si la recarga
      // que sigue a una escritura buena falla, el bloque guardado ya está ahí
      // y la alumna no lo crea otra vez sin enterarse.
      _loguear(_user());
      final api = _FakeBlocksApi(
        bloques: <Object>[_sinBloquesJson(), Exception('socket')],
        ocurrencias: <Object>[_sinOcurrenciasJson(), Exception('socket')],
      );
      final s = _servicio(api);
      await s.load(from: _desde, to: _hasta);
      expect(s.blocks, isEmpty);

      final creado = await s.create(_entrada());
      expect(s.hasError, isTrue, reason: 'la recarga falló');
      expect(s.blocks.map((b) => b.id), <int>[creado.id]);
      expect(s.blocks.single.title, 'PRÁCTICAS DE PRUEBA');

      await s.update(creado.id, _entrada());
      expect(
        s.blocks,
        hasLength(1),
        reason: 'la editada reemplaza a la del mismo id, no se suma otra',
      );
      expect(s.blocks.single.title, 'PRÁCTICAS EDITADAS');
    });
  });
}
