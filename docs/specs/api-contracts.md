# API Contracts

Contrato REST local del frontend ULima++. Mantener alineado manualmente con `ULima_Backend_IS2/docs/specs/api-contracts.md`.

## Reglas

- Todo endpoint, payload, respuesta, error o permiso debe actualizarse aquí antes de implementar frontend.
- Las specs frontend deben referenciar este archivo.
- PostgreSQL definitivo es la fuente de verdad a través del backend.
- No existe fallback final a JSON.
- Cada sección debe ser refinada por la spec de feature antes de implementar.

## Principios Globales

- Todas las rutas, salvo `GET /`, `GET /health`, `POST /auth/login`, `POST /auth/google`, `POST /auth/password-reset/request` y `POST /auth/password-reset/confirm`, usan `Authorization: Bearer <token>`.
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
        "weekText": "Semana 2 del ciclo"
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

## Portal Sync (carga de ciclo desde miUlima) — PROPUESTO, pendiente de implementar

Importa los datos oficiales del alumno desde el portal miUlima usando la **sesión del portal que el alumno abrió en un WebView de la app**. El backend nunca recibe contraseña ni código TOTP. Ver `specs/features/portal-sync/portal-sync.spec.md`.

Alumno (`requireRole(student|delegate|subdelegate)`, `studentId` y `code` del JWT):

- `GET /portal-sync/status`
  - Response: `{ "activePeriod": { "id": number, "code": "2026-2" } | null, "enrollmentsInActivePeriod": number, "needsImport": boolean }`
  - `needsImport` = no hay período activo o el alumno no tiene `enrollment` activa en él.
- `POST /portal-sync/import`
  - Body: `{ "cookies": { "JSESSIONID": string, "LtpaToken2": string, "LtpaToken": string|null } }` (cookies de `webaloe.ulima.edu.pe`; nunca se persisten ni se registran en logs)
  - Response `200`:
    ```json
    {
      "period": { "id": 12, "code": "2026-2", "created": false },
      "identity": { "portalCode": "20235218", "fullName": "string", "career": "INGENIERÍA DE SISTEMAS" },
      "summary": {
        "coursesCreated": 0, "teachersCreated": 0, "sectionsCreated": 0, "sectionsUpdated": 5,
        "sessionsUpserted": 12, "enrollmentsUpserted": 5, "enrollmentsWithdrawn": 0,
        "progressUpserted": 53, "progressSkipped": 4, "alertsCreated": 1
      },
      "warnings": [ { "code": "PERIOD_DATES_DEFAULTED" | "TEACHER_MISSING" | "PARSER_FAILED" | "CAREER_MISMATCH" | "PROGRESS_SKIPPED" | "WITHDRAW_SKIPPED_WOULD_LOCK_OUT" | "LEVEL_OUT_OF_RANGE" | "GRADE_NOT_NUMERIC", "block": "string", "message": "string" } ]
    }
    ```
  - Errores: **`409 PORTAL_SESSION_INVALID`** (el portal devolvió `inicio.jsp` o pidió passcode — es 409 y no 401 a propósito: `ApiClient` del frontend trata todo 401 como expiración del JWT y cerraría la sesión del usuario), `403 PORTAL_IDENTITY_MISMATCH` (código del portal ≠ `app_user.code`), `422 PORTAL_IDENTITY_UNVERIFIABLE` (no se pudo leer el código del portal), `502 PORTAL_UNAVAILABLE`, `504 PORTAL_TIMEOUT`, `429 TOO_MANY_REQUESTS` (máx. 5 importaciones por alumno por hora).
  - La verificación de identidad ocurre ANTES de cualquier escritura y no se degrada a `warnings`.
  - Idempotente: repetir la importación deja el mismo estado (todos los upsert usan `ON CONFLICT` sobre constraints existentes). No toca `simulated_grades`, simulación de malla, especialidades, anuncios, asesorías, representantes, chat, networking, `schedule_session.color_hex` ni las horas de asistencia.
  - **La primera importación de un ciclo nuevo activa ese `academic_period` para TODOS los alumnos** (`is_active` es único global). Solo avanza el ciclo, nunca lo retrocede.
