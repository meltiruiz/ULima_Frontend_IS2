// lib/services/auth_service.dart
// Autenticación real contra el backend + persistencia segura del JWT.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../configs/google_auth_config.dart';
import '../models/user_model.dart';
import 'api_client.dart';
import 'courses_service.dart';
import 'evaluations_service.dart';
import 'malla_service.dart';
import 'official_grades_service.dart';
import 'storage_service.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find();
  static const String invalidCredentialsMessage =
      'Código o contraseña incorrectos.';

  /// Mapea el código de error del backend (HU01) al mensaje que ve el usuario
  /// en el login. Puro y testeable: `USER_NOT_FOUND`/`INVALID_PASSWORD` ocultan
  /// cuál falló (anti-enumeración de cuentas); `NOT_ENROLLED` es específico; y
  /// cualquier otro código propaga el mensaje del backend.
  static String loginErrorMessage(String code, String backendMessage) {
    if (code == 'USER_NOT_FOUND' || code == 'INVALID_PASSWORD') {
      return invalidCredentialsMessage;
    }
    if (code == 'NOT_ENROLLED') {
      return 'No tienes una matrícula activa.';
    }
    return backendMessage;
  }

  final ApiClient _api = ApiClient();
  final Rx<UserModel?> _currentUser = Rx<UserModel?>(null);
  final RxList<Map<String, dynamic>> _carreras = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _especialidades =
      <Map<String, dynamic>>[].obs;
  final RxBool _loading = false.obs;

  // Instancia única de Google Sign-In.
  // - Web: requiere `clientId` (el client web) para el botón oficial (GIS).
  // - Android/iOS: requiere `serverClientId` (el MISMO client web) para que
  //   `account.authentication.idToken` no sea null. Ese `idToken` se emite con
  //   `aud = client web`, que es el que el backend verifica en `/auth/google`.
  //   Sin `serverClientId`, en Android el idToken llega null y el login falla.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? googleWebClientId : null,
    serverClientId: kIsWeb ? null : googleWebClientId,
    scopes: const ['email'],
  );

  /// Expuesta para que la UI de web pueda renderizar el botón oficial y
  /// escuchar `onCurrentUserChanged`.
  GoogleSignIn get googleSignIn => _googleSignIn;

  UserModel? get currentUser => _currentUser.value;
  Rx<UserModel?> get currentUserRx => _currentUser;
  bool get isLoggedIn => _currentUser.value != null;
  bool get isLoading => _loading.value;

  /// Secciones donde el docente es Profesor titular (`section.teacher_id`), no
  /// JP. Se llena al iniciar sesión (docente) desde `/official-grades/teacher/
  /// sections`, que devuelve solo secciones de titular. Es la fuente de
  /// `canGrade` (pestaña Calificar) y del gating de "alertar" por sección.
  final Set<int> _profesorSectionIds = <int>{};

  /// True si el docente es Profesor titular de al menos una sección → puede
  /// calificar. Un JP puro (solo `jp_id`) queda en false.
  bool get canGrade => _profesorSectionIds.isNotEmpty;

  /// True si el docente es el Profesor titular de esa sección (no el JP). Se usa
  /// para habilitar/ocultar las acciones de "alertar" del modal de la sección.
  bool isProfesorOfSection(int sectionId) =>
      _profesorSectionIds.contains(sectionId);

  StorageService get _storage => StorageService.to;

  List<Map<String, dynamic>> get carreras => _carreras;
  List<Map<String, dynamic>> get especialidades => _especialidades;

  String getCareerName(int? id) {
    if (id == null) return '';
    final match = _carreras.firstWhereOrNull((c) => c['id'] == id);
    return match != null ? match['name']?.toString() ?? '' : '';
  }

  String getEspecialidadName(int id) {
    final match = _especialidades.firstWhereOrNull((e) => e['id'] == id);
    return match != null ? match['name']?.toString() ?? '' : '';
  }

  /// Recarga el usuario actual desde `/auth/me` SIN cerrar la sesión si falla.
  ///
  /// Existe aparte de [tryRestoreSession] a propósito: ese hace
  /// `clearSession()` ante cualquier excepción, así que usarlo como refresco
  /// significaría que un hipo de red al volver de importar echa al alumno de la
  /// app. Acá un fallo simplemente deja el usuario como estaba.
  ///
  /// Reasignar `_currentUser.value` dispara los `ever()` que ambos controllers
  /// de malla instalan sobre `currentUserRx`, así que el nivel y la carrera se
  /// propagan solos.
  Future<void> refreshCurrentUser() async {
    final token = await _storage.savedToken;
    if (token == null || token.isEmpty) return;
    try {
      final response = await _api.getJson('/auth/me', token: token);
      _currentUser.value = UserModel.fromJson(_mapFrom(response['user']));
    } catch (_) {
      // A propósito sin clearSession: un refresco fallido no cierra sesión.
    }
  }

  Future<bool> tryRestoreSession() async {
    final token = await _storage.savedToken;
    if (token == null || token.isEmpty) return false;

    try {
      final response = await _api.getJson('/auth/me', token: token);
      final user = UserModel.fromJson(_mapFrom(response['user']));
      // Los catálogos de carrera/especialidad son de alumno (endpoints con
      // requireRole de alumno): un docente recibiría 403.
      if (!user.isTeacher) {
        await _loadCatalogs(token: token, careerId: user.careerId);
      } else {
        await _loadProfesorSections();
      }
      _currentUser.value = user;
      await _storage.saveCode(user.code);
      return true;
    } on ApiException {
      await _storage.clearSession();
      return false;
    } catch (_) {
      await _storage.clearSession();
      return false;
    }
  }

  Future<String?> login({
    required String code,
    required String password,
  }) async {
    _loading.value = true;
    try {
      final response = await _api.postJson(
        '/auth/login',
        body: {'code': code.trim(), 'password': password},
      );

      final token = response['token']?.toString();
      if (token == null || token.isEmpty) {
        return 'No se recibió token de sesión.';
      }

      final user = UserModel.fromJson(_mapFrom(response['user']));
      await _storage.saveToken(token);
      await _storage.saveCode(user.code);
      // Los catálogos son de alumno; un docente (HU18) los omite (evita 403).
      if (!user.isTeacher) {
        await _loadCatalogs(token: token, careerId: user.careerId);
      } else {
        await _loadProfesorSections();
      }
      _currentUser.value = user;
      return null;
    } on ApiException catch (e) {
      return loginErrorMessage(e.code, e.message);
    } finally {
      _loading.value = false;
    }
  }

  /// Login con Google en móvil/escritorio (flujo interactivo `signIn()`).
  /// En web NO se usa: ahí el botón oficial (`renderButton`) dispara el flujo y
  /// la cuenta llega por `googleSignIn.onCurrentUserChanged` (ver LoginController).
  Future<String?> loginWithGoogle() async {
    _loading.value = true;
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return null; // El usuario canceló
      }
      return await finishGoogleLogin(account);
    } catch (_) {
      return 'No se pudo iniciar sesión con Google.';
    } finally {
      _loading.value = false;
    }
  }

  /// Completa el login con una cuenta de Google (web y móvil): obtiene el
  /// idToken, lo canjea en el backend (`/auth/google`) y guarda la sesión.
  Future<String?> finishGoogleLogin(GoogleSignInAccount account) async {
    try {
      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        await _resetGoogleAccount();
        return 'No se obtuvo información de Google.';
      }

      final response = await _api.postJson(
        '/auth/google',
        body: {'idToken': idToken},
      );

      final token = response['token']?.toString();
      if (token == null || token.isEmpty) {
        await _resetGoogleAccount();
        return 'No se recibió token de sesión.';
      }

      final user = UserModel.fromJson(_mapFrom(response['user']));
      await _storage.saveToken(token);
      await _storage.saveCode(user.code);
      // Los catálogos son endpoints exclusivos de alumno. Un docente que entra
      // con Google debe omitirlos, igual que en el login con código/contraseña.
      if (!user.isTeacher) {
        await _loadCatalogs(token: token, careerId: user.careerId);
      } else {
        await _loadProfesorSections();
      }
      _currentUser.value = user;
      return null;
    } on ApiException catch (e) {
      await _resetGoogleAccount();
      if (e.code == 'INVALID_DOMAIN') {
        return 'Debes usar tu correo @aloe.ulima.edu.pe o @ulima.edu.pe.';
      }
      if (e.code == 'USER_NOT_FOUND') {
        return 'Tu correo no está registrado en el sistema.';
      }
      return e.message;
    } catch (_) {
      await _resetGoogleAccount();
      return 'No se pudo iniciar sesión con Google.';
    }
  }

  /// Limpia la cuenta de Google en caché tras un intento fallido (p. ej. una
  /// cuenta no-ULima rechazada por el backend). Sin esto, `signIn()` reusaría
  /// silenciosamente la misma cuenta y el selector no volvería a aparecer.
  /// En un login exitoso NO se llama, así que la sesión de Google sí se mantiene.
  Future<void> _resetGoogleAccount() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  Future<void> completeSetup({
    required int careerId,
    int? especialidadPrincipal,
    required List<int> especialidadesInteres,
  }) async {
    final user = _currentUser.value;
    if (user == null) return;

    final token = await _requiredToken();
    final response = await _api.putJson(
      '/academic-profile/me/specialties',
      token: token,
      body: {
        'primarySpecialtyId': especialidadPrincipal,
        // La principal nunca viaja también como interés (409 DUPLICATE_PRIMARY).
        'interestSpecialtyIds': especialidadesInteres
            .where((id) => id != especialidadPrincipal)
            .toList(),
      },
    );

    final savedSpecialties = _listFrom(response, 'specialties');
    final savedPrincipal = savedSpecialties
        .where((s) => s['selectionType']?.toString() == 'primary')
        .map((s) => _parseInt(s['specialtyId']))
        .whereType<int>()
        .firstOrNull;
    final savedInterest = savedSpecialties
        .where((s) => s['selectionType']?.toString() == 'interest')
        .map((s) => _parseInt(s['specialtyId']))
        .whereType<int>()
        .toList();

    user.careerId = careerId;
    user.especialidadPrincipal = savedPrincipal;
    user.especialidadesInteres = savedInterest;
    user.setupComplete = response['setupComplete'] as bool? ?? true;
    _currentUser.refresh();

    await _storage.saveSetup(
      code: user.code,
      careerId: careerId,
      especialidadPrincipal: user.especialidadPrincipal,
      especialidadesInteres: user.especialidadesInteres,
      setupComplete: user.setupComplete,
    );
  }

  Future<void> logout() async {
    final token = await _storage.savedToken;
    if (token != null && token.isNotEmpty) {
      try {
        await _api.postJson(
          '/auth/logout',
          token: token,
          body: const <String, dynamic>{},
        );
      } catch (_) {
        // Logout es stateless; si el servidor no responde, limpiamos local igual.
      }
    }
    // TT06: invalidar TODAS las cachés por-usuario para que otra cuenta en el
    // mismo dispositivo no vea datos del usuario anterior.
    MallaService.to.clear();
    CoursesService().clear();
    EvaluationSyllabusService().clear();
    _profesorSectionIds.clear();
    _currentUser.value = null;
    await _storage.clearSession();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  /// Carga las secciones donde el docente es Profesor titular (para `canGrade` e
  /// `isProfesorOfSection`). El endpoint `/official-grades/teacher/sections` solo
  /// devuelve secciones de titular, así que un JP recibe lista vacía.
  /// Degradación segura: ante cualquier fallo deja el set vacío y NO rompe el
  /// login (el docente no verá acciones de profesor hasta reintentar/reingresar).
  Future<void> _loadProfesorSections() async {
    try {
      final sections = await OfficialGradesService().fetchTeacherSections();
      _profesorSectionIds
        ..clear()
        ..addAll(sections.map((s) => s.sectionId));
    } catch (_) {
      _profesorSectionIds.clear();
    }
  }

  Future<void> _loadCatalogs({required String token, int? careerId}) async {
    final careersResponse = await _api.getJson(
      '/academic-profile/careers',
      token: token,
    );
    _carreras.assignAll(_listFrom(careersResponse, 'careers'));

    final specialtiesResponse = await _api.getJson(
      '/academic-profile/specialties',
      token: token,
      query: {'careerId': careerId?.toString()},
    );
    _especialidades.assignAll(_listFrom(specialtiesResponse, 'specialties'));
  }

  Future<String> _requiredToken() async {
    final token = await _storage.savedToken;
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa.');
    }
    return token;
  }

  Map<String, dynamic> _mapFrom(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _listFrom(
    Map<String, dynamic> response,
    String key,
  ) {
    final raw = response[key];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
