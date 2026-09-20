# Récord académico (frontend) — Plan de implementación

> **Para agentes:** SUB-SKILL REQUERIDA: usa superpowers:subagent-driven-development (recomendado) o superpowers:executing-plans para ejecutar este plan tarea por tarea. Los pasos usan casillas (`- [ ]`).

**Objetivo:** Que el alumno vea dentro de ULima++ el récord académico que hoy solo está en el portal: tarjeta con PPA y créditos en el Perfil, pantalla `/mi-record` de un ciclo a la vez, borrado a pedido y consentimiento antes de entregar sus credenciales.

**Arquitectura:** Un único `AcademicRecordService` (`GetxService` permanente, como `MallaService`) guarda todo el estado del récord y es lo único que habla con la API; la tarjeta del Perfil y la pantalla `/mi-record` lo leen con `Obx`, así que comparten una sola copia que se invalida tras el `DELETE` y en `PortalSyncService.refreshAfterImport`. El modelo parsea el contrato con helpers defensivos que conservan `null` —nunca 0—, y toda la presentación (progreso de créditos, decimales, ubicación relativa, chip de nota y etiqueta "N.ª vez") vive en funciones puras que se prueban aparte de los widgets. La pantalla usa binding por ruta con `Get.lazyPut`, y el consentimiento es una sola `PortalConsentView` que Portal Sync y Registro montan como un paso más de su máquina de estados.

**Stack:** Flutter + Dart + GetX (flutter en `$FLUTTER`)

**Spec:** `specs/features/academic-record/academic-record.spec.md` (y la contraparte en el otro repo: `ULima_Backend_IS2/specs/features/academic-record/academic-record.spec.md`, RS-BE-19 a RS-BE-29)

**Repo y rama:** `.`, rama `feat/record-academico-fe`

## Restricciones globales

- **Variables de los comandos.** Los comandos de este plan usan `$FLUTTER` para no fijar la ruta del SDK de una maquina concreta: `export FLUTTER=$(which flutter)` (o la ruta de tu instalacion). Las rutas relativas son desde la raiz de este repo.
- Idioma: español en todo texto visible, comentarios, nombres de group/test y mensajes de commit.
- Repo y rama: . en feat/record-academico-fe. Trabajar solo ahí. Editar con Edit sobre anclas concretas; nunca cp/mv para respaldar o restaurar, y nunca git stash (el stash se comparte entre worktrees).
- Commits: el autor ya está configurado en git (Jeffangeloss <178797184+jeffangeloss@users.noreply.github.com>). SIN trailer Co-Authored-By. Un commit por tarea, con git add solo de los archivos de esa tarea. Formato: 'feat(academic-record): …' o 'test(…): …', en español.
- No hacer push ni abrir PR: lo decide el dueño. Si alguna vez se hace, siempre 'git push origin feat/record-academico-fe', nunca git push a secas (upstream es el repo del grupo).
- Repo público: ningún dato real. Alumno sintético code '20230001', firstName 'Alumna', lastName 'De Prueba', email 'test@aloe.ulima.edu.pe', role 'student'. Segundo alumno: 'otro.alumno.test'. Docente: code 'docente.test', role 'teacher'. Nunca copiar valores de test/HU31_jeff/fixtures ni de spike-portal/. Los JSON de prueba son inventados: cursos 'CURSO …', códigos 1000xx.
- Valores PROHIBIDOS en todo archivo del repo: los que aparecen en `test/HU31_jeff/fixtures/` y en `spike-portal/`, porque son de un récord real. Antes de usar un valor nuevo hay que comprobarlo con `grep` contra esas dos carpetas; si aparece, se elige otro. Los de este plan ya se comprobaron así: PPA 14.62, ubicación 'TERCIO SUPERIOR' (y 'MEDIO SUPERIOR' cuando hace falta una segunda), 164 de 200 créditos en las tareas 3 y 4, 197 de 240 en las tareas 6, 7 y 8, secciones '917' y '80x', y cursos 'CURSO …' con códigos 1000xx.
- Tests: $FLUTTER test test/HU34_jeff/<archivo>. Análisis: $FLUTTER analyze, sin issues nuevos; los preexistentes se reportan aparte. La línea base la mide la tarea 1 y la deja fuera del repo, en $TMP/plan-fe/analyze-baseline.txt: donde una tarea diga 'la misma línea de la tarea 1', se compara con un cat de ese archivo, porque cada tarea corre en su propia sesión y no ve el reporte de la anterior.
- El frontend se prueba solo con dobles escritos a mano: extends ApiClient con super(configuredBaseUrl: 'http://test') y @override con la firma exacta; extends AuthService. Nunca contra el backend real. Sin mockito ni mocktail. No se agregan dependencias a pubspec.yaml (no hay intl).
- Firmas a sobreescribir en ApiClient: Future<Map<String, dynamic>> getJson(String path, {String? token, Map<String, String?> query = const {}, bool suppressSessionExpiry = false}); postJson(String path, {required Map<String, dynamic> body, String? token}); deleteJson(String path, {String? token}).
- Archivos permitidos: los targets de specs/features/academic-record/academic-record.spec.md; los tests de test/HU34_jeff/; los tests existentes que rompa un cambio de firma (test/HU31_jeff/portal_sync_test.dart y test/HU33_jeff/registro_*_test.dart); y los docs docs/specs/api-contracts.md, docs/specs/feature-index.md y specs/features/{academic-record,portal-sync,registro}/*.spec.md. NO tocar lib/services/auth_service.dart, lib/configs/themes.dart ni lib/models/user_model.dart, y no ampliar /auth/me.
- GetX: binding por ruta y nunca Get.put dentro de build(). HTTP solo en services; ningún widget lee JSON. Ninguna carga se dispara durante build: la tarjeta usa WidgetsBinding.instance.addPostFrameCallback y el controller usa onReady().
- Números del récord: helpers double?/int? que conservan null. Prohibidos _asInt (official_grades_models.dart:5) y '?? 0'. Un dato null se omite, nunca se pinta '0'. Los decimales van sin redondear ('1.5 créd.') y los enteros sin '.0' ('3 créd.').
- La pantalla se llama 'Mi récord académico'. Nunca 'notas oficiales', que es /mis-notas.
- Un docente (UserModel.isTeacher, role 'teacher' o 'docente') nunca ve la tarjeta ni dispara GET o DELETE /academic-record/me.
- Consentimiento: se manda solo 'consent': true, en el nivel superior del body, y solo después de tocar 'Acepto'. Nunca se manda 'consent': false. La aceptación no se recuerda entre visitas: nada en StorageService ni en shared_preferences.
- SkeletonPulse anima sin fin: mientras haya un skeleton en pantalla no se usa pumpAndSettle, sino tester.pump(). Lo mismo vale con un campo de texto con foco, por el parpadeo del cursor.
- Texto visible: AGENTS.md:50 prohíbe texto que no exista en la spec o en las maquetas. Este plan se desvía a propósito y agrega estas cadenas, que el dueño tiene que aprobar antes del merge: 'Sincronizado hoy' y 'Sincronizado hace 1 día' (la spec solo da 'hace N días'); RecordProfileCard.errorTitle y su enlace (estado de error de la tarjeta, que la spec no pide); 'No se pudo cargar tu récord'; 'No se pudo borrar tu récord. Inténtalo de nuevo.'; el título, el cuerpo y los dos botones del diálogo de borrado; 'Volver' como salida del consentimiento en el registro; y la redacción de PortalConsentView (RF-REC-6 fija su contenido, no sus palabras: es texto de Ley 29733). Fuera de esta lista no se inventa ningún texto. Ver 'Riesgos abiertos y decisiones del dueño'.

## Estructura de archivos

| Ruta | Acción | Responsabilidad |
|:---|:---|:---|
| `lib/models/academic_record_model.dart` | crear | DTOs del contrato GET /academic-record/me con fromJson defensivo que conserva null: AcademicRecord, AcademicSnapshot, AcademicTotals, AcademicPeriodSummary, RecordPeriod, RecordCourse. |
| `lib/services/academic_record_service.dart` | crear | GetxService permanente, estado único del récord (tarjeta y pantalla): load, reload, clear y deleteRecord, con guardas de docente y de usuario dueño. Define AcademicRecordFailure. |
| `lib/pages/academic_record/record_format.dart` | crear | Funciones puras de presentación: creditsProgress, formatDecimal, creditsOfRequiredLabel, creditsShortLabel, formatRelativePosition, progressPercentLabel. |
| `lib/pages/academic_record/record_position_badge.dart` | crear | Insignia de ubicación relativa, compartida por la tarjeta y el encabezado de la pantalla. |
| `lib/pages/academic_record/record_profile_card.dart` | crear | Tarjeta del Perfil (RF-REC-1): PPA, insignia, 'N de M créditos' con barra y enlace a /mi-record, con estados de carga, error, nunca sincronizó y éxito. |
| `lib/pages/academic_record/record_course_row.dart` | crear | Lógica pura del chip de nota y de la etiqueta 'N.ª vez' (RF-REC-3), y el widget RecordCourseRow. |
| `lib/pages/academic_record/academic_record_controller.dart` | crear | Controller de /mi-record: delega en AcademicRecordService; ciclo elegido, texto 'Sincronizado hace…' en hora de Lima, borrado. Estáticos puros probados. |
| `lib/pages/academic_record/academic_record_binding.dart` | crear | Binding por ruta: Get.lazyPut del AcademicRecordController. |
| `lib/pages/academic_record/academic_record_page.dart` | crear | Pantalla 'Mi récord académico': estados de carga, error, vacío y éxito; encabezado con anillo; chips de ciclo; tarjeta de cursos; botón de borrar con diálogo. |
| `lib/components/portal_consent/portal_consent_view.dart` | crear | Pantalla única de consentimiento (RF-REC-6), reutilizada por Portal Sync y Registro. |
| `lib/main.dart` | modificar | Registro permanente de AcademicRecordService y GetPage '/mi-record' con AcademicRecordBinding. |
| `lib/pages/perfil/perfil.dart` | modificar | Inserta const RecordProfileCard() como primer hijo del bloque if (!user.isTeacher). |
| `lib/services/portal_sync_service.dart` | modificar | refreshAfterImport recarga el récord. import() recibe required bool consent y manda 'consent': true. |
| `lib/pages/portal_sync/portal_sync_controller.dart` | modificar | Paso consent inicial, consentimientoAceptado, aceptarConsentimiento() y guarda en submit(). |
| `lib/pages/portal_sync/portal_sync_page.dart` | modificar | Caso PortalSyncStep.consent, que monta PortalConsentView. |
| `lib/pages/registro/registro_controller.dart` | modificar | Paso consentimiento entre datos y verificar; aceptarConsentimiento(); guarda en enviar(); consent en registrar. |
| `lib/pages/registro/registro_page.dart` | modificar | Caso RegistroPaso.consentimiento, que monta PortalConsentView. |
| `lib/services/registro_service.dart` | modificar | registrar() recibe required bool consent y manda 'consent': true. |
| `test/HU34_jeff/academic_record_model_test.dart` | crear | Parseo del contrato: decimales, null nunca 0, estado vacío y orden. |
| `test/HU34_jeff/academic_record_service_test.dart` | crear | Servicio: caché, docente, cambio de usuario, respuestas viejas, delete, reload y refreshAfterImport. |
| `test/HU34_jeff/record_card_test.dart` | crear | Funciones de record_format.dart y la tarjeta del Perfil (RF-REC-1, RF-REC-5). |
| `test/HU34_jeff/record_course_row_test.dart` | crear | Los seis casos del chip, 'N.ª vez', subtítulo, colores y fila (RF-REC-3). |
| `test/HU34_jeff/record_page_test.dart` | crear | Ruta, estados, encabezado, fecha de Lima, chips, cursos y borrado (RF-REC-2, 4, 5). |
| `test/HU34_jeff/portal_sync_consent_test.dart` | crear | PortalConsentView y consentimiento en Portal Sync (RF-REC-6). |
| `test/HU34_jeff/registro_consent_test.dart` | crear | Consentimiento en Registro (RF-REC-6). |
| `test/HU31_jeff/portal_sync_test.dart` | modificar | Agrega 'consent: false' a las llamadas a import() y reemplaza el código de alumno real por '20230001'. |
| `test/HU33_jeff/registro_controller_test.dart` | modificar | Adapta el doble a la firma nueva e inserta aceptarConsentimiento() en el flujo. |
| `test/HU33_jeff/registro_page_test.dart` | modificar | Adapta los dobles a la firma nueva, más el paso de consentimiento en el caso 2, el caso 3 y _hastaIncierto. |
| `test/HU33_jeff/registro_service_test.dart` | modificar | Agrega 'consent: false' a las llamadas existentes. |
| `specs/features/academic-record/academic-record.spec.md` | modificar | Solo agrega los [@test] de los dos archivos de test nuevos que la spec no lista. |
| `specs/features/portal-sync/portal-sync.spec.md` | modificar | BR-SYNC-F-02 remite a RF-REC-6 sin WebView; BR-SYNC-F-03 suma consent; renombra la pantalla de consentimiento. |
| `specs/features/registro/registro.spec.md` | modificar | Paso consentimiento en BR-REG-F-01, UI Behavior y Data Flow; consent en el body. |
| `docs/specs/api-contracts.md` | modificar | Sección Academic Record (GET y DELETE) y campo consent en import y register. |
| `docs/specs/feature-index.md` | modificar | Fila nueva: Récord académico. |

## Orden y cobertura

| Requisito | Tareas |
|:---|:---|
| RF-REC-1: tarjeta dentro de if (!user.isTeacher), antes de _CarreraCard (entre 'Configurar carnet' y Carrera) | 4 |
| RF-REC-1: PPA en grande e insignia de ubicación relativa | 3, 4 |
| RF-REC-1: créditos acumulados de los requeridos ('164 de 200 créditos') con barra | 3, 4 |
| RF-REC-1: enlace 'Ver mi récord completo ›' con Get.toNamed('/mi-record') | 4 |
| RF-REC-1: un docente nunca ve la tarjeta ni dispara el GET (403) | 2, 4 |
| RF-REC-1: se lee GET /academic-record/me con AcademicRecordService; no se amplía /auth/me | 2, 4 |
| RF-REC-1: si nunca sincronizó, 'Sincroniza con el portal para ver tu récord' y el toque lleva a la pantalla | 4 |
| RF-REC-1 Datos que faltan: null se omite; sin barra ni texto si falta un dato o requeridos <= 0; clamp probado con null, 0 y acumulados > requeridos | 1, 3, 4 |
| RF-REC-1 Decimales: helper double?/null, nunca _asInt; '1.5 créd.' y '3 créd.' sin '.0' | 1, 3, 5 |
| RF-REC-2: ruta '/mi-record' con AcademicRecordBinding en lib/main.dart | 6 |
| RF-REC-2: encabezado con anillo (misma función y guardas), PPA e insignia | 3, 6 |
| RF-REC-2: 'Sincronizado hace N días' calculado en hora de Lima | 6 |
| RF-REC-2: chips de ciclo del más reciente al más viejo, con el más reciente seleccionado | 7 |
| RF-REC-2: cursos del ciclo elegido en una tarjeta con promedio de periods, omitido si falta o es null | 7 |
| RF-REC-2: un solo ciclo a la vez | 7 |
| RF-REC-2: estados de carga (SkeletonPulse), error (ErrorRetry), vacío y éxito | 6 |
| RF-REC-3: nombre y 'código · N créd.' | 5 |
| RF-REC-3: los seis casos del chip; el ciclo en curso nunca en azul | 5, 7 |
| RF-REC-3: 'N.ª vez' si attempt >= 2 | 5 |
| RF-REC-3: observation debajo del código en texto pequeño | 5 |
| RF-REC-3: cursos de mallas anteriores con código y nombre originales | 5 |
| RF-REC-3: lógica del chip y de la etiqueta como función pura probada | 5 |
| RF-REC-4: estado vacío con ícono, 'Aún no tienes tu récord', línea explicativa y botón 'Sincronizar con el portal' a /portal-sync | 6 |
| RF-REC-5: botón 'Borrar mi récord de ULima++' al final; showDialog<bool> que explica la copia, la malla y la resincronización | 8 |
| RF-REC-5: DELETE /academic-record/me y la pantalla pasa al estado vacío | 2, 8 |
| RF-REC-5: un solo GetxService permanente, como MallaService, compartido por tarjeta y pantalla | 2, 4, 8 |
| RF-REC-5: el estado se invalida y se recarga tras el DELETE y en PortalSyncService.refreshAfterImport | 2, 8 |
| RF-REC-5: al volver con back, la tarjeta nunca muestra el PPA ni los créditos anteriores | 2, 4, 8 |
| RF-REC-6: pantalla única de consentimiento con qué se importa, para qué y que la contraseña se usa una vez y no se guarda; 'Acepto' y salir | 9 |
| RF-REC-6 Portal Sync: paso consent inicial; form solo tras 'Acepto'; un fallo vuelve a form sin pedir la aceptación; salir y volver a entrar la pide de nuevo | 10 |
| RF-REC-6 Registro: paso consentimiento entre datos y verificar, nunca entre el authenticator y el envío; sin aceptación no se envía | 11 |
| RF-REC-6 / RS-BE-29: consent: true en el body de POST /portal-sync/import y POST /auth/register, solo tras aceptar y nunca false | 10, 11 |
| RF-REC-6: se muestra antes de cada importación; Qué NO entra: recordar el consentimiento | 10, 11 |
| Contrato que se consume: numéricos como number, decimales, null por campo y forma de periods | 1, 2 |
| Contrato (backend): GET /academic-record/me con syncedAt, snapshot, periods y record; record del más reciente al más viejo; campo 'section' | 1, 2, 7 |
| Contrato (backend): DELETE /academic-record/me responde { ok: true } | 2, 8 |
| Contrato (backend): POST /portal-sync/import { cookies \| credentials, consent?: true } y POST /auth/register { …, consent?: true } | 10, 11 |
| Modelo de datos (backend, migración 0011): el frontend no toca la base; lo refleja con el modelo Dart del contrato | 1 |
| Fixtures: ninguna prueba reutiliza test/HU31_jeff/fixtures ni datos reales; solo JSON inventado | 1, 2, 6 |
| Nombres que no se confunden: 'Mi récord académico', nunca 'notas oficiales' | 6 |
| Cambios en otras specs: portal-sync.spec.md BR-SYNC-F-02 remite a RF-REC-6, sin WebView y sin 'la contraseña nunca sale del portal'; BR-SYNC-F-03 suma consent | 10 |
| Cambios en otras specs: registro.spec.md suma el paso consentimiento y consent: true en el body | 11 |
| Cambios en otras specs (backend): docs/specs/api-contracts.md con las dos rutas nuevas y el campo consent | 2, 10, 11 |
| Cambios en otras specs (backend): docs/specs/feature-index.md con la funcionalidad nueva | 6 |
| Qué NO entra: el resumen por ciclo completo (solo el promedio donde exista) | 7 |
| Qué NO entra: mostrar el récord a otros roles o al chatbot | 2, 4, 6 |

## Riesgos abiertos y decisiones del dueño

- **PARAR antes del merge — texto legal del consentimiento.** Las constantes de `PortalConsentView` (`titulo`, `introduccion`, `datosImportados`, `finalidad`, `contrasena`) las redacta este plan: la spec fija el CONTENIDO que exige la Ley 29733, no las palabras. No se mergea sin que el dueño lea y apruebe esos cinco textos.
- **PARAR antes del merge — textos visibles que no están en la spec ni en las maquetas.** `AGENTS.md:50` los prohíbe y estos son nuevos: 'Sincronizado hoy' y 'Sincronizado hace 1 día' (la spec solo da 'hace N días'); el estado de error de la tarjeta del Perfil; 'No se pudo cargar tu récord' (`lib/components/error_retry.dart:18` ya trae 'No se pudo cargar' por defecto); 'No se pudo borrar tu récord. Inténtalo de nuevo.'; el título, el cuerpo y los dos botones del diálogo de borrado; 'Volver' como salida del consentimiento en el registro. El dueño los aprueba o los cambia.
- **PARAR antes de desplegar — orden app/backend.** Si la app sale antes que el backend con `GET /academic-record/me`, la tarjeta del Perfil de TODOS los alumnos queda en su estado de error (404) y `/mi-record` muestra `ErrorRetry`. El backend va primero. El campo `consent` sí es inocuo con un backend viejo: `importSchema` y `registerSchema` son `z.object` no estrictos y descartan las claves que no conocen.
- `lib/services/auth_service.dart` no está en los targets de la spec, así que `logout()` no limpia `AcademicRecordService`. Mitigación: la guarda por dueño (el servicio guarda el código del alumno, el getter `record` devuelve null para otro usuario y `load()` limpia antes de cualquier `await`). Aun así, el récord del usuario anterior queda en memoria, invisible, hasta cerrar la app. Limpiarlo en `logout` obliga a sumar `auth_service.dart` a los targets y a proteger la llamada con `Get.isRegistered`, porque `test/HU02_jeff/user_cache_reset_test.dart:139` llama a `logout()` sin registrar el servicio nuevo.
- Quedan códigos de alumnos reales ya commiteados en `test/HU01_jeff/login_relogin_regression_test.dart`, `test/HU10_mel/anuncios_{unit,cajablanca,cajanegra}_test.dart` y `test/HU25_mel/networking_unit_test.dart`. Fuera de alcance: este plan solo limpia `test/HU31_jeff/portal_sync_test.dart`, porque igual lo toca. El ejemplo `164 de 200 créditos` que la spec publica en RF-REC-1 es inventado y se comprobó con `grep` contra `test/HU31_jeff/fixtures/` y `spike-portal/`.
- Detalles que salen de la maqueta aprobada y no del texto de la spec: la nota de dos dígitos ('08'), la ubicación relativa en tipo oración y el rótulo 'PPA' con el anillo de porcentaje redondeado ('82%'). Donde la maqueta y la spec chocan (la maqueta pinta 'CONV' fijo para un convalidado; la spec manda mostrar el texto de `gradeRaw`), manda la spec.
- `refreshAfterImport` ahora espera un GET más (hasta 15 s de timeout) antes de que Portal Sync muestre el resumen de la importación.
- `PortalSyncController.submit` solo atrapa `PortalSyncFailure` (`lib/pages/portal_sync/portal_sync_controller.dart:91`); otra excepción deja la pantalla en `loading`. Agujero preexistente, fuera de alcance.
- Montar `ProfilePage` entera en un test (tarea 4) no tiene precedente en el repo: hoy ningún test la monta. Si algún subwidget pide otro servicio al construirse, se le registra un doble mínimo en el test; no se toca `perfil.dart` para eso.
- Un cambio del récord hecho fuera de la app (otro dispositivo, o un borrado por soporte) no se ve hasta reiniciar la app o volver a sincronizar: `load()` sin `force` es idempotente por usuario.

---

### Tarea 1: Modelo del récord académico con números que conservan null

**Archivos:**
- Crear: `lib/models/academic_record_model.dart`
- Modificar: `specs/features/academic-record/academic-record.spec.md:173-175` (agrega el enlace `[@test]` entre la línea 173 y el título `## Nombres que no se confunden`)
- Test: `test/HU34_jeff/academic_record_model_test.dart` (crear; la carpeta `test/HU34_jeff/` todavía no existe y se crea junto con este archivo)

**Interfaces:**
- Consume: no depende de otras tareas. Del repo solo toma patrones, sin importar nada:
  - `lib/models/portal_sync_models.dart`: doc comment de librería seguido de `library;` (líneas 1-6), `String _asString(dynamic v) => v == null ? '' : v.toString();` (línea 15, se copia literal), constructores `const` con `required` y `factory PortalSyncPeriod.fromJson(Map<String, dynamic> json)` (líneas 18-26). El archivo no tiene ningún `toJson`.
  - `lib/models/official_grades_models.dart:6-7`: `double? _asDoubleOrNull(dynamic v) => v == null ? null : (v is num ? v.toDouble() : double.tryParse(v.toString()));`. Se copia literal.
  - Queda **prohibido** `_asInt` (`official_grades_models.dart:5` y `portal_sync_models.dart:8-13`), porque convierte `null` y `"1.5"` en 0.
  - `ApiClient.getJson` (`lib/services/api_client.dart:68`) llama a `_send`, que devuelve `_decode(resolved)` (línea 151). `_decode` decodifica con `jsonDecode` (línea 190) y copia la raíz con `Map<String, dynamic>.from` (líneas 198-200). Por eso el test pasa sus JSON por `jsonEncode`/`jsonDecode`: así obtiene los mismos tipos (`Map<String, dynamic>` y `List<dynamic>`).
- Produce: `lib/models/academic_record_model.dart`, sin imports de Flutter:
  - `class AcademicTotals { const AcademicTotals({required this.courses, required this.credits}); final int? courses; final double? credits; static const AcademicTotals none = AcademicTotals(courses: null, credits: null); factory AcademicTotals.fromJson(Object? json); }`
  - `class AcademicSnapshot { const AcademicSnapshot({required this.ppa, required this.relativePosition, required this.creditsAccumulated, required this.creditsRequired, required this.approved, required this.convalidated}); final double? ppa; final String? relativePosition; final double? creditsAccumulated; final double? creditsRequired; final AcademicTotals approved; final AcademicTotals convalidated; factory AcademicSnapshot.fromJson(Map<String, dynamic> json); }`
  - `class AcademicPeriodSummary { const AcademicPeriodSummary({required this.periodCode, required this.average, required this.relativePosition, required this.level, required this.convalidated, required this.enrolled, required this.approved, required this.failed}); final String periodCode; final double? average; final String? relativePosition; final int? level; final AcademicTotals convalidated; final AcademicTotals enrolled; final AcademicTotals approved; final AcademicTotals failed; factory AcademicPeriodSummary.fromJson(Map<String, dynamic> json); }`
  - `class RecordCourse { const RecordCourse({required this.code, required this.name, required this.attempt, required this.credits, required this.grade, required this.gradeRaw, required this.section, required this.observation}); final String code; final String name; final int? attempt; final double? credits; final int? grade; final String? gradeRaw; final String? section; final String? observation; factory RecordCourse.fromJson(Map<String, dynamic> json); }`
  - `class RecordPeriod { const RecordPeriod({required this.periodCode, required this.courses}); final String periodCode; final List<RecordCourse> courses; factory RecordPeriod.fromJson(Map<String, dynamic> json); }`
  - `class AcademicRecord { const AcademicRecord({required this.syncedAt, required this.snapshot, required this.periodSummaries, required this.coursesByPeriod}); final DateTime? syncedAt; /* UTC */ final AcademicSnapshot? snapshot; final List<AcademicPeriodSummary> periodSummaries; /* json 'periods' */ final List<RecordPeriod> coursesByPeriod; /* json 'record', en el orden del backend */ bool get hasRecord => syncedAt != null; static const AcademicRecord empty; factory AcademicRecord.fromJson(Map<String, dynamic> json); }`

Claves JSON exactas del contrato (spec del backend, sección "Contrato"):
- raíz: `syncedAt`, `snapshot`, `periods`, `record`;
- `snapshot`: `ppa`, `relativePosition`, `creditsAccumulated`, `creditsRequired`, `approved`, `convalidated`;
- cada grupo: `courses`, `credits`;
- `periods[]`: `periodCode`, `average`, `relativePosition`, `level`, `convalidated`, `enrolled`, `approved`, `failed`;
- `record[]`: `periodCode`, `courses`;
- `courses[]`: `code`, `name`, `attempt`, `credits`, `grade`, `gradeRaw`, `section`, `observation`.

**Ojo:** la sección se llama `section`, no `sectionCode`.

**Datos de prueba:** todos inventados. No se usan los valores del ejemplo del contrato del backend (PPA, ubicación, créditos, sección), porque algunos coinciden con los fixtures reales. Cada grupo de totales tiene números distintos, así que un grupo leído con la clave de otro hace fallar la prueba.

- [ ] **Paso 1: Escribir la prueba que falla**

Crear `test/HU34_jeff/academic_record_model_test.dart` con este contenido completo:

```dart
// test/HU34_jeff/academic_record_model_test.dart
//
// UNITARIA — HU34 (récord académico): AcademicRecord.fromJson().
// Modelo: lib/models/academic_record_model.dart
//
// Contrato de GET /academic-record/me: spec del frontend ("Contrato que se
// consume") y spec del backend (RS-BE-26). Un dato sin valor queda null y
// nunca 0 (RF-REC-1). Los créditos con decimal no se redondean. El récord
// conserva el orden del backend, del ciclo más reciente al más viejo.
//
// Todos los valores son inventados: cursos "CURSO …", códigos 1000xx y
// secciones 9xx. No se reutilizan los fixtures del backend
// (test/HU31_jeff/fixtures) ni los del spike del portal.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/models/academic_record_model.dart';

/// Pasa el mapa por `jsonEncode`/`jsonDecode` para que los tipos sean los
/// mismos que entrega `ApiClient.getJson` (`Map<String, dynamic>` y
/// `List<dynamic>`), y para que el test pueda poner null en cualquier campo.
Map<String, dynamic> _comoJson(Map<String, dynamic> valor) =>
    jsonDecode(jsonEncode(valor)) as Map<String, dynamic>;

/// Respuesta completa inventada, con la forma exacta del contrato. Cada grupo
/// de totales tiene números distintos: leer un grupo con la clave de otro falla.
Map<String, dynamic> _completo() => _comoJson(<String, dynamic>{
      'syncedAt': '2026-09-18T15:00:00Z',
      'snapshot': {
        'ppa': 14.62,
        'relativePosition': 'TERCIO SUPERIOR',
        'creditsAccumulated': 120,
        'creditsRequired': 200,
        'approved': {'courses': 40, 'credits': 118},
        'convalidated': {'courses': 1, 'credits': 2},
      },
      'periods': [
        {
          'periodCode': '2026-0',
          'average': 15.5,
          'relativePosition': 'MEDIO SUPERIOR',
          'level': 6,
          'convalidated': {'courses': 0, 'credits': 0},
          'enrolled': {'courses': 3, 'credits': 10},
          'approved': {'courses': 2, 'credits': 7},
          'failed': {'courses': 1, 'credits': 3},
        },
      ],
      'record': [
        {
          'periodCode': '2026-1',
          'courses': [
            {
              'code': '100001',
              'name': 'CURSO DE PRUEBA A',
              'attempt': 1,
              'credits': 1.5,
              'grade': 17,
              'gradeRaw': '17',
              'section': '917',
              'observation': null,
            },
          ],
        },
        {
          'periodCode': '2025-2',
          'courses': [
            {
              'code': '100002',
              'name': 'CURSO DE PRUEBA B',
              'attempt': 2,
              'credits': 3,
              'grade': null,
              'gradeRaw': 'CONV',
              'section': null,
              'observation': 'Convalidado por examen',
            },
          ],
        },
      ],
    });

Map<String, dynamic> _snapshotDe(Map<String, dynamic> json) =>
    json['snapshot'] as Map<String, dynamic>;

Map<String, dynamic> _resumenDe(Map<String, dynamic> json) =>
    (json['periods'] as List<dynamic>).first as Map<String, dynamic>;

/// El único curso del ciclo en la posición [ciclo] de `record`.
Map<String, dynamic> _cursoDe(Map<String, dynamic> json, int ciclo) {
  final periodo = (json['record'] as List<dynamic>)[ciclo] as Map<String, dynamic>;
  return (periodo['courses'] as List<dynamic>).first as Map<String, dynamic>;
}

void main() {
  group('UNITARIA · AcademicRecord.fromJson (HU34)', () {
    test('lee una respuesta completa con la forma del contrato', () {
      final r = AcademicRecord.fromJson(_completo());

      expect(r.hasRecord, isTrue);
      expect(r.syncedAt, DateTime.utc(2026, 9, 18, 15));
      expect(r.syncedAt!.isUtc, isTrue);

      final s = r.snapshot!;
      expect(s.ppa, 14.62);
      expect(s.relativePosition, 'TERCIO SUPERIOR');
      expect(s.creditsAccumulated, 120.0);
      expect(s.creditsRequired, 200.0);
      expect(s.approved.courses, 40);
      expect(s.approved.credits, 118.0);
      expect(s.convalidated.courses, 1);
      expect(s.convalidated.credits, 2.0);

      final resumen = r.periodSummaries.single;
      expect(resumen.periodCode, '2026-0');
      expect(resumen.average, 15.5);
      expect(resumen.relativePosition, 'MEDIO SUPERIOR');
      expect(resumen.level, 6);
      expect(resumen.convalidated.courses, 0);
      expect(resumen.convalidated.credits, 0.0);
      expect(resumen.enrolled.courses, 3);
      expect(resumen.enrolled.credits, 10.0);
      expect(resumen.approved.courses, 2);
      expect(resumen.approved.credits, 7.0);
      expect(resumen.failed.courses, 1);
      expect(resumen.failed.credits, 3.0);

      expect(
        r.coursesByPeriod.map((p) => p.periodCode).toList(),
        ['2026-1', '2025-2'],
      );

      final primero = r.coursesByPeriod.first.courses.single;
      expect(primero.code, '100001');
      expect(primero.name, 'CURSO DE PRUEBA A');
      expect(primero.attempt, 1);
      expect(primero.credits, 1.5);
      expect(primero.grade, 17);
      expect(primero.gradeRaw, '17');
      expect(primero.section, '917');
      expect(primero.observation, isNull);

      final convalidado = r.coursesByPeriod[1].courses.single;
      expect(convalidado.code, '100002');
      expect(convalidado.name, 'CURSO DE PRUEBA B');
      expect(convalidado.attempt, 2);
      expect(convalidado.credits, 3.0);
      expect(convalidado.grade, isNull);
      expect(convalidado.gradeRaw, 'CONV');
      expect(convalidado.section, isNull);
      expect(convalidado.observation, 'Convalidado por examen');
    });

    test('los créditos con decimal no se redondean', () {
      final json = _completo();
      _snapshotDe(json)['creditsAccumulated'] = 120.5;
      (_snapshotDe(json)['approved'] as Map<String, dynamic>)['credits'] = 118.5;
      (_resumenDe(json)['enrolled'] as Map<String, dynamic>)['credits'] = 10.5;

      final r = AcademicRecord.fromJson(json);

      expect(r.coursesByPeriod.first.courses.single.credits, 1.5);
      expect(r.coursesByPeriod[1].courses.single.credits, 3.0);
      expect(r.snapshot!.creditsAccumulated, 120.5);
      expect(r.snapshot!.approved.credits, 118.5);
      expect(r.periodSummaries.single.enrolled.credits, 10.5);
    });

    test('un número null queda null, nunca 0', () {
      final json = _completo();
      final snapshot = _snapshotDe(json);
      snapshot['ppa'] = null;
      snapshot['creditsRequired'] = null;
      snapshot.remove('creditsAccumulated');
      (snapshot['approved'] as Map<String, dynamic>)['courses'] = null;
      final resumen = _resumenDe(json);
      resumen['average'] = null;
      resumen['level'] = null;
      final curso = _cursoDe(json, 0);
      curso['attempt'] = null;
      curso['grade'] = null;
      curso['credits'] = null;

      final r = AcademicRecord.fromJson(json);

      expect(r.snapshot!.ppa, isNull);
      expect(r.snapshot!.creditsRequired, isNull);
      expect(r.snapshot!.creditsAccumulated, isNull);
      expect(r.snapshot!.approved.courses, isNull);
      // Cada número del grupo va por separado: el otro se conserva.
      expect(r.snapshot!.approved.credits, 118.0);
      expect(r.periodSummaries.single.average, isNull);
      expect(r.periodSummaries.single.level, isNull);
      final c = r.coursesByPeriod.first.courses.single;
      expect(c.attempt, isNull);
      expect(c.grade, isNull);
      expect(c.credits, isNull);
    });

    test('nunca sincronizó: hasRecord false, sin snapshot y listas vacías', () {
      final r = AcademicRecord.fromJson(_comoJson(<String, dynamic>{
        'syncedAt': null,
        'snapshot': null,
        'periods': <dynamic>[],
        'record': <dynamic>[],
      }));

      expect(r.hasRecord, isFalse);
      expect(r.syncedAt, isNull);
      expect(r.snapshot, isNull);
      expect(r.periodSummaries, isEmpty);
      expect(r.coursesByPeriod, isEmpty);
    });

    test('un número que llega como texto se lee igual', () {
      final json = _completo();
      _snapshotDe(json)['ppa'] = '14.62';
      _resumenDe(json)['average'] = 'abc';
      final curso = _cursoDe(json, 0);
      curso['grade'] = '17';
      curso['credits'] = '1.5';
      curso['attempt'] = '2';

      final r = AcademicRecord.fromJson(json);

      expect(r.snapshot!.ppa, 14.62);
      expect(r.periodSummaries.single.average, isNull);
      final c = r.coursesByPeriod.first.courses.single;
      expect(c.grade, 17);
      expect(c.credits, 1.5);
      expect(c.attempt, 2);
    });

    test('un texto vacío o en blanco queda null', () {
      final json = _completo();
      _cursoDe(json, 0)['gradeRaw'] = '';
      _cursoDe(json, 0)['section'] = '';
      _cursoDe(json, 1)['gradeRaw'] = '   ';
      _cursoDe(json, 1)['observation'] = '   ';

      final r = AcademicRecord.fromJson(json);

      expect(r.coursesByPeriod[0].courses.single.gradeRaw, isNull);
      expect(r.coursesByPeriod[0].courses.single.section, isNull);
      expect(r.coursesByPeriod[1].courses.single.gradeRaw, isNull);
      expect(r.coursesByPeriod[1].courses.single.observation, isNull);
    });

    test('un snapshot sin approved deja sus dos números en null', () {
      final json = _completo();
      _snapshotDe(json).remove('approved');

      final r = AcademicRecord.fromJson(json);

      expect(r.snapshot!.approved.courses, isNull);
      expect(r.snapshot!.approved.credits, isNull);
      expect(r.snapshot!.convalidated.courses, 1);
      expect(AcademicTotals.fromJson('no es un objeto').credits, isNull);
    });

    test('un ciclo del récord que no es objeto se descarta', () {
      final r = AcademicRecord.fromJson(_comoJson(<String, dynamic>{
        'syncedAt': '2026-09-18T15:00:00Z',
        'snapshot': null,
        'periods': <dynamic>[],
        'record': <dynamic>[
          'x',
          <String, dynamic>{
            'periodCode': '2026-1',
            'courses': <dynamic>[
              <String, dynamic>{
                'code': '100003',
                'name': 'CURSO DE PRUEBA C',
                'attempt': 1,
                'credits': 4,
                'grade': 12,
                'gradeRaw': '12',
                'section': '918',
                'observation': null,
              },
            ],
          },
        ],
      }));

      expect(r.coursesByPeriod, hasLength(1));
      expect(r.coursesByPeriod.single.periodCode, '2026-1');
      expect(r.coursesByPeriod.single.courses.single.code, '100003');
    });

    test('una nota con decimal no es un entero válido y queda null', () {
      final json = _completo();
      _cursoDe(json, 0)['grade'] = 15.5;
      _cursoDe(json, 1)['attempt'] = 2.0;

      final r = AcademicRecord.fromJson(json);

      expect(r.coursesByPeriod[0].courses.single.grade, isNull);
      expect(r.coursesByPeriod[1].courses.single.attempt, 2);
    });

    test('AcademicRecord.empty no tiene récord', () {
      expect(AcademicRecord.empty.hasRecord, isFalse);
      expect(AcademicRecord.empty.syncedAt, isNull);
      expect(AcademicRecord.empty.snapshot, isNull);
      expect(AcademicRecord.empty.periodSummaries, isEmpty);
      expect(AcademicRecord.empty.coursesByPeriod, isEmpty);
    });

    test('respeta el orden del backend y no reordena los ciclos', () {
      final json = _completo();
      json['record'] = (json['record'] as List<dynamic>).reversed.toList();

      final r = AcademicRecord.fromJson(json);

      expect(
        r.coursesByPeriod.map((p) => p.periodCode).toList(),
        ['2025-2', '2026-1'],
      );
    });
  });
}
```

En los doc comments del test, los genéricos van entre backticks (`Map<String, dynamic>`, `List<dynamic>`). Si quedan sueltos, el lint `unintended_html_in_doc_comment` de `flutter_lints` 6 los marca como HTML y el Paso 6 deja de dar `No issues found!`.

- [ ] **Paso 2: Correr la prueba y ver que falla**

```bash
cd . && $FLUTTER test test/HU34_jeff/academic_record_model_test.dart
```

Esperado: FAIL de compilación, porque el modelo no existe todavía. La salida incluye:
- `Error: Error when reading '…lib/models/academic_record_model.dart': No such file or directory`;
- `Error: Undefined name 'AcademicRecord'.` (y lo mismo con `'AcademicTotals'`);
- al final, `Failed to load "…academic_record_model_test.dart"` y `Some tests failed.`

Si falla por otra razón, por ejemplo un error de sintaxis del test, corrígelo antes de seguir.

- [ ] **Paso 3: Implementación mínima**

Crear `lib/models/academic_record_model.dart` con este contenido completo. El archivo no importa nada, ni Flutter ni otros modelos. Los helpers se copian aquí en vez de importarse.

```dart
/// Modelos del récord académico que ULima++ copia de miUlima
/// (`GET /academic-record/me`).
///
/// `fromJson` a mano con coerción defensiva, como el resto del repo, con una
/// diferencia: aquí un dato sin valor queda `null`, nunca 0 (RF-REC-1). La UI
/// lo omite en vez de pintar un 0 que el alumno tomaría por real. Por eso no se
/// usa `_asInt` (`official_grades_models.dart:5`), que convierte `null` y
/// `"1.5"` en 0.
///
/// `credits`, `ppa`, `average` y los `credits*` pueden traer decimal y se
/// guardan como `double` sin redondear. `attempt`, `grade`, `level` y
/// `courses` son enteros.
library;

/// `double` o `null`. Copia de `official_grades_models.dart:6-7`.
double? _asDoubleOrNull(dynamic v) =>
    v == null ? null : (v is num ? v.toDouble() : double.tryParse(v.toString()));

/// `int` o `null`. Un número con decimal (una nota 15.5) no es un entero
/// válido y queda `null`; 2.0 sí se lee como 2.
int? _asIntOrNull(dynamic v) {
  if (v is int) return v;
  if (v is num) return v == v.truncateToDouble() ? v.toInt() : null;
  if (v is String) return int.tryParse(v.trim());
  return null;
}

String _asString(dynamic v) => v == null ? '' : v.toString();

/// Texto sin espacios en los bordes, o `null` si no hay texto.
String? _asStringOrNull(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

Map<String, dynamic>? _asMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;

/// Los elementos que son objetos; el resto se descarta.
List<Map<String, dynamic>> _asMapList(dynamic v) => v is List
    ? v.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList()
    : const <Map<String, dynamic>>[];

/// Cantidad de cursos y de créditos de un grupo (aprobados, convalidados,
/// matriculados o desaprobados). Cada número es `null` por separado.
class AcademicTotals {
  const AcademicTotals({required this.courses, required this.credits});

  final int? courses;
  final double? credits;

  /// Grupo sin datos: lo que queda cuando el JSON no trae el objeto.
  static const AcademicTotals none = AcademicTotals(courses: null, credits: null);

  factory AcademicTotals.fromJson(Object? json) {
    final map = _asMap(json);
    if (map == null) return none;
    return AcademicTotals(
      courses: _asIntOrNull(map['courses']),
      credits: _asDoubleOrNull(map['credits']),
    );
  }
}

/// Información general del alumno según miUlima: la foto acumulada
/// (RS-BE-24 y RS-BE-25).
class AcademicSnapshot {
  const AcademicSnapshot({
    required this.ppa,
    required this.relativePosition,
    required this.creditsAccumulated,
    required this.creditsRequired,
    required this.approved,
    required this.convalidated,
  });

  final double? ppa;

  /// Tal como la da el portal, en mayúsculas ("TERCIO SUPERIOR").
  final String? relativePosition;
  final double? creditsAccumulated;
  final double? creditsRequired;
  final AcademicTotals approved;
  final AcademicTotals convalidated;

  factory AcademicSnapshot.fromJson(Map<String, dynamic> json) =>
      AcademicSnapshot(
        ppa: _asDoubleOrNull(json['ppa']),
        relativePosition: _asStringOrNull(json['relativePosition']),
        creditsAccumulated: _asDoubleOrNull(json['creditsAccumulated']),
        creditsRequired: _asDoubleOrNull(json['creditsRequired']),
        approved: AcademicTotals.fromJson(json['approved']),
        convalidated: AcademicTotals.fromJson(json['convalidated']),
      );
}

/// Resumen de un ciclo (un elemento de `periods`). El backend solo tiene
/// algunos ciclos, así que un ciclo del récord puede no tener resumen.
class AcademicPeriodSummary {
  const AcademicPeriodSummary({
    required this.periodCode,
    required this.average,
    required this.relativePosition,
    required this.level,
    required this.convalidated,
    required this.enrolled,
    required this.approved,
    required this.failed,
  });

  final String periodCode;
  final double? average;
  final String? relativePosition;
  final int? level;
  final AcademicTotals convalidated;
  final AcademicTotals enrolled;
  final AcademicTotals approved;
  final AcademicTotals failed;

  factory AcademicPeriodSummary.fromJson(Map<String, dynamic> json) =>
      AcademicPeriodSummary(
        periodCode: _asString(json['periodCode']),
        average: _asDoubleOrNull(json['average']),
        relativePosition: _asStringOrNull(json['relativePosition']),
        level: _asIntOrNull(json['level']),
        convalidated: AcademicTotals.fromJson(json['convalidated']),
        enrolled: AcademicTotals.fromJson(json['enrolled']),
        approved: AcademicTotals.fromJson(json['approved']),
        failed: AcademicTotals.fromJson(json['failed']),
      );
}

/// Un curso del récord. Los cursos de mallas anteriores traen su código y su
/// nombre originales.
class RecordCourse {
  const RecordCourse({
    required this.code,
    required this.name,
    required this.attempt,
    required this.credits,
    required this.grade,
    required this.gradeRaw,
    required this.section,
    required this.observation,
  });

  final String code;
  final String name;

  /// Vez que se lleva el curso (1, 2, 3…).
  final int? attempt;
  final double? credits;

  /// Nota entera de 0 a 20, o `null` (ciclo en curso, convalidación, retiro…).
  final int? grade;

  /// Texto original de la celda NOTA del portal; `null` si venía vacía.
  final String? gradeRaw;

  /// Sección. En el JSON la clave es `section`, no `sectionCode`.
  final String? section;
  final String? observation;

  factory RecordCourse.fromJson(Map<String, dynamic> json) => RecordCourse(
        code: _asString(json['code']),
        name: _asString(json['name']),
        attempt: _asIntOrNull(json['attempt']),
        credits: _asDoubleOrNull(json['credits']),
        grade: _asIntOrNull(json['grade']),
        gradeRaw: _asStringOrNull(json['gradeRaw']),
        section: _asStringOrNull(json['section']),
        observation: _asStringOrNull(json['observation']),
      );
}

/// Los cursos de un ciclo del récord (un elemento de `record`).
class RecordPeriod {
  const RecordPeriod({required this.periodCode, required this.courses});

  final String periodCode;
  final List<RecordCourse> courses;

  factory RecordPeriod.fromJson(Map<String, dynamic> json) => RecordPeriod(
        periodCode: _asString(json['periodCode']),
        courses: _asMapList(json['courses']).map(RecordCourse.fromJson).toList(),
      );
}

/// Respuesta de `GET /academic-record/me`.
class AcademicRecord {
  const AcademicRecord({
    required this.syncedAt,
    required this.snapshot,
    required this.periodSummaries,
    required this.coursesByPeriod,
  });

  /// Fecha de la importación que guardó esta copia, en UTC. `null` si el
  /// alumno nunca sincronizó con un récord de confianza y su consentimiento.
  final DateTime? syncedAt;

  /// Información general; `null` si el backend no la tiene.
  final AcademicSnapshot? snapshot;

  /// Resumen por ciclo (clave JSON `periods`).
  final List<AcademicPeriodSummary> periodSummaries;

  /// Cursos agrupados por ciclo (clave JSON `record`), en el orden del
  /// backend: del ciclo más reciente al más viejo (RS-BE-26). Aquí no se
  /// reordena.
  final List<RecordPeriod> coursesByPeriod;

  /// Sin `syncedAt` no hay récord y la pantalla muestra su estado vacío
  /// (RF-REC-4).
  bool get hasRecord => syncedAt != null;

  /// Sin récord: el estado que queda tras borrarlo (RF-REC-5).
  static const AcademicRecord empty = AcademicRecord(
    syncedAt: null,
    snapshot: null,
    periodSummaries: <AcademicPeriodSummary>[],
    coursesByPeriod: <RecordPeriod>[],
  );

  factory AcademicRecord.fromJson(Map<String, dynamic> json) {
    final raw = json['syncedAt'];
    final snapshot = _asMap(json['snapshot']);
    return AcademicRecord(
      syncedAt: raw is String ? DateTime.tryParse(raw)?.toUtc() : null,
      snapshot: snapshot == null ? null : AcademicSnapshot.fromJson(snapshot),
      periodSummaries: _asMapList(json['periods'])
          .map(AcademicPeriodSummary.fromJson)
          .toList(),
      coursesByPeriod:
          _asMapList(json['record']).map(RecordPeriod.fromJson).toList(),
    );
  }
}
```

El código anterior ya cumple estas reglas. No las "arregles":
- ningún `?? 0` y ningún `_asInt`;
- `coursesByPeriod` y `periodSummaries` no se ordenan;
- en los doc comments, todo genérico o texto entre `<…>` va entre backticks, por el lint `unintended_html_in_doc_comment`;
- dentro de `static const … = AcademicRecord(...)` no se escribe `const`, por el lint `unnecessary_const`;
- todas las funciones de nivel superior tienen tipos explícitos, por el lint `strict_top_level_inference`.

- [ ] **Paso 4: Correr la prueba y ver que pasa**

```bash
cd . && $FLUTTER test test/HU34_jeff/academic_record_model_test.dart
```

Esperado: PASS. La última línea es `+11: All tests passed!`.

- [ ] **Paso 5: Enlazar el test en la spec**

En `specs/features/academic-record/academic-record.spec.md`, sección `## Contrato que se consume`, usa Edit con este reemplazo exacto (líneas 173-175 del archivo actual).

Reemplazar esto:

```markdown
cada grupo con `{ courses, credits }`. El detalle completo está en la spec del backend.

## Nombres que no se confunden
```

por esto:

```markdown
cada grupo con `{ courses, credits }`. El detalle completo está en la spec del backend.

`[@test] ../../../test/HU34_jeff/academic_record_model_test.dart`

## Nombres que no se confunden
```

No cambies ninguna otra línea de la spec. Compruébalo:

```bash
cd . && git diff --stat specs/features/academic-record/academic-record.spec.md
```

Esperado: `1 file changed, 2 insertions(+)`.

- [ ] **Paso 6: Análisis estático e issues preexistentes**

Primero, los dos archivos de esta tarea:

```bash
cd . && $FLUTTER analyze lib/models/academic_record_model.dart test/HU34_jeff/academic_record_model_test.dart
```

Esperado: `No issues found! (ran in …)`. Si aparece algún issue, corrígelo en esos dos archivos y vuelve a correr los Pasos 4 y 6.

Después, el proyecto entero. Nadie midió todavía los issues preexistentes (riesgo abierto del esqueleto), y esta tarea los mide:

```bash
cd . && $FLUTTER analyze 2>&1 | grep -E "issues? found|academic_record_model"
```

Esperado: una sola línea, `N issues found. (ran in …)` o `No issues found! (ran in …)`, y ninguna línea que nombre `academic_record_model`. Todos esos N issues son preexistentes, porque todavía nadie importa los dos archivos nuevos y la spec no se analiza. Anota N en tu reporte como "issues preexistentes" y no corrijas ninguno en esta tarea.

Y guarda esa línea en un archivo, porque las ocho tareas que siguen la comparan y cada una corre en su propia sesión, sin tu reporte a la vista:

```bash
cd . && $FLUTTER analyze 2>&1 | grep -E "issues? found" | sed 's/ (ran in .*//' > $TMP/plan-fe/analyze-baseline.txt && cat $TMP/plan-fe/analyze-baseline.txt
```

Esperado: una sola línea, la misma de arriba pero sin el `(ran in …)`. Ese archivo vive fuera del repo y no se commitea. Las tareas siguientes lo leen con `cat` para comparar; si no existe, la tarea 1 no se corrió en esta máquina y hay que medir la línea base antes de seguir.

- [ ] **Paso final: Commit**

Revisa primero que el árbol no tenga cambios ajenos que puedas mezclar sin querer:

```bash
cd . && git status --short --untracked-files=all
```

Esperado, en cualquier orden, exactamente estas tres líneas:

```
 M specs/features/academic-record/academic-record.spec.md
?? lib/models/academic_record_model.dart
?? test/HU34_jeff/academic_record_model_test.dart
```

Si aparece otro archivo, no lo agregues ni lo toques: puede ser de otra sesión.

```bash
cd . && git add lib/models/academic_record_model.dart test/HU34_jeff/academic_record_model_test.dart specs/features/academic-record/academic-record.spec.md && git diff --cached --stat
```

Esperado: `git diff --cached --stat` muestra exactamente esos 3 archivos y `3 files changed`.

```bash
cd . && git commit -m "feat(academic-record): modelo del récord con números que conservan null"
```

El autor ya está configurado en git. El mensaje no lleva trailer `Co-Authored-By`. No hagas push.

### Tarea 2: AcademicRecordService: estado único, borrado e invalidación tras importar

**Archivos:**
- Crear: `lib/services/academic_record_service.dart`
- Modificar: `lib/services/portal_sync_service.dart:1-4` (imports), `:110` (doc comment: CINCO → SEIS), `:122-123` (doc comment: capa 6) y `:137-142` (cuerpo de `refreshAfterImport`)
- Modificar: `lib/main.dart:13` (import) y `lib/main.dart:65` (registro permanente)
- Modificar: `docs/specs/api-contracts.md:499` (sección nueva al final del archivo; 499 es la última línea)
- Modificar: `specs/features/academic-record/academic-record.spec.md:134-137` (nuevo `[@test]` después de la L135, antes del título de RF-REC-6)
- Test: `test/HU34_jeff/academic_record_service_test.dart` (crear)

**Precondición:** la tarea 1 ya tiene su commit. Comprobarlo antes de empezar:

```bash
cd . && ls lib/models/academic_record_model.dart test/HU34_jeff/ && git status --short
```

Deben existir `lib/models/academic_record_model.dart` y la carpeta `test/HU34_jeff/`, y el árbol debe estar limpio. Todo se hace en `.`, rama `feat/record-academico-fe`. Los archivos existentes se editan con Edit sobre las anclas literales de abajo. No se usan `cp`, `mv` ni `git stash`. `lib/services/auth_service.dart` no se toca.

**Interfaces:**
- Consume:
  - Tarea 1 (`lib/models/academic_record_model.dart`): `factory AcademicRecord.fromJson(Map<String, dynamic> json)`; `static const AcademicRecord empty` (con `hasRecord` false); `bool get hasRecord => syncedAt != null`; `final AcademicSnapshot? snapshot`; `AcademicSnapshot.ppa` (`double?`).
  - `lib/services/api_client.dart:42-43`: `ApiClient({String? configuredBaseUrl})`.
  - `lib/services/api_client.dart:68-73`: `Future<Map<String, dynamic>> getJson(String path, {String? token, Map<String, String?> query = const {}, bool suppressSessionExpiry = false})`.
  - `lib/services/api_client.dart:99-102`: `Future<Map<String, dynamic>> deleteJson(String path, {String? token})`.
  - `lib/services/api_client.dart:11-16`: `ApiException({required this.statusCode, required this.code, required this.message, this.details})`, constructor **no** `const` (la clase está en `:10-25`).
  - `lib/services/api_client.dart:128`: `_send` llama a `request.send()` sin `.timeout()`; por eso cada servicio pone el suyo.
  - `lib/services/auth_service.dart:18`: `static AuthService get to => Get.find();`.
  - `lib/services/auth_service.dart:59-60`: `UserModel? get currentUser` y `Rx<UserModel?> get currentUserRx`.
  - `lib/services/auth_service.dart:179`: `Future<void> refreshCurrentUser()`.
  - `lib/models/user_model.dart:29-45`: `UserModel({required String code, required String firstName, required String lastName, String? avatarUrl, String? fullName, required String email, required String role, String? teacherLabel, int? careerId, int? especialidadPrincipal, List<int>? especialidadesInteres, required String currentCycle, required bool setupComplete, CourseProgress? courseProgress})`; `final String code` (`:7`) y `bool get isTeacher => role == 'teacher' || role == 'docente';` (`:106`).
  - `lib/services/portal_sync_service.dart:20`: `PortalSyncService({ApiClient? apiClient})`.
  - `lib/services/portal_sync_service.dart:126`: `Future<void> refreshAfterImport({String? token})`.
  - `lib/services/malla_service.dart:14-15`: patrón `class MallaService extends GetxService { static MallaService get to => Get.find(); … }`.
  - GetX 4.7.3: `bool isRegistered<S>({String? tag})`, `S put<S>(S dependency, {String? tag, bool permanent = false, InstanceBuilderCallback<S>? builder})`, `class Rxn<T> extends Rx<T?>`, `RxBool`, `.obs`, y `void reset({bool clearRouteBindings = true})` (extensión `GetResetExt`, que ya se usa como tear-off en `tearDown(Get.reset)` en el repo). `Get.put` de un `GetxService` agenda `onReady` con `Get.engine.addPostFrameCallback`, y `Get.engine` es `WidgetsFlutterBinding.ensureInitialized()`.
- Produce:
  - `lib/services/academic_record_service.dart`:
    ```dart
    class AcademicRecordService extends GetxService {
      AcademicRecordService({ApiClient? apiClient});
      static AcademicRecordService get to => Get.find();
      static const Duration loadTimeout = Duration(seconds: 15);
      static const Duration deleteTimeout = Duration(seconds: 15);
      static const String deleteErrorMessage = 'No se pudo borrar tu récord. Inténtalo de nuevo.';
      AcademicRecord? get record;  // null salvo que haya una copia cargada PARA el usuario actual; lee el Rx para que Obx se suscriba
      bool get isLoading;
      bool get hasError;
      Future<void> load({bool force = false});  // nunca lanza; no hace nada sin usuario o con docente; sin force es idempotente por usuario
      Future<void> reload();  // clear() y luego load(force: true)
      void clear();
      Future<void> deleteRecord();  // DELETE '/academic-record/me'; ante un fallo lanza AcademicRecordFailure(deleteErrorMessage); si sale bien, record = AcademicRecord.empty y recarga
    }
    class AcademicRecordFailure implements Exception { const AcademicRecordFailure(this.message); final String message; }
    ```
  - `lib/main.dart` registra `Get.put<AcademicRecordService>(AcademicRecordService(), permanent: true);`.
  - `PortalSyncService.refreshAfterImport` sigue haciendo lo de antes y además llama a `await AcademicRecordService.to.reload()`, con la guarda `Get.isRegistered<AcademicRecordService>()` y su propio `try`.

**Datos de prueba:** los mismos inventados de la tarea 1 (PPA 14.62, "TERCIO SUPERIOR", 120 de 200 créditos, curso `100001` "CURSO DE PRUEBA A", sección `917`). No se usan los del ejemplo del contrato del backend, porque la ubicación relativa y los créditos requeridos de ese ejemplo coinciden con los fixtures reales del portal.

- [ ] **Paso 1: Escribir la prueba que falla**

Crear `test/HU34_jeff/academic_record_service_test.dart` con este contenido completo:

```dart
// test/HU34_jeff/academic_record_service_test.dart
//
// UNITARIA — HU34 (récord académico): AcademicRecordService (RF-REC-5).
// Servicio: lib/services/academic_record_service.dart
//
// Estado único del récord: caché por usuario, guarda de docente, respuestas
// viejas, borrado e invalidación tras importar.
//
// Datos inventados: ningún valor sale de un récord real, y son los mismos que
// usa test/HU34_jeff/academic_record_model_test.dart.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/services/academic_record_service.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/portal_sync_service.dart';

UserModel _user({String code = '20230001', String role = 'student'}) =>
    UserModel(
      code: code,
      firstName: 'Alumna',
      lastName: 'De Prueba',
      email: 'test@aloe.ulima.edu.pe',
      role: role,
      currentCycle: '2026-1',
      setupComplete: true,
    );

class _FakeAuthService extends AuthService {
  _FakeAuthService(UserModel? user) : userRx = Rx<UserModel?>(user);

  final Rx<UserModel?> userRx;

  @override
  UserModel? get currentUser => userRx.value;

  @override
  Rx<UserModel?> get currentUserRx => userRx;

  @override
  Future<void> refreshCurrentUser() async {}
}

class _FakeRecordApi extends ApiClient {
  _FakeRecordApi(this.getResponses) : super(configuredBaseUrl: 'http://test');

  /// Respuestas del GET, en orden; la última se repite. Un Map se devuelve,
  /// un Completer se espera y cualquier otra cosa se lanza.
  final List<Object> getResponses;
  Object? deleteError;
  int getCalls = 0;
  int deleteCalls = 0;
  String? lastGetPath;
  String? lastDeletePath;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    String? token,
    Map<String, String?> query = const {},
    bool suppressSessionExpiry = false,
  }) async {
    lastGetPath = path;
    final i =
        getCalls < getResponses.length ? getCalls : getResponses.length - 1;
    final r = getResponses[i];
    getCalls++;
    if (r is Completer<Map<String, dynamic>>) return r.future;
    if (r is Map<String, dynamic>) return r;
    throw r;
  }

  @override
  Future<Map<String, dynamic>> deleteJson(String path, {String? token}) async {
    deleteCalls++;
    lastDeletePath = path;
    if (deleteError != null) throw deleteError!;
    return <String, dynamic>{'ok': true};
  }
}

Map<String, dynamic> _syncedJson({Object? ppa = 14.62}) => <String, dynamic>{
      'syncedAt': '2026-09-18T15:00:00Z',
      'snapshot': <String, dynamic>{
        'ppa': ppa,
        'relativePosition': 'TERCIO SUPERIOR',
        'creditsAccumulated': 120,
        'creditsRequired': 200,
        'approved': <String, dynamic>{'courses': 40, 'credits': 118},
        'convalidated': <String, dynamic>{'courses': 1, 'credits': 2},
      },
      'periods': <dynamic>[],
      'record': <dynamic>[
        <String, dynamic>{
          'periodCode': '2026-1',
          'courses': <dynamic>[
            <String, dynamic>{
              'code': '100001',
              'name': 'CURSO DE PRUEBA A',
              'attempt': 1,
              'credits': 3,
              'grade': null,
              'gradeRaw': null,
              'section': '917',
              'observation': null,
            },
          ],
        },
      ],
    };

Map<String, dynamic> _neverSyncedJson() => <String, dynamic>{
      'syncedAt': null,
      'snapshot': null,
      'periods': <dynamic>[],
      'record': <dynamic>[],
    };

_FakeAuthService _loguear(UserModel? user) {
  final auth = _FakeAuthService(user);
  Get.put<AuthService>(auth);
  return auth;
}

AcademicRecordService _servicio(_FakeRecordApi api) =>
    Get.put<AcademicRecordService>(AcademicRecordService(apiClient: api));

PortalSyncService _portalSync() =>
    PortalSyncService(apiClient: ApiClient(configuredBaseUrl: 'http://test'));

void main() {
  // Get.put de un GetxService agenda onReady con
  // Get.engine.addPostFrameCallback, que necesita el binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(Get.reset);
  tearDown(Get.reset);

  group('UNITARIA · AcademicRecordService (HU34)', () {
    test('caso 1: un alumno pide GET /academic-record/me una vez y guarda el récord',
        () async {
      _loguear(_user());
      final api = _FakeRecordApi([_syncedJson()]);
      final s = _servicio(api);

      await s.load();

      expect(api.lastGetPath, '/academic-record/me');
      expect(api.getCalls, 1);
      expect(s.record!.snapshot!.ppa, 14.62);
      expect(s.isLoading, isFalse);
      expect(s.hasError, isFalse);
    });

    test('caso 2: sin force no vuelve a pedir; con force sí', () async {
      _loguear(_user());
      final api = _FakeRecordApi([_syncedJson(), _syncedJson(ppa: 15.1)]);
      final s = _servicio(api);

      await s.load();
      await s.load();
      expect(api.getCalls, 1);

      await s.load(force: true);
      expect(api.getCalls, 2);
      expect(s.record!.snapshot!.ppa, 15.1);
    });

    test('caso 3: un docente o una sesión sin usuario nunca disparan el GET',
        () async {
      final auth = _loguear(_user(code: 'docente.test', role: 'teacher'));
      final api = _FakeRecordApi([_syncedJson()]);
      final s = _servicio(api);

      await s.load();
      await s.load(force: true);
      await s.reload();
      expect(api.getCalls, 0);
      expect(s.record, isNull);
      expect(s.isLoading, isFalse);

      auth.userRx.value = null;
      await s.load(force: true);
      expect(api.getCalls, 0);
      expect(s.record, isNull);
    });

    test(
        'caso 4: un fallo no lanza: deja hasError y ningún récord, y el '
        'siguiente load() reintenta', () async {
      _loguear(_user());
      final errores = <Object>[
        Exception('socket'),
        ApiException(statusCode: 500, code: 'HTTP_ERROR', message: 'x'),
      ];
      for (final error in errores) {
        final api = _FakeRecordApi([error, _syncedJson()]);
        // Sin registrarlo: load() solo busca AuthService.
        final s = AcademicRecordService(apiClient: api);

        await expectLater(s.load(), completes);
        expect(s.hasError, isTrue, reason: '$error');
        expect(s.record, isNull, reason: '$error');
        expect(s.isLoading, isFalse, reason: '$error');

        await s.load();
        expect(api.getCalls, 2, reason: 'un fallo no deja la caché marcada');
        expect(s.hasError, isFalse);
        expect(s.record!.snapshot!.ppa, 14.62);
      }
    });

    test('caso 5: dos load() simultáneos hacen un solo GET', () async {
      _loguear(_user());
      final pendiente = Completer<Map<String, dynamic>>();
      final api = _FakeRecordApi([pendiente]);
      final s = _servicio(api);

      final a = s.load();
      final b = s.load();
      expect(s.isLoading, isTrue);

      pendiente.complete(_syncedJson());
      await Future.wait([a, b]);
      expect(api.getCalls, 1);
      expect(s.record!.snapshot!.ppa, 14.62);
      expect(s.isLoading, isFalse);
    });

    test('caso 6: otro usuario sin logout de por medio nunca ve el récord anterior',
        () async {
      final auth = _loguear(_user());
      final api = _FakeRecordApi([_syncedJson(), _neverSyncedJson()]);
      final s = _servicio(api);
      await s.load();
      expect(s.record, isNotNull);

      auth.userRx.value = _user(code: 'otro.alumno.test');
      expect(s.record, isNull, reason: 'ni siquiera antes de llamar a load()');

      await s.load();
      expect(api.getCalls, 2);
      expect(s.record!.hasRecord, isFalse);
    });

    test('caso 7: una respuesta que llega después de clear() se descarta',
        () async {
      _loguear(_user());
      final vieja = Completer<Map<String, dynamic>>();
      final nueva = Completer<Map<String, dynamic>>();
      final api = _FakeRecordApi([vieja, nueva]);
      final s = _servicio(api);

      unawaited(s.load());
      s.clear();
      final f = s.load();

      vieja.complete(_syncedJson());
      await Future<void>.delayed(Duration.zero);
      expect(s.record, isNull, reason: 'la respuesta vieja no se pinta');
      expect(s.isLoading, isTrue, reason: 'la carga nueva sigue en vuelo');

      nueva.complete(_syncedJson(ppa: 15.1));
      await f;
      expect(s.record!.snapshot!.ppa, 15.1);
      expect(s.isLoading, isFalse);
      expect(api.getCalls, 2);
    });

    test('caso 8: reload() vacía el estado antes de pedir', () async {
      _loguear(_user());
      final segundo = Completer<Map<String, dynamic>>();
      final api = _FakeRecordApi([_syncedJson(), segundo]);
      final s = _servicio(api);
      await s.load();

      final f = s.reload();
      expect(s.record, isNull, reason: 'nunca se ve el PPA anterior');
      expect(s.isLoading, isTrue);

      segundo.complete(_syncedJson(ppa: 15.1));
      await f;
      expect(s.record!.snapshot!.ppa, 15.1);
    });

    test(
        'caso 9: deleteRecord llama al DELETE, muestra el estado vacío al '
        'instante y recarga', () async {
      _loguear(_user());
      final recarga = Completer<Map<String, dynamic>>();
      final api = _FakeRecordApi([_syncedJson(), recarga]);
      final s = _servicio(api);
      await s.load();

      final f = s.deleteRecord();
      await Future<void>.delayed(Duration.zero);
      expect(api.deleteCalls, 1);
      expect(api.lastDeletePath, '/academic-record/me');
      expect(s.record, isNotNull,
          reason: 'el estado vacío se ve sin esperar la recarga');
      expect(s.record!.hasRecord, isFalse);
      expect(api.getCalls, 2, reason: 'recarga para confirmar el borrado');

      recarga.complete(_neverSyncedJson());
      await f;
      expect(s.record!.hasRecord, isFalse);
      expect(s.isLoading, isFalse);
    });

    test('caso 10: si la recarga posterior al DELETE falla, el estado sigue vacío',
        () async {
      _loguear(_user());
      final api = _FakeRecordApi([_syncedJson(), Exception('socket')]);
      final s = _servicio(api);
      await s.load();

      await s.deleteRecord();

      expect(s.record, isNotNull);
      expect(s.record!.hasRecord, isFalse);
      expect(api.getCalls, 2);
    });

    test('caso 11: si el DELETE falla, lanza AcademicRecordFailure y conserva el récord',
        () async {
      _loguear(_user());
      final api = _FakeRecordApi([_syncedJson()])
        ..deleteError =
            ApiException(statusCode: 500, code: 'HTTP_ERROR', message: 'x');
      final s = _servicio(api);
      await s.load();

      await expectLater(
        s.deleteRecord(),
        throwsA(
          isA<AcademicRecordFailure>().having(
            (e) => e.message,
            'message',
            AcademicRecordService.deleteErrorMessage,
          ),
        ),
      );
      expect(s.record!.hasRecord, isTrue);
      expect(s.record!.snapshot!.ppa, 14.62);
      expect(api.getCalls, 1, reason: 'sin borrado no hay recarga');
    });

    test('caso 12: un docente no llama al DELETE', () async {
      _loguear(_user(code: 'docente.test', role: 'teacher'));
      final api = _FakeRecordApi([_syncedJson()]);
      final s = _servicio(api);

      await s.deleteRecord();

      expect(api.deleteCalls, 0);
      expect(api.getCalls, 0);
    });
  });

  group('UNITARIA · refreshAfterImport invalida el récord (HU34)', () {
    // MallaService no se registra a propósito: su Get.find falla dentro del
    // try compartido de refreshAfterImport. Que el récord igual se recargue
    // prueba que su bloque tiene un try propio.
    test('caso 13: vacía el récord al instante y lo vuelve a pedir', () async {
      _loguear(_user());
      final segundo = Completer<Map<String, dynamic>>();
      final api = _FakeRecordApi([_syncedJson(), segundo]);
      _servicio(api);
      await AcademicRecordService.to.load();
      expect(AcademicRecordService.to.record!.snapshot!.ppa, 14.62);

      final f = _portalSync().refreshAfterImport();
      await Future<void>.delayed(Duration.zero);
      expect(AcademicRecordService.to.record, isNull,
          reason: 'nunca se ve el PPA anterior');
      expect(api.getCalls, 2);

      segundo.complete(_syncedJson(ppa: 15.1));
      await f;
      expect(AcademicRecordService.to.record!.snapshot!.ppa, 15.1);
    });

    test('caso 14: sin AcademicRecordService registrado, no lanza', () async {
      _loguear(_user());
      await expectLater(_portalSync().refreshAfterImport(), completes);
    });
  });
}
```

El test **no** importa `academic_record_model.dart`: nunca nombra sus tipos (llega a ellos por inferencia, con `s.record!.snapshot!.ppa`), y un import sin usar sería un `unused_import` en `flutter analyze`.

- [ ] **Paso 2: Correr la prueba y ver que falla**

```bash
cd . && $FLUTTER test test/HU34_jeff/academic_record_service_test.dart
```

Esperado: FAIL de compilación. El runner muestra `Failed to load "…/test/HU34_jeff/academic_record_service_test.dart"` y, entre otros, estos errores:
- `Error: Error when reading 'lib/services/academic_record_service.dart': No such file or directory`, en `import 'package:ulima_plus/services/academic_record_service.dart';`;
- `Error: Type 'AcademicRecordService' not found.` (en la firma de `_servicio`);
- `Error: Type 'AcademicRecordFailure' not found.` (en `isA<AcademicRecordFailure>()`);
- `Error: Undefined name 'AcademicRecordService'.` (en `AcademicRecordService.to` y `AcademicRecordService.deleteErrorMessage`).

Todos los errores deben apuntar al archivo que falta. Si aparece alguno sobre `user_model.dart`, `auth_service.dart`, `api_client.dart` o `portal_sync_service.dart`, el ancla o la firma cambió: detente y revisa.

- [ ] **Paso 3: Implementación mínima**

**3.1 Crear `lib/services/academic_record_service.dart`** con este contenido completo. No importa `dart:async`: `Future` y `.timeout` vienen de `dart:core` (`dart:core` reexporta `Future` de `dart:async`), y con ese import sobraría un `unnecessary_import`. Usa `debugPrint`, nunca `print`.

```dart
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/academic_record_model.dart';
import 'api_client.dart';
import 'auth_service.dart';

/// Estado único del récord académico del alumno (RF-REC-5).
///
/// La tarjeta del Perfil y la pantalla `/mi-record` leen de este mismo
/// servicio, así que nunca muestran dos versiones del récord. El estado se
/// vacía y se vuelve a pedir tras el `DELETE` ([deleteRecord]) y en
/// `PortalSyncService.refreshAfterImport` ([reload]).
///
/// **Guarda por dueño.** `auth_service.dart` no está entre los archivos de la
/// spec, así que `logout()` no limpia este servicio. Por eso se guarda el
/// código del alumno dueño del estado: [record] devuelve null para cualquier
/// otro usuario, y [load] descarta el estado ajeno antes del primer `await`.
/// El récord anterior queda en memoria, invisible, hasta la próxima carga o
/// hasta cerrar la app.
///
/// Un docente nunca dispara el `GET` ni el `DELETE`: para él la ruta responde
/// 403 (RF-REC-1).
class AcademicRecordService extends GetxService {
  AcademicRecordService({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  static AcademicRecordService get to => Get.find();

  /// `ApiClient` no impone timeout (`_send` llama a `request.send()` sin
  /// `.timeout()`): sin esto, la tarjeta del Perfil se quedaría cargando para
  /// siempre si el backend no responde.
  static const Duration loadTimeout = Duration(seconds: 15);
  static const Duration deleteTimeout = Duration(seconds: 15);

  /// Mensaje que la pantalla muestra cuando el `DELETE` falla.
  static const String deleteErrorMessage =
      'No se pudo borrar tu récord. Inténtalo de nuevo.';

  final ApiClient _api;
  final Rxn<AcademicRecord> _record = Rxn<AcademicRecord>();
  final RxBool _loading = false.obs;
  final RxBool _hasError = false.obs;

  /// Alumno dueño del estado, o de la carga en vuelo.
  String? _ownerCode;

  /// Sube con cada [clear] y con cada carga nueva. Una respuesta que vuelve
  /// con otro número es vieja y se descarta.
  int _generation = 0;

  /// Carga en vuelo: dos [load] seguidos comparten un solo `GET`.
  Future<void>? _inFlight;

  /// El récord del usuario actual, o null si todavía no hay una copia cargada
  /// para él. Con [AcademicRecord.hasRecord] en false es el estado vacío
  /// (nunca sincronizó, o borró su récord).
  AcademicRecord? get record {
    // El Rx se lee SIEMPRE primero: así el Obx que llama a este getter se
    // suscribe aunque después se devuelva null.
    final r = _record.value;
    final code = AuthService.to.currentUser?.code;
    return (code != null && code == _ownerCode) ? r : null;
  }

  bool get isLoading => _loading.value;
  bool get hasError => _hasError.value;

  /// Olvida el récord y descarta la carga en vuelo.
  void clear() {
    _generation++;
    _inFlight = null;
    _ownerCode = null;
    _record.value = null;
    _hasError.value = false;
    _loading.value = false;
  }

  /// Pide `GET /academic-record/me`. Nunca lanza: un fallo queda en
  /// [hasError]. Sin usuario o con un docente no hace nada. Sin [force] es
  /// idempotente por usuario: si ya hay récord o una carga en vuelo, no
  /// vuelve a pedir.
  Future<void> load({bool force = false}) {
    final user = AuthService.to.currentUser;
    if (user == null || user.isTeacher) return Future<void>.value();
    // Otro usuario sin logout de por medio: su estado se descarta ANTES de
    // cualquier await.
    if (_ownerCode != user.code) clear();
    if (!force && _record.value != null) return Future<void>.value();
    if (!force && _inFlight != null) return _inFlight!;
    _ownerCode = user.code;
    final generation = ++_generation;
    return _inFlight = _fetch(generation);
  }

  Future<void> _fetch(int generation) async {
    _loading.value = true;
    _hasError.value = false;
    try {
      final json =
          await _api.getJson('/academic-record/me').timeout(loadTimeout);
      if (generation != _generation) return;
      _record.value = AcademicRecord.fromJson(json);
    } catch (e) {
      if (generation != _generation) return;
      // ApiException, fallo de red crudo (ApiClient no lo envuelve) o plazo
      // vencido. No se propaga: la tarjeta y la pantalla muestran su estado
      // de error y ofrecen reintentar.
      debugPrint('Error cargando el récord académico: $e');
      _hasError.value = true;
    } finally {
      if (generation == _generation) {
        _loading.value = false;
        _inFlight = null;
      }
    }
  }

  /// Vacía el estado y lo vuelve a pedir. Mientras llega, [record] es null:
  /// nadie ve el PPA ni los créditos anteriores (RF-REC-5).
  Future<void> reload() {
    clear();
    return load(force: true);
  }

  /// `DELETE /academic-record/me`. Si falla, lanza [AcademicRecordFailure]
  /// con [deleteErrorMessage] y el récord no cambia. Si sale bien, [record]
  /// pasa al instante a [AcademicRecord.empty] y se recarga para confirmarlo.
  Future<void> deleteRecord() async {
    final user = AuthService.to.currentUser;
    if (user == null || user.isTeacher) return;
    try {
      await _api.deleteJson('/academic-record/me').timeout(deleteTimeout);
    } catch (e) {
      // ApiException, fallo de red crudo o plazo vencido: para el alumno es
      // lo mismo.
      debugPrint('Error borrando el récord académico: $e');
      throw const AcademicRecordFailure(deleteErrorMessage);
    }
    // El backend ya no tiene copia: el estado vacío se muestra al instante y
    // la recarga lo confirma (RF-REC-5). Se descarta cualquier carga en
    // vuelo, que traería el récord recién borrado.
    _generation++;
    _inFlight = null;
    _ownerCode = user.code;
    _record.value = AcademicRecord.empty;
    _hasError.value = false;
    _loading.value = false;
    // load() nunca lanza: si esta recarga falla, record sigue siendo
    // AcademicRecord.empty (no null) y la pantalla se queda en el estado vacío.
    await load(force: true);
  }
}

/// Fallo del borrado, con un mensaje ya listo para mostrar.
class AcademicRecordFailure implements Exception {
  const AcademicRecordFailure(this.message);

  final String message;

  @override
  String toString() => 'AcademicRecordFailure: $message';
}
```

**3.2 Comprobar que el servicio pasa y que falta la invalidación tras importar**

```bash
cd . && $FLUTTER test test/HU34_jeff/academic_record_service_test.dart
```

Esperado: `+13 -1: Some tests failed.`
- Pasan los casos 1 a 12 y el caso 14. El caso 14 ya pasa hoy y sirve de guarda de regresión.
- Falla solo el caso 13, con `Expected: null`, `Actual: <Instance of 'AcademicRecord'>` y `nunca se ve el PPA anterior`, porque `refreshAfterImport` todavía no toca el récord.
- Si en vez de eso hay un error de compilación sobre `lib/models/academic_record_model.dart`, `AcademicRecord.fromJson` o `AcademicRecord.empty`, la tarea 1 no está hecha o quedó distinta: detente.
- Si falla algún caso del 1 al 12, corrige el servicio antes de seguir.

**3.3 Modificar `lib/services/portal_sync_service.dart`** con cuatro reemplazos exactos.

(a) Imports (líneas 1-4). Reemplazar esto:

```dart
import 'dart:async';

import '../models/portal_sync_models.dart';
import 'api_client.dart';
```

por esto:

```dart
import 'dart:async';

import 'package:get/get.dart';

import '../models/portal_sync_models.dart';
import 'academic_record_service.dart';
import 'api_client.dart';
```

(b) Doc comment, línea 110. Reemplazar esto:

```dart
  /// Son CINCO capas, no las tres que suponía el diseño original. Cada una
```

por esto:

```dart
  /// Son SEIS capas, no las tres que suponía el diseño original. Cada una
```

(c) Doc comment, líneas 122-123. Reemplazar esto:

```dart
  ///  5. Las alertas, porque la importación crea algunas.
  ///
```

por esto:

```dart
  ///  5. Las alertas, porque la importación crea algunas.
  ///  6. El récord académico (RF-REC-5): `AcademicRecordService` se vacía y se
  ///     vuelve a pedir, así la tarjeta del Perfil nunca muestra el PPA ni los
  ///     créditos anteriores. Una importación sin consentimiento no guarda
  ///     récord, y la recarga trae lo que haya.
  ///
```

(d) Cuerpo, líneas 137-142. El récord NO entra al `try` compartido: si ahí falla `Get.find`, se salta todo lo que sigue. Reemplazar esto:

```dart
    try {
      CoursesService().clear();
      EvaluationSyllabusService().clear();
      MallaService.to.clear();
    } catch (_) { /* servicios no registrados en algún test */ }
  }
```

por esto:

```dart
    try {
      CoursesService().clear();
      EvaluationSyllabusService().clear();
      MallaService.to.clear();
    } catch (_) { /* servicios no registrados en algún test */ }
    // RF-REC-5: la importación pudo guardar un récord nuevo (o ninguno, sin
    // consentimiento). Try propio: si falta un servicio del bloque de arriba,
    // esta invalidación no se salta.
    if (Get.isRegistered<AcademicRecordService>()) {
      try {
        await AcademicRecordService.to.reload();
      } catch (_) { /* load() no lanza; el import ya salió bien */ }
    }
  }
```

- [ ] **Paso 4: Correr la prueba y ver que pasa**

```bash
cd . && $FLUTTER test test/HU34_jeff/academic_record_service_test.dart
```

Esperado: PASS (`+14: All tests passed!`).

- [ ] **Paso 5: Registrar el servicio permanente en `lib/main.dart`**

Hace dos reemplazos. No agregues ningún fetch al arrancar: la tarjeta pide el récord al montarse.

(a) Import, línea 13. Reemplazar esto:

```dart
import '/services/malla_service.dart';
```

por esto:

```dart
import '/services/malla_service.dart';
import '/services/academic_record_service.dart';
```

(b) Registro, línea 65. Reemplazar esto:

```dart
  Get.put<MallaService>(MallaService(), permanent: true);
```

por esto:

```dart
  Get.put<MallaService>(MallaService(), permanent: true);
  // Estado único del récord (RF-REC-5), compartido por la tarjeta del Perfil y
  // /mi-record. No carga nada al arrancar: la tarjeta lo pide al montarse.
  Get.put<AcademicRecordService>(AcademicRecordService(), permanent: true);
```

Queda después de `Get.put<AuthService>(...)` (L63) y antes de `tryRestoreSession()` (L68), que es lo que necesita el `AuthService.to` del servicio. Estas dos ediciones corren `lib/main.dart` cuatro líneas: el `print` preexistente pasa de la L79 a la L83.

Comprueba que el registro quedó escrito:

```bash
cd . && grep -c "Get.put<AcademicRecordService>(AcademicRecordService(), permanent: true);" lib/main.dart
```

Esperado: `1`. Este grep es la ÚNICA verificación de RF-REC-5 ("un `GetxService` permanente, como `MallaService`") en todo el plan: ninguna prueba ejecuta `main()`, y las 30 y pico que tocan el servicio hacen su propio `Get.put<AcademicRecordService>(...)` antes de montar nada —incluida la que monta la app real con `const MyApp(initialRoute: '/mi-record')`, porque `MyApp` es solo el widget y el `Get.put(..., permanent: true)` vive en `main()`—. Sin esta línea la suite queda en verde y el Perfil se cae en runtime con "AcademicRecordService not found" desde `RecordProfileCard.initState`, y lo mismo el constructor por defecto de `AcademicRecordController` desde `AcademicRecordBinding`. Repite este mismo grep en el Paso final, antes del commit.

- [ ] **Paso 6: Documentar la API en `docs/specs/api-contracts.md`**

La sección nueva va al final del archivo (AGENTS.md, regla 6). Todos los valores de ejemplo son inventados y son los mismos de las pruebas. Reemplazar la última línea del archivo (L499):

```markdown
  - **La primera importación de un ciclo nuevo activa ese `academic_period` para TODOS los alumnos** (`is_active` es único global). Solo avanza el ciclo, nunca lo retrocede.
```

por esto:

````markdown
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
````

- [ ] **Paso 7: Enlazar el test en la spec**

En `specs/features/academic-record/academic-record.spec.md`, al final de RF-REC-5 (líneas 134-137), reemplazar esto:

```markdown
`[@test] ../../../test/HU34_jeff/record_page_test.dart`
`[@test] ../../../test/HU34_jeff/record_card_test.dart`

### RF-REC-6 — Consentimiento antes de dar las credenciales
```

por esto:

```markdown
`[@test] ../../../test/HU34_jeff/record_page_test.dart`
`[@test] ../../../test/HU34_jeff/record_card_test.dart`
`[@test] ../../../test/HU34_jeff/academic_record_service_test.dart`

### RF-REC-6 — Consentimiento antes de dar las credenciales
```

(El par de líneas `record_page_test.dart` + `record_card_test.dart` aparece una sola vez en el archivo, en las L134-135; las L63 y L85 tienen otras combinaciones.)

- [ ] **Paso 8: Regresión y análisis**

```bash
cd . && $FLUTTER test test/HU34_jeff/academic_record_service_test.dart test/HU34_jeff/academic_record_model_test.dart test/HU31_jeff/portal_sync_test.dart
```

Esperado: PASS (`All tests passed!`). `portal_sync_test.dart` no llama a `refreshAfterImport`, pero sí importa `portal_sync_service.dart`: confirma que el archivo compila con sus imports nuevos.

```bash
cd . && $FLUTTER analyze
```

Esperado: ningún issue nuevo respecto de la línea base medida en la tarea 1, que está en `$TMP/plan-fe/analyze-baseline.txt` (léela con `cat` y compara la línea `N issues found` sin el `(ran in …)`). Los preexistentes se reportan aparte y no se corrigen aquí; el `avoid_print` de `lib/main.dart:79` pasa a reportarse en `lib/main.dart:83` por las cuatro líneas que agrega el paso 5. En los cuatro archivos Dart de esta tarea (`academic_record_service.dart`, `portal_sync_service.dart`, `main.dart` y el test) no puede aparecer ningún `unused_import`, `empty_catches` ni `avoid_print`.

- [ ] **Paso final: Commit**

Revisa primero que el registro permanente siga en su sitio y que el árbol no tenga cambios ajenos:

```bash
cd . && grep -c "Get.put<AcademicRecordService>(AcademicRecordService(), permanent: true);" lib/main.dart && git status --short --untracked-files=all
```

Esperado: `1` y después, en cualquier orden, exactamente estas seis líneas:

```
 M docs/specs/api-contracts.md
 M lib/main.dart
 M lib/services/portal_sync_service.dart
 M specs/features/academic-record/academic-record.spec.md
?? lib/services/academic_record_service.dart
?? test/HU34_jeff/academic_record_service_test.dart
```

Si aparece otro archivo, no lo agregues ni lo toques: puede ser de otra sesión.

```bash
cd . && git add lib/services/academic_record_service.dart lib/services/portal_sync_service.dart lib/main.dart docs/specs/api-contracts.md specs/features/academic-record/academic-record.spec.md test/HU34_jeff/academic_record_service_test.dart && git diff --cached --stat
```

Esperado: exactamente esos 6 archivos y `6 files changed`.

```bash
cd . && git commit -m "feat(academic-record): servicio único del récord con borrado e invalidación tras importar"
```

El autor ya está configurado en git. El mensaje va sin trailer `Co-Authored-By`. No hagas push.

### Tarea 3: Funciones puras de formato: progreso de créditos, decimales y ubicación

**Archivos:**
- Crear: `lib/pages/academic_record/record_format.dart` (la carpeta `lib/pages/academic_record/` todavía no existe en el repo; este es el primer archivo que la crea)
- Test: `test/HU34_jeff/record_card_test.dart` (crear; la carpeta `test/HU34_jeff/` tampoco existe todavía en el repo: la crea la tarea 1 con `academic_record_model_test.dart`, y si por lo que sea corres esta tarea antes, créala al escribir el archivo. La tarea 4 le agrega imports, dobles y grupos nuevos al final de `main()`, así que este archivo se escribe pensando en que va a crecer: aquí no se define ningún doble)
- No se modifica ningún archivo existente. La spec ya enlaza este test en RF-REC-1 (`specs/features/academic-record/academic-record.spec.md:63`) y en RF-REC-5 (`:135`), así que esta tarea no toca la spec. (Las tareas 1 y 2 insertan `[@test]` después de las líneas 173 y 135 respectivamente, así que esas dos anclas siguen en 63 y 135 cuando llegue esta tarea.)

**Interfaces:**
- Consume: **nada** de las tareas 1 y 2. Son funciones sobre `double?` y `String?`, sin imports de Flutter, de GetX ni de los modelos. Del repo solo se copian precedentes:
  - `lib/models/portal_sync_models.dart:1-6`: doc comment de librería seguido de `library;` en la línea 6, la forma que usa el repo para documentar un archivo sin clase principal.
  - `lib/pages/malla/malla_list_controller.dart:389`: `int get approvedPercent => (approvedRatio * 100).round();` — el porcentaje que se muestra se redondea al entero. Es el precedente de `progressPercentLabel`.
  - `lib/pages/descripcion_cursos/descrip_cursos.dart:548`: `final verde = fraccionAsistida.clamp(0.0, 1.0) * 2 * math.pi;` — el anillo que ya existe recorta la fracción a [0, 1].
  - `lib/pages/horario/horario.dart:81` (`(duration - blockHairline).clamp(8.0, double.infinity).toDouble()`) y `lib/pages/malla/malla_page.dart:605` (`_matrixScale().clamp(0.5, 1.6).toDouble()`): la forma que usa el repo para que el tipo estático quede en `double`, porque `num.clamp` devuelve `num`.
  - Queda **prohibido** `_asInt` (`lib/models/official_grades_models.dart:5`) y cualquier `?? 0`: si falta un dato, estas funciones devuelven `null` y la UI omite el bloque; nunca se pinta un 0 inventado (RF-REC-1, "Datos que faltan", `spec:53-57`, que cita el precedente RS-BE-10).
- Produce: `lib/pages/academic_record/record_format.dart`, funciones de nivel superior sin imports de Flutter:
  - `double? creditsProgress(double? accumulated, double? requiredCredits)` — `null` si falta alguno o si `requiredCredits <= 0`; si no, `clamp(accumulated / requiredCredits, 0, 1)`.
  - `String formatDecimal(double value)` — `3.0` → `'3'`; `1.5` → `'1.5'`; `14.62` → `'14.62'`.
  - `String? creditsOfRequiredLabel(double? accumulated, double? requiredCredits)` — `'164 de 200 créditos'`, o `null` con las mismas guardas que `creditsProgress`.
  - `String creditsShortLabel(double credits)` — `'1.5 créd.'` | `'3 créd.'`.
  - `String? formatRelativePosition(String? raw)` — `'TERCIO SUPERIOR'` → `'Tercio superior'`; `null` o en blanco → `null`.
  - `String progressPercentLabel(double progress)` — `0.8195` → `'82%'`.

Quién las usa después, tal como lo fija el esqueleto: la tarea 4 (`creditsProgress`, `formatDecimal`, `creditsOfRequiredLabel` y `formatRelativePosition`, en la tarjeta del Perfil), la tarea 5 (`creditsShortLabel`, en el subtítulo del curso), la tarea 6 (`creditsProgress`, `formatDecimal`, `formatRelativePosition` y `progressPercentLabel`, en el encabezado y el anillo — **no** usa `creditsOfRequiredLabel`, que es solo de la tarjeta) y la tarea 7 (`formatDecimal`, en el promedio del ciclo). El parámetro se llama `requiredCredits` y no `required` porque `required` es palabra reservada contextual de Dart.

**Ojo con los nombres:** hoy no existe en `lib/` ni en `test/` ninguna función con estos seis nombres (`grep -rn "formatDecimal\|creditsProgress\|creditsShortLabel\|formatRelativePosition\|progressPercentLabel\|creditsOfRequiredLabel" lib/ test/` no devuelve nada), así que se importan sin prefijo y no chocan con nada. Tampoco hay ya un helper de decimales que reutilizar: todo el repo formatea con `toStringAsFixed`, que redondea y por eso aquí no sirve.

- [ ] **Paso 1: Escribir la prueba que falla**

Crear `test/HU34_jeff/record_card_test.dart` con este contenido completo:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/pages/academic_record/record_format.dart';

/// Récord académico: formato puro de la tarjeta del Perfil (RF-REC-1) y del
/// encabezado de la pantalla (RF-REC-2).
///
/// La barra de la tarjeta y el anillo de la pantalla usan la misma
/// `creditsProgress`, así que sus guardas se prueban una sola vez aquí: si
/// falta un dato o los requeridos son 0 o menos, no se dibuja nada; y un 0
/// acumulado es un dato real, no un dato que falta. Todos los valores son
/// inventados.
void main() {
  group('UNITARIA · creditsProgress (RF-REC-1)', () {
    test('164 de 200 da la proporción exacta, sin redondear', () {
      expect(creditsProgress(164, 200), closeTo(164 / 200, 1e-12));
    });

    test('sin un dato o con requeridos en 0 o menos da null: no hay barra ni anillo', () {
      expect(creditsProgress(null, 200), isNull);
      expect(creditsProgress(164, null), isNull);
      expect(creditsProgress(null, null), isNull);
      expect(creditsProgress(164, 0), isNull);
      expect(creditsProgress(164, -5), isNull);
    });

    test('0 créditos acumulados es un dato real: da 0.0, no null', () {
      expect(creditsProgress(0, 200), 0.0);
    });

    test('acumulados mayores que requeridos se recortan a 1.0', () {
      expect(creditsProgress(230, 200), 1.0);
    });

    test('los decimales entran tal cual: 1.5 de 3 es 0.5', () {
      expect(creditsProgress(1.5, 3), 0.5);
    });

    test('un acumulado negativo se recorta a 0.0', () {
      expect(creditsProgress(-3, 200), 0.0);
    });
  });

  group('UNITARIA · formatDecimal y créditos', () {
    test('un valor entero se muestra sin ".0"', () {
      expect(formatDecimal(3.0), '3');
      expect(formatDecimal(164.0), '164');
      expect(formatDecimal(0.0), '0');
    });

    test('un decimal se muestra tal cual, sin redondear', () {
      expect(formatDecimal(1.5), '1.5');
      expect(formatDecimal(14.62), '14.62');
    });

    test('creditsShortLabel: "1.5 créd." y "3 créd."', () {
      expect(creditsShortLabel(1.5), '1.5 créd.');
      expect(creditsShortLabel(3.0), '3 créd.');
    });

    test('creditsOfRequiredLabel arma "N de M créditos" con los valores sin recortar', () {
      expect(creditsOfRequiredLabel(164, 200), '164 de 200 créditos');
      expect(creditsOfRequiredLabel(164.5, 200), '164.5 de 200 créditos');
      expect(creditsOfRequiredLabel(230, 200), '230 de 200 créditos');
    });

    test('creditsOfRequiredLabel tiene las mismas guardas que la barra', () {
      expect(creditsOfRequiredLabel(null, 200), isNull);
      expect(creditsOfRequiredLabel(168, null), isNull);
      expect(creditsOfRequiredLabel(168, 0), isNull);
      expect(creditsOfRequiredLabel(168, -5), isNull);
    });
  });

  group('UNITARIA · formatRelativePosition', () {
    test('las mayúsculas del portal pasan a tipo oración', () {
      expect(formatRelativePosition('TERCIO SUPERIOR'), 'Tercio superior');
    });

    test('los espacios de más se recortan', () {
      expect(formatRelativePosition('medio  superior'), 'Medio superior');
      expect(formatRelativePosition('  TERCIO SUPERIOR  '), 'Tercio superior');
    });

    test('sin dato o en blanco da null: no hay insignia', () {
      expect(formatRelativePosition(null), isNull);
      expect(formatRelativePosition(''), isNull);
      expect(formatRelativePosition('   '), isNull);
    });
  });

  group('UNITARIA · progressPercentLabel', () {
    test('el porcentaje del anillo se redondea al entero', () {
      expect(progressPercentLabel(0.8195), '82%');
      expect(progressPercentLabel(1.0), '100%');
      expect(progressPercentLabel(0.0), '0%');
    });

    test('el anillo sale de creditsProgress: 164 de 200 muestra 82%', () {
      expect(progressPercentLabel(creditsProgress(164, 200)!), '82%');
    });
  });
}
```

Por qué estos casos y no otros:
- `164`, `200` y `'164 de 200 créditos'` son el ejemplo que publica la spec en RF-REC-1 (`spec:43`), y acá se prueba justo ese ejemplo. Son inventados, como todo dato de este plan: se comprobaron con `grep` contra `test/HU31_jeff/fixtures/` y `spike-portal/` y no aparecen ahí.
- Los literales enteros (`164`, `200`, `0`, `-5`) se aceptan donde el parámetro es `double?`: Dart convierte un literal entero cuando el tipo de contexto es `double`, también cuando ese tipo es nulable.
- `(0, 200)` y `(-3, 200)` separan "dato que falta" de "dato que vale 0 o menos": el primero da `null`, los otros dos dan `0.0`. Es la diferencia que RF-REC-1 exige para no pintar ceros inventados.
- `14.62` y `164.5` prueban que no se redondea nada; `3.0`, `164.0` y `0.0`, que el entero va sin `.0`.
- `0.8195` cae en `81.95`, así que solo pasa si el porcentaje se redondea (`.round()`) y no se trunca.
- Son 16 casos en cuatro grupos, y cubren los cuatro requisitos del esqueleto para esta tarea: el `clamp` con `null`/0/acumulados mayores que requeridos (grupo 1), la ausencia de barra y de "N de M créditos" cuando falta un dato o los requeridos son ≤ 0 (grupo 1 más el último caso del grupo 2), los decimales "1.5 créd." y "3 créd." sin `.0` ni redondeo (grupo 2), y el anillo de RF-REC-2 apoyado en la misma función y las mismas guardas (último caso del grupo 4, que encadena `creditsProgress` con `progressPercentLabel`).

- [ ] **Paso 2: Correr la prueba y ver que falla**

```bash
cd . && $FLUTTER test test/HU34_jeff/record_card_test.dart
```

Esperado: falla al compilar, porque el archivo que se importa todavía no existe. Las primeras líneas:

```
test/HU34_jeff/record_card_test.dart:2:8: Error: Error when reading 'lib/pages/academic_record/record_format.dart': No such file or directory
import 'package:ulima_plus/pages/academic_record/record_format.dart';
       ^
test/HU34_jeff/record_card_test.dart:15:14: Error: Method not found: 'creditsProgress'.
      expect(creditsProgress(164, 200), closeTo(164 / 200, 1e-12));
             ^^^^^^^^^^^^^^^
```

y al final:

```
00:00 +0 -1: Some tests failed.

Failing tests:
  ./test/HU34_jeff/record_card_test.dart: loading ./test/HU34_jeff/record_card_test.dart
```

Es el fallo correcto: `Method not found` para las seis funciones (`creditsProgress`, `formatDecimal`, `creditsShortLabel`, `creditsOfRequiredLabel`, `formatRelativePosition`, `progressPercentLabel`), repetido en cada llamada, así que entre las dos líneas de arriba y el resumen final hay unas dos docenas de bloques `Error: Method not found`. Ningún cuerpo de test llega a correr todavía. Si en vez de esto sale `All tests passed!`, el archivo de implementación ya existía: revísalo antes de seguir.

- [ ] **Paso 3: Implementación mínima**

Crear `lib/pages/academic_record/record_format.dart` con este contenido completo (crea también la carpeta `lib/pages/academic_record/`):

```dart
/// Formato puro del récord académico: lo que comparten la tarjeta del Perfil
/// (RF-REC-1) y el encabezado de la pantalla (RF-REC-2).
///
/// Sin imports de Flutter a propósito: son funciones sobre `double?` y
/// `String?`, probadas sin montar widgets. Conservan el `null`: un dato que no
/// vino se omite en la UI, nunca se pinta como 0 (precedente RS-BE-10).
library;

/// Proporción de créditos acumulados sobre los requeridos, entre 0 y 1.
///
/// Devuelve `null` —y entonces no se dibujan ni la barra ni el anillo— si
/// falta cualquiera de los dos datos o si los requeridos son 0 o menos.
double? creditsProgress(double? accumulated, double? requiredCredits) {
  if (accumulated == null || requiredCredits == null) return null;
  if (requiredCredits <= 0) return null;
  return (accumulated / requiredCredits).clamp(0.0, 1.0).toDouble();
}

/// Número tal como se muestra: sin redondear y sin el `.0` de los enteros.
String formatDecimal(double value) {
  if (!value.isFinite) return value.toString();
  return value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toString();
}

/// "164 de 200 créditos", con las mismas guardas que [creditsProgress].
String? creditsOfRequiredLabel(double? accumulated, double? requiredCredits) {
  if (creditsProgress(accumulated, requiredCredits) == null) return null;
  return '${formatDecimal(accumulated!)} de '
      '${formatDecimal(requiredCredits!)} créditos';
}

/// "1.5 créd." | "3 créd.".
String creditsShortLabel(double credits) => '${formatDecimal(credits)} créd.';

/// "TERCIO SUPERIOR" del portal en tipo oración: "Tercio superior".
///
/// `null` si no hay dato o si viene en blanco: entonces no hay insignia.
String? formatRelativePosition(String? raw) {
  final texto = (raw ?? '')
      .trim()
      .split(' ')
      .where((parte) => parte.isNotEmpty)
      .join(' ');
  if (texto.isEmpty) return null;
  final minusculas = texto.toLowerCase();
  return minusculas[0].toUpperCase() + minusculas.substring(1);
}

/// Porcentaje del anillo, redondeado al entero: "82%".
String progressPercentLabel(double progress) =>
    '${(progress.clamp(0.0, 1.0) * 100).round()}%';
```

Detalles que no son libres:
- `formatDecimal` usa `double.toString()`, que da la representación decimal más corta que vuelve a leerse como el mismo `double`: `14.62` queda `'14.62'`, sin redondear. Nada de `toStringAsFixed`, que sí redondearía; es lo que usa el resto del repo y por eso aquí hace falta una función propia.
- La guarda `!value.isFinite` está porque `double.infinity.truncateToDouble()` es igual a sí mismo y `infinity.toInt()` lanza `UnsupportedError`.
- El `.toDouble()` de `creditsProgress` no es adorno: `clamp` está declarado en `num` y devuelve `num`, así que sin él el tipo estático no sería `double` y la función no compilaría contra su propia firma. Es el mismo remate de `horario.dart:81` y `malla_page.dart:605`.
- `creditsOfRequiredLabel` delega la decisión en `creditsProgress`, así que la barra y el texto nunca pueden discrepar; los `!` son seguros justo después de esa guarda. El texto usa los valores **sin recortar** (`'230 de 200 créditos'`), aunque la barra sí se recorte a 1.0: el número que ve el alumno es el suyo.
- `progressPercentLabel` es el único lugar donde algo se redondea, y es presentación del anillo. PPA y créditos no se redondean nunca.
- El doc comment de archivo va seguido de `library;` (línea 6, igual que `lib/models/portal_sync_models.dart:6`). Sin esa línea, `flutter_lints` 6 marca `dangling_library_doc_comments` y el Paso 5 deja de dar `No issues found!`.

- [ ] **Paso 4: Correr la prueba y ver que pasa**

```bash
cd . && $FLUTTER test test/HU34_jeff/record_card_test.dart
```

Esperado: PASS, con los 16 casos de los cuatro grupos:

```
00:00 +16: All tests passed!
```

- [ ] **Paso 5: Análisis estático**

```bash
cd . && $FLUTTER analyze lib/pages/academic_record/record_format.dart test/HU34_jeff/record_card_test.dart
```

Esperado: `No issues found! (ran in …)`. Si sale algún issue, corrígelo en esos dos archivos y vuelve a correr los Pasos 4 y 5.

Después, el proyecto entero, para comprobar que el número de issues preexistentes que anotaste en la tarea 1 no subió:

```bash
cd . && $FLUTTER analyze 2>&1 | grep -E "issues? found|record_format|record_card"
```

Esperado: la misma línea `N issues found. (ran in …)` (o `No issues found!`) de la tarea 1, y ninguna línea que nombre `record_format` o `record_card`. Si esta tarea corre en otra sesión no tienes el reporte de la tarea 1: la línea base está en `$TMP/plan-fe/analyze-baseline.txt`; léela con `cat` y compara sin el `(ran in …)`. Si el número subió, el issue nuevo es de esta tarea: corrígelo.

- [ ] **Paso final: Commit**

Revisa primero que el árbol no tenga cambios ajenos:

```bash
cd . && git status --short --untracked-files=all
```

Esperado, en cualquier orden, exactamente estas dos líneas:

```
?? lib/pages/academic_record/record_format.dart
?? test/HU34_jeff/record_card_test.dart
```

Si aparece otro archivo, no lo agregues ni lo toques: puede ser de otra sesión.

```bash
cd . && git add lib/pages/academic_record/record_format.dart test/HU34_jeff/record_card_test.dart && git diff --cached --stat
```

Esperado: exactamente esos 2 archivos y `2 files changed`.

```bash
cd . && git commit -m "feat(academic-record): formato puro de créditos, decimales y ubicación"
```

El autor ya está configurado en git. El mensaje no lleva trailer `Co-Authored-By`. No hagas push.

### Tarea 4: Tarjeta del récord en el Perfil

**Archivos:**
- Crear: `lib/pages/academic_record/record_position_badge.dart`
- Crear: `lib/pages/academic_record/record_profile_card.dart`
- Modificar: `lib/pages/perfil/perfil.dart:6-7` (un import más) y `lib/pages/perfil/perfil.dart:43-44` (la tarjeta como primer hijo del bloque `if (!user.isTeacher) ...[`). Nada más del archivo, que hoy tiene 1364 líneas.
- Test: `test/HU34_jeff/record_card_test.dart` (ya existe desde la tarea 3: se le agregan imports arriba, un grupo nuevo al final de `main()` y los dobles después de `main()`. Los cuatro grupos `UNITARIA ·` de la tarea 3 no se tocan)
- No se toca la spec: `specs/features/academic-record/academic-record.spec.md:63` (RF-REC-1) y `:135` (RF-REC-5) ya enlazan este archivo de test. Comprobado: las dos líneas dicen literalmente `` `[@test] ../../../test/HU34_jeff/record_card_test.dart` ``, y los `[@test]` que insertan las tareas 1 y 2 van después de la L135, así que ninguna de las dos se corre.

**Precondición:** las tareas 1, 2 y 3 ya tienen su commit. Comprobarlo antes de empezar:

```bash
cd . && ls lib/models/academic_record_model.dart lib/services/academic_record_service.dart lib/pages/academic_record/record_format.dart test/HU34_jeff/record_card_test.dart && git status --short
```

Los cuatro archivos deben existir y el árbol debe estar limpio. Todo se hace en `.`, rama `feat/record-academico-fe`, editando con Edit sobre las anclas literales de abajo. Nada de `cp`, `mv` ni `git stash`.

**Interfaces:**
- Consume (tarea 1, `lib/models/academic_record_model.dart`):
  - `class AcademicRecord { const AcademicRecord({required this.syncedAt, required this.snapshot, required this.periodSummaries, required this.coursesByPeriod}); final DateTime? syncedAt; final AcademicSnapshot? snapshot; final List<AcademicPeriodSummary> periodSummaries; final List<RecordPeriod> coursesByPeriod; bool get hasRecord => syncedAt != null; static const AcademicRecord empty; }`
  - `class AcademicSnapshot { final double? ppa; final String? relativePosition; final double? creditsAccumulated; final double? creditsRequired; final AcademicTotals approved; final AcademicTotals convalidated; }`
  - De estos dos, la tarjeta solo nombra el tipo `AcademicSnapshot` (parámetro de `_conRecord`) y lee `hasRecord`, `snapshot`, `ppa`, `relativePosition`, `creditsAccumulated` y `creditsRequired`. Los cuatro campos numéricos son `double?`, que es justo lo que piden las funciones de la tarea 3.
- Consume (tarea 2, `lib/services/academic_record_service.dart`):
  - ```dart
    class AcademicRecordService extends GetxService {
      AcademicRecordService({ApiClient? apiClient});
      static AcademicRecordService get to => Get.find();
      static const Duration loadTimeout = Duration(seconds: 15);
      static const Duration deleteTimeout = Duration(seconds: 15);
      static const String deleteErrorMessage = 'No se pudo borrar tu récord. Inténtalo de nuevo.';
      AcademicRecord? get record;
      bool get isLoading;
      bool get hasError;
      Future<void> load({bool force = false});
      Future<void> reload();
      void clear();
      Future<void> deleteRecord();
    }
    ```
    La tarjeta usa solo `to`, `record`, `hasError` y `load()`; el test usa además el constructor con `apiClient`, `reload()` y `deleteRecord()`. `isLoading` no se usa aquí: el estado de carga de la tarjeta es "no hay récord y no hay error".
  - `record` devuelve `null` mientras no haya una copia cargada **para el usuario actual**, y lee el `Rx` antes de comparar el dueño, así que el `Obx` de la tarjeta se suscribe igual. `load()` nunca lanza y ya trae dentro la guarda de docente y la caché por usuario: la tarjeta no repite ninguna de las dos. `reload()` hace `clear()` (deja `record` en null) y luego `load(force: true)`; `deleteRecord()` deja `record` en `AcademicRecord.empty` al instante y después recarga.
- Consume (tarea 3, `lib/pages/academic_record/record_format.dart`):
  - `double? creditsProgress(double? accumulated, double? requiredCredits)`
  - `String formatDecimal(double value)`
  - `String? creditsOfRequiredLabel(double? accumulated, double? requiredCredits)`
  - `String? formatRelativePosition(String? raw)`
- Consume (repo, sin modificarlos):
  - `lib/components/skeleton.dart:19`: `class SkeletonPulse extends StatefulWidget { const SkeletonPulse({super.key, required this.child}); final Widget child; }`; `:52`: `class SkeletonBox extends StatelessWidget { const SkeletonBox({super.key, this.width, this.height = 14, this.borderRadius = 8}); }`.
  - `lib/configs/themes.dart`: `MaterialTheme.cardBg(Brightness)` (`:59`), `textPrimary` (`:63`), `textSecondary` (`:67`), `borderColor` (`:79`), `progressBg` (`:91`), `espPrincipalBg` (`:99`), `labelColor` (`:135`), y las constantes `static const Color primaryColor` (`:10`) y `static const Color primaryDark` (`:12`) — por eso los `TextStyle` y el `Icon` que solo las usan a ellas pueden ser `const`.
  - `lib/components/networking/networking_profile_entry_card.dart` (83 líneas): es la plantilla exacta de tarjeta tocable del Perfil — `Semantics(button: true, label: …)` → `Material(color: Colors.transparent)` → `InkWell(onTap: …, borderRadius: BorderRadius.circular(14))` → `Ink(padding: EdgeInsets.all(14), decoration: BoxDecoration(color: cardBg, borderRadius: 14, border: Border.all(color: borderColor)))`.
  - `lib/pages/malla/malla_page.dart:137-144`: la barra `ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: …, minHeight: 6, backgroundColor: MaterialTheme.progressBg(brightness), color: MaterialTheme.primaryColor))`.
  - `lib/pages/perfil/perfil.dart:653`: la forma de navegar del Perfil, `Get.toNamed<dynamic>('/portal-sync')`.
  - `lib/services/api_client.dart:42-43`, `:68-73` y `:99-102`: `ApiClient({String? configuredBaseUrl})`, `Future<Map<String, dynamic>> getJson(String path, {String? token, Map<String, String?> query = const {}, bool suppressSessionExpiry = false})` y `Future<Map<String, dynamic>> deleteJson(String path, {String? token})` — las firmas que copian los dobles del test.
  - `lib/services/auth_service.dart:18`, `:59-60` y `:179`: `static AuthService get to`, `UserModel? get currentUser`, `Rx<UserModel?> get currentUserRx` y `Future<void> refreshCurrentUser()`.
  - `lib/models/user_model.dart:29-45`: `UserModel({required String code, required String firstName, required String lastName, …, required String email, required String role, …, required String currentCycle, required bool setupComplete, …})` (constructor **no** `const`); `:106`: `bool get isTeacher => role == 'teacher' || role == 'docente';`.
- Produce:
  - `lib/pages/academic_record/record_position_badge.dart`:
    `class RecordPositionBadge extends StatelessWidget { const RecordPositionBadge({super.key, required this.label}); final String label; }`
    Recibe el texto **ya formateado** con `formatRelativePosition`; si esa función dio `null`, quien llama no monta la insignia. La tarea 6 la reutiliza en el encabezado de la pantalla.
  - `lib/pages/academic_record/record_profile_card.dart`:
    ```dart
    class RecordProfileCard extends StatefulWidget {
      const RecordProfileCard({super.key});
      static const Key skeletonKey = Key('record-card-skeleton');
      static const String ppaLabel = 'PPA';
      static const String neverSyncedText = 'Sincroniza con el portal para ver tu récord';
      static const String linkText = 'Ver mi récord completo ›';
      static const String errorTitle = 'Mi récord académico';
    }
    ```
    Toda la tarjeta es tocable y hace `Get.toNamed<dynamic>('/mi-record')`, en los cuatro estados.
  - `lib/pages/perfil/perfil.dart`: `const RecordProfileCard()` es el primer hijo del spread `if (!user.isTeacher) ...[`, seguido de `const SizedBox(height: 16)` y del `const _CarreraCard()` que ya estaba.

**Ojo con los nombres:** `RecordProfileCard` y `RecordPositionBadge` no existen todavía en el repo (`grep -rn "RecordProfileCard\|RecordPositionBadge" lib/ test/` no devuelve nada). El texto `'Mi récord académico'` sí aparecerá también como `label` del `Semantics`, pero `find.text` solo mira widgets `Text`, así que el test del estado de error no se confunde. La ruta `'/mi-record'` todavía **no** está registrada en `lib/main.dart` (`grep -rn "mi-record" lib/` no devuelve nada; la registra la tarea 6): por eso el test monta su propio `GetMaterialApp` con esa ruta.

**Sobre los lints:** el repo usa `flutter_lints: ^6.0.0` (`include: package:flutter_lints/flutter.yaml`, que a su vez incluye `package:lints/recommended.yaml`) sin reglas extra en `analysis_options.yaml`. Ese conjunto **no** trae `prefer_const_constructors`, pero sí `sort_child_properties_last`, `use_key_in_widget_constructors`, `prefer_const_constructors_in_immutables`, `unnecessary_const`, `annotate_overrides` y `avoid_renaming_method_parameters`: por eso `child`/`children` van siempre al final, los dos widgets llevan `super.key` y constructor `const`, y los `@override` de los dobles repiten los nombres de parámetro del padre tal cual.

- [ ] **Paso 1: Escribir la prueba que falla**

Son tres inserciones sobre `test/HU34_jeff/record_card_test.dart`. Ninguna toca los cuatro grupos `UNITARIA ·` de la tarea 3.

**1.1 · Imports.** Reemplazar las dos primeras líneas del archivo:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/pages/academic_record/record_format.dart';
```

por:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/academic_record/record_format.dart';
import 'package:ulima_plus/pages/academic_record/record_position_badge.dart';
import 'package:ulima_plus/pages/academic_record/record_profile_card.dart';
import 'package:ulima_plus/pages/perfil/perfil.dart';
import 'package:ulima_plus/services/academic_record_service.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/auth_service.dart';
```

Los doce imports se usan: `dart:async` por `Completer` y `unawaited`; `material.dart` por `Widget`, `Scaffold`, `Padding`, `EdgeInsets` y `LinearProgressIndicator`; `get.dart` por `Get`, `Rx`, `GetMaterialApp` y `GetPage`; `perfil.dart` por `ProfilePage`. Ninguno queda como `unused_import`.

**1.2 · Doc comment y binding al inicio de `main()`.** Reemplazar el final del doc comment y las dos líneas que le siguen:

```dart
/// acumulado es un dato real, no un dato que falta. Todos los valores son
/// inventados.
void main() {
  group('UNITARIA · creditsProgress (RF-REC-1)', () {
```

por:

```dart
/// acumulado es un dato real, no un dato que falta. Todos los valores son
/// inventados.
///
/// El grupo WIDGET monta además la tarjeta del Perfil (RF-REC-1) y comprueba
/// que tras borrar o recargar nunca se ve el récord anterior (RF-REC-5).
void main() {
  // Get.put de un GetxService agenda onReady con
  // Get.engine.addPostFrameCallback, que necesita el binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UNITARIA · creditsProgress (RF-REC-1)', () {
```

**1.3 · Grupo de widget al final de `main()`, y los dobles después.** Reemplazar el final del archivo, que hoy es:

```dart
    test('el anillo sale de creditsProgress: 164 de 200 muestra 82%', () {
      expect(progressPercentLabel(creditsProgress(164, 200)!), '82%');
    });
  });
}
```

por:

```dart
    test('el anillo sale de creditsProgress: 164 de 200 muestra 82%', () {
      expect(progressPercentLabel(creditsProgress(164, 200)!), '82%');
    });
  });

  group('WIDGET · RecordProfileCard (RF-REC-1, RF-REC-5)', () {
    setUp(() {
      Get.testMode = true;
      Get.reset();
    });

    tearDown(Get.reset);

    testWidgets('con récord muestra PPA, insignia, créditos y el enlace', (
      tester,
    ) async {
      await _montarTarjeta(tester, [_syncedJson()]);

      expect(find.text(RecordProfileCard.ppaLabel), findsOneWidget);
      expect(find.text('14.62'), findsOneWidget);
      expect(find.byType(RecordPositionBadge), findsOneWidget);
      expect(find.text('Tercio superior'), findsOneWidget);
      expect(find.text('164 de 200 créditos'), findsOneWidget);
      expect(find.text(RecordProfileCard.linkText), findsOneWidget);

      final barra = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(barra.value, closeTo(164 / 200, 1e-9));
    });

    testWidgets('sin PPA no se pinta ni la etiqueta ni un 0', (tester) async {
      await _montarTarjeta(tester, [_syncedJson(ppa: null)]);

      expect(find.text(RecordProfileCard.ppaLabel), findsNothing);
      expect(find.text('0'), findsNothing);
      // La insignia y los créditos sí siguen: solo se omite el dato que falta.
      expect(find.text('Tercio superior'), findsOneWidget);
      expect(find.text('164 de 200 créditos'), findsOneWidget);
    });

    testWidgets('sin créditos requeridos no hay barra ni texto de créditos', (
      tester,
    ) async {
      await _montarTarjeta(tester, [_syncedJson(creditsRequired: null)]);

      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.textContaining('créditos'), findsNothing);
      expect(find.text('14.62'), findsOneWidget);
    });

    testWidgets('con créditos requeridos en 0 tampoco hay barra ni texto', (
      tester,
    ) async {
      await _montarTarjeta(tester, [_syncedJson(creditsRequired: 0)]);

      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.textContaining('créditos'), findsNothing);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('con más acumulados que requeridos la barra va al tope y el '
        'texto muestra el número real', (tester) async {
      await _montarTarjeta(tester, [_syncedJson(creditsAccumulated: 230)]);

      expect(find.text('230 de 200 créditos'), findsOneWidget);
      final barra = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(barra.value, 1.0);
    });

    testWidgets('si nunca sincronizó muestra el aviso y ninguna cifra', (
      tester,
    ) async {
      await _montarTarjeta(tester, [_neverSyncedJson()]);

      expect(find.text(RecordProfileCard.neverSyncedText), findsOneWidget);
      expect(find.text(RecordProfileCard.ppaLabel), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byType(RecordPositionBadge), findsNothing);
    });

    testWidgets('tocar la tarjeta con récord lleva a /mi-record', (
      tester,
    ) async {
      await _montarTarjeta(tester, [_syncedJson()]);

      await tester.tap(find.byType(RecordProfileCard));
      await tester.pumpAndSettle();

      expect(Get.currentRoute, '/mi-record');
      expect(find.text('RECORD'), findsOneWidget);
    });

    testWidgets('tocar la tarjeta sin sincronizar también lleva a /mi-record', (
      tester,
    ) async {
      await _montarTarjeta(tester, [_neverSyncedJson()]);

      await tester.tap(find.byType(RecordProfileCard));
      await tester.pumpAndSettle();

      expect(Get.currentRoute, '/mi-record');
      expect(find.text('RECORD'), findsOneWidget);
    });

    testWidgets('mientras carga se ve el skeleton y ningún 0', (tester) async {
      final pendiente = Completer<Map<String, dynamic>>();
      await _montarTarjeta(tester, [pendiente]);

      // SkeletonPulse anima sin fin: aquí se usa pump(), nunca pumpAndSettle.
      expect(find.byKey(RecordProfileCard.skeletonKey), findsOneWidget);
      expect(find.text('0'), findsNothing);
      expect(find.text(RecordProfileCard.ppaLabel), findsNothing);

      // Se completa antes de terminar para que el Timer de loadTimeout se
      // cancele: uno pendiente hace fallar al test con "A Timer is still
      // pending even after the widget tree was disposed".
      pendiente.complete(_syncedJson());
      await tester.pump();
      await tester.pump();
      expect(find.byKey(RecordProfileCard.skeletonKey), findsNothing);
      expect(find.text('14.62'), findsOneWidget);
    });

    testWidgets('si la carga falla se ve el título del récord y el enlace, '
        'sin cifras', (tester) async {
      await _montarTarjeta(tester, [Exception('socket')]);

      expect(find.text(RecordProfileCard.errorTitle), findsOneWidget);
      expect(find.text(RecordProfileCard.linkText), findsOneWidget);
      expect(find.text(RecordProfileCard.ppaLabel), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byKey(RecordProfileCard.skeletonKey), findsNothing);
    });

    testWidgets('en el Perfil va entre "Configurar carnet" y "Carrera"', (
      tester,
    ) async {
      Get.put<AuthService>(_FakeAuthService(_student()));
      Get.put<AcademicRecordService>(
        AcademicRecordService(apiClient: _FakeRecordApi([_syncedJson()])),
      );

      await tester.pumpWidget(const GetMaterialApp(home: ProfilePage()));
      await tester.pump();
      await tester.pump();

      expect(find.byType(RecordProfileCard), findsOneWidget);

      final carnet = tester.getTopLeft(find.text('Configurar carnet')).dy;
      final tarjeta = tester.getTopLeft(find.byType(RecordProfileCard)).dy;
      final carrera = tester.getTopLeft(find.text('Carrera').first).dy;

      expect(tarjeta, greaterThan(carnet));
      expect(carrera, greaterThan(tarjeta));
    });

    testWidgets('un docente no ve la tarjeta ni dispara el GET', (
      tester,
    ) async {
      final api = _FakeRecordApi([_syncedJson()]);
      Get.put<AuthService>(_FakeAuthService(_teacher()));
      Get.put<AcademicRecordService>(AcademicRecordService(apiClient: api));

      await tester.pumpWidget(const GetMaterialApp(home: ProfilePage()));
      await tester.pump();
      await tester.pump();

      expect(find.byType(RecordProfileCard), findsNothing);
      expect(api.getCalls, 0);
      expect(AcademicRecordService.to.record, isNull);
    });

    testWidgets('después de borrar, la tarjeta pasa al aviso y no muestra el '
        'PPA anterior', (tester) async {
      final api = await _montarTarjeta(tester, [
        _syncedJson(),
        _neverSyncedJson(),
      ]);
      expect(find.text('14.62'), findsOneWidget);

      await AcademicRecordService.to.deleteRecord();
      await tester.pump();
      await tester.pump();

      expect(api.deleteCalls, 1);
      expect(api.lastDeletePath, '/academic-record/me');
      expect(api.getCalls, 2);
      expect(find.text(RecordProfileCard.neverSyncedText), findsOneWidget);
      expect(find.text('14.62'), findsNothing);
    });

    testWidgets('durante una recarga no se ve el PPA anterior', (tester) async {
      final recarga = Completer<Map<String, dynamic>>();
      final api = await _montarTarjeta(tester, [_syncedJson(), recarga]);
      expect(find.text('14.62'), findsOneWidget);

      unawaited(AcademicRecordService.to.reload());
      await tester.pump();

      expect(find.byKey(RecordProfileCard.skeletonKey), findsOneWidget);
      expect(find.text('14.62'), findsNothing);

      recarga.complete(_syncedJson(ppa: 16.02));
      await tester.pump();
      await tester.pump();

      expect(find.text('16.02'), findsOneWidget);
      expect(api.getCalls, 2);
    });
  });
}

// ── Dobles y datos del grupo WIDGET ──────────────────────────────────────────
//
// Escritos a mano, sin mockito ni mocktail. Son copias de los de
// test/HU34_jeff/academic_record_service_test.dart: allá son privados de ese
// archivo, así que no se pueden importar.

UserModel _student() => UserModel(
  code: '20230001',
  firstName: 'Alumna',
  lastName: 'De Prueba',
  email: 'test@aloe.ulima.edu.pe',
  role: 'student',
  currentCycle: '2026-1',
  setupComplete: true,
);

UserModel _teacher() => UserModel(
  code: 'docente.test',
  firstName: 'Docente',
  lastName: 'De Prueba',
  email: 'docente.test@ulima.edu.pe',
  role: 'teacher',
  currentCycle: '2026-1',
  setupComplete: true,
);

class _FakeAuthService extends AuthService {
  _FakeAuthService(UserModel? user) : userRx = Rx<UserModel?>(user);

  final Rx<UserModel?> userRx;

  @override
  UserModel? get currentUser => userRx.value;

  @override
  Rx<UserModel?> get currentUserRx => userRx;

  @override
  Future<void> refreshCurrentUser() async {}
}

class _FakeRecordApi extends ApiClient {
  _FakeRecordApi(this.getResponses) : super(configuredBaseUrl: 'http://test');

  /// Respuestas del GET, en orden; la última se repite. Un Map se devuelve,
  /// un Completer se espera y cualquier otra cosa se lanza.
  final List<Object> getResponses;
  Object? deleteError;
  int getCalls = 0;
  int deleteCalls = 0;
  String? lastGetPath;
  String? lastDeletePath;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    String? token,
    Map<String, String?> query = const {},
    bool suppressSessionExpiry = false,
  }) async {
    lastGetPath = path;
    final i = getCalls < getResponses.length
        ? getCalls
        : getResponses.length - 1;
    final r = getResponses[i];
    getCalls++;
    if (r is Completer<Map<String, dynamic>>) return r.future;
    if (r is Map<String, dynamic>) return r;
    throw r;
  }

  @override
  Future<Map<String, dynamic>> deleteJson(String path, {String? token}) async {
    deleteCalls++;
    lastDeletePath = path;
    if (deleteError != null) throw deleteError!;
    return <String, dynamic>{'ok': true};
  }
}

/// Récord inventado. Cada campo del snapshot se puede volver null para probar
/// que el dato que falta se omite y nunca se pinta como 0 (RF-REC-1).
Map<String, dynamic> _syncedJson({
  Object? ppa = 14.62,
  Object? relativePosition = 'TERCIO SUPERIOR',
  Object? creditsAccumulated = 164,
  Object? creditsRequired = 200,
}) => <String, dynamic>{
  'syncedAt': '2026-09-18T15:00:00Z',
  'snapshot': <String, dynamic>{
    'ppa': ppa,
    'relativePosition': relativePosition,
    'creditsAccumulated': creditsAccumulated,
    'creditsRequired': creditsRequired,
    'approved': <String, dynamic>{'courses': 50, 'credits': 164},
    'convalidated': <String, dynamic>{'courses': 0, 'credits': 0},
  },
  'periods': <dynamic>[],
  'record': <dynamic>[
    <String, dynamic>{
      'periodCode': '2026-1',
      'courses': <dynamic>[
        <String, dynamic>{
          'code': '100001',
          'name': 'CURSO DE PRUEBA A',
          'attempt': 1,
          'credits': 3,
          'grade': null,
          'gradeRaw': null,
          'section': '917',
          'observation': null,
        },
      ],
    },
  ],
};

Map<String, dynamic> _neverSyncedJson() => <String, dynamic>{
  'syncedAt': null,
  'snapshot': null,
  'periods': <dynamic>[],
  'record': <dynamic>[],
};

/// App mínima con la ruta destino: '/mi-record' todavía no está en main.dart
/// (la registra la tarea 6).
Widget _cardApp() => GetMaterialApp(
  initialRoute: '/',
  getPages: [
    GetPage(
      name: '/',
      page: () => const Scaffold(
        body: Padding(padding: EdgeInsets.all(16), child: RecordProfileCard()),
      ),
    ),
    GetPage(
      name: '/mi-record',
      page: () => const Scaffold(body: Text('RECORD')),
    ),
  ],
);

/// Monta la tarjeta suelta. El postFrameCallback de `initState` ya corrió al
/// final del frame de `pumpWidget`, así que `load()` está en vuelo: el primer
/// pump() vacía las microtareas y resuelve el Future del doble, y el segundo
/// pinta el frame que el Obx agendó al cambiar el Rx.
Future<_FakeRecordApi> _montarTarjeta(
  WidgetTester tester,
  List<Object> getResponses, {
  UserModel? user,
}) async {
  final api = _FakeRecordApi(getResponses);
  Get.put<AuthService>(_FakeAuthService(user ?? _student()));
  Get.put<AcademicRecordService>(AcademicRecordService(apiClient: api));
  await tester.pumpWidget(_cardApp());
  await tester.pump();
  await tester.pump();
  return api;
}
```

Por qué estos casos y no otros:
- Los cuatro estados que pide AGENTS ("estados explícitos de loading, error, vacío y éxito") quedan cubiertos: carga (`skeletonKey`), error (`errorTitle`), vacío (`neverSyncedText`) y éxito.
- `164`, `200` y `'164 de 200 créditos'` son el ejemplo que la spec publica en RF-REC-1 (`spec:43`), y esta tarjeta es justo lo que ese ejemplo describe. `14.62`, `16.02`, `230`, `'TERCIO SUPERIOR'`, `'100001'`, `'CURSO DE PRUEBA A'` y `'917'` son inventados y no aparecen en ningún fixture del repo ni en `spike-portal/` (comprobado con `grep`). El alumno es el sintético `20230001`; el docente, `docente.test`, el mismo que ya usa `test/components/header/app_header_test.dart`.
- `find.text('0')` en tres casos es la comprobación de "un dato null se omite, nunca se pinta 0".
- `find.textContaining('créditos')` cubre a la vez el texto y que no aparezca ninguna variante suya: la barra y el texto se deciden con la misma `creditsProgress`, así que no pueden discrepar. Ningún otro texto de la tarjeta contiene "créditos".
- `closeTo(164 / 200, 1e-9)` y no `0.8195`: el valor de la barra no se redondea; el `82%` redondeado es solo del anillo de la tarea 6.
- El test del docente mira dos cosas distintas: que la tarjeta ni se monta (guarda de `perfil.dart`) y que `getCalls` es 0 (guarda del servicio).
- Los dos últimos casos son RF-REC-5, y prueban caminos distintos: `deleteRecord()` deja `record` en `AcademicRecord.empty` (estado vacío, sin skeleton), mientras que `reload()` lo deja en null (skeleton). En los dos, el `14.62` anterior desaparece.
- `ProfilePage` se monta con solo `AuthService` y `AcademicRecordService` registrados: `_CarreraCard` llama a `getCareerName(null)`, que devuelve `''` y pinta `'—'`; `_PrincipalChip` (el único que usa `MallaService.to`) solo se construye si el usuario tiene `especialidadPrincipal`, y el alumno sintético no la tiene; `AvatarPerfil` crea su `AvatarService` y su `ImagePicker` con `late final`, así que nunca los instancia si no se toca; y `_ResetPasswordCard` no pide nada en `initState`.
- Ningún caso deja un `Timer` pendiente: los `Completer` se completan antes de terminar y `Future.timeout` cancela su Timer en cuanto el futuro se resuelve, también cuando se resuelve con error.

- [ ] **Paso 2: Correr la prueba y ver que falla**

```bash
cd . && $FLUTTER test test/HU34_jeff/record_card_test.dart
```

Esperado: falla al compilar, porque los dos archivos de widget todavía no existen. Las primeras líneas:

```
test/HU34_jeff/record_card_test.dart:8:8: Error: Error when reading 'lib/pages/academic_record/record_position_badge.dart': No such file or directory
import 'package:ulima_plus/pages/academic_record/record_position_badge.dart';
       ^
test/HU34_jeff/record_card_test.dart:9:8: Error: Error when reading 'lib/pages/academic_record/record_profile_card.dart': No such file or directory
import 'package:ulima_plus/pages/academic_record/record_profile_card.dart';
       ^
```

y después, un error por cada uso de los dos nombres que faltan: `Error: Undefined name 'RecordProfileCard'.` en cada `RecordProfileCard.ppaLabel`/`.linkText`/`.skeletonKey`/`find.byType(...)`, `Error: Undefined name 'RecordPositionBadge'.` en los dos `find.byType(RecordPositionBadge)` y `Error: Method not found: 'RecordProfileCard'.` en el `const RecordProfileCard()` de `_cardApp`. Termina en:

```
00:00 +0 -1: Some tests failed.
```

Es el fallo correcto: no compila por los dos archivos que faltan —ninguno sobre `perfil.dart`, `academic_record_service.dart` o `record_format.dart`— y ningún cuerpo de test llega a correr. Si sale un error sobre alguno de esos tres, un ancla o una firma cambió: detente. Si pasa cualquier otra cosa, los archivos ya existían: revísalos antes de seguir.

- [ ] **Paso 3: Implementación mínima**

**3.1 · Crear `lib/pages/academic_record/record_position_badge.dart`** con este contenido completo:

```dart
import 'package:flutter/material.dart';

import '../../configs/themes.dart';

/// Insignia de ubicación relativa del alumno ("Tercio superior").
///
/// La comparten la tarjeta del Perfil (RF-REC-1) y el encabezado de la
/// pantalla del récord (RF-REC-2). Recibe el texto YA formateado con
/// `formatRelativePosition`: cuando esa función devuelve null no hay dato y
/// quien llama simplemente no monta la insignia.
class RecordPositionBadge extends StatelessWidget {
  const RecordPositionBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: MaterialTheme.espPrincipalBg(brightness),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: MaterialTheme.primaryDark,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
```

**3.2 · Crear `lib/pages/academic_record/record_profile_card.dart`** con este contenido completo:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../components/skeleton.dart';
import '../../configs/themes.dart';
import '../../models/academic_record_model.dart';
import '../../services/academic_record_service.dart';
import 'record_format.dart';
import 'record_position_badge.dart';

/// Tarjeta del récord académico en el Perfil (RF-REC-1).
///
/// Lee el mismo [AcademicRecordService] que la pantalla, así que las dos
/// comparten un solo estado (RF-REC-5): al volver con back, o mientras se
/// recarga, nunca se ve el PPA ni los créditos anteriores.
///
/// Es `StatefulWidget` porque `ProfilePage` no es reactiva y se vuelve a
/// montar cada vez que se abre la pestaña Perfil: la carga se dispara en
/// `initState`, no en `build`. Un dato `null` se omite; nunca se pinta 0.
class RecordProfileCard extends StatefulWidget {
  const RecordProfileCard({super.key});

  /// Marca el bloque de carga para los tests: con `SkeletonPulse` en pantalla
  /// no se puede usar `pumpAndSettle`.
  static const Key skeletonKey = Key('record-card-skeleton');

  static const String ppaLabel = 'PPA';
  static const String neverSyncedText =
      'Sincroniza con el portal para ver tu récord';
  static const String linkText = 'Ver mi récord completo ›';

  /// Título que se muestra cuando la carga falló: sin cifras, solo el nombre
  /// de la pantalla y el enlace para entrar y reintentar.
  static const String errorTitle = 'Mi récord académico';

  @override
  State<RecordProfileCard> createState() => _RecordProfileCardState();
}

class _RecordProfileCardState extends State<RecordProfileCard> {
  @override
  void initState() {
    super.initState();
    // Después del frame, nunca durante build: load() cambia Rx y un Obx que
    // reaccionara haría setState en plena construcción del árbol.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // La guarda de docente y la caché por usuario ya están en el servicio.
      if (mounted) AcademicRecordService.to.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Semantics(
      button: true,
      label: 'Mi récord académico',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.toNamed<dynamic>('/mi-record'),
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: MaterialTheme.cardBg(brightness),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: MaterialTheme.borderColor(brightness)),
            ),
            child: Obx(() {
              final servicio = AcademicRecordService.to;
              // Los dos Rx se leen siempre, pase lo que pase después: así el
              // Obx queda suscrito a los dos en cualquier estado.
              final record = servicio.record;
              final hasError = servicio.hasError;

              if (record == null) {
                return hasError ? _error(brightness) : _cargando();
              }
              if (!record.hasRecord) return _sinSincronizar(brightness);
              return _conRecord(brightness, record.snapshot);
            }),
          ),
        ),
      ),
    );
  }

  Widget _cargando() => const SkeletonPulse(
    key: RecordProfileCard.skeletonKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SkeletonBox(width: 40, height: 10),
        SizedBox(height: 6),
        SkeletonBox(width: 90, height: 26),
        SizedBox(height: 12),
        SkeletonBox(width: double.infinity, height: 6),
      ],
    ),
  );

  Widget _error(Brightness brightness) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        RecordProfileCard.errorTitle,
        style: TextStyle(
          color: MaterialTheme.textPrimary(brightness),
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        RecordProfileCard.linkText,
        style: TextStyle(
          color: MaterialTheme.primaryDark,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );

  Widget _sinSincronizar(Brightness brightness) => Row(
    children: [
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: MaterialTheme.espPrincipalBg(brightness),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.history_edu_outlined,
          color: MaterialTheme.primaryDark,
          size: 20,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          RecordProfileCard.neverSyncedText,
          style: TextStyle(
            color: MaterialTheme.textPrimary(brightness),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Icon(
        LucideIcons.chevronRight,
        size: 18,
        color: MaterialTheme.labelColor(brightness),
      ),
    ],
  );

  Widget _conRecord(Brightness brightness, AcademicSnapshot? snapshot) {
    final ppa = snapshot?.ppa;
    final posicion = formatRelativePosition(snapshot?.relativePosition);
    final progreso = creditsProgress(
      snapshot?.creditsAccumulated,
      snapshot?.creditsRequired,
    );
    final creditos = creditsOfRequiredLabel(
      snapshot?.creditsAccumulated,
      snapshot?.creditsRequired,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Cada bloque solo se monta si su dato vino: RF-REC-1, "Datos que
        // faltan". Nunca se rellena con 0.
        if (ppa != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    RecordProfileCard.ppaLabel,
                    style: TextStyle(
                      color: MaterialTheme.labelColor(brightness),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    formatDecimal(ppa),
                    style: TextStyle(
                      color: MaterialTheme.textPrimary(brightness),
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (posicion != null) RecordPositionBadge(label: posicion),
            ],
          )
        else if (posicion != null)
          Align(
            alignment: Alignment.centerLeft,
            child: RecordPositionBadge(label: posicion),
          ),
        if (progreso != null) ...[
          const SizedBox(height: 10),
          Text(
            // creditsOfRequiredLabel tiene las mismas guardas que
            // creditsProgress: si hay barra, hay texto.
            creditos!,
            style: TextStyle(
              color: MaterialTheme.textSecondary(brightness),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 6,
              backgroundColor: MaterialTheme.progressBg(brightness),
              color: MaterialTheme.primaryColor,
            ),
          ),
        ],
        const SizedBox(height: 10),
        const Text(
          RecordProfileCard.linkText,
          style: TextStyle(
            color: MaterialTheme.primaryDark,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
```

Detalles que no son libres:
- El `Obx` lee `record` **y** `hasError` antes de decidir nada: `record` es un getter que lee el `Rx` primero y después compara el dueño, así que la suscripción existe aunque devuelva null.
- Las tres `Column` llevan `mainAxisSize: MainAxisSize.min`: la tarjeta vive dentro del `SingleChildScrollView` del Perfil, con altura sin acotar.
- `SkeletonBox(width: double.infinity, ...)` dentro de una `Column` toma el ancho disponible: `Container` mete su `BoxConstraints.tightFor(width: infinity)` por `enforce` contra las que le llegan, y el infinito queda recortado al `maxWidth` de la columna.
- `MaterialTheme.primaryDark` y `MaterialTheme.primaryColor` son `static const Color`, por eso los `TextStyle` y el `Icon` que solo los usan a ellos van `const`. `_cargando()` es `const` entero, con `RecordProfileCard.skeletonKey` como `key`.
- El enlace se pinta en los tres estados con contenido (éxito, error y —como chevron— sin sincronizar), porque toda la tarjeta navega igual a `/mi-record`.
- `child`/`children` siempre al final de cada constructor: `sort_child_properties_last` está activo.

**3.3 · Comprobar que solo falta el Perfil**

```bash
cd . && $FLUTTER test test/HU34_jeff/record_card_test.dart
```

Esperado: `00:0X +29 -1: Some tests failed.` — los 16 casos de la tarea 3 y 13 de los 14 nuevos pasan; el único que falla es el del orden en el Perfil, con:

```
Expected: exactly one matching candidate
  Actual: _TypeWidgetFinder:<Found 0 widgets with type "RecordProfileCard": []>
```

Si falla alguno más, arréglalo antes de tocar `perfil.dart`.

**3.4 · Modificar `lib/pages/perfil/perfil.dart`** (dos cambios, nada más en el archivo)

Reemplazar esto (líneas 6-7, sin sangría):

```dart
import '../../components/networking/networking_profile_entry_card.dart';
import '../../configs/themes.dart';
```

por esto:

```dart
import '../../components/networking/networking_profile_entry_card.dart';
import '../../configs/themes.dart';
import '../academic_record/record_profile_card.dart';
```

Reemplazar esto (líneas 43-44; el `if` lleva 26 espacios de sangría y `const _CarreraCard(),` lleva 28):

```dart
                          if (!user.isTeacher) ...[
                            const _CarreraCard(),
```

por esto:

```dart
                          if (!user.isTeacher) ...[
                            const RecordProfileCard(),
                            const SizedBox(height: 16),
                            const _CarreraCard(),
```

La tarjeta queda dentro del bloque de alumno, entre "Configurar carnet" (el `NetworkingProfileEntryCard` de las líneas 39-41) y la tarjeta de Carrera, que es lo que pide RF-REC-1. Un docente no entra al bloque, así que no monta la tarjeta y no dispara el `GET`. El import nuevo va tercero porque `../academic_record/...` ordena después de `../../configs/...` en el bloque relativo que ya tiene el archivo.

- [ ] **Paso 4: Correr la prueba y ver que pasa**

```bash
cd . && $FLUTTER test test/HU34_jeff/record_card_test.dart
```

Esperado: PASS, los 16 casos de la tarea 3 más los 14 nuevos:

```
00:0X +30: All tests passed!
```

Después, la carpeta entera de la HU, para comprobar que nada de las tareas 1 y 2 se rompió:

```bash
cd . && $FLUTTER test test/HU34_jeff/
```

Esperado: `All tests passed!`.

- [ ] **Paso 5: Análisis estático**

```bash
cd . && $FLUTTER analyze lib/pages/academic_record/ lib/pages/perfil/perfil.dart test/HU34_jeff/record_card_test.dart
```

Esperado: `No issues found! (ran in …)`. Si sale algún issue en los archivos nuevos o en el test, corrígelo y repite los pasos 4 y 5. Si el issue ya venía de `perfil.dart` en la línea base de la tarea 1, no lo toques: se reporta aparte, tal como pide AGENTS.

Y el proyecto entero, para comprobar que el número de issues preexistentes que anotaste en la tarea 1 no subió:

```bash
cd . && $FLUTTER analyze 2>&1 | grep -E "issues? found|record_profile_card|record_position_badge|record_card|perfil"
```

Esperado: la misma línea `N issues found. (ran in …)` (o `No issues found!`) de la tarea 1, ninguna línea que nombre `record_profile_card`, `record_position_badge` ni `record_card`, y sobre `perfil` exactamente las mismas líneas (si había alguna) que ya estaban en esa línea base. Si esta tarea corre en otra sesión no tienes el reporte de la tarea 1: la línea base está en `$TMP/plan-fe/analyze-baseline.txt`; léela con `cat` y compara sin el `(ran in …)`. Si el número subió, el issue nuevo es de esta tarea: corrígelo.

- [ ] **Paso final: Commit**

Revisa primero que el árbol no tenga cambios ajenos:

```bash
cd . && git status --short --untracked-files=all
```

Esperado, en cualquier orden, exactamente estas cuatro líneas:

```
 M lib/pages/perfil/perfil.dart
 M test/HU34_jeff/record_card_test.dart
?? lib/pages/academic_record/record_position_badge.dart
?? lib/pages/academic_record/record_profile_card.dart
```

Si aparece otro archivo, no lo agregues ni lo toques: puede ser de otra sesión.

```bash
cd . && git add lib/pages/academic_record/record_position_badge.dart lib/pages/academic_record/record_profile_card.dart lib/pages/perfil/perfil.dart test/HU34_jeff/record_card_test.dart && git diff --cached --stat
```

Esperado: exactamente esos 4 archivos y `4 files changed`.

```bash
cd . && git commit -m "feat(academic-record): tarjeta del récord en el Perfil"
```

El autor ya está configurado en git. El mensaje no lleva trailer `Co-Authored-By`. No hagas push.

### Tarea 5: Fila de curso: chip de nota, 'N.ª vez' y observación

**Archivos:**
- Crear: `lib/pages/academic_record/record_course_row.dart` (la carpeta `lib/pages/academic_record/` ya existe: la creó la tarea 3 con `record_format.dart`)
- Test: `test/HU34_jeff/record_course_row_test.dart` (crear; la carpeta `test/HU34_jeff/` ya existe desde la tarea 1). Es un archivo propio de esta tarea: ninguna tarea posterior le agrega grupos.
- No se modifica ningún archivo existente. La spec ya enlaza este test al final de RF-REC-3 (`specs/features/academic-record/academic-record.spec.md:111`), así que esta tarea **no** toca la spec. Las inserciones de las tareas 1 y 2 van después (líneas 173 y 135), de modo que RF-REC-3 sigue en las líneas 87-111 cuando llegues aquí.
- La tarea 7 monta estas filas dentro de la tarjeta de cursos del ciclo elegido; aquí no se toca `academic_record_page.dart` ni ningún controller.

**Interfaces:**
- Consume:
  - **Tarea 1**, `lib/models/academic_record_model.dart`: `class RecordCourse { const RecordCourse({required this.code, required this.name, required this.attempt, required this.credits, required this.grade, required this.gradeRaw, required this.section, required this.observation}); final String code; final String name; final int? attempt; final double? credits; final int? grade; final String? gradeRaw; final String? section; final String? observation; }`. Los ocho parámetros son `required`, así que en las pruebas hay que pasarlos todos (por eso el helper `curso(...)` del Paso 1). Esta tarea **no** usa `section`.
  - **Tarea 3**, `lib/pages/academic_record/record_format.dart`: `String creditsShortLabel(double credits)` — `'1.5 créd.'` | `'3 créd.'`. Es la única función de formato que usa esta tarea; `formatDecimal` no se llama directo.
  - **Del repo**, `lib/configs/themes.dart` (clase `MaterialTheme`, línea 5). Las cinco que se usan aquí son estáticas y reciben un solo `Brightness b`: `textPrimary` (`:63`), `textMuted` (`:71`), `tagBg` (`:83`), `espInteresBg` (`:103`), `labelColor` (`:135`). El archivo no se modifica (está en la lista de intocables del plan).
  - **Del repo**, precedentes de color que se reutilizan sin inventar ninguno: `lib/pages/mis_notas/mis_notas_page.dart:209` (`const Color(0xFF16A34A)` aprobado / `const Color(0xFFDC2626)` desaprobado, con fondo `color.withValues(alpha: 0.12)` en `:213`); `lib/models/malla_models.dart:23` y `:37` (`const Color(0xFFF59E0B)` y `const Color(0xFFD97706)` de `CourseStatus.current`); `lib/pages/perfil/perfil.dart:594-596` (`brightness == Brightness.light ? const Color(0xFF0369A1) : const Color(0xFF38BDF8)`, dentro de `_InteresChip`, que pone de fondo `MaterialTheme.espInteresBg(brightness)` en `:580`); `lib/pages/perfil/perfil.dart:273-297` (la insignia "Fija" de `_CarreraCard`, clase que empieza en `:216`: `tagBg` de fondo y `labelColor` de texto).
  - **Del repo**, patrones que se imitan: `lib/pages/horario/horario.dart:56` (`static List<String> blockMetaLines({...})`) y `:73` (`static ({double top, double height}) blockGeometry({...})`), las dos estáticas de `HorarioPage` (`:18`) que la spec cita como modelo de lógica pura y probada (`spec:108-109`) — aquí las funciones son de nivel superior, no `static`, porque el archivo no tiene una clase-página que las albergue; `lib/pages/mis_notas/mis_notas_page.dart:16` (`final brightness = Theme.brightnessOf(context);`); `Wrap(spacing:, runSpacing:)` de `lib/pages/perfil/perfil.dart:470` y `lib/pages/malla/widgets/course_detail_sheet.dart:153`.
- Produce: `lib/pages/academic_record/record_course_row.dart`
  - `enum RecordChipTone { green, amber, red, blue, neutral }`
  - `typedef RecordChip = ({RecordChipTone tone, String label});`
  - `RecordChip recordChipFor({required int? grade, required String? gradeRaw, required bool isMostRecentPeriod})`
  - `({Color background, Color foreground}) recordChipColors(RecordChipTone tone, Brightness brightness)`
  - `String? attemptLabel(int? attempt)` — `2` → `'2.ª vez'`; `1`, `0` y `null` → `null`
  - `String courseSubtitle({required String code, required double? credits})` — `'100002 · 1.5 créd.'`; con `credits` null → solo el código
  - `class RecordCourseRow extends StatelessWidget { const RecordCourseRow({super.key, required this.course, required this.isMostRecentPeriod}); final RecordCourse course; final bool isMostRecentPeriod; static const String inProgressLabel = 'En curso'; static const String noGradeLabel = '—'; }`

Quién lo usa después: la tarea 7 construye `RecordCourseRow(course: …, isMostRecentPeriod: …)` para cada curso del ciclo elegido, y es ella la que decide qué ciclo es el más reciente (el primer `periodCode` de `coursesByPeriod`); esta fila no lo adivina, se lo dan.

**Ojo con los nombres y con los datos:**
- Hoy no existe en `lib/` ni en `test/` nada llamado `recordChipFor`, `RecordChipTone`, `RecordChip`, `recordChipColors`, `attemptLabel`, `courseSubtitle` ni `RecordCourseRow` (`grep -rn "recordChipFor\|RecordChipTone\|attemptLabel\|courseSubtitle\|RecordCourseRow\|recordChipColors" lib/ test/` no devuelve nada), así que se importan sin prefijo y no chocan con nada.
- **Códigos inventados, siempre.** El esqueleto ilustraba `courseSubtitle` con un código de seis dígitos que sale del volcado real del portal (`rec_spike.html`); aquí se cambió por `100002`. En las pruebas y en los comentarios del código van códigos `1000xx`, `1234` para el curso de una malla anterior (que tenía códigos más cortos), secciones `9xx` como en la tarea 1 y nombres `CURSO … DE PRUEBA`: el repo es público y no entra ningún dato real, ni de fixtures ni del spike del portal.
- El nombre y el código se pintan **tal como llegan**, sin pasarlos por la malla vigente ni normalizarlos: eso es lo que cumple "los cursos de mallas anteriores se muestran con su código y nombre originales" (`spec:106`).

- [ ] **Paso 1: Escribir la prueba que falla**

Crear `test/HU34_jeff/record_course_row_test.dart` con este contenido completo:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/academic_record_model.dart';
import 'package:ulima_plus/pages/academic_record/record_course_row.dart';

/// Récord académico: la fila de un curso (RF-REC-3).
///
/// El chip es la única parte del récord donde un error de lógica cambia lo que
/// el alumno cree de su historia académica: pintar de azul —el color de las
/// marcas del portal, como una convalidación— un curso del ciclo en curso que
/// todavía no tiene nota le diría que ya no lo lleva. Por eso la decisión vive
/// en funciones puras, probadas caso por caso, y el widget solo las llama.
///
/// Todos los cursos, códigos, notas y observaciones son inventados.
void main() {
  RecordCourse curso({
    String code = '100001',
    String name = 'CURSO DE PRUEBA UNO',
    int? attempt = 1,
    double? credits = 3,
    int? grade,
    String? gradeRaw,
    String? section = '917',
    String? observation,
  }) => RecordCourse(
    code: code,
    name: name,
    attempt: attempt,
    credits: credits,
    grade: grade,
    gradeRaw: gradeRaw,
    section: section,
    observation: observation,
  );

  Widget montar(RecordCourse course, {bool isMostRecentPeriod = false}) =>
      MaterialApp(
        home: Scaffold(
          body: RecordCourseRow(
            course: course,
            isMostRecentPeriod: isMostRecentPeriod,
          ),
        ),
      );

  group('UNITARIA · recordChipFor: los seis casos de RF-REC-3', () {
    RecordChip chip(int? grade, String? gradeRaw, {bool reciente = false}) =>
        recordChipFor(
          grade: grade,
          gradeRaw: gradeRaw,
          isMostRecentPeriod: reciente,
        );

    test('de 14 para arriba: verde, con la nota', () {
      expect(chip(20, null), (tone: RecordChipTone.green, label: '20'));
      expect(chip(17, null), (tone: RecordChipTone.green, label: '17'));
      expect(chip(14, null), (tone: RecordChipTone.green, label: '14'));
    });

    test('de 11 a 13: ámbar', () {
      expect(chip(13, null), (tone: RecordChipTone.amber, label: '13'));
      expect(chip(11, null), (tone: RecordChipTone.amber, label: '11'));
    });

    test('por debajo de 11: rojo, y las de un dígito con cero delante', () {
      expect(chip(10, null), (tone: RecordChipTone.red, label: '10'));
      expect(chip(8, null), (tone: RecordChipTone.red, label: '08'));
      expect(chip(0, null), (tone: RecordChipTone.red, label: '00'));
    });

    test('sin nota pero con marca del portal: azul, con el texto tal cual', () {
      expect(chip(null, 'CONV'), (tone: RecordChipTone.blue, label: 'CONV'));
      expect(chip(null, 'RET'), (tone: RecordChipTone.blue, label: 'RET'));
      // Una marca del portal es azul también en el ciclo más reciente.
      expect(
        chip(null, 'CONV', reciente: true),
        (tone: RecordChipTone.blue, label: 'CONV'),
      );
    });

    test('sin nota en el ciclo más reciente: neutro, "En curso"', () {
      expect(
        chip(null, null, reciente: true),
        (tone: RecordChipTone.neutral, label: 'En curso'),
      );
      // Un gradeRaw en blanco no es una marca: es un dato que no vino.
      expect(
        chip(null, '   ', reciente: true),
        (tone: RecordChipTone.neutral, label: 'En curso'),
      );
    });

    test('sin nota en un ciclo viejo: neutro, una raya', () {
      expect(chip(null, null), (tone: RecordChipTone.neutral, label: '—'));
      expect(chip(null, '   '), (tone: RecordChipTone.neutral, label: '—'));
    });

    test('un curso sin nota del ciclo en curso NUNCA se pinta de azul', () {
      // El caso que la spec marca aparte (spec:100-101): el ciclo en curso
      // viene seleccionado, así que sus cursos sin nota son lo primero que ve
      // el alumno. En azul parecerían convalidados o retirados.
      expect(chip(null, null, reciente: true).tone, isNot(RecordChipTone.blue));
    });

    test('la nota manda sobre el ciclo: un 15 del ciclo en curso va en verde', () {
      expect(chip(15, null, reciente: true), (
        tone: RecordChipTone.green,
        label: '15',
      ));
    });

    test('los rótulos neutros son las constantes de la fila', () {
      expect(RecordCourseRow.inProgressLabel, 'En curso');
      expect(RecordCourseRow.noGradeLabel, '—');
    });
  });

  group('UNITARIA · attemptLabel y courseSubtitle', () {
    test('la etiqueta aparece recién desde la segunda vez', () {
      expect(attemptLabel(null), isNull);
      expect(attemptLabel(0), isNull);
      expect(attemptLabel(1), isNull);
      expect(attemptLabel(2), '2.ª vez');
      expect(attemptLabel(3), '3.ª vez');
    });

    test('el subtítulo junta el código y los créditos con " · "', () {
      expect(
        courseSubtitle(code: '100002', credits: 1.5),
        '100002 · 1.5 créd.',
      );
      // Un valor entero va sin ".0".
      expect(courseSubtitle(code: '100002', credits: 3), '100002 · 3 créd.');
    });

    test('sin créditos queda solo el código: nunca "0 créd."', () {
      expect(courseSubtitle(code: '100002', credits: null), '100002');
    });
  });

  group('UNITARIA · recordChipColors', () {
    test('verde, ámbar y rojo son los colores que el repo ya usa', () {
      expect(
        recordChipColors(RecordChipTone.green, Brightness.light).foreground,
        const Color(0xFF16A34A),
      );
      expect(
        recordChipColors(RecordChipTone.amber, Brightness.light).foreground,
        const Color(0xFFD97706),
      );
      expect(
        recordChipColors(RecordChipTone.red, Brightness.light).foreground,
        const Color(0xFFDC2626),
      );
    });

    test('el fondo de la nota es su mismo color con alfa, no un color nuevo', () {
      expect(
        recordChipColors(RecordChipTone.green, Brightness.light).background,
        const Color(0xFF16A34A).withValues(alpha: 0.12),
      );
      expect(
        recordChipColors(RecordChipTone.red, Brightness.light).background,
        const Color(0xFFDC2626).withValues(alpha: 0.12),
      );
      expect(
        recordChipColors(RecordChipTone.amber, Brightness.light).background,
        const Color(0xFFF59E0B).withValues(alpha: 0.15),
      );
    });

    test('los tres colores de nota no cambian con el modo oscuro', () {
      for (final tono in [
        RecordChipTone.green,
        RecordChipTone.amber,
        RecordChipTone.red,
      ]) {
        expect(
          recordChipColors(tono, Brightness.dark).foreground,
          recordChipColors(tono, Brightness.light).foreground,
          reason: 'la nota se lee igual en los dos modos',
        );
      }
    });

    test('el azul sí cambia con el modo, como el chip de interés del Perfil', () {
      expect(
        recordChipColors(RecordChipTone.blue, Brightness.light).foreground,
        const Color(0xFF0369A1),
      );
      expect(
        recordChipColors(RecordChipTone.blue, Brightness.dark).foreground,
        const Color(0xFF38BDF8),
      );
      for (final b in [Brightness.light, Brightness.dark]) {
        expect(
          recordChipColors(RecordChipTone.blue, b).background,
          MaterialTheme.espInteresBg(b),
        );
      }
    });

    test('el neutro sale del tema, como la insignia "Fija" del Perfil', () {
      for (final b in [Brightness.light, Brightness.dark]) {
        final colores = recordChipColors(RecordChipTone.neutral, b);
        expect(colores.foreground, MaterialTheme.labelColor(b));
        expect(colores.background, MaterialTheme.tagBg(b));
      }
    });
  });

  group('WIDGET · RecordCourseRow', () {
    testWidgets('un curso repetido con nota y observación muestra las cinco cosas', (
      tester,
    ) async {
      await tester.pumpWidget(
        montar(
          curso(
            code: '100002',
            name: 'CURSO DE PRUEBA DOS',
            attempt: 2,
            credits: 1.5,
            grade: 17,
            observation: 'Convalidado por examen',
          ),
        ),
      );

      expect(find.text('CURSO DE PRUEBA DOS'), findsOneWidget);
      expect(find.text('2.ª vez'), findsOneWidget);
      expect(find.text('100002 · 1.5 créd.'), findsOneWidget);
      expect(find.text('17'), findsOneWidget);
      expect(find.text('Convalidado por examen'), findsOneWidget);

      // "debajo del código, en texto pequeño" (spec:104-105): la observación
      // se lee más chica que el subtítulo, no igual.
      final tamanoCodigo = tester
          .widget<Text>(find.text('100002 · 1.5 créd.'))
          .style
          ?.fontSize;
      final tamanoObservacion = tester
          .widget<Text>(find.text('Convalidado por examen'))
          .style
          ?.fontSize;
      expect(tamanoCodigo, isNotNull);
      expect(tamanoObservacion, lessThan(tamanoCodigo!));
    });

    testWidgets('en la primera vez no aparece ninguna etiqueta', (tester) async {
      await tester.pumpWidget(montar(curso(attempt: 1, grade: 13)));
      expect(find.textContaining('vez'), findsNothing);
    });

    testWidgets('el chip usa el color de su tono, no uno propio', (tester) async {
      await tester.pumpWidget(montar(curso(grade: 17)));
      expect(
        tester.widget<Text>(find.text('17')).style?.color,
        const Color(0xFF16A34A),
      );

      await tester.pumpWidget(montar(curso(grade: 8)));
      expect(
        tester.widget<Text>(find.text('08')).style?.color,
        const Color(0xFFDC2626),
      );
    });

    testWidgets('un curso de una malla anterior conserva su código y su nombre', (
      tester,
    ) async {
      await tester.pumpWidget(
        montar(
          curso(
            code: '1234',
            name: 'CURSO ANTIGUO DE PRUEBA',
            credits: 2,
            grade: 12,
          ),
        ),
      );
      expect(find.text('CURSO ANTIGUO DE PRUEBA'), findsOneWidget);
      expect(find.text('1234 · 2 créd.'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('sin nota: "En curso" en el ciclo reciente y una raya en otro', (
      tester,
    ) async {
      await tester.pumpWidget(montar(curso(), isMostRecentPeriod: true));
      expect(find.text('En curso'), findsOneWidget);
      expect(find.text('—'), findsNothing);

      await tester.pumpWidget(montar(curso()));
      expect(find.text('—'), findsOneWidget);
      expect(find.text('En curso'), findsNothing);
    });

    testWidgets('sin créditos el subtítulo es solo el código', (tester) async {
      await tester.pumpWidget(
        montar(curso(code: '100004', credits: null, gradeRaw: 'CONV')),
      );
      expect(find.text('100004'), findsOneWidget);
      expect(find.text('CONV'), findsOneWidget);
    });
  });
}
```

Por qué estos casos y no otros:
- Los cuatro grupos suman **23 casos** y cubren los ocho requisitos del esqueleto para esta tarea: los seis renglones de la tabla de RF-REC-3 (grupo 1), la regla "nunca azul" del ciclo en curso como caso propio (grupo 1), `attempt ≥ 2` (grupo 2 y grupo 4), el subtítulo `'código · N créd.'` con decimales sin `.0` (grupo 2 y grupo 4), la observación en su propia línea y **más chica que el código** (grupo 4), y el curso de malla anterior con su código y nombre originales (grupo 4).
- Las fronteras van dos a dos —14 y 20 en verde, 13 y 11 en ámbar, 10 y 8 y 0 en rojo— porque el error típico aquí es un `>` donde va un `>=`: sin el 14 y el 11 exactos, un chip mal puesto pasaría igual.
- `0` no es "sin nota", es un cero real, y por eso tiene que salir rojo y con rótulo `'00'`. Es el mismo criterio de RF-REC-1 con los créditos: un dato que vale 0 se muestra; uno que no vino se omite.
- `'   '` en `gradeRaw` prueba la única normalización que hay: un espacio en blanco del portal no es una marca. Sin el `trim()`, el chip saldría azul con un rótulo invisible.
- El caso del `15` en el ciclo más reciente fija la precedencia: primero la nota, después el ciclo.
- El grupo de colores compara contra los literales que el repo ya usa (`0xFF16A34A`, `0xFFD97706`, `0xFFDC2626`) y contra los helpers de `MaterialTheme`, no contra colores nuevos; y el caso del modo oscuro existe porque el azul es el único tono que cambia.
- `find.textContaining('vez')` funciona porque ningún nombre inventado de curso contiene esa sílaba; si alguna vez se agrega uno que sí, hay que cambiar el nombre, no el aserto.
- En el grupo de widget, el aserto del color del `Text` del chip es el que impide que la fila se pinte sola: comprueba que el widget llama a `recordChipColors` en vez de repetir el literal. La comparación de tamaños de la observación hace lo mismo con "texto pequeño": sin ella, una observación del mismo tamaño que el código pasaría la prueba. Los `find.text` exactos (`'100002 · 1.5 créd.'`) comprueban de paso el separador ` · ` (U+00B7 con un espacio a cada lado) y que `creditsShortLabel` está enchufado.
- El `credits: 3` y el `credits: 2` de las pruebas son literales enteros en contexto `double?`: Dart los toma como `3.0` y `2.0`, así que compilan y `creditsShortLabel` los imprime sin el `.0`.
- Ninguna prueba monta `SkeletonPulse` ni un campo con foco, así que aquí `pumpWidget` basta y no hace falta la regla de no usar `pumpAndSettle`.

- [ ] **Paso 2: Correr la prueba y ver que falla**

```bash
cd . && $FLUTTER test test/HU34_jeff/record_course_row_test.dart
```

Esperado: no compila, porque el archivo que se importa todavía no existe. Las primeras líneas, con estas posiciones exactas:

```
test/HU34_jeff/record_course_row_test.dart:5:8: Error: Error when reading 'lib/pages/academic_record/record_course_row.dart': No such file or directory
import 'package:ulima_plus/pages/academic_record/record_course_row.dart';
       ^
test/HU34_jeff/record_course_row_test.dart:40:17: Error: Method not found: 'RecordCourseRow'.
          body: RecordCourseRow(
                ^^^^^^^^^^^^^^^
test/HU34_jeff/record_course_row_test.dart:48:5: Error: 'RecordChip' isn't a type.
    RecordChip chip(int? grade, String? gradeRaw, {bool reciente = false}) =>
    ^^^^^^^^^^
test/HU34_jeff/record_course_row_test.dart:49:9: Error: Method not found: 'recordChipFor'.
        recordChipFor(
        ^^^^^^^^^^^^^
```

y al final:

```
00:00 +0 -1: Some tests failed.

Failing tests:
  ./test/HU34_jeff/record_course_row_test.dart: loading ./test/HU34_jeff/record_course_row_test.dart
```

Es el fallo correcto: entre esas líneas y el resumen hay un bloque `Error:` por cada uso de un nombre que todavía no existe —56 en total, y el compilador los imprime dos veces, primero sueltos y después indentados dentro del reporte—, repartidos así: 30 `Undefined name 'RecordChipTone'`, 12 `Method not found: 'recordChipColors'`, 5 `Method not found: 'attemptLabel'`, 3 `Method not found: 'courseSubtitle'`, 2 `Undefined name 'RecordCourseRow'` (los dos usos de las constantes `inProgressLabel` y `noGradeLabel`), 1 `Method not found: 'recordChipFor'`, 1 `Method not found: 'RecordCourseRow'`, 1 `'RecordChip' isn't a type` y el de lectura del archivo. Ningún cuerpo de test llega a correr. Lo que **no** debe salir es un error sobre `RecordCourse` ni sobre `package:ulima_plus/models/academic_record_model.dart`: eso significaría que la tarea 1 no está hecha en este árbol, y entonces hay que terminarla antes de seguir. Si sale `All tests passed!`, el archivo de implementación ya existía: revísalo antes de tocar nada.

- [ ] **Paso 3: Implementación mínima**

Crear `lib/pages/academic_record/record_course_row.dart` con este contenido completo:

```dart
// lib/pages/academic_record/record_course_row.dart
// La fila de un curso del récord académico (RF-REC-3): el nombre, la etiqueta
// "N.ª vez", "código · N créd.", la observación y el chip de nota.
//
// La decisión del chip y la de la etiqueta son funciones puras de nivel
// superior para poder probarlas sin montar widgets, igual que
// HorarioPage.blockMetaLines y HorarioPage.blockGeometry
// (lib/pages/horario/horario.dart:56-82), que la spec cita como modelo.

import 'package:flutter/material.dart';

import '../../configs/themes.dart';
import '../../models/academic_record_model.dart';
import 'record_format.dart';

/// Los cinco tonos del chip de nota de RF-REC-3.
enum RecordChipTone { green, amber, red, blue, neutral }

/// Lo que se pinta en el chip: de qué color va y qué dice.
typedef RecordChip = ({RecordChipTone tone, String label});

/// Los seis casos de la tabla de RF-REC-3, en un solo lugar.
///
/// El orden importa: la nota manda. Un curso con nota es verde, ámbar o rojo
/// aunque esté en el ciclo más reciente; recién cuando no hay nota entra en
/// juego `gradeRaw` (la marca del portal: convalidación, retiro u otra) y,
/// si tampoco la hay, el ciclo decide entre "En curso" y una raya.
///
/// Un curso del ciclo en curso sin nota NUNCA sale azul: el azul es el color
/// de las marcas del portal, y ese ciclo es el que el alumno ve primero.
RecordChip recordChipFor({
  required int? grade,
  required String? gradeRaw,
  required bool isMostRecentPeriod,
}) {
  if (grade != null) {
    // Las notas de un dígito llevan cero delante ("08"), como en la maqueta
    // aprobada: así todos los chips miden lo mismo en la columna.
    final label = grade.toString().padLeft(2, '0');
    if (grade >= 14) return (tone: RecordChipTone.green, label: label);
    if (grade >= 11) return (tone: RecordChipTone.amber, label: label);
    return (tone: RecordChipTone.red, label: label);
  }
  // Un gradeRaw en blanco no es una marca del portal: es un dato que no vino.
  final raw = gradeRaw?.trim() ?? '';
  if (raw.isNotEmpty) return (tone: RecordChipTone.blue, label: raw);
  return isMostRecentPeriod
      ? (tone: RecordChipTone.neutral, label: RecordCourseRow.inProgressLabel)
      : (tone: RecordChipTone.neutral, label: RecordCourseRow.noGradeLabel);
}

/// Colores del chip. Todos salen de la paleta que el repo ya usa.
///
/// Verde y rojo son los de la nota final de /mis-notas
/// (mis_notas_page.dart:209), el ámbar es el del curso en curso de la malla
/// (malla_models.dart:23 y :37), el azul es el del chip de interés del Perfil
/// (perfil.dart:594-596) y el neutro es el de la insignia "Fija"
/// (perfil.dart:273-297).
({Color background, Color foreground}) recordChipColors(
  RecordChipTone tone,
  Brightness brightness,
) {
  switch (tone) {
    case RecordChipTone.green:
      return (
        background: const Color(0xFF16A34A).withValues(alpha: 0.12),
        foreground: const Color(0xFF16A34A),
      );
    case RecordChipTone.amber:
      return (
        background: const Color(0xFFF59E0B).withValues(alpha: 0.15),
        foreground: const Color(0xFFD97706),
      );
    case RecordChipTone.red:
      return (
        background: const Color(0xFFDC2626).withValues(alpha: 0.12),
        foreground: const Color(0xFFDC2626),
      );
    case RecordChipTone.blue:
      return (
        background: MaterialTheme.espInteresBg(brightness),
        foreground: brightness == Brightness.light
            ? const Color(0xFF0369A1)
            : const Color(0xFF38BDF8),
      );
    case RecordChipTone.neutral:
      return (
        background: MaterialTheme.tagBg(brightness),
        foreground: MaterialTheme.labelColor(brightness),
      );
  }
}

/// "2.ª vez" desde la segunda matrícula; en la primera no hay etiqueta.
///
/// Con `attempt` nulo tampoco: un dato que no vino no se convierte en "1.ª
/// vez" ni en nada.
String? attemptLabel(int? attempt) =>
    (attempt != null && attempt >= 2) ? '$attempt.ª vez' : null;

/// "100002 · 1.5 créd.", o solo el código si no vinieron los créditos.
String courseSubtitle({required String code, required double? credits}) =>
    credits == null ? code : '$code · ${creditsShortLabel(credits)}';

/// Un curso del récord, tal como llegó del portal.
///
/// El código y el nombre se muestran sin tocarlos y sin cruzarlos con la malla
/// vigente: los cursos de mallas anteriores conservan los suyos (RF-REC-3).
///
/// Quién es el ciclo más reciente lo decide la pantalla, no la fila: por eso
/// [isMostRecentPeriod] entra como parámetro.
class RecordCourseRow extends StatelessWidget {
  const RecordCourseRow({
    super.key,
    required this.course,
    required this.isMostRecentPeriod,
  });

  final RecordCourse course;
  final bool isMostRecentPeriod;

  /// Chip neutro del ciclo en curso: el curso todavía no tiene nota.
  static const String inProgressLabel = 'En curso';

  /// Chip neutro de un ciclo viejo que se quedó sin nota y sin marca.
  static const String noGradeLabel = '—';

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.brightnessOf(context);
    final chip = recordChipFor(
      grade: course.grade,
      gradeRaw: course.gradeRaw,
      isMostRecentPeriod: isMostRecentPeriod,
    );
    final colors = recordChipColors(chip.tone, brightness);
    final intento = attemptLabel(course.attempt);
    final observation = course.observation;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wrap y no Row: con un nombre largo, la etiqueta "N.ª vez"
                // baja a la línea siguiente en vez de desbordar.
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      course.name,
                      style: TextStyle(
                        color: MaterialTheme.textPrimary(brightness),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (intento != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: MaterialTheme.tagBg(brightness),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          intento,
                          style: TextStyle(
                            color: MaterialTheme.labelColor(brightness),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  courseSubtitle(code: course.code, credits: course.credits),
                  style: TextStyle(
                    color: MaterialTheme.textMuted(brightness),
                    fontSize: 12,
                  ),
                ),
                if (observation != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      observation,
                      style: TextStyle(
                        color: MaterialTheme.textMuted(brightness),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            constraints: const BoxConstraints(minWidth: 40),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              chip.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.foreground,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

Detalles que no son libres:
- `final observation = course.observation;` antes del `build` del árbol **hace falta**: `observation` es un campo público de otra clase, así que Dart no lo promueve y `if (course.observation != null) … Text(course.observation)` no compilaría sin un `!`. Con la variable local, la promoción sí ocurre. Lo mismo pasa con `intento`, que además evita llamar dos veces a `attemptLabel`.
- La observación va en `fontSize: 11` y el subtítulo en `12`: ese orden es lo que prueba el aserto de "texto pequeño" del Paso 1. Si los igualas, la prueba falla.
- El archivo empieza con un comentario `//` (no `///`) y por eso **no** lleva `library;`: es el estilo de `lib/components/skeleton.dart:1-7`. El `library;` solo hace falta cuando el comentario de cabecera es `///`, como en `record_format.dart` de la tarea 3; si no, `flutter_lints` marca `dangling_library_doc_comments`.
- `recordChipFor` usa las constantes `RecordCourseRow.inProgressLabel` y `RecordCourseRow.noGradeLabel` y no los literales sueltos: así el texto vive en un solo sitio y la prueba del Paso 1 puede anclarse a las constantes. Que la función de nivel superior nombre una clase declarada más abajo en el mismo archivo es válido en Dart.
- El `switch` de `recordChipColors` es una sentencia con `return` por caso y sin `default`, como `CourseStatusX.color` (`malla_models.dart:18-29`). Sin `default`, si alguien agrega un tono nuevo al enum el analizador avisa en vez de dejarlo caer en un color cualquiera.
- `Theme.brightnessOf(context)` y no `Theme.of(context).brightness`: es lo que usa la página hermana (`mis_notas_page.dart:16`) y no reconstruye la fila por cambios de tema que no sean el brillo.
- El separador del subtítulo es ` · ` (U+00B7 con un espacio a cada lado), tal como está en la maqueta aprobada y en la prueba.
- Ni aquí ni en `courseSubtitle` hay un `?? 0`: sin créditos, el subtítulo es solo el código; sin nota, el chip es neutro. Nunca se pinta un 0 que el portal no mandó.

- [ ] **Paso 4: Correr la prueba y ver que pasa**

```bash
cd . && $FLUTTER test test/HU34_jeff/record_course_row_test.dart
```

Esperado: PASS, con los 23 casos de los cuatro grupos:

```
00:00 +23: All tests passed!
```

- [ ] **Paso 5: Análisis estático**

```bash
cd . && $FLUTTER analyze lib/pages/academic_record/record_course_row.dart test/HU34_jeff/record_course_row_test.dart
```

Esperado: `No issues found! (ran in …)`. Si sale algún issue, corrígelo en esos dos archivos y repite los Pasos 4 y 5.

Después, el proyecto entero, para comprobar que el número de issues preexistentes que anotaste en la tarea 1 no subió:

```bash
cd . && $FLUTTER analyze 2>&1 | grep -E "issues? found|record_course_row"
```

Esperado: la misma línea `N issues found. (ran in …)` (o `No issues found!`) de la tarea 1, y ninguna línea que nombre `record_course_row`. Si esta tarea corre en otra sesión no tienes el reporte de la tarea 1: la línea base está en `$TMP/plan-fe/analyze-baseline.txt`; léela con `cat` y compara sin el `(ran in …)`. Si el número subió, el issue nuevo es de esta tarea: corrígelo.

- [ ] **Paso final: Commit**

Revisa primero que el árbol no tenga cambios ajenos:

```bash
cd . && git status --short --untracked-files=all
```

Esperado, en cualquier orden, exactamente estas dos líneas:

```
?? lib/pages/academic_record/record_course_row.dart
?? test/HU34_jeff/record_course_row_test.dart
```

Si aparece otro archivo, no lo agregues ni lo toques: puede ser de otra sesión trabajando en el mismo árbol.

```bash
cd . && git add lib/pages/academic_record/record_course_row.dart test/HU34_jeff/record_course_row_test.dart && git diff --cached --stat
```

Esperado: exactamente esos 2 archivos y `2 files changed`.

```bash
cd . && git commit -m "feat(academic-record): fila de curso con chip de nota y etiqueta de vez"
```

El autor ya está configurado en git. El mensaje no lleva trailer `Co-Authored-By`. No hagas push.

### Tarea 6: Pantalla "Mi récord académico": ruta, estados y encabezado

**Archivos:**
- Crear: `lib/pages/academic_record/academic_record_controller.dart`
- Crear: `lib/pages/academic_record/academic_record_binding.dart`
- Crear: `lib/pages/academic_record/academic_record_page.dart`
- Modificar: `lib/main.dart:29` (dos imports nuevos delante de esa línea) y `lib/main.dart:206-210` (el `GetPage` de `/mis-notas`, inmediatamente después del cual entra el nuevo)
- Modificar: `docs/specs/feature-index.md:24` (fila 17 nueva justo después de la fila 16, que hoy es la última de la tabla y la última línea antes del `## Workflow`)
- Test: `test/HU34_jeff/record_page_test.dart` (crear; las tareas 7 y 8 le agregan grupos)
- **No** se toca la spec: `specs/features/academic-record/academic-record.spec.md:85` (RF-REC-2) y `:119` (RF-REC-4) ya dicen literalmente `` `[@test] ../../../test/HU34_jeff/record_page_test.dart` ``, y los `[@test]` que insertan las tareas 1 y 2 van después de las líneas 173 y 135, así que esas dos anclas no se corren.

**Sobre los números de línea de `lib/main.dart`.** En `HEAD` el import de `mis_notas_binding.dart` es la L28 y el `GetPage` de `/mis-notas` va de la L202 a la L206 (con su comentario en la L201). La tarea 2 mete **cuatro** líneas: una en el bloque de imports (`import '/services/academic_record_service.dart';` después de la L13) y tres en `main()` (dos de comentario más el `Get.put<AcademicRecordService>(…)` después de la L65). Por eso, cuando empieza esta tarea, el import de `mis_notas_binding.dart` está en la L29 (solo baja 1: las otras tres van más abajo) y el `GetPage` de `/mis-notas` en las L206-210, con su comentario en la L205. Ninguna otra tarea (1, 3, 4, 5) toca `lib/main.dart`. Igual, **las anclas literales del Paso 3 son lo que manda**: si los números no cuadran, se busca el texto.

**Precondición:** las tareas 1 a 5 ya tienen su commit. Comprobarlo antes de empezar:

```bash
cd . && ls lib/models/academic_record_model.dart lib/services/academic_record_service.dart lib/pages/academic_record/record_format.dart lib/pages/academic_record/record_position_badge.dart test/HU34_jeff/ && git status --short
```

Los cuatro archivos deben existir, `test/HU34_jeff/` debe tener los tests de las tareas 1 a 5 y el árbol debe estar limpio. Todo se hace en `.`, rama `feat/record-academico-fe`, editando con Edit sobre las anclas literales. Nada de `cp`, `mv` ni `git stash`.

**Interfaces:**
- Consume (tarea 1) — `lib/models/academic_record_model.dart`: `class AcademicRecord { final DateTime? syncedAt; final AcademicSnapshot? snapshot; final List<AcademicPeriodSummary> periodSummaries; final List<RecordPeriod> coursesByPeriod; bool get hasRecord; factory AcademicRecord.fromJson(Map<String, dynamic> json); }` y `class AcademicSnapshot { final double? ppa; final String? relativePosition; final double? creditsAccumulated; final double? creditsRequired; final AcademicTotals approved; final AcademicTotals convalidated; }`. La pantalla solo nombra los tipos `AcademicRecord` y `AcademicSnapshot`, y lee `hasRecord`, `syncedAt`, `snapshot`, `ppa`, `relativePosition`, `creditsAccumulated` y `creditsRequired`.
- Consume (tarea 2) — `lib/services/academic_record_service.dart`: `class AcademicRecordService extends GetxService { AcademicRecordService({ApiClient? apiClient}); static AcademicRecordService get to; AcademicRecord? get record; bool get isLoading; bool get hasError; Future<void> load({bool force = false}); Future<void> reload(); void clear(); Future<void> deleteRecord(); }`. `load()` **nunca lanza**: un fallo deja `record` en `null` y `hasError` en `true`, y aplica `.timeout(AcademicRecordService.loadTimeout)` (15 s) sobre el `GET`.
- Consume (tarea 3) — `lib/pages/academic_record/record_format.dart`: `double? creditsProgress(double? accumulated, double? requiredCredits)`, `String formatDecimal(double value)`, `String? formatRelativePosition(String? raw)`, `String progressPercentLabel(double progress)`. No se usa `creditsOfRequiredLabel`, que es solo de la tarjeta del Perfil.
- Consume (tarea 4) — `lib/pages/academic_record/record_position_badge.dart`: `class RecordPositionBadge extends StatelessWidget { const RecordPositionBadge({super.key, required this.label}); final String label; }`; pinta un `Text(label)`, así que `find.text('Tercio superior')` lo encuentra.
- Consume (repo):
  - `lib/components/error_retry.dart:13-22`: `class ErrorRetry extends StatelessWidget { const ErrorRetry({super.key, required this.onRetry, this.title = 'No se pudo cargar', this.message = 'Hubo un problema al cargar esta información. Revisa tu conexión e inténtalo de nuevo.', this.icon = Icons.wifi_off_rounded, this.compact = false}); }`, con `final VoidCallback onRetry;` y un `ElevatedButton.icon` cuyo `label` es `Text('Reintentar')` (`:70-76`).
  - `lib/components/skeleton.dart:15-16`: `class SkeletonPulse extends StatelessWidget { const SkeletonPulse({super.key, required this.child}); }` (en realidad `StatefulWidget`, con `AnimationController…repeat(reverse: true)`: **nunca** `pumpAndSettle` mientras esté montado) y `:50-56`: `class SkeletonBox extends StatelessWidget { const SkeletonBox({super.key, this.width, this.height = 14, this.borderRadius = 8}); }`.
  - `lib/configs/themes.dart`: `static const Color primaryColor` (`:10`), y `pageBg` (`:55`), `cardBg` (`:59`), `textPrimary` (`:63`), `textSecondary` (`:67`), `textMuted` (`:71`), `borderColor` (`:79`), `progressBg` (`:91`) y `labelColor` (`:135`), todos `static Color f(Brightness b)`.
  - `lib/main.dart:89-91`: `class MyApp extends StatelessWidget { const MyApp({super.key, required this.initialRoute}); final String initialRoute; }`.
  - `lib/services/api_client.dart:42`: `ApiClient({String? configuredBaseUrl})`; `:68-73`: `Future<Map<String, dynamic>> getJson(String path, {String? token, Map<String, String?> query = const {}, bool suppressSessionExpiry = false})`; `:99-102`: `Future<Map<String, dynamic>> deleteJson(String path, {String? token})`.
  - `lib/services/auth_service.dart:17-18`: `class AuthService extends GetxService { static AuthService get to => Get.find(); … }`; `:59-60`: `UserModel? get currentUser` y `Rx<UserModel?> get currentUserRx`; `:179`: `Future<void> refreshCurrentUser()`.
  - `lib/models/user_model.dart:29-45`: `UserModel({required String code, required String firstName, required String lastName, String? avatarUrl, String? fullName, required String email, required String role, String? teacherLabel, int? careerId, int? especialidadPrincipal, List<int>? especialidadesInteres, required String currentCycle, required bool setupComplete, CourseProgress? courseProgress})`.
  - Precedentes que se copian: el `AppBar` de `lib/pages/networking/networking_page.dart:25-32`; el `CustomPainter` `_AnilloAsistencia` de `lib/pages/descripcion_cursos/descrip_cursos.dart:521-563` (incluido `shouldRepaint(_AnilloAsistencia old)`, que estrecha el parámetro porque el de `CustomPainter` es `covariant`); `Get.toNamed<dynamic>('/portal-sync')` de `lib/pages/perfil/perfil.dart:653`.
- Produce — `lib/pages/academic_record/academic_record_controller.dart`:
  ```dart
  class AcademicRecordController extends GetxController {
    AcademicRecordController({AcademicRecordService? service, DateTime Function()? now});
    AcademicRecord? get record;
    bool get isLoading;
    bool get hasError;                       // true también para un docente
    String? get syncedLabel;                 // null si record o syncedAt son null
    Future<void> retry();                    // service.load(force: true)
    @override void onReady();                // service.load()
    static String syncedAgoLabel(DateTime syncedAt, DateTime now);
    // 'Sincronizado hoy' | 'Sincronizado hace 1 día' | 'Sincronizado hace N días'
  }
  ```
- Produce — `lib/pages/academic_record/academic_record_binding.dart`: `class AcademicRecordBinding extends Bindings { @override void dependencies() { Get.lazyPut<AcademicRecordController>(() => AcademicRecordController()); } }`.
- Produce — `lib/pages/academic_record/academic_record_page.dart`:
  ```dart
  class AcademicRecordPage extends GetView<AcademicRecordController> {
    const AcademicRecordPage({super.key});
    static const String title = 'Mi récord académico';
    static const String emptyTitle = 'Aún no tienes tu récord';
    static const String emptyBody = 'Sincroniza con miUlima una vez y verás aquí tus notas de toda la carrera, tu PPA y tus créditos.';
    static const String syncButtonLabel = 'Sincronizar con el portal';
    static const String loadErrorTitle = 'No se pudo cargar tu récord';
    static const Key skeletonKey = Key('record-page-skeleton');
    static const Key ringKey = Key('record-credits-ring');
    static const Key successViewKey = Key('record-success-view');
  }
  ```
  Widget privado `_RecordSuccessView({required this.controller, required this.record})`: `SingleChildScrollView(key: successViewKey)` con un `Column(crossAxisAlignment: CrossAxisAlignment.stretch)` cuyos children son `[_RecordHeader(snapshot: record.snapshot), SizedBox(height: 10), la línea syncedLabel, SizedBox(height: 16)]`. La tarea 7 inserta ahí los chips de ciclo y la tarjeta de cursos; la tarea 8 agrega el botón de borrar al final de esa lista.
- Produce — ruta `'/mi-record'` en `lib/main.dart`.
- Produce — arnés de `test/HU34_jeff/record_page_test.dart` que reutilizan las tareas 7 y 8: `UserModel _student();`, `class _FakeAuthService extends AuthService` (campo `userRx`), `class _FakeRecordApi extends ApiClient { _FakeRecordApi(this.getResponses); final List<Object> getResponses; Object? deleteError; int getCalls; int deleteCalls; String? lastDeletePath; }`, `Map<String, dynamic> _syncedJson({Object? creditsRequired = 240});`, `Map<String, dynamic> _neverSyncedJson();`, `DateTime _now() => DateTime.utc(2026, 9, 21, 16);`, `Widget _app();`, `Future<_FakeRecordApi> _mountPage(WidgetTester tester, {required List<Object> getResponses, UserModel? user});` (sin `user` monta al alumno `_student()`).

**Datos de prueba, todos inventados (repo PÚBLICO).** Alumna sintética `20230001`. La foto usa `TERCIO SUPERIOR` y 197 de 240 créditos, y el resumen del ciclo 2025-2 usa `MEDIO SUPERIOR`, para que un cruce de campos haga fallar la prueba. 197/240 = 0,820833, que redondeado da el mismo `'82%'` que pide el esqueleto y además ejercita el redondeo. El PPA 14.62, el promedio 17.3, los cursos `CURSO …`, los códigos `1000xx` y las secciones `80x` no aparecen en ningún fixture real: se comprobó con `grep` contra `test/HU31_jeff/fixtures/` y `spike-portal/`, que es de donde NO puede salir ningún valor.

---

- [ ] **Paso 1: Escribir la prueba que falla**

Crear `test/HU34_jeff/record_page_test.dart` con este contenido completo (el directorio `test/HU34_jeff/` ya existe desde la tarea 1):

```dart
// test/HU34_jeff/record_page_test.dart
//
// WIDGET + UNITARIA — HU34 (récord académico): la pantalla "Mi récord
// académico" (RF-REC-2 y RF-REC-4): ruta, estados y encabezado.
// Pantalla: lib/pages/academic_record/academic_record_page.dart
//
// Todos los datos son inventados; el repo es público. Ningún valor sale del
// récord real: ni la ubicación relativa ni los créditos requeridos.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/error_retry.dart';
import 'package:ulima_plus/components/skeleton.dart';
import 'package:ulima_plus/main.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/academic_record/academic_record_controller.dart';
import 'package:ulima_plus/pages/academic_record/academic_record_page.dart';
import 'package:ulima_plus/services/academic_record_service.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/auth_service.dart';

UserModel _student() => UserModel(
      code: '20230001',
      firstName: 'Alumna',
      lastName: 'De Prueba',
      email: 'test@aloe.ulima.edu.pe',
      role: 'student',
      currentCycle: '2026-1',
      setupComplete: true,
    );

class _FakeAuthService extends AuthService {
  _FakeAuthService(UserModel? user) : userRx = Rx<UserModel?>(user);

  final Rx<UserModel?> userRx;

  @override
  UserModel? get currentUser => userRx.value;

  @override
  Rx<UserModel?> get currentUserRx => userRx;

  @override
  Future<void> refreshCurrentUser() async {}
}

/// Doble del cliente HTTP. `getResponses` se consume en orden y el último se
/// repite: un `Map` se devuelve, un `Completer` se espera (deja la pantalla
/// cargando) y cualquier otra cosa se lanza.
class _FakeRecordApi extends ApiClient {
  _FakeRecordApi(this.getResponses) : super(configuredBaseUrl: 'http://test');

  final List<Object> getResponses;
  Object? deleteError;
  int getCalls = 0;
  int deleteCalls = 0;
  String? lastDeletePath;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    String? token,
    Map<String, String?> query = const {},
    bool suppressSessionExpiry = false,
  }) async {
    final r = getResponses[
        getCalls < getResponses.length ? getCalls : getResponses.length - 1];
    getCalls++;
    if (r is Completer<Map<String, dynamic>>) return r.future;
    if (r is Map<String, dynamic>) return r;
    throw r;
  }

  @override
  Future<Map<String, dynamic>> deleteJson(String path, {String? token}) async {
    deleteCalls++;
    lastDeletePath = path;
    if (deleteError != null) throw deleteError!;
    return <String, dynamic>{'ok': true};
  }
}

/// Récord inventado de punta a punta. Ninguna cifra ni etiqueta de aquí sale
/// de un récord real: si hay que cambiarlas, se cambian por otras inventadas,
/// nunca por las que devuelve el portal.
Map<String, dynamic> _syncedJson({Object? creditsRequired = 240}) =>
    <String, dynamic>{
      'syncedAt': '2026-09-18T15:00:00Z',
      'snapshot': <String, dynamic>{
        'ppa': 14.62,
        'relativePosition': 'TERCIO SUPERIOR',
        'creditsAccumulated': 197,
        'creditsRequired': creditsRequired,
        'approved': <String, dynamic>{'courses': 58, 'credits': 197},
        'convalidated': <String, dynamic>{'courses': 0, 'credits': 0},
      },
      'periods': <dynamic>[
        <String, dynamic>{
          'periodCode': '2025-2',
          'average': 17.3,
          'relativePosition': 'MEDIO SUPERIOR',
          'level': 8,
          'convalidated': <String, dynamic>{'courses': 0, 'credits': 0},
          'enrolled': <String, dynamic>{'courses': 2, 'credits': 3.5},
          'approved': <String, dynamic>{'courses': 2, 'credits': 3.5},
          'failed': <String, dynamic>{'courses': 0, 'credits': 0},
        },
        <String, dynamic>{
          'periodCode': '2025-1',
          'average': null,
          'relativePosition': null,
          'level': null,
          'convalidated': <String, dynamic>{'courses': null, 'credits': null},
          'enrolled': <String, dynamic>{'courses': null, 'credits': null},
          'approved': <String, dynamic>{'courses': null, 'credits': null},
          'failed': <String, dynamic>{'courses': null, 'credits': null},
        },
      ],
      'record': <dynamic>[
        <String, dynamic>{
          'periodCode': '2026-1',
          'courses': <dynamic>[
            <String, dynamic>{
              'code': '100001',
              'name': 'CURSO EN CURSO',
              'attempt': 1,
              'credits': 3,
              'grade': null,
              'gradeRaw': null,
              'section': '801',
              'observation': null,
            },
          ],
        },
        <String, dynamic>{
          'periodCode': '2025-2',
          'courses': <dynamic>[
            <String, dynamic>{
              'code': '100002',
              'name': 'CURSO APROBADO',
              'attempt': 2,
              'credits': 1.5,
              'grade': 17,
              'gradeRaw': '17',
              'section': '802',
              'observation': null,
            },
            <String, dynamic>{
              'code': '100003',
              'name': 'CURSO CONVALIDADO',
              'attempt': 1,
              'credits': 2,
              'grade': null,
              'gradeRaw': 'CONV',
              'section': null,
              'observation': 'Convalidado por examen',
            },
          ],
        },
        <String, dynamic>{
          'periodCode': '2025-1',
          'courses': <dynamic>[
            <String, dynamic>{
              'code': '100004',
              'name': 'CURSO SIN NOTA ANTIGUO',
              'attempt': 1,
              'credits': 4,
              'grade': null,
              'gradeRaw': null,
              'section': null,
              'observation': null,
            },
            <String, dynamic>{
              'code': '100005',
              'name': 'CURSO JALADO',
              'attempt': 1,
              'credits': 4,
              'grade': 8,
              'gradeRaw': '08',
              'section': '803',
              'observation': null,
            },
          ],
        },
      ],
    };

Map<String, dynamic> _neverSyncedJson() => <String, dynamic>{
      'syncedAt': null,
      'snapshot': null,
      'periods': <dynamic>[],
      'record': <dynamic>[],
    };

/// Reloj fijo: tres días de calendario después del `syncedAt` de `_syncedJson`.
DateTime _now() => DateTime.utc(2026, 9, 21, 16);

Widget _app() => GetMaterialApp(
      initialRoute: '/mi-record',
      getPages: [
        GetPage(name: '/mi-record', page: () => const AcademicRecordPage()),
        GetPage(
          name: '/portal-sync',
          page: () => const Scaffold(body: Text('PORTAL SYNC')),
        ),
      ],
    );

/// Monta la pantalla con su tabla de rutas propia. Al final del frame de
/// `pumpWidget` GetX dispara el `onReady` del controller → `load()`; el primer
/// `pump` pinta ya la respuesta resuelta y el segundo deja el árbol estable.
Future<_FakeRecordApi> _mountPage(
  WidgetTester tester, {
  required List<Object> getResponses,
  UserModel? user,
}) async {
  final api = _FakeRecordApi(getResponses);
  Get.put<AuthService>(_FakeAuthService(user ?? _student()));
  Get.put<AcademicRecordService>(AcademicRecordService(apiClient: api));
  Get.put<AcademicRecordController>(
    AcademicRecordController(service: AcademicRecordService.to, now: _now),
  );
  await tester.pumpWidget(_app());
  await tester.pump();
  await tester.pump();
  return api;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  group('WIDGET · AcademicRecordPage (RF-REC-2, RF-REC-4)', () {
    testWidgets('la ruta /mi-record vive en main.dart con su binding',
        (tester) async {
      // Monta la app REAL: lo que hay que blindar es la cadena entre el
      // GetPage de main.dart, el AcademicRecordBinding y la pantalla. Con una
      // tabla de rutas escrita en el test, la ruta podría faltar y nadie se
      // enteraría hasta ejecutar la app.
      final api = _FakeRecordApi(<Object>[_syncedJson()]);
      Get.put<AuthService>(_FakeAuthService(_student()));
      Get.put<AcademicRecordService>(AcademicRecordService(apiClient: api));

      await tester.pumpWidget(const MyApp(initialRoute: '/mi-record'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(AcademicRecordPage), findsOneWidget);
      expect(Get.currentRoute, equals('/mi-record'));
      expect(find.text('Mi récord académico'), findsOneWidget);
      expect(api.getCalls, 1);
    });

    testWidgets('mientras carga muestra el skeleton, no el error',
        (tester) async {
      // Respuesta que nunca completa: la pantalla queda cargando. Sin
      // pumpAndSettle: SkeletonPulse anima sin fin y colgaría el test.
      final pendiente = Completer<Map<String, dynamic>>();
      await _mountPage(tester, getResponses: <Object>[pendiente]);

      expect(find.byKey(AcademicRecordPage.skeletonKey), findsOneWidget);
      expect(find.byType(SkeletonPulse), findsOneWidget);
      expect(find.byType(ErrorRetry), findsNothing);
      expect(find.byKey(AcademicRecordPage.successViewKey), findsNothing);

      // Cerrar la carga antes de terminar. `AcademicRecordService.load()`
      // aplica `.timeout(loadTimeout)`, y ese Timer de 15 s seguiría vivo al
      // desmontarse el árbol: el binding haría fallar el test con "A Timer is
      // still pending even after the widget tree was disposed."
      pendiente.complete(_syncedJson());
      await tester.pump();
      await tester.pump();
      expect(find.byKey(AcademicRecordPage.successViewKey), findsOneWidget);
    });

    testWidgets('si la carga falla, ErrorRetry y "Reintentar" vuelve a pedir',
        (tester) async {
      final api = await _mountPage(
        tester,
        getResponses: <Object>[Exception('socket'), _syncedJson()],
      );

      expect(find.byType(ErrorRetry), findsOneWidget);
      expect(find.text('No se pudo cargar tu récord'), findsOneWidget);

      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      await tester.pump();

      expect(api.getCalls, 2);
      expect(find.byType(ErrorRetry), findsNothing);
      expect(find.text('14.62'), findsOneWidget);
    });

    testWidgets('RF-REC-4: sin sincronizar, estado vacío y botón a /portal-sync',
        (tester) async {
      await _mountPage(tester, getResponses: <Object>[_neverSyncedJson()]);

      expect(find.text('Aún no tienes tu récord'), findsOneWidget);
      expect(
        find.textContaining('tus notas de toda la carrera, tu PPA y tus créditos'),
        findsOneWidget,
      );
      expect(find.text('Sincronizar con el portal'), findsOneWidget);
      expect(find.byKey(AcademicRecordPage.ringKey), findsNothing);
      expect(find.byKey(AcademicRecordPage.successViewKey), findsNothing);

      await tester.tap(find.text('Sincronizar con el portal'));
      await tester.pumpAndSettle();

      expect(Get.currentRoute, equals('/portal-sync'));
    });

    testWidgets('el encabezado trae anillo, porcentaje, PPA y ubicación',
        (tester) async {
      await _mountPage(tester, getResponses: <Object>[_syncedJson()]);

      expect(find.byKey(AcademicRecordPage.successViewKey), findsOneWidget);
      expect(find.byKey(AcademicRecordPage.ringKey), findsOneWidget);
      expect(find.text('82%'), findsOneWidget); // 197 de 240
      expect(find.text('14.62'), findsOneWidget);
      expect(find.text('Tercio superior'), findsOneWidget);
    });

    testWidgets('sin créditos requeridos no hay anillo ni porcentaje',
        (tester) async {
      // RF-REC-1/RF-REC-2: un dato que falta se omite; nunca se pinta un 0.
      await _mountPage(
        tester,
        getResponses: <Object>[_syncedJson(creditsRequired: null)],
      );

      expect(find.byKey(AcademicRecordPage.successViewKey), findsOneWidget);
      expect(find.byKey(AcademicRecordPage.ringKey), findsNothing);
      expect(find.textContaining('%'), findsNothing);
      expect(find.text('14.62'), findsOneWidget);
    });

    testWidgets('la línea de sincronización cuenta días de Lima',
        (tester) async {
      await _mountPage(tester, getResponses: <Object>[_syncedJson()]);

      expect(find.text('Sincronizado hace 3 días'), findsOneWidget);
    });

    testWidgets('la pantalla nunca se llama "notas oficiales"',
        (tester) async {
      await _mountPage(tester, getResponses: <Object>[_syncedJson()]);

      expect(find.text('Mi récord académico'), findsOneWidget);
      expect(find.textContaining('notas oficiales'), findsNothing);
      expect(find.textContaining('Notas oficiales'), findsNothing);
    });

    testWidgets('un docente no ve el récord ni se queda cargando',
        (tester) async {
      // "Qué NO entra: mostrar el récord a otros roles" (spec:195). El
      // servicio no dispara el GET para un docente, así que 'record' queda
      // null: sin la guarda del controller, la pantalla se quedaría en el
      // skeleton para siempre y sin salida.
      final api = await _mountPage(
        tester,
        getResponses: <Object>[_syncedJson()],
        user: UserModel(
          code: 'docente.test',
          firstName: 'Docente',
          lastName: 'De Prueba',
          email: 'docente.test@ulima.edu.pe',
          role: 'teacher',
          currentCycle: '2026-1',
          setupComplete: true,
        ),
      );

      expect(api.getCalls, 0);
      expect(find.byKey(AcademicRecordPage.skeletonKey), findsNothing);
      expect(find.byKey(AcademicRecordPage.successViewKey), findsNothing);
      expect(find.byType(ErrorRetry), findsOneWidget);
    });
  });

  group('UNITARIA · syncedAgoLabel en hora de Lima (RF-REC-2)', () {
    test('tres días de calendario', () {
      expect(
        AcademicRecordController.syncedAgoLabel(
          DateTime.utc(2026, 9, 18, 15),
          DateTime.utc(2026, 9, 21, 16),
        ),
        'Sincronizado hace 3 días',
      );
    });

    test('el mismo día en Lima', () {
      expect(
        AcademicRecordController.syncedAgoLabel(
          DateTime.utc(2026, 9, 18, 15),
          DateTime.utc(2026, 9, 18, 23),
        ),
        'Sincronizado hoy',
      );
    });

    test('una hora antes puede ser "hace 1 día"', () {
      // En Lima son el 17 a las 23:30 y el 18 a las 00:30: son fechas de
      // calendario distintas aunque haya pasado una sola hora.
      expect(
        AcademicRecordController.syncedAgoLabel(
          DateTime.utc(2026, 9, 18, 4, 30),
          DateTime.utc(2026, 9, 18, 5, 30),
        ),
        'Sincronizado hace 1 día',
      );
    });

    test('en UTC ya es otro día, en Lima todavía no', () {
      expect(
        AcademicRecordController.syncedAgoLabel(
          DateTime.utc(2026, 9, 18, 15),
          DateTime.utc(2026, 9, 19, 4),
        ),
        'Sincronizado hoy',
      );
    });

    test('un syncedAt futuro no produce días negativos', () {
      expect(
        AcademicRecordController.syncedAgoLabel(
          DateTime.utc(2026, 9, 22, 15),
          DateTime.utc(2026, 9, 21, 16),
        ),
        'Sincronizado hoy',
      );
    });
  });
}
```

- [ ] **Paso 2: Correr la prueba y ver que falla**

```
cd . && $FLUTTER test test/HU34_jeff/record_page_test.dart
```

Esperado: FALLA al compilar, porque faltan los dos archivos que el test importa (`record_format.dart` y `record_position_badge.dart` de las tareas 3 y 4 ya existen; el binding no lo importa el test, lo estrena `main.dart` en el Paso 3):

```
test/HU34_jeff/record_page_test.dart:10:8: Error: Error when reading 'lib/pages/academic_record/academic_record_controller.dart': No such file or directory
import 'package:ulima_plus/pages/academic_record/academic_record_controller.dart';
       ^
test/HU34_jeff/record_page_test.dart:11:8: Error: Error when reading 'lib/pages/academic_record/academic_record_page.dart': No such file or directory
import 'package:ulima_plus/pages/academic_record/academic_record_page.dart';
       ^
```

Detrás de esas dos líneas salen además un `Error: Undefined name 'AcademicRecordPage'.` o `'AcademicRecordController'.` por cada uso (constantes, `find.byType`, `syncedAgoLabel`, `const AcademicRecordPage()`), y termina en:

```
Failed to load "./test/HU34_jeff/record_page_test.dart": Compilation failed
```

Si en vez de eso hay errores sobre `lib/pages/academic_record/record_format.dart`, `record_position_badge.dart` o `lib/services/academic_record_service.dart`, alguna tarea anterior no está hecha: detente.

- [ ] **Paso 3: Implementación mínima**

**3.1. Crear `lib/pages/academic_record/academic_record_controller.dart`** (completo):

```dart
// lib/pages/academic_record/academic_record_controller.dart
// Controller de /mi-record (RF-REC-2).

import 'package:get/get.dart';

import '../../models/academic_record_model.dart';
import '../../services/academic_record_service.dart';
import '../../services/auth_service.dart';

/// Vista de la pantalla sobre el estado único del récord.
///
/// No guarda una copia del récord: lo lee de [AcademicRecordService], que es el
/// mismo estado que pinta la tarjeta del Perfil (RF-REC-5). Así, al volver con
/// back después de borrar, la tarjeta no puede mostrar cifras viejas.
class AcademicRecordController extends GetxController {
  AcademicRecordController({
    AcademicRecordService? service,
    DateTime Function()? now,
  })  : _service = service ?? AcademicRecordService.to,
        _now = now ?? DateTime.now;

  final AcademicRecordService _service;
  final DateTime Function() _now;

  AcademicRecord? get record => _service.record;
  bool get isLoading => _service.isLoading;
  /// Un docente nunca tiene récord: el servicio no dispara el GET para él
  /// (RF-REC-1) y la pantalla se quedaría en el skeleton para siempre.
  /// `/mi-record` es una ruta con nombre y cualquiera puede llegar a ella
  /// ("Qué NO entra: mostrar el récord a otros roles").
  bool get hasError =>
      _service.hasError || (AuthService.to.currentUser?.isTeacher ?? false);

  String? get syncedLabel {
    final s = record?.syncedAt;
    return s == null ? null : syncedAgoLabel(s, _now());
  }

  Future<void> retry() => _service.load(force: true);

  @override
  void onReady() {
    // GetX agenda onReady después del primer frame, así que ningún Rx cambia
    // mientras build construye: el Obx de la tarjeta del Perfil, que queda
    // debajo en la pila, escucha estos mismos Rx.
    super.onReady();
    _service.load();
  }

  /// Pura y expuesta para probarla. Compara FECHAS de calendario en Lima
  /// (UTC-5, sin horario de verano), no bloques de 24 h: una sincronización a
  /// las 23:30 de ayer es "hace 1 día" aunque haya pasado una hora.
  static String syncedAgoLabel(DateTime syncedAt, DateTime now) {
    DateTime diaEnLima(DateTime t) {
      final lima = t.toUtc().subtract(const Duration(hours: 5));
      return DateTime.utc(lima.year, lima.month, lima.day);
    }

    final dias = diaEnLima(now).difference(diaEnLima(syncedAt)).inDays;
    if (dias <= 0) return 'Sincronizado hoy';
    if (dias == 1) return 'Sincronizado hace 1 día';
    return 'Sincronizado hace $dias días';
  }
}
```

**3.2. Crear `lib/pages/academic_record/academic_record_binding.dart`** (completo):

```dart
// lib/pages/academic_record/academic_record_binding.dart

import 'package:get/get.dart';

import 'academic_record_controller.dart';

/// Binding por ruta, como el resto de la app: nada de Get.put dentro de build.
class AcademicRecordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AcademicRecordController>(() => AcademicRecordController());
  }
}
```

**3.3. Crear `lib/pages/academic_record/academic_record_page.dart`** (completo):

```dart
// lib/pages/academic_record/academic_record_page.dart
// Pantalla "Mi récord académico" (RF-REC-2 y RF-REC-4).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/error_retry.dart';
import '../../components/skeleton.dart';
import '../../configs/themes.dart';
import '../../models/academic_record_model.dart';
import 'academic_record_controller.dart';
import 'record_format.dart';
import 'record_position_badge.dart';

/// El histórico del portal, con un estilo más entendible que su tabla de 12
/// columnas.
///
/// No confundir con "Notas oficiales" (`/mis-notas`), que son las que el
/// docente carga en ULima++ para el ciclo en curso.
class AcademicRecordPage extends GetView<AcademicRecordController> {
  const AcademicRecordPage({super.key});

  static const String title = 'Mi récord académico';
  static const String emptyTitle = 'Aún no tienes tu récord';
  static const String emptyBody =
      'Sincroniza con miUlima una vez y verás aquí tus notas de toda la '
      'carrera, tu PPA y tus créditos.';
  static const String syncButtonLabel = 'Sincronizar con el portal';
  static const String loadErrorTitle = 'No se pudo cargar tu récord';

  static const Key skeletonKey = Key('record-page-skeleton');
  static const Key ringKey = Key('record-credits-ring');
  static const Key successViewKey = Key('record-success-view');

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.brightnessOf(context);

    return Scaffold(
      backgroundColor: MaterialTheme.pageBg(brightness),
      appBar: AppBar(
        title: const Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
      ),
      body: Obx(() {
        final record = controller.record;
        // Sin récord en memoria: o falló la carga, o todavía está en camino.
        if (record == null) {
          if (controller.hasError) {
            return ErrorRetry(title: loadErrorTitle, onRetry: controller.retry);
          }
          return const _RecordSkeleton();
        }
        if (!record.hasRecord) return const _RecordEmptyState();
        return _RecordSuccessView(controller: controller, record: record);
      }),
    );
  }
}

/// Silueta de la pantalla mientras carga: encabezado, chips y tarjeta.
class _RecordSkeleton extends StatelessWidget {
  const _RecordSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkeletonPulse(
      key: AcademicRecordPage.skeletonKey,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 18, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: double.infinity, height: 110, borderRadius: 14),
            SizedBox(height: 16),
            Row(
              children: [
                SkeletonBox(width: 64, height: 30, borderRadius: 20),
                SizedBox(width: 8),
                SkeletonBox(width: 64, height: 30, borderRadius: 20),
                SizedBox(width: 8),
                SkeletonBox(width: 64, height: 30, borderRadius: 20),
              ],
            ),
            SizedBox(height: 16),
            SkeletonBox(width: double.infinity, height: 220, borderRadius: 14),
          ],
        ),
      ),
    );
  }
}

/// RF-REC-4: el alumno nunca sincronizó. No es un error ni una lista vacía.
class _RecordEmptyState extends StatelessWidget {
  const _RecordEmptyState();

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_edu_outlined,
              size: 48,
              color: MaterialTheme.textMuted(b),
            ),
            const SizedBox(height: 12),
            Text(
              AcademicRecordPage.emptyTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MaterialTheme.textPrimary(b),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AcademicRecordPage.emptyBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MaterialTheme.textSecondary(b),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Get.toNamed<dynamic>('/portal-sync'),
              style: FilledButton.styleFrom(
                backgroundColor: MaterialTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(AcademicRecordPage.syncButtonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

/// El récord cargado. SingleChildScrollView y no ListView: así todos los hijos
/// existen en el árbol aunque queden fuera de pantalla.
class _RecordSuccessView extends StatelessWidget {
  const _RecordSuccessView({required this.controller, required this.record});

  final AcademicRecordController controller;
  final AcademicRecord record;

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    final synced = controller.syncedLabel;

    return SingleChildScrollView(
      key: AcademicRecordPage.successViewKey,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RecordHeader(snapshot: record.snapshot),
          const SizedBox(height: 10),
          if (synced != null)
            Text(
              synced,
              style: TextStyle(
                color: MaterialTheme.textMuted(b),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Anillo de créditos, PPA e insignia de ubicación relativa.
///
/// Cada pieza se omite si su dato falta: un récord sin créditos requeridos no
/// dibuja un anillo en 0 %, y uno sin PPA no muestra "0".
class _RecordHeader extends StatelessWidget {
  const _RecordHeader({required this.snapshot});

  final AcademicSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    final s = snapshot;
    final progress = creditsProgress(s?.creditsAccumulated, s?.creditsRequired);
    final ppa = s?.ppa;
    final posicion = formatRelativePosition(s?.relativePosition);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MaterialTheme.cardBg(b),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MaterialTheme.borderColor(b)),
      ),
      child: Row(
        children: [
          if (progress != null) ...[
            SizedBox(
              key: AcademicRecordPage.ringKey,
              width: 84,
              height: 84,
              child: CustomPaint(
                painter: _CreditsRingPainter(
                  progress: progress,
                  track: MaterialTheme.progressBg(b),
                  color: MaterialTheme.primaryColor,
                ),
                child: Center(
                  child: Text(
                    progressPercentLabel(progress),
                    style: TextStyle(
                      color: MaterialTheme.textPrimary(b),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ppa != null) ...[
                  Text(
                    'PPA',
                    style: TextStyle(
                      color: MaterialTheme.labelColor(b),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    formatDecimal(ppa),
                    style: TextStyle(
                      color: MaterialTheme.textPrimary(b),
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
                if (posicion != null) ...[
                  const SizedBox(height: 6),
                  RecordPositionBadge(label: posicion),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Anillo del avance de créditos, con la misma forma que `_AnilloAsistencia`
/// de descrip_cursos.dart: pista completa y un arco que arranca a las 12.
class _CreditsRingPainter extends CustomPainter {
  const _CreditsRingPainter({
    required this.progress,
    required this.track,
    required this.color,
  });

  final double progress;
  final Color track;
  final Color color;

  static const double _grosor = 8;
  static const double _arriba = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final rect =
        Rect.fromLTWH(0, 0, size.width, size.height).deflate(_grosor / 2);
    final trazo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _grosor
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(rect.center, rect.width / 2, trazo..color = track);

    final barrido = progress.clamp(0.0, 1.0) * 2 * math.pi;
    if (barrido > 0) {
      canvas.drawArc(rect, _arriba, barrido, false, trazo..color = color);
    }
  }

  @override
  bool shouldRepaint(_CreditsRingPainter old) =>
      old.progress != progress || old.track != track || old.color != color;
}
```

**3.4. Modificar `lib/main.dart`** — imports. Reemplazar esto (línea única, ancla exacta; con la tarea 2 hecha es la L29):

```dart
import 'pages/mis_notas/mis_notas_binding.dart';
```

por esto:

```dart
import 'pages/academic_record/academic_record_binding.dart';
import 'pages/academic_record/academic_record_page.dart';
import 'pages/mis_notas/mis_notas_binding.dart';
```

**3.5. Modificar `lib/main.dart`** — la ruta. Reemplazar esto (con la tarea 2 y el paso 3.4 hechos, son las L207-212; la indentación es de 8 espacios para el comentario y `GetPage(`, y 10 para lo de adentro):

```dart
        // Notas oficiales del alumno (solo lectura). Binding por ruta.
        GetPage(
          name: '/mis-notas',
          page: () => const MisNotasPage(),
          binding: MisNotasBinding(),
        ),
```

por esto:

```dart
        // Notas oficiales del alumno (solo lectura). Binding por ruta.
        GetPage(
          name: '/mis-notas',
          page: () => const MisNotasPage(),
          binding: MisNotasBinding(),
        ),
        // Récord académico del portal (RF-REC-2). Binding por ruta, como el
        // resto.
        GetPage(
          name: '/mi-record',
          page: () => const AcademicRecordPage(),
          binding: AcademicRecordBinding(),
        ),
```

El bloque nuevo queda en las L213-219 y `lib/main.dart` pasa de 240 a 249 líneas.

- [ ] **Paso 4: Correr la prueba y ver que pasa**

```
cd . && $FLUTTER test test/HU34_jeff/record_page_test.dart
```

Esperado: PASS (14 tests: 9 de widget y 5 unitarios), con la línea final `+14: All tests passed!`.

Si sale `A Timer is still pending even after the widget tree was disposed.`, es que el caso del skeleton no cerró su `Completer`: el `.timeout(loadTimeout)` de `AcademicRecordService` deja un Timer de 15 s vivo y el binding lo detecta al desmontar el árbol.

- [ ] **Paso 5: Analizar**

```bash
cd . && $FLUTTER analyze 2>&1 | grep -E "issues? found|academic_record|main.dart"
```

Esperado: la misma línea `N issues found. (ran in …)` (o `No issues found!`) de la tarea 1 —la línea base está en `$TMP/plan-fe/analyze-baseline.txt`, léela con `cat` y compara sin el `(ran in …)`— y, sobre `main.dart`, exactamente las mismas líneas que ya estaban en esa línea base. Si el número subió, el issue nuevo es de esta tarea: corrígelo. Dicho de otro modo: ningún issue nuevo en `lib/pages/academic_record/**`, `lib/main.dart` ni `test/HU34_jeff/record_page_test.dart`. En esos archivos no puede aparecer ningún `unused_import`, `unused_local_variable` ni `avoid_print`. Los issues preexistentes de otros archivos se reportan aparte y no se arreglan aquí (el `avoid_print` de `lib/main.dart`, que la tarea 2 corrió a la L83, no se mueve con esta tarea: las dos ediciones de aquí van después de él).

- [ ] **Paso 6: Documentación (`docs/specs/feature-index.md`)**

Reemplazar esto (la fila 16, hoy la L24 y la última de la tabla):

```
| 16 | Registro de alumno | `specs/features/registro/registro.spec.md` | HU-REG-01, HU-REG-02 | Alta de cuenta contra miUlima en dos pasos; el portal certifica la matrícula y entrega los datos | `lib/pages/registro/**`, `lib/services/registro_service.dart` | Implementada — **pendiente de verificar contra el portal real** |
```

por esto:

```
| 16 | Registro de alumno | `specs/features/registro/registro.spec.md` | HU-REG-01, HU-REG-02 | Alta de cuenta contra miUlima en dos pasos; el portal certifica la matrícula y entrega los datos | `lib/pages/registro/**`, `lib/services/registro_service.dart` | Implementada — **pendiente de verificar contra el portal real** |
| 17 | Récord académico | `specs/features/academic-record/academic-record.spec.md` | HU34 | RF-REC-1 a RF-REC-6: tarjeta en Perfil, pantalla /mi-record, borrado a pedido y consentimiento antes del portal | `lib/pages/academic_record/**`, `lib/services/academic_record_service.dart`, `lib/models/academic_record_model.dart`, `lib/components/portal_consent/**` | Aprobada el 2026-09-18 — en implementación |
```

- [ ] **Paso final: Commit**

Revisa primero que el árbol no tenga cambios ajenos:

```bash
cd . && git status --short --untracked-files=all
```

Esperado, en cualquier orden, exactamente estas seis líneas (`record_page_test.dart` sale como `??` porque lo crea esta tarea):

```
 M docs/specs/feature-index.md
 M lib/main.dart
?? lib/pages/academic_record/academic_record_binding.dart
?? lib/pages/academic_record/academic_record_controller.dart
?? lib/pages/academic_record/academic_record_page.dart
?? test/HU34_jeff/record_page_test.dart
```

Si aparece otro archivo, no lo agregues ni lo toques: puede ser de otra sesión.

```bash
cd . && git add lib/pages/academic_record/academic_record_controller.dart lib/pages/academic_record/academic_record_binding.dart lib/pages/academic_record/academic_record_page.dart lib/main.dart docs/specs/feature-index.md test/HU34_jeff/record_page_test.dart && git diff --cached --stat
```

Esperado: exactamente esos 6 archivos y `6 files changed`.

```bash
cd . && git commit -m "feat(academic-record): pantalla Mi récord académico con estados y encabezado"
```

El autor ya está configurado en git. El mensaje no lleva trailer `Co-Authored-By`. No hagas push.

### Tarea 7: Chips de ciclo y tarjeta de cursos del ciclo elegido

**Archivos:**
- Modificar: `lib/pages/academic_record/academic_record_controller.dart` (lo crea la tarea 6; aquí se le agregan **siete** miembros en un solo bloque, justo después de `retry()`)
- Modificar: `lib/pages/academic_record/academic_record_page.dart` (lo crea la tarea 6; aquí van **tres** ediciones: un import; dos constantes estáticas de `AcademicRecordPage`; y, en una sola edición, el `Obx` de chips y cursos como último hijo de `_RecordSuccessView` más las tres clases privadas nuevas `_PeriodChips`, `_PeriodChip` y `_PeriodCoursesCard`)
- Test: `test/HU34_jeff/record_page_test.dart` (lo crea la tarea 6; aquí se le agregan dos imports y dos grupos nuevos. Los grupos de la tarea 6 no se tocan, y su arnés —`_mountPage`, `_syncedJson`, `_neverSyncedJson`, `_FakeRecordApi`, `_FakeAuthService`, `_student`, `_now`, `_app`— se reutiliza tal cual)
- No se toca la spec: `specs/features/academic-record/academic-record.spec.md:85` (final de RF-REC-2) ya dice literalmente `` `[@test] ../../../test/HU34_jeff/record_page_test.dart` ``, y `:111` (final de RF-REC-3) ya enlaza `record_course_row_test.dart`. Los `[@test]` que insertan las tareas 1 y 2 van después de las líneas 173 y 135, las dos **después** de la 111, así que RF-REC-2 y RF-REC-3 siguen donde están.
- No se toca `lib/main.dart`: la ruta `/mi-record` con su binding ya quedó registrada en la tarea 6.
- No se toca `lib/configs/themes.dart` (está en la lista de intocables del plan): solo se leen sus estáticas.

**Precondición:** las tareas 1 a 6 ya tienen su commit y el árbol está limpio. Comprobarlo antes de editar nada, porque **las cuatro anclas de esta tarea las escribió la tarea 6** y los dos imports nuevos del test solo se pueden insertar si todavía no están. Los comandos van separados por `;` a propósito, para ver todos los resultados aunque uno falle:

```bash
cd . && \
  echo "--- arbol" ; git status --short --untracked-files=all ; \
  echo "--- tareas 1, 3 y 5" ; ls lib/models/academic_record_model.dart lib/pages/academic_record/record_format.dart lib/pages/academic_record/record_course_row.dart ; \
  echo "--- ancla 1 (controller)" ; grep -n "retry() => _service.load(force: true);" lib/pages/academic_record/academic_record_controller.dart ; \
  echo "--- ancla 2 (import de la pagina)" ; grep -n "^import 'record_format.dart';" lib/pages/academic_record/academic_record_page.dart ; \
  echo "--- ancla 3 (successViewKey)" ; grep -n "successViewKey = Key('record-success-view')" lib/pages/academic_record/academic_record_page.dart ; \
  echo "--- ancla 4 (SizedBox 16)" ; grep -n "const SizedBox(height: 16)," lib/pages/academic_record/academic_record_page.dart ; \
  echo "--- ancla 5 (grupo del test)" ; grep -n "UNITARIA · syncedAgoLabel en hora de Lima (RF-REC-2)" test/HU34_jeff/record_page_test.dart ; \
  echo "--- anclas de import del test" ; grep -n "^import 'package:ulima_plus/models/user_model.dart';\|^import 'package:ulima_plus/pages/academic_record/academic_record_page.dart';" test/HU34_jeff/record_page_test.dart ; \
  echo "--- NO deben existir todavia" ; grep -n "academic_record_model.dart\|record_course_row.dart" test/HU34_jeff/record_page_test.dart
```

Esperado:
- `git status --short` no imprime nada (árbol limpio);
- `ls` lista los tres archivos de las tareas 1, 3 y 5;
- las anclas 1, 2, 3 y 5 devuelven **una** línea cada una;
- el ancla 4 devuelve **una sola** línea, la de 10 espacios de indentación: la última de la lista `children` de `_RecordSuccessView`, que es la del ancla. Las dos `SizedBox(height: 16),` de `_RecordSkeleton` van **sin** `const` (están dentro de un `const SkeletonPulse(...)`, y ponérselo dispararía `unnecessary_const`), así que este grep no las ve; aun así, el bloque de seis líneas del Paso 3.4 desambigua solo;
- las dos anclas de import del test devuelven una línea cada una;
- el último `grep` **no** imprime nada: si imprimiera, la tarea 6 ya importó el modelo o la fila y habría que saltarse el Paso 1.1 o el 1.2 en vez de duplicar el import.

Si falta alguna, la tarea 6 no está hecha en este árbol: termínala antes de seguir. Todo se hace en `.`, rama `feat/record-academico-fe`, con `Edit` sobre las anclas literales de abajo. Nada de `cp`, `mv` ni `git stash`.

**Interfaces:**
- Consume (tarea 1, `lib/models/academic_record_model.dart`):
  - `class RecordPeriod { const RecordPeriod({required this.periodCode, required this.courses}); final String periodCode; final List<RecordCourse> courses; }`
  - `class AcademicPeriodSummary { const AcademicPeriodSummary({required this.periodCode, required this.average, required this.relativePosition, required this.level, required this.convalidated, required this.enrolled, required this.approved, required this.failed}); final String periodCode; final double? average; final String? relativePosition; final int? level; final AcademicTotals convalidated; final AcademicTotals enrolled; final AcademicTotals approved; final AcademicTotals failed; }` — los ocho parámetros son `required`, por eso el helper `resumen(...)` del Paso 1.
  - `class AcademicTotals { static const AcademicTotals none = AcademicTotals(courses: null, credits: null); }` — se usa solo para rellenar los cuatro grupos de `AcademicPeriodSummary` en la prueba unitaria.
  - `class AcademicRecord { final List<AcademicPeriodSummary> periodSummaries; /* json 'periods' */ final List<RecordPeriod> coursesByPeriod; /* json 'record', en el orden del backend */ }`
- Consume (tarea 3, `lib/pages/academic_record/record_format.dart`): `String formatDecimal(double value)` — `17.3` → `'17.3'`, `3.0` → `'3'`. Es la única función de formato que agrega esta tarea; `academic_record_page.dart` ya la importa desde la tarea 6.
- Consume (tarea 5, `lib/pages/academic_record/record_course_row.dart`):
  - `class RecordCourseRow extends StatelessWidget { const RecordCourseRow({super.key, required this.course, required this.isMostRecentPeriod}); final RecordCourse course; final bool isMostRecentPeriod; static const String inProgressLabel = 'En curso'; static const String noGradeLabel = '—'; }`
  - La fila **no** adivina si el ciclo es el más reciente: se lo dice esta tarea con `isMostRecentPeriod`, que sale de `AcademicRecordController.isMostRecentPeriod(periodCode)`.
- Consume (tarea 6):
  - `class AcademicRecordController extends GetxController { AcademicRecordController({AcademicRecordService? service, DateTime Function()? now}); AcademicRecord? get record; bool get isLoading; bool get hasError; String? get syncedLabel; Future<void> retry(); @override void onReady(); static String syncedAgoLabel(DateTime syncedAt, DateTime now); }` — `hasError` da `true` también para un docente (guarda de la tarea 6), y por eso `/mi-record` nunca se queda en el skeleton para él.
  - `class AcademicRecordPage extends GetView<AcademicRecordController>` con `static const String title = 'Mi récord académico';`, `emptyTitle`, `emptyBody`, `syncButtonLabel`, `loadErrorTitle`, `skeletonKey`, `ringKey` y `static const Key successViewKey = Key('record-success-view');`
  - El widget privado `_RecordSuccessView({required this.controller, required this.record})`, con los campos `final AcademicRecordController controller;` y `final AcademicRecord record;`: es un `SingleChildScrollView(key: AcademicRecordPage.successViewKey, padding: EdgeInsets.fromLTRB(16, 12, 16, 32))` con un `Column(crossAxisAlignment: CrossAxisAlignment.stretch)` cuyos hijos hoy son el encabezado, `SizedBox(height: 10)`, la línea de `syncedLabel` y `SizedBox(height: 16)`.
  - El arnés de `test/HU34_jeff/record_page_test.dart`: `Future<_FakeRecordApi> _mountPage(WidgetTester tester, {required List<Object> getResponses, UserModel? user})`, `Map<String, dynamic> _syncedJson({Object? creditsRequired = 240})`, `Map<String, dynamic> _neverSyncedJson()`, `DateTime _now()`, `Widget _app()`, `UserModel _student()`, `class _FakeAuthService extends AuthService` y `class _FakeRecordApi extends ApiClient`. Ningún valor del arnés sale de `test/HU31_jeff/fixtures/` ni de `spike-portal/`: si este arnés no coincide con lo que dice aquí, manda el archivo, no esta lista.
  - Los ciclos que trae `_syncedJson()` en `record`, en este orden: `'2026-1'` (CURSO EN CURSO, `100001`, sin nota y sin `gradeRaw`), `'2025-2'` (CURSO APROBADO, `100002`, `attempt` 2, `credits` 1.5, `grade` 17; y CURSO CONVALIDADO, `100003`, `gradeRaw` `'CONV'`, `observation` `'Convalidado por examen'`) y `'2025-1'` (CURSO SIN NOTA ANTIGUO, `100004`, sin nota; y CURSO JALADO, `100005`, `grade` 8, `gradeRaw` `'08'`). En `periods` solo hay dos elementos: `'2025-2'` con `average` 17.3, `relativePosition` `'MEDIO SUPERIOR'` y `level` 8, y `'2025-1'` con `average` null. Ese `'MEDIO SUPERIOR'` es distinto **a propósito** del `'TERCIO SUPERIOR'` del `snapshot`: si la pantalla cruza los campos, la prueba falla. **`'2026-1'` no está en `periods`**: es justo el caso "no hay elemento" de la spec (`spec:78-80`).
- Consume (del repo, sin modificarlo): `lib/configs/themes.dart`, clase `MaterialTheme` — `primaryColor` (`:10`), `cardBg` (`:59`), `textPrimary` (`:63`), `textSecondary` (`:67`), `borderColor` (`:79`). Plantilla de la fila de chips: `lib/pages/teacher/at_risk_students_page.dart:391-412` (`_FilterChips`: `SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(...))`) y `:444-485` (`_FilterChip`, que no lleva `key` ni `Semantics`: los dos se agregan aquí). Separador entre filas: `Divider(height: 1, thickness: 1, color: MaterialTheme.borderColor(brightness))` de `lib/pages/horario/horario_list_view.dart:92-96`. Brillo: `final brightness = Theme.brightnessOf(context);` de `lib/pages/mis_notas/mis_notas_page.dart:16`.
- Produce — `AcademicRecordController`, además de lo que ya tiene:
  - `final selectedPeriodCode = RxnString();`
  - `List<String> get periodCodes;` — `record?.coursesByPeriod.map((p) => p.periodCode)`, en el orden del backend
  - `String? get currentPeriodCode;` — `periodoSeleccionado(periodCodes, selectedPeriodCode.value)`
  - `bool isMostRecentPeriod(String periodCode);` — `periodCodes.isNotEmpty && periodCodes.first == periodCode`
  - `void selectPeriod(String periodCode);`
  - `static String? periodoSeleccionado(List<String> periodCodes, String? elegido);`
  - `static double? periodAverage(List<AcademicPeriodSummary> periods, String periodCode);`
- Produce — `AcademicRecordPage`, además de lo que ya tiene:
  - `static ValueKey<String> periodChipKey(String periodCode) => ValueKey<String>('record-period-chip-$periodCode');`
  - `static const Key coursesCardKey = Key('record-courses-card');`
  - El texto del promedio del ciclo es literalmente `'prom. ${formatDecimal(average)}'`.

Quién lo usa después: la **tarea 8** pone `_DeleteRecordButton` como último hijo del mismo `Column` de `_RecordSuccessView` (después de esta sección), compara su posición contra `AcademicRecordPage.coursesCardKey` y, tras borrar, hace `selectedPeriodCode.value = null`.

**Ojo con dos trampas:**
1. **El `Obx` de la página no alcanza.** El `Obx` del `body` solo registra los `Rx` que se leen **dentro de su propia closure**. `selectedPeriodCode.value` se lee en `_RecordSuccessView.build`, que corre fuera de esa closure: sin un `Obx` propio, tocar un chip cambiaría el `Rx` y la lista no se repintaría. Por eso toda la sección va envuelta en su propio `Obx`, y dentro se leen primero `controller.currentPeriodCode` (que lee `selectedPeriodCode.value` **y** el `Rx` del récord, porque `periodCodes` pasa por `AcademicRecordService.record`) y después `controller.record`. Se lee `controller.record` y no el campo `record` del widget justamente para que el `Rx` quede registrado en **este** `Obx`.
2. **`find.text('2025-2')` encuentra dos widgets**: el chip y el encabezado de la tarjeta dicen lo mismo. Para tocar se usa siempre `find.byKey(AcademicRecordPage.periodChipKey('2025-2'))`; para mirar la lista, `find.descendant(of: find.byKey(AcademicRecordPage.coursesCardKey), matching: ...)`. Los dos helpers están en el Paso 1.

Hoy no existe en `lib/` ni en `test/` nada llamado `periodChipKey`, `coursesCardKey`, `periodoSeleccionado`, `periodAverage`, `selectedPeriodCode`, `_PeriodChips`, `_PeriodChip` ni `_PeriodCoursesCard` (`grep -rn "periodChipKey\|coursesCardKey\|periodoSeleccionado\|periodAverage\|selectedPeriodCode\|_PeriodChip\|_PeriodCoursesCard" lib/ test/` no devuelve nada), así que ningún nombre choca.

- [ ] **Paso 1: Escribir la prueba que falla**

Son tres inserciones sobre `test/HU34_jeff/record_page_test.dart`. Ninguna toca los grupos de la tarea 6.

**1.1 · Import del modelo.** Reemplazar la línea:

```dart
import 'package:ulima_plus/models/user_model.dart';
```

por:

```dart
import 'package:ulima_plus/models/academic_record_model.dart';
import 'package:ulima_plus/models/user_model.dart';
```

Hace falta por `AcademicPeriodSummary` y `AcademicTotals.none`, que la prueba unitaria construye a mano. Queda antes de `user_model.dart`, que es el orden alfabético del resto del archivo.

**1.2 · Import de la fila de curso.** Reemplazar la línea:

```dart
import 'package:ulima_plus/pages/academic_record/academic_record_page.dart';
```

por:

```dart
import 'package:ulima_plus/pages/academic_record/academic_record_page.dart';
import 'package:ulima_plus/pages/academic_record/record_course_row.dart';
```

Hace falta por `RecordCourseRow.inProgressLabel`, `RecordCourseRow.noGradeLabel` y `find.byType(RecordCourseRow)`. Los dos imports se usan; ninguno queda como `unused_import`.

**1.3 · Los dos grupos nuevos.** Van antes del último grupo de la tarea 6, que es el ancla: así el ancla es única (`group('UNITARIA · syncedAgoLabel…` aparece una sola vez) y el orden de los `group` no cambia en nada cómo corren, porque cada uno monta su propia pantalla. El nombre del grupo lleva el sufijo `(RF-REC-2)` que le puso la tarea 6: copia la línea tal cual, con el sufijo, o el `Edit` no encuentra el ancla. Reemplazar la línea:

```dart
  group('UNITARIA · syncedAgoLabel en hora de Lima (RF-REC-2)', () {
```

por:

```dart
  group('WIDGET · Chips de ciclo y cursos (RF-REC-2, RF-REC-3)', () {
    // El chip y el encabezado de la tarjeta dicen lo mismo ('2025-2'), así que
    // find.text encontraría dos. Para tocar se usa la key del chip; para mirar
    // la lista, solo lo que está dentro de la tarjeta.
    Finder chip(String periodCode) =>
        find.byKey(AcademicRecordPage.periodChipKey(periodCode));

    Finder enLaTarjeta(Finder matching) => find.descendant(
      of: find.byKey(AcademicRecordPage.coursesCardKey),
      matching: matching,
    );

    Future<void> tocarChip(WidgetTester tester, String periodCode) async {
      await tester.tap(chip(periodCode));
      await tester.pump();
    }

    testWidgets('los chips van del más reciente al más viejo', (tester) async {
      await _mountPage(tester, getResponses: [_syncedJson()]);

      expect(chip('2026-1'), findsOneWidget);
      expect(chip('2025-2'), findsOneWidget);
      expect(chip('2025-1'), findsOneWidget);

      // El orden es el del backend (RS-BE-26): el cliente no reordena.
      final x2026 = tester.getTopLeft(chip('2026-1')).dx;
      final x20252 = tester.getTopLeft(chip('2025-2')).dx;
      final x20251 = tester.getTopLeft(chip('2025-1')).dx;
      expect(x2026, lessThan(x20252));
      expect(x20252, lessThan(x20251));
    });

    testWidgets('viene seleccionado el ciclo más reciente', (tester) async {
      await _mountPage(tester, getResponses: [_syncedJson()]);

      expect(enLaTarjeta(find.text('2026-1')), findsOneWidget);
      expect(enLaTarjeta(find.text('CURSO EN CURSO')), findsOneWidget);
      expect(enLaTarjeta(find.text('CURSO APROBADO')), findsNothing);
      expect(find.byType(RecordCourseRow), findsOneWidget);
    });

    testWidgets('tocar otro chip cambia la lista: un ciclo a la vez', (
      tester,
    ) async {
      await _mountPage(tester, getResponses: [_syncedJson()]);
      await tocarChip(tester, '2025-2');

      expect(enLaTarjeta(find.text('CURSO APROBADO')), findsOneWidget);
      expect(enLaTarjeta(find.text('CURSO CONVALIDADO')), findsOneWidget);
      expect(enLaTarjeta(find.text('CURSO EN CURSO')), findsNothing);
      expect(find.byType(RecordCourseRow), findsNWidgets(2));

      // Y se puede volver: sigue habiendo un solo ciclo a la vista.
      await tocarChip(tester, '2026-1');
      expect(enLaTarjeta(find.text('CURSO EN CURSO')), findsOneWidget);
      expect(enLaTarjeta(find.text('CURSO APROBADO')), findsNothing);
      expect(find.byType(RecordCourseRow), findsOneWidget);
    });

    testWidgets('el promedio sale de periods, y solo si el backend lo tiene', (
      tester,
    ) async {
      await _mountPage(tester, getResponses: [_syncedJson()]);

      // '2026-1' no está en 'periods': no hay promedio que mostrar.
      expect(find.textContaining('prom.'), findsNothing);

      await tocarChip(tester, '2025-2');
      expect(enLaTarjeta(find.text('prom. 17.3')), findsOneWidget);

      // '2025-1' sí está en 'periods', pero con average null: tampoco se
      // pinta nada, y mucho menos un 0.
      await tocarChip(tester, '2025-1');
      expect(find.textContaining('prom.'), findsNothing);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('"En curso" solo en el ciclo más reciente del récord', (
      tester,
    ) async {
      await _mountPage(tester, getResponses: [_syncedJson()]);

      expect(
        enLaTarjeta(find.text(RecordCourseRow.inProgressLabel)),
        findsOneWidget,
      );

      await tocarChip(tester, '2025-1');
      expect(enLaTarjeta(find.text('CURSO SIN NOTA ANTIGUO')), findsOneWidget);
      expect(
        enLaTarjeta(find.text(RecordCourseRow.noGradeLabel)),
        findsOneWidget,
      );
      expect(find.text(RecordCourseRow.inProgressLabel), findsNothing);
      expect(enLaTarjeta(find.text('08')), findsOneWidget);
    });

    testWidgets('cada curso del ciclo elegido se pinta como pide RF-REC-3', (
      tester,
    ) async {
      await _mountPage(tester, getResponses: [_syncedJson()]);
      await tocarChip(tester, '2025-2');

      expect(enLaTarjeta(find.text('2.ª vez')), findsOneWidget);
      expect(enLaTarjeta(find.text('100002 · 1.5 créd.')), findsOneWidget);
      expect(enLaTarjeta(find.text('17')), findsOneWidget);
      expect(enLaTarjeta(find.text('CONV')), findsOneWidget);
      expect(enLaTarjeta(find.text('Convalidado por examen')), findsOneWidget);

      // Qué NO entra: el resumen completo del ciclo. De 'periods' sale el
      // promedio y nada más, aunque el '2025-2' de la respuesta traiga
      // relativePosition 'MEDIO SUPERIOR', level 8 y los cuatro grupos de
      // cursos y créditos. ('Tercio superior' SÍ está en pantalla, pero en el
      // encabezado: es la ubicación del snapshot, que pide RF-REC-2; por eso
      // lo de la ubicación se mira solo dentro de la tarjeta.)
      expect(find.textContaining('MEDIO'), findsNothing);
      expect(find.textContaining('Medio'), findsNothing);
      expect(enLaTarjeta(find.textContaining('superior')), findsNothing);
      expect(enLaTarjeta(find.textContaining('créditos')), findsNothing);
    });
  });

  group('UNITARIA · periodoSeleccionado y periodAverage (RF-REC-2)', () {
    const ciclos = ['2026-1', '2025-2'];

    AcademicPeriodSummary resumen(String periodCode, double? average) =>
        AcademicPeriodSummary(
          periodCode: periodCode,
          average: average,
          relativePosition: null,
          level: null,
          convalidated: AcademicTotals.none,
          enrolled: AcademicTotals.none,
          approved: AcademicTotals.none,
          failed: AcademicTotals.none,
        );

    test('sin elección previa manda el más reciente, que es el primero', () {
      expect(
        AcademicRecordController.periodoSeleccionado(ciclos, null),
        '2026-1',
      );
    });

    test('un ciclo elegido que existe se respeta', () {
      expect(
        AcademicRecordController.periodoSeleccionado(ciclos, '2025-2'),
        '2025-2',
      );
    });

    test('un ciclo que ya no está en el récord cae al más reciente', () {
      // Pasa al volver a sincronizar: el récord nuevo puede no traer el ciclo
      // que estaba elegido.
      expect(
        AcademicRecordController.periodoSeleccionado(ciclos, '2024-1'),
        '2026-1',
      );
    });

    test('sin ciclos no hay nada que elegir', () {
      expect(
        AcademicRecordController.periodoSeleccionado(
          const <String>[],
          '2025-2',
        ),
        isNull,
      );
    });

    test('periodAverage solo devuelve el promedio que el backend tiene', () {
      final periods = [resumen('2025-2', 17.3), resumen('2025-1', null)];

      expect(AcademicRecordController.periodAverage(periods, '2025-2'), 17.3);
      // El ciclo no está en 'periods'.
      expect(AcademicRecordController.periodAverage(periods, '2026-1'), isNull);
      // El ciclo está, pero sin promedio.
      expect(AcademicRecordController.periodAverage(periods, '2025-1'), isNull);
    });
  });

  group('UNITARIA · syncedAgoLabel en hora de Lima (RF-REC-2)', () {
```

- [ ] **Paso 2: Correr la prueba y ver que falla**

```bash
cd . && $FLUTTER test test/HU34_jeff/record_page_test.dart
```

Esperado: **no compila**, porque los cuatro miembros nuevos todavía no existen. Sale un `Error: Member not found:` por cada uno de los nueve usos —el compilador los imprime dos veces, primero sueltos y después dentro del reporte—, con esta forma (los números de línea y de columna dependen de dónde cayeron los grupos):

```
test/HU34_jeff/record_page_test.dart:NNN:CC: Error: Member not found: 'periodChipKey'.
        find.byKey(AcademicRecordPage.periodChipKey(periodCode));
                                      ^^^^^^^^^^^^^
test/HU34_jeff/record_page_test.dart:NNN:CC: Error: Member not found: 'coursesCardKey'.
      of: find.byKey(AcademicRecordPage.coursesCardKey),
                                        ^^^^^^^^^^^^^^
test/HU34_jeff/record_page_test.dart:NNN:CC: Error: Member not found: 'periodoSeleccionado'.
        AcademicRecordController.periodoSeleccionado(ciclos, null),
                                 ^^^^^^^^^^^^^^^^^^^
test/HU34_jeff/record_page_test.dart:NNN:CC: Error: Member not found: 'periodAverage'.
      expect(AcademicRecordController.periodAverage(periods, '2025-2'), 17.3);
                                      ^^^^^^^^^^^^^
```

y al final:

```
00:00 +0 -1: Some tests failed.

Failing tests:
  ./test/HU34_jeff/record_page_test.dart: loading ./test/HU34_jeff/record_page_test.dart
```

El reparto de los nueve usos: 1 de `periodChipKey`, 1 de `coursesCardKey`, 4 de `periodoSeleccionado` y 3 de `periodAverage`. Es el fallo correcto: el archivo no carga, así que en este estado tampoco corren los grupos de la tarea 6 — vuelven en el Paso 4. Lo que **no** debe salir es un error sobre `RecordCourseRow`, `AcademicPeriodSummary` o `AcademicTotals`: eso significaría que la tarea 5 o la tarea 1 no están hechas en este árbol, y hay que terminarlas antes de seguir. Si sale `All tests passed!`, alguien ya implementó esta tarea: revisa el árbol antes de tocar nada.

- [ ] **Paso 3: Implementación mínima**

**3.1 · `lib/pages/academic_record/academic_record_controller.dart`** — una sola edición. Reemplazar la línea:

```dart
  Future<void> retry() => _service.load(force: true);
```

por:

```dart
  Future<void> retry() => _service.load(force: true);

  /// Ciclo que el alumno tocó. Queda null hasta el primer toque, y entonces
  /// manda el más reciente (RF-REC-2). La tarea 8 lo vuelve a null al borrar
  /// el récord.
  final selectedPeriodCode = RxnString();

  /// Los ciclos del récord, en el orden en que los manda el backend: del más
  /// reciente al más viejo (RS-BE-26). El cliente no los reordena.
  List<String> get periodCodes =>
      record?.coursesByPeriod.map((p) => p.periodCode).toList() ??
      const <String>[];

  /// El ciclo que se está mostrando ahora mismo.
  String? get currentPeriodCode =>
      periodoSeleccionado(periodCodes, selectedPeriodCode.value);

  /// Solo el ciclo más reciente del récord puede decir "En curso" (RF-REC-3):
  /// en los demás, un curso sin nota es una raya.
  bool isMostRecentPeriod(String periodCode) =>
      periodCodes.isNotEmpty && periodCodes.first == periodCode;

  /// Un solo ciclo a la vez: el chip que se toca reemplaza al anterior.
  void selectPeriod(String periodCode) => selectedPeriodCode.value = periodCode;

  /// Pura y expuesta para probarla. Un ciclo elegido que ya no está en el
  /// récord —porque se volvió a sincronizar y cambió— cae al más reciente, que
  /// es el primero de la lista.
  static String? periodoSeleccionado(
    List<String> periodCodes,
    String? elegido,
  ) {
    if (periodCodes.isEmpty) return null;
    if (elegido != null && periodCodes.contains(elegido)) return elegido;
    return periodCodes.first;
  }

  /// Pura y expuesta para probarla. El promedio del ciclo sale de `periods`,
  /// no de las notas: si el backend no manda ese ciclo, o su `average` es
  /// null, devuelve null y la tarjeta no pinta nada (nunca un 0).
  static double? periodAverage(
    List<AcademicPeriodSummary> periods,
    String periodCode,
  ) {
    for (final p in periods) {
      if (p.periodCode == periodCode) return p.average;
    }
    return null;
  }
```

No hacen falta imports nuevos: `RxnString` viene de `package:get/get.dart` y `AcademicPeriodSummary` de `../../models/academic_record_model.dart`, los dos ya importados por la tarea 6.

**3.2 · `lib/pages/academic_record/academic_record_page.dart`, import.** La página todavía no importa la fila de curso; se agrega justo antes de `record_format.dart`, que es el orden alfabético. Reemplazar la línea:

```dart
import 'record_format.dart';
```

por:

```dart
import 'record_course_row.dart';
import 'record_format.dart';
```

**3.3 · Las dos constantes de la página.** Reemplazar la línea:

```dart
  static const Key successViewKey = Key('record-success-view');
```

por:

```dart
  static const Key successViewKey = Key('record-success-view');

  /// Key de cada chip de ciclo. El chip y el encabezado de la tarjeta dicen el
  /// mismo texto, así que los tests tocan por key, no por texto.
  static ValueKey<String> periodChipKey(String periodCode) =>
      ValueKey<String>('record-period-chip-$periodCode');

  /// Key de la tarjeta de cursos del ciclo elegido.
  static const Key coursesCardKey = Key('record-courses-card');
```

**3.4 · La sección de chips y cursos, y las tres clases privadas.** Una sola edición, que cierra `_RecordSuccessView` y abre las clases nuevas justo debajo. Reemplazar estas seis líneas —el final de la lista `children` de `_RecordSuccessView` y el cierre de su `build` y de su clase—:

```dart
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
```

por:

```dart
          const SizedBox(height: 16),
          // Chips de ciclo y cursos del ciclo elegido (RF-REC-2), en su propio
          // Obx: el Obx del body solo registra los Rx que se leen dentro de su
          // closure, y selectedPeriodCode.value se lee acá. Sin este Obx,
          // tocar un chip cambiaría el Rx y la lista no se repintaría.
          Obx(() {
            // currentPeriodCode lee selectedPeriodCode.value y el récord, y
            // controller.record vuelve a leer el mismo Rx: los dos quedan
            // registrados en ESTE Obx. Por eso se usa controller.record y no
            // el campo `record` del widget, que no es observable.
            final selected = controller.currentPeriodCode;
            final rec = controller.record;
            if (rec == null || selected == null) {
              return const SizedBox.shrink();
            }
            // `selected` sale de estos mismos `coursesByPeriod`, leídos sin
            // ningún await en medio: el ciclo siempre está.
            final period = rec.coursesByPeriod.firstWhere(
              (p) => p.periodCode == selected,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PeriodChips(
                  periodCodes: controller.periodCodes,
                  selected: selected,
                  onSelect: controller.selectPeriod,
                ),
                const SizedBox(height: 12),
                _PeriodCoursesCard(
                  period: period,
                  average: AcademicRecordController.periodAverage(
                    rec.periodSummaries,
                    selected,
                  ),
                  isMostRecent: controller.isMostRecentPeriod(selected),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

/// Fila horizontal de chips de ciclo (RF-REC-2), en el orden del backend: del
/// más reciente al más viejo. Plantilla: `_FilterChips`
/// (lib/pages/teacher/at_risk_students_page.dart:391-412).
class _PeriodChips extends StatelessWidget {
  const _PeriodChips({
    required this.periodCodes,
    required this.selected,
    required this.onSelect,
  });

  final List<String> periodCodes;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // El padding va a la derecha de cada chip, también del último: así
          // el final de la fila respira cuando se llega scrolleando.
          for (final code in periodCodes)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _PeriodChip(
                key: AcademicRecordPage.periodChipKey(code),
                periodCode: code,
                isSelected: code == selected,
                onTap: () => onSelect(code),
              ),
            ),
        ],
      ),
    );
  }
}

/// Un chip de ciclo. Copia de `_FilterChip`
/// (lib/pages/teacher/at_risk_students_page.dart:444-485) con el naranja de la
/// app fijo y sin el conteo entre paréntesis, más la key y el Semantics que
/// aquel no tiene.
class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    super.key,
    required this.periodCode,
    required this.isSelected,
    required this.onTap,
  });

  final String periodCode;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const chipColor = MaterialTheme.primaryColor;
    return Semantics(
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        // Opaque para que el toque valga también en el padding del chip, no
        // solo encima del texto.
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? chipColor.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? chipColor : chipColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Text(
            periodCode,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? chipColor : chipColor.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}

/// Los cursos del ciclo elegido, en una tarjeta (RF-REC-2).
///
/// El promedio llega ya resuelto desde `periods`: si el backend no tiene ese
/// ciclo, o su `average` es null, acá llega null y no se pinta nada. Nunca un
/// 0. Del resumen del ciclo no entra nada más: ni la ubicación relativa, ni el
/// nivel, ni los grupos de cursos y créditos. Cada fila es un
/// [RecordCourseRow], y es esta tarjeta la que le dice si el ciclo es el más
/// reciente del récord (RF-REC-3).
class _PeriodCoursesCard extends StatelessWidget {
  const _PeriodCoursesCard({
    required this.period,
    required this.average,
    required this.isMostRecent,
  });

  final RecordPeriod period;
  final double? average;
  final bool isMostRecent;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.brightnessOf(context);
    final promedio = average;
    final filas = <Widget>[];
    for (var i = 0; i < period.courses.length; i++) {
      if (i > 0) {
        filas.add(
          Divider(
            height: 1,
            thickness: 1,
            color: MaterialTheme.borderColor(brightness),
          ),
        );
      }
      filas.add(
        RecordCourseRow(
          course: period.courses[i],
          isMostRecentPeriod: isMostRecent,
        ),
      );
    }
    return Container(
      key: AcademicRecordPage.coursesCardKey,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MaterialTheme.cardBg(brightness),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MaterialTheme.borderColor(brightness)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                period.periodCode,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: MaterialTheme.textPrimary(brightness),
                ),
              ),
              const Spacer(),
              if (promedio != null)
                Text(
                  'prom. ${formatDecimal(promedio)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: MaterialTheme.textSecondary(brightness),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...filas,
        ],
      ),
    );
  }
}
```

Las tres clases nuevas quedan a columna 0, igual que el `}` que cierra `_RecordSuccessView`. Comprobarlo después de la edición con `grep -n "^class _Period" lib/pages/academic_record/academic_record_page.dart`, que debe devolver tres líneas.

Dos detalles que no son de estilo: `final promedio = average;` no es un adorno —`average` es un campo público, y los campos públicos no se promueven a no-nulo, así que sin la copia local `formatDecimal(promedio)` no compila—; y el `Divider` va **entre** filas, nunca antes de la primera ni después de la última, que es lo que hace el `if (i > 0)`.

- [ ] **Paso 4: Correr la prueba y ver que pasa**

```bash
cd . && $FLUTTER test test/HU34_jeff/record_page_test.dart
```

Esperado: **PASS**, con todos los casos del archivo — los de la tarea 6 más los **11 nuevos** (6 en `WIDGET · Chips de ciclo y cursos (RF-REC-2, RF-REC-3)` y 5 en `UNITARIA · periodoSeleccionado y periodAverage (RF-REC-2)`):

```
00:00 +25: All tests passed!
```

El número exacto depende de en cuántos `test`/`testWidgets` haya quedado dividida la tarea 6 (25 si fueron 14); lo que tiene que cumplirse es que suba en 11 respecto de la corrida anterior y que no quede ningún `-N`.

Si falla `tocar otro chip cambia la lista`, y en cambio el resto pasa, el `Obx` quedó fuera de `_RecordSuccessView` o lee los getters en otro orden: revisa que dentro de la closure se llame a `controller.currentPeriodCode` **antes** de cualquier `return`.

- [ ] **Paso 5: Análisis estático**

```bash
cd . && $FLUTTER analyze lib/pages/academic_record/academic_record_controller.dart lib/pages/academic_record/academic_record_page.dart test/HU34_jeff/record_page_test.dart
```

Esperado: `No issues found! (ran in …)`. Si sale algún issue, corrígelo en esos tres archivos y repite los Pasos 4 y 5.

Después, el proyecto entero, para comprobar que el número de issues preexistentes que se anotó en la tarea 1 no subió:

```bash
cd . && $FLUTTER analyze 2>&1 | grep -E "issues? found|academic_record"
```

Esperado: la misma línea `N issues found. (ran in …)` (o `No issues found!`) de la tarea 1, y ninguna línea que nombre `academic_record`. Si esta tarea corre en otra sesión no tienes el reporte de la tarea 1: la línea base está en `$TMP/plan-fe/analyze-baseline.txt`; léela con `cat` y compara sin el `(ran in …)`. Si el número subió, el issue nuevo es de esta tarea: corrígelo.

- [ ] **Paso final: Commit**

Revisa primero que el árbol no tenga cambios ajenos:

```bash
cd . && git status --short --untracked-files=all
```

Esperado, en cualquier orden, exactamente estas tres líneas:

```
 M lib/pages/academic_record/academic_record_controller.dart
 M lib/pages/academic_record/academic_record_page.dart
 M test/HU34_jeff/record_page_test.dart
```

Si aparece otro archivo, no lo agregues ni lo toques: puede ser de otra sesión trabajando en el mismo árbol.

```bash
cd . && git add lib/pages/academic_record/academic_record_controller.dart lib/pages/academic_record/academic_record_page.dart test/HU34_jeff/record_page_test.dart && git diff --cached --stat
```

Esperado: exactamente esos 3 archivos y `3 files changed`.

```bash
cd . && git commit -m "feat(academic-record): chips de ciclo y cursos del ciclo elegido"
```

El autor ya está configurado en git. El mensaje no lleva trailer `Co-Authored-By`. No hagas push.

### Tarea 8: Borrar mi récord: diálogo, DELETE y estado vacío compartido

**Archivos:**
- Modificar: `lib/pages/academic_record/academic_record_controller.dart` (lo crea la tarea 6 y lo amplía la tarea 7; aquí **una** edición: `deleting` y `deleteRecord()` justo después de `selectPeriod`, antes de las estáticas `periodoSeleccionado` y `periodAverage`)
- Modificar: `lib/pages/academic_record/academic_record_page.dart` (lo crea la tarea 6 y lo amplía la tarea 7; aquí **cuatro** ediciones: un import, las seis constantes nuevas de `AcademicRecordPage`, el `SizedBox(height: 28)` + `_DeleteRecordButton` como últimos hijos del `Column` de `_RecordSuccessView`, y la clase `_DeleteRecordButton` al final del archivo)
- Test: `test/HU34_jeff/record_page_test.dart` (lo crea la tarea 6 y lo amplía la tarea 7; aquí **tres** ediciones: dos imports y un grupo nuevo al final de `main()`. No se tocan los grupos anteriores: se reutiliza su arnés tal cual)
- **No** se dan números de línea de estos tres archivos porque ninguno existe en `HEAD`: los escriben las tareas 6 y 7. Lo que manda son las anclas literales del Paso 1 y del Paso 3, que se comprueban con los `grep` de la precondición.
- **No** se toca la spec: `specs/features/academic-record/academic-record.spec.md:134` ya dice literalmente `` `[@test] ../../../test/HU34_jeff/record_page_test.dart` `` al final de RF-REC-5 (comprobado: `grep -n "@test" specs/features/academic-record/academic-record.spec.md` devuelve `134` para `record_page_test.dart` y `135` para `record_card_test.dart`, y los `[@test]` que insertan las tareas 1 y 2 van después de la L135 y de la L173, así que la 134 no se corre). Tampoco `docs/specs/api-contracts.md`: el `DELETE /academic-record/me` lo documentó la tarea 2 en su Paso 6.
- **No** se toca `lib/main.dart` (la ruta `/mi-record` ya está desde la tarea 6), ni `lib/pages/perfil/perfil.dart` (la tarjeta ya está desde la tarea 4), ni `lib/services/academic_record_service.dart` (`deleteRecord()` y `AcademicRecordFailure` ya están desde la tarea 2). Esta tarea **solo** cablea la UI.

**Precondición:** las tareas 1 a 7 ya tienen su commit y el árbol está limpio. Las anclas de esta tarea las escribieron las tareas 6 y 7, así que hay que comprobarlas antes de editar. Los comandos van separados por `;` a propósito, para ver todos los resultados aunque uno falle:

```bash
cd . && \
  echo "--- arbol" ; git status --short --untracked-files=all ; \
  echo "--- archivos de las tareas 2, 4 y 6" ; ls lib/services/academic_record_service.dart lib/pages/academic_record/record_profile_card.dart lib/pages/academic_record/academic_record_binding.dart ; \
  echo "--- tarea 2 (mensaje y excepcion del borrado)" ; grep -n "deleteErrorMessage =\|^class AcademicRecordFailure" lib/services/academic_record_service.dart ; \
  echo "--- tarea 4 (texto de la tarjeta)" ; grep -n "neverSyncedText =" lib/pages/academic_record/record_profile_card.dart ; \
  echo "--- ancla 1 (controller, tarea 7)" ; grep -n "void selectPeriod(String periodCode) => selectedPeriodCode.value = periodCode;" lib/pages/academic_record/academic_record_controller.dart ; \
  echo "--- ancla 2 (import de la pagina, tarea 6)" ; grep -n "^import '../../models/academic_record_model.dart';" lib/pages/academic_record/academic_record_page.dart ; \
  echo "--- ancla 3 (coursesCardKey, tarea 7)" ; grep -n "static const Key coursesCardKey = Key('record-courses-card');" lib/pages/academic_record/academic_record_page.dart ; \
  echo "--- ancla 4 (cierre del Obx de chips, tarea 7)" ; grep -n "^/// Fila horizontal de chips de ciclo (RF-REC-2), en el orden del backend: del" lib/pages/academic_record/academic_record_page.dart ; \
  echo "--- ancla 5 (fin del archivo de la pagina)" ; grep -n "bool shouldRepaint(_CreditsRingPainter old)" lib/pages/academic_record/academic_record_page.dart ; \
  echo "--- ancla 6 (fin del test)" ; grep -n "un syncedAt futuro no produce días negativos" test/HU34_jeff/record_page_test.dart ; \
  echo "--- anclas de import del test" ; grep -n "^import 'package:ulima_plus/pages/academic_record/academic_record_controller.dart';\|^import 'package:ulima_plus/pages/academic_record/record_course_row.dart';" test/HU34_jeff/record_page_test.dart ; \
  echo "--- NO debe existir todavia" ; grep -n "deleteButtonKey\|_DeleteRecordButton\|deleteDialogTitle\|record_profile_card.dart\|academic_record_binding.dart" lib/pages/academic_record/academic_record_page.dart test/HU34_jeff/record_page_test.dart
```

Esperado:
- `git status --short --untracked-files=all` no imprime nada (árbol limpio);
- `ls` lista los tres archivos;
- el `grep` de la tarea 2 devuelve **dos** líneas (`static const String deleteErrorMessage =` y `class AcademicRecordFailure implements Exception {`);
- el de la tarea 4 devuelve **una**;
- las anclas 1 a 6 devuelven **una** línea cada una;
- las dos anclas de import del test devuelven una línea cada una (la segunda la agregó la tarea 7);
- el último `grep` **no** imprime nada.

Si falta el ancla 1 o la 3, la tarea 7 no está hecha en este árbol; si falta la 2, la 4, la 5 o la 6, falta la tarea 6; si fallan los `grep` de las tareas 2 o 4, faltan esas. Termínalas antes de seguir. Todo se hace en `.`, rama `feat/record-academico-fe`, con `Edit` sobre las anclas literales de abajo. Nada de `cp`, `mv` ni `git stash`.

**Interfaces:**
- Consume (tarea 2, `lib/services/academic_record_service.dart`):
  - `Future<void> deleteRecord();` — hace `DELETE '/academic-record/me'` con `.timeout(deleteTimeout)`; si el backend falla lanza `AcademicRecordFailure(AcademicRecordService.deleteErrorMessage)` y el récord **no** cambia (tampoco recarga); si sale bien deja `record = AcademicRecord.empty` y después hace `await load(force: true)`, que **nunca lanza**.
  - `static const String deleteErrorMessage = 'No se pudo borrar tu récord. Inténtalo de nuevo.';`
  - `class AcademicRecordFailure implements Exception { const AcademicRecordFailure(this.message); final String message; }`
  - `AcademicRecordService({ApiClient? apiClient});`, `static AcademicRecordService get to => Get.find();` y `AcademicRecord? get record;`
- Consume (tarea 4, `lib/pages/academic_record/record_profile_card.dart`): `class RecordProfileCard extends StatefulWidget { const RecordProfileCard({super.key}); static const String neverSyncedText = 'Sincroniza con el portal para ver tu récord'; }`. Dispara `AcademicRecordService.to.load()` en un `addPostFrameCallback` de `initState` y toda ella es tocable con `Get.toNamed<dynamic>('/mi-record')`. En el estado de éxito pinta `formatDecimal(ppa)` y `creditsOfRequiredLabel(...)`, o sea `'14.62'` y `'197 de 240 créditos'` con el récord de prueba del arnés.
- Consume (tarea 6):
  - `class AcademicRecordBinding extends Bindings` (`Get.lazyPut<AcademicRecordController>(() => AcademicRecordController())`).
  - `class AcademicRecordPage extends GetView<AcademicRecordController>` con `const AcademicRecordPage({super.key});`, `static const String emptyTitle = 'Aún no tienes tu récord';` y `static const Key successViewKey = Key('record-success-view');`.
  - El widget privado `_RecordSuccessView({required this.controller, required this.record})`, con `final AcademicRecordController controller;`: es un `SingleChildScrollView(key: AcademicRecordPage.successViewKey, padding: EdgeInsets.fromLTRB(16, 12, 16, 32))` con un `Column(crossAxisAlignment: CrossAxisAlignment.stretch)`.
  - `AcademicRecordController({AcademicRecordService? service, DateTime Function()? now});` con `AcademicRecord? get record => _service.record;` y el campo privado `final AcademicRecordService _service;`.
  - El arnés de `test/HU34_jeff/record_page_test.dart`: `Future<_FakeRecordApi> _mountPage(WidgetTester tester, {required List<Object> getResponses, UserModel? user})` —que hace `Get.put<AuthService>` (con `_student()` si no se le pasa `user`), `Get.put<AcademicRecordService>` y `Get.put<AcademicRecordController>`—, `class _FakeRecordApi extends ApiClient { _FakeRecordApi(this.getResponses); Object? deleteError; int getCalls; int deleteCalls; String? lastDeletePath; }`, `class _FakeAuthService extends AuthService`, `UserModel _student()`, `Map<String, dynamic> _syncedJson({Object? creditsRequired = 240})` —con `ppa` 14.62, `creditsAccumulated` 197 y los ciclos `2026-1`, `2025-2` y `2025-1`— y `Map<String, dynamic> _neverSyncedJson()`.
- Consume (tarea 7): `static ValueKey<String> periodChipKey(String periodCode)`, `static const Key coursesCardKey = Key('record-courses-card');`, `final selectedPeriodCode = RxnString();` y `void selectPeriod(String periodCode)`.
- Consume (del repo, sin modificarlo):
  - El patrón de confirmación de `_LogoutButton` (`lib/pages/perfil/perfil.dart:1306-1364`): `SizedBox(height: 50)` con `OutlinedButton.icon`, `showDialog<bool>` + `AlertDialog`, `Navigator.of(ctx).pop(false)` / `pop(true)`, `if (confirmar != true) return;`, y `OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent, width: 1.4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))`.
  - Aviso de error con `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));`, como `lib/components/avatar/avatar_perfil.dart:132`.
  - `class ApiException implements Exception { ApiException({required this.statusCode, required this.code, required this.message, this.details}); }` en `lib/services/api_client.dart:10-25` (constructor **no** `const`), solo para el test.
  - `Flutter 3.47.2 / Dart 3.13.2`: `OutlinedButton.icon` es un **constructor con nombre** de `OutlinedButton` (`packages/flutter/lib/src/material/outlined_button.dart:100-124`), así que `tester.widget<OutlinedButton>(find.byKey(...)).onPressed` es válido.
  - `flutter_lints ^6.0.0`: trae `use_build_context_synchronously`, `prefer_const_constructors_in_immutables`, `sort_child_properties_last` y `use_key_in_widget_constructors` (esta última **no** aplica a clases privadas: `_LogoutButton` no lleva `key` y el repo analiza limpio). No trae `prefer_const_constructors` ni `unawaited_futures`.
- Produce — `AcademicRecordController`, además de lo que ya tiene:
  - `final deleting = false.obs;`
  - `Future<void> deleteRecord();` — relanza `AcademicRecordFailure`; si sale bien, `selectedPeriodCode.value = null`; un segundo llamado mientras el primero está en vuelo no hace nada
- Produce — `AcademicRecordPage`, además de lo que ya tiene:
  - `static const Key deleteButtonKey = Key('record-delete-button');`
  - `static const String deleteButtonLabel = 'Borrar mi récord de ULima++';`
  - `static const String deleteDialogTitle = 'Borrar mi récord';`
  - `static const String deleteDialogBody = 'Se borra la copia de tu récord guardada en ULima++. Tu malla no cambia. Si vuelves a sincronizar con el portal, se guarda de nuevo.';`
  - `static const String deleteConfirmLabel = 'Borrar';`
  - `static const String deleteCancelLabel = 'Cancelar';`

Nadie consume esto después: es la última tarea de la pantalla. Las tareas 9 a 11 son el consentimiento y no tocan estos archivos.

**Datos de prueba, todos inventados (repo PÚBLICO).** Se reutilizan tal cual los del arnés de la tarea 6: alumno sintético `20230001`, PPA 14.62, `TERCIO SUPERIOR`, 197 de 240 créditos, cursos `CURSO …` con códigos `1000xx`. Todos comprobados con `grep` contra `test/HU31_jeff/fixtures/` y `spike-portal/`. Esta tarea no inventa ningún dato nuevo.

**Cuatro trampas de esta tarea:**
1. **El botón solo existe en el estado de éxito.** En el vacío no hay copia que borrar, y en el de error no se sabe si la hay. Por eso `_DeleteRecordButton` va dentro de `_RecordSuccessView` y no en el `Scaffold`: tras un borrado exitoso el `Obx` del `body` ve `record.hasRecord == false`, pinta `_RecordEmptyState` y el botón **se desmonta solo**.
2. **El `context` después del `await`.** En el camino de error el botón sigue montado, pero `use_build_context_synchronously` (que `flutter_lints` sí trae) marca igual cualquier uso de `context` después de un `await`. El `if (!context.mounted) return;` es lo que lo apaga, y además cubre el caso en que el borrado deje la pantalla en el estado vacío.
3. **Sin spinner.** Mientras borra, el botón se deshabilita (`onPressed: null`) y nada más. Un `CircularProgressIndicator` anima sin fin y colgaría todos los `pumpAndSettle` de los tests, igual que `SkeletonPulse` (notas de UI, `notas-fe-perfil-ui.md:533`: "Es una animación infinita: `pumpAndSettle` hace timeout").
4. **El `SnackBar` deja un `Timer` de 4 s.** El `ScaffoldMessenger` lo arranca cuando termina la animación de entrada, así que el `pumpAndSettle` que la completa lo deja vivo. Si el test termina antes de que se cierre, el binding falla con `A Timer is still pending even after the widget tree was disposed.`. El caso 5 lo deja irse a propósito con `pump(const Duration(seconds: 4))` y un `pumpAndSettle` final.

En el estado de éxito no hay ningún `SkeletonPulse` ni ningún indicador indeterminado (`_CreditsRingPainter` es un `CustomPaint` estático, los chips son `GestureDetector` y `RecordCourseRow` es un `StatelessWidget` sin animación), así que en este grupo `pumpAndSettle` sí se puede usar.

- [ ] **Paso 1: Escribir la prueba que falla**

Son tres inserciones sobre `test/HU34_jeff/record_page_test.dart`. Ninguna toca los grupos de las tareas 6 y 7.

**1.1 · Import del binding.** Reemplazar la línea:

```dart
import 'package:ulima_plus/pages/academic_record/academic_record_controller.dart';
```

por:

```dart
import 'package:ulima_plus/pages/academic_record/academic_record_binding.dart';
import 'package:ulima_plus/pages/academic_record/academic_record_controller.dart';
```

Hace falta en el caso 7, que monta la ruta `/mi-record` con el binding real en vez de poner el controller a mano. Queda en orden alfabético, antes de `academic_record_controller.dart`.

**1.2 · Import de la tarjeta del Perfil.** Reemplazar la línea (la agregó la tarea 7):

```dart
import 'package:ulima_plus/pages/academic_record/record_course_row.dart';
```

por:

```dart
import 'package:ulima_plus/pages/academic_record/record_course_row.dart';
import 'package:ulima_plus/pages/academic_record/record_profile_card.dart';
```

Hace falta por `RecordProfileCard` y `RecordProfileCard.neverSyncedText` en el caso 7. Los dos imports se usan; ninguno queda como `unused_import`.

**1.3 · El grupo nuevo, al final de `main()`.** El ancla son las últimas doce líneas del archivo: el último `test` del grupo de la tarea 6 (que sigue siendo el último grupo, porque la tarea 7 metió los suyos **antes**), el cierre de ese grupo y el cierre de `main()`. Reemplazar esto:

```dart
    test('un syncedAt futuro no produce días negativos', () {
      expect(
        AcademicRecordController.syncedAgoLabel(
          DateTime.utc(2026, 9, 22, 15),
          DateTime.utc(2026, 9, 21, 16),
        ),
        'Sincronizado hoy',
      );
    });
  });
}
```

por esto:

```dart
    test('un syncedAt futuro no produce días negativos', () {
      expect(
        AcademicRecordController.syncedAgoLabel(
          DateTime.utc(2026, 9, 22, 15),
          DateTime.utc(2026, 9, 21, 16),
        ),
        'Sincronizado hoy',
      );
    });
  });

  group('WIDGET · Borrar mi récord (RF-REC-5)', () {
    Future<_FakeRecordApi> montarConRecord(
      WidgetTester tester, {
      List<Object>? getResponses,
    }) =>
        _mountPage(
          tester,
          getResponses: getResponses ?? <Object>[_syncedJson()],
        );

    // El botón es el último hijo de una pantalla scrolleable: antes de tocarlo
    // hay que asegurarse de que esté a la vista. En el estado de éxito no hay
    // ningún SkeletonPulse, así que acá pumpAndSettle sí se puede usar.
    Future<void> traerBotonALaVista(WidgetTester tester) async {
      await tester.ensureVisible(
        find.byKey(AcademicRecordPage.deleteButtonKey),
      );
      await tester.pumpAndSettle();
    }

    Future<void> abrirDialogo(WidgetTester tester) async {
      await traerBotonALaVista(tester);
      await tester.tap(find.byKey(AcademicRecordPage.deleteButtonKey));
      await tester.pumpAndSettle();
    }

    testWidgets('el botón va al final, después de la tarjeta de cursos',
        (tester) async {
      await montarConRecord(tester);

      expect(find.text(AcademicRecordPage.deleteButtonLabel), findsOneWidget);

      await traerBotonALaVista(tester);

      // "Al final de la pantalla" (RF-REC-5): debajo de la tarjeta de cursos.
      // Las dos posiciones se miden después del mismo scroll, así que lo que
      // se compara es el orden dentro del Column.
      expect(
        tester.getTopLeft(find.byKey(AcademicRecordPage.deleteButtonKey)).dy,
        greaterThan(
          tester.getTopLeft(find.byKey(AcademicRecordPage.coursesCardKey)).dy,
        ),
      );
    });

    testWidgets('el diálogo explica qué se borra y qué no', (tester) async {
      await montarConRecord(tester);
      await abrirDialogo(tester);

      // find.text es exacto: 'Borrar mi récord' no choca con el botón
      // 'Borrar mi récord de ULima++', que sigue montado detrás del diálogo.
      expect(find.text(AcademicRecordPage.deleteDialogTitle), findsOneWidget);
      expect(find.text(AcademicRecordPage.deleteDialogBody), findsOneWidget);
      expect(find.text(AcademicRecordPage.deleteCancelLabel), findsOneWidget);
      expect(find.text(AcademicRecordPage.deleteConfirmLabel), findsOneWidget);
    });

    testWidgets('cancelar no borra nada', (tester) async {
      final api = await montarConRecord(tester);
      await abrirDialogo(tester);

      await tester.tap(find.text(AcademicRecordPage.deleteCancelLabel));
      await tester.pumpAndSettle();

      expect(api.deleteCalls, 0);
      expect(find.text(AcademicRecordPage.deleteDialogTitle), findsNothing);
      expect(find.byKey(AcademicRecordPage.successViewKey), findsOneWidget);
      expect(find.text('14.62'), findsOneWidget);
    });

    testWidgets('confirmar llama al DELETE y la pantalla pasa al estado vacío',
        (tester) async {
      final api = await montarConRecord(
        tester,
        getResponses: <Object>[_syncedJson(), _neverSyncedJson()],
      );
      final controller = Get.find<AcademicRecordController>();

      // Un ciclo elegido a mano: después de borrar tiene que volver a null,
      // porque ese ciclo ya no existe. Los chips están arriba del todo, así
      // que se tocan antes de bajar al botón.
      await tester.tap(find.byKey(AcademicRecordPage.periodChipKey('2025-2')));
      await tester.pump();
      expect(controller.selectedPeriodCode.value, '2025-2');

      await abrirDialogo(tester);
      await tester.tap(find.text(AcademicRecordPage.deleteConfirmLabel));
      await tester.pumpAndSettle();

      expect(api.deleteCalls, 1);
      expect(api.lastDeletePath, '/academic-record/me');
      expect(api.getCalls, 2); // la recarga que confirma el borrado
      expect(find.text(AcademicRecordPage.emptyTitle), findsOneWidget);
      expect(find.byKey(AcademicRecordPage.successViewKey), findsNothing);
      expect(find.text('14.62'), findsNothing);
      // Ya no hay copia: el botón de borrar desaparece con ella.
      expect(find.byKey(AcademicRecordPage.deleteButtonKey), findsNothing);
      expect(controller.selectedPeriodCode.value, isNull);
      expect(controller.deleting.value, isFalse);
    });

    testWidgets('si el DELETE falla, aviso explícito y el récord sigue ahí',
        (tester) async {
      final api = await montarConRecord(tester);
      final controller = Get.find<AcademicRecordController>();
      api.deleteError = ApiException(
        statusCode: 500,
        code: 'HTTP_ERROR',
        message: 'x',
      );
      await abrirDialogo(tester);

      await tester.tap(find.text(AcademicRecordPage.deleteConfirmLabel));
      await tester.pumpAndSettle();

      expect(api.deleteCalls, 1);
      expect(api.getCalls, 1); // no recargó: no se borró nada
      expect(
        find.text(AcademicRecordService.deleteErrorMessage),
        findsOneWidget,
      );
      expect(find.text('14.62'), findsOneWidget);
      expect(find.byKey(AcademicRecordPage.deleteButtonKey), findsOneWidget);
      // El finally del controller corre también cuando el DELETE falla.
      expect(controller.deleting.value, isFalse);

      // El SnackBar se cierra solo a los 4 s con un Timer. Si el test termina
      // antes, el binding falla con "A Timer is still pending even after the
      // widget tree was disposed".
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('mientras borra, el botón no acepta otro toque',
        (tester) async {
      final api = await montarConRecord(tester);
      final controller = Get.find<AcademicRecordController>();

      // El doble resuelve el DELETE al instante, así que no hay forma de
      // dejarlo colgado desde la UI: se pone la bandera a mano, que es
      // exactamente el estado en el que queda el controller mientras el
      // DELETE va en camino.
      controller.deleting.value = true;
      await tester.pump();

      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(AcademicRecordPage.deleteButtonKey),
            )
            .onPressed,
        isNull,
      );
      // Deshabilitado y nada más: sin indicador animado, que colgaría los
      // pumpAndSettle del resto del archivo.
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Y el guardia del controller impide un segundo DELETE aunque se llame
      // al método directamente.
      await controller.deleteRecord();
      expect(api.deleteCalls, 0);

      controller.deleting.value = false;
      await tester.pump();
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(AcademicRecordPage.deleteButtonKey),
            )
            .onPressed,
        isNotNull,
      );
    });

    testWidgets(
        'RF-REC-5: al volver con back, la tarjeta del Perfil ya no muestra el '
        'PPA ni los créditos borrados', (tester) async {
      // Integración con la tarjeta real y el binding real: lo que se prueba
      // es que las dos pantallas leen el MISMO AcademicRecordService.
      final api = _FakeRecordApi(<Object>[_syncedJson(), _neverSyncedJson()]);
      Get.put<AuthService>(_FakeAuthService(_student()));
      Get.put<AcademicRecordService>(AcademicRecordService(apiClient: api));

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/',
          getPages: [
            GetPage(
              name: '/',
              page: () => const Scaffold(
                body: Padding(
                  padding: EdgeInsets.all(16),
                  child: RecordProfileCard(),
                ),
              ),
            ),
            GetPage(
              name: '/mi-record',
              page: () => const AcademicRecordPage(),
              binding: AcademicRecordBinding(),
            ),
            GetPage(
              name: '/portal-sync',
              page: () => const Scaffold(body: Text('PORTAL SYNC')),
            ),
          ],
        ),
      );
      await tester.pump(); // el postFrameCallback de la tarjeta → load()
      await tester.pump();

      expect(find.text('14.62'), findsOneWidget);
      expect(find.text('197 de 240 créditos'), findsOneWidget);

      await tester.tap(find.byType(RecordProfileCard));
      await tester.pumpAndSettle();

      expect(find.byType(AcademicRecordPage), findsOneWidget);
      expect(api.getCalls, 1); // la pantalla usa la caché del servicio

      await abrirDialogo(tester);
      await tester.tap(find.text(AcademicRecordPage.deleteConfirmLabel));
      await tester.pumpAndSettle();

      expect(api.deleteCalls, 1);
      expect(find.text(AcademicRecordPage.emptyTitle), findsOneWidget);

      Get.back<void>();
      await tester.pumpAndSettle();

      expect(find.text(RecordProfileCard.neverSyncedText), findsOneWidget);
      expect(find.text('14.62'), findsNothing);
      expect(find.text('197 de 240 créditos'), findsNothing);
    });
  });
}
```

Por qué el caso 7 vale lo que cuesta: mientras `/mi-record` está encima, la tarjeta queda en la parte *offstage* del `Overlay` (`_TheatreElement.debugVisitOnstageChildren` no la visita), así que los `find.text` de en medio solo ven la pantalla. Tras el `Get.back<void>()` la tarjeta vuelve a estar a la vista **sin volver a montarse** (`maintainState` de `GetPage` es true y su `initState` no corre de nuevo): si guardara una copia propia del récord en vez de leer el servicio, seguiría pintando `14.62` y `197 de 240 créditos`, y este caso lo cazaría.

- [ ] **Paso 2: Correr la prueba y ver que falla**

```bash
cd . && $FLUTTER test test/HU34_jeff/record_page_test.dart
```

Esperado: **FALLA al compilar**. `AcademicRecordPage` existe, pero ninguna de sus seis constantes nuevas, así que el front end saca un `Member not found` por cada uso —17 en total— y después el archivo no carga:

```
test/HU34_jeff/record_page_test.dart:XXX:YY: Error: Member not found: 'deleteButtonKey'.
        find.byKey(AcademicRecordPage.deleteButtonKey),
                                      ^^^^^^^^^^^^^^^
...
Failed to load "test/HU34_jeff/record_page_test.dart": Compilation failed
```

que `flutter test` resume al final como:

```
00:00 +0 -1: Some tests failed.
```

El reparto de los 17: 7 de `deleteButtonKey`, 4 de `deleteConfirmLabel`, 2 de `deleteDialogTitle`, 2 de `deleteCancelLabel`, 1 de `deleteButtonLabel` y 1 de `deleteDialogBody`. Es el fallo correcto: el archivo no carga, así que en este estado tampoco corren los grupos de las tareas 6 y 7 — vuelven en el Paso 4. Lo que **no** debe salir es un error sobre `RecordProfileCard`, `AcademicRecordBinding`, `AcademicRecordService.deleteErrorMessage` o `AcademicRecordPage.periodChipKey`: eso significaría que la tarea 4, la 6, la 2 o la 7 no están hechas en este árbol, y hay que terminarlas antes de seguir. Si sale `All tests passed!`, alguien ya implementó esta tarea: revisa el árbol antes de tocar nada.

- [ ] **Paso 3: Implementación mínima**

**3.1 · `lib/pages/academic_record/academic_record_controller.dart`** — una sola edición. Reemplazar estas dos líneas (las escribió la tarea 7):

```dart
  /// Un solo ciclo a la vez: el chip que se toca reemplaza al anterior.
  void selectPeriod(String periodCode) => selectedPeriodCode.value = periodCode;
```

por:

```dart
  /// Un solo ciclo a la vez: el chip que se toca reemplaza al anterior.
  void selectPeriod(String periodCode) => selectedPeriodCode.value = periodCode;

  /// Borrado en vuelo (RF-REC-5). Mientras dure, el botón se deshabilita y no
  /// hay spinner: un indicador animado nunca para y colgaría los
  /// `pumpAndSettle` de los tests, igual que `SkeletonPulse`.
  final deleting = false.obs;

  /// Borra la copia del récord guardada en ULima++ (RF-REC-5).
  ///
  /// Relanza [AcademicRecordFailure] tal cual: el controller no sabe pintar
  /// avisos y es la pantalla la que muestra el mensaje. Si sale bien, el
  /// servicio deja el récord vacío, así que el ciclo elegido deja de existir
  /// y vuelve a null; si no, la próxima sincronización abriría en un chip
  /// que ya no está.
  Future<void> deleteRecord() async {
    if (deleting.value) return; // doble toque mientras el DELETE va en camino
    deleting.value = true;
    try {
      await _service.deleteRecord();
      selectedPeriodCode.value = null;
    } finally {
      deleting.value = false;
    }
  }
```

No hacen falta imports nuevos: `AcademicRecordFailure` vive en `../../services/academic_record_service.dart`, que la tarea 6 ya importó, y `.obs` viene de `package:get/get.dart`. El bloque entra entre `selectPeriod` y la estática `periodoSeleccionado`, que es donde deja el cursor el ancla.

**3.2 · `lib/pages/academic_record/academic_record_page.dart`, import.** La página todavía no importa el servicio; lo necesita por `AcademicRecordFailure` en el `catch`. Reemplazar estas dos líneas:

```dart
import '../../models/academic_record_model.dart';
import 'academic_record_controller.dart';
```

por:

```dart
import '../../models/academic_record_model.dart';
import '../../services/academic_record_service.dart';
import 'academic_record_controller.dart';
```

**3.3 · Las seis constantes.** Reemplazar estas dos líneas (las escribió la tarea 7):

```dart
  /// Key de la tarjeta de cursos del ciclo elegido.
  static const Key coursesCardKey = Key('record-courses-card');
```

por:

```dart
  /// Key de la tarjeta de cursos del ciclo elegido.
  static const Key coursesCardKey = Key('record-courses-card');

  /// Borrar mi récord (RF-REC-5). El diálogo dice las tres cosas que el
  /// alumno necesita saber antes de confirmar: qué se borra, qué no cambia y
  /// cómo se recupera.
  static const Key deleteButtonKey = Key('record-delete-button');
  static const String deleteButtonLabel = 'Borrar mi récord de ULima++';
  static const String deleteDialogTitle = 'Borrar mi récord';
  static const String deleteDialogBody =
      'Se borra la copia de tu récord guardada en ULima++. Tu malla no '
      'cambia. Si vuelves a sincronizar con el portal, se guarda de nuevo.';
  static const String deleteConfirmLabel = 'Borrar';
  static const String deleteCancelLabel = 'Cancelar';
```

**3.4 · El botón, último hijo de `_RecordSuccessView`.** El ancla son las últimas líneas del `build` de `_RecordSuccessView` —el cierre del `Obx` de chips y cursos que puso la tarea 7— más la primera línea del comentario de `_PeriodChips`, que la hace única. Reemplazar esto:

```dart
          }),
        ],
      ),
    );
  }
}

/// Fila horizontal de chips de ciclo (RF-REC-2), en el orden del backend: del
```

por esto:

```dart
          }),
          // RF-REC-5: al final de todo, y solo en el estado de éxito. En el
          // vacío no hay copia que borrar, y en el de error no se sabe si la
          // hay.
          const SizedBox(height: 28),
          _DeleteRecordButton(controller: controller),
        ],
      ),
    );
  }
}

/// Fila horizontal de chips de ciclo (RF-REC-2), en el orden del backend: del
```

**3.5 · La clase `_DeleteRecordButton`, al final del archivo.** El ancla son las cuatro últimas líneas de `_CreditsRingPainter`, que cierran el archivo (la tarea 7 metió sus tres clases privadas justo después de `_RecordSuccessView`, así que el painter sigue siendo lo último). Reemplazar esto:

```dart
  @override
  bool shouldRepaint(_CreditsRingPainter old) =>
      old.progress != progress || old.track != track || old.color != color;
}
```

por esto:

```dart
  @override
  bool shouldRepaint(_CreditsRingPainter old) =>
      old.progress != progress || old.track != track || old.color != color;
}

/// Botón destructivo del final de la pantalla (RF-REC-5).
///
/// Mismo estilo que `_LogoutButton` (lib/pages/perfil/perfil.dart:1306-1364):
/// la app ya pide confirmación así para lo que no se deshace.
class _DeleteRecordButton extends StatelessWidget {
  const _DeleteRecordButton({required this.controller});

  final AcademicRecordController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: Obx(() {
        final borrando = controller.deleting.value;
        return OutlinedButton.icon(
          key: AcademicRecordPage.deleteButtonKey,
          // Mientras el DELETE está en vuelo el botón no acepta otro toque.
          // Sin spinner: un indicador animado no para nunca y colgaría los
          // pumpAndSettle de los tests.
          onPressed: borrando ? null : () => _confirmarYBorrar(context),
          icon: const Icon(Icons.delete_outline),
          label: const Text(AcademicRecordPage.deleteButtonLabel),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.redAccent,
            side: const BorderSide(color: Colors.redAccent, width: 1.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      }),
    );
  }

  Future<void> _confirmarYBorrar(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AcademicRecordPage.deleteDialogTitle),
        content: const Text(AcademicRecordPage.deleteDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AcademicRecordPage.deleteCancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              AcademicRecordPage.deleteConfirmLabel,
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    // Cerrar el diálogo con el barrier o con back devuelve null: tampoco borra.
    if (confirmar != true) return;

    try {
      await controller.deleteRecord();
      // Salió bien: el récord queda vacío, la pantalla pinta el estado vacío
      // y este botón se desmonta con él. No hay nada más que avisar.
    } on AcademicRecordFailure catch (e) {
      // ScaffoldMessenger y no Get.snackbar: no necesita Get.testMode y el
      // aviso queda dentro del Scaffold de esta pantalla (mismo criterio que
      // lib/components/avatar/avatar_perfil.dart:132).
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }
}
```

- [ ] **Paso 4: Correr la prueba y ver que pasa**

```bash
cd . && $FLUTTER test test/HU34_jeff/record_page_test.dart
```

Esperado: **PASS**, con los casos de las tareas 6 y 7 más los **7 nuevos** de `WIDGET · Borrar mi récord (RF-REC-5)`:

```
00:00 +32: All tests passed!
```

El número exacto depende de en cuántos `test`/`testWidgets` quedaron divididas las tareas 6 y 7 (32 si fueron 25); lo que tiene que cumplirse es que suba en 7 respecto de la corrida de la tarea 7 y que no quede ningún `-N`.

Diagnóstico si algo falla:
- si el único que falla es **`al volver con back…`**, con `14.62` todavía a la vista, la tarjeta o la pantalla se guardaron una copia del récord en vez de leer `AcademicRecordService`: revisa que `AcademicRecordController.record` siga siendo `=> _service.record` y que el `Obx` de la tarjeta lea `AcademicRecordService.to.record` en cada build;
- si en ese mismo caso falla `expect(api.getCalls, 1)` con 2, la pantalla está forzando la recarga: `AcademicRecordController.onReady` tiene que llamar a `_service.load()` **sin** `force`;
- si falla **`confirmar llama al DELETE…`** con `deleteCalls` en 0, el `showDialog` devolvió null: el `pop(true)` tiene que usar el `ctx` del `builder`, no el `context` del botón;
- si sale `A Timer is still pending even after the widget tree was disposed`, faltó el `pump(const Duration(seconds: 4))` del caso del `SnackBar`;
- si sale `pumpAndSettle timed out`, alguien metió un indicador de progreso animado en el botón: quítalo.

- [ ] **Paso 5: Análisis estático**

```bash
cd . && $FLUTTER analyze lib/pages/academic_record/academic_record_controller.dart lib/pages/academic_record/academic_record_page.dart test/HU34_jeff/record_page_test.dart
```

Esperado: `No issues found! (ran in …)`. El lint que más fácil salta acá es `use_build_context_synchronously`: lo apaga el `if (!context.mounted) return;` que va justo antes del `ScaffoldMessenger`. Si sale algún issue, corrígelo en esos tres archivos y repite los Pasos 4 y 5.

Después, el proyecto entero, para comprobar que el número de issues preexistentes que se anotó en la tarea 1 no subió:

```bash
cd . && $FLUTTER analyze 2>&1 | grep -E "issues? found|academic_record"
```

Esperado: la misma línea `N issues found. (ran in …)` (o `No issues found!`) de la tarea 1, y ninguna línea que nombre `academic_record`. Si esta tarea corre en otra sesión no tienes el reporte de la tarea 1: la línea base está en `$TMP/plan-fe/analyze-baseline.txt`; léela con `cat` y compara sin el `(ran in …)`. Si el número subió, el issue nuevo es de esta tarea: corrígelo.

- [ ] **Paso final: Commit**

Revisa primero que el árbol no tenga cambios ajenos:

```bash
cd . && git status --short --untracked-files=all
```

Esperado, en cualquier orden, exactamente estas tres líneas:

```
 M lib/pages/academic_record/academic_record_controller.dart
 M lib/pages/academic_record/academic_record_page.dart
 M test/HU34_jeff/record_page_test.dart
```

Si aparece otro archivo, no lo agregues ni lo toques: puede ser de otra sesión trabajando en el mismo árbol.

```bash
cd . && git add lib/pages/academic_record/academic_record_controller.dart lib/pages/academic_record/academic_record_page.dart test/HU34_jeff/record_page_test.dart && git diff --cached --stat
```

Esperado: exactamente esos 3 archivos y `3 files changed`.

```bash
cd . && git commit -m "feat(academic-record): borrar mi récord con confirmación"
```

Sin trailer `Co-Authored-By`: el autor ya está configurado en este árbol. Nada de `git push`: eso lo decide el dueño.

### Tarea 9: Pantalla de consentimiento reutilizable (PortalConsentView)

**Archivos:**
- Crear: `lib/components/portal_consent/portal_consent_view.dart` (la carpeta `lib/components/portal_consent/` todavía no existe: este archivo la crea. La spec ya la declara como target en `specs/features/academic-record/academic-record.spec.md:8`, `  - ../../../lib/components/portal_consent/**`)
- Test: `test/HU34_jeff/portal_sync_consent_test.dart` (crear. La carpeta `test/HU34_jeff/` la crea la tarea 1; si corres esta tarea antes, créala al escribir el archivo. La **tarea 10** le agrega imports, dobles y grupos nuevos al final de `main()`, así que este archivo se escribe pensando en que va a crecer: aquí no se define ningún doble de servicio ni se usa GetX)
- No se modifica ningún archivo existente. La spec ya enlaza este test en RF-REC-6 (`specs/features/academic-record/academic-record.spec.md:164`, que pasa a ser la 165 después de que la tarea 2 inserte un `[@test]` nuevo tras la L135), así que esta tarea **no toca la spec ni los docs**. `docs/specs/feature-index.md` lo actualiza la tarea 6, no esta. Portal Sync y Registro todavía no montan este widget: eso es de las tareas 10 y 11.

**Interfaces:**
- Consume: nada de las tareas 1 a 8. Este widget no conoce el récord, ni el servicio, ni los modelos: es texto y dos callbacks. Del repo usa solo el kit público de `lib/pages/password_reset/password_reset_ui.dart`, con import **relativo** `'../../pages/password_reset/password_reset_ui.dart'` (el precedente de un componente que importa de `pages/` es `lib/components/calculadora/add_score.dart:4`, `import '../../pages/calculadora/calculadora_controller.dart';`):
  - `class PasswordResetPalette` (`password_reset_ui.dart:13-97`), de la que se usan `fieldText`, `fieldHint` y `cursor`.
    - **Trampa (`password_reset_ui.dart:50`):** en modo oscuro `buttonBackground` vale `Color(0x00000000)`, transparente. Para íconos se usa `palette.cursor`, como ya hacen `portal_sync_page.dart:187-190` y `registro_page.dart:281-283`.
  - `factory PasswordResetPalette.from(BuildContext context)` (`password_reset_ui.dart:34`), que resuelve claro/oscuro con `Theme.brightnessOf(context)` (`:35`) y por eso necesita un `Theme` encima: en el test lo da el `MaterialApp`.
  - `const PasswordResetScaffold({super.key, required this.palette, required this.child})` (`password_reset_ui.dart:100-105`). Dibuja siempre, en un `Positioned` (`:149-157`), un `IconButton(icon: Icon(Icons.arrow_back, color: palette.backIcon), tooltip: 'Volver', onPressed: () => Navigator.of(context).maybePop())`, y su tarjeta va en un `SingleChildScrollView` (`:119`) con `BoxConstraints(maxWidth: 340)` (`:126-127`) y `EdgeInsets.fromLTRB(32, 36, 32, 32)` de padding interno (`:142`).
  - `const PasswordResetPrimaryButton({super.key, required this.palette, required this.label, required this.loading, required this.onPressed})` (`password_reset_ui.dart:438-445`). `onPressed` es un `VoidCallback` **no nullable** y el botón solo se deshabilita con `loading: true` (`onPressed: loading ? null : onPressed`, `:457`); con `loading: false` pinta `Text(label)` (`:479-486`), que es lo que encuentra `find.text('Acepto')`.
  - No existe widget público de botón secundario: para el enlace de salir se copia el `GestureDetector` + `Text` de `'Ahora no'` en `portal_sync_page.dart:116-125`.
- Produce: `lib/components/portal_consent/portal_consent_view.dart`

```dart
class PortalConsentView extends StatelessWidget {
  const PortalConsentView({super.key, required this.palette, required this.onAccept, required this.onExit, required this.exitLabel});
  final PasswordResetPalette palette;
  final VoidCallback onAccept;
  final VoidCallback onExit;
  final String exitLabel;  // Portal Sync: 'Ahora no'; Registro: 'Volver'
  static const String titulo = 'Antes de entrar a miUlima';
  static const String introduccion = 'Para cargar tus datos, ULima++ entra a miUlima con tu contraseña y trae:';
  static const List<String> datosImportados = <String>['Tus datos: nombre, código, carrera y nivel.', 'Tu ciclo: cursos, secciones, docentes, horarios y matrícula.', 'Tu récord académico: notas históricas, PPA, ubicación relativa y créditos.', 'Tu estado de impedimento y deuda.'];
  static const String finalidad = 'Estos datos se usan solo para mostrártelos a ti.';
  static const String contrasena = 'Tu contraseña se usa una sola vez y no se guarda.';
  static const String botonAceptar = 'Acepto';
}
```

  Es **solo el contenido de la tarjeta**: no trae `Scaffold` ni fondo. Quien lo usa lo monta como `child` de su propio `PasswordResetScaffold`.
  Quién lo usa después: la **tarea 10** (`PortalConsentView(palette:…, exitLabel: 'Ahora no', onAccept: controller.aceptarConsentimiento, onExit: () => Get.back<void>())` en el `case PortalSyncStep.consent` de `portal_sync_page.dart`, y `PortalConsentView.titulo` y `PortalConsentView.botonAceptar` en sus tests) y la **tarea 11** (lo mismo en el `case RegistroPaso.consentimiento`, con `exitLabel: 'Volver'`, usando `PortalConsentView.titulo` y el literal `'Acepto'`).

**Ojo con los nombres:** hoy no existe nada llamado `PortalConsentView` ni ninguna carpeta `portal_consent` en el código. Comprobado: `grep -rn "PortalConsentView\|portal_consent" lib/ test/ docs/ specs/` devuelve una sola línea en todo el repo, `specs/features/academic-record/academic-record.spec.md:8`, la de targets. No hay conflicto con nada.

**Qué NO hace esta tarea:** no toca `PortalSyncStep`, ni `PortalSyncController`, ni `RegistroPaso`, ni ningún servicio, ni manda `consent` a ninguna parte. Este widget no guarda nada: la aceptación no se recuerda entre visitas, y por eso aquí no aparecen `StorageService` ni `shared_preferences`.

- [ ] **Paso 1: Escribir la prueba que falla**

Crear `test/HU34_jeff/portal_sync_consent_test.dart` con este contenido completo:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/components/portal_consent/portal_consent_view.dart';
import 'package:ulima_plus/pages/password_reset/password_reset_ui.dart';

/// Consentimiento antes de dar la contraseña del portal (RF-REC-6).
///
/// Aquí se prueba la pantalla sola: qué dice y a quién llama. Su uso dentro
/// del flujo de Portal Sync lo cubren los grupos del final de este archivo.
/// Todos los valores son inventados.

/// Monta [PortalConsentView] dentro del mismo `PasswordResetScaffold` que
/// usan las dos pantallas reales, para que la tarjeta tenga el ancho de 340 y
/// el scroll de verdad.
Widget _consentApp({
  required VoidCallback onAccept,
  required VoidCallback onExit,
  String exitLabel = 'Ahora no',
}) => MaterialApp(
      home: Builder(
        builder: (context) {
          final palette = PasswordResetPalette.from(context);
          return PasswordResetScaffold(
            palette: palette,
            child: PortalConsentView(
              palette: palette,
              onAccept: onAccept,
              onExit: onExit,
              exitLabel: exitLabel,
            ),
          );
        },
      ),
    );

/// Todo el texto visible de la pantalla, en una sola cadena.
String _textoVisible(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? '')
    .join(' ');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WIDGET · PortalConsentView (RF-REC-6)', () {
    testWidgets('muestra el título, los cuatro datos, la finalidad, la contraseña y los dos botones', (tester) async {
      await tester.pumpWidget(_consentApp(onAccept: () {}, onExit: () {}));
      await tester.pump();

      expect(find.text('Antes de entrar a miUlima'), findsOneWidget);
      expect(
        find.text('Para cargar tus datos, ULima++ entra a miUlima con tu contraseña y trae:'),
        findsOneWidget,
      );
      expect(find.text('Tus datos: nombre, código, carrera y nivel.'), findsOneWidget);
      expect(find.text('Tu ciclo: cursos, secciones, docentes, horarios y matrícula.'), findsOneWidget);
      expect(
        find.text('Tu récord académico: notas históricas, PPA, ubicación relativa y créditos.'),
        findsOneWidget,
      );
      expect(find.text('Tu estado de impedimento y deuda.'), findsOneWidget);
      expect(find.text('Estos datos se usan solo para mostrártelos a ti.'), findsOneWidget);
      expect(find.text('Tu contraseña se usa una sola vez y no se guarda.'), findsOneWidget);
      expect(find.text('Acepto'), findsOneWidget);
      expect(find.text('Ahora no'), findsOneWidget);
    });

    testWidgets('nombra cada dato que se importa, como exige RF-REC-6', (tester) async {
      await tester.pumpWidget(_consentApp(onAccept: () {}, onExit: () {}));
      await tester.pump();

      final texto = _textoVisible(tester);
      for (final dato in const <String>[
        'nombre',
        'código',
        'carrera',
        'nivel',
        'cursos',
        'secciones',
        'docentes',
        'horarios',
        'matrícula',
        'notas históricas',
        'PPA',
        'ubicación relativa',
        'créditos',
        'impedimento',
        'deuda',
      ]) {
        expect(
          texto,
          contains(dato),
          reason: 'la pantalla de consentimiento no nombra "$dato"',
        );
      }
    });

    testWidgets('dice para qué se usan los datos y que la contraseña no se guarda', (tester) async {
      await tester.pumpWidget(_consentApp(onAccept: () {}, onExit: () {}));
      await tester.pump();

      final texto = _textoVisible(tester);
      expect(texto, contains('solo para mostrártelos a ti'));
      expect(texto, contains('se usa una sola vez y no se guarda'));
    });

    testWidgets('no promete que la contraseña nunca sale del portal: es falso', (tester) async {
      await tester.pumpWidget(_consentApp(onAccept: () {}, onExit: () {}));
      await tester.pump();

      expect(_textoVisible(tester), isNot(contains('nunca sale del portal')));
    });

    testWidgets('"Acepto" llama a onAccept una vez y no a onExit', (tester) async {
      var aceptos = 0;
      var salidas = 0;
      await tester.pumpWidget(_consentApp(
        onAccept: () => aceptos++,
        onExit: () => salidas++,
      ));
      await tester.pump();

      // La tarjeta mide 704 px de alto y la pantalla del test 600: 'Acepto'
      // cae fuera (y ≈ 696-719). Sin este ensureVisible, el tap falla.
      await tester.ensureVisible(find.text('Acepto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Acepto'));
      await tester.pump();

      expect(aceptos, 1);
      expect(salidas, 0);
    });

    testWidgets('el botón de salir muestra el exitLabel recibido y llama a onExit', (tester) async {
      var aceptos = 0;
      var salidas = 0;
      await tester.pumpWidget(_consentApp(
        onAccept: () => aceptos++,
        onExit: () => salidas++,
        exitLabel: 'Volver',
      ));
      await tester.pump();

      expect(find.text('Ahora no'), findsNothing);
      // 'Volver' también es el tooltip de la flecha del scaffold, pero un
      // tooltip sin mostrar no crea ningún Text: este es el enlace de salir.
      expect(find.text('Volver'), findsOneWidget);

      await tester.ensureVisible(find.text('Volver'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Volver'));
      await tester.pump();

      expect(salidas, 1);
      expect(aceptos, 0);
    });

    testWidgets('es solo el contenido de la tarjeta: no trae Scaffold propio', (tester) async {
      await tester.pumpWidget(_consentApp(onAccept: () {}, onExit: () {}));
      await tester.pump();

      // Si trajera su propio Scaffold no se podría montar como `child` del
      // PasswordResetScaffold de Portal Sync ni del de Registro.
      expect(
        find.descendant(
          of: find.byType(PortalConsentView),
          matching: find.byType(Scaffold),
        ),
        findsNothing,
      );
      expect(find.byType(PasswordResetScaffold), findsOneWidget);
    });
  });

  group('UNITARIA · textos fijos de PortalConsentView (RF-REC-6)', () {
    test('las constantes que reutilizan Portal Sync y Registro no cambian', () {
      expect(PortalConsentView.titulo, 'Antes de entrar a miUlima');
      expect(PortalConsentView.botonAceptar, 'Acepto');
      expect(PortalConsentView.introduccion,
          'Para cargar tus datos, ULima++ entra a miUlima con tu contraseña y trae:');
      expect(PortalConsentView.finalidad,
          'Estos datos se usan solo para mostrártelos a ti.');
      expect(PortalConsentView.contrasena,
          'Tu contraseña se usa una sola vez y no se guarda.');
      expect(PortalConsentView.datosImportados, hasLength(4));
    });
  });
}
```

Por qué estos casos y no otros: RF-REC-6 (`spec:141-146`) exige cuatro cosas comprobables —la lista de datos, la finalidad, lo de la contraseña y los dos botones— y el bloque "Cambios en otras specs" (`spec:183-187`) exige que la frase "la contraseña nunca sale del portal" desaparezca, por eso el cuarto caso es una aserción negativa. El caso del `exitLabel` y el del "no trae Scaffold propio" son los que cubren el "**una sola** pantalla reutilizada en los dos lugares": si el widget se quedara con su propio `Scaffold` o con un texto de salida fijo, no se podría montar en las dos pantallas. El último grupo fija los literales de los que dependen las tareas 10 y 11, para que un retoque de redacción rompa aquí y no allá.

Dos cosas del estilo del archivo de test, para que nadie las "corrija":
- El bloque `///` que va **después de los imports** y antes del doc de `_consentApp` es el encabezado del archivo y es correcto: `dangling_library_doc_comments` solo salta cuando el doc comment está antes de la primera directiva. Es el mismo patrón de `test/HU33_jeff/api_client_401_test.dart` y `test/HU33_jeff/registro_page_test.dart`. (Comprobado con `dart analyze` sobre los dos casos: con el `///` arriba del `import` sale el issue; debajo, no.)
- Los `ensureVisible` no son decorativos. Medido: `PortalConsentView` ocupa `Size(276.0, 704.0)` y el `Text('Acepto')` cae en `Rect.fromLTRB(351.1, 696.5, 448.9, 719.5)` sobre una pantalla de 800x600.

- [ ] **Paso 2: Correr la prueba y ver que falla**

```bash
cd . && $FLUTTER test test/HU34_jeff/portal_sync_consent_test.dart
```

Esperado: **ninguna prueba llega a ejecutarse**, porque el archivo no compila. El contador se queda en `+0 -1` y la salida termina así:

```
00:00 +0 -1: Some tests failed.

Failing tests:
  …/test/HU34_jeff/portal_sync_consent_test.dart: loading …/test/HU34_jeff/portal_sync_consent_test.dart
```

Antes de eso, el compilador lista, en este orden, los errores que importan:

```
test/HU34_jeff/portal_sync_consent_test.dart:3:8: Error: Error when reading 'lib/components/portal_consent/portal_consent_view.dart': No such file or directory
import 'package:ulima_plus/components/portal_consent/portal_consent_view.dart';
       ^
test/HU34_jeff/portal_sync_consent_test.dart:25:20: Error: Method not found: 'PortalConsentView'.
            child: PortalConsentView(
                   ^^^^^^^^^^^^^^^^^
test/HU34_jeff/portal_sync_consent_test.dart:166:27: Error: Undefined name 'PortalConsentView'.
          of: find.byType(PortalConsentView),
                          ^^^^^^^^^^^^^^^^^
test/HU34_jeff/portal_sync_consent_test.dart:177:14: Error: Undefined name 'PortalConsentView'.
      expect(PortalConsentView.titulo, 'Antes de entrar a miUlima');
             ^^^^^^^^^^^^^^^^^
```

(más un `Undefined name: 'PortalConsentView'` por cada una de las otras constantes del último grupo, L178 a L185).

Ese es el fallo correcto: falta el widget. Si en cambio el error nombrara `PasswordResetScaffold`, `PasswordResetPalette` o `ensureVisible`, el error estaría en el test y hay que arreglarlo antes de seguir.

- [ ] **Paso 3: Implementación mínima**

Crear la carpeta `lib/components/portal_consent/` y dentro el archivo `portal_consent_view.dart` con este contenido completo:

```dart
// lib/components/portal_consent/portal_consent_view.dart
// Pantalla de consentimiento previa a pedirle al alumno la contraseña de
// miUlima. La montan Portal Sync (/portal-sync) y Registro (/registro).

import 'package:flutter/material.dart';

import '../../pages/password_reset/password_reset_ui.dart';

/// Contenido de la única pantalla de consentimiento de la app (RF-REC-6).
///
/// La Ley 29733 pide decirle al alumno qué datos se llevan, para qué y qué
/// pasa con su contraseña **antes** de que la escriba. Los dos lugares donde
/// ULima++ se la pide —Portal Sync y Registro— montan este mismo widget, y los
/// textos viven aquí como constantes para que las dos pantallas digan
/// exactamente lo mismo: si el alumno acepta en una, aceptó lo mismo que en la
/// otra.
///
/// Es solo el contenido de la tarjeta: quien lo usa lo pasa como `child` de su
/// propio [PasswordResetScaffold], igual que `portal_sync_page.dart` hace con
/// sus otros pasos.
///
/// No recuerda nada. La aceptación dura lo que dura la visita, porque se
/// muestra antes de cada importación (RF-REC-6, "Qué NO entra").
class PortalConsentView extends StatelessWidget {
  const PortalConsentView({
    super.key,
    required this.palette,
    required this.onAccept,
    required this.onExit,
    required this.exitLabel,
  });

  final PasswordResetPalette palette;
  final VoidCallback onAccept;
  final VoidCallback onExit;

  /// Texto del enlace para salir: 'Ahora no' en Portal Sync, 'Volver' en
  /// Registro, donde salir es retroceder un paso y no abandonar la pantalla.
  final String exitLabel;

  static const String titulo = 'Antes de entrar a miUlima';
  static const String introduccion =
      'Para cargar tus datos, ULima++ entra a miUlima con tu contraseña y trae:';
  static const List<String> datosImportados = <String>[
    'Tus datos: nombre, código, carrera y nivel.',
    'Tu ciclo: cursos, secciones, docentes, horarios y matrícula.',
    'Tu récord académico: notas históricas, PPA, ubicación relativa y créditos.',
    'Tu estado de impedimento y deuda.',
  ];
  static const String finalidad =
      'Estos datos se usan solo para mostrártelos a ti.';
  static const String contrasena =
      'Tu contraseña se usa una sola vez y no se guarda.';
  static const String botonAceptar = 'Acepto';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.fieldText,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          introduccion,
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.fieldHint, fontSize: 12, height: 1.4),
        ),
        const SizedBox(height: 16),
        for (final dato in datosImportados)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // `palette.cursor` y NO `buttonBackground`: en modo oscuro el
                // fondo del botón es 0x00000000 y el ícono quedaría invisible
                // sobre la tarjeta negra (portal_sync_page.dart:187-190).
                Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: palette.cursor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dato,
                    style: TextStyle(
                      color: palette.fieldText,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Text(
          finalidad,
          style: TextStyle(
            color: palette.fieldText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          contrasena,
          style: TextStyle(
            color: palette.fieldText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        PasswordResetPrimaryButton(
          palette: palette,
          label: botonAceptar,
          loading: false,
          onPressed: onAccept,
        ),
        const SizedBox(height: 14),
        // No hay widget público de botón secundario en el kit: este es el
        // mismo GestureDetector + Text de 'Ahora no' (portal_sync_page.dart:116-125).
        GestureDetector(
          onTap: onExit,
          child: Text(
            exitLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.fieldHint,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
```

Detalles que no son libres:
- El encabezado del archivo va con `//` y no con `///`. Aquí el comentario sí está **antes de la primera directiva**, así que un `///` dispara `dangling_library_doc_comments` de `flutter_lints` 6 y el Paso 5 deja de dar `No issues found!` (comprobado: `info - …:1:1 - Dangling library doc comment. Add a 'library' directive after the library comment.`). El doc comment `///` va pegado a `class PortalConsentView`.
- La finalidad y la frase de la contraseña van **sin** `textAlign: TextAlign.center`: son las dos líneas que el alumno tiene que leer entera, y alineadas a la izquierda se leen como el resto de la lista. El `Column` es `stretch`, así que ocupan todo el ancho igual.
- Los textos son constantes `static const` y no literales sueltos en el `build`: las tareas 10 y 11 los referencian por nombre, y así no hay dos redacciones posibles del mismo consentimiento.
- La lista se recorre con un `for` de colección dentro de `children`, no con `datosImportados.map(...).toList()`: es lo que hace el resto del repo (`portal_sync_page.dart:225`).
- `loading: false` es fijo: este paso no espera a nadie. El botón solo se deshabilita con `loading: true` (`password_reset_ui.dart:457`), así que aquí siempre está activo.
- `onPressed: onAccept` se pasa tal cual, sin envolver: quien decide qué pasa al aceptar es la pantalla que lo monta (tarea 10: `controller.aceptarConsentimiento`).
- Nada de `Get.back()` ni de `Navigator` dentro del widget, ni de `Scaffold`: sale por `onExit`, que en Portal Sync cierra la pantalla y en Registro retrocede un paso. Si esto supiera navegar o trajera su propio andamio, no sería reutilizable (lo fija el caso "no trae Scaffold propio").

- [ ] **Paso 4: Correr la prueba y ver que pasa**

```bash
cd . && $FLUTTER test test/HU34_jeff/portal_sync_consent_test.dart
```

Esperado: PASS, con los 8 casos (7 de widget y 1 unitario):

```
00:0X +8: All tests passed!
```

Ningún `RenderFlex overflowed` en la salida: la tarjeta va dentro del `SingleChildScrollView` del scaffold y cada texto de la lista va en un `Expanded`.

Después, la carpeta entera de la HU, para comprobar que nada de las tareas anteriores se rompió:

```bash
cd . && $FLUTTER test test/HU34_jeff/
```

Esperado: `All tests passed!`.

- [ ] **Paso 5: Análisis estático**

```bash
cd . && $FLUTTER analyze lib/components/portal_consent/portal_consent_view.dart test/HU34_jeff/portal_sync_consent_test.dart
```

Esperado: `No issues found! (ran in …)`. Si sale algún issue, corrígelo en esos dos archivos y repite los pasos 4 y 5.

Y el proyecto entero, para comprobar que el número de issues preexistentes que anotaste en la tarea 1 no subió:

```bash
cd . && $FLUTTER analyze 2>&1 | grep -E "issues? found|portal_consent"
```

Esperado: la misma línea `N issues found. (ran in …)` (o `No issues found!`) que anotaste en la tarea 1, y ninguna línea que nombre `portal_consent`. Si esta tarea corre en otra sesión no tienes ese reporte: la línea base está en `$TMP/plan-fe/analyze-baseline.txt`; léela con `cat` y compara sin el `(ran in …)`. Si el número subió, el issue nuevo es de esta tarea: corrígelo.

- [ ] **Paso final: Commit**

Revisa primero que el árbol no tenga cambios ajenos:

```bash
cd . && git status --short --untracked-files=all
```

Esperado, si vienes de la tarea 8 con todo commiteado, exactamente estas dos líneas (en cualquier orden):

```
?? lib/components/portal_consent/portal_consent_view.dart
?? test/HU34_jeff/portal_sync_consent_test.dart
```

Si aparece otro archivo, no lo agregues ni lo toques: puede ser de otra sesión.

```bash
cd . && git add lib/components/portal_consent/portal_consent_view.dart test/HU34_jeff/portal_sync_consent_test.dart && git diff --cached --stat
```

Esperado: exactamente esos 2 archivos y `2 files changed`.

```bash
cd . && git commit -m "feat(academic-record): pantalla de consentimiento antes de dar la contraseña del portal"
```

El autor ya está configurado en git. El mensaje no lleva trailer `Co-Authored-By`. No hagas push.

### Tarea 10: Portal Sync: paso de consentimiento y `consent: true` en la importación

**Archivos:**
- Modificar: `lib/pages/portal_sync/portal_sync_controller.dart:11-12` (enum), `:43-46` (estado inicial y campo nuevo), `:48-51` (método nuevo), `:61-63` (guarda en `submit()`), `:81` (llamada a `import`)
- Modificar: `lib/pages/portal_sync/portal_sync_page.dart:4-5` (imports), `:10-12` (doc), `:25-26` (caso nuevo del `switch`)
- Modificar: `lib/services/portal_sync_service.dart:46-54` (doc y firma de `import()`) y `:59-61` (body). **Ojo:** la tarea 2 mete tres líneas al bloque de imports de este archivo (`package:get/get.dart`, una línea en blanco y `academic_record_service.dart`), así que si ya corrió, estos bloques están en `:49-57` y `:62-64`. Por eso abajo se dan anclas literales y no números.
- Modificar: `test/HU31_jeff/portal_sync_test.dart:70` y `:82` (código de alumno real → `'20230001'`), `:75`, `:90`, `:110` y `:123` (`consent: false` en las cuatro llamadas a `.import(...)`)
- Modificar: `specs/features/portal-sync/portal-sync.spec.md:78-79`, `:83` y `:112`
- Modificar: `docs/specs/api-contracts.md:482` (sub-bullet nuevo del Body de `POST /portal-sync/import`). La tarea 2 solo **añade una sección al final** de este archivo (reemplaza la L499, que es la última), así que la 482 no se corre: comprobado en el plan de la tarea 2.
- Test: `test/HU34_jeff/portal_sync_consent_test.dart` (**modificar**: lo creó la tarea 9; aquí se agregan imports arriba, dobles antes de `main()` y tres grupos al final de `main()`. **No se toca ningún grupo de la tarea 9.**)

**Precondición:** las tareas 2 y 9 ya tienen su commit. Comprobarlo antes de empezar:

```bash
cd . && ls lib/components/portal_consent/portal_consent_view.dart test/HU34_jeff/portal_sync_consent_test.dart && git status --short
```

Deben existir los dos archivos y el árbol debe estar limpio. Todo se hace en `.`, rama `feat/record-academico-fe`, editando con Edit sobre las anclas literales de abajo. Nada de `cp`, `mv` ni `git stash`.

**Interfaces:**
- Consume:
  - Tarea 9, `lib/components/portal_consent/portal_consent_view.dart`: `const PortalConsentView({super.key, required PasswordResetPalette palette, required VoidCallback onAccept, required VoidCallback onExit, required String exitLabel})`; `static const String PortalConsentView.titulo = 'Antes de entrar a miUlima'`; `static const String PortalConsentView.botonAceptar = 'Acepto'`. Es solo el contenido de la tarjeta: se monta como `child` de un `PasswordResetScaffold` ajeno.
  - Tarea 2: `PortalSyncService.refreshAfterImport({String? token})` ya recarga `AcademicRecordService`, con `Get.isRegistered` y su propio `try`. **Aquí no se toca.**
  - `lib/pages/portal_sync/portal_sync_controller.dart:33-34`: `PortalSyncController({PortalSyncService? service}) : _service = service ?? PortalSyncService();` (la clase abre en `:32`), con `passwordCtrl`, `passcodeCtrl` (`:40-41`), `step` (`:43`), `errorMessage` (`:44`), `bool get cargando` (`:48`) y `Future<void> submit() async` (`:61`).
  - `lib/pages/portal_sync/portal_sync_binding.dart:8-13`: `class PortalSyncBinding extends Bindings` con `Get.lazyPut<PortalSyncController>(PortalSyncController.new);`. Es **`lazyPut` sin `fenix`**: con el `SmartManagement.full` por defecto, `GetPageRoute.dispose()` llama a `RouterReportManager.reportRouteDispose`, que **borra la dependencia de forma síncrona** (`router_report.dart:51-56` → `_removeDependencyByRoute`, get 4.7.3). Salir de la ruta destruye el controller y cada entrada construye uno nuevo. De ahí sale gratis el "salir y volver a entrar pide la aceptación de nuevo".
  - `lib/pages/portal_sync/portal_sync_page.dart:16-17`: `class PortalSyncPage extends GetView<PortalSyncController>` con `const PortalSyncPage({super.key})`.
  - `lib/services/portal_sync_service.dart:20`: `PortalSyncService({ApiClient? apiClient})`; `:146-154`: `class PortalSyncFailure implements Exception { const PortalSyncFailure(this.message, {this.code}); final String message; final String? code; }`.
  - `lib/services/api_client.dart:41-43`: `class ApiClient` con `ApiClient({String? configuredBaseUrl})`; `:83-89`: `Future<Map<String, dynamic>> postJson(String path, {required Map<String, dynamic> body, String? token})` (`getJson` es `:68-81`, y esta tarea no lo usa); `:10-25`: `class ApiException implements Exception` con `ApiException({required this.statusCode, required this.code, required this.message, this.details})` en `:11-16`, constructor **no** `const`.
  - `lib/pages/password_reset/password_reset_ui.dart:34`: `factory PasswordResetPalette.from(BuildContext context)`. Ningún widget de ese kit usa `autofocus` (comprobado: `grep -n autofocus` no devuelve nada en el archivo), así que en las pruebas de widget no hay temporizador de cursor y `pumpAndSettle` siempre asienta.
  - GetX 4.7.3: `StreamSubscription<T> listen(void Function(T) onData, {...})` de `NotifyManager` (`rx_impl.dart:166-180`) **no** emite el valor actual al suscribirse —eso lo hace `listenAndPump` (`:120-132`)—, que es justo lo que necesita el caso 5. `Get.testMode` solo desactiva la aserción de `addKey` (`extension_navigation.dart:1097`): la navegación por rutas funciona igual. `void reset({bool clearRouteBindings = true})` se usa ya como tear-off en `tearDown(Get.reset)` en el repo.
  - `lib/main.dart:210-214`: `GetPage(name: '/portal-sync', page: () => const PortalSyncPage(), binding: PortalSyncBinding())`. **No se modifica**: la ruta y el binding ya son los correctos.
- Produce:
  - `lib/pages/portal_sync/portal_sync_controller.dart`:
    ```dart
    enum PortalSyncStep { consent, form, loading, done }   // consent es el PRIMERO
    final step = PortalSyncStep.consent.obs;               // estado inicial
    final consentimientoAceptado = false.obs;
    void aceptarConsentimiento();  // consentimientoAceptado = true, errorMessage = null, step = form
    ```
    y `submit()` sin aceptación no llama al servicio y deja `step = PortalSyncStep.consent`.
  - `lib/services/portal_sync_service.dart`:
    ```dart
    Future<PortalSyncResult> import({
      required String password,
      required String passcode,
      required bool consent,
    })
    ```
    con body `{'credentials': {'password': password, 'passcode': passcode}, if (consent) 'consent': true}`.
  - Quién lo usa después: la **tarea 11** copia el mismo patrón en Registro, pero no importa nada de aquí: `RegistroPaso.consentimiento` y `RegistroService.registrar(..., required bool consent)` son suyos.

**Las tres puertas a `/portal-sync` quedan cubiertas sin tocarlas.** `home_page.dart:171`, `perfil/perfil.dart:653` y `descripcion_cursos/descrip_cursos.dart:290` entran todas con `Get.toNamed<dynamic>('/portal-sync')`, así que el paso de consentimiento aparece en las tres. Eso cierra BR-SYNC-F-07 ("Repetir desde Perfil … incluido el consentimiento") sin ningún cambio extra.

**Datos de prueba:** todos inventados. Alumno sintético `'20230001'`, `'Alumna De Prueba'`, carrera `'CARRERA DE PRUEBA'`, contraseña `'clave'`, passcode `'123456'`, ciclo `'2026-2'`. Ningún valor sale de `test/HU31_jeff/fixtures` ni de `spike-portal/`.

---

- [ ] **Paso 1: Escribir la prueba que falla**

El archivo `test/HU34_jeff/portal_sync_consent_test.dart` ya existe (tarea 9). Se le hacen **tres inserciones**, sin tocar nada más.

**1.1 Imports.** Reemplazar el bloque de imports de la cabecera:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/components/portal_consent/portal_consent_view.dart';
import 'package:ulima_plus/pages/password_reset/password_reset_ui.dart';
```

por esto:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/portal_consent/portal_consent_view.dart';
import 'package:ulima_plus/pages/password_reset/password_reset_ui.dart';
import 'package:ulima_plus/pages/portal_sync/portal_sync_binding.dart';
import 'package:ulima_plus/pages/portal_sync/portal_sync_controller.dart';
import 'package:ulima_plus/pages/portal_sync/portal_sync_page.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/portal_sync_service.dart';
```

**1.2 Dobles y helpers.** Reemplazar esto (las dos líneas con que arranca `main()`):

```dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
```

por esto:

```dart
/// `ApiClient` falso para el POST de la importación. Cuenta las llamadas y
/// guarda el último body, que es lo que esta tarea tiene que comprobar.
class _FakePortalApi extends ApiClient {
  _FakePortalApi({this.respuesta, this.error})
      : super(configuredBaseUrl: 'http://test');

  final Map<String, dynamic>? respuesta;
  final Object? error;

  int posts = 0;
  Map<String, dynamic>? ultimoBody;

  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    posts++;
    ultimoBody = body;
    if (error != null) throw error!;
    return respuesta ?? <String, dynamic>{};
  }
}

/// Respuesta de una importación que salió bien. Todo inventado; el código
/// `20230001` es el alumno sintético del repo.
Map<String, dynamic> _importOk() => <String, dynamic>{
      'period': {'id': 2, 'code': '2026-2'},
      'identity': {
        'portalCode': '20230001',
        'fullName': 'Alumna De Prueba',
        'career': 'CARRERA DE PRUEBA',
      },
      'summary': {'enrollmentsUpserted': 5},
      'warnings': <dynamic>[],
    };

/// Controller con el formulario ya llenado, construido a mano y sin `Get.put`.
///
/// En el camino exitoso, `refreshAfterImport` y `_refrescarPantallas` no
/// revientan sin servicios registrados: todo lo suyo va dentro de un `try` o
/// detrás de `Get.isRegistered`. Como `_importOk()` no trae `token`, el
/// `replaceToken` ni se intenta (`portal_sync_service.dart:129`).
PortalSyncController _controller(_FakePortalApi api) {
  final c = PortalSyncController(service: PortalSyncService(apiClient: api));
  c.passwordCtrl.text = 'clave';
  c.passcodeCtrl.text = '123456';
  return c;
}

/// Ruta y binding REALES de `/portal-sync`, para que el paso inicial y el
/// reinicio al volver a entrar se prueben como los vive el alumno. No hay red:
/// ninguna prueba de este grupo toca 'Cargar mis datos'.
Widget _portalApp() => GetMaterialApp(
      initialRoute: '/inicio',
      getPages: [
        GetPage(
          name: '/inicio',
          page: () => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Get.toNamed<dynamic>('/portal-sync'),
                child: const Text('ABRIR'),
              ),
            ),
          ),
        ),
        GetPage(
          name: '/portal-sync',
          page: () => const PortalSyncPage(),
          binding: PortalSyncBinding(),
        ),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
```

**1.3 Los tres grupos nuevos, al final de `main()`.** Reemplazar el final del archivo:

```dart
      expect(PortalConsentView.datosImportados, hasLength(4));
    });
  });
}
```

por esto:

```dart
      expect(PortalConsentView.datosImportados, hasLength(4));
    });
  });

  group('UNITARIA · PortalSyncController consentimiento (RF-REC-6)', () {
    test('caso 1: arranca en el consentimiento y sin aceptación', () {
      final c = _controller(_FakePortalApi(respuesta: _importOk()));

      expect(c.step.value, PortalSyncStep.consent);
      expect(c.consentimientoAceptado.value, isFalse);
    });

    test('caso 2: submit() sin aceptar no manda nada y se queda en consent', () async {
      final api = _FakePortalApi(respuesta: _importOk());
      final c = _controller(api);

      await c.submit();

      expect(api.posts, 0,
          reason: 'sin aceptación no puede salir ninguna petición');
      expect(c.step.value, PortalSyncStep.consent);
    });

    test('caso 3: aceptarConsentimiento() abre el formulario', () {
      final c = _controller(_FakePortalApi(respuesta: _importOk()));

      c.aceptarConsentimiento();

      expect(c.consentimientoAceptado.value, isTrue);
      expect(c.step.value, PortalSyncStep.form);
      expect(c.errorMessage.value, isNull);
    });

    test('caso 4: tras aceptar, el body lleva consent: true en el nivel superior', () async {
      final api = _FakePortalApi(respuesta: _importOk());
      final c = _controller(api);

      c.aceptarConsentimiento();
      await c.submit();

      expect(api.posts, 1);
      expect(api.ultimoBody!['consent'], isTrue);
      expect(api.ultimoBody!.keys.toSet(), equals({'credentials', 'consent'}),
          reason: 'consent va AL LADO de credentials, nunca dentro');
      expect(
        (api.ultimoBody!['credentials'] as Map<String, dynamic>).keys.toSet(),
        equals({'password', 'passcode'}),
      );
      expect(c.step.value, PortalSyncStep.done);
    });

    test('caso 5: un fallo vuelve al formulario sin volver a pedir la aceptación', () async {
      final api = _FakePortalApi(
        error: ApiException(
          statusCode: 409,
          code: 'PORTAL_LOGIN_REJECTED',
          message: 'x',
        ),
      );
      final c = _controller(api);
      c.aceptarConsentimiento();

      // Se anotan TODOS los estados por los que pasa desde que aceptó: la
      // prueba es que `consent` no vuelve a aparecer en esta visita. `listen`
      // de GetX no reemite el valor actual (eso es `listenAndPump`), así que
      // `vistos` son exactamente los cambios posteriores a la aceptación.
      final vistos = <PortalSyncStep>[];
      final sub = c.step.listen(vistos.add);

      await c.submit();

      expect(api.posts, 1);
      expect(c.step.value, PortalSyncStep.form);
      expect(c.consentimientoAceptado.value, isTrue);
      expect(c.errorMessage.value, isNotNull);

      // El catch limpia el passcode porque ya caducó; el alumno escribe otro.
      c.passcodeCtrl.text = '123456';
      await c.submit();

      expect(api.posts, 2,
          reason: 'el segundo intento sale sin volver a aceptar');
      expect(vistos, isNot(contains(PortalSyncStep.consent)));
      await sub.cancel();
    });

    test('caso 6: una visita nueva vuelve a empezar por el consentimiento', () {
      final primera = _controller(_FakePortalApi(respuesta: _importOk()));
      primera.aceptarConsentimiento();
      expect(primera.step.value, PortalSyncStep.form);

      // PortalSyncBinding usa lazyPut SIN fenix: salir de la ruta borra el
      // controller y volver a entrar construye otro desde cero.
      final segunda = _controller(_FakePortalApi(respuesta: _importOk()));

      expect(segunda.step.value, PortalSyncStep.consent);
      expect(segunda.consentimientoAceptado.value, isFalse);
    });
  });

  group('UNITARIA · PortalSyncService.import consent', () {
    test('caso 7: con consent false la clave no viaja en el body', () async {
      final api = _FakePortalApi(respuesta: _importOk());

      await PortalSyncService(apiClient: api)
          .import(password: 'c', passcode: '123456', consent: false);

      expect(api.ultimoBody!.keys.toSet(), equals({'credentials'}));
      expect(api.ultimoBody!.containsKey('consent'), isFalse,
          reason: 'nunca se manda consent: false (RS-BE-29)');
    });
  });

  group('WIDGET · PortalSyncPage con consentimiento', () {
    setUp(() => Get.testMode = true);
    tearDown(Get.reset);

    testWidgets('caso 8: /portal-sync arranca en el consentimiento, no en el formulario', (tester) async {
      await tester.pumpWidget(_portalApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle();

      expect(find.text(PortalConsentView.titulo), findsOneWidget);
      expect(find.text('Carga tus datos del ciclo'), findsNothing);
      expect(find.text('Contraseña de miUlima'), findsNothing);
    });

    testWidgets('caso 9: "Acepto" muestra el formulario de credenciales', (tester) async {
      await tester.pumpWidget(_portalApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle();

      // La tarjeta del consentimiento es más alta que la pantalla del test
      // (704 px medidos en la tarea 9, contra 600): sin ensureVisible el tap
      // sobre 'Acepto' falla.
      await tester.ensureVisible(find.text(PortalConsentView.botonAceptar));
      await tester.pumpAndSettle();
      await tester.tap(find.text(PortalConsentView.botonAceptar));
      await tester.pump();

      expect(find.text('Carga tus datos del ciclo'), findsOneWidget);
      expect(find.text(PortalConsentView.titulo), findsNothing);
    });

    testWidgets('caso 10: "Ahora no" en el consentimiento cierra la pantalla', (tester) async {
      await tester.pumpWidget(_portalApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Ahora no'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ahora no'));
      await tester.pumpAndSettle();

      // Vuelve a /inicio. home_page.dart:171 recibe null y no refresca nada,
      // que es lo correcto: no hubo importación.
      expect(find.text('ABRIR'), findsOneWidget);
      expect(find.text(PortalConsentView.titulo), findsNothing);
    });

    testWidgets('caso 11: salir y volver a entrar pide la aceptación de nuevo', (tester) async {
      await tester.pumpWidget(_portalApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text(PortalConsentView.botonAceptar));
      await tester.pumpAndSettle();
      await tester.tap(find.text(PortalConsentView.botonAceptar));
      await tester.pump();
      expect(find.text('Carga tus datos del ciclo'), findsOneWidget);

      // Ya en el formulario, se sale por su propio 'Ahora no'. Ningún campo
      // del formulario tiene foco (nadie escribió ni tocó uno) y el kit no usa
      // `autofocus`, así que no hay cursor parpadeando y pumpAndSettle asienta.
      await tester.ensureVisible(find.text('Ahora no'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ahora no'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle();

      expect(find.text(PortalConsentView.titulo), findsOneWidget);
      expect(find.text('Carga tus datos del ciclo'), findsNothing);
    });
  });
}
```

Por qué estos casos y no otros: RF-REC-6 (`academic-record.spec.md:148-151`) pide cuatro cosas comprobables y cada una tiene su caso. "`consent` es el estado inicial" → casos 1 y 8. "El formulario solo aparece tras tocar Acepto" → casos 2, 3 y 9. "Si la importación falla se vuelve a `form` sin volver a pedir la aceptación dentro de la misma visita" → caso 5, que por eso registra la secuencia de estados y no solo el estado final. "Salir y volver a entrar la pide otra vez" → casos 6 (unitario) y 11 (con el binding real, que es donde se ve de verdad); entre los dos cubren también el "Qué NO entra: no se recuerda el consentimiento entre importaciones" (`spec:196`). `spec:157-159` pide `consent: true` en el body → casos 4 y 7, y el 7 es el que fija que **nunca** se manda `false`. El caso 10 existe porque salir desde el consentimiento tiene que devolver `null` a `home_page.dart:171`, no `true`.

- [ ] **Paso 2: Correr la prueba y ver que falla**

```bash
cd . && $FLUTTER test test/HU34_jeff/portal_sync_consent_test.dart
```

Esperado: **ninguna prueba llega a ejecutarse**, porque el archivo no compila. El contador se queda en `+0 -1` y la salida termina con:

```
00:00 +0 -1: Some tests failed.

Failing tests:
  …/test/HU34_jeff/portal_sync_consent_test.dart: loading …/test/HU34_jeff/portal_sync_consent_test.dart
```

Antes de eso el compilador nombra los **cuatro** símbolos que faltan, uno por cada cosa que implementa el Paso 3 (cada uno se repite una vez por cada uso; `PortalSyncStep.consent` sale cuatro veces, en los casos 1, 2, 5 y 6):

```
test/HU34_jeff/portal_sync_consent_test.dart: Error: Member not found: 'consent'.
      expect(c.step.value, PortalSyncStep.consent);
                                          ^^^^^^^
test/HU34_jeff/portal_sync_consent_test.dart: Error: The getter 'consentimientoAceptado' isn't defined for the class 'PortalSyncController'.
      expect(c.consentimientoAceptado.value, isFalse);
               ^^^^^^^^^^^^^^^^^^^^^^
test/HU34_jeff/portal_sync_consent_test.dart: Error: The method 'aceptarConsentimiento' isn't defined for the class 'PortalSyncController'.
      c.aceptarConsentimiento();
        ^^^^^^^^^^^^^^^^^^^^^
test/HU34_jeff/portal_sync_consent_test.dart: Error: No named parameter with the name 'consent'.
          .import(password: 'c', passcode: '123456', consent: false);
                                                     ^^^^^^^
```

Ese es el fallo correcto: faltan el valor del enum, el campo, el método y el parámetro. Si en cambio el error nombrara `PortalConsentView`, `PortalSyncBinding`, `PortalSyncPage` o `ApiException`, el problema está en los imports del test o falta la tarea 9: detente y arréglalo antes de seguir.

- [ ] **Paso 3: Implementación mínima**

Los tres archivos se editan seguidos y **sin correr nada en medio**: en cuanto 3.1(a) agrega `consent` al enum, el `switch` de `portal_sync_page.dart` deja de ser exhaustivo y el proyecto no compila hasta 3.3(c).

**3.1 `lib/pages/portal_sync/portal_sync_controller.dart`**, cinco reemplazos exactos.

(a) Líneas 11-12, el enum. Reemplazar esto:

```dart
/// En qué punto del flujo está la pantalla.
enum PortalSyncStep { form, loading, done }
```

por esto:

```dart
/// En qué punto del flujo está la pantalla.
///
/// `consent` va PRIMERO y es el estado inicial (RF-REC-6): el formulario de
/// credenciales no se dibuja hasta que el alumno acepta.
enum PortalSyncStep { consent, form, loading, done }
```

(b) Líneas 43-46, el estado inicial y el campo nuevo. Reemplazar esto:

```dart
  final step = PortalSyncStep.form.obs;
  final errorMessage = RxnString();
  final passwordVisible = false.obs;
  final Rx<PortalSyncResult?> result = Rx<PortalSyncResult?>(null);
```

por esto:

```dart
  final step = PortalSyncStep.consent.obs;
  final errorMessage = RxnString();
  final passwordVisible = false.obs;
  final Rx<PortalSyncResult?> result = Rx<PortalSyncResult?>(null);

  /// Si el alumno ya aceptó el consentimiento EN ESTA VISITA. No se guarda en
  /// `StorageService` ni en `shared_preferences` a propósito (RF-REC-6, "Qué
  /// NO entra"): se pregunta antes de cada importación.
  final consentimientoAceptado = false.obs;
```

(c) Líneas 48-51, el método nuevo. Reemplazar esto:

```dart
  bool get cargando => step.value == PortalSyncStep.loading;

  @override
  void onClose() {
```

por esto:

```dart
  bool get cargando => step.value == PortalSyncStep.loading;

  /// RF-REC-6: el alumno aceptó la pantalla de consentimiento. Dura lo que dura
  /// este controller, es decir, una visita a /portal-sync: PortalSyncBinding usa
  /// lazyPut sin fenix, así que salir y volver a entrar la pide de nuevo.
  void aceptarConsentimiento() {
    consentimientoAceptado.value = true;
    errorMessage.value = null;
    step.value = PortalSyncStep.form;
  }

  @override
  void onClose() {
```

(d) Líneas 61-63, la guarda de `submit()`. Reemplazar esto:

```dart
  Future<void> submit() async {
    if (cargando) return;
    final password = passwordCtrl.text;
```

por esto:

```dart
  Future<void> submit() async {
    if (cargando) return;
    // Sin aceptación no se envía nada (RF-REC-6).
    if (!consentimientoAceptado.value) {
      step.value = PortalSyncStep.consent;
      return;
    }
    final password = passwordCtrl.text;
```

(e) Línea 81, la llamada al servicio. Reemplazar esto:

```dart
      final r = await _service.import(password: password, passcode: passcode);
```

por esto:

```dart
      final r = await _service.import(
        password: password,
        passcode: passcode,
        consent: consentimientoAceptado.value,
      );
```

Lo que **no** se toca en este archivo:
- El `on PortalSyncFailure catch (e)` de las líneas 91-98: ya deja `step = PortalSyncStep.form` y no mira `consentimientoAceptado`, que es exactamente lo que pide "sin volver a pedir la aceptación".
- `volverAlFormulario()` (`:130-133`), que pondría `step = form` saltándose el consentimiento: hoy no lo llama nadie (`grep -rn "volverAlFormulario" lib/ test/` devuelve solo su definición). Es código muerto y quitarlo o retocarlo metería un cambio ajeno en este commit.
- El agujero conocido de que solo se atrapa `PortalSyncFailure` (documentado en `registro_controller.dart:205`): está fuera de alcance.

**3.2 `lib/services/portal_sync_service.dart`**, dos reemplazos exactos.

(a) Doc y firma de `import()` (líneas 46-54 hoy; 49-57 si la tarea 2 ya corrió). Reemplazar esto:

```dart
  /// Importa usando las credenciales de miUlima.
  ///
  /// Devuelve el resultado, o lanza [PortalSyncFailure] con un mensaje ya listo
  /// para mostrar. Nunca lanza `ApiException` cruda: la pantalla no debería
  /// tener que conocer los códigos del backend.
  Future<PortalSyncResult> import({
    required String password,
    required String passcode,
  }) async {
```

por esto:

```dart
  /// Importa usando las credenciales de miUlima.
  ///
  /// Devuelve el resultado, o lanza [PortalSyncFailure] con un mensaje ya listo
  /// para mostrar. Nunca lanza `ApiException` cruda: la pantalla no debería
  /// tener que conocer los códigos del backend.
  ///
  /// [consent] es la aceptación de la pantalla de consentimiento (RF-REC-6).
  /// Con `true` el body lleva `'consent': true` y el backend guarda el récord
  /// académico (RS-BE-29); con `false` la clave no viaja. Es `required` para
  /// que ninguna pantalla nueva se olvide de decidirlo.
  Future<PortalSyncResult> import({
    required String password,
    required String passcode,
    required bool consent,
  }) async {
```

(b) El body (líneas 59-61 hoy; 62-64 tras la tarea 2). Reemplazar esto:

```dart
            body: {
              'credentials': {'password': password, 'passcode': passcode},
            },
```

por esto:

```dart
            body: {
              'credentials': {'password': password, 'passcode': passcode},
              // Nivel SUPERIOR del body, nunca dentro de 'credentials'.
              // RS-BE-29: solo `true` o ausente; nunca se manda `false`. El
              // backend viejo lo descarta sin error porque `importSchema` es
              // un `z.object` no estricto (backend portal-sync.schemas.ts:36).
              if (consent) 'consent': true,
            },
```

**3.3 `lib/pages/portal_sync/portal_sync_page.dart`**, tres reemplazos exactos.

(a) Imports, líneas 4-5. Reemplazar esto:

```dart
import '../../models/portal_sync_models.dart';
import '../password_reset/password_reset_ui.dart';
```

por esto:

```dart
import '../../components/portal_consent/portal_consent_view.dart';
import '../../models/portal_sync_models.dart';
import '../password_reset/password_reset_ui.dart';
```

(b) Doc, líneas 10-12. Reemplazar esto:

```dart
/// Una sola pantalla con tres estados (formulario, cargando, resumen) en vez de
/// tres rutas: el flujo es lineal y el alumno no gana nada pudiendo volver al
/// paso anterior con el botón del sistema mientras la carga corre.
```

por esto:

```dart
/// Una sola pantalla con cuatro estados (consentimiento, formulario, cargando,
/// resumen) en vez de cuatro rutas: el flujo es lineal y el alumno no gana nada
/// pudiendo volver al paso anterior con el botón del sistema mientras la carga
/// corre.
```

(c) El `switch`, líneas 25-26. Es un statement sin `default`, así que el caso nuevo es obligatorio para que compile. Reemplazar esto:

```dart
        switch (controller.step.value) {
          case PortalSyncStep.loading:
```

por esto:

```dart
        switch (controller.step.value) {
          case PortalSyncStep.consent:
            // Salir desde aquí devuelve null a home_page.dart:171, que no
            // refresca el banner: no hubo importación, y eso es lo correcto.
            return PortalConsentView(
              palette: palette,
              exitLabel: 'Ahora no',
              onAccept: controller.aceptarConsentimiento,
              onExit: () => Get.back<void>(),
            );
          case PortalSyncStep.loading:
```

- [ ] **Paso 4: Correr la prueba y ver que pasa**

```bash
cd . && $FLUTTER test test/HU34_jeff/portal_sync_consent_test.dart
```

Esperado: **PASS**, con los 19 casos (los 8 de la tarea 9 más los 11 de esta):

```
00:0X +19: All tests passed!
```

Sin ningún `RenderFlex overflowed` en la salida: tanto el consentimiento como el formulario van dentro del `SingleChildScrollView` de `PasswordResetScaffold` (`password_reset_ui.dart:119`).

- [ ] **Paso 5: Reparar `test/HU31_jeff/portal_sync_test.dart`, que la firma nueva rompe**

Ese archivo llama a `.import(...)` sin `consent` en cuatro sitios, así que ahora no compila. Además tiene un código de alumno REAL en dos líneas, y el repo es público: se cambia por el sintético en la misma pasada.

**5.1 El código real de las líneas 70 y 82.** No lo transcribas a ningún otro archivo ni al mensaje del commit. Sustitúyelo en el sitio:

```bash
cd . && perl -i -pe "s/'\\d{8}'/'20230001'/ if \$. == 70 || \$. == 82" test/HU31_jeff/portal_sync_test.dart
```

Comprobar que solo cambiaron esas dos líneas y que el archivo ya no contiene ningún otro código de ocho dígitos:

```bash
cd . && git diff --numstat test/HU31_jeff/portal_sync_test.dart && grep -oE "20[0-9]{6}" test/HU31_jeff/portal_sync_test.dart | sort -u
```

Esperado: `2	2	test/HU31_jeff/portal_sync_test.dart` y exactamente una línea, `20230001`. Y las dos líneas deben quedar así:

```dart
        'identity': {'portalCode': '20230001', 'fullName': 'X', 'career': 'Y'},
```
```dart
      expect(api.ultimoBody.toString(), isNot(contains('20230001')));
```

La segunda sigue siendo una aserción real: el body solo lleva `credentials` (y ahora `consent`), nunca el código del alumno.

**5.2 Las cuatro llamadas a `.import(...)`.** Cuatro reemplazos exactos; las dos últimas se distinguen solo por la indentación, por eso van con las líneas de alrededor.

(a) Línea 75. Reemplazar esto:

```dart
          .import(password: 'clave', passcode: '123456');
```

por esto:

```dart
          .import(password: 'clave', passcode: '123456', consent: false);
```

(b) Línea 90. Reemplazar esto:

```dart
          .import(password: 'clave', passcode: '000000')
```

por esto:

```dart
          .import(password: 'clave', passcode: '000000', consent: false)
```

(c) Línea 110 (dentro del `for`, con 12 espacios de indentación). Reemplazar esto:

```dart
        final e = await PortalSyncService(apiClient: api)
            .import(password: 'c', passcode: '123456')
            .then<Object?>((_) => null)
```

por esto:

```dart
        final e = await PortalSyncService(apiClient: api)
            .import(password: 'c', passcode: '123456', consent: false)
            .then<Object?>((_) => null)
```

(d) Línea 123 (con 10 espacios de indentación). Reemplazar esto:

```dart
      final e = await PortalSyncService(apiClient: api)
          .import(password: 'c', passcode: '123456')
          .then<Object?>((_) => null)
```

por esto:

```dart
      final e = await PortalSyncService(apiClient: api)
          .import(password: 'c', passcode: '123456', consent: false)
          .then<Object?>((_) => null)
```

Las aserciones de ese archivo no cambian: la de la línea 78 mira solo las claves de `credentials`, y con `consent: false` el body ni siquiera gana una clave.

**5.3 Correr lo que toca este cambio.**

```bash
cd . && $FLUTTER test test/HU31_jeff/portal_sync_test.dart test/HU34_jeff/
```

Esperado: `All tests passed!`, sin ningún fallo en `test/HU34_jeff/academic_record_service_test.dart`, que es el otro archivo que ejercita `refreshAfterImport`.

- [ ] **Paso 6: Documentación**

**6.1 `specs/features/portal-sync/portal-sync.spec.md`**, tres reemplazos exactos.

(a) Líneas 78-79. Se van el WebView, que ya no existe, y la frase "la contraseña nunca sale del portal", que es falsa (lo exige `academic-record.spec.md:183-187`). Reemplazar esto:

```
### BR-SYNC-F-02: Consentimiento previo
- Antes de abrir el portal se muestra una pantalla con qué datos se importarán (nombre, código, carrera, cursos, secciones, docentes, horario, matrícula, notas históricas, impedimentos), con qué finalidad y que la contraseña nunca sale del portal. Requiere aceptación explícita. Sin aceptación no se abre el WebView.
```

por esto:

```
### BR-SYNC-F-02: Consentimiento previo
- Ver RF-REC-6 de `specs/features/academic-record/academic-record.spec.md`. Antes del formulario de credenciales se muestra `PortalConsentView`: qué datos se importan, para qué (solo para mostrárselos al propio alumno) y que la contraseña se usa una sola vez y no se guarda. Requiere aceptación explícita; sin ella no aparece el formulario y no se envía nada. Tras aceptar, el body de `POST /portal-sync/import` lleva `consent: true`.
```

(b) Línea 83. Reemplazar esto:

```
- Una sola pantalla con tres estados (`PortalSyncStep`): formulario, cargando y resumen. No son tres rutas: el flujo es lineal y volver atrás a mitad de la carga no le sirve al alumno.
```

por esto:

```
- Una sola pantalla con cuatro estados (`PortalSyncStep`): consentimiento (`consent`, el inicial), formulario, cargando y resumen. No son cuatro rutas: el flujo es lineal y volver atrás a mitad de la carga no le sirve al alumno. Si la importación falla se vuelve al formulario sin volver a pedir la aceptación; salir y volver a entrar la pide de nuevo.
```

(c) Línea 112. Reemplazar esto:

```
- **PortalSyncConsentPage**: qué se importa, finalidad, aceptar o cancelar.
```

por esto:

```
- **PortalConsentView** (`lib/components/portal_consent/`, compartida con el registro): qué se importa, finalidad, aceptar o cancelar.
```

La otra mención, la de la línea 121, está dentro del bloque de Data Flow y describe el flujo de WebView que nunca se implementó: **no se toca en esta tarea**. Es otro arreglo, y meterlo aquí mezclaría dos cosas en el mismo commit.

**6.2 `docs/specs/api-contracts.md`**, un reemplazo exacto en la línea 482. Reemplazar esto:

```
    - Ninguno de los dos se persiste ni se registra en logs.
```

por esto:

```
    - Ninguno de los dos se persiste ni se registra en logs.
  - `"consent": true` es opcional y va en el nivel superior del body (RS-BE-29). La app lo manda solo después de que el alumno toca «Acepto» en la pantalla de consentimiento (RF-REC-6). Sin él la importación corre igual, pero el backend no guarda récord, foto ni resumen ni desmarca electivos. La app nunca manda `false`.
```

(El sub-bullet nuevo va con dos espacios de indentación, al nivel de `- Body:` y `- Response 200:`, no al de los tres sub-bullets del Body: `consent` no es una alternativa a `cookies`/`credentials`.)

- [ ] **Paso 7: Análisis estático**

```bash
cd . && $FLUTTER analyze lib/pages/portal_sync/ lib/services/portal_sync_service.dart test/HU34_jeff/portal_sync_consent_test.dart test/HU31_jeff/portal_sync_test.dart
```

Esperado: `No issues found! (ran in …)`. Si sale algún issue, corrígelo en esos archivos y repite los pasos 4, 5.3 y 7.

Y el proyecto entero, para comprobar que el número de issues preexistentes que anotaste en la tarea 1 no subió:

```bash
cd . && $FLUTTER analyze 2>&1 | grep -E "issues? found|portal_sync|portal_consent"
```

Esperado: la misma línea `N issues found. (ran in …)` (o `No issues found!`) que anotaste en la tarea 1, y ninguna línea que nombre `portal_sync` ni `portal_consent`. Si esta tarea corre en otra sesión no tienes ese reporte: la línea base está en `$TMP/plan-fe/analyze-baseline.txt`; léela con `cat` y compara sin el `(ran in …)`. Si el número subió, el issue nuevo es de esta tarea: corrígelo.

- [ ] **Paso final: Commit**

Revisa primero que el árbol no tenga cambios ajenos:

```bash
cd . && git status --short --untracked-files=all
```

Esperado, si vienes de la tarea 9 con todo commiteado, exactamente estas siete líneas modificadas (en cualquier orden):

```
 M docs/specs/api-contracts.md
 M lib/pages/portal_sync/portal_sync_controller.dart
 M lib/pages/portal_sync/portal_sync_page.dart
 M lib/services/portal_sync_service.dart
 M specs/features/portal-sync/portal-sync.spec.md
 M test/HU31_jeff/portal_sync_test.dart
 M test/HU34_jeff/portal_sync_consent_test.dart
```

Si aparece otro archivo, no lo agregues ni lo toques: puede ser de otra sesión.

```bash
cd . && git add lib/pages/portal_sync/portal_sync_controller.dart lib/pages/portal_sync/portal_sync_page.dart lib/services/portal_sync_service.dart test/HU34_jeff/portal_sync_consent_test.dart test/HU31_jeff/portal_sync_test.dart specs/features/portal-sync/portal-sync.spec.md docs/specs/api-contracts.md && git diff --cached --stat
```

Esperado: exactamente esos 7 archivos y `7 files changed`.

```bash
cd . && git commit -m "feat(portal-sync): consentimiento antes de las credenciales y consent en la importación"
```

El autor ya está configurado en git. El mensaje no lleva trailer `Co-Authored-By`. No hagas push.

### Tarea 11: Registro: paso de consentimiento y `consent: true` en el alta

**Archivos:**
- Crear: `test/HU34_jeff/registro_consent_test.dart`
- Modificar: `lib/pages/registro/registro_controller.dart:11`, `:109-110`, `:168-172`, `:177-179`, `:193-198`
- Modificar: `lib/pages/registro/registro_page.dart:4`, `:12-13`, `:46-48`
- Modificar: `lib/services/registro_service.dart:30-48`
- Modificar: `test/HU33_jeff/registro_controller_test.dart:25-32`, `:135-138`, y las 11 parejas `c.continuar();` + `await c.enviar();` (L155, 166, 173, 185, 201, 212, 223, 242, 251, 270 y 291)
- Modificar: `test/HU33_jeff/registro_page_test.dart:5-6`, `:17-23`, `:33-39`, `:62-63`, `:111-115`, `:131-132`
- Modificar: `test/HU33_jeff/registro_service_test.dart:56-67`, `:72-74`, `:89`, `:102`, `:113`, `:125`
- Modificar: `specs/features/registro/registro.spec.md:59-61`, `:146`, `:148`, `:162`, `:168`, `:191`, `:234`, `:244`
- Modificar: `docs/specs/api-contracts.md:52-53`
- Test: `test/HU34_jeff/registro_consent_test.dart`

**Depende de la tarea 9:** `lib/components/portal_consent/portal_consent_view.dart` tiene que existir antes de empezar. Hoy no existe (`ls lib/components/portal_consent/` da «No such file or directory»), así que esta tarea va después de la 9. `test/HU34_jeff/` tampoco existe todavía: la crea la tarea 1.

**Interfaces:**
- Consume (tarea 9), en `lib/components/portal_consent/portal_consent_view.dart`:
  - `class PortalConsentView extends StatelessWidget`
  - `const PortalConsentView({super.key, required this.palette, required this.onAccept, required this.onExit, required this.exitLabel});`
  - `final PasswordResetPalette palette;`, `final VoidCallback onAccept;`, `final VoidCallback onExit;`, `final String exitLabel;`
  - `static const String titulo = 'Antes de entrar a miUlima';`
  - `static const String botonAceptar = 'Acepto';`
  - Es **solo el contenido de la tarjeta**: se monta como `child` de un `PasswordResetScaffold`, que es justo lo que ya hace `RegistroPage`.
- Consume (repo), comprobado leyendo los archivos:
  - `lib/pages/registro/registro_controller.dart`: `enum RegistroPaso { datos, verificar, enviando, listo, incierto }` (L11); `RegistroController({RegistroService? service, AdoptarSesionFn? adoptarSesion, IniciarSesionFn? iniciarSesion})` (L76-82); `codigoCtrl`, `passwordCtrl`, `confirmacionCtrl`, `portalPasswordCtrl`, `passcodeCtrl` (L103-107); `final paso = RegistroPaso.datos.obs;` (L109); `final errorMessage = RxnString();` (L110); `bool get enviando => paso.value == RegistroPaso.enviando;` (L137); `void continuar()` (L158-170); `void volverADatos()` (L172-175); `Future<void> enviar()` (L177-231); `void _manejarFallo(RegistroFailure e)` (L233-254), con `aDatos = {'USER_ALREADY_EXISTS', 'INVALID_REQUEST_BODY', 'INVALID_JSON_BODY'}`; `void volverAVerificar()` (L296-300).
  - `lib/pages/registro/registro_binding.dart:15`: `Get.lazyPut<RegistroController>(RegistroController.new);` — **sin `fenix` ni `permanent`**, así que salir de `/registro` destruye el controller.
  - `lib/models/registro_models.dart`: `const RegistroResult({required this.token, required this.user, required this.summary, required this.warnings})` (L13-18); `const RegistroFailure(this.message, {this.code})` (L69).
  - `lib/models/portal_sync_models.dart:89-98`: `const PortalSyncSummary({required this.coursesCreated, required this.sectionsCreated, required this.sectionsUpdated, required this.sessionsUpserted, required this.enrollmentsUpserted, required this.enrollmentsWithdrawn, required this.progressUpserted, required this.syllabiUpserted})`.
  - `lib/models/user_model.dart:29-45`: `UserModel({required this.code, required this.firstName, required this.lastName, this.avatarUrl, String? fullName, required this.email, required this.role, this.teacherLabel, this.careerId, this.especialidadPrincipal, List<int>? especialidadesInteres, required this.currentCycle, required this.setupComplete, this.courseProgress})`. Los siete obligatorios son `code`, `firstName`, `lastName`, `email`, `role`, `currentCycle` y `setupComplete`; el resto es opcional. **No es `const`.**
  - `lib/services/api_client.dart:42`: `ApiClient({String? configuredBaseUrl})`; `:83-90`: `Future<Map<String, dynamic>> postJson(String path, {required Map<String, dynamic> body, String? token})`.
  - `lib/pages/password_reset/password_reset_ui.dart`: `factory PasswordResetPalette.from(BuildContext context)` (L34); `const PasswordResetScaffold({super.key, required this.palette, required this.child})` (L101-105). El scaffold dibuja un `IconButton(..., tooltip: 'Volver', ...)` (L149-157): es un **tooltip**, no un `Text`, así que no interfiere con `find.text('Volver')`.
- Produce (nadie lo consume después: la 11 es la última tarea del plan):
  - `enum RegistroPaso { datos, consentimiento, verificar, enviando, listo, incierto }`
  - `RegistroController`: `final consentimientoAceptado = false.obs;` (`RxBool`)
  - `void aceptarConsentimiento();` — pone `consentimientoAceptado = true`, `errorMessage = null` y `paso = RegistroPaso.verificar`.
  - `continuar()` valida y pasa a `RegistroPaso.consentimiento`, o directo a `RegistroPaso.verificar` si ya aceptó en esta visita.
  - `enviar()` sin aceptación no llama al servicio y deja `paso = RegistroPaso.consentimiento`.
  - `Future<RegistroResult> RegistroService.registrar({required String code, required String portalPassword, required String passcode, required String password, required bool consent})`, con body `{'code': …, 'portalPassword': …, 'passcode': …, 'password': …, if (consent) 'consent': true}`.

---

- [ ] **Paso 1: Escribir la prueba que falla**

Crear `test/HU34_jeff/registro_consent_test.dart` con este contenido completo:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/portal_consent/portal_consent_view.dart';
import 'package:ulima_plus/models/portal_sync_models.dart';
import 'package:ulima_plus/models/registro_models.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/registro/registro_controller.dart';
import 'package:ulima_plus/pages/registro/registro_page.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/registro_service.dart';

/// Consentimiento en el alta de cuenta (RF-REC-6).
///
/// El paso `consentimiento` va entre `datos` y `verificar`, nunca entre el
/// código del authenticator y el botón que envía: ese código vence en 30
/// segundos (BR-REG-F-01). Sin aceptación el registro no se envía, y tras
/// aceptar el body de `POST /auth/register` lleva `consent: true`.
///
/// Todos los valores son inventados.

/// Doble del servicio: cuenta llamadas y guarda qué consentimiento recibió.
class _ServicioFalso implements RegistroService {
  _ServicioFalso({this.resultado, this.fallo});

  final RegistroResult? resultado;
  final RegistroFailure? fallo;
  int llamadas = 0;
  bool? consentRecibido;

  @override
  Future<RegistroResult> registrar({
    required String code,
    required String portalPassword,
    required String passcode,
    required String password,
    required bool consent,
  }) async {
    llamadas++;
    consentRecibido = consent;
    if (fallo != null) throw fallo!;
    return resultado!;
  }
}

/// Doble del cliente HTTP: guarda el body para mirar sus claves.
class _FakeApiClient extends ApiClient {
  _FakeApiClient(this.respuesta) : super(configuredBaseUrl: 'http://test');

  final Map<String, dynamic> respuesta;
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
    return respuesta;
  }
}

UserModel _usuario() => UserModel(
      code: '20230001',
      firstName: 'Alumna',
      lastName: 'De Prueba',
      email: 'test@aloe.ulima.edu.pe',
      role: 'student',
      currentCycle: '2026-1',
      setupComplete: false,
    );

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

RegistroResult _resultado() => RegistroResult(
      token: 'jwt',
      user: _usuario(),
      summary: _summary(),
      warnings: const [],
    );

/// Respuesta `201` inventada, con la forma del contrato.
Map<String, dynamic> _respuestaValida() => {
      'token': 'jwt',
      'tokenType': 'Bearer',
      'expiresIn': 86400,
      'user': {
        'id': 1,
        'studentId': 1,
        'code': '20230001',
        'fullName': 'DE PRUEBA ALUMNA',
        'institutionalEmail': 'test@aloe.ulima.edu.pe',
        'role': 'student',
        'career_id': 1,
        'setupComplete': false,
      },
      'summary': {
        'enrollmentsUpserted': 5,
        'sessionsUpserted': 12,
        'progressUpserted': 40,
      },
      'warnings': <dynamic>[],
    };

/// Controller con las tres costuras controladas y los cinco campos llenos.
RegistroController _controller({RegistroService? servicio}) {
  final c = RegistroController(
    service: servicio ?? _ServicioFalso(resultado: _resultado()),
    adoptarSesion: ({required token, required user}) async {},
    iniciarSesion: ({required code, required password}) async => null,
  );
  c.codigoCtrl.text = '20230001';
  c.passwordCtrl.text = 'micontrasena';
  c.confirmacionCtrl.text = 'micontrasena';
  c.portalPasswordCtrl.text = 'clave-portal';
  c.passcodeCtrl.text = '123456';
  return c;
}

Widget _app() => GetMaterialApp(
      initialRoute: '/registro',
      getPages: [
        GetPage(name: '/registro', page: () => const RegistroPage()),
        GetPage(name: '/login', page: () => const Scaffold(body: Text('LOGIN'))),
      ],
    );

void main() {
  // El archivo mezcla `test` y `testWidgets`; dejar el binding puesto desde el
  // arranque evita depender del orden en que se ejecuten.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UNITARIA · RegistroController consentimiento (RF-REC-6)', () {
    test('caso 1: continuar lleva al consentimiento, no al formulario del portal',
        () {
      final servicio = _ServicioFalso(resultado: _resultado());
      final c = _controller(servicio: servicio);
      expect(c.paso.value, equals(RegistroPaso.datos));

      c.continuar();

      expect(c.paso.value, equals(RegistroPaso.consentimiento),
          reason: 'el consentimiento va ANTES de pedir la contraseña de miUlima');
      expect(servicio.llamadas, equals(0));
    });

    test('caso 2: aceptar lleva a verificar y deja constancia de la aceptación',
        () {
      final c = _controller();
      c.continuar();
      expect(c.consentimientoAceptado.value, isFalse);

      c.aceptarConsentimiento();

      expect(c.paso.value, equals(RegistroPaso.verificar));
      expect(c.consentimientoAceptado.value, isTrue);
    });

    test('caso 3: sin aceptación el registro no se envía', () async {
      final servicio = _ServicioFalso(resultado: _resultado());
      final c = _controller(servicio: servicio);
      c.continuar();

      await c.enviar();

      expect(servicio.llamadas, equals(0),
          reason: 'sin «Acepto» no sale nada hacia el backend');
      expect(c.paso.value, equals(RegistroPaso.consentimiento));
    });

    test('caso 4: tras aceptar, el alta manda consent: true', () async {
      final servicio = _ServicioFalso(resultado: _resultado());
      final c = _controller(servicio: servicio);
      c.continuar();
      c.aceptarConsentimiento();

      await c.enviar();

      expect(servicio.llamadas, equals(1));
      expect(servicio.consentRecibido, isTrue);
      expect(c.paso.value, equals(RegistroPaso.listo));
    });

    test('caso 5: un fallo que vuelve a datos no vuelve a pedir la aceptación',
        () async {
      // El alumno no se movió de `/registro`: volver a mostrarle la misma
      // pantalla de consentimiento en el mismo intento es ruido.
      final c = _controller(
        servicio: _ServicioFalso(
          fallo: const RegistroFailure('Ya existe una cuenta.',
              code: 'USER_ALREADY_EXISTS'),
        ),
      );
      c.continuar();
      c.aceptarConsentimiento();
      await c.enviar();
      expect(c.paso.value, equals(RegistroPaso.datos));

      c.continuar();

      expect(c.paso.value, equals(RegistroPaso.verificar));
    });

    test('caso 6: volver desde el consentimiento no borra lo tipeado', () {
      final c = _controller();
      c.continuar();
      expect(c.paso.value, equals(RegistroPaso.consentimiento));

      c.volverADatos();

      expect(c.paso.value, equals(RegistroPaso.datos));
      expect(c.codigoCtrl.text, equals('20230001'));
      expect(c.passwordCtrl.text, equals('micontrasena'));
      expect(c.confirmacionCtrl.text, equals('micontrasena'));
    });

    test('caso 7: una visita nueva arranca sin aceptación', () {
      // No se recuerda entre visitas: `RegistroBinding` usa `lazyPut` sin
      // `fenix`, así que salir y volver a entrar construye otro controller.
      final c = _controller();
      c.continuar();
      c.aceptarConsentimiento();
      expect(c.consentimientoAceptado.value, isTrue);

      final otra = _controller();

      expect(otra.consentimientoAceptado.value, isFalse);
      expect(otra.paso.value, equals(RegistroPaso.datos));
      otra.continuar();
      expect(otra.paso.value, equals(RegistroPaso.consentimiento));
    });
  });

  group('UNITARIA · RegistroService consent (RF-REC-6, RS-BE-29)', () {
    test('caso 8: consent true viaja en el nivel superior del body', () async {
      final api = _FakeApiClient(_respuestaValida());

      await RegistroService(apiClient: api).registrar(
        code: '20230001',
        portalPassword: 'clave-portal',
        passcode: '123456',
        password: 'micontrasena',
        consent: true,
      );

      expect(api.ultimaRuta, equals('/auth/register'));
      expect(api.ultimoBody!['consent'], isTrue);
      expect(
        api.ultimoBody!.keys.toSet(),
        equals({'code', 'portalPassword', 'passcode', 'password', 'consent'}),
      );
    });

    test('caso 9: sin consentimiento el campo no se manda; nunca va false',
        () async {
      final api = _FakeApiClient(_respuestaValida());

      await RegistroService(apiClient: api).registrar(
        code: '20230001',
        portalPassword: 'clave-portal',
        passcode: '123456',
        password: 'micontrasena',
        consent: false,
      );

      expect(
        api.ultimoBody!.keys.toSet(),
        equals({'code', 'portalPassword', 'passcode', 'password'}),
      );
      expect(api.ultimoBody!.containsKey('consent'), isFalse);
    });
  });

  group('WIDGET · RegistroPage consentimiento (RF-REC-6)', () {
    setUp(() => Get.testMode = true);
    tearDown(Get.reset);

    testWidgets('caso 10: continuar muestra el consentimiento antes que miUlima',
        (tester) async {
      Get.put<RegistroController>(_controller());
      await tester.pumpWidget(_app());
      await tester.pump();

      await tester.tap(find.text('Continuar'));
      await tester.pump();

      expect(find.text(PortalConsentView.titulo), findsOneWidget);
      expect(find.text('Verificamos que eres alumno'), findsNothing);
      expect(find.text('Código del authenticator'), findsNothing,
          reason: 'el código vence en 30 s: no puede esperar a que se lea el aviso');
    });

    testWidgets('caso 11: «Acepto» lleva al formulario de miUlima',
        (tester) async {
      Get.put<RegistroController>(_controller());
      await tester.pumpWidget(_app());
      await tester.pump();

      await tester.tap(find.text('Continuar'));
      await tester.pump();

      // La tarjeta mide 340 de ancho y va dentro de un scroll: el botón puede
      // quedar fuera de los 800x600 del test.
      await tester.ensureVisible(find.text(PortalConsentView.botonAceptar));
      await tester.tap(find.text(PortalConsentView.botonAceptar));
      await tester.pump();

      expect(find.text('Verificamos que eres alumno'), findsOneWidget);
      expect(find.text('Código del authenticator'), findsOneWidget);
    });

    testWidgets('caso 12: «Volver» regresa a los datos sin borrarlos',
        (tester) async {
      final c = _controller();
      Get.put<RegistroController>(c);
      await tester.pumpWidget(_app());
      await tester.pump();

      await tester.tap(find.text('Continuar'));
      await tester.pump();
      expect(find.text(PortalConsentView.titulo), findsOneWidget);

      // El único `Text` con 'Volver' es el enlace de salida de la tarjeta: el
      // 'Volver' del scaffold es un tooltip, no un Text.
      await tester.ensureVisible(find.text('Volver'));
      await tester.tap(find.text('Volver'));
      await tester.pump();

      expect(find.text('Crea tu cuenta de ULima++'), findsOneWidget);
      expect(c.codigoCtrl.text, equals('20230001'),
          reason: 'salir del consentimiento es retroceder un paso, no empezar de cero');
    });
  });
}
```

- [ ] **Paso 2: Correr la prueba y ver que falla**

```bash
cd . && $FLUTTER test test/HU34_jeff/registro_consent_test.dart
```

Esperado: la suite **ni compila**. `flutter test` usa el frontend de Dart (CFE), que imprime, con los números de línea y columna que toquen:

```
test/HU34_jeff/registro_consent_test.dart:…: Error: Member not found: 'consentimiento'.
test/HU34_jeff/registro_consent_test.dart:…: Error: The method 'aceptarConsentimiento' isn't defined for the type 'RegistroController'.
 - 'RegistroController' is from 'package:ulima_plus/pages/registro/registro_controller.dart'.
test/HU34_jeff/registro_consent_test.dart:…: Error: The getter 'consentimientoAceptado' isn't defined for the type 'RegistroController'.
 - 'RegistroController' is from 'package:ulima_plus/pages/registro/registro_controller.dart'.
test/HU34_jeff/registro_consent_test.dart:…: Error: No named parameter with the name 'consent'.
```

y termina sin correr ningún test, con un `Failed to load "…/test/HU34_jeff/registro_consent_test.dart"` y salida distinta de cero. Lo que tiene que aparecer son esos cuatro errores: falta el valor `consentimiento` del enum (sale una vez por cada `RegistroPaso.consentimiento` del archivo, en los casos 1, 3, 6 y 7), faltan `aceptarConsentimiento` y `consentimientoAceptado`, y falta el parámetro `consent` de `registrar` (casos 8 y 9).

**Ojo con lo que NO va a salir:** el `required bool consent` de más en `_ServicioFalso.registrar` **no** produce error del CFE. Comprobado con Dart 3.13.2: `dart run` lo acepta y solo `dart analyze` lo marca como `invalid_override`. Por eso el fallo de este paso no depende de ese doble: depende de los cuatro errores de arriba. Después del paso 3 la firma del doble coincide con la del servicio y el `invalid_override` desaparece también para el analizador.

- [ ] **Paso 3: Implementación mínima**

**3.1 `lib/pages/registro/registro_controller.dart`** — cinco reemplazos.

Reemplazar esto (L11):

```dart
enum RegistroPaso { datos, verificar, enviando, listo, incierto }
```

por esto:

```dart
enum RegistroPaso { datos, consentimiento, verificar, enviando, listo, incierto }
```

Reemplazar esto (L109-110):

```dart
  final paso = RegistroPaso.datos.obs;
  final errorMessage = RxnString();
```

por esto:

```dart
  final paso = RegistroPaso.datos.obs;

  /// True cuando el alumno ya tocó «Acepto» en ESTA visita a `/registro`.
  ///
  /// No se guarda en ningún lado (RF-REC-6, «Qué NO entra»): `RegistroBinding`
  /// usa `lazyPut` sin `fenix`, así que salir de la ruta destruye el controller
  /// y volver a entrar pide la aceptación de nuevo. Un fallo que devuelve a
  /// `datos` sí la conserva: el alumno no se movió de la pantalla.
  final consentimientoAceptado = false.obs;

  final errorMessage = RxnString();
```

Reemplazar esto (L168-172, el final de `continuar()` y el arranque de `volverADatos()`):

```dart
    errorMessage.value = null;
    paso.value = RegistroPaso.verificar;
  }

  void volverADatos() {
```

por esto:

```dart
    errorMessage.value = null;
    // RF-REC-6: el consentimiento va ANTES del formulario del portal, nunca
    // entre el código del authenticator y el botón que envía (BR-REG-F-01).
    // Aceptado una vez, dura lo que dura la visita a /registro.
    paso.value = consentimientoAceptado.value
        ? RegistroPaso.verificar
        : RegistroPaso.consentimiento;
  }

  /// El alumno tocó «Acepto» en `PortalConsentView`.
  void aceptarConsentimiento() {
    consentimientoAceptado.value = true;
    errorMessage.value = null;
    paso.value = RegistroPaso.verificar;
  }

  void volverADatos() {
```

Reemplazar esto (L177-179):

```dart
  Future<void> enviar() async {
    if (enviando) return;
    final error = validarPasoVerificar(
```

por esto:

```dart
  Future<void> enviar() async {
    if (enviando) return;

    // Sin aceptación el registro no se envía (RF-REC-6). Va ANTES de validar
    // los campos: si se llegó acá sin pasar por el consentimiento, lo que
    // falta no es un dato sino el permiso, y el mensaje rojo sobraría.
    if (!consentimientoAceptado.value) {
      errorMessage.value = null;
      paso.value = RegistroPaso.consentimiento;
      return;
    }

    final error = validarPasoVerificar(
```

Reemplazar esto (L193-198):

```dart
      r = await _service.registrar(
        code: codigoCtrl.text.trim(),
        portalPassword: portalPasswordCtrl.text,
        passcode: passcodeCtrl.text.trim(),
        password: passwordCtrl.text,
      );
```

por esto:

```dart
      r = await _service.registrar(
        code: codigoCtrl.text.trim(),
        portalPassword: portalPasswordCtrl.text,
        passcode: passcodeCtrl.text.trim(),
        password: passwordCtrl.text,
        consent: consentimientoAceptado.value,
      );
```

`volverAVerificar()` y `_manejarFallo` no se tocan: a los dos solo se llega después de un envío, que ya exigió la aceptación.

**3.2 `lib/services/registro_service.dart`** — un reemplazo (L30-48).

Reemplazar esto:

```dart
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
```

por esto:

```dart
  /// Registra y devuelve la sesión, o lanza [RegistroFailure] con un mensaje
  /// listo para mostrar. Nunca lanza `ApiException` cruda.
  ///
  /// [consent] es la aceptación explícita de la pantalla de consentimiento
  /// (RF-REC-6). Sin ella el backend crea la cuenta e importa el ciclo igual,
  /// pero no guarda el récord académico (RS-BE-29).
  Future<RegistroResult> registrar({
    required String code,
    required String portalPassword,
    required String passcode,
    required String password,
    required bool consent,
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
          // RS-BE-29: solo `true` o ausente; nunca se manda `false`.
          if (consent) 'consent': true,
        },
      ).timeout(registroTimeout);
```

**3.3 `lib/pages/registro/registro_page.dart`** — tres reemplazos.

Reemplazar esto (L4):

```dart
import '../../models/portal_sync_models.dart';
```

por esto:

```dart
import '../../components/portal_consent/portal_consent_view.dart';
import '../../models/portal_sync_models.dart';
```

Reemplazar esto (L12-13):

```dart
/// Una sola ruta con cinco estados en vez de cinco pantallas, como hace
/// `PortalSyncPage` con tres: el flujo es lineal y volver atrás a mitad del
```

por esto:

```dart
/// Una sola ruta con seis estados en vez de seis pantallas, como hace
/// `PortalSyncPage` con cuatro: el flujo es lineal y volver atrás a mitad del
```

(`PortalSyncPage` pasa de tres estados a cuatro en la tarea 10, que va antes que esta.)

Reemplazar esto (L46-48):

```dart
          child: switch (controller.paso.value) {
            RegistroPaso.datos => _PasoDatos(palette: palette, controller: controller),
            RegistroPaso.verificar => _PasoVerificar(palette: palette, controller: controller),
```

por esto:

```dart
          child: switch (controller.paso.value) {
            RegistroPaso.datos => _PasoDatos(palette: palette, controller: controller),
            // 'Volver' regresa a `datos` sin borrar lo tipeado (BR-REG-F-05).
            RegistroPaso.consentimiento => PortalConsentView(
                palette: palette,
                exitLabel: 'Volver',
                onAccept: controller.aceptarConsentimiento,
                onExit: controller.volverADatos,
              ),
            RegistroPaso.verificar => _PasoVerificar(palette: palette, controller: controller),
```

El `switch` es una expresión exhaustiva sobre el enum, así que sin este caso el archivo no compila. El `PopScope` no cambia: `canPop` sigue siendo `!controller.enviando`.

- [ ] **Paso 4: Correr la prueba y ver que pasa**

```bash
cd . && $FLUTTER test test/HU34_jeff/registro_consent_test.dart
```

Esperado: PASS, con `+12: All tests passed!`.

- [ ] **Paso 5: Adaptar los tests de HU33 que rompe el cambio de firma**

Los tres dobles de `RegistroService` de HU33 se quedan sin el parámetro nuevo. Si corres `test/HU33_jeff` antes de tocarlos, el CFE dice, por cada uno:

```
Error: The method '_ServicioFalso.registrar' doesn't have the named parameter 'consent' of overridden method 'RegistroService.registrar'.
```

**5.1 `test/HU33_jeff/registro_controller_test.dart`** — tres reemplazos.

Reemplazar esto (L25-32):

```dart
  Future<RegistroResult> registrar({
    required String code,
    required String portalPassword,
    required String passcode,
    required String password,
  }) async {
    llamadas++;
    codigoRecibido = code;
```

por esto:

```dart
  Future<RegistroResult> registrar({
    required String code,
    required String portalPassword,
    required String passcode,
    required String password,
    required bool consent,
  }) async {
    llamadas++;
    codigoRecibido = code;
```

Reemplazar esto (L135-138, caso 1):

```dart
      c.continuar();
      expect(c.paso.value, equals(RegistroPaso.verificar));
      expect(servicio.llamadas, equals(0),
          reason: 'el paso 1 no consulta al backend: sería un oráculo de enumeración');
```

por esto:

```dart
      c.continuar();
      expect(c.paso.value, equals(RegistroPaso.consentimiento),
          reason: 'RF-REC-6: el consentimiento va entre datos y verificar');
      c.aceptarConsentimiento();
      expect(c.paso.value, equals(RegistroPaso.verificar));
      expect(servicio.llamadas, equals(0),
          reason: 'el paso 1 no consulta al backend: sería un oráculo de enumeración');
```

Reemplazar **todas** las ocurrencias de este par de líneas (comprobado: son exactamente 11, con 6 espacios de indentación las 11, en L155, 166, 173, 185, 201, 212, 223, 242, 251, 270 y la del helper `enIncierto` en L291):

```dart
      c.continuar();
      await c.enviar();
```

por esto:

```dart
      c.continuar();
      c.aceptarConsentimiento();
      await c.enviar();
```

El caso 2 (L141-146) no cambia: `continuar()` con datos inválidos sigue quedándose en `datos`.

**5.2 `test/HU33_jeff/registro_page_test.dart`** — seis reemplazos.

Reemplazar esto (L5-6):

```dart
import 'package:get/get.dart';
import 'package:ulima_plus/main.dart';
```

por esto:

```dart
import 'package:get/get.dart';
import 'package:ulima_plus/components/portal_consent/portal_consent_view.dart';
import 'package:ulima_plus/main.dart';
```

Reemplazar esto (L17-23, `_ServicioColgado`):

```dart
  Future<RegistroResult> registrar({
    required String code,
    required String portalPassword,
    required String passcode,
    required String password,
  }) =>
      Completer<RegistroResult>().future;
```

por esto:

```dart
  Future<RegistroResult> registrar({
    required String code,
    required String portalPassword,
    required String passcode,
    required String password,
    required bool consent,
  }) =>
      Completer<RegistroResult>().future;
```

Reemplazar esto (L33-39, `_ServicioQueFalla`):

```dart
  Future<RegistroResult> registrar({
    required String code,
    required String portalPassword,
    required String passcode,
    required String password,
  }) async =>
      throw fallo;
```

por esto:

```dart
  Future<RegistroResult> registrar({
    required String code,
    required String portalPassword,
    required String passcode,
    required String password,
    required bool consent,
  }) async =>
      throw fallo;
```

Reemplazar esto (L62-63, dentro de `_hastaIncierto`, indentación de 2 espacios):

```dart
  c.continuar();
  c.portalPasswordCtrl.text = 'clave';
```

por esto:

```dart
  c.continuar();
  c.aceptarConsentimiento();
  c.portalPasswordCtrl.text = 'clave';
```

Reemplazar esto (L111-115, caso 2):

```dart
    await tester.tap(find.text('Continuar'));
    await tester.pump();

    expect(find.text('Verificamos que eres alumno'), findsOneWidget);
    expect(find.text('Código del authenticator'), findsOneWidget);
```

por esto:

```dart
    await tester.tap(find.text('Continuar'));
    await tester.pump();

    // RF-REC-6: entre los datos y el portal va el consentimiento.
    expect(find.text(PortalConsentView.titulo), findsOneWidget);
    await tester.ensureVisible(find.text(PortalConsentView.botonAceptar));
    await tester.tap(find.text(PortalConsentView.botonAceptar));
    await tester.pump();

    expect(find.text('Verificamos que eres alumno'), findsOneWidget);
    expect(find.text('Código del authenticator'), findsOneWidget);
```

Reemplazar esto (L131-132, caso 3, indentación de 4 espacios; es la única ocurrencia con esa indentación, la de 2 espacios ya se cambió arriba):

```dart
    c.continuar();
    c.portalPasswordCtrl.text = 'clave';
```

por esto:

```dart
    c.continuar();
    c.aceptarConsentimiento();
    c.portalPasswordCtrl.text = 'clave';
```

**5.3 `test/HU33_jeff/registro_service_test.dart`** — tres reemplazos.

Reemplazar esto (L56-67, caso 1):

```dart
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
```

por esto:

```dart
      await RegistroService(apiClient: api).registrar(
        code: '20230001',
        portalPassword: 'clave-portal',
        passcode: '123456',
        password: 'micontrasena',
        consent: false,
      );

      expect(api.ultimaRuta, equals('/auth/register'));
      // Sin consentimiento el campo `consent` NO viaja: nunca se manda `false`
      // (RS-BE-29). Por eso las claves siguen siendo exactamente cuatro.
      expect(
        api.ultimoBody!.keys.toSet(),
        equals({'code', 'portalPassword', 'passcode', 'password'}),
      );
```

Reemplazar esto (L72-74, caso 2):

```dart
      final r = await RegistroService(apiClient: api).registrar(
        code: '20230001', portalPassword: 'x', passcode: '123456', password: 'micontrasena',
      );
```

por esto:

```dart
      final r = await RegistroService(apiClient: api).registrar(
        code: '20230001', portalPassword: 'x', passcode: '123456',
        password: 'micontrasena', consent: false,
      );
```

Reemplazar **todas** las ocurrencias de esta línea (comprobado: son exactamente 4, en L89, L102, L113 y L125, todas con 10 espacios de indentación):

```dart
          .registrar(code: '20230001', portalPassword: 'x', passcode: '123456', password: 'micontrasena')
```

por esto:

```dart
          .registrar(
            code: '20230001', portalPassword: 'x', passcode: '123456',
            password: 'micontrasena', consent: false,
          )
```

Correr:

```bash
cd . && $FLUTTER test test/HU33_jeff
```

Esperado: PASS, `+52: All tests passed!` — los cuatro archivos de `test/HU33_jeff/` en verde, incluido `api_client_401_test.dart`, que no se toca. El número no cambia porque ningún test se agrega ni se quita. El caso 3 de `registro_service_test.dart` tarda ~2 min por el `timeout` de 120 s: es así desde HU33.

- [ ] **Paso 6: Documentación**

**6.1 `specs/features/registro/registro.spec.md`** — ocho reemplazos.

Reemplazar esto (L59-61, el segundo párrafo de BR-REG-F-01 con la línea en blanco y el encabezado que le siguen):

```
El orden no es estético. El código del authenticator **cambia cada 30 segundos**, y tipear una contraseña dos veces toma más que eso. Con el orden inverso —miUlima primero— el código estaría vencido al llegar el POST, el backend respondería `401 PORTAL_AUTH_FAILED`, que es deliberadamente indistinguible de "contraseña mala", y la persona se iría convencida de que se equivocó de contraseña universitaria. Poniendo el authenticator inmediatamente antes del botón que envía —igual que hace `PortalSyncPage`— el problema desaparece.

### BR-REG-F-02: El paso 1 no habla con el backend
```

por esto:

```
El orden no es estético. El código del authenticator **cambia cada 30 segundos**, y tipear una contraseña dos veces toma más que eso. Con el orden inverso —miUlima primero— el código estaría vencido al llegar el POST, el backend respondería `401 PORTAL_AUTH_FAILED`, que es deliberadamente indistinguible de "contraseña mala", y la persona se iría convencida de que se equivocó de contraseña universitaria. Poniendo el authenticator inmediatamente antes del botón que envía —igual que hace `PortalSyncPage`— el problema desaparece.

Entre los dos pasos va el de consentimiento (`consentimiento`, RF-REC-6 de `specs/features/academic-record/academic-record.spec.md`): la pantalla `PortalConsentView`, que dice qué datos se importan y para qué. Va antes del formulario del portal y nunca entre el código del authenticator y el botón que envía. Sin aceptación el registro no se envía; aceptada una vez, dura lo que dura la visita a `/registro`.

### BR-REG-F-02: El paso 1 no habla con el backend
```

Reemplazar esto (L146):

```
Una sola ruta, `/registro`, con **cinco estados** en la misma pantalla — el patrón de `PortalSyncPage`, que resuelve tres estados sin tres rutas. Toda la pantalla se compone con el kit público de `password_reset_ui.dart`.
```

por esto:

```
Una sola ruta, `/registro`, con **seis estados** en la misma pantalla — el patrón de `PortalSyncPage`, que resuelve cuatro estados sin cuatro rutas. Toda la pantalla se compone con el kit público de `password_reset_ui.dart`.
```

Reemplazar esto (L148):

```
- **`datos`** — «Crea tu cuenta de ULima++». Código, contraseña, repetir contraseña. Nota bajo los campos: con esta contraseña entrarás al app. Botón `Continuar`. Enlace secundario para volver al login.
```

por esto:

```
- **`datos`** — «Crea tu cuenta de ULima++». Código, contraseña, repetir contraseña. Nota bajo los campos: con esta contraseña entrarás al app. Botón `Continuar`. Enlace secundario para volver al login.
- **`consentimiento`** — `PortalConsentView` (RF-REC-6). Botón `Acepto`, que lleva a `verificar`; enlace `Volver`, que regresa a `datos` sin borrar lo tipeado.
```

Reemplazar esto (L162):

```
   │     └─ Continuar ──▶ verificar
```

por esto:

```
   │     └─ Continuar ──▶ consentimiento ──Acepto──▶ verificar
```

Reemplazar esto (L168):

```
                   POST /auth/register {code, portalPassword, passcode, password}
```

por esto:

```
                   POST /auth/register {code, portalPassword, passcode, password, consent: true}
```

Reemplazar esto (L191):

```
Request: `{ "code": "20230001", "portalPassword": "…", "passcode": "123456", "password": "…" }`
```

por esto:

```
Request: `{ "code": "20230001", "portalPassword": "…", "passcode": "123456", "password": "…", "consent": true }`
```

Reemplazar esto (L234):

```
- Tests nuevos en `test/HU33_jeff/`, siguiendo la convención del repo —dobles escritos a mano con `extends` + `@override`, sin mockito—: el mapeo de errores código por código, las transiciones entre los cinco estados, los validadores locales, el parseo de la respuesta y el borrado de credenciales al cerrar la pantalla.
```

por esto:

```
- Tests nuevos en `test/HU33_jeff/`, siguiendo la convención del repo —dobles escritos a mano con `extends` + `@override`, sin mockito—: el mapeo de errores código por código, las transiciones entre los seis estados, los validadores locales, el parseo de la respuesta y el borrado de credenciales al cerrar la pantalla.
```

Reemplazar esto (L244):

```
5. `lib/pages/registro/` — controller con los cinco estados, binding por ruta con `lazyPut` (para que `onClose` borre las credenciales) y página compuesta con el kit de `password_reset_ui.dart`, envuelta en `PopScope`.
```

por esto:

```
5. `lib/pages/registro/` — controller con los seis estados, binding por ruta con `lazyPut` (para que `onClose` borre las credenciales) y página compuesta con el kit de `password_reset_ui.dart`, envuelta en `PopScope`.
```

No se agrega ningún `[@test]` acá: `specs/features/academic-record/academic-record.spec.md:165` ya enlaza `../../../test/HU34_jeff/registro_consent_test.dart`, así que esa spec no se toca.

**6.2 `docs/specs/api-contracts.md`** — un reemplazo (L52-53).

Reemplazar esto:

```
  - Request: `{ "code": "string", "portalPassword": "string", "passcode": "string", "password": "string" }`
  - `code` es `^\d{6,10}$`. `portalPassword` y `passcode` son de **miUlima**: se usan para entrar al portal y se descartan; no se persisten ni se registran en logs. `password` es la que la persona quiere para ULima++.
```

por esto:

```
  - Request: `{ "code": "string", "portalPassword": "string", "passcode": "string", "password": "string", "consent"?: true }`
  - `code` es `^\d{6,10}$`. `portalPassword` y `passcode` son de **miUlima**: se usan para entrar al portal y se descartan; no se persisten ni se registran en logs. `password` es la que la persona quiere para ULima++.
  - `consent` (RS-BE-29) es opcional y la app lo manda solo tras «Acepto» en la pantalla de consentimiento (RF-REC-6). Sin él la cuenta se crea igual, pero no se guarda el récord. Nunca `false`.
```

- [ ] **Paso 7: Análisis y suite completa**

Primero los archivos tocados:

```bash
cd . && $FLUTTER analyze lib/pages/registro lib/services/registro_service.dart test/HU33_jeff test/HU34_jeff/registro_consent_test.dart
```

Esperado: `No issues found! (ran in …)`. Si sale algo, corrígelo en esos archivos y repite los pasos 4 y 5.

Después el proyecto entero, para comprobar que el número de issues preexistentes que anotaste en la tarea 1 no subió:

```bash
cd . && $FLUTTER analyze 2>&1 | grep -E "issues? found|registro|portal_consent"
```

Esperado: la misma línea `N issues found. (ran in …)` (o `No issues found!`) que anotaste en la tarea 1, y ninguna línea que nombre `registro` ni `portal_consent`. Si esta tarea corre en otra sesión no tienes ese reporte: la línea base está en `$TMP/plan-fe/analyze-baseline.txt`; léela con `cat` y compara sin el `(ran in …)`. Si el número subió, el issue nuevo es de esta tarea: corrígelo.

Y toda la carpeta de la HU:

```bash
cd . && $FLUTTER test test/HU34_jeff
```

Esperado: PASS con los siete archivos de `test/HU34_jeff/` —`academic_record_model_test.dart`, `academic_record_service_test.dart`, `record_card_test.dart`, `record_course_row_test.dart`, `record_page_test.dart`, `portal_sync_consent_test.dart` y `registro_consent_test.dart`—, es decir los de las tareas 1 a 10 más el de esta.

- [ ] **Paso final: Commit**

Revisa primero que el árbol no tenga cambios ajenos:

```bash
cd . && git status --short --untracked-files=all
```

Esperado, si vienes de la tarea 10 con todo commiteado, exactamente estas nueve líneas (en cualquier orden):

```
 M docs/specs/api-contracts.md
 M lib/pages/registro/registro_controller.dart
 M lib/pages/registro/registro_page.dart
 M lib/services/registro_service.dart
 M specs/features/registro/registro.spec.md
 M test/HU33_jeff/registro_controller_test.dart
 M test/HU33_jeff/registro_page_test.dart
 M test/HU33_jeff/registro_service_test.dart
?? test/HU34_jeff/registro_consent_test.dart
```

Si aparece otro archivo, no lo agregues ni lo toques: puede ser de otra sesión.

```bash
cd . && git add \
  lib/pages/registro/registro_controller.dart \
  lib/pages/registro/registro_page.dart \
  lib/services/registro_service.dart \
  test/HU34_jeff/registro_consent_test.dart \
  test/HU33_jeff/registro_controller_test.dart \
  test/HU33_jeff/registro_page_test.dart \
  test/HU33_jeff/registro_service_test.dart \
  specs/features/registro/registro.spec.md \
  docs/specs/api-contracts.md && git diff --cached --stat
```

Esperado: exactamente esos 9 archivos y `9 files changed`.

```bash
cd . && git commit -m "feat(registro): paso de consentimiento antes del portal y consent en el alta"
```

El autor ya está configurado en git. El mensaje no lleva trailer `Co-Authored-By`. No hagas push.

