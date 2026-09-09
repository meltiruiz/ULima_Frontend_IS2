---
name: Registro de alumno (HU33)
description: Pantalla de alta de cuenta en ULima++ para un alumno que todavía no existe en la base, autenticando contra miUlima desde la propia app
targets:
  - ../../../lib/pages/registro/**
  - ../../../lib/models/registro_models.dart
  - ../../../lib/services/registro_service.dart
  - ../../../lib/services/auth_service.dart
  - ../../../lib/services/api_client.dart
  - ../../../lib/pages/login/login_page.dart
  - ../../../lib/main.dart
  - ../../../test/HU33_jeff/**
---

# Registro

> Estado: **implementada el 2026-09-08.** Consume `POST /auth/register`, que hoy vive en una rama del backend sin desplegar, así que la pantalla está probada entera contra dobles pero **todavía no contra el portal real**. Es la cara visible de `specs/features/registro/registro.spec.md` del backend (RS-BE-17 y RS-BE-18).

## Contexto

Alguien intentó entrar y no estaba en la base. Los dos caminos de login existentes devuelven `401 USER_NOT_FOUND` y ahí se acaba el recorrido: no hay forma de crear una cuenta desde la app.

El backend ya resolvió el fondo del problema. Quien certifica que una persona es alumno matriculado es **el portal de la Universidad**, no una deducción nuestra ni el dominio del correo, y en el mismo acto entrega los datos con los que la cuenta nace usable. Lo que falta es la pantalla.

### Lo que esta feature NO es

No es un formulario de alta genérico. No pide nombre, ni carrera, ni correo, pero los tres llegan por caminos distintos: el nombre y el código salen del consolidado de matrícula de miUlima, el correo se **deriva** como `<código del portal>@aloe.ulima.edu.pe`, y la carrera es la única que existe hoy en la base — el nombre de carrera del portal solo se compara, y si difiere llega como el warning `CAREER_MISMATCH` sin cambiar nada. Lo único que la persona elige es **su contraseña de ULima++**.

## User Stories

| ID | Description |
| --- | --- |
| HU-REG-01 | Como alumno sin cuenta en ULima++, quiero crearla desde la app usando mis datos de miUlima, para no depender de que alguien me dé de alta. |
| HU-REG-02 | Como alumno que se registra, quiero entender que mi contraseña de ULima++ no es la de la Universidad, para no confundirlas después. |

## Requirements

- RS-FE-1: Desde `/login` se puede llegar a `/registro` y crear una cuenta que queda lista para usarse, sin pasar por ningún canal fuera de la app.
  `[@test] ../../../test/HU33_jeff/registro_service_test.dart`
  `[@test] ../../../test/HU33_jeff/registro_controller_test.dart`
  `[@test] ../../../test/HU33_jeff/registro_page_test.dart`
- RS-FE-2: Las dos contraseñas en juego —la de miUlima y la de ULima++— se piden en pantallas distintas y la de ULima++ se rotula como propia de la app. Nunca se ven las dos a la vez.
  `[@test] ../../../test/HU33_jeff/registro_page_test.dart`
- RS-FE-3: El cliente no agrega ningún camino para averiguar si un código tiene cuenta. Ninguna pantalla anterior al envío consulta al backend por un código, y el registro no se ofrece en función de por qué falló un login. Ver §Deuda conocida: el endpoint ya es distinguible por sí mismo, y eso no se arregla desde acá.
  `[@test] ../../../test/HU33_jeff/registro_controller_test.dart`
- RS-FE-4: Ningún fallo del registro cierra sesiones, navega fuera de la pantalla ni muestra un mensaje que no describa lo que pasó.
  `[@test] ../../../test/HU33_jeff/api_client_401_test.dart`
- RS-FE-5: Si el cliente no puede saber si la cuenta quedó creada, lo dice con esas palabras y ofrece iniciar sesión. Nunca afirma que el registro falló cuando no lo sabe.
  `[@test] ../../../test/HU33_jeff/registro_controller_test.dart`
- RS-FE-6: Las credenciales de miUlima viven solo en los `TextEditingController` de la pantalla y no sobreviven a salir de ella.
  `[@test] ../../../test/HU33_jeff/registro_controller_test.dart`

## Business Rules

### BR-REG-F-01: Dos pasos, y el authenticator es el último campo

El alta se reparte en dos pantallas: primero los datos de ULima++ (código, contraseña, repetir), después la verificación contra miUlima (contraseña del portal, código del authenticator).

El orden no es estético. El código del authenticator **cambia cada 30 segundos**, y tipear una contraseña dos veces toma más que eso. Con el orden inverso —miUlima primero— el código estaría vencido al llegar el POST, el backend respondería `401 PORTAL_AUTH_FAILED`, que es deliberadamente indistinguible de "contraseña mala", y la persona se iría convencida de que se equivocó de contraseña universitaria. Poniendo el authenticator inmediatamente antes del botón que envía —igual que hace `PortalSyncPage`— el problema desaparece.

### BR-REG-F-02: El paso 1 no habla con el backend

Sería cómodo adelantar el `409 USER_ALREADY_EXISTS` preguntando "¿existe este código?" al terminar el paso 1. **Está prohibido.** Ese endpoint sería un oráculo de enumeración de cuentas: cualquiera podría averiguar quién usa ULima++ tecleando códigos. Es exactamente lo que `AuthService.loginErrorMessage` evita hoy al aplastar `USER_NOT_FOUND` e `INVALID_PASSWORD` en un mismo mensaje.

Por la misma razón el registro **no se ofrece de forma reactiva** cuando un login falla: mostrar "¿creamos tu cuenta?" solo cuando el código no existe delata lo mismo por otra puerta. El acceso es un enlace fijo bajo el login, junto a "¿Olvidaste tu contraseña?".

### BR-REG-F-03: Validar en local antes de gastar cupo

El backend limita el registro a **5 intentos por código por hora**, y ese contador corre **antes** de validar el cuerpo. Peor: el limitador aplica `.trim()` al código para usarlo de clave, pero el esquema de validación no lo hace y su regex está anclada. Un código con espacios consume cupo y después recibe `400`. Cinco envíos así dejan a la persona bloqueada una hora sin haber intentado ni un login.

Por eso el cliente valida antes de enviar, y envía el código ya recortado:

- código: `^\d{6,10}$` sobre el valor recortado — el mismo rango que `registerSchema`, ni más ni menos.
- contraseña de ULima++: `validateNewPassword` (mínimo 8) y `validatePasswordConfirmation`, los validadores que ya usa el reset. El backend acepta cualquier cosa (`z.string().min(1)`) y lo declara deuda consciente; el frontend ya exige 8 al restablecer, así que pedir menos al crear dejaría una cuenta que no puede recuperar su propia contraseña.
- contraseña de miUlima: no vacía. La forma la decide el portal, no nosotros.
- authenticator: `^\d{6,8}$` sobre el valor recortado — el mismo rango que ya valida `PortalSyncController`, y por el mismo motivo. SecurID entrega 6 dígitos de tokencode y 8 cuando el PIN va delante, así que exigir exactamente 6 rechazaría un passcode legítimo. Además `PasswordResetOtpField` **no** recorta el texto: se le quitó el `LengthLimitingTextInputFormatter` para arreglar el borrado en iOS y el recorte a 6 ocurre solo al pintar. Un validador de exactamente 6 mostraría seis casillas correctas junto a un error incomprensible.

### BR-REG-F-04: Un 401 del registro no es una sesión expirada

`ApiClient._send` trata **cualquier** 401 que no venga de `/auth/login` como caducidad de sesión: borra la sesión, llama a `offAllToLogin()` y muestra el snackbar "Sesión expirada".

`POST /auth/register` responde `401 PORTAL_AUTH_FAILED` en su fallo **más común** —contraseña de miUlima mal tipeada o código del authenticator vencido—. Sin arreglar esto, esa persona vería su pantalla de registro destruida, aterrizaría en el login y leería que su sesión caducó, cuando nunca tuvo una.

`/auth/register` se suma por lo tanto a la exención que hoy tiene `/auth/login`, en la condición externa, para que no se limpie sesión **ni** se navegue.

La exención por ruta no basta, y por eso `api_client.dart` recibe una segunda modificación: `getJson` y `_send` aceptan `suppressSessionExpiry`, que apaga ese tratamiento **para una llamada concreta**. Los catálogos que `adoptarSesion` carga después del 201 (`/academic-profile/careers` y `/academic-profile/specialties`) no pueden eximirse por ruta, porque los mismos endpoints, llamados desde un login normal, sí deben cerrar la sesión ante un 401. Lo que cambia no es la ruta sino el momento (§BR-REG-F-10). Las dos modificaciones juntas son requisito para que RS-FE-4 se cumpla.

### BR-REG-F-05: El reintento cuesta seis dígitos

Tras un fallo del portal se vuelve al paso de verificación con el **passcode borrado y la contraseña de miUlima intacta**: lo que casi siempre venció es el código, y obligar a reescribir la contraseña alarga el reintento justo hasta que el código nuevo también vence. Es la misma decisión que ya tomó `PortalSyncController`.

Un `409 USER_ALREADY_EXISTS` es la excepción: vuelve al paso 1, porque lo que hay que revisar es el código.

Moverse entre pasos —hacia adelante, hacia atrás o por un error— **nunca borra lo tipeado**. Lo único que se borra es el passcode, y solo cuando un envío falló. Los cuatro campos viven en `TextEditingController` del controller, que sobrevive a los cambios de estado porque la ruta es una sola.

### BR-REG-F-06: La identidad la pone el portal

El `code` que la persona tipea sirve **solo para entrar a miUlima**. La cuenta se crea con el código que devuelve el portal, y si difieren gana el del portal. En consecuencia el `user.code` de la respuesta puede no ser el que se envió, y todo lo que el cliente guarde o muestre después —`StorageService.saveCode`, el nombre del resumen— sale de la respuesta, nunca de lo tecleado.

### BR-REG-F-07: Un 201 con avisos es un éxito

La respuesta trae `warnings` con el mismo shape que la importación (`code`, `block`, `message`). Un registro perfectamente válido puede traerlos: sílabos caídos, el panel de delegados fuera de servicio, `CAREER_MISMATCH`. Se muestran en el resumen como información, con el `message` tal cual, y **no** convierten el alta en un fallo.

### BR-REG-F-08: El plazo es de 120 segundos y su vencimiento no es un fallo

`ApiClient` no impone ningún timeout: `request.send()` corre sin plazo, así que sin uno propio la pantalla quedaría colgada para siempre. El plazo lo pone `RegistroService`, igual que `PortalSyncService` pone el suyo.

Son **120 segundos**, más que los 90 de la importación, porque el registro hace todo lo que hace la importación —incluido el login contra el portal— y además crea la cuenta. El tope real no lo pone el cliente sino la plataforma, que corta la función a los 300 segundos.

Que el plazo venza **no prueba que el registro falló**: el servidor pudo haber confirmado la transacción mientras el cliente dejaba de esperar. Decir "no se pudo crear tu cuenta" en ese caso sería mentir, y la persona reintentaría contra un `409`. De ahí RS-FE-5 y el estado `incierto`.

Se evaluó sondear con un `login` silencioso para deshacer la ambigüedad, y se descartó: un sondeo lanzado antes de que la transacción confirme responde `USER_NOT_FOUND` y mentiría en la dirección contraria, que es la peor de las dos.

Un fallo de red crudo —que `ApiClient` propaga sin envolver— sí se trata como fallo normal, porque lo habitual es que la petición no haya llegado. La distinción es imperfecta y se asume a conciencia.

### BR-REG-F-09: No se sale mientras se envía

Durante el envío la pantalla bloquea el retroceso con `PopScope(canPop: false)`. Cubre a la vez el gesto del sistema y el botón de volver que `PasswordResetScaffold` dibuja siempre —un `IconButton` que llama a `maybePop()` y que no se puede ocultar—. Salir a mitad del envío produce exactamente el estado que RS-FE-5 existe para evitar: una cuenta creada que su dueño no sabe que tiene.

### BR-REG-F-10: Después del 201 nada puede volverse un error

Recibido el 201, la cuenta **existe**. Lo que el cliente haga después —guardar el token, cargar catálogos de carrera y especialidad, fijar el usuario— no puede convertirse en un mensaje de fallo.

La carga de catálogos va con `suppressSessionExpiry: true` y no es opcional. Sin eso, un `401` de `/academic-profile/careers` recorre el camino genérico de `ApiClient`: borra el token guardado cuatro líneas antes, arranca `/registro` de la pila con `offAllToLogin()` y anuncia «Sesión expirada» a alguien cuya cuenta nació hace un segundo. El efecto ocurre **dentro** de `ApiClient`, antes de que `adoptarSesion` vea la excepción, así que atraparla no lo desharía: hay que impedirlo en el origen.

La carga de catálogos se reintenta **una vez** y, si vuelve a fallar, se sigue adelante igual. Pero el fallo no se cura solo, y conviene decirlo: `_loadCatalogs` es privado y solo corre en `tryRestoreSession`, `login` y `finishGoogleLogin`, así que la persona aterrizaría en `/setup-carrera` —justo la pantalla que consume esas dos listas— con la carrera en blanco y sin especialidades que elegir hasta el próximo arranque de la app. Se asume a conciencia: el asistente sigue siendo completable, y ninguna alternativa justifica convertir un 201 en un error. Curarlo del todo es trabajo de `/setup-carrera`, no de esta feature.

Es el reflejo en el cliente de la regla del backend: nada posterior al commit puede terminar en error, porque la persona reintentaría y el `409` le cerraría el paso.

### BR-REG-F-11: De `incierto` siempre se sale

`incierto` no es un final. Tiene dos salidas y las dos están definidas:

**`Iniciar sesión`** llama a `AuthService.login` desde la propia pantalla, con el código que se envió y la contraseña de ULima++ que la persona acaba de elegir. Si entra, la cuenta existía: `Get.offAllNamed(postLoginRoute(user))` y se acabó la ambigüedad.

Si el login falla, **no se concluye que la cuenta no existe**. Puede no existir, pero también puede existir bajo el código que devolvió el portal, que gana sobre el tecleado (§BR-REG-F-06) — y entonces el login con el código tecleado falla aunque la cuenta esté ahí. Se sigue en `incierto` y el texto cambia a algo accionable: volver a intentar el registro, y si esta vez responde «ya existe una cuenta con ese código», eso **confirma** que sí se creó y el camino es recuperar la contraseña desde el login. El `409` deja de ser un obstáculo y pasa a ser la respuesta.

`AuthService.login` solo atrapa `ApiException`: un socket caído sale crudo. Y a `incierto` se llega casi siempre **por** una red mala, así que la pantalla tiene que contar con que siga mala al pulsar el botón. Ese fallo se atrapa en el controller y se responde «No hay conexión. Revisa tu internet e inténtalo de nuevo.»; dejarlo escapar borraría el texto rojo sin poner nada en su lugar y el botón no haría nada visible. Mientras el intento está en vuelo el botón queda en `loading`, que a la vez acusa recibo y bloquea el segundo toque: `paso` sigue en `incierto` durante todo el `await` y no sirve de guarda.

**`Volver a intentar`** regresa a `verificar` con el passcode borrado y la contraseña de miUlima intacta, como cualquier otro reintento.

Retener la contraseña de ULima++ en memoria mientras dura este estado es deliberado: es lo que hace posible la primera salida. Muere con la pantalla, igual que las credenciales del portal (§RS-FE-6).

## UI Behavior

Una sola ruta, `/registro`, con **cinco estados** en la misma pantalla — el patrón de `PortalSyncPage`, que resuelve tres estados sin tres rutas. Toda la pantalla se compone con el kit público de `password_reset_ui.dart`.

- **`datos`** — «Crea tu cuenta de ULima++». Código, contraseña, repetir contraseña. Nota bajo los campos: con esta contraseña entrarás al app. Botón `Continuar`. Enlace secundario para volver al login.
- **`verificar`** — «Verificamos que eres alumno». Texto que explica que entramos a miUlima una vez y no guardamos los datos. Contraseña de miUlima (con mostrar/ocultar) y `PasswordResetOtpField` de 6 dígitos. Botón `Crear mi cuenta`. Enlace para volver al paso anterior.
- **`enviando`** — spinner a pantalla completa, «Creando tu cuenta…», con la advertencia de que puede tomar un par de minutos y no cerrar la app. Sin salida. El título habla de lo que la persona pidió, no del paso interno que estemos dando: entrar a miUlima es un medio, y nombrarlo invita a creer que se está iniciando sesión en el portal.
- **`listo`** — ícono de éxito, «Listo, *nombre*», el conteo de cursos cargados del `summary`, los `warnings` si los hay, y un botón que entra a la app.
- **`incierto`** — dos títulos, según lo que de verdad se sepa. Con el plazo vencido, «No pudimos confirmar si tu cuenta se creó», y explica que puede haberse creado igual. Con `SIN_TOKEN` el `201` ya llegó y la cuenta existe, así que el título es «Tu cuenta ya está creada» y lo que se explica es que falló dejar la sesión puesta: titular duda sobre un texto que afirma la creación se contradice hacia el lado que sabe menos. El mensaje de error no se pinta cuando repite la frase del título. Dos salidas, ambas definidas en §BR-REG-F-11: `Iniciar sesión`, que lo intenta ahí mismo, y `Volver a intentar`, que regresa a `verificar`.

Los errores se muestran con `PasswordResetErrorMessage` bajo el formulario del paso correspondiente. El botón no se deshabilita por validación —`PasswordResetPrimaryButton.onPressed` no admite `null` y solo se apaga con `loading: true`—, así que la validación ocurre al pulsar.

## Data Flow

```
/login  ──「Crea tu cuenta」──▶  /registro
   │
   ├─ datos      validación local (código, contraseña, confirmación) · sin red
   │     └─ Continuar ──▶ verificar
   │
   ├─ verificar  validación local (contraseña del portal, 6 dígitos)
   │     └─ Crear mi cuenta ──▶ enviando
   │
   └─ enviando   RegistroService.registrar()
                   POST /auth/register {code, portalPassword, passcode, password}
                   .timeout(120 s)
         │
         ├─ 201 ──▶ AuthService.adoptarSesion(token, user)
         │            saveToken · saveCode(user.code del portal)
         │            catálogos (tolerante a fallo) · currentUser
         │          ──▶ listo ──「Entrar」──▶ Get.offAllNamed(postLoginRoute(user))
         │
         ├─ ApiException ──▶ mensaje según `code` ──▶ datos | verificar
         ├─ TimeoutException ──▶ incierto
         │        ├─「Iniciar sesión」──▶ AuthService.login(code, password)
         │        │        ├─ entra ──▶ Get.offAllNamed(postLoginRoute(user))
         │        │        └─ falla ──▶ incierto, con texto accionable
         │        └─「Volver a intentar」──▶ verificar · passcode borrado
         └─ error de red crudo ──▶ verificar · «No hay conexión»
```

Una cuenta recién creada llega con `setupComplete: false`, así que `postLoginRoute` la manda a `/setup-carrera`. Es el destino correcto: todavía no eligió especialidades.

## API Dependencies

`POST /auth/register` — pública, sin token, responde **201**.

Request: `{ "code": "20230001", "portalPassword": "…", "passcode": "123456", "password": "…" }`

Response `201`: `{ token, tokenType, expiresIn, user, summary, warnings }` — plano. **No** tiene los `period` ni `identity` anidados de `POST /portal-sync/import`, así que `PortalSyncResult` no sirve; `PortalSyncSummary` y `PortalSyncWarning` sí se reutilizan tal cual.

Errores, con el mensaje que ve la persona y a qué paso vuelve:

| Código | HTTP | Mensaje | Vuelve a |
| --- | --- | --- | --- |
| `USER_ALREADY_EXISTS` | 409 | Ya existe una cuenta con ese código. Inicia sesión o recupera tu contraseña. | `datos` |
| `PORTAL_AUTH_FAILED` | 401 | miUlima rechazó los datos. Revisa tu contraseña del portal y que el código del authenticator siga vigente. | `verificar` |
| `PORTAL_SESSION_INVALID` | 409 | La sesión de miUlima se cortó mientras cargábamos. Inténtalo de nuevo. | `verificar` |
| `NOT_ENROLLED` | 403 | miUlima no reporta matrícula en el ciclo actual, así que todavía no podemos crear tu cuenta. No hace falta que lo intentes de nuevo ahora. | `verificar` |
| `PORTAL_IDENTITY_UNVERIFIABLE` | 422 | No pudimos leer tu matrícula en miUlima. | `verificar` |
| `PORTAL_TIMEOUT` | 504 | miUlima tardó demasiado en responder. Inténtalo más tarde. | `verificar` |
| `PORTAL_UNAVAILABLE` | 502 | miUlima no está respondiendo. Inténtalo más tarde. | `verificar` |
| `RATE_LIMITED` | 429 | El `message` del backend tal cual: ya viene en español. | `verificar` |
| `REGISTRATION_UNAVAILABLE` | 503 | El registro no está disponible por ahora. Vuelve a intentarlo más tarde. | `verificar` |
| `INVALID_REQUEST_BODY`, `INVALID_JSON_BODY` | 400 | Revisa tus datos: el código debe tener entre 6 y 10 dígitos. | `datos` |
| `INTERNAL_ERROR`, `INTERNAL_SERVER_ERROR` | 500 | Algo falló de nuestro lado. Inténtalo de nuevo. | `verificar` |
| cualquier otro | — | El `message` del backend si no viene vacío; si no, un genérico. | `verificar` |

**La columna «Vuelve a» dice dónde aterriza la persona, no que reintentar sirva.** Esta tabla decía antes solo qué salió mal, y esa era una versión incompleta del contrato: el paso `verificar` tiene un único botón, rotulado «Crear mi cuenta», y cada pulsada gasta uno de los cinco intentos por hora que el backend concede por código —los gasta incluso cuando el rechazo es previo, porque el contador corre antes de validar el cuerpo—. Un mensaje que solo describe el problema deja la pantalla leyéndose como un formulario que hay que corregir, y quien lee «miUlima no reporta matrícula en el ciclo actual» reescribe el passcode y vuelve a pulsar hasta quedar bloqueado una hora; el quinto mensaje le dirá que espere 42 minutos.

Por eso, cuando el reintento inmediato **no puede** funcionar, el mensaje lo dice. `NOT_ENROLLED` cierra con «No hace falta que lo intentes de nuevo ahora» —la matrícula no aparece porque no existe, no porque se haya tecleado mal—, y `REGISTRATION_UNAVAILABLE` con «Vuelve a intentarlo más tarde», que es la forma correcta para algo apagado del lado del servidor y que se enciende solo. `PORTAL_TIMEOUT` y `PORTAL_UNAVAILABLE` ya terminaban en «Inténtalo más tarde» y se quedan como están. A `RATE_LIMITED` no se le agrega nada: sus dos limitadores ya dicen cuánto esperar y cualquier añadido nuestro chocaría con uno de los dos.

Lo que **no** se hace es mandar esos códigos a otro estado. Un sexto estado para «no reintentes» duplicaría la máquina por un caso de texto, y el destino honesto sigue siendo `verificar`: la persona está ahí, con sus datos, y puede salir de la pantalla cuando quiera.

Los dos códigos de 400 y el `INTERNAL_SERVER_ERROR` traen su `message` **en inglés**; por eso se traducen acá en vez de mostrarse crudos. Hay dos códigos distintos de 500 porque `register` es el único método del módulo sin traductor de errores de base de datos; ambos se contemplan.

Detrás de `RATE_LIMITED` hay **dos** limitadores montados en la misma ruta, y por eso se muestra el `message` crudo y no se lee `details`: el de por código (5 por hora) da los minutos exactos y pone `retryAfterMinutes`, mientras que el de concurrencia (4 registros en vuelo) dice solo «en unos segundos» y pone `retryAfterSeconds`. Leer una clave fija daría `null` la mitad de las veces.

⚠️ El endpoint todavía no está desplegado. Vive en el PR #1 del backend. La pantalla se puede construir y probar entera contra dobles, pero el primer registro real necesita que ese PR aterrice.

## Mock Data Elimination

| Mock | Estado |
| --- | --- |
| _(ninguno)_ | Esta feature nace consumiendo PostgreSQL a través del backend. |

## Verification

- `flutter analyze` sin nuevos warnings.
- `flutter test` en verde.
- Tests nuevos en `test/HU33_jeff/`, siguiendo la convención del repo —dobles escritos a mano con `extends` + `@override`, sin mockito—: el mapeo de errores código por código, las transiciones entre los cinco estados, los validadores locales, el parseo de la respuesta y el borrado de credenciales al cerrar la pantalla.
- Los enlaces `[@test]` se agregan cuando los archivos existan; el repo prohíbe enlazar tests que todavía no se escribieron.
- Verificación manual pendiente de que `POST /auth/register` esté desplegado: un registro real con una cuenta que no esté en la base.

## Implementation Plan

1. `lib/services/api_client.dart` — eximir `/auth/register` del tratamiento genérico del 401 (BR-REG-F-04). Es el arreglo del que dependen los demás pasos.
2. `lib/models/registro_models.dart` — `RegistroResult` (token, `UserModel`, `PortalSyncSummary`, `List<PortalSyncWarning>`) y `RegistroFailure` (mensaje ya redactado + `code` opcional).
3. `lib/services/registro_service.dart` — `ApiClient` inyectable por constructor, como `PortalSyncService`, porque `AuthService` crea el suyo inline y no se puede sustituir en tests. El mapeo de errores va **público y estático**, al estilo de `AuthService.loginErrorMessage`, para poder probarlo directo; el de portal-sync es privado y sus tests tienen que llegar a él dando un rodeo.
4. `lib/services/auth_service.dart` — `adoptarSesion(token, userJson)`: lo mismo que hace `login()` después de recibir la respuesta, con la carga de catálogos tolerante a fallo (BR-REG-F-10).
5. `lib/pages/registro/` — controller con los cinco estados, binding por ruta con `lazyPut` (para que `onClose` borre las credenciales) y página compuesta con el kit de `password_reset_ui.dart`, envuelta en `PopScope`.
6. `lib/main.dart` — `GetPage('/registro')` con su binding.
7. `lib/pages/login/login_page.dart` — enlace fijo «Crea tu cuenta», junto al de contraseña olvidada.
8. Tests en `test/HU33_jeff/`.
Los pasos 9 y 10 —documentar el endpoint en `docs/specs/api-contracts.md`, tanto en `## Auth` como en la enumeración cerrada de rutas públicas de `## Principios Globales`, y agregar la fila al `docs/specs/feature-index.md`— **ya están hechos** en el mismo cambio que trae esta spec. No hay que rehacerlos.

## Deuda conocida

**El endpoint distingue por sí mismo si un código tiene cuenta, y esta feature no puede arreglarlo.** El backend comprueba `codeExists` *antes* de tocar el portal, así que un `409` vuelve en milisegundos con credenciales inventadas, mientras que cualquier otro desenlace cuesta una secuencia completa de login contra miUlima. La diferencia se nota en el código de respuesta y también en el tiempo.

El límite de 5 intentos por código por hora **no** cierra esto: averiguar si un código concreto tiene cuenta cuesta una sola petición, y el tope es por código, así que barrer muchos códigos distintos sigue siendo barato. Es una propiedad del endpoint, no de la pantalla; RS-FE-3 se limita por eso a lo que el cliente sí controla. Corregirlo —igualar tiempos y respuesta, o mover la comprobación después del login del portal— es trabajo de la spec del backend y queda anotado en su PR.

**El contador por código se consume aunque el rechazo venga del limitador de concurrencia.** Los dos middlewares corren en orden y el de código incrementa antes de que el de concurrencia pueda rechazar, así que un salón entero registrándose a la vez gasta cupo recibiendo «hay demasiados registros en curso, intenta en unos segundos» — un mensaje que invita a reintentar justo lo que agota el cupo. También es del backend.
