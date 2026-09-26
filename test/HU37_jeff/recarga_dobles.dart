// test/HU37_jeff/recarga_dobles.dart
//
// Dobles y datos de prueba compartidos por las pruebas de la recarga desde la
// ULima (specs/features/recarga-portal/recarga-portal.spec.md). Todo es
// inventado, porque el repo es público. La alumna es la 20230001, el segundo
// alumno es el 20230002 y los cursos salen del ejemplo del contrato.

import 'dart:async';

import 'package:get/get.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/auth_service.dart';

UserModel alumna({String code = '20230001'}) => UserModel(
  code: code,
  firstName: 'Alumna',
  lastName: 'De Prueba',
  email: 'test@aloe.ulima.edu.pe',
  role: 'student',
  currentCycle: '2026-2',
  setupComplete: true,
);

/// Un docente, que nunca usa la recarga.
UserModel docente() => UserModel(
  code: 'docente.test',
  firstName: 'Docente',
  lastName: 'De Prueba',
  email: 'docente.test@ulima.edu.pe',
  role: 'teacher',
  currentCycle: '2026-2',
  setupComplete: true,
);

class AuthFalso extends AuthService {
  AuthFalso(UserModel? user) : userRx = Rx<UserModel?>(user);

  final Rx<UserModel?> userRx;

  @override
  UserModel? get currentUser => userRx.value;

  @override
  Rx<UserModel?> get currentUserRx => userRx;

  @override
  Future<void> refreshCurrentUser() async {}
}

/// Registra a [user] como el usuario actual.
AuthFalso loguear(UserModel? user) {
  final auth = AuthFalso(user);
  Get.put<AuthService>(auth);
  return auth;
}

/// `ApiClient` falso con respuestas por método y ruta, sin la query.
///
/// Cada clave es, por ejemplo, `GET /grades/me/ulima`. Las respuestas salen
/// en orden y la última se repite. Un `Map` se devuelve, un `Completer` se
/// espera y cualquier otra cosa se lanza. Una ruta sin respuestas devuelve
/// un mapa vacío. Con [calcularPromedio], `POST /grades/me/calculate` suma
/// valor · peso / 100 como el backend.
class ApiRecargaFalsa extends ApiClient {
  ApiRecargaFalsa({this.calcularPromedio = false})
    : super(configuredBaseUrl: 'http://test');

  final bool calcularPromedio;
  final Map<String, List<Object>> _respuestas = <String, List<Object>>{};
  final Map<String, int> _usadas = <String, int>{};

  /// Cada llamada, como `POST /portal-sync/refresh`, en orden.
  final List<String> llamadas = <String>[];

  /// El cuerpo de cada POST, en orden, junto a su ruta.
  final List<(String, Map<String, dynamic>)> cuerpos =
      <(String, Map<String, dynamic>)>[];

  void responder(String clave, Object respuesta) =>
      _respuestas.putIfAbsent(clave, () => <Object>[]).add(respuesta);

  int veces(String clave) => llamadas.where((l) => l == clave).length;

  List<Map<String, dynamic>> cuerposDe(String ruta) =>
      cuerpos.where((c) => c.$1 == ruta).map((c) => c.$2).toList();

  Future<Map<String, dynamic>> _salida(String clave) async {
    llamadas.add(clave);
    final lista = _respuestas[clave];
    if (lista == null || lista.isEmpty) return <String, dynamic>{};
    final i = _usadas[clave] ?? 0;
    _usadas[clave] = i + 1;
    final r = lista[i < lista.length ? i : lista.length - 1];
    if (r is Completer<Map<String, dynamic>>) return r.future;
    if (r is Map<String, dynamic>) return r;
    throw r;
  }

  static String _ruta(String path) => path.split('?').first;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    String? token,
    Map<String, String?> query = const {},
    bool suppressSessionExpiry = false,
  }) => _salida('GET ${_ruta(path)}');

  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) {
    final ruta = _ruta(path);
    cuerpos.add((ruta, body));
    if (calcularPromedio && ruta == '/grades/me/calculate') {
      llamadas.add('POST $ruta');
      var promedio = 0.0;
      var suma = 0.0;
      for (final n in (body['notas'] as List).cast<Map>()) {
        final peso = (n['peso'] as num).toDouble();
        promedio += (n['valor'] as num).toDouble() * peso / 100;
        suma += peso;
      }
      return Future.value(<String, dynamic>{
        'promedio': promedio,
        'sumaPesos': suma,
      });
    }
    return _salida('POST $ruta');
  }

  @override
  Future<Map<String, dynamic>> deleteJson(String path, {String? token}) =>
      _salida('DELETE ${_ruta(path)}');
}

ApiException errorApi(int status, String code, {Object? details}) =>
    ApiException(
      statusCode: status,
      code: code,
      message: 'mensaje del backend que la app nunca muestra',
      details: details,
    );

// --- JSON inventado con la forma del contrato ------------------------------

Map<String, dynamic> evaluacionJson({
  String key = '07.13',
  String? group = 'EVC',
  String name = 'Examen escrito 1',
  Object? week = 3,
  Object weight = 15,
  Object? value = 14.5,
  String mark = 'graded',
  Object? assessmentId = 5011,
  String match = 'exact',
}) => <String, dynamic>{
  'key': key,
  'group': group,
  'name': name,
  'week': week,
  'weight': weight,
  'value': value,
  'mark': mark,
  'assessmentId': assessmentId,
  'match': match,
};

Map<String, dynamic> cursoJson({
  Object sectionId = 81,
  String courseCode = '690417',
  String courseName = 'TALLER DE PROTOTIPADO',
  String sectionCode = '812',
  Object? lastReadAt = '2025-09-22T15:42:10.000Z',
  List<Map<String, dynamic>>? assessments,
}) => <String, dynamic>{
  'sectionId': sectionId,
  'courseCode': courseCode,
  'courseName': courseName,
  'sectionCode': sectionCode,
  'lastReadAt': lastReadAt,
  'assessments':
      assessments ??
      <Map<String, dynamic>>[
        evaluacionJson(),
        evaluacionJson(
          key: '07.15',
          name: 'Exposición',
          week: 10,
          weight: 20,
          value: null,
          mark: 'pending',
          assessmentId: 5013,
          match: 'week_shift',
        ),
      ],
};

/// La vista del ejemplo del contrato. La hora de lectura por omisión es del
/// 22 de septiembre de 2025 a las 10:42 de Lima, que da un texto fijo sea
/// cual sea el día en que corre la prueba.
Map<String, dynamic> vistaJson({
  Object? lastReadAt = '2025-09-22T15:42:10.000Z',
  List<Map<String, dynamic>>? courses,
}) => <String, dynamic>{
  'lastReadAt': lastReadAt,
  'courses': courses ?? <Map<String, dynamic>>[cursoJson()],
};

Map<String, dynamic> resultadoJson({
  Map<String, dynamic>? view,
  List<Map<String, dynamic>>? courses,
}) => <String, dynamic>{
  'readAt': '2025-09-22T15:42:10.000Z',
  'attendance': {'updated': 1, 'skipped': 0, 'failed': 0, 'unavailable': 0},
  'grades': {'read': 1, 'failed': 0, 'unavailable': 0, 'withValue': 1},
  'courses':
      courses ??
      <Map<String, dynamic>>[
        {
          'sectionId': 81,
          'courseCode': '690417',
          'sectionCode': '812',
          'attendance': 'updated',
          'grades': 'read',
        },
      ],
  'view': view ?? vistaJson(),
  'warnings': <dynamic>[],
};

/// El texto de la hora de lectura por omisión de [vistaJson].
const String lecturaDePrueba = 'el 22 de septiembre de 2025 a las 10:42';
