# Feature Index

This index connects real user stories, product requirements, Flutter files, mockups, and specs.

| Priority | Feature | Spec | User Stories | Requirements | Flutter target | Status |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | Platform Runtime | `specs/features/platform-runtime/platform-runtime.spec.md` | Infra | Runtime config | `lib/services/api_client.dart` | Activo |
| 0 | Application Shell | `specs/features/app-shell/app-shell.spec.md` | Infra | Encabezado global | `lib/components/header/app_header.dart` | Activo |
| 1 | Auth | `specs/features/auth/auth.spec.md` | US01, US02, US03, HU18 | R1, R2, RNF7 | `lib/pages/login`, `lib/services/auth_service.dart` | Implementado (incluye Google SSO docente) |
| 2 | Academic Profile | `specs/features/academic-profile/academic-profile.spec.md` | US05 | R12, R13 | `lib/pages/setup_carrera` | Spec existente |
| 3 | Curriculum | `specs/features/curriculum/curriculum.spec.md` | US03, US04 | R4, R5, R10, R11 | `lib/pages/malla` | Spec existente |
| 4 | Grades | `specs/features/grades/grades.spec.md` | US06, US07 | R6, R9 | `lib/pages/calculadora` | Spec existente |
| 5 | Schedule | `specs/features/schedule/schedule.spec.md` | US09 | R19 | `lib/pages/horario` | Spec existente |
| 6 | Course Detail | `specs/features/course-detail/course-detail.spec.md` | US13, US14, US17 | R20 | `lib/pages/descripcion_cursos` | Spec existente |
| 7 | Alerts | `specs/features/alerts/alerts.spec.md` | US15 | R15, R16, R22, R23 | `lib/pages/home`, `lib/pages/perfil` | Spec existente |
| 8 | Section Management | `specs/features/section-management/section-management.spec.md` | US16, US17, US18 | R14, R17, R18, R21 | services and delegate mockups | Spec existente |
| 9 | Teacher / Advising | _(sin spec)_ | HU18 | Rol docente, asesorías extra | `lib/pages/teacher/**`, `lib/services/advising_service.dart` | Implementado sin spec |
| 10 | Password Reset | _(sin spec)_ | HU20 | Restablecer contraseña vía OTP | `lib/pages/password_reset/**`, `lib/services/password_reset_service.dart` | Implementado sin spec |
| 11 | Silabo Viewer | _(sin spec)_ | HU21 | Visualizar sílabo en PDF | `lib/pages/silabo/**`, `lib/services/silabo_service.dart` | Implementado sin spec |
| 12 | Release Build | `specs/features/release-build/release-build.spec.md` | Infra | Build config | `android/`, `pubspec.yaml` | Documentado |
| 13 | Chatbot Asistente Académico | `specs/features/chatbot/chatbot.spec.md` | HU-CHATBOT-01, HU-CHATBOT-02 | Chatbot con IA para consultas académicas | `lib/pages/chatbot/**`, `lib/services/chatbot_service.dart`, `lib/components/chatbot_fab.dart`, `lib/models/chatbot_models.dart` | **Diseñada — pendiente de implementar** |
| 14 | Carnet de networking | `specs/features/networking/networking.spec.md` | HU25 (issues históricos HU27) | Opt-in y una red social propia | `lib/pages/networking/**`, `lib/services/networking_service.dart` | Escenario 1 implementado |
| 15 | Portal Sync (carga de ciclo desde miUlima) | `specs/features/portal-sync/portal-sync.spec.md` | HU-SYNC-01, HU-SYNC-02 | Login en WebView de miUlima + importación al backend; banner en Home y opción en Perfil | `lib/pages/portal_sync/**`, `lib/services/portal_sync_service.dart` | **Diseñada — pendiente de aprobación e implementación** |

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
