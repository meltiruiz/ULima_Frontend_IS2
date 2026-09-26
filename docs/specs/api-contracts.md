# API Contracts

Contrato REST local del frontend ULima++. Mantener alineado manualmente con `ULima_Backend_IS2/docs/specs/api-contracts.md`.

## Reglas

- Todo endpoint, payload, respuesta, error o permiso debe actualizarse aquí antes de implementar frontend.
- Las specs frontend deben referenciar este archivo.
- PostgreSQL definitivo es la fuente de verdad a través del backend.
- No existe fallback final a JSON.
- Cada sección debe ser refinada por la spec de feature antes de implementar.

## Principios Globales

- Todas las rutas, salvo `GET /`, `GET /health`, `POST /auth/login`, `POST /auth/register`, `POST /auth/google`, `POST /auth/password-reset/request` y `POST /auth/password-reset/confirm`, usan `Authorization: Bearer <token>`.
- El usuario autenticado es estudiante **o docente** (HU18).
- Roles permitidos: `student`, `delegate`, `subdelegate`, `teacher`.
- `teacher` es el rol técnico compartido por profesor y jefe de práctica (JP); su etiqueta se deriva de `section.teacher_id` vs `section.jp_id`. El JWT docente lleva `teacherId` en vez de `studentId`.
- IDs numéricos pueden viajar como number o string según DTO final aprobado; cada spec debe fijarlo antes de implementar.
- Errores siguen forma general:

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable message",
    "details": {}
  }
}
```

## Auth

## Public

- `GET /`
  - Response: metadata básica del backend y módulos disponibles.
- `GET /version`
  - Response: `{ "commit": "string", "ref": "string|null", "deployment": "string|null" }`
  - Expone el commit desplegado (Vercel inyecta `VERCEL_GIT_COMMIT_SHA`).
- `GET /health`
  - Response: `{ "status": "ok", "timestamp": "ISO-8601 string" }`

## Auth

- `POST /auth/login`
  - Request: `{ "code": "string", "password": "string" }`
  - Response: `{ "token": "string", "tokenType": "Bearer", "expiresIn": 86400, "user": User }`
  - HU18: si el `code` no es de un `student` pero sí de un `teacher` (vía `teacher.user_id`), inicia sesión como docente. El `user` docente es `{ id, teacherId, code, fullName, institutionalEmail, role: "teacher", teacherLabel: "Profesor"|"Jefe de Práctica", setupComplete: true }` (sin `studentId`). No exige matrícula activa.
- `POST /auth/register`
  - Público, sin token. Responde `201`.
  - Request: `{ "code": "string", "portalPassword": "string", "passcode": "string", "password": "string", "consent"?: true }`
  - `code` es `^\d{6,10}$`. `portalPassword` y `passcode` son de **miUlima**: se usan para entrar al portal y se descartan; no se persisten ni se registran en logs. `password` es la que la persona quiere para ULima++.
  - `consent` (RS-BE-29) es opcional y la app lo manda solo tras «Acepto» en la pantalla de consentimiento (RF-REC-6). Sin él la cuenta se crea igual, pero no se guarda el récord. Nunca `false`.
  - Response `201`: `{ "token": "string", "tokenType": "Bearer", "expiresIn": 86400, "user": User, "summary": ImportSummary, "warnings": SyncWarning[] }`
  - `summary` y `warnings` tienen la misma forma que en `POST /portal-sync/import`, pero **planos**, sin `period` ni `identity`. Un `201` con `warnings` no vacío es un éxito.
  - La identidad la pone el portal: el `code` enviado sirve solo para el login, y `user.code` puede diferir de él.
  - Errores: `409 USER_ALREADY_EXISTS`, `401 PORTAL_AUTH_FAILED`, `409 PORTAL_SESSION_INVALID`, `403 NOT_ENROLLED`, `422 PORTAL_IDENTITY_UNVERIFIABLE`, `504 PORTAL_TIMEOUT`, `502 PORTAL_UNAVAILABLE`, `429 RATE_LIMITED` (5 intentos por código por hora, y 4 registros simultáneos), `503 REGISTRATION_UNAVAILABLE`, `400 INVALID_REQUEST_BODY`, `400 INVALID_JSON_BODY`, `500 INTERNAL_ERROR`, `500 INTERNAL_SERVER_ERROR`.
  - Igual que en `POST /auth/login`, su `401` **no** significa sesión caducada: `ApiClient` exime a ambas rutas del cierre de sesión automático.
- `POST /auth/google`
  - Request: `{ "idToken": "string" }`
  - Acepta `@aloe.ulima.edu.pe` para cuentas vinculadas a `student.user_id` y `@ulima.edu.pe` para cuentas vinculadas a `teacher.user_id`. No crea cuentas ni perfiles.
  - Response: `{ "token": "string", "tokenType": "Bearer", "expiresIn": 86400, "user": User }`. El alumno conserva su shape y reglas de matrícula/representación. El docente recibe el mismo shape y JWT docente de `POST /auth/login`, sin exigir matrícula.
  - En ambos casos se vincula `app_user.google_id` y se incrementa `tokenVersion`; el login con código/contraseña sigue disponible.
  - Errores: `401 INVALID_TOKEN`, `401 USER_NOT_FOUND`, `403 INVALID_DOMAIN`; `403 NOT_ENROLLED` solo para alumnos.
- `GET /auth/me`
  - Response: `{ "user": User }`
- `POST /auth/logout`
  - Response: `{ "message": "Session closed" }`
- `POST /auth/password-reset/request` (público)
  - Request: `{ "identifier": "string" }` (código de alumno o correo institucional)
  - Response (siempre `200`, exista o no la cuenta): `{ "message": "Si la cuenta existe, enviamos un código a tu correo institucional." }`
- `POST /auth/password-reset/confirm` (público)
  - Request: `{ "identifier": "string", "code": "string", "newPassword": "string" }`
  - Response `200`: `{ "message": "Contraseña actualizada correctamente." }`
  - Errores: `400 WEAK_PASSWORD` (menos de 8 caracteres), `400 INVALID_RESET_CODE` ("Código inválido o expirado.", genérico a propósito)
- `POST /auth/password-reset/request-me` (Bearer token)
  - Response `200`: `{ "message": "Enviamos un código a tu correo institucional.", "email": "2023****@aloe.ulima.edu.pe" }`

`User` mínimo:

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
  "currentLevel": 5,
  "setupComplete": false,
  "specialties": [
    { "specialtyId": 1, "name": "Ingeniería de Software", "selectionType": "primary" }
  ]
}
```

Errores de login con código: `401 USER_NOT_FOUND`, `401 INVALID_PASSWORD`, `403 NOT_ENROLLED`. Errores adicionales de Google: `401 INVALID_TOKEN`, `403 INVALID_DOMAIN`.

## Academic Profile

### GET /academic-profile/me

Perfil completo del estudiante autenticado.

- **Auth**: Bearer token
- **Response** `200 OK`:
  ```json
  {
    "profile": {
      "id": 1,
      "studentId": 10,
      "code": "20201234",
      "fullName": "Nombre Apellido",
      "institutionalEmail": "user@aloe.ulima.edu.pe",
      "role": "student",
      "currentLevel": 5,
      "career": {
        "id": 1,
        "code": "ING-INF",
        "name": "Ingeniería de Sistemas",
        "faculty": "Facultad de Ingeniería"
      },
      "curriculum": {
        "id": 1,
        "name": "Currículo 2023"
      },
      "specialties": [
        { "specialtyId": 1, "name": "Ingeniería de Software", "selectionType": "primary" },
        { "specialtyId": 2, "name": "Ciencia de Datos", "selectionType": "interest" }
      ]
    }
  }
  ```
- **Errors**: `401` `MISSING_TOKEN`, `401` `INVALID_TOKEN`, `404` `USER_NOT_FOUND`

### GET /academic-profile/careers

- **Auth**: Bearer token
- **Response** `200 OK`:
  ```json
  {
    "careers": [
      { "id": 1, "code": "ING-INF", "name": "Ingeniería de Sistemas", "faculty": "Facultad de Ingeniería" }
    ]
  }
  ```

### GET /academic-profile/specialties

- **Auth**: Bearer token
- **Query**: `?careerId={id}` (opcional)
- **Response** `200 OK`:
  ```json
  {
    "specialties": [
      { "id": 1, "careerId": 1, "name": "Ingeniería de Software", "description": "..." }
    ]
  }
  ```
- **Campos que la app lee.** El backend manda además `carrera_id`, `is_active` y `display_order` (`findSpecialtiesByCareerId` del backend), y la app lee `id`, `carrera_id`, `name`, `description`, `is_active` y `display_order` (`setup_carrera_controller.dart` y `perfil.dart`).
- **Solo lo oficial** *(aprobado el 2026-09-25 con la spec del test de especialidad, BR-AP-07 de la spec de Academic Profile del backend, pendiente de implementar)*. Con `careerId` y sin él, la lista trae solo las especialidades con `is_active = true`, que en Ingeniería de Sistemas son los cuatro diplomas oficiales. `is_active` sigue en cada elemento, ahora siempre `true`, y `display_order` se numera después del filtro. La app conserva su filtro `is_active == true` como defensa (RF-TEST-14 de `specs/features/specialty-test/specialty-test.spec.md`).

### PUT /academic-profile/me/specialties

Reemplaza las especialidades activas del estudiante autenticado. Escribe en `student_specialty`.

- **Auth**: Bearer token
- **Request body**:
  ```json
  {
    "primarySpecialtyId": 1,
    "interestSpecialtyIds": [2, 3]
  }
  ```
- **Response** `200 OK`:
  ```json
  {
    "message": "Specialties updated",
    "specialties": [
      { "specialtyId": 1, "selectionType": "primary" },
      { "specialtyId": 2, "selectionType": "interest" }
    ]
  }
  ```
- **Errors**: `400` `INVALID_BODY`, `404` `SPECIALTY_NOT_FOUND`, `409` `DUPLICATE_PRIMARY`
- **Solo lo oficial y reemplazo atómico** *(aprobado el 2026-09-25 con la spec del test de especialidad, BR-AP-07 y BR-AP-08 del backend, pendiente de implementar)*. `404 SPECIALTY_NOT_FOUND` también para una especialidad que existe pero tiene `is_active = false`, con el mismo mensaje que una de otra carrera. El desactivado, los `upsert` y la marca de `specialty_setup_completed` corren en una sola transacción. La forma de la ruta no cambia. La app nunca manda un id que no esté en el catálogo oficial (RF-TEST-14) y usa esta ruta para «Elegir como principal» y para los corazones del resultado del test (RF-TEST-9).

Notas:

- No existe endpoint para cambiar carrera/curriculum en v1.

## Curriculum

- `GET /curriculum/me`
- `PUT /curriculum/me/simulation`
- `DELETE /curriculum/me/simulation/:curriculumCourseId`

Notas:

- Progreso real viene de `student_course_progress`.
- Cursos actuales vienen de `enrollment.status = 'active'`.
- Simulación visual viene de `student_curriculum_simulation`.
- La simulación no escribe `student_course_progress`, `enrollment` ni `student_score`.

## Grades

- `GET /grades/me/courses` — **IMPLEMENTADO**. Devuelve cursos + evaluaciones del sílabo con sus pesos.
- `POST /grades/me/calculate` — **IMPLEMENTADO**. Calcula el promedio ponderado en el backend.
- `GET /grades/me/notes` — **IMPLEMENTADO**. Recupera notas guardadas del alumno desde `student_score`.
- `POST /grades/me/notes` — **IMPLEMENTADO**. Guarda notas del alumno en `student_score` (upsert).
- ~~`PUT /grades/me/scores`~~ — **NO IMPLEMENTADO** (reemplazado por `POST /grades/me/notes`).
- ~~`GET /grades/me/courses/:sectionId/average`~~ — **NO IMPLEMENTADO** (el cálculo se hace vía `POST /grades/me/calculate`).

Notas:

- `student_score` es la tabla de persistencia de notas personales del alumno.
- El cálculo de promedio ponderado y la persistencia de notas se delegan al backend.
- `POST /grades/syllabi` queda fuera de v1 salvo spec aprobada; la tabla `syllabus` ya existe.

## Schedule

### GET /schedule/me/sessions
Retorna el horario semanal por bloques de tiempo para las secciones donde el estudiante se encuentra matriculado activamente.
- **Auth**: Bearer token
- **Response** `200 OK`:
  ```json
  {
    "days": [
      {
        "dayName": "Lunes",
        "dateText": "12 de Enero",
        "weekText": "Semana 2 del ciclo",
        "isoDate": "2026-01-12"
      }
    ],
    "secciones": [
      {
        "idSeccion": "1",
        "codigoSeccion": "856",
        "docenteCode": "T001",
        "promedioSeccion": 0,
        "idCurso": "10",
        "curso": "INGENIERÍA DE SOFTWARE II",
        "asistido": 12,
        "inasistencia": 2,
        "total": 30,
        "asistenciaDisponible": true,
        "horasTranscurridas": 8,
        "horarios": [
          {
            "dia": "Lunes",
            "inicio": "08:00:00",
            "hora_inicio": "08:00 am",
            "fin": "10:00:00",
            "hora_fin": "10:00 am",
            "aula": "L3-402",
            "salon": "L3-402",
            "color": "#F94B3F"
          }
        ]
      }
    ]
  }
  ```

> **`isoDate`** (RS-BE-36): la fecha de ese día en hora de Lima, `"YYYY-MM-DD"`, la misma de la que sale `dateText` (que no trae año). Llega en `null` cuando el ciclo no tiene semanas: el mismo caso en que `dateText` viene vacío y `weekText` dice "Semana actual". Es aditivo: un backend anterior no lo manda, y la app lo trata como `null`. La app lo usa para pedir los bloques propios del ciclo visible y para saber qué bloques caen en cada día (`specs/features/time-blocks/time-blocks.spec.md`, RF-BLQ-4 y RF-BLQ-7). Con `null`, solo el ciclo sin semanas, que llega con siete días, toma ese día de la semana en la semana de hoy; si llegan más de siete días sin `isoDate` (un ciclo con semanas que manda un backend sin RS-BE-36), no hay fecha y la app no pinta bloques propios ni la línea de horas.

> **`asistenciaDisponible`** (RS-BE-10, backend `specs/features/attendance-risk/attendance-risk.spec.md`): dice si esta matrícula tiene asistencia cargada. Es una bandera POSITIVA: `asistido`, `inasistencia` y `total` en 0 NO significan "cero faltas", significan "nunca se midió". Un cliente que divida `asistido / total` obtiene `NaN`, que Flutter clampea al MÁXIMO y pinta como asistencia perfecta. Con `false` hay que mostrar estado "sin datos", nunca un porcentaje.
>
> Las filas de horario **docente** y de **asesoría** siempre lo emiten en `false`.
>
> **`horasTranscurridas`** (RS-BE-16): horas ya DICTADAS (`asistido + inasistencia`), no las del ciclo. El porcentaje se calcula sobre este número: dividir `asistido / total` daría 8/64 = 12.5% en la semana 2, que el alumno lee como "asististe al 12.5%".
>
> **Riesgo por inasistencias** (`/attendance-risk`): `status` admite `impedido | en_riesgo | normal | sin_datos`, y `absencePercentage` es **nullable** — llega `null` exactamente cuando `status` es `sin_datos`. El `summary` incluye `sin_datos` como contador propio, que NO se suma a `normal`.

### GET /schedule/me/assessments
Retorna la lista de evaluaciones programadas en el sílabo mapeadas a fechas y horarios reales basados en el cronograma semanal de clases del estudiante.
- **Auth**: Bearer token
- **Response** `200 OK`:
  ```json
  {
    "assessments": [
      {
        "id": "1",
        "courseName": "INGENIERÍA DE SOFTWARE II",
        "sectionCode": "856",
        "code": "EE1",
        "name": "Examen Escrito 1",
        "weekNumber": 2,
        "date": "2026-01-12",
        "startTime": "08:00:00",
        "endTime": "10:00:00",
        "classroom": "L3-402",
        "color": "#F94B3F"
      }
    ]
  }
  ```

### GET /schedule/me/load
Retorna la carga académica por semana para el periodo académico activo, identificando semanas con alta carga académica.
- **Auth**: Bearer token
- **Response** `200 OK`:
  ```json
  {
    "weeks": [
      {
        "weekNumber": 2,
        "startDate": "2026-01-12",
        "endDate": "2026-01-18",
        "assessmentCount": 3,
        "isHighLoad": true
      }
    ]
  }
  ```

Notas:

- Horario usa `schedule_session` de secciones con enrollment activo.
- Evaluaciones usan `assessment.week_number` mapeado dinámicamente a fechas reales de la clase en esa semana académica.
- Alta carga es 3+ evaluaciones en una misma semana académica.

- `GET /schedule/me/sessions` expone `schedule_session.classroom` por sesiÃ³n como `aula`/`salon`; `color` puede venir como nombre legacy o como hexadecimal desde `schedule_session.color_hex`.

## Course Detail

- `GET /course-detail/sections/:sectionId`
- `GET /course-detail/sections/:sectionId/announcements`
- `GET /course-detail/sections/:sectionId/contacts`
- `GET /course-detail/sections` (lista general)
- `GET /course-detail/teachers`
- `GET /course-detail/enrollments`

Notas:

- Solo roles de alumno (`requireRole('student','delegate','subdelegate')`); un token docente recibe `403 FORBIDDEN`.
- El estudiante solo ve secciones donde está matriculado.
- Contactos agrega la clave top-level `jefePractica` (`{ code, lastName, firstName }` o `null`) desde `section.jp_id`, entre `docente` y `alumnos`.
- Anuncios visibles solo si pertenecen a la sección del estudiante.
- El listado de asesorías y RSVP del alumno migraron a `advising-student` (ver abajo).

## Alerts

- `GET /alerts/me`
- `PUT /alerts/me/:alertId/read`

Notas:

- Tipos válidos: `academic_risk`, `high_load`.
- Recalcular alertas es interno; no hay endpoint público de recalculo en v1.
- `academic_risk` no compara contra promedio de sección.

## Advising Student — RSVP del alumno (HU17)

Sub-módulo `student/` dentro de `src/modules/advising/`.

- `GET /advising/section/:sectionId` — listado de asesorías (recurrentes + extras, excluye pasadas).
- `POST /advising/:sessionId/rsvp` — confirmar asistencia.
- `DELETE /advising/:sessionId/rsvp` — cancelar asistencia.

Detalle en `specs/features/advising-student/advising-student.spec.md`.

## Advising (HU18 — docentes)

Rol requerido: `teacher`.

- `GET /advising/me/sections` — secciones del docente (como profesor o JP) en el período activo.
- `GET /advising/me/sessions` — asesorías del docente (recurrentes + extras) con `asistentes` y `rol`.
- `POST /advising/me/sessions` — crea asesoría extra.
- `DELETE /advising/me/sessions/:id` — elimina una extra propia.
- `GET /advising/me/sessions/:id/attendees` — conteo + lista de confirmados.

## Section Management

- `GET /section-management/representatives` — **IMPLEMENTADO** (único endpoint real).
- ~~`GET /section-management/me/sections`~~ — **NO IMPLEMENTADO**.
- ~~`POST /section-management/sections/:sectionId/announcements`~~ — **NO IMPLEMENTADO** (HU10, pendiente).
- ~~`GET /section-management/sections/:sectionId/progress`~~ — **NO IMPLEMENTADO** (HU11, pendiente).

Notas:

- **Estado real**: el módulo solo expone `GET /representatives`. Los endpoints de registro de anuncios y estadísticas están documentados pero no implementados.
- Los anuncios reales en frontend se sirven actualmente desde el módulo `course-detail` (`GET /course-detail/sections/:sectionId/announcements`).

## Chatbot (Asistente Académico con IA)

Asistente conversacional con IA (Cohere) para alumnos. Detalle en `specs/features/chatbot/chatbot.spec.md`.

Roles requeridos: `student`, `delegate`, `subdelegate`.

### Sesiones

| Método | Endpoint | Descripción |
| --- | --- | --- |
| `POST` | `/chatbot/sessions` | Crear nueva sesión. Response `201`: `{ "session": { "id", "title", "createdAt", "updatedAt" } }` |
| `GET` | `/chatbot/sessions` | Listar sesiones del alumno. Response `200`: `{ "sessions": [...] }` |
| `GET` | `/chatbot/sessions/:id` | Obtener sesión con mensajes. Response `200`: `{ "session": {...}, "messages": [...] }` |
| `DELETE` | `/chatbot/sessions/:id` | Eliminar sesión. Response `200`: `{ "message": "..." }` |

### Preguntas

- `POST /chatbot/sessions/:id/ask`
  - Request: `{ "question": "string<=500", "localGrades?": [...] }`
  - Response `200`: `{ "answer": "string", "sessionId": "uuid" }`
  - `localGrades` (opcional): `[{ "id": "sectionId", "nombre": "string", "notas": [{ "titulo": "string", "peso": 0-100, "valor": 0-20 }] }]`
  - Errores: `400 INVALID_QUESTION`, `404 SESSION_NOT_FOUND`, `429 RATE_LIMITED`, `503 CHATBOT_UNAVAILABLE`

## Networking (HU25 — Escenario 1)

Aplica a cualquier usuario autenticado. El propietario se deriva del JWT; el
frontend no envía un `userId` ni decide permisos. PostgreSQL sigue siendo la
fuente de verdad y no se modifica el esquema para este escenario.

### GET /networking/me

- **Auth**: Bearer token.
- **Response** `200 OK`:

  ```json
  {
    "optIn": true,
    "links": [
      {
        "platform": "linkedin",
        "url": "https://www.linkedin.com/in/usuario",
        "label": null
      }
    ]
  }
  ```

- `links` contiene cero o un elemento.
- Plataformas: `linkedin|instagram|github|x|website|other`.
- El propietario recibe su enlace aunque `optIn` sea `false`.

### PUT /networking/me

- **Auth**: Bearer token.
- **Request body**:

  ```json
  {
    "optIn": true,
    "links": [
      {
        "platform": "linkedin",
        "url": "https://www.linkedin.com/in/usuario",
        "label": null
      }
    ]
  }
  ```

- Reemplaza el conjunto del carnet propio y persiste el opt-in en una sola
  operación de backend.
- Máximo una red total. La URL debe ser HTTP(S) válida y de hasta 255
  caracteres. `label` admite hasta 80 caracteres y el backend determina su
  obligatoriedad para `website|other`.
- `optIn:false` oculta el carnet sin borrar un enlace incluido en `links`.
- **Response** `200 OK`: el mismo shape actualizado de `GET /networking/me`.
- `label` se envía y recibe como `string|null`.
- Errores: `400 INVALID_REQUEST_BODY`, `401 MISSING_TOKEN`, `401 INVALID_TOKEN` y los
  errores de validación específicos definidos por backend. El cliente muestra
  el mensaje del backend sin reinterpretar autorización o reglas de negocio.

La consulta pública y el uso en contactos/chat quedan fuera del Escenario 1.

## Portal Sync (carga de ciclo desde miUlima) — implementado el 2026-09-02

Importa los datos oficiales del alumno desde el portal miUlima. Ver `specs/features/portal-sync/portal-sync.spec.md`.

El diseño original abría un WebView en la app y mandaba solo las cookies de la sesión, para que el backend nunca viera la contraseña. Ese camino **no fue el que se implementó**: hoy la app manda `credentials` —contraseña de miUlima y passcode del authenticator— y es el backend quien entra al portal. El body sigue aceptando `cookies` porque el otro camino nunca se retiró, pero ninguna pantalla lo usa.

Las credenciales se usan para el login y se descartan: no se persisten ni se registran en logs. Es una promesa del backend (RS-BE-7 de su spec), no una propiedad del protocolo como lo era con las cookies.

Alumno (`requireRole(student|delegate|subdelegate)`, `studentId` y `code` del JWT):

- `GET /portal-sync/status`
  - Response: `{ "activePeriod": { "id": number, "code": "2026-2" } | null, "enrollmentsInActivePeriod": number, "needsImport": boolean }`
  - `needsImport` = no hay período activo o el alumno no tiene `enrollment` activa en él.
- `POST /portal-sync/import`
  - Body: `cookies` **o** `credentials`, exactamente uno de los dos.
    - `{ "credentials": { "password": string, "passcode": string } }` — el camino que usa la app. `passcode` es `^\d{6,8}$`.
    - `{ "cookies": { "JSESSIONID": string, "LtpaToken2": string, "LtpaToken": string|null } }` — cookies de `webaloe.ulima.edu.pe`, del diseño de WebView que no se implementó.
    - Ninguno de los dos se persiste ni se registra en logs.
  - `"consent": true` es opcional y va en el nivel superior del body (RS-BE-29). La app lo manda solo después de que el alumno toca «Acepto» en la pantalla de consentimiento (RF-REC-6). Sin él la importación corre igual, pero el backend no guarda récord, foto ni resumen ni desmarca electivos. La app nunca manda `false`.
  - Response `200`:
    ```json
    {
      "period": { "id": 12, "code": "2026-2", "created": false },
      "identity": { "portalCode": "20230001", "fullName": "string", "career": "INGENIERÍA DE SISTEMAS" },
      "summary": {
        "coursesCreated": 0, "teachersCreated": 0, "sectionsCreated": 0, "sectionsUpdated": 5,
        "sessionsUpserted": 12, "enrollmentsUpserted": 5, "enrollmentsWithdrawn": 0,
        "progressUpserted": 53, "progressSkipped": 4, "alertsCreated": 1
      },
      "warnings": [ { "code": "PERIOD_DATES_DEFAULTED" | "PERIOD_NOT_ACTIVATED_YET" | "TEACHER_MISSING" | "PARSER_FAILED" | "CAREER_MISMATCH" | "PROGRESS_SKIPPED" | "WITHDRAW_SKIPPED_WOULD_LOCK_OUT" | "LEVEL_OUT_OF_RANGE" | "LEVEL_REGRESSION_BLOCKED" | "SYLLABUS_UNAVAILABLE" | "DELEGADOS_UNAVAILABLE" | "ASISTENCIA_UNAVAILABLE", "block": "string", "message": "string" } ]
    }
    ```
  - Errores: **`409 PORTAL_LOGIN_REJECTED`** (miUlima rechazó la contraseña o el passcode) y **`409 PORTAL_SESSION_INVALID`** (el portal devolvió `inicio.jsp` o pidió passcode). Los dos son 409 y no 401 a propósito: `ApiClient` del frontend trata todo 401 como expiración del JWT y cerraría la sesión del usuario. `403 PORTAL_IDENTITY_MISMATCH` (código del portal ≠ `app_user.code`), `422 PORTAL_IDENTITY_UNVERIFIABLE` (no se pudo leer el código del portal), `502 PORTAL_UNAVAILABLE`, `504 PORTAL_TIMEOUT`, `429 RATE_LIMITED` (máx. 5 importaciones por alumno por hora, con `details.retryAfterMinutes`).
  - La verificación de identidad ocurre ANTES de cualquier escritura y no se degrada a `warnings`.
  - Idempotente: repetir la importación deja el mismo estado (todos los upsert usan `ON CONFLICT` sobre constraints existentes). No toca `simulated_grades`, simulación de malla, especialidades, anuncios, asesorías, representantes, chat, networking, `schedule_session.color_hex` ni las horas de asistencia.
  - **La primera importación de un ciclo nuevo activa ese `academic_period` para TODOS los alumnos** (`is_active` es único global). Solo avanza el ciclo, nunca lo retrocede.

## Academic Record (récord académico) — RF-REC-1 a RF-REC-5

Copia del récord académico del portal que el backend guarda cuando el alumno sincroniza y acepta el consentimiento. Ver `specs/features/academic-record/academic-record.spec.md` y, en el backend, RS-BE-26 y RS-BE-27 de `ULima_Backend_IS2/specs/features/academic-record/academic-record.spec.md`.

Alumno (`requireRole(student|delegate|subdelegate)`); el alumno sale del token. Un docente recibe 403: la app nunca la pide para él.

- `GET /academic-record/me`
  - Response `200`, con `Cache-Control: no-store`:
    ```json
    {
      "syncedAt": "2026-09-18T15:00:00Z" | null,
      "snapshot": {
        "ppa": 14.62, "relativePosition": "TERCIO SUPERIOR",
        "creditsAccumulated": 120, "creditsRequired": 200,
        "approved": { "courses": 40, "credits": 118 },
        "convalidated": { "courses": 1, "credits": 2 }
      } | null,
      "periods": [ {
        "periodCode": "2026-0", "average": 15.5, "relativePosition": "MEDIO SUPERIOR",
        "level": 6,
        "convalidated": { "courses": 0, "credits": 0 },
        "enrolled":     { "courses": 3, "credits": 10 },
        "approved":     { "courses": 2, "credits": 7 },
        "failed":       { "courses": 1, "credits": 3 }
      } ],
      "record": [ { "periodCode": "2026-1", "courses": [
          { "code": "100001", "name": "CURSO DE PRUEBA A", "attempt": 1,
            "credits": 1.5, "grade": 17, "gradeRaw": "17", "section": "917",
            "observation": null } ] } ]
    }
    ```
  - Nunca sincronizó: `syncedAt` null, `snapshot` null, `periods` [] y `record` [], también con 200. La app muestra el estado vacío (RF-REC-4).
  - Los numéricos siempre son `number`, nunca string: `credits`, `ppa`, `average` y los `credits*` pueden traer decimal; `attempt`, `grade`, `level` y `courses` son enteros. Sin dato es `null`, nunca 0, cada número por separado.
  - `record` llega del ciclo más reciente al más viejo. La sección de cada curso viaja como `section`.
- `DELETE /academic-record/me`
  - Response `200`: `{ "ok": true }`.
  - Borra la copia, la foto y el resumen del alumno. No toca `student_course_progress`, así que la malla no cambia. Si vuelve a sincronizar y acepta, la copia se guarda otra vez.

En la app, `AcademicRecordService` es el único que llama a estas dos rutas. Un fallo del `GET` deja la tarjeta y la pantalla en su estado de error. Un fallo del `DELETE` se muestra como "No se pudo borrar tu récord. Inténtalo de nuevo.".

## Time Blocks (bloques de horario propios) — RF-BLQ-1 a RF-BLQ-7

Bloques que el propio alumno registra en su horario (prácticas, trabajo): un patrón semanal con rango de fechas, más excepciones por día. Ver `specs/features/time-blocks/time-blocks.spec.md` y, en el backend, RS-BE-30 a RS-BE-35 de `ULima_Backend_IS2/specs/features/time-blocks/time-blocks.spec.md`.

Alumno (`requireRole(student|delegate|subdelegate)`); el alumno sale del token y no hay parámetro de alumno ni acceso para docentes. Las horas viajan como `"HH:MM"` y las fechas como `"YYYY-MM-DD"`, siempre en hora de Lima y sin zona pegada: son horas de pared. Una fecha que no existe en el calendario o que cae fuera de 2000-01-01 a 2099-12-31 es un formato inválido para el servidor; el formulario de la app solo ofrece fechas del año pasado a dos años adelante, dentro de ese rango. `daysOfWeek` usa la convención de `schedule_session.day_of_week`: 1 es lunes y 7 es domingo.

- `GET /time-blocks/me`
  - Response `200`:
    ```json
    { "blocks": [ {
      "id": 12, "title": "PRÁCTICAS DE PRUEBA", "colorHex": "#EB5757",
      "daysOfWeek": [1, 3], "startTime": "14:00", "endTime": "18:00",
      "startDate": "2026-09-01", "endDate": "2026-12-15",
      "exceptions": [ { "date": "2026-10-07", "status": "cancelled",
                        "startTime": null, "endTime": null },
                      { "date": "2026-10-14", "status": "moved",
                        "startTime": "15:00", "endTime": "19:00" } ]
    } ] }
    ```
  - `status` es `"cancelled"` o `"moved"`. En `"cancelled"`, `startTime` y `endTime` son `null` y la app los conserva así.
- `POST /time-blocks/me`
  - Body: `{ "title": string, "colorHex": "#RRGGBB", "daysOfWeek": number[], "startTime": "HH:MM", "endTime": "HH:MM", "startDate": "YYYY-MM-DD", "endDate": "YYYY-MM-DD" }`
  - Response `201`: `{ "block": { …como arriba, con "exceptions": [] } }`
- `PATCH /time-blocks/me/:id`
  - Body: los mismos siete campos. Reemplaza la regla entera y **conserva** las excepciones.
  - Response `200`: `{ "block": … }`
- `DELETE /time-blocks/me/:id`
  - Response `200`: `{ "ok": true }`. Borra el bloque y sus excepciones.
- `PUT /time-blocks/me/:id/occurrences/:date`
  - Body: `{ "status": "cancelled" }` o `{ "status": "moved", "startTime": "15:00", "endTime": "19:00" }`. Con `"cancelled"` la app **no manda** `startTime` ni `endTime` (si llegaran, el servidor las ignora); con `"moved"` las dos son obligatorias.
  - Response `200`: `{ "exception": { "date": "2026-10-14", "status": "moved", "startTime": "15:00", "endTime": "19:00" } }`, con la forma de la excepción dentro de su bloque (en `"cancelled"`, las dos horas en `null`). La app no lee la respuesta: recarga su ventana.
  - Idempotente: repetir el mismo `PUT` deja el mismo estado, y un `PUT` sobre una fecha que ya tenía excepción la reemplaza.
  - La fecha tiene que caer dentro del rango del bloque y en uno de sus días de la semana.
- `DELETE /time-blocks/me/:id/occurrences/:date`
  - Response `200`: `{ "ok": true }`. Ese día vuelve al patrón. Idempotente, y no exige que la fecha siga en el patrón: sirve para limpiar una excepción que quedó fuera después de un `PATCH`.
- `GET /time-blocks/me/occurrences?from=YYYY-MM-DD&to=YYYY-MM-DD`
  - La ventana es obligatoria, incluye los dos extremos y cubre 120 días como máximo.
  - Response `200` para `?from=2026-09-21&to=2026-09-27`, con el bloque de arriba:
    ```json
    {
      "occurrences": [ { "blockId": 12, "title": "PRÁCTICAS DE PRUEBA", "colorHex": "#EB5757",
                         "date": "2026-09-21", "dayOfWeek": 1,
                         "startTime": "14:00", "endTime": "18:00", "moved": false },
                       { "blockId": 12, "title": "PRÁCTICAS DE PRUEBA", "colorHex": "#EB5757",
                         "date": "2026-09-23", "dayOfWeek": 3,
                         "startTime": "14:00", "endTime": "18:00", "moved": false } ],
      "weeks": [ { "weekStart": "2026-09-21", "hours": 8 } ]
    }
    ```
  - El servidor ya expandió el patrón y aplicó las excepciones: un día cancelado no aparece y uno movido llega con sus horas nuevas y `moved: true`. Las ocurrencias salen ordenadas por fecha y hora de inicio.
  - `weeks` trae una entrada por cada semana de lunes a domingo entre el lunes de `from` y el lunes de `to`, ordenadas, con ese lunes en `weekStart` (puede ser anterior a `from`) y en `hours` el total de horas de los bloques del alumno en la semana **entera**, aunque la ventana la corte. `hours` puede traer decimal (`8.5`). Un día cancelado no suma y uno movido suma su duración nueva. Una semana sin ocurrencias llega con `hours: 0`. Solo cuentan los bloques propios, nunca las clases.
  - La app pinta la línea de RF-BLQ-6 solo si `hours`, redondeado a un decimal (la precisión con que se pinta), es mayor que 0. Con `0`, con menos de `0.05` (un bloque de dos minutos llega con `0.033`, porque el servidor no redondea), con `null` (el backend no lo manda) o sin la semana en la lista, no hay línea.
- Errores: `404 TIME_BLOCK_NOT_FOUND`; `400 INVALID_REQUEST_BODY` (body inválido en `POST`, `PATCH` y `PUT`); `400 INVALID_QUERY_PARAMS` (falta `from` o `to`, alguna no es una fecha válida, o `to` es anterior a `from`); `400 TIME_BLOCK_OUT_OF_GRID` (alguna hora fuera de 07:00–22:00, el rango que la grilla puede pintar); `400 TIME_BLOCK_LIMIT_REACHED` (máximo 20 bloques **guardados**, vencidos incluidos: el tope acota lo que el servidor expande en una ventana, y un bloque vencido se sigue expandiendo en una ventana pasada; su mensaje lo dice y sugiere borrar uno viejo); `400 TIME_BLOCK_OCCURRENCE_NOT_IN_PATTERN` (la fecha no cae en el patrón del bloque); `400 TIME_BLOCK_WINDOW_TOO_WIDE` (más de 120 días); `400 INVALID_ROUTE_PARAMS` (un `:id` o un `:date` mal formados); `400 INVALID_JSON_BODY` (un cuerpo que no es JSON, en `POST`, `PATCH` y `PUT`); más los 401/403 del middleware.

En la app, `TimeBlocksService` es el único que llama a estas siete rutas. El mensaje de un error del servidor se muestra tal cual llega (RF-BLQ-2); un fallo sin mensaje —red caída o plazo vencido— se muestra como "No se pudo guardar tu bloque. Inténtalo de nuevo.", y en ese caso la app vuelve a pedir su ventana, porque la escritura pudo quedar guardada. Los ejemplos usan datos inventados.

## Specialty Test (test de especialidad), aprobado el 2026-09-25 e implementado en la app en la rama `feat/test-especialidad-fe`

Test que conduce Ulises y que recomienda uno de los cuatro diplomas oficiales. El backend sirve el contenido versionado, calcula el puntaje con la fórmula del contenido, decide los desempates, pide a Cohere el motivo con respaldo de plantillas y guarda solo el último resultado del alumno. Ver `specs/features/specialty-test/specialty-test.spec.md` (RF-TEST-1 a RF-TEST-14) y, en el backend, RS-BE-37 a RS-BE-47 de `ULima_Backend_IS2/specs/features/specialty-test/specialty-test.spec.md` (rama `feat/test-especialidad`). El dueño aprueba las dos specs el 2026-09-25, con los íconos de Lucide por tarea de la versión `2026-09-25.4` del contenido. El resultado vive en `student_specialty_test_result`, la tabla de la migración `0014` del backend, un cambio de BD que el dueño aprueba con las specs. Aplicar la `0014` en producción pide además, en el momento del despliegue, el respaldo y el permiso explícito del dueño.

Las tres rutas comparten estas reglas.

- **Auth**: Bearer token, roles `student`, `delegate`, `subdelegate`. Un token docente recibe `403 FORBIDDEN`; la app nunca abre el test para un docente. El alumno sale solo del token y ningún cuerpo lleva datos del alumno.
- **Disponibilidad**: el servidor traduce las claves `sw`, `ti`, `si` y `vj` a los `specialtyId` de las especialidades activas de la carrera del alumno. Si alguna no aparece, responde `404 SPECIALTY_TEST_NOT_AVAILABLE`, y la app pasa a la elección manual en el asistente y oculta la tarjeta del test en el Perfil.
- **Tipos**: `affinity` es un entero de 0 a 100. El servidor decide el orden, los desempates y el empate; la app no calcula nada del resultado. Las fechas van en ISO-8601 UTC con milisegundos.
- **Mensajes** (`error.message` de cada código nuevo): `SPECIALTY_TEST_NOT_AVAILABLE` "El test de especialidad no está disponible para tu carrera.", `SPECIALTY_TEST_VERSION_OUTDATED` "El test se actualizó. Vuelve a empezarlo.", `SPECIALTY_TEST_INVALID_ANSWERS` "Las respuestas no corresponden a esta versión del test.", `SPECIALTY_TEST_TIEBREAK_MISMATCH` "Los desempates enviados no son los que corresponden a estas respuestas.", `PAYLOAD_TOO_LARGE` "La petición es demasiado grande." y `RATE_LIMITED` "Hiciste demasiados intentos del test. Intenta de nuevo en N minuto(s).".
- **Errors comunes**: `401` `MISSING_TOKEN`, `401` `INVALID_TOKEN`, `403` `FORBIDDEN`, `404` `USER_NOT_FOUND`, `404` `SPECIALTY_TEST_NOT_AVAILABLE`.
- Todos los valores de los ejemplos son inventados, y los `specialtyId` son ilustrativos.

### GET /specialty-test/content

Contenido de la versión vigente, con lo necesario para conducir el test sin red entre pregunta y pregunta.

- **Response** `200 OK` (recortado):
  ```json
  {
    "version": "2026-09-25.4",
    "specialties": [
      {
        "key": "sw", "specialtyId": 1, "name": "Ingeniería de Software",
        "tagline": "Diseña y programa aplicaciones que funcionan bien y se pueden seguir mejorando.",
        "color": { "light": "#1E3A8A", "dark": "#A5C0F7" }, "icon": "code-xml", "totalCredits": 21,
        "electives": [
          { "code": "650070", "name": "Paradigmas de Programación", "shortName": "Paradigmas de Programación",
            "credits": 3, "prerequisite": "Haber culminado el V ciclo" }
        ]
      }
    ],
    "ulises": {
      "welcome": ["¡Hola! Soy Ulises. …"], "startButton": "Vamos",
      "duelHelp": "Toca la tarea que harías con más ganas.",
      "scaleHelp": "Elige cuánto te gustaría hacer esta tarea.",
      "reactions": { "pick": ["Anotado."], "both": ["…"], "none": ["…"], "scale": ["…"] },
      "loading": "Dame un toque que junto tus respuestas."
    },
    "duelOptions": [
      { "id": "top", "label": "(tarea de arriba)" }, { "id": "bottom", "label": "(tarea de abajo)" },
      { "id": "both", "label": "Me gustan las dos" }, { "id": "none", "label": "Ninguna me llama" }
    ],
    "scaleOptions": [
      { "id": "nada", "label": "Nada" }, { "id": "un_poco", "label": "Un poco" },
      { "id": "bastante", "label": "Bastante" }, { "id": "me_encantaria", "label": "Me encantaría" }
    ],
    "questions": [
      { "id": "q01", "n": 1, "type": "duel", "prompt": "¿Cuál harías con más ganas?",
        "top": { "id": "q01.top", "specialty": "sw", "text": "…", "illustration": "…", "icon": "shopping-cart" },
        "bottom": { "id": "q01.bottom", "specialty": "si", "text": "…", "illustration": "…", "icon": "shelving-unit" },
        "reaction": "…" },
      { "id": "q04", "n": 4, "type": "scale", "prompt": "¿Cuánto te gustaría hacer esto?",
        "task": { "id": "q04.task", "specialty": "ti", "text": "…", "illustration": "…", "icon": "drumstick" },
        "blockClose": "Primer tramo listo. Van 4 de 14." }
    ]
  }
  ```
- **Qué no viaja**: el nombre del ícono en Flutter (`icon.flutter`) de cada especialidad y de cada tarea, resúmenes y electivos de cada tarea, pesos, umbral, plantillas del motivo, líneas de Ulises del resultado salvo la de espera (`ulises.loading`), líneas del desempate, desempates, ejemplos, balance y fuentes. Son del cálculo y del motivo, que hace el servidor.
- **En la app**: `SpecialtyTestService.fetchContent()` lo pide una vez por cada apertura de `/test-especialidad`, y en la primera apertura desde el asistente ese pedido es la precarga del paso de carrera. «Rehacer el test» sigue con la misma copia, que queda en memoria durante la sesión (RF-TEST-2). La app usa `specialty` de cada tarea solo para encender la tarjeta tocada; antes del toque las tarjetas son neutras. `illustration` no se muestra. El `icon` de cada especialidad y de cada tarea es la cadena de `icon.lucide` del contenido, y la app lo traduce con un mapa cerrado de nombres a `LucideIcons` (`lucide_icons_flutter` 3.1.15), con `LucideIcons.sparkles` para un nombre fuera del mapa o ausente. El ícono de la tarea va en color neutro hasta que el alumno toca su tarjeta del duelo, y en la escala nunca toma el color de su especialidad (RF-TEST-5 y RF-TEST-6). Un contenido que no pasa la validación del modelo cuenta como error de carga.

### POST /specialty-test/me/evaluate

Evaluación sin estado. Recibe todas las respuestas dadas hasta ese momento y devuelve el siguiente desempate o el resultado final. Solo el resultado final se guarda.

- **Body** (hasta 4 KiB):
  ```json
  {
    "version": "2026-09-25.4",
    "answers": {
      "q01": "bottom", "q02": "bottom", "q03": "both", "q04": "nada", "q05": "top",
      "q06": "top", "q07": "top", "q08": "bastante", "q09": "top", "q10": "top",
      "q11": "bottom", "q12": "me_encantaria", "q13": "bottom", "q14": "un_poco"
    },
    "tiebreakAnswers": [ { "id": "tb-si-vj-1", "answer": "bottom" } ]
  }
  ```
- **Response** `200 OK` cuando toca un desempate: `{ "status": "tiebreak", "tiebreak": { "id", "order", "prompt", "top", "bottom" }, "ulisesLine": "…" }`, con `top` y `bottom` en la misma forma que las tareas del contenido, `icon` incluido.
- **Response** `200 OK` con el resultado final:
  ```json
  {
    "status": "result",
    "result": {
      "version": "2026-09-25.4",
      "completedAt": "2026-09-25T20:15:00.000Z",
      "tie": false,
      "ranking": [
        { "key": "vj", "specialtyId": 7, "name": "Desarrollo de Videojuegos", "affinity": 75 },
        { "key": "si", "specialtyId": 6, "name": "Sistemas de Información", "affinity": 65 },
        { "key": "ti", "specialtyId": 5, "name": "Tecnologías de la Información", "affinity": 28 },
        { "key": "sw", "specialtyId": 1, "name": "Ingeniería de Software", "affinity": 24 }
      ],
      "reason": "…",
      "reasonSource": "templates",
      "ulises": {
        "intro": "Ya tengo tu resultado.",
        "headline": "Lo tuyo apunta a Desarrollo de Videojuegos, con 75 % de afinidad.",
        "tiebreakOutcome": "Ahí está, ya se inclinó la balanza.",
        "closing": "…",
        "retake": "Si más adelante cambias de idea, puedes volver a hacer el test."
      }
    }
  }
  ```
- `reasonSource` es `"ai"` si el motivo lo redacta Cohere o `"templates"` si sale de las plantillas; un fallo o una demora de Cohere nunca es un error para la app. `tiebreakOutcome` es `null` sin desempate. Con empate, `tie` es `true` y las dos primeras del ranking son las ganadoras.
- `Cache-Control: no-store`. Límite de 30 evaluaciones por alumno por hora.
- **Errors**: `400` `INVALID_JSON_BODY`, `400` `INVALID_REQUEST_BODY`, `400` `SPECIALTY_TEST_INVALID_ANSWERS` (`details.missing`, `details.unexpected`, `details.invalid`), `400` `SPECIALTY_TEST_TIEBREAK_MISMATCH` (`details.expected`), `409` `SPECIALTY_TEST_VERSION_OUTDATED` (`details.currentVersion`), `413` `PAYLOAD_TOO_LARGE`, `429` `RATE_LIMITED` (`details.retryAfterMinutes`), `500` `INTERNAL_SERVER_ERROR` si falla el guardado del resultado, que va antes de la llamada a Cohere, y los comunes.
- **En la app**: `SpecialtyTestService.evaluate()` la llama con un plazo de 20 s. Las respuestas viven solo en memoria y un reintento manda el mismo cuerpo. Un `409` o un `400 SPECIALTY_TEST_INVALID_ANSWERS` vuelven a pedir el contenido y empiezan de nuevo; un `400 SPECIALTY_TEST_TIEBREAK_MISMATCH` se reintenta una vez sin desempates; un `429` muestra el mensaje del servidor. Detalle en RF-TEST-7 y RF-TEST-11.

### GET /specialty-test/me/result

Último resultado guardado del alumno, para el Perfil.

- **Response** `200 OK`: `{ "result": { "version", "isCurrentVersion", "completedAt", "tie", "ranking" } }`, con el `ranking` en la misma forma que el de la evaluación, o `{ "result": null }` si el alumno no tiene ningún test terminado.
- No trae el motivo, que no se guarda. `name` sale de la versión vigente del contenido por la clave.
- `Cache-Control: no-store`.
- **Errors**: los comunes, y `500` `INTERNAL_SERVER_ERROR` si la fila guardada no tiene la forma esperada.
- **En la app**: la tarjeta del Perfil (RF-TEST-10) lo pide al montarse y otra vez al volver de un test terminado. Un error muestra «No se pudo cargar tu último test.» con «Reintentar», y el `404 SPECIALTY_TEST_NOT_AVAILABLE` oculta la tarjeta.
