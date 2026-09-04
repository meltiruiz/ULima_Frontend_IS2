---
name: Portal Sync
description: Carga de ciclo desde miUlima: el alumno escribe su contraseña y el código del authenticator, y el backend inicia sesión en el portal e importa sus datos oficiales.
targets:
  - ../../../lib/pages/portal_sync/**
  - ../../../lib/services/portal_sync_service.dart
  - ../../../lib/models/portal_sync_models.dart
  - ../../../lib/services/api_client.dart
  - ../../../lib/main.dart
  - ../../../lib/pages/home/home_page.dart
  - ../../../lib/pages/home/home_controller.dart
  - ../../../lib/pages/perfil/perfil.dart
  - ../../../pubspec.yaml
  - ../../../test/services/portal_sync_service_test.dart
---

# Portal Sync

> Estado: **implementada el 2026-09-02**, con el diseño ALTERNATIVO (credenciales), no el original de WebView. Ver §Cambio de diseño.

## User Stories

| ID | Description |
| --- | --- |
| HU-SYNC-01 | Como alumno, al empezar un ciclo quiero cargar en ULima++ mis cursos, secciones, horario y avance oficial desde miUlima, sin que nadie los digite. |
| HU-SYNC-02 | Como alumno, quiero repetir la carga durante el ciclo (por ejemplo tras una matrícula complementaria) sin perder mis notas personales ni mi simulación de malla. |

## Requirements

- RS-FE-1: La app detecta cuándo el alumno necesita importar y se lo propone al entrar.
- RS-FE-2: El login de ULima++ **no cambia**. El login en miUlima ocurre solo dentro del flujo de importación.
- RS-FE-3: La app envía la contraseña y el código del authenticator **solo al backend de ULima++**, nunca los guarda y los descarta apenas se usan (ver §Cambio de diseño).
- RS-FE-4: La importación se puede repetir desde Perfil.
- RS-FE-5: Un fallo de la sesión del portal **nunca** cierra la sesión de ULima++.
- RS-FE-6: El alumno da consentimiento informado antes de que se abra el portal.

## Cambio de diseño (2026-09-02)

El diseño original abría un WebView contra `inicio.jsp`, dejaba que el alumno se
logueara en la página real del portal, y la app solo leía las cookies de sesión.
Su gran virtud era que **la contraseña nunca salía del portal**.

Se descartó. Las cookies `JSESSIONID` y `LtpaToken2` son `HttpOnly`, así que la
única vía para leerlas es el almacén nativo vía `CookieManager`, y eso exigía un
spike de verificación contra un iPhone real antes de poder confiar en el
enfoque. **El owner decidió no pagar ese prerrequisito** y optó por el diseño
alternativo que la propia spec contemplaba como plan B.

**Diseño vigente**: la app pide contraseña de miUlima y código del authenticator
en una pantalla propia, y el **backend** hace el login de tres pasos contra el
portal (`POST /portal-sync/import` con `{credentials}`).

**La consecuencia aceptada es que la contraseña pasa por la app y por el
backend.** Por eso RS-FE-3 cambia de sentido y estas reglas son obligatorias:

- La contraseña vive SOLO en el `TextEditingController` de la pantalla. No entra
  en un `Rx` observable, no va a `shared_preferences` ni a `flutter_secure_storage`,
  y no se imprime en ningún `debugPrint`.
- Se limpia apenas se usa (éxito o fallo) y otra vez en `onClose()`, con
  `clear()` antes de `dispose()`.
- **No se manda el usuario**: el usuario del portal es el código del alumno y el
  backend lo saca de `app_user.code` a partir del JWT.
- El código del authenticator se limpia tras un fallo: ya caducó, y así el
  alumno escribe el siguiente sin borrar a mano.

Ya no hay dependencia de `flutter_inappwebview`: el diseño vigente no usa
WebView.


## Business Rules

### BR-SYNC-F-01: Cuándo se propone importar
- Al llegar a `/home` con rol alumno, `HomeController` llama a `GET /portal-sync/status`. Si `needsImport` es `true` se muestra un banner con botón **Cargar ahora** y **Después**.
- El texto del banner depende de `activePeriod`, que el contrato permite `null`: con período → "Carga tus datos del ciclo `<código>` desde miUlima"; sin período → "Carga tus datos del ciclo desde miUlima".
- "Después" oculta el banner solo hasta el próximo arranque: se guarda en memoria en `HomeController`, no en `shared_preferences`.
- Docentes nunca ven el banner ni la opción. Un fallo de `GET /portal-sync/status` no bloquea el Home: se omite el banner en silencio.

### BR-SYNC-F-02: Consentimiento previo
- Antes de abrir el portal se muestra una pantalla con qué datos se importarán (nombre, código, carrera, cursos, secciones, docentes, horario, matrícula, notas históricas, impedimentos), con qué finalidad y que la contraseña nunca sale del portal. Requiere aceptación explícita. Sin aceptación no se abre el WebView.

### BR-SYNC-F-03: Pantalla de credenciales
- Ruta `/portal-sync` con binding por ruta (`PortalSyncBinding`), nunca `Get.put` dentro de `build()`: eso ataría el controller al overlay del snackbar y GetX destruiría sus `TextEditingController`.
- Una sola pantalla con tres estados (`PortalSyncStep`): formulario, cargando y resumen. No son tres rutas: el flujo es lineal y volver atrás a mitad de la carga no le sirve al alumno.
- Reutiliza los widgets públicos de `password_reset_ui.dart` (`PasswordResetScaffold`, `PasswordResetField`, `PasswordResetOtpField`, `PasswordResetPrimaryButton`, `PasswordResetErrorMessage`). Los del login son privados y no se pueden importar.
- El código del authenticator usa `PasswordResetOtpField`, que ya trae seis casillas, teclado numérico, `digitsOnly` y `autofillHints: oneTimeCode`.
- El estado de carga dice qué está pasando y cuánto puede tardar: la importación real toma entre 30 y 50 segundos y sin eso el alumno cree que la app se colgó.


### BR-SYNC-F-04: Importación
- `PortalSyncService.importFromPortal(cookies)` hace `POST /portal-sync/import` con timeout propio de 60 s. `ApiClient` no impone timeout hoy, así que el service envuelve la llamada; sin eso el estado de "timeout" de esta spec no puede producirse.
- Mientras responde, pantalla de progreso "Importando datos de miUlima…".
- Éxito: se muestra el resumen y las advertencias en lenguaje simple.
- Mapeo de errores: `409 PORTAL_SESSION_INVALID` → "La sesión de miUlima expiró, vuelve a iniciar sesión" y se reabre el WebView. `403 PORTAL_IDENTITY_MISMATCH` → "La cuenta de miUlima no corresponde a tu usuario de ULima++", sin reintento. `422 PORTAL_IDENTITY_UNVERIFIABLE` → "No se pudo confirmar tu identidad en el portal". `502`/`504` → "miUlima no responde, inténtalo más tarde".
- Las cookies se descartan de memoria apenas termina la llamada; nunca se guardan en `shared_preferences` ni en `flutter_secure_storage`.

### BR-SYNC-F-05: Un fallo del portal no cierra la sesión de ULima++
- Hoy `ApiClient._send` trata **todo** 401 (salvo `/auth/login`) como expiración del JWT: limpia la sesión y expulsa a `/login`. Por eso el backend devuelve **409** para sesión de portal inválida, y esta spec **no** introduce ningún 401 nuevo.
- `api_client.dart` está en `targets` solo para añadir el timeout configurable por llamada; no se modifica el interceptor de 401.

### BR-SYNC-F-06: Refresco después de importar
Recargar la pantalla no basta; hay tres capas que hay que invalidar en este orden:
1. `AuthService.to.refreshCurrentUser()` (`GET /auth/me`): el nivel, la carrera y el rol del alumno viven en `AuthService.currentUser` y hoy solo se recargan al arrancar la app.
2. Invalidar las cachés de `CoursesService` y `EvaluationSyllabusService`, que cortocircuitan cualquier recarga de `/grades/me/courses`.
3. Recargar los controllers. `MallaListController` está registrado por binding de ruta y admite `Get.find`. `HorarioController` y `CalculadoraController` **no** están registrados por binding sino dentro de `build()`: el refresco debe hacerse con `Get.isRegistered<T>()` antes de `Get.find`, y si no están registrados no se hace nada (la pantalla los creará al abrirse).

### BR-SYNC-F-07: Repetir desde Perfil
- En `ProfilePage`, opción **Actualizar desde miUlima** con el mismo flujo, incluido el consentimiento. Muestra el período activo. No muestra "última carga": el backend no persiste esa fecha.

## UI Behavior

- **Banner en Home**: solo alumnos, solo si `needsImport`. Estados: oculto / visible / "Después" pulsado.
- **PortalSyncConsentPage**: qué se importa, finalidad, aceptar o cancelar.
- **PortalSyncWebViewPage**: loading, página del portal, cierre manual, timeout de 5 min.
- **PortalSyncProgressPage**: progreso, resumen con conteos, lista de advertencias, botón "Listo".
- **Errores**: diálogo con el mensaje de BR-SYNC-F-04 y botón reintentar cuando aplica.

## Data Flow

```
Home → HomeController.checkPortalSync() → PortalSyncService.status() → GET /portal-sync/status
  → needsImport → banner → "Cargar ahora" → PortalSyncConsentPage → acepta
  → PortalSyncWebViewPage (inicio.jsp) → alumno se logea con SecurID
  → onLoadStop en layout.jsp + cookies presentes → CookieManager.getCookies
  → PortalSyncService.importFromPortal(cookies) → POST /portal-sync/import
  → PortalSyncResult → PortalSyncProgressPage → refresco (BR-SYNC-F-06)
```

## API Dependencies

- `GET /portal-sync/status`
- `POST /portal-sync/import`

Ambos con la forma exacta de `docs/specs/api-contracts.md` § Portal Sync. `PortalSyncWarning` mapea `{ code, block, message }`.

## Mock Data Elimination

| File | Status | Reason |
| --- | --- | --- |
| _(ninguno)_ | — | La feature no reemplaza mocks; alimenta PostgreSQL desde el portal. |

## Verification

- `flutter analyze` must pass.
- Test de `PortalSyncService` con `ApiClient` simulado: `status`, `import` exitoso y cada código de error mapeado a su estado, incluido que un 409 **no** dispara cierre de sesión.
- Test de widget del banner: visible solo con `needsImport = true` y rol alumno; texto correcto con `activePeriod = null`; "Después" lo oculta.
- Spike del §Prerrequisito en iPhone real **antes** de escribir el resto.
- Agregar `[@test]` cuando existan los archivos.

## Implementation Plan

1. Spike de cookies en iOS (§Prerrequisito). Si falla, parar y rediseñar.
2. `flutter_inappwebview` en `pubspec.yaml`; verificar compatibilidad con el SDK Dart declarado.
3. `lib/models/portal_sync_models.dart`: `PortalSyncStatus`, `PortalSyncResult`, `PortalSyncWarning`.
4. Timeout por llamada en `api_client.dart` (sin tocar el interceptor de 401).
5. `lib/services/portal_sync_service.dart`.
6. `lib/pages/portal_sync/`: controller, consent, webview y progress; binding por ruta y registro de `/portal-sync` en `main.dart`.
7. Banner en `HomePage`/`HomeController` y entrada en `ProfilePage`.
8. Tests y `flutter analyze`.
