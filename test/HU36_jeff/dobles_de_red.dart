// test/HU36_jeff/dobles_de_red.dart
//
// Dobles escritos a mano para las pruebas del test de especialidad (HU36).
// No es un archivo de pruebas. Nada de mockito ni mocktail.

import 'dart:async';

import 'package:get/get.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/storage_service.dart';

import 'datos_de_prueba.dart';

/// Un `ApiClient` sin red. Cada ruta tiene su cola de respuestas en orden, y
/// la última se repite. Un Map se devuelve, un Completer se espera y
/// cualquier otra cosa se lanza.
class ApiFalsaDelTest extends ApiClient {
  ApiFalsaDelTest({
    List<Object>? contenido,
    List<Object>? evaluaciones,
    List<Object>? resultados,
    List<Object>? guardados,
    List<Object>? carreras,
    List<Object>? especialidades,
  }) : contenido = contenido ?? <Object>[contenidoJson()],
       evaluaciones = evaluaciones ?? <Object>[resultadoJson()],
       resultados = resultados ?? <Object>[ultimoResultadoJson()],
       guardados = guardados ?? const <Object>[],
       carreras = carreras ?? <Object>[carrerasJson()],
       especialidades = especialidades ?? <Object>[especialidadesJson()],
       super(configuredBaseUrl: 'http://test');

  final List<Object> contenido;
  final List<Object> evaluaciones;
  final List<Object> resultados;

  /// Sin respuestas propias, el `PUT` devuelve lo que recibe.
  final List<Object> guardados;
  final List<Object> carreras;
  final List<Object> especialidades;

  int getsDeContenido = 0;
  int getsDeResultado = 0;
  int getsDeCarreras = 0;
  int getsDeEspecialidades = 0;
  final List<Map<String, dynamic>> cuerposDeEvaluacion =
      <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> cuerposDeGuardado = <Map<String, dynamic>>[];

  /// "VERBO /ruta" de cada llamada, en orden.
  final List<String> llamadas = <String>[];

  Future<Map<String, dynamic>> _responder(List<Object> cola, int indice) {
    final r = cola[indice < cola.length ? indice : cola.length - 1];
    if (r is Completer<Map<String, dynamic>>) return r.future;
    if (r is Map<String, dynamic>) {
      return Future<Map<String, dynamic>>.value(r);
    }
    return Future<Map<String, dynamic>>.error(r);
  }

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    String? token,
    Map<String, String?> query = const {},
    bool suppressSessionExpiry = false,
  }) {
    llamadas.add('GET $path');
    switch (path) {
      case '/specialty-test/content':
        return _responder(contenido, getsDeContenido++);
      case '/specialty-test/me/result':
        return _responder(resultados, getsDeResultado++);
      case '/academic-profile/careers':
        return _responder(carreras, getsDeCarreras++);
      case '/academic-profile/specialties':
        return _responder(especialidades, getsDeEspecialidades++);
    }
    return Future<Map<String, dynamic>>.error(
      StateError('ruta sin respuesta de prueba: $path'),
    );
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) {
    llamadas.add('POST $path');
    if (path == '/specialty-test/me/evaluate') {
      cuerposDeEvaluacion.add(body);
      return _responder(evaluaciones, cuerposDeEvaluacion.length - 1);
    }
    // POST /auth/logout y cualquier otro no tienen nada que responder.
    return Future<Map<String, dynamic>>.value(<String, dynamic>{});
  }

  @override
  Future<Map<String, dynamic>> putJson(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) {
    llamadas.add('PUT $path');
    cuerposDeGuardado.add(body);
    if (guardados.isEmpty) {
      return Future<Map<String, dynamic>>.value(respuestaDeGuardado(body));
    }
    return _responder(guardados, cuerposDeGuardado.length - 1);
  }
}

/// Lo que responde `PUT /academic-profile/me/specialties` a [body].
Map<String, dynamic> respuestaDeGuardado(Map<String, dynamic> body) =>
    <String, dynamic>{
      'message': 'Specialties updated',
      'specialties': <dynamic>[
        if (body['primarySpecialtyId'] != null)
          <String, dynamic>{
            'specialtyId': body['primarySpecialtyId'],
            'selectionType': 'primary',
          },
        for (final id in body['interestSpecialtyIds'] as List)
          <String, dynamic>{'specialtyId': id, 'selectionType': 'interest'},
      ],
    };

/// `GET /academic-profile/careers` con la carrera de prueba.
Map<String, dynamic> carrerasJson() => <String, dynamic>{
  'careers': <dynamic>[
    <String, dynamic>{
      'id': 1,
      'code': 'ING-PRUEBA',
      'name': 'Carrera de Prueba',
      'faculty': 'Facultad de Prueba',
    },
  ],
};

/// `GET /academic-profile/specialties` con las cuatro oficiales, con los
/// campos que la app lee.
Map<String, dynamic> especialidadesJson({List<int>? ids}) {
  const nombres = <int, String>{
    kIdSw: 'Ingeniería de Software',
    kIdTi: 'Tecnologías de la Información',
    kIdSi: 'Sistemas de Información',
    kIdVj: 'Desarrollo de Videojuegos',
  };
  final lista = ids ?? nombres.keys.toList();
  return <String, dynamic>{
    'specialties': <dynamic>[
      for (var i = 0; i < lista.length; i++)
        <String, dynamic>{
          'id': lista[i],
          'carrera_id': 1,
          'name': nombres[lista[i]] ?? 'ESPECIALIDAD DE PRUEBA ${lista[i]}',
          'description': 'Descripción de prueba.',
          'is_active': true,
          'display_order': i + 1,
        },
    ],
  };
}

/// Un `AuthService` que solo pone un usuario, como en las pruebas de HU35.
class AuthConUsuario extends AuthService {
  AuthConUsuario(UserModel? user) : userRx = Rx<UserModel?>(user);

  final Rx<UserModel?> userRx;

  @override
  UserModel? get currentUser => userRx.value;

  @override
  Rx<UserModel?> get currentUserRx => userRx;

  @override
  Future<void> refreshCurrentUser() async {}
}

/// Un `StorageService` en memoria, con un token de prueba. No toca
/// `shared_preferences` ni el llavero.
class AlmacenDePrueba extends StorageService {
  AlmacenDePrueba({this.token = 'token-de-prueba'});

  String? token;
  int setupsGuardados = 0;

  @override
  Future<String?> get savedToken async => token;

  @override
  Future<void> saveToken(String token) async => this.token = token;

  @override
  Future<void> saveCode(String code) async {}

  @override
  Future<void> saveSetup({
    required String code,
    required int careerId,
    int? especialidadPrincipal,
    required List<int> especialidadesInteres,
    required bool setupComplete,
  }) async => setupsGuardados++;

  @override
  Future<void> clearSession() async => token = null;
}
