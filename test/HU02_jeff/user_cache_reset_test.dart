import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/courses_service.dart';
import 'package:ulima_plus/services/evaluations_service.dart';
import 'package:ulima_plus/services/malla_service.dart';
import 'package:ulima_plus/services/storage_service.dart';
import 'package:ulima_plus/services/api_client.dart';

class _FakeAuthService extends AuthService {
  UserModel? user;

  @override
  UserModel? get currentUser => user;
}

class _FakeStorageService extends StorageService {
  @override
  Future<String?> get savedToken async => null;

  @override
  Future<void> clearSession() async {}
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(configuredBaseUrl: 'http://test');

  int fetchCalls = 0;
  String? _cursoId;

  void serve(String cursoId) {
    _cursoId = cursoId;
    fetchCalls = 0;
  }

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    String? token,
    Map<String, String?> query = const {},
    bool suppressSessionExpiry = false,
  }) async {
    fetchCalls++;
    final id = _cursoId ?? 'default';
    return {
      'cursos': [
        {'id': id, 'silaboUrl': 'https://silabos.test/$id.pdf'},
      ],
      'syllabi': [
        {
          'cursoId': id,
          'cursoNombre': 'Curso $id',
          'evaluaciones': <Map<String, dynamic>>[],
        },
      ],
    };
  }
}

UserModel _user(String code) {
  return UserModel(
    code: code,
    firstName: 'Alumna',
    lastName: 'De Prueba',
    email: 'test@aloe.ulima.edu.pe',
    role: 'student',
    currentCycle: '2026-1',
    setupComplete: true,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAuthService auth;
  late _FakeApiClient fakeApi;

  setUp(() {
    Get.reset();
    auth = _FakeAuthService();
    fakeApi = _FakeApiClient();
    Get.put<AuthService>(auth);
    Get.put<StorageService>(_FakeStorageService());
    Get.put<MallaService>(MallaService());
    CoursesService.setTestInstance(CoursesService(apiClient: fakeApi));
    EvaluationSyllabusService.setTestInstance(
      EvaluationSyllabusService(apiClient: fakeApi),
    );
  });

  tearDown(() {
    Get.reset();
  });

  void serveCourse(String cursoId) {
    fakeApi.serve(cursoId);
  }

  test('CoursesService cachea por usuario y recarga al cambiar de cuenta',
      () async {
    auth.user = _user('111');
    serveCourse('curso-a');

    await CoursesService.instance.loadCoursesData();
    expect(CoursesService.instance.allCourses.single['id'], 'curso-a');

    auth.user = _user('222');
    serveCourse('curso-b');
    await CoursesService.instance.loadCoursesData();
    expect(CoursesService.instance.allCourses.single['id'], 'curso-b');
  });

  test(
      'EvaluationSyllabusService recarga al cambiar de cuenta y no conserva '
      'URLs de silabo del usuario anterior', () async {
    auth.user = _user('111');
    serveCourse('curso-a');

    await EvaluationSyllabusService.instance.loadEvaluationData();
    expect(EvaluationSyllabusService.instance.allSyllabuses.single.cursoId, 'curso-a');
    expect(EvaluationSyllabusService.instance.getSilaboUrl('curso-a'), isNotNull);

    auth.user = _user('222');
    serveCourse('curso-b');
    await EvaluationSyllabusService.instance.loadEvaluationData();
    expect(EvaluationSyllabusService.instance.allSyllabuses.single.cursoId, 'curso-b');
    expect(EvaluationSyllabusService.instance.getSilaboUrl('curso-b'), isNotNull);
    expect(EvaluationSyllabusService.instance.getSilaboUrl('curso-a'), isNull);
  });

  test('logout() invalida las cache de cursos, silabos y simulacion',
      () async {
    auth.user = _user('111');
    await CoursesService.instance.loadCoursesData();
    await EvaluationSyllabusService.instance.loadEvaluationData();
    MallaService.to.replaceSimulation({'curso-x': 'approved'});

    await AuthService.to.logout();

    expect(CoursesService.instance.isLoaded, isFalse);
    expect(CoursesService.instance.allCourses, isEmpty);
    expect(EvaluationSyllabusService.instance.isLoaded, isFalse);
    expect(EvaluationSyllabusService.instance.allSyllabuses, isEmpty);
    expect(EvaluationSyllabusService.instance.getSilaboUrl('curso-a'), isNull);
    expect(MallaService.to.simulation, isEmpty);
  });

  test('tras logout, el mismo usuario vuelve a pedir datos al re-loguear',
      () async {
    auth.user = _user('111');
    serveCourse('curso-a');

    await CoursesService.instance.loadCoursesData();

    await AuthService.to.logout();

    await CoursesService.instance.loadCoursesData();
    expect(CoursesService.instance.allCourses.single['id'], 'curso-a');
  });
}
