---
name: Auth
description: Login, logout, JWT session persistence, and authenticated navigation for ULima++ Flutter app
targets:
  - ../../../lib/pages/login/**
  - ../../../lib/services/auth_service.dart
  - ../../../lib/services/storage_service.dart
  - ../../../lib/services/api_client.dart
  - ../../../lib/models/user_model.dart
  - ../../../lib/configs/google_auth_config.dart
  - ../../../lib/components/google_sign_in_button*.dart
---

# Auth

> Enmienda del 2026-09-25, **aprobada por el dueño el 2026-09-26** junto con la spec de la
> bienvenida con Ulises (`specs/features/bienvenida/bienvenida.spec.md`) e implementada el
> 2026-09-26. La bienvenida reemplaza a la tarjeta del login como pantalla sin sesión y cambia la
> forma, no las reglas, del inicio de sesión. El detalle está en «Enmienda de la bienvenida con
> Ulises», al final. Desde esa fecha, el código sigue la enmienda.

## User Stories

| ID | Description |
| --- | --- |
| US01 | Iniciar sesión con código y contraseña. |
| US02 | Cerrar sesión. |
| US03 | Iniciar sesión con Google usando correo institucional de alumno (`@aloe.ulima.edu.pe`) o docente (`@ulima.edu.pe`) en web y Android. |

## Business Rules

### BR-AUTH-F-01: Login flow
- El formulario recolecta `code` y `password`.
- `LoginController.submit()` valida que ambos campos no estén vacíos.
- Si vacío → muestra `"Ingresa tu código y contraseña."` sin llamar API.
- Si completo → llama `AuthService.login(code, password)`.
- El servicio envía `POST /auth/login` con `{ code, password }`.
- Si la respuesta es exitosa:
  1. Guarda el JWT (`token`) en `StorageService`.
  2. Construye `UserModel` desde `user`.
  3. Redirige a `/home` si `user.setupComplete`, o a `/setup-carrera` si no.
- Si la respuesta es error (`401 USER_NOT_FOUND`, `401 INVALID_PASSWORD`, etc.):
  - Muestra `"Código o contraseña incorrectos."` sin exponer detalles del backend.

### BR-AUTH-F-02: JWT token storage
- El JWT recibido en el login se persiste en `shared_preferences` bajo la clave `session_token`.
- No se persiste el `code` del usuario; el JWT es suficiente para identificar la sesión.
- El token se usa como `Authorization: Bearer <token>` en todas las requests autenticadas.

### BR-AUTH-F-03: Session restoration
- Al iniciar la app, `main.dart` llama `AuthService.tryRestoreSession()`.
- Si hay un JWT guardado:
  1. Configura el token en `ApiClient` para requests autenticados.
  2. Llama `GET /auth/me` (con el Bearer token) para validar la sesión y obtener datos del usuario.
  3. Si la respuesta es exitosa → construye `UserModel` y navega según `setupComplete`.
  4. Si la respuesta es error (`401 INVALID_TOKEN`) → limpia la sesión y redirige a `/login`.
- Si no hay JWT guardado → redirige a `/login`.

### BR-AUTH-F-04: Logout
- `AuthService.logout()`:
  1. Envía `POST /auth/logout` con el Bearer token (best-effort, no bloquea).
  2. Limpia el JWT y datos de sesión de `StorageService`.
  3. Redirige a `/login`.
- El cierre de sesión es definitivo: no hay re-autenticación automática.

### BR-AUTH-F-05: Role mapping
- El backend devuelve `role` como `"student"`, `"delegate"` o `"subdelegate"`.
- `UserModel.role` almacena el valor en español: `"estudiante"`, `"delegado"`, `"subdelegado"`.
- Mapeo:
  - `"student"` → `"estudiante"`
  - `"delegate"` → `"delegado"`
  - `"subdelegate"` → `"subdelegado"`
- `UserModel.isDelegate` retorna `true` si role es `"delegado"` o `"subdelegado"`.

### BR-AUTH-F-06: UserModel from backend DTO
- El backend devuelve `User` con esta estructura:

```json
{
  "id": 1,
  "studentId": 10,
  "code": "20201234",
  "fullName": "Nombre Apellido",
  "institutionalEmail": "user@aloe.ulima.edu.pe",
  "role": "student",
  "careerId": 1,
  "curriculumId": 1,
  "currentLevel": 5
}
```

- `UserModel.fromJson` debe mapear:
  | Backend field | UserModel field | Transformación |
  |---|---| --- |
  | `code` | `code` | directo |
  | `fullName` | `firstName`, `lastName` | split por último espacio: "Nombre Apellido" → firstName="Nombre", lastName="Apellido" |
  | `institutionalEmail` | `email` | directo |
  | `role` | `role` | mapear a español |
  | `careerId` | `careerId` | directo |
  | `currentCycle` | `currentCycle` | no viene del backend; se mantiene como "2026-1" por defecto |
  | `setupComplete` | `setupComplete` | no viene del backend; se lee desde `StorageService` |
  | `especialidadPrincipal` | `especialidadPrincipal` | no viene del backend; se lee desde `StorageService` |
  | `especialidadesInteres` | `especialidadesInteres` | no viene del backend; se lee desde `StorageService` |

### BR-AUTH-F-07: ApiClient auth header
- `ApiClient` debe exponer un método o setter para configurar el token JWT.
- Todas las requests que no sean `POST /auth/login` deben incluir `Authorization: Bearer <token>`.
- Si una request autenticada recibe un error `401 Unauthorized`, el Frontend debe interceptarlo globalmente, limpiar los datos locales (`StorageService.clearSession()`) y redirigir forzosamente a `/login` (previniendo un estado inválido por sesiones concurrentes en otros dispositivos).

### BR-AUTH-F-08: Loading state
- Durante el login, el botón "Entrar" muestra un `CircularProgressIndicator` y está deshabilitado.
- Esto ya está implementado en `login_page.dart` vía `controller.submitting.value`.

### BR-AUTH-F-09: Single Active Session (Concurrency)
- ⚠️ **NO IMPLEMENTADO**: El backend soporta Token Versioning (el JWT incluye `tokenVersion` y el middleware verifica que coincida con `app_user.tokenVersion`) pero el frontend aún no implementa la intercepción global de 401 para detectar sesiones concurrentes. El `ApiClient` intercepta 401 genéricamente pero sin lógica específica de token versioning.

### BR-AUTH-F-10: Google sign-in flow (web + Android)
- El login con Google canjea un `idToken` de Google por un JWT propio vía `POST /auth/google` con `{ idToken }`.
- El backend acepta `@aloe.ulima.edu.pe` para alumnos y `@ulima.edu.pe` para docentes. La cuenta y el perfil correspondiente deben existir previamente; no hay autoaprovisionamiento.
- Tras una respuesta exitosa, `finishGoogleLogin` construye primero el `UserModel` y diferencia el rol:
  - alumno: carga catálogos de carrera/especialidad y continúa con su navegación habitual;
  - docente: omite esos catálogos porque sus endpoints son exclusivos de alumno, conserva la sesión y navega a `/home`, donde el shell docente ya existente toma el control.
- El guard docente debe ejecutarse tanto en web como en Android porque ambos caminos terminan en `finishGoogleLogin`.
- **Configuración de Google OAuth** (`lib/configs/google_auth_config.dart` → `googleWebClientId`):
  - El `GoogleSignIn` se construye con `clientId` solo en web y `serverClientId` solo en móvil; ambos usan el **mismo client ID web**.
  - `serverClientId` es obligatorio en Android: sin él, `account.authentication.idToken` es `null` y el login falla con `"No se obtuvo información de Google."`. El `idToken` resultante lleva `aud = client web` y se envía al backend.
  - ⚠️ **Deuda de seguridad preexistente, fuera de este cambio**: el backend actual no pasa un `audience` a `verifyIdToken`; la validación explícita contra el client web debe evaluarse como hardening separado con su configuración de despliegue.
- **Web** (`kIsWeb == true`):
  - Se renderiza el botón oficial de Google Identity Services (`renderButton`, ver `google_sign_in_button_web.dart`); `signIn()` no se usa en web en `google_sign_in` 6.x.
  - La cuenta seleccionada llega por `googleSignIn.onCurrentUserChanged` y `LoginController` la completa con `AuthService.finishGoogleLogin(account)`.
- **Android** (`kIsWeb == false`):
  - El botón propio dispara `LoginController.loginWithGoogle()` → `AuthService.loginWithGoogle()` → `_googleSignIn.signIn()` (flujo interactivo nativo) → `finishGoogleLogin(account)`.
  - Requiere un **OAuth Client de tipo Android** registrado en el mismo proyecto de Google Cloud que el client web, con `package name = com.example.ulima_plus` y la huella **SHA-1** del certificado de firma (debug para desarrollo, release para producción). Este client NO se versiona ni se embebe: Google Play Services lo resuelve en runtime por package name + SHA-1. Sin él, `signIn()` falla con `ApiException: 10` (DEVELOPER_ERROR).
  - No requiere `google-services.json` ni Firebase (`google_sign_in` no depende de Firebase).
- **Errores mapeados** (`finishGoogleLogin`):
  - `403 INVALID_DOMAIN` → mensaje que indique ambos dominios admitidos: `@aloe.ulima.edu.pe` y `@ulima.edu.pe`.
  - `401 USER_NOT_FOUND` → `"Tu correo no está registrado en el sistema."`
  - Cancelación del usuario (`account == null`) → sin error, no navega.

## UI Behavior

### Login screen (`login_page.dart`)
- La UI ya está implementada y no requiere cambios visuales.
- **Estados**:
  - **Initial**: campos vacíos, botón "Entrar" habilitado.
  - **Loading**: botón muestra spinner y está deshabilitado.
  - **Error**: mensaje de error en rojo debajo del campo de contraseña.
  - **Success**: navega a `/home` o `/setup-carrera` según `setupComplete`.
- **Validación local**: si code o password están vacíos → `"Ingresa tu código y contraseña."`.

### Navigation
- `POST /auth/login` exitoso → `Get.offAllNamed('/home')` si `setupComplete` es `true`, o `Get.offAllNamed('/setup-carrera')` si es `false`.
- `POST /auth/logout` → `Get.offAllNamed('/login')`.
- Session restoration fallida → `Get.offAllNamed('/login')`.

## Data Flow

### Login flow
```
User input → LoginController.submit()
  → AuthService.login(code, password)
    → ApiClient.postJson('/auth/login', { code, password })
    → Response: { token, user }
    → StorageService.saveToken(token)
    → UserModel.fromJson(user)
    → StorageService.loadSetup(code) → setupComplete, especialidades
    → AuthService.currentUser = user
  → LoginController: Get.offAllNamed(route)
```

### Session restoration flow
```
App start → main.dart → AuthService.tryRestoreSession()
  → StorageService.getToken() ? null → return false → navigate /login
  → ApiClient.setToken(token)
  → ApiClient.getJson('/auth/me')
    → Response: { user }
    → UserModel.fromJson(user)
    → StorageService.loadSetup(code) → setupComplete, especialidades
    → AuthService.currentUser = user
    → return true → navigate según setupComplete
```

### Logout flow
```
User action → AuthService.logout()
  → ApiClient.postJson('/auth/logout') (best-effort)
  → StorageService.clearSession() (incluye token)
  → AuthService.currentUser = null
  → Get.offAllNamed('/login')
```

## Implementation Plan

### `api_client.dart`
- Agregar propiedad `String? _authToken`.
- Agregar método `setToken(String? token)` para configurar el token.
- Modificar `getJson` y `postJson` para incluir `Authorization: Bearer <token>` cuando `_authToken` no sea null, excepto para `POST /auth/login`.
- Opcional: detectar `401` en `_decode` y lanzar un error específico.

### `storage_service.dart`
- Agregar constantes:
  ```dart
  static const _kToken = 'session_token';
  ```
- Agregar métodos:
  ```dart
  String? get savedToken => _prefs.getString(_kToken);
  Future<void> saveToken(String token) => _prefs.setString(_kToken, token);
  ```
- `clearSession()` debe remover también `_kToken`.

### `auth_service.dart`
- `login()`:
  - Recibir el `token` de la respuesta y llamar `_storage.saveToken(token)`.
  - Llamar `_api.setToken(token)`.
  - Dejar de guardar el `code` por separado (el JWT basta).
- `tryRestoreSession()`:
  - Leer `_storage.savedToken`.
  - Si no hay token → retornar `false`.
  - Llamar `_api.setToken(token)`.
  - Llamar `GET /auth/me` (sin query params, usa el Bearer token).
  - Construir `UserModel` desde la respuesta.
  - Si falla → llamar `_storage.clearSession()` y `_api.setToken(null)`.
- `logout()`:
  - Intentar `POST /auth/logout` (try-catch, best-effort).
  - Llamar `_storage.clearSession()`.
  - Llamar `_api.setToken(null)`.
  - Setear `_currentUser.value = null`.

### `user_model.dart`
- `UserModel.fromJson`:
  - Mapear `fullName` a `firstName` (todo excepto última palabra) y `lastName` (última palabra).
  - Mapear `institutionalEmail` a `email`.
  - Mapear `role` de inglés a español.
  - Eliminar dependencia de campos legacy del backend (`especialidades`, `courseProgress`, `career_id` numérico, etc.).
- Agregar helper `_roleToSpanish(String role)`:
  - `"student"` → `"estudiante"`
  - `"delegate"` → `"delegado"`
  - `"subdelegate"` → `"subdelegado"`
  - default → `"estudiante"`
- El `careerId`, `especialidadPrincipal`, `especialidadesInteres`, `setupComplete` se cargan desde `StorageService` después de construir el modelo base.

### `login_controller.dart`
- Sin cambios. Ya usa `AuthService.to.login()` y navega según `user.setupComplete`.

### `login_page.dart`
- Sin cambios visuales. La UI ya es correcta.

## Test Links

*(Test links a ser agregados cuando existan tests de auth. Los `test/auth/` y `test/services/api_client_auth_test.dart` no existen actualmente.)*

## Enmienda de la bienvenida con Ulises (2026-09-25, aprobada el 2026-09-26)

Nace con `specs/features/bienvenida/bienvenida.spec.md` (RF-BIEN-1, RF-BIEN-3, RF-BIEN-6,
RF-BIEN-12, RF-BIEN-20 y RF-BIEN-21), y el dueño la aprueba con ella el 2026-09-26, con las
decisiones B-9 y B-10 en la opción que elige ese día. Cambia los puntos de esta lista, y el resto
de la spec sigue igual. Las referencias `archivo:línea` apuntan a `4e2a0b2`.

- **Targets.** Suma `lib/pages/bienvenida/**`, `lib/services/session_navigation.dart` y
  `lib/components/google_sign_in_button_web.dart`. `lib/pages/login/login_page.dart` sale del
  código, y `lib/pages/login/**` sigue por `login_binding.dart` y `login_controller.dart`.
- **US03.** El login con Google corre también en iOS, que ya lo hace hoy con el `GIDClientID` de
  `ios/Runner/Info.plist:72-73` y el mismo `loginWithGoogle` de Android.
- **BR-AUTH-F-01.** El formulario pasa a dos turnos de la conversación, E1 con el código o
  usuario y E2 con la contraseña (RF-BIEN-6). La validación, el servicio y los mensajes no
  cambian. El botón de envío de E1 y «Entrar» quedan inactivos mientras su campo está vacío, y
  «Ingresa tu código y contraseña.» sigue en `LoginController` como defensa. Tras un error, la
  conversación vuelve a E1 con el código escrito y la contraseña vacía (decisión B-6 de la
  bienvenida). Tras el éxito, la navegación la hace la bienvenida y no `LoginController`. La
  bienvenida decide con `postLoginRoute`, que no cambia, entre el paso al horario de RF-BIEN-11
  y, para un alumno con la configuración a medias, el test dentro de la conversación, sin navegar
  a `/setup-carrera` (decisión B-10 y RF-BIEN-21).
- **Fallo de red en el login.** `AuthService.login` solo atrapa `ApiException`
  (`auth_service.dart:218-250`), así que hoy un fallo de red deja `submitting` en `true` y el botón
  «Entrar» girando (`login_controller.dart:73-75`), y en web `_onGoogleUserChanged` queda
  bloqueado por ese `submitting` (`login_controller.dart:36`). `LoginController.submit` atrapa ese
  fallo con un `finally` que apaga `submitting` en todos los casos, y la bienvenida muestra «No
  hay conexión. Revisa tu internet e inténtalo de nuevo.». Queda como deuda que `login` guarda el
  token antes de cargar los catálogos (`auth_service.dart:235-242`), así que un fallo de red en
  ese tramo deja una sesión que el siguiente arranque restaura («Qué NO entra» de la
  bienvenida).
- **BR-AUTH-F-03 y BR-AUTH-F-04.** La sesión que no se restaura y el cierre de sesión siguen
  llevando a `/login`, que ahora muestra la bienvenida. `offAllToLogin` suma el parámetro
  opcional `motivo`, con `expirada` desde el interceptor del 401 y `restablecida` desde el
  restablecimiento de contraseña (RF-BIEN-1 y RF-BIEN-3). El botón «Volver a iniciar sesión» del
  Perfil (`perfil.dart:97`) no pasa motivo y sigue compilando. Los avisos «Sesión expirada» y
  «Contraseña actualizada» salen abajo para no tapar el sello (decisión B-29 de la bienvenida). En
  BR-AUTH-F-03, la sesión restaurada de un alumno con `setupComplete` en `false` ya no lleva a
  `/setup-carrera`. El splash hace el relevo a `/login` sin borrar la sesión, y la bienvenida la
  reconoce y le toma el test (RF-SPL-12 del splash y RF-BIEN-21).
- **BR-AUTH-F-07.** Un 401 dentro de la conversación, con la sesión ya puesta, no navega, porque
  `/login` ya es la ruta actual. La bienvenida lo detecta y vuelve a E1 con «Tu sesión caducó o
  iniciaste sesión en otro dispositivo.» (RF-BIEN-12).
- **BR-AUTH-F-08.** «Entrar» sigue mostrando su indicador y quedando inactivo mientras espera.
- **BR-AUTH-F-10.** En Android y en iOS, el botón propio dice «Continuar con Google», con el logo
  oficial de `assets/images/google_logo.svg` y los colores de la marca de Google, en lugar de
  «Google» (`login_page.dart:423-429`). En web, `renderButton` recibe un `GSIButtonConfiguration`
  con el texto `continueWith`, el idioma `es`, el tema `outline` en claro y `filledBlack` en
  oscuro, la forma rectangular, el logo a la izquierda y el ancho del compositor hasta 400 px,
  valores que salen de una función pura (decisión B-35 de la bienvenida). La cuenta de web llega a
  la bienvenida por un resultado observable de `LoginController`. Los campos de E1 y E2 comparten
  un `AutofillGroup` (RF-BIEN-6). Los mensajes de error no cambian, y ninguno ofrece crear una
  cuenta (RF-BIEN-9).
- **UI Behavior.** La tarjeta de `login_page.dart` sale, y con ella la frase «La UI ya está
  implementada y no requiere cambios visuales». La pantalla sin sesión es la bienvenida, con sus
  estados de carga, error y éxito en la conversación (RF-BIEN-5 y RF-BIEN-12). «¿Olvidaste tu
  contraseña?» sigue abriendo `/forgot-password`, cuyas pantallas de hoy llevan el sello del logo
  en su cabecera (decisión B-9 y RF-BIEN-20), y «¿No tienes cuenta? Créala» deja su lugar a «Soy
  nuevo» (RF-BIEN-6).
- **Navigation.** El login correcto termina en el paso al horario, con `Get.offAll` a `/home`, sin
  transición y con el argumento de la pestaña Horario (RF-SPL-20 y RF-BIEN-11). Un alumno con la
  configuración a medias hace antes el test en la conversación y termina en el mismo paso al
  horario (decisión B-10 y RF-BIEN-21).
- **Implementation Plan.** `login_controller.dart` deja de navegar, devuelve el resultado a la
  bienvenida y vacía sus campos cuando la bienvenida sale hacia `/home`, y `login_page.dart` sale.
  `login_binding.dart` no reinicia nada dentro del build (RF-BIEN-1). Lo demás del plan de arriba
  ya está hecho y no cambia.
- **Test Links.** Las pruebas de la enmienda son `test/bienvenida/bienvenida_ruta_test.dart`,
  `bienvenida_entrar_test.dart`, `bienvenida_errores_test.dart`,
  `bienvenida_sin_especialidad_test.dart` y `bienvenida_restablecer_test.dart`, y
  siguen `test/HU01_jeff/login_navigation_paths_test.dart` y `login_relogin_regression_test.dart`,
  ajustadas a la bienvenida.
