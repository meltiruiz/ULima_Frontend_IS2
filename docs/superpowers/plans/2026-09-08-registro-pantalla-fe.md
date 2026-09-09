# Pantalla de Registro (HU33) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Que un alumno que no existe en la base pueda crear su cuenta de ULima++ desde la app, autenticándose contra miUlima, y entrar con el ciclo ya cargado.

**Architecture:** Una sola ruta `/registro` con cinco estados en un `GetxController`, igual que `PortalSyncPage` resuelve tres. La red vive en un `RegistroService` con `ApiClient` inyectable por constructor; el controller recibe además dos costuras (`adoptarSesion` e `iniciarSesion`) para poder probarse sin tocar `AuthService`, que no es construible en tests. La UI se compone entera con el kit público de `password_reset_ui.dart`.

**Tech Stack:** Flutter, Dart, GetX, `flutter_test` (sin mockito: los dobles del repo son clases privadas con `extends` + `@override`).

**Spec:** `specs/features/registro/registro.spec.md`

## Global Constraints

- Rama de trabajo: `feat/registro-fe`, en el worktree `/Users/jjjangelosss/ULIMA++/.worktrees/registro-fe`. Nunca `cd` a `ULima_Frontend_IS2`.
- Commits firmados como `Jeffangeloss <178797184+jeffangeloss@users.noreply.github.com>`. **Sin trailer `Co-Authored-By`**: la autoría es del usuario.
- El repo es **PÚBLICO**. Prohibido escribir códigos de alumno reales —los del equipo no se enumeran acá; están en la memoria del proyecto—, hosts de base de datos o credenciales. En tests usar `20230001` y nombres sintéticos.
- Las credenciales de miUlima no se persisten, no se loguean y no entran en ningún `Rx`. Solo viven en `TextEditingController` (RS-FE-6).
- Nada posterior a un `201` puede convertirse en un mensaje de fallo (BR-REG-F-10).
- Un plazo vencido **no** significa que el registro falló (BR-REG-F-08).
- `flutter analyze` sin warnings nuevos y `flutter test` en verde antes de cada commit.
- Tests en `test/HU33_jeff/`, con `group('UNITARIA · <sujeto> (HU33)')` y nombres de caso que empiezan por `caso N:`, siguiendo `test/HU01_jeff/login_error_mapping_test.dart`.
- No mover carpetas ni refactorizar nada fuera de los archivos listados en cada tarea.

---

## File Structure

| Archivo | Responsabilidad |
| --- | --- |
| `lib/services/api_client.dart` *(modificar)* | Eximir `/auth/register` del tratamiento genérico del 401. Es el prerequisito de todo lo demás. |
| `lib/models/registro_models.dart` *(crear)* | `RegistroResult` (parseo del 201 plano) y `RegistroFailure` (mensaje ya redactado + código interno). |
| `lib/services/registro_service.dart` *(crear)* | La única frontera HTTP del registro: arma el body, pone el plazo, traduce errores. |
| `lib/services/auth_service.dart` *(modificar)* | `adoptarSesion`: establecer la sesión con lo que trajo el registro, sin repetir el login. |
| `lib/pages/registro/registro_controller.dart` *(crear)* | Validadores puros + la máquina de cinco estados. |
| `lib/pages/registro/registro_page.dart` *(crear)* | Los cinco estados dibujados con el kit de `password_reset_ui.dart`. |
| `lib/pages/registro/registro_binding.dart` *(crear)* | Binding por ruta con `lazyPut`, para que `onClose` borre las credenciales. |
| `lib/main.dart` *(modificar)* | `GetPage('/registro')`. |
| `lib/pages/login/login_page.dart` *(modificar)* | Enlace fijo «Crea tu cuenta». |

---

### Task 1: Eximir `/auth/register` del 401 de sesión caducada

Hoy `ApiClient._send` trata **cualquier** 401 que no venga de `/auth/login` como caducidad: borra la sesión, navega al login con `offAllToLogin()` y muestra el snackbar «Sesión expirada». El fallo más común del registro —contraseña de miUlima mal tipeada o passcode vencido— responde `401 PORTAL_AUTH_FAILED`. Sin esta tarea, esa persona vería su pantalla destruida y leería que caducó una sesión que nunca tuvo.

La condición se extrae a una función pura y con nombre, para que la regla se pueda probar. Probar `_send` directamente exigiría un servidor HTTP; probar el predicado no exige nada.

**Files:**
- Modify: `lib/services/api_client.dart` (la condición del 401, hoy en la línea 98)
- Test: `test/HU33_jeff/api_client_401_test.dart`

**Interfaces:**
- Consumes: nada.
- Produces: `bool esRuta401Exenta(String path)` — función de nivel superior en `lib/services/api_client.dart`, exportada con el archivo.

- [ ] **Step 1: Escribir el test que falla**

Crear `test/HU33_jeff/api_client_401_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/services/api_client.dart';

/// Qué rutas quedan fuera del tratamiento genérico del 401 (HU33).
void main() {
  group('UNITARIA · esRuta401Exenta (HU33)', () {
    test('caso 1: /auth/register queda exento: su 401 es del portal, no de sesión', () {
      expect(esRuta401Exenta('/auth/register'), isTrue);
    });

    test('caso 2: /auth/login sigue exento, como antes', () {
      expect(esRuta401Exenta('/auth/login'), isTrue);
    });

    test('caso 3: una ruta autenticada NO queda exenta', () {
      expect(esRuta401Exenta('/auth/me'), isFalse);
      expect(esRuta401Exenta('/portal-sync/import'), isFalse);
      expect(esRuta401Exenta('/academic-profile/careers'), isFalse);
    });

    test('caso 4: /auth/logout no entra por acá; su excepción es la de navegar', () {
      expect(esRuta401Exenta('/auth/logout'), isFalse);
    });
  });
}
```

Los casos 3 y 4 son los que hacen que el test muerda: sin ellos, un `return true` constante pasaría.

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `flutter test test/HU33_jeff/api_client_401_test.dart`
Expected: FAIL en compilación, `Undefined name 'esRuta401Exenta'`.

- [ ] **Step 3: Implementar**

En `lib/services/api_client.dart`, agregar la función de nivel superior justo antes de `class ApiClient`:

```dart
/// Rutas cuyo 401 **no** significa que la sesión caducó.
///
/// `/auth/login` porque un login rechazado es un 401 normal. `/auth/register`
/// porque su fallo más común —miUlima rechaza la contraseña o el passcode—
/// también responde 401, y quien se está registrando no tiene ninguna sesión
/// que caducar: sin la exención se le borraría la sesión inexistente, se le
/// sacaría de la pantalla de registro con `offAllToLogin()` y leería
/// "Sesión expirada". Ver BR-REG-F-04 de `specs/features/registro`.
///
/// `/auth/logout` NO va acá: su 401 sí limpia la sesión (es lo que se pidió),
/// solo se salta la navegación. Esa excepción vive dentro del `if`.
bool esRuta401Exenta(String path) =>
    path.contains('/auth/login') || path.contains('/auth/register');
```

Y reemplazar la condición existente:

```dart
    if (resolved.statusCode == 401 && !path.contains('/auth/login')) {
```

por:

```dart
    if (resolved.statusCode == 401 && !esRuta401Exenta(path)) {
```

No tocar nada más del bloque: el `if (!path.contains('/auth/logout') && offAllToLogin())` de adentro se queda tal cual.

- [ ] **Step 4: Correr los tests**

Run: `flutter test test/HU33_jeff/api_client_401_test.dart`
Expected: PASS, 4 casos.

Run: `flutter analyze`
Expected: sin warnings nuevos.

- [ ] **Step 5: Commit**

```bash
git add lib/services/api_client.dart test/HU33_jeff/api_client_401_test.dart
git commit -m "fix(api): el 401 del registro no es una sesión caducada

ApiClient trataba cualquier 401 ajeno a /auth/login como expiración: borraba
la sesión, navegaba al login y avisaba 'Sesión expirada'. El fallo más común
de POST /auth/register es un 401 del portal, y quien se registra no tiene
sesión que caducar, así que se le destruía la pantalla y se le mentía.

La condición pasa a una función con nombre para poder probarla: probar _send
exigiría levantar un servidor, probar el predicado no exige nada."
```

---

### Task 2: Modelos y servicio del registro

La única frontera HTTP de la feature. `ApiClient` se recibe por constructor —como hace `PortalSyncService` y a diferencia de `AuthService`, que lo crea inline y por eso no se puede probar— y el traductor de errores se expone **público y estático**, para poder probarlo directo; el de portal-sync es privado y sus tests tienen que llegar a él dando un rodeo.

**Files:**
- Create: `lib/models/registro_models.dart`
- Create: `lib/services/registro_service.dart`
- Test: `test/HU33_jeff/registro_service_test.dart`

**Interfaces:**
- Consumes: `ApiClient`, `ApiException` de `lib/services/api_client.dart`; `PortalSyncSummary`, `PortalSyncWarning` de `lib/models/portal_sync_models.dart`; `UserModel` de `lib/models/user_model.dart`.
- Produces:
  - `class RegistroResult { final String token; final UserModel user; final PortalSyncSummary summary; final List<PortalSyncWarning> warnings; factory RegistroResult.fromJson(Map<String, dynamic>); }`
  - `class RegistroFailure implements Exception { const RegistroFailure(String message, {String? code}); final String message; final String? code; }`
  - `class RegistroService { RegistroService({ApiClient? apiClient}); static const Duration registroTimeout; Future<RegistroResult> registrar({required String code, required String portalPassword, required String passcode, required String password}); static String mensajeDeError(ApiException e); }`
  - Códigos internos de `RegistroFailure` que no vienen del backend: `TIEMPO_AGOTADO`, `SIN_TOKEN`, `SIN_CONEXION`.

- [ ] **Step 1: Escribir el test que falla**

Crear `test/HU33_jeff/registro_service_test.dart`:

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/models/registro_models.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/registro_service.dart';

/// Alta de cuenta contra miUlima (HU33), lado servicio.

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.respuesta, this.error, this.demora})
      : super(configuredBaseUrl: 'http://test');

  final Map<String, dynamic>? respuesta;
  final Object? error;
  final Duration? demora;
  Map<String, dynamic>? ultimoBody;
  String? ultimaRuta;

  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    ultimaRuta = path;
    ultimoBody = body;
    if (demora != null) await Future<void>.delayed(demora!);
    if (error != null) throw error!;
    return respuesta ?? <String, dynamic>{};
  }
}

Map<String, dynamic> _respuestaValida() => {
      'token': 'jwt-de-prueba',
      'tokenType': 'Bearer',
      'expiresIn': 86400,
      'user': {
        'id': 1,
        'studentId': 1,
        'code': '20230001',
        'fullName': 'GARCIA LOPEZ MARIA',
        'institutionalEmail': '20230001@aloe.ulima.edu.pe',
        'role': 'student',
        'career_id': 1,
        'setupComplete': false,
      },
      'summary': {'enrollmentsUpserted': 5, 'sessionsUpserted': 12, 'progressUpserted': 40},
      'warnings': [
        {'code': 'SYLLABUS_UNAVAILABLE', 'block': 'silabo', 'message': 'Los sílabos no respondieron.'},
      ],
    };

void main() {
  group('UNITARIA · RegistroService.registrar (HU33)', () {
    test('caso 1: manda los cuatro campos a /auth/register y nada más', () async {
      final api = _FakeApiClient(respuesta: _respuestaValida());
      await RegistroService(apiClient: api).registrar(
        code: '20230001',
        portalPassword: 'clave-portal',
        passcode: '123456',
        password: 'micontrasena',
      );

      expect(api.ultimaRuta, equals('/auth/register'));
      expect(
        api.ultimoBody!.keys.toSet(),
        equals({'code', 'portalPassword', 'passcode', 'password'}),
      );
    });

    test('caso 2: un 201 con warnings es éxito, no fallo', () async {
      final api = _FakeApiClient(respuesta: _respuestaValida());
      final r = await RegistroService(apiClient: api).registrar(
        code: '20230001', portalPassword: 'x', passcode: '123456', password: 'micontrasena',
      );

      expect(r.token, equals('jwt-de-prueba'));
      expect(r.user.code, equals('20230001'));
      expect(r.summary.cursos, equals(5));
      expect(r.warnings, hasLength(1));
      expect(r.warnings.first.message, equals('Los sílabos no respondieron.'));
    });

    test('caso 3: el plazo vencido NO dice que falló: dice que no se sabe', () async {
      final api = _FakeApiClient(
        respuesta: _respuestaValida(),
        demora: RegistroService.registroTimeout + const Duration(seconds: 1),
      );
      final e = await RegistroService(apiClient: api)
          .registrar(code: '20230001', portalPassword: 'x', passcode: '123456', password: 'micontrasena')
          .then<Object?>((_) => null)
          .catchError((Object err) => err);

      expect(e, isA<RegistroFailure>());
      expect((e! as RegistroFailure).code, equals('TIEMPO_AGOTADO'));
      expect((e as RegistroFailure).message, isNot(contains('no se pudo crear')));
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('caso 4: un 201 sin token deja la cuenta creada pero sin sesión', () async {
      final sinToken = _respuestaValida()..remove('token');
      final api = _FakeApiClient(respuesta: sinToken);
      final e = await RegistroService(apiClient: api)
          .registrar(code: '20230001', portalPassword: 'x', passcode: '123456', password: 'micontrasena')
          .then<Object?>((_) => null)
          .catchError((Object err) => err);

      expect(e, isA<RegistroFailure>());
      expect((e! as RegistroFailure).code, equals('SIN_TOKEN'));
    });

    test('caso 5: un fallo de red crudo no se disfraza de error del backend', () async {
      final api = _FakeApiClient(error: const SocketExceptionFalsa());
      final e = await RegistroService(apiClient: api)
          .registrar(code: '20230001', portalPassword: 'x', passcode: '123456', password: 'micontrasena')
          .then<Object?>((_) => null)
          .catchError((Object err) => err);

      expect((e! as RegistroFailure).code, equals('SIN_CONEXION'));
    });

    test('caso 6: un ApiException conserva su código para que la pantalla decida', () async {
      final api = _FakeApiClient(
        error: ApiException(statusCode: 409, code: 'USER_ALREADY_EXISTS', message: 'x'),
      );
      final e = await RegistroService(apiClient: api)
          .registrar(code: '20230001', portalPassword: 'x', passcode: '123456', password: 'micontrasena')
          .then<Object?>((_) => null)
          .catchError((Object err) => err);

      expect((e! as RegistroFailure).code, equals('USER_ALREADY_EXISTS'));
    });
  });

  group('UNITARIA · RegistroService.mensajeDeError (HU33)', () {
    String mensaje(String code, [String backend = '']) =>
        RegistroService.mensajeDeError(
          ApiException(statusCode: 400, code: code, message: backend),
        );

    test('caso 1: el 401 del portal nombra las DOS causas posibles', () {
      final m = mensaje('PORTAL_AUTH_FAILED');
      expect(m, contains('contraseña'));
      expect(m, contains('authenticator'));
    });

    test('caso 2: cada código del contrato tiene su propio mensaje', () {
      final codigos = [
        'USER_ALREADY_EXISTS', 'PORTAL_AUTH_FAILED', 'PORTAL_SESSION_INVALID',
        'NOT_ENROLLED', 'PORTAL_IDENTITY_UNVERIFIABLE', 'PORTAL_TIMEOUT',
        'PORTAL_UNAVAILABLE', 'REGISTRATION_UNAVAILABLE',
      ];
      final mensajes = codigos.map((c) => mensaje(c)).toList();
      expect(mensajes.toSet(), hasLength(codigos.length),
          reason: 'dos códigos distintos no pueden compartir mensaje');
      for (final m in mensajes) {
        expect(m, isNotEmpty);
      }
    });

    test('caso 3: los mensajes en inglés del backend se traducen, no se muestran', () {
      expect(mensaje('INVALID_REQUEST_BODY', 'Invalid request body'),
          isNot(contains('Invalid')));
      expect(mensaje('INVALID_JSON_BODY', 'Invalid JSON body'),
          isNot(contains('Invalid')));
      expect(mensaje('INTERNAL_SERVER_ERROR', 'Unexpected server error'),
          isNot(contains('Unexpected')));
    });

    test('caso 4: los DOS códigos de 500 se contemplan', () {
      expect(mensaje('INTERNAL_ERROR', 'Error interno del servidor.'),
          equals(mensaje('INTERNAL_SERVER_ERROR', 'Unexpected server error')));
    });

    test('caso 5: el 429 usa el texto del backend, que trae el tiempo de espera', () {
      expect(mensaje('RATE_LIMITED', 'Intenta de nuevo en 42 minuto(s).'),
          equals('Intenta de nuevo en 42 minuto(s).'));
    });

    test('caso 6: un código desconocido con mensaje vacío no deja la pantalla muda', () {
      expect(mensaje('LO_QUE_SEA'), isNotEmpty);
    });
  });
}

/// Un fallo de red cualquiera: `ApiClient` los propaga sin envolver.
class SocketExceptionFalsa implements Exception {
  const SocketExceptionFalsa();
}
```

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `flutter test test/HU33_jeff/registro_service_test.dart`
Expected: FAIL en compilación, `Target of URI doesn't exist: 'package:ulima_plus/models/registro_models.dart'`.

- [ ] **Step 3: Escribir los modelos**

Crear `lib/models/registro_models.dart`:

```dart
/// Modelos del alta de cuenta contra miUlima (HU33).
///
/// `POST /auth/register` devuelve un cuerpo **plano**: no tiene los `period` ni
/// `identity` anidados de `POST /portal-sync/import`, así que `PortalSyncResult`
/// no sirve acá. `summary` y `warnings` sí son idénticos y se reutilizan.
library;

import 'portal_sync_models.dart';
import 'user_model.dart';

/// Lo que devuelve un registro exitoso.
class RegistroResult {
  const RegistroResult({
    required this.token,
    required this.user,
    required this.summary,
    required this.warnings,
  });

  final String token;

  /// El usuario tal como quedó en la base. Su `code` es el que certificó el
  /// portal, que puede no ser el que la persona tecleó (BR-REG-F-06).
  final UserModel user;

  final PortalSyncSummary summary;

  /// Un registro exitoso puede traerlos: sílabos caídos, panel de delegados
  /// fuera de servicio, `CAREER_MISMATCH`. No son errores (BR-REG-F-07).
  final List<PortalSyncWarning> warnings;

  factory RegistroResult.fromJson(Map<String, dynamic> json) {
    final usuario = json['user'];
    final resumen = json['summary'];
    final avisos = json['warnings'];
    return RegistroResult(
      token: json['token']?.toString() ?? '',
      user: UserModel.fromJson(
        usuario is Map ? Map<String, dynamic>.from(usuario) : <String, dynamic>{},
      ),
      summary: resumen is Map<String, dynamic>
          ? PortalSyncSummary.fromJson(resumen)
          : const PortalSyncSummary(
              coursesCreated: 0,
              sectionsCreated: 0,
              sectionsUpdated: 0,
              sessionsUpserted: 0,
              enrollmentsUpserted: 0,
              enrollmentsWithdrawn: 0,
              progressUpserted: 0,
              syllabiUpserted: 0,
            ),
      warnings: avisos is List
          ? avisos
              .whereType<Map<String, dynamic>>()
              .map(PortalSyncWarning.fromJson)
              .toList()
          : const <PortalSyncWarning>[],
    );
  }
}

/// Fallo del registro con un mensaje ya listo para mostrar.
///
/// `code` es el del backend cuando el fallo vino de él, o uno interno
/// (`TIEMPO_AGOTADO`, `SIN_TOKEN`, `SIN_CONEXION`) cuando lo produjo el
/// cliente. La pantalla decide a qué paso volver mirando ese código.
class RegistroFailure implements Exception {
  const RegistroFailure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'RegistroFailure($code): $message';
}
```

- [ ] **Step 4: Escribir el servicio**

Crear `lib/services/registro_service.dart`:

```dart
import 'dart:async';

import '../models/registro_models.dart';
import 'api_client.dart';

/// Alta de cuenta en ULima++ para quien todavía no existe en la base.
///
/// La persona escribe su código, la contraseña que quiere para ULima++, su
/// contraseña de miUlima y el código del authenticator. El BACKEND entra al
/// portal, comprueba que sea alumno matriculado, crea la cuenta e importa el
/// ciclo, todo en una transacción.
///
/// **Las credenciales de miUlima no se guardan en ningún lado.** Llegan por
/// parámetro, viajan en el cuerpo y se descartan. No entran en un `Rx`, no van
/// a `shared_preferences`, no se imprimen.
class RegistroService {
  RegistroService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  /// `ApiClient` no impone timeout (`_send` llama a `request.send()` sin
  /// `.timeout()`), así que sin esto la pantalla quedaría colgada para siempre.
  ///
  /// Son 120 s y no los 90 de la importación porque el registro hace todo lo
  /// que hace ella —incluido el login contra el portal— y además crea la
  /// cuenta. Quedarse corto es peor que quedarse largo: el servidor puede
  /// confirmar la transacción mientras el cliente ya dejó de esperar.
  static const Duration registroTimeout = Duration(seconds: 120);

  /// Registra y devuelve la sesión, o lanza [RegistroFailure] con un mensaje
  /// listo para mostrar. Nunca lanza `ApiException` cruda.
  Future<RegistroResult> registrar({
    required String code,
    required String portalPassword,
    required String passcode,
    required String password,
  }) async {
    Map<String, dynamic> res;
    try {
      res = await _api.postJson(
        '/auth/register',
        body: {
          'code': code,
          'portalPassword': portalPassword,
          'passcode': passcode,
          'password': password,
        },
      ).timeout(registroTimeout);
    } on ApiException catch (e) {
      throw RegistroFailure(mensajeDeError(e), code: e.code);
    } on TimeoutException {
      // NO se afirma que falló: el servidor pudo haber confirmado la
      // transacción mientras dejábamos de esperar. Ver BR-REG-F-08.
      throw const RegistroFailure(
        'No pudimos confirmar si tu cuenta se creó.',
        code: 'TIEMPO_AGOTADO',
      );
    } catch (_) {
      // `ApiClient` propaga los fallos de red sin envolver. A diferencia del
      // plazo vencido, acá lo habitual es que la petición ni haya llegado.
      throw const RegistroFailure(
        'No hay conexión. Revisa tu internet e inténtalo de nuevo.',
        code: 'SIN_CONEXION',
      );
    }

    // A partir de acá el 201 ya llegó: la cuenta EXISTE. Nada de lo que pase
    // ahora puede reportarse como "no se pudo crear" (BR-REG-F-10).
    try {
      final r = RegistroResult.fromJson(res);
      if (r.token.isEmpty) {
        throw const RegistroFailure(
          'Tu cuenta se creó, pero no recibimos la sesión.',
          code: 'SIN_TOKEN',
        );
      }
      return r;
    } on RegistroFailure {
      rethrow;
    } catch (_) {
      // `UserModel.fromJson` hace casts duros sobre `role` y `setupComplete`.
      throw const RegistroFailure(
        'Tu cuenta se creó, pero no pudimos leer la respuesta.',
        code: 'SIN_TOKEN',
      );
    }
  }

  /// Traduce el código del backend a algo que la persona entienda.
  ///
  /// Pública y estática a propósito, para poder probarla directo: la
  /// equivalente de portal-sync es privada y sus tests tienen que ejercerla
  /// dando un rodeo por `import()`.
  static String mensajeDeError(ApiException e) {
    switch (e.code) {
      case 'USER_ALREADY_EXISTS':
        return 'Ya existe una cuenta con ese código. Inicia sesión o recupera '
            'tu contraseña.';
      case 'PORTAL_AUTH_FAILED':
        // Nombra las dos causas porque el backend no las distingue: aplastarlo
        // a "contraseña mala" manda a cambiar la contraseña universitaria sin
        // motivo, cuando lo más probable es que el código haya vencido.
        return 'miUlima rechazó los datos. Revisa tu contraseña del portal y '
            'que el código del authenticator siga vigente.';
      case 'PORTAL_SESSION_INVALID':
        return 'La sesión de miUlima se cortó mientras cargábamos. Inténtalo de nuevo.';
      case 'NOT_ENROLLED':
        return 'miUlima no reporta matrícula en el ciclo actual, así que '
            'todavía no podemos crear tu cuenta.';
      case 'PORTAL_IDENTITY_UNVERIFIABLE':
        return 'No pudimos leer tu matrícula en miUlima.';
      case 'PORTAL_TIMEOUT':
        return 'miUlima tardó demasiado en responder. Inténtalo más tarde.';
      case 'PORTAL_UNAVAILABLE':
        return 'miUlima no está respondiendo. Inténtalo más tarde.';
      case 'REGISTRATION_UNAVAILABLE':
        return 'El registro no está disponible por ahora.';
      case 'RATE_LIMITED':
        // Se muestra el texto del backend y NO se lee `details`: detrás de este
        // código hay dos limitadores y la clave cambia entre ellos
        // (`retryAfterMinutes` vs `retryAfterSeconds`).
        return e.message.isNotEmpty
            ? e.message
            : 'Demasiados intentos. Espera un rato antes de volver a intentar.';
      case 'INVALID_REQUEST_BODY':
      case 'INVALID_JSON_BODY':
        // Los dos traen su mensaje en inglés.
        return 'Revisa tus datos: el código debe tener entre 6 y 10 dígitos.';
      case 'INTERNAL_ERROR':
      case 'INTERNAL_SERVER_ERROR':
        // Son dos códigos distintos porque `register` es el único método del
        // módulo sin traductor de errores de base de datos.
        return 'Algo falló de nuestro lado. Inténtalo de nuevo.';
      default:
        return e.message.isNotEmpty
            ? e.message
            : 'No pudimos crear tu cuenta. Inténtalo de nuevo.';
    }
  }
}
```

- [ ] **Step 5: Correr los tests**

Run: `flutter test test/HU33_jeff/registro_service_test.dart`
Expected: PASS, 12 casos. El caso 3 tarda ~2 minutos porque espera el plazo real.

Run: `flutter analyze`
Expected: sin warnings nuevos.

- [ ] **Step 6: Commit**

```bash
git add lib/models/registro_models.dart lib/services/registro_service.dart test/HU33_jeff/registro_service_test.dart
git commit -m "feat(registro): servicio y modelos del alta contra miUlima

La respuesta de POST /auth/register es plana: no tiene los period ni identity
anidados de portal-sync/import, así que PortalSyncResult no sirve. Summary y
warnings sí se reutilizan tal cual.

Dos decisiones que se apartan de portal-sync a propósito:

- El ApiClient entra por constructor, para que el servicio se pueda probar.
- El traductor de errores es público y estático. El de portal-sync es privado
  y sus tests tienen que ejercerlo dando un rodeo por import().

El plazo vencido no se reporta como fallo: el servidor pudo confirmar la
transacción mientras el cliente dejaba de esperar, y decir 'no se pudo crear'
mandaría a la persona a reintentar contra un 409."
```

---

### Task 3: `AuthService.adoptarSesion`

Establece la sesión con lo que ya trajo el registro, sin repetir el login contra el portal.

No lleva test propio: `AuthService` no se puede construir en un test —sus inicializadores de campo levantan un `ApiClient` y un `GoogleSignIn` reales— y `_loadCatalogs` es privado. Es la misma situación del resto del servicio, cuyo único test llama a un método estático sin instanciar nada. Lo que sí se prueba es la costura por la que el controller lo invoca, en la Task 4.

**Files:**
- Modify: `lib/services/auth_service.dart` (agregar el método después de `replaceToken`)

**Interfaces:**
- Consumes: `UserModel`.
- Produces: `Future<void> adoptarSesion({required String token, required UserModel user})` en `AuthService`. **Puede lanzar** si el almacén seguro falla; el controller trata ese caso como cuenta creada sin sesión.

- [ ] **Step 1: Implementar**

En `lib/services/auth_service.dart`, justo después del método `replaceToken`:

```dart
  /// Establece la sesión con lo que devolvió `POST /auth/register`.
  ///
  /// Hace lo mismo que `login()` después de recibir la respuesta. Existe
  /// aparte porque el registro ya trae token y usuario: repetir el login
  /// significaría una segunda vuelta contra el portal.
  ///
  /// El código que se guarda es el del `user`, o sea el que certificó el
  /// portal, que puede no ser el que la persona tecleó (BR-REG-F-06).
  ///
  /// Los catálogos se reintentan UNA vez y, si vuelven a fallar, se sigue
  /// igual: recibido el 201 la cuenta existe y nada de acá puede convertirse
  /// en un error. El precio está anotado en BR-REG-F-10 de la spec — la
  /// persona aterriza en `/setup-carrera` sin carrera ni especialidades hasta
  /// el próximo arranque, porque `_loadCatalogs` solo corre al iniciar sesión.
  Future<void> adoptarSesion({
    required String token,
    required UserModel user,
  }) async {
    await _storage.saveToken(token);
    await _storage.saveCode(user.code);
    // Una cuenta recién registrada es siempre de alumno, pero se consulta el
    // rol igual: los catálogos son endpoints exclusivos de alumno y un docente
    // recibiría 403, como ya contempla `login()`.
    if (!user.isTeacher) {
      try {
        await _loadCatalogs(token: token, careerId: user.careerId);
      } catch (_) {
        try {
          await _loadCatalogs(token: token, careerId: user.careerId);
        } catch (_) {
          // Se sigue sin catálogos. Ver BR-REG-F-10.
        }
      }
    }
    _currentUser.value = user;
  }
```

- [ ] **Step 2: Verificar que compila y que nada se rompió**

Run: `flutter analyze`
Expected: sin warnings nuevos.

Run: `flutter test`
Expected: toda la suite en verde, sin cambios respecto de antes.

- [ ] **Step 3: Commit**

```bash
git add lib/services/auth_service.dart
git commit -m "feat(auth): adoptarSesion para entrar con lo que trajo el registro

El registro ya devuelve token y usuario, así que repetir login() significaría
una segunda vuelta contra el portal. Se guarda el código del user, que es el
que certificó el portal y puede no ser el que se tecleó.

Los catálogos se reintentan una vez y, si vuelven a fallar, se sigue igual:
recibido el 201 la cuenta existe y nada posterior puede volverse un error.

Sin test propio: AuthService no es construible en tests (sus inicializadores
levantan un ApiClient y un GoogleSignIn reales) y _loadCatalogs es privado.
Lo que se prueba es la costura por la que el controller lo llama."
```

---

### Task 4: Validadores y controller de los cinco estados

El corazón de la feature. Se prueba entero con dobles, sin montar widgets.

**Files:**
- Create: `lib/pages/registro/registro_controller.dart`
- Test: `test/HU33_jeff/registro_controller_test.dart`

**Interfaces:**
- Consumes: `RegistroService`, `RegistroResult`, `RegistroFailure`; `validateNewPassword` y `validatePasswordConfirmation` de `lib/pages/password_reset/password_reset_validators.dart`; `AuthService.to.adoptarSesion` y `AuthService.to.login`.
- Produces:
  - `enum RegistroPaso { datos, verificar, enviando, listo, incierto }`
  - `String? validarCodigo(String value)`
  - `String? validarPasoDatos({required String codigo, required String password, required String confirmacion})`
  - `String? validarPasoVerificar({required String portalPassword, required String passcode})`
  - `typedef AdoptarSesionFn = Future<void> Function({required String token, required UserModel user});`
  - `typedef IniciarSesionFn = Future<String?> Function({required String code, required String password});`
  - `class RegistroController extends GetxController` con `paso`, `errorMessage`, `resultado`, `passwordVisible`, `portalPasswordVisible`, los cinco `TextEditingController` (`codigoCtrl`, `passwordCtrl`, `confirmacionCtrl`, `portalPasswordCtrl`, `passcodeCtrl`), y los métodos `continuar()`, `volverADatos()`, `enviar()`, `intentarIniciarSesion()`, `volverAVerificar()`.

- [ ] **Step 1: Escribir el test que falla**

Crear `test/HU33_jeff/registro_controller_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/models/registro_models.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/registro/registro_controller.dart';
import 'package:ulima_plus/services/registro_service.dart';

/// Máquina de estados del registro (HU33).
///
/// El controller se construye DIRECTO, sin Get.put(): así GetX no dispara
/// onInit() y no hay red. Es el estilo mayoritario del repo para lógica de
/// controller.

class _ServicioFalso implements RegistroService {
  _ServicioFalso({this.resultado, this.fallo});

  final RegistroResult? resultado;
  final RegistroFailure? fallo;
  int llamadas = 0;
  String? codigoRecibido;

  @override
  Future<RegistroResult> registrar({
    required String code,
    required String portalPassword,
    required String passcode,
    required String password,
  }) async {
    llamadas++;
    codigoRecibido = code;
    if (fallo != null) throw fallo!;
    // Un `resultado` nulo revienta acá a propósito: es como el caso 10 fabrica
    // una excepción que NO es RegistroFailure.
    return resultado!;
  }
}

UserModel _usuario() => UserModel.fromJson({
      'id': 1,
      'studentId': 1,
      'code': '20230001',
      'fullName': 'GARCIA LOPEZ MARIA',
      'institutionalEmail': '20230001@aloe.ulima.edu.pe',
      'role': 'student',
      'career_id': 1,
      'setupComplete': false,
    });

PortalSyncSummary _summary() => const PortalSyncSummary(
      coursesCreated: 0,
      sectionsCreated: 0,
      sectionsUpdated: 0,
      sessionsUpserted: 12,
      enrollmentsUpserted: 5,
      enrollmentsWithdrawn: 0,
      progressUpserted: 40,
      syllabiUpserted: 0,
    );

RegistroResult _resultado({String token = 'jwt'}) => RegistroResult(
      token: token,
      user: _usuario(),
      summary: _summary(),
      warnings: const [],
    );

/// Controller con las tres costuras controladas.
RegistroController _controller({
  RegistroService? servicio,
  AdoptarSesionFn? adoptar,
  IniciarSesionFn? login,
}) {
  final c = RegistroController(
    service: servicio ?? _ServicioFalso(resultado: _resultado()),
    adoptarSesion: adoptar ?? ({required token, required user}) async {},
    iniciarSesion: login ?? ({required code, required password}) async => null,
  );
  c.codigoCtrl.text = '20230001';
  c.passwordCtrl.text = 'micontrasena';
  c.confirmacionCtrl.text = 'micontrasena';
  c.portalPasswordCtrl.text = 'clave-portal';
  c.passcodeCtrl.text = '123456';
  return c;
}

void main() {
  group('UNITARIA · validadores del registro (HU33)', () {
    test('caso 1: el código acepta de 6 a 10 dígitos, ni más ni menos', () {
      expect(validarCodigo('20230001'), isNull);
      expect(validarCodigo('123456'), isNull);
      expect(validarCodigo('1234567890'), isNull);
      expect(validarCodigo('12345'), isNotNull);
      expect(validarCodigo('12345678901'), isNotNull);
      expect(validarCodigo('2023000a'), isNotNull);
      expect(validarCodigo(''), isNotNull);
    });

    test('caso 2: el código con espacios alrededor es válido: se recorta', () {
      // El limitador de tasa del backend recorta para su clave pero el esquema
      // no, así que enviarlo sin recortar gastaría cupo y devolvería 400.
      expect(validarCodigo('  20230001  '), isNull);
    });

    test('caso 3: la contraseña de ULima++ exige 8 y su confirmación coincide', () {
      expect(validarPasoDatos(codigo: '20230001', password: 'corta', confirmacion: 'corta'), isNotNull);
      expect(validarPasoDatos(codigo: '20230001', password: 'micontrasena', confirmacion: 'otra'), isNotNull);
      expect(validarPasoDatos(codigo: '20230001', password: 'micontrasena', confirmacion: 'micontrasena'), isNull);
    });

    test('caso 4: el authenticator acepta de 6 a 8 dígitos', () {
      // SecurID entrega 6 de tokencode y 8 cuando el PIN va delante, y el campo
      // no recorta: exigir exactamente 6 rechazaría un passcode legítimo.
      expect(validarPasoVerificar(portalPassword: 'x', passcode: '123456'), isNull);
      expect(validarPasoVerificar(portalPassword: 'x', passcode: '12345678'), isNull);
      expect(validarPasoVerificar(portalPassword: 'x', passcode: '12345'), isNotNull);
      expect(validarPasoVerificar(portalPassword: 'x', passcode: '123456789'), isNotNull);
      expect(validarPasoVerificar(portalPassword: '', passcode: '123456'), isNotNull);
    });
  });

  group('UNITARIA · RegistroController transiciones (HU33)', () {
    test('caso 1: arranca en datos y continuar no toca la red', () async {
      final servicio = _ServicioFalso(resultado: _resultado());
      final c = _controller(servicio: servicio);
      expect(c.paso.value, equals(RegistroPaso.datos));

      c.continuar();
      expect(c.paso.value, equals(RegistroPaso.verificar));
      expect(servicio.llamadas, equals(0),
          reason: 'el paso 1 no consulta al backend: sería un oráculo de enumeración');
    });

    test('caso 2: continuar con datos inválidos se queda en datos', () {
      final c = _controller()..passwordCtrl.text = 'corta';
      c.continuar();
      expect(c.paso.value, equals(RegistroPaso.datos));
      expect(c.errorMessage.value, isNotNull);
    });

    test('caso 3: un registro exitoso deja la sesión puesta y pasa a listo', () async {
      var adoptado = false;
      final c = _controller(adoptar: ({required token, required user}) async {
        adoptado = true;
        expect(token, equals('jwt'));
        expect(user.code, equals('20230001'));
      });
      c.continuar();
      await c.enviar();

      expect(c.paso.value, equals(RegistroPaso.listo));
      expect(adoptado, isTrue);
      expect(c.resultado.value, isNotNull);
    });

    test('caso 4: el código se envía recortado', () async {
      final servicio = _ServicioFalso(resultado: _resultado());
      final c = _controller(servicio: servicio)..codigoCtrl.text = '  20230001 ';
      c.continuar();
      await c.enviar();
      expect(servicio.codigoRecibido, equals('20230001'));
    });

    test('caso 5: tras el éxito las credenciales del portal quedan vacías', () async {
      final c = _controller();
      c.continuar();
      await c.enviar();
      expect(c.portalPasswordCtrl.text, isEmpty);
      expect(c.passcodeCtrl.text, isEmpty);
    });

    test('caso 6: un fallo del portal vuelve a verificar, borra el passcode y conserva la contraseña', () async {
      final c = _controller(
        servicio: _ServicioFalso(
          fallo: const RegistroFailure('miUlima rechazó los datos.', code: 'PORTAL_AUTH_FAILED'),
        ),
      );
      c.continuar();
      await c.enviar();

      expect(c.paso.value, equals(RegistroPaso.verificar));
      expect(c.passcodeCtrl.text, isEmpty, reason: 'lo que casi siempre venció es el código');
      expect(c.portalPasswordCtrl.text, equals('clave-portal'),
          reason: 'reescribirla alarga el reintento hasta que el código nuevo también vence');
      expect(c.errorMessage.value, contains('miUlima'));
    });

    test('caso 7: un 409 vuelve a datos, que es donde está el código', () async {
      final c = _controller(
        servicio: _ServicioFalso(
          fallo: const RegistroFailure('Ya existe una cuenta.', code: 'USER_ALREADY_EXISTS'),
        ),
      );
      c.continuar();
      await c.enviar();
      expect(c.paso.value, equals(RegistroPaso.datos));
    });

    test('caso 8: el plazo vencido va a incierto, no a un fallo', () async {
      final c = _controller(
        servicio: _ServicioFalso(
          fallo: const RegistroFailure('No pudimos confirmar…', code: 'TIEMPO_AGOTADO'),
        ),
      );
      c.continuar();
      await c.enviar();
      expect(c.paso.value, equals(RegistroPaso.incierto));
    });

    test('caso 9: si adoptar la sesión falla, la cuenta existe: incierto, no fallo', () async {
      final c = _controller(
        adoptar: ({required token, required user}) async => throw Exception('keychain'),
      );
      c.continuar();
      await c.enviar();
      expect(c.paso.value, equals(RegistroPaso.incierto));
    });

    test('caso 10: una excepción inesperada no deja la pantalla colgada en enviando', () async {
      final c = _controller(servicio: _ServicioFalso(resultado: null));
      c.continuar();
      await c.enviar();
      expect(c.paso.value, isNot(equals(RegistroPaso.enviando)),
          reason: 'portal-sync tiene ese agujero; acá no se repite');
      expect(c.errorMessage.value, isNotNull);
    });

    test('caso 11: la contraseña de miUlima no llega a ningún estado observable', () async {
      // RS-FE-6. Es la comprobación que sí muerde: `onClose` también borra los
      // campos, pero eso no se puede afirmar después de `dispose()` sin
      // depender de si el SDK lanza al leer un controller liberado.
      final c = _controller(
        servicio: _ServicioFalso(
          fallo: const RegistroFailure('miUlima rechazó los datos.', code: 'PORTAL_AUTH_FAILED'),
        ),
      );
      c.continuar();
      await c.enviar();

      expect(c.errorMessage.value ?? '', isNot(contains('clave-portal')));
      expect(c.resultado.value?.toString() ?? '', isNot(contains('clave-portal')));
      expect(c.paso.value.toString(), isNot(contains('clave-portal')));
    });
  });

  group('UNITARIA · RegistroController salidas de incierto (HU33)', () {
    Future<RegistroController> enIncierto({IniciarSesionFn? login}) async {
      final c = _controller(
        servicio: _ServicioFalso(
          fallo: const RegistroFailure('No pudimos confirmar…', code: 'TIEMPO_AGOTADO'),
        ),
        login: login,
      );
      c.continuar();
      await c.enviar();
      expect(c.paso.value, equals(RegistroPaso.incierto));
      return c;
    }

    test('caso 1: si el login de rescate entra, la cuenta existía', () async {
      final c = await enIncierto(login: ({required code, required password}) async => null);
      expect(await c.intentarIniciarSesion(), isTrue);
    });

    test('caso 2: el login usa el código y la contraseña que se eligieron', () async {
      String? codigoUsado;
      String? claveUsada;
      final c = await enIncierto(login: ({required code, required password}) async {
        codigoUsado = code;
        claveUsada = password;
        return null;
      });
      await c.intentarIniciarSesion();
      expect(codigoUsado, equals('20230001'));
      expect(claveUsada, equals('micontrasena'));
    });

    test('caso 3: si el login falla NO se concluye que la cuenta no existe', () async {
      final c = await enIncierto(
        login: ({required code, required password}) async => 'Código o contraseña incorrectos.',
      );
      expect(await c.intentarIniciarSesion(), isFalse);
      expect(c.paso.value, equals(RegistroPaso.incierto), reason: 'sigue siendo incierto');
      // Puede existir bajo el código que devolvió el portal, que gana sobre el
      // tecleado: el mensaje tiene que dar el siguiente paso, no un veredicto.
      expect(c.errorMessage.value, contains('ya existe'));
    });

    test('caso 4: volver a intentar regresa a verificar con el passcode limpio', () async {
      final c = await enIncierto();
      c.passcodeCtrl.text = '999999';
      c.volverAVerificar();
      expect(c.paso.value, equals(RegistroPaso.verificar));
      expect(c.passcodeCtrl.text, isEmpty);
    });
  });
}
```

El import de `package:ulima_plus/models/portal_sync_models.dart` hace falta para `PortalSyncSummary`; agregarlo arriba junto a los demás.

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `flutter test test/HU33_jeff/registro_controller_test.dart`
Expected: FAIL en compilación, `Target of URI doesn't exist: '.../registro_controller.dart'`.

- [ ] **Step 3: Implementar el controller**

Crear `lib/pages/registro/registro_controller.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../models/registro_models.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/registro_service.dart';
import '../password_reset/password_reset_validators.dart';

/// En qué punto del alta está la pantalla.
enum RegistroPaso { datos, verificar, enviando, listo, incierto }

/// Validación pura: `null` = válido. Separada del widget para poder probarla
/// sin montar nada, como `password_reset_validators.dart`.
///
/// El rango es el mismo `^\d{6,10}$` de `registerSchema`. Se valida acá porque
/// el limitador de tasa del backend corre ANTES de validar el cuerpo: mandar
/// un código mal formado gasta uno de los cinco intentos por hora y devuelve
/// un 400 (BR-REG-F-03).
String? validarCodigo(String value) {
  final v = value.trim();
  if (v.isEmpty) return 'Escribe tu código de alumno.';
  if (!RegExp(r'^\d{6,10}$').hasMatch(v)) {
    return 'El código son entre 6 y 10 dígitos, sin espacios ni letras.';
  }
  return null;
}

/// Primer error del paso 1, o `null` si los tres campos están bien.
///
/// La contraseña usa los validadores del reset (mínimo 8). El backend acepta
/// cualquier cosa a propósito y lo declara deuda; pedir menos acá dejaría una
/// cuenta que no puede recuperar su propia contraseña.
String? validarPasoDatos({
  required String codigo,
  required String password,
  required String confirmacion,
}) =>
    validarCodigo(codigo) ??
    validateNewPassword(password) ??
    validatePasswordConfirmation(password, confirmacion);

String? validarPortalPassword(String value) =>
    value.trim().isEmpty ? 'Escribe tu contraseña de miUlima.' : null;

/// De 6 a 8 dígitos, igual que `PortalSyncController` y por el mismo motivo:
/// SecurID entrega 6 de tokencode y 8 cuando el PIN va delante, y
/// `PasswordResetOtpField` no recorta el texto (se le quitó el limitador de
/// longitud para arreglar el borrado en iOS).
String? validarPasscode(String value) {
  final v = value.trim();
  if (v.isEmpty) return 'Escribe el código de tu authenticator.';
  if (!RegExp(r'^\d{6,8}$').hasMatch(v)) {
    return 'El código del authenticator son 6 dígitos, sin espacios.';
  }
  return null;
}

String? validarPasoVerificar({
  required String portalPassword,
  required String passcode,
}) =>
    validarPortalPassword(portalPassword) ?? validarPasscode(passcode);

/// Costuras hacia `AuthService`, que no es construible en tests.
typedef AdoptarSesionFn = Future<void> Function({
  required String token,
  required UserModel user,
});
typedef IniciarSesionFn = Future<String?> Function({
  required String code,
  required String password,
});

class RegistroController extends GetxController {
  RegistroController({
    RegistroService? service,
    AdoptarSesionFn? adoptarSesion,
    IniciarSesionFn? iniciarSesion,
  })  : _service = service ?? RegistroService(),
        _adoptar = adoptarSesion ?? _adoptarPorDefecto,
        _login = iniciarSesion ?? _loginPorDefecto;

  static Future<void> _adoptarPorDefecto({
    required String token,
    required UserModel user,
  }) =>
      AuthService.to.adoptarSesion(token: token, user: user);

  static Future<String?> _loginPorDefecto({
    required String code,
    required String password,
  }) =>
      AuthService.to.login(code: code, password: password);

  final RegistroService _service;
  final AdoptarSesionFn _adoptar;
  final IniciarSesionFn _login;

  // Los cinco campos viven SOLO acá. Ninguno entra en un Rx observable, se
  // guarda o se imprime. Moverse entre pasos nunca los borra: lo único que se
  // borra es el passcode, y solo cuando un envío falló (BR-REG-F-05).
  final codigoCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmacionCtrl = TextEditingController();
  final portalPasswordCtrl = TextEditingController();
  final passcodeCtrl = TextEditingController();

  final paso = RegistroPaso.datos.obs;
  final errorMessage = RxnString();
  final passwordVisible = false.obs;
  final portalPasswordVisible = false.obs;
  final Rx<RegistroResult?> resultado = Rx<RegistroResult?>(null);

  bool get enviando => paso.value == RegistroPaso.enviando;

  @override
  void onClose() {
    // `clear()` antes de `dispose()`: el texto no queda en el buffer del campo
    // cuando la pantalla se destruye.
    for (final c in [
      codigoCtrl,
      passwordCtrl,
      confirmacionCtrl,
      portalPasswordCtrl,
      passcodeCtrl,
    ]) {
      c.clear();
      c.dispose();
    }
    super.onClose();
  }

  /// Paso 1 → paso 2. **No consulta al backend**: preguntar "¿existe este
  /// código?" sería un oráculo de enumeración de cuentas (BR-REG-F-02).
  void continuar() {
    final error = validarPasoDatos(
      codigo: codigoCtrl.text,
      password: passwordCtrl.text,
      confirmacion: confirmacionCtrl.text,
    );
    if (error != null) {
      errorMessage.value = error;
      return;
    }
    errorMessage.value = null;
    paso.value = RegistroPaso.verificar;
  }

  void volverADatos() {
    errorMessage.value = null;
    paso.value = RegistroPaso.datos;
  }

  Future<void> enviar() async {
    if (enviando) return;
    final error = validarPasoVerificar(
      portalPassword: portalPasswordCtrl.text,
      passcode: passcodeCtrl.text,
    );
    if (error != null) {
      errorMessage.value = error;
      return;
    }

    errorMessage.value = null;
    paso.value = RegistroPaso.enviando;

    final RegistroResult r;
    try {
      r = await _service.registrar(
        code: codigoCtrl.text.trim(),
        portalPassword: portalPasswordCtrl.text,
        passcode: passcodeCtrl.text.trim(),
        password: passwordCtrl.text,
      );
    } on RegistroFailure catch (e) {
      _manejarFallo(e);
      return;
    } catch (_) {
      // El servicio envuelve todo, pero si un doble o un cambio futuro lanza
      // otra cosa, la pantalla no puede quedarse en `enviando` para siempre.
      // Es el agujero que sí tiene `PortalSyncController`.
      _manejarFallo(const RegistroFailure(
        'No pudimos crear tu cuenta. Inténtalo de nuevo.',
      ));
      return;
    }

    // Apenas se usaron, se borran.
    portalPasswordCtrl.clear();
    passcodeCtrl.clear();

    try {
      await _adoptar(token: r.token, user: r.user);
    } catch (_) {
      // La cuenta EXISTE: el 201 ya volvió. Lo que falló es dejar la sesión
      // puesta, y para eso `incierto` ofrece justamente iniciar sesión.
      resultado.value = r;
      _manejarFallo(const RegistroFailure(
        'Tu cuenta se creó, pero no pudimos dejarte la sesión iniciada.',
        code: 'SIN_TOKEN',
      ));
      return;
    }

    resultado.value = r;
    paso.value = RegistroPaso.listo;
  }

  void _manejarFallo(RegistroFailure e) {
    passcodeCtrl.clear();
    errorMessage.value = e.message;

    const aIncierto = {'TIEMPO_AGOTADO', 'SIN_TOKEN'};
    const aDatos = {
      'USER_ALREADY_EXISTS',
      'INVALID_REQUEST_BODY',
      'INVALID_JSON_BODY',
    };

    if (aIncierto.contains(e.code)) {
      paso.value = RegistroPaso.incierto;
    } else if (aDatos.contains(e.code)) {
      paso.value = RegistroPaso.datos;
    } else {
      paso.value = RegistroPaso.verificar;
    }
  }

  /// Primera salida de `incierto`: intentar entrar con lo que ya se eligió.
  ///
  /// Devuelve `true` si la sesión quedó iniciada; navegar es cosa de la página.
  ///
  /// Un fallo **no** prueba que la cuenta no exista: puede existir bajo el
  /// código que devolvió el portal, que gana sobre el tecleado (BR-REG-F-06).
  Future<bool> intentarIniciarSesion() async {
    if (paso.value != RegistroPaso.incierto) return false;
    errorMessage.value = null;
    final error = await _login(
      code: codigoCtrl.text.trim(),
      password: passwordCtrl.text,
    );
    if (error == null) return true;
    errorMessage.value =
        'Seguimos sin poder confirmarlo. Puedes volver a intentar el registro: '
        'si te dice que ya existe una cuenta con ese código, es que sí se creó '
        'y puedes recuperar la contraseña desde el login.';
    return false;
  }

  /// Segunda salida de `incierto`.
  void volverAVerificar() {
    errorMessage.value = null;
    passcodeCtrl.clear();
    paso.value = RegistroPaso.verificar;
  }
}
```

- [ ] **Step 4: Correr los tests**

Run: `flutter test test/HU33_jeff/registro_controller_test.dart`
Expected: PASS, 18 casos.

Run: `flutter test`
Expected: toda la suite en verde.

Run: `flutter analyze`
Expected: sin warnings nuevos.

- [ ] **Step 5: Commit**

```bash
git add lib/pages/registro/registro_controller.dart test/HU33_jeff/registro_controller_test.dart
git commit -m "feat(registro): validadores y máquina de cinco estados

Los datos de ULima++ van primero y el authenticator queda como último campo
antes de enviar: el código vence cada 30 segundos y tipear una contraseña dos
veces toma más que eso.

El paso 1 no consulta al backend a propósito. Adelantar el 409 preguntando si
un código existe sería un oráculo de enumeración de cuentas, que es justo lo
que loginErrorMessage se cuida de no ser.

El passcode se valida de 6 a 8 dígitos, no exactamente 6: SecurID entrega 8
cuando el PIN va delante, y el campo OTP no recorta el texto desde que se le
quitó el limitador de longitud para arreglar el borrado en iOS.

El estado incierto tiene sus dos salidas definidas. Un login de rescate que
falla no prueba que la cuenta no exista: puede existir bajo el código que
devolvió el portal, así que el mensaje da el siguiente paso y no un veredicto."
```

---

### Task 5: Pantalla, ruta y acceso desde el login

**Files:**
- Create: `lib/pages/registro/registro_page.dart`
- Create: `lib/pages/registro/registro_binding.dart`
- Modify: `lib/main.dart` (imports y `getPages`)
- Modify: `lib/pages/login/login_page.dart` (agregar el enlace bajo `_ForgotPasswordLink`)
- Test: `test/HU33_jeff/registro_page_test.dart`

**Interfaces:**
- Consumes: todo lo de la Task 4; el kit público de `lib/pages/password_reset/password_reset_ui.dart` (`PasswordResetPalette.from(context)`, `PasswordResetScaffold({palette, child})`, `PasswordResetFieldLabel({palette, text})`, `PasswordResetField({controller, palette, hint, keyboardType, textInputAction, obscureText, onSubmitted, suffixIcon})`, `PasswordResetOtpField({controller, palette, length})`, `PasswordResetPrimaryButton({palette, label, loading, onPressed})`, `PasswordResetErrorMessage({palette, message})`); `postLoginRoute`.
- Produces: ruta `/registro`; `class RegistroBinding extends Bindings`; `class RegistroPage extends GetView<RegistroController>`.

- [ ] **Step 1: Escribir el binding**

Crear `lib/pages/registro/registro_binding.dart`:

```dart
import 'package:get/get.dart';

import 'registro_controller.dart';

/// Binding por ruta, que es la convención dura del repo: `Get.put` dentro de
/// `build()` asociaba el controller al overlay del snackbar y GetX lo destruía,
/// rompiendo los `TextEditingController`.
///
/// `lazyPut` sin `fenix` ni `permanent` a propósito: GetX elimina el controller
/// al salir de la ruta, y eso es lo que dispara `onClose()` y por tanto el
/// borrado de las credenciales de miUlima (RS-FE-6).
class RegistroBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RegistroController>(RegistroController.new);
  }
}
```

- [ ] **Step 2: Escribir la página**

Crear `lib/pages/registro/registro_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/portal_sync_models.dart';
import '../../services/auth_service.dart';
import '../../services/post_login_route.dart';
import '../password_reset/password_reset_ui.dart';
import 'registro_controller.dart';

/// Alta de cuenta contra miUlima.
///
/// Una sola ruta con cinco estados en vez de cinco pantallas, como hace
/// `PortalSyncPage` con tres: el flujo es lineal y volver atrás a mitad del
/// envío solo produce cuentas creadas que su dueño no sabe que tiene.
///
/// Reutiliza los widgets públicos de `password_reset_ui.dart` porque son el
/// mismo lenguaje visual del login, ya extraído (los del login son privados).
class RegistroPage extends GetView<RegistroController> {
  const RegistroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = PasswordResetPalette.from(context);
    return Obx(() {
      // Mientras se envía no se sale: ni con el gesto del sistema ni con el
      // botón de volver que `PasswordResetScaffold` dibuja siempre, porque
      // `PopScope` intercepta el `maybePop()` de los dos (BR-REG-F-09).
      return PopScope(
        canPop: !controller.enviando,
        child: PasswordResetScaffold(
          palette: palette,
          child: switch (controller.paso.value) {
            RegistroPaso.datos => _PasoDatos(palette: palette, controller: controller),
            RegistroPaso.verificar => _PasoVerificar(palette: palette, controller: controller),
            RegistroPaso.enviando => _Enviando(palette: palette),
            RegistroPaso.listo => _Listo(palette: palette, controller: controller),
            RegistroPaso.incierto => _Incierto(palette: palette, controller: controller),
          },
        ),
      );
    });
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo({required this.palette, required this.texto, required this.bajada});

  final PasswordResetPalette palette;
  final String texto;
  final String bajada;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          texto,
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.fieldText, fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Text(
          bajada,
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.fieldHint, fontSize: 12, height: 1.4),
        ),
      ],
    );
  }
}

/// Ojo de mostrar/ocultar, igual que el del login.
class _OjoContrasena extends StatelessWidget {
  const _OjoContrasena({required this.palette, required this.visible, required this.onTap});

  final PasswordResetPalette palette;
  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 20,
        color: palette.fieldHint,
      ),
      onPressed: onTap,
      splashRadius: 18,
    );
  }
}

class _PasoDatos extends StatelessWidget {
  const _PasoDatos({required this.palette, required this.controller});

  final PasswordResetPalette palette;
  final RegistroController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Titulo(
          palette: palette,
          texto: 'Crea tu cuenta de ULima++',
          bajada: 'Elige la contraseña con la que entrarás al app. '
              'No es la de miUlima.',
        ),
        const SizedBox(height: 24),
        PasswordResetFieldLabel(palette: palette, text: 'Código'),
        const SizedBox(height: 8),
        PasswordResetField(
          controller: controller.codigoCtrl,
          palette: palette,
          hint: 'Tu código de alumno',
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 20),
        PasswordResetFieldLabel(palette: palette, text: 'Contraseña'),
        const SizedBox(height: 8),
        Obx(() => PasswordResetField(
              controller: controller.passwordCtrl,
              palette: palette,
              hint: 'Al menos 8 caracteres',
              obscureText: !controller.passwordVisible.value,
              textInputAction: TextInputAction.next,
              suffixIcon: _OjoContrasena(
                palette: palette,
                visible: controller.passwordVisible.value,
                onTap: controller.passwordVisible.toggle,
              ),
            )),
        const SizedBox(height: 20),
        PasswordResetFieldLabel(palette: palette, text: 'Repetir contraseña'),
        const SizedBox(height: 8),
        Obx(() => PasswordResetField(
              controller: controller.confirmacionCtrl,
              palette: palette,
              hint: 'La misma otra vez',
              obscureText: !controller.passwordVisible.value,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => controller.continuar(),
            )),
        Obx(() => PasswordResetErrorMessage(
              palette: palette,
              message: controller.errorMessage.value,
            )),
        const SizedBox(height: 20),
        PasswordResetPrimaryButton(
          palette: palette,
          label: 'Continuar',
          loading: false,
          onPressed: controller.continuar,
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => Get.back<void>(),
          child: Text(
            'Ya tengo cuenta',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.fieldHint, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _PasoVerificar extends StatelessWidget {
  const _PasoVerificar({required this.palette, required this.controller});

  final PasswordResetPalette palette;
  final RegistroController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Titulo(
          palette: palette,
          texto: 'Verificamos que eres alumno',
          bajada: 'Entramos a miUlima con tus datos una sola vez, para traer '
              'tus cursos y tu avance. No los guardamos.',
        ),
        const SizedBox(height: 24),
        PasswordResetFieldLabel(palette: palette, text: 'Contraseña de miUlima'),
        const SizedBox(height: 8),
        Obx(() => PasswordResetField(
              controller: controller.portalPasswordCtrl,
              palette: palette,
              hint: 'Tu contraseña del portal',
              obscureText: !controller.portalPasswordVisible.value,
              textInputAction: TextInputAction.next,
              suffixIcon: _OjoContrasena(
                palette: palette,
                visible: controller.portalPasswordVisible.value,
                onTap: controller.portalPasswordVisible.toggle,
              ),
            )),
        const SizedBox(height: 20),
        PasswordResetFieldLabel(palette: palette, text: 'Código del authenticator'),
        const SizedBox(height: 8),
        PasswordResetOtpField(controller: controller.passcodeCtrl, palette: palette),
        const SizedBox(height: 8),
        Text(
          'El código de 6 dígitos que cambia cada 30 segundos.',
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.fieldHint, fontSize: 11),
        ),
        Obx(() => PasswordResetErrorMessage(
              palette: palette,
              message: controller.errorMessage.value,
            )),
        const SizedBox(height: 16),
        PasswordResetPrimaryButton(
          palette: palette,
          label: 'Crear mi cuenta',
          loading: false,
          onPressed: controller.enviar,
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: controller.volverADatos,
          child: Text(
            'Volver',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.fieldHint, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _Enviando extends StatelessWidget {
  const _Enviando({required this.palette});

  final PasswordResetPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 46,
          height: 46,
          // `palette.cursor` y no `buttonBackground`: en modo oscuro ese es
          // transparente y el spinner sería invisible.
          child: CircularProgressIndicator(strokeWidth: 3, color: palette.cursor),
        ),
        const SizedBox(height: 24),
        Text(
          'Creando tu cuenta…',
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.fieldText, fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Text(
          'Estamos entrando a miUlima y trayendo tus cursos, tu horario y tu '
          'avance. Puede tomar un par de minutos: no cierres la app.',
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.fieldHint, fontSize: 12, height: 1.4),
        ),
      ],
    );
  }
}

class _Listo extends StatelessWidget {
  const _Listo({required this.palette, required this.controller});

  final PasswordResetPalette palette;
  final RegistroController controller;

  @override
  Widget build(BuildContext context) {
    final r = controller.resultado.value;
    final avisos = r?.warnings ?? const <PortalSyncWarning>[];
    final nombre = r?.user.firstName ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_rounded, size: 54, color: palette.cursor),
        const SizedBox(height: 16),
        Text(
          nombre.isEmpty ? 'Listo, ya tienes cuenta' : 'Listo, $nombre',
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.fieldText, fontSize: 20, fontWeight: FontWeight.w800),
        ),
        if (r != null) ...[
          const SizedBox(height: 16),
          _Fila(palette: palette, etiqueta: 'Cursos matriculados', valor: '${r.summary.cursos}'),
          _Fila(palette: palette, etiqueta: 'Clases en tu horario', valor: '${r.summary.sessionsUpserted}'),
          _Fila(palette: palette, etiqueta: 'Cursos de tu avance', valor: '${r.summary.progressUpserted}'),
        ],
        if (avisos.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            'Algunas cosas que notamos',
            style: TextStyle(color: palette.fieldText, fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (final a in avisos)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '· ${a.message}',
                style: TextStyle(color: palette.fieldHint, fontSize: 11, height: 1.35),
              ),
            ),
        ],
        const SizedBox(height: 24),
        PasswordResetPrimaryButton(
          palette: palette,
          label: 'Entrar',
          loading: false,
          onPressed: () {
            final user = controller.resultado.value?.user;
            if (user == null) return;
            Get.offAllNamed(postLoginRoute(user));
          },
        ),
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.palette, required this.etiqueta, required this.valor});

  final PasswordResetPalette palette;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: TextStyle(color: palette.fieldHint, fontSize: 13)),
          Text(valor, style: TextStyle(color: palette.fieldText, fontSize: 13, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _Incierto extends StatelessWidget {
  const _Incierto({required this.palette, required this.controller});

  final PasswordResetPalette palette;
  final RegistroController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.help_outline_rounded, size: 54, color: palette.error),
        const SizedBox(height: 16),
        _Titulo(
          palette: palette,
          texto: 'No pudimos confirmar si tu cuenta se creó',
          bajada: 'Es posible que sí se haya creado. Prueba entrar con el '
              'código y la contraseña que acabas de elegir.',
        ),
        Obx(() => PasswordResetErrorMessage(
              palette: palette,
              message: controller.errorMessage.value,
            )),
        const SizedBox(height: 20),
        PasswordResetPrimaryButton(
          palette: palette,
          label: 'Iniciar sesión',
          loading: false,
          onPressed: () async {
            final entro = await controller.intentarIniciarSesion();
            if (!entro) return;
            // `login()` ya dejó el usuario puesto; de ahí sale la ruta.
            final user = AuthService.to.currentUser;
            if (user != null) Get.offAllNamed(postLoginRoute(user));
          },
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: controller.volverAVerificar,
          child: Text(
            'Volver a intentar el registro',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.fieldHint, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Registrar la ruta**

En `lib/main.dart`, agregar los imports junto a los de portal_sync (líneas 29-30):

```dart
import 'pages/registro/registro_binding.dart';
import 'pages/registro/registro_page.dart';
```

Y en `getPages`, inmediatamente después del `GetPage` de `/reset-password`:

```dart
        // Alta de cuenta contra miUlima (HU33). Binding por ruta, como el
        // resto: `lazyPut` sin `fenix` garantiza que GetX elimine el controller
        // al salir y que `onClose` borre las credenciales del portal.
        GetPage(
          name: '/registro',
          page: () => const RegistroPage(),
          binding: RegistroBinding(),
        ),
```

- [ ] **Step 4: Agregar el enlace en el login**

En `lib/pages/login/login_page.dart`, dentro de `_LoginCard`, justo después de la línea `_ForgotPasswordLink(palette: palette),`:

```dart
              _CrearCuentaLink(palette: palette),
```

Y al final del archivo, junto a `_ForgotPasswordLink`:

```dart
/// Acceso al registro.
///
/// Es un enlace FIJO y no una oferta reactiva tras un login fallido: mostrar
/// "¿creamos tu cuenta?" solo cuando el código no existe delataría quién tiene
/// cuenta, que es justo lo que `AuthService.loginErrorMessage` evita al
/// aplastar USER_NOT_FOUND e INVALID_PASSWORD en un mismo mensaje.
class _CrearCuentaLink extends StatelessWidget {
  const _CrearCuentaLink({required this.palette});
  final _LoginPalette palette;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () => Get.toNamed('/registro'),
        style: TextButton.styleFrom(
          foregroundColor: palette.fieldHint,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text(
          '¿No tienes cuenta? Créala',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Escribir el test de widgets**

Crear `test/HU33_jeff/registro_page_test.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/registro_models.dart';
import 'package:ulima_plus/pages/registro/registro_controller.dart';
import 'package:ulima_plus/pages/registro/registro_page.dart';
import 'package:ulima_plus/services/registro_service.dart';

/// La pantalla de registro (HU33), estado por estado.

/// Nunca completa: deja la pantalla en `enviando` para poder inspeccionarla.
class _ServicioColgado implements RegistroService {
  @override
  Future<RegistroResult> registrar({
    required String code,
    required String portalPassword,
    required String passcode,
    required String password,
  }) =>
      Completer<RegistroResult>().future;
}

Widget _app() => GetMaterialApp(
      initialRoute: '/registro',
      getPages: [
        GetPage(name: '/registro', page: () => const RegistroPage()),
        GetPage(name: '/login', page: () => const Scaffold(body: Text('LOGIN'))),
      ],
    );

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('caso 1: arranca pidiendo los datos de ULima++, no los de miUlima',
      (tester) async {
    Get.put<RegistroController>(RegistroController(
      service: _ServicioColgado(),
      adoptarSesion: ({required token, required user}) async {},
      iniciarSesion: ({required code, required password}) async => null,
    ));
    await tester.pumpWidget(_app());
    await tester.pump();

    expect(find.text('Crea tu cuenta de ULima++'), findsOneWidget);
    expect(find.text('Contraseña de miUlima'), findsNothing,
        reason: 'las dos contraseñas nunca se ven a la vez');
  });

  testWidgets('caso 2: continuar con datos válidos lleva al paso de miUlima',
      (tester) async {
    final c = RegistroController(
      service: _ServicioColgado(),
      adoptarSesion: ({required token, required user}) async {},
      iniciarSesion: ({required code, required password}) async => null,
    );
    Get.put<RegistroController>(c);
    await tester.pumpWidget(_app());
    await tester.pump();

    c.codigoCtrl.text = '20230001';
    c.passwordCtrl.text = 'micontrasena';
    c.confirmacionCtrl.text = 'micontrasena';
    await tester.tap(find.text('Continuar'));
    await tester.pump();

    expect(find.text('Verificamos que eres alumno'), findsOneWidget);
    expect(find.text('Código del authenticator'), findsOneWidget);
  });

  testWidgets('caso 3: mientras se envía no se puede salir', (tester) async {
    final c = RegistroController(
      service: _ServicioColgado(),
      adoptarSesion: ({required token, required user}) async {},
      iniciarSesion: ({required code, required password}) async => null,
    );
    Get.put<RegistroController>(c);
    await tester.pumpWidget(_app());
    await tester.pump();

    c.codigoCtrl.text = '20230001';
    c.passwordCtrl.text = 'micontrasena';
    c.confirmacionCtrl.text = 'micontrasena';
    c.continuar();
    c.portalPasswordCtrl.text = 'clave';
    c.passcodeCtrl.text = '123456';
    unawaited(c.enviar());
    await tester.pump();

    expect(find.text('Creando tu cuenta…'), findsOneWidget);

    // El PopScope más cercano al contenido es el nuestro; buscarlo por
    // `byType` a secas encontraría también los que instala el Navigator.
    final scope = tester.widget<PopScope>(
      find
          .ancestor(
            of: find.text('Creando tu cuenta…'),
            matching: find.byType(PopScope),
          )
          .first,
    );
    expect(scope.canPop, isFalse,
        reason: 'salir a mitad del envío deja cuentas que su dueño no sabe que tiene');
  });

  testWidgets('caso 4: el estado incierto ofrece las dos salidas', (tester) async {
    final c = RegistroController(
      service: _ServicioColgado(),
      adoptarSesion: ({required token, required user}) async {},
      iniciarSesion: ({required code, required password}) async => null,
    );
    Get.put<RegistroController>(c);
    await tester.pumpWidget(_app());
    await tester.pump();

    c.paso.value = RegistroPaso.incierto;
    await tester.pump();

    expect(find.text('No pudimos confirmar si tu cuenta se creó'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Volver a intentar el registro'), findsOneWidget);
  });
}
```

Agregar `import 'dart:async';` al inicio del test (por `Completer` y `unawaited`).

- [ ] **Step 6: Correr todo**

Run: `flutter test test/HU33_jeff/`
Expected: PASS, los cuatro archivos.

Run: `flutter test`
Expected: toda la suite en verde.

Run: `flutter analyze`
Expected: sin warnings nuevos.

- [ ] **Step 7: Commit**

```bash
git add lib/pages/registro/ lib/main.dart lib/pages/login/login_page.dart test/HU33_jeff/registro_page_test.dart
git commit -m "feat(registro): pantalla de alta y acceso desde el login

Cinco estados en una sola ruta, como portal-sync resuelve tres. Compuesta con
el kit público de password_reset_ui.dart, que es el mismo lenguaje visual del
login ya extraído.

PopScope bloquea la salida mientras se envía. Cubre tanto el gesto del sistema
como el botón de volver que PasswordResetScaffold dibuja siempre y que no se
puede ocultar: salir a mitad del envío produce exactamente la cuenta creada
que su dueño no sabe que tiene.

El acceso es un enlace fijo bajo el login y no una oferta que aparece cuando
el login falla: ofrecerlo solo cuando el código no existe delataría quién
tiene cuenta."
```

---

## Verificación final

- [ ] `flutter analyze` sin warnings nuevos.
- [ ] `flutter test` en verde, incluidos los cuatro archivos de `test/HU33_jeff/`.
- [ ] Agregar los enlaces `[@test]` a `specs/features/registro/registro.spec.md`, ahora que los archivos existen: bajo RS-FE-1 los de servicio y controller, bajo RS-FE-4 el de `api_client_401_test.dart`, bajo RS-FE-5 los casos de `incierto`, bajo RS-FE-6 el caso 11 del controller. El repo prohíbe enlazar tests inexistentes, por eso van al final y no en la spec original.
- [ ] Cambiar el estado de la spec de «pendiente de implementación» a implementada, y la fila 16 de `docs/specs/feature-index.md`.
- [ ] Commit de esos dos ajustes de documentación.

**Lo que NO verifica esta rama:** el primer registro real. `POST /auth/register` vive en el PR #1 del backend y no está desplegado, así que hasta que ese PR aterrice la pantalla solo está probada contra dobles. La comprobación manual —registrarse con una cuenta que no esté en la base— necesita credenciales de miUlima y solo la puede hacer el usuario.
