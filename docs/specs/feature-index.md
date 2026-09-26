# Feature Index

This index connects real user stories, product requirements, Flutter files, mockups, and specs.

| Priority | Feature | Spec | User Stories | Requirements | Flutter target | Status |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | Platform Runtime | `specs/features/platform-runtime/platform-runtime.spec.md` | Infra | Runtime config | `lib/services/api_client.dart` | Activo |
| 0 | Application Shell | `specs/features/app-shell/app-shell.spec.md` | Infra | BR-SHELL-F-00 a BR-SHELL-F-03: encabezado global, orientación del shell y pestañas del footer | `lib/main.dart`, `lib/components/header/app_header.dart`, `lib/pages/home/home_page.dart`, `lib/pages/home/home_shell_config.dart`, `lib/components/footer/app_footer.dart` | Activo; BR-SHELL-F-02 y BR-SHELL-F-03 (chats de curso) ya están en el código y el dueño los aprueba el 2026-09-23, junto con la spec del chat |
| 1 | Auth | `specs/features/auth/auth.spec.md` | US01, US02, US03, HU18 | R1, R2, RNF7 | `lib/pages/login`, `lib/services/auth_service.dart` | Implementado (incluye Google SSO docente) |
| 2 | Academic Profile | `specs/features/academic-profile/academic-profile.spec.md` | US05 | R12, R13 | `lib/pages/setup_carrera` | Spec existente |
| 3 | Curriculum | `specs/features/curriculum/curriculum.spec.md` | US03, US04 | R4, R5, R10, R11 | `lib/pages/malla` | Spec existente |
| 4 | Grades | `specs/features/grades/grades.spec.md` | US06, US07 | R6, R9 | `lib/pages/calculadora` | Spec existente |
| 5 | Schedule | `specs/features/schedule/schedule.spec.md` | US09 | R19 | `lib/pages/horario` | Spec existente; el ajuste de los chats de curso (Horario solo calendario) ya está en el código y el dueño lo aprueba el 2026-09-23, junto con la spec del chat |
| 6 | Course Detail | `specs/features/course-detail/course-detail.spec.md` | US13, US14, US17 | R20 | `lib/pages/descripcion_cursos` | Spec existente; el ajuste de los chats de curso (botón «Chat del curso») ya está en el código y el dueño lo aprueba el 2026-09-23, junto con la spec del chat |
| 7 | Alerts | `specs/features/alerts/alerts.spec.md` | US15 | R15, R16, R22, R23 | `lib/pages/home`, `lib/pages/perfil` | Spec existente |
| 8 | Section Management | `specs/features/section-management/section-management.spec.md` | US16, US17, US18 | R14, R17, R18, R21 | services and delegate mockups | Spec existente |
| 9 | Teacher / Advising | _(sin spec)_ | HU18 | Rol docente, asesorías extra | `lib/pages/teacher/**`, `lib/services/advising_service.dart` | Implementado sin spec |
| 10 | Password Reset | _(sin spec)_ | HU20 | Restablecer contraseña vía OTP | `lib/pages/password_reset/**`, `lib/services/password_reset_service.dart` | Implementado sin spec |
| 11 | Silabo Viewer | _(sin spec)_ | HU21 | Visualizar sílabo en PDF | `lib/pages/silabo/**`, `lib/services/silabo_service.dart` | Implementado sin spec |
| 12 | Release Build | `specs/features/release-build/release-build.spec.md` | Infra | Build config | `android/`, `pubspec.yaml` | Documentado |
| 13 | Chatbot Asistente Académico | `specs/features/chatbot/chatbot.spec.md` | HU-CHATBOT-01, HU-CHATBOT-02 | Chatbot con IA para consultas académicas | `lib/pages/chatbot/**`, `lib/services/chatbot_service.dart`, `lib/components/chatbot_fab.dart`, `lib/models/chatbot_models.dart` | **Diseñada — pendiente de implementar** |
| 14 | Carnet de networking | `specs/features/networking/networking.spec.md` | HU25 (issues históricos HU27) | Opt-in y una red social propia | `lib/pages/networking/**`, `lib/services/networking_service.dart` | Escenario 1 implementado |
| 15 | Portal Sync (carga de ciclo desde miUlima) | `specs/features/portal-sync/portal-sync.spec.md` | HU-SYNC-01, HU-SYNC-02 | Login en WebView de miUlima + importación al backend; banner en Home y opción en Perfil | `lib/pages/portal_sync/**`, `lib/services/portal_sync_service.dart` | **Diseñada — pendiente de aprobación e implementación** |
| 16 | Registro de alumno | `specs/features/registro/registro.spec.md` | HU-REG-01, HU-REG-02 | Alta de cuenta contra miUlima en dos pasos; el portal certifica la matrícula y entrega los datos | `lib/pages/registro/**`, `lib/services/registro_service.dart` | Implementada — **pendiente de verificar contra el portal real** |
| 17 | Récord académico | `specs/features/academic-record/academic-record.spec.md` | HU34 | RF-REC-1 a RF-REC-6: tarjeta en Perfil, pantalla /mi-record, borrado a pedido y consentimiento antes del portal | `lib/pages/academic_record/**`, `lib/services/academic_record_service.dart`, `lib/models/academic_record_model.dart`, `lib/components/portal_consent/**` | Implementado — pendiente de verificación end-to-end |
| 18 | Bloques de horario propios | `specs/features/time-blocks/time-blocks.spec.md` | HU35 | RF-BLQ-1 a RF-BLQ-8: bloques propios del alumno en el horario (crear, editar, corregir un día suelto), aviso de cruce, reparto lado a lado con las clases, domingo en la vista semanal, horas por semana y la lista Mis bloques | `lib/pages/time_blocks/**`, `lib/services/time_blocks_service.dart`, `lib/models/time_block_model.dart`, `lib/pages/horario/horario.dart`, `lib/pages/horario/horario_controller.dart`, `lib/pages/horario/horario_layout.dart` | Implementado y probado contra el backend desplegado el 2026-09-23, día en que se aplicó la migración 0012, se desplegó el backend y el dueño recorrió las siete rutas contra producción con 11 de 11 pasos correctos. Falta la revisión manual en un iPhone SE. El ajuste de RF-BLQ-8 por los chats de curso (el botón «Mis bloques» sin la condición de la lista de chats) ya está en el código y el dueño lo aprobó el 2026-09-23, junto con la spec del chat, así que no quedan aprobaciones pendientes |
| 19 | Chat de sección | `specs/features/chat/chat.spec.md` | HU23 | RF-CHAT-1 a RF-CHAT-13: chat en vivo por sección (token, mensajes, texto y carnet, borrado de los mensajes propios con cualquier rol y de cualquiera por el profesor titular), pestaña Chats del alumno con su bandeja, botón «Chat del curso» en la ficha, conversación con la identidad de la app y acceso del docente desde Secciones | `lib/pages/chat/**`, `lib/services/chat_repository.dart`, `lib/models/message.dart`, `lib/pages/home/home_shell_config.dart`, `lib/pages/home/home_page.dart`, `lib/components/footer/app_footer.dart`, `lib/components/header/app_header.dart`, `lib/pages/horario/horario.dart`, `lib/pages/horario/horario_controller.dart`, `lib/pages/horario/horario_list_view.dart` (borrado en la fase 1), `lib/pages/descripcion_cursos/descrip_cursos.dart`, `lib/pages/teacher/teacher_sections_page.dart`, `lib/configs/themes.dart` | Implementada el 2026-09-23 (fase 1, con el borrado de los mensajes propios de RF-CHAT-4 y el retoque final); falta la revisión manual en un iPhone SE que pide «Verificación», en claro y en oscuro, del footer del delegado, de la bandeja y de la conversación. La misma revisión confirma con SF, la fuente del iPhone, que las seis etiquetas del delegado se leen completas con la activa en 13 px (RF-CHAT-5). El dueño aprobó la spec y el ajuste de RF-CHAT-4 el 2026-09-23, igual que los ajustes de app-shell (BR-SHELL-F-02 y BR-SHELL-F-03), schedule, course-detail y time-blocks (RF-BLQ-8), así que no quedan aprobaciones pendientes |
| 20 | Truco del 67 | `specs/features/six-seven/six-seven.spec.md` | HU-67-01, HU-67-02 | RF-67-1 a RF-67-7. Un mensaje que es solo un 67 inclina la interfaz del chat unos 2 s y muestra «SIX SEVEN!!!», como burbuja local de Ulises en el chatbot, sin llamar al backend, y como rótulo pasajero en los chats de sección, solo con los mensajes que llegan en vivo | `lib/domain/seis_siete/seis_siete.dart`, `lib/components/seis_siete/tambaleo_seis_siete.dart`, `lib/pages/chat/chat_seis_siete.dart`, `lib/pages/chat/chat_page.dart`, `lib/pages/chatbot/chatbot_controller.dart`, `lib/pages/chatbot/chatbot_page.dart`, `test/six_seven/**` | Aprobada el 2026-09-25, con D4 en «toda la pantalla», e implementada el 2026-09-25. Falta la revisión manual que pide «Verificación» en un iPhone SE y en un simulador de iPad. Ajusta de paso RF-CHAT-2 (el stream del chat de sección se crea una vez por página) y la entrada de preguntas del chatbot |

## Workflow

1. Read `KNOWLEDGE.md` and this index before updating a spec.
2. Update or create the feature spec before changing Flutter behavior.
3. Confirm API changes in `docs/specs/api-contracts.md`.
4. Implement within existing `lib/` folders; do not restructure frontend directories unless explicitly approved.
5. Add widget/service tests and link them from the spec using `[@test]`.
6. Review UI behavior against the feature spec and mockups.
7. Runtime/build changes that affect deployed connectivity should live in `specs/features/platform-runtime/platform-runtime.spec.md`.

## Data Rules

- PostgreSQL through the backend is definitive.
- `assets/data/*.json` files are disposable mocks.
- Do not use JSON as final fallback for API-backed features.
- Services own API/data access; widgets must not read assets or call HTTP directly.
- Report missing backend/PostgreSQL data instead of reintroducing mock behavior.
