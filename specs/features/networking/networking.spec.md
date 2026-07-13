---
name: Carnet de networking (HU25)
description: Edición y vista previa del carnet propio con una única red social y visibilidad opt-in.
targets:
  - ../../../lib/pages/networking/**
  - ../../../lib/components/networking/**
  - ../../../lib/models/networking_model.dart
  - ../../../lib/services/networking_service.dart
  - ../../../lib/pages/perfil/perfil.dart
  - ../../../lib/main.dart
  - ../../../test/networking_*.dart
  - ../../../test/services/networking_service_test.dart
---

# Carnet de networking — Escenario 1

Esta spec implementa el primer escenario de HU25. El nombre HU27 se conserva
únicamente como referencia histórica de los issues de backend/frontend.

## User Stories

| ID | Description |
| --- | --- |
| HU25-E1 | Como alumno o docente, quiero configurar y activar mi carnet con una red social para conectar con otros usuarios. |

## Scope

- El acceso aparece en Perfil para alumnos y docentes, después del bloque
  académico cuando este existe y antes de Seguridad.
- La pantalla permite consultar, agregar, editar, reemplazar o quitar una sola
  red y cambiar el opt-in.
- Contactos y chat consumen el carnet publico mediante el backend; esta spec
  documenta la integracion existente, aunque el refactor se concentra en la
  pantalla propia de networking.
- No se modifica el esquema ni la migración de base de datos.

## Business Rules

### BR-NET-F-01: El backend es autoritativo

- El frontend no decide permisos, propiedad, límites persistentes ni
  autorización. Envía el carnet del usuario autenticado a `/networking/me` y
  presenta los errores devueltos por el backend.
- PostgreSQL, a través del backend, es la única fuente de verdad. No se usa
  JSON ni `shared_preferences` como fallback.

### BR-NET-F-02: Un enlace en la interfaz

- La interfaz presenta como máximo un enlace configurado y permite
  reemplazarlo o quitarlo. El contrato usa `links` como arreglo para respetar
  el modelo existente, pero el backend valida el máximo de un elemento.
  `[@test] ../../../test/networking_model_test.dart`
- Desactivar el opt-in no quita el enlace del formulario ni solicita borrarlo.
  La persistencia y privacidad efectiva son responsabilidad del backend.

### BR-NET-F-03: Apertura defensiva de enlaces

- El cliente no bloquea ni previene `PUT /networking/me` por validaciones de
  URL: todo borrador se envía al backend y su respuesta prevalece.
- Antes de abrir una URL ya persistida, el cliente comprueba defensivamente
  que sea una URI absoluta HTTP(S). No valida dominios por plataforma ni usa
  esta comprobación para decidir persistencia.
  `[@test] ../../../test/networking_validators_test.dart`
- Las plataformas del contrato son `linkedin`, `instagram`, `github`, `x`,
  `website` y `other`. Para `website` y `other` se muestra el campo `label`,
  sin convertir su obligatoriedad en una decisión autoritativa del cliente.

## UI Behavior

### Acceso desde Perfil

- Una tarjeta “Carnet de networking”, con estética consistente con Perfil,
  navega a `/networking`.
- Está disponible para alumnos, delegados, subdelegados y docentes que ya
  tienen una sesión válida.

### Pantalla del carnet

- La pantalla usa colores y activos de Universidad de Lima.
- La vista previa muestra nombre completo, código y uno de estos rótulos:
  `Alumno`, `Docente` o `Jefe de Práctica`. Delegado y subdelegado se presentan
  como `Alumno`; el rótulo docente se toma de la sesión autenticada.
  `[@test] ../../../test/networking_card_preview_test.dart`
- El enlace configurado se representa con plataforma/etiqueta y la acción
  “Abrir enlace”. Solo se abre una URL hidratada o confirmada por el backend,
  usando `url_launcher` fuera de la app; un borrador aún no guardado nunca se
  lanza como enlace.
  `[@test] ../../../test/networking_controller_test.dart`
- Un switch controla el borrador de `optIn` y “Guardar cambios” persiste toda
  la edición mediante `PUT /networking/me`.
- Si no hay enlace, se ofrece “Agregar una red”. Si existe, los campos permiten
  editarla/reemplazarla y una acción permite quitarla.

### Estados

- `loading`: indicador durante `GET /networking/me`.
- `error`: mensaje recuperable con acción “Reintentar”.
- `empty`: vista previa sin red y formulario listo para agregar una.
- `success`: vista previa y formulario hidratados desde backend.
- `saving`: botón bloqueado e indicador; al completar se hidrata con la
  respuesta del backend.
- Los fallos muestran el mensaje de `ApiException` y conservan el borrador.
  `[@test] ../../../test/networking_controller_test.dart`

## Data Flow

```text
Ruta /networking → Binding → Controller → NetworkingService → ApiClient
  → GET/PUT /networking/me → DTO → estado GetX → UI
```

- Los widgets no llaman HTTP ni interpretan JSON.
- El service es la frontera de API y el controller solo coordina estado de
  presentación, edición del formulario y mensajes.
- `networking_model.dart` actua como **DTO Mapper** del cliente: convierte JSON
  de backend a objetos Dart y serializa el payload de `PUT /networking/me`.
- `networking_validators.dart` concentra validaciones defensivas de URL y
  reglas simples de formulario; el backend sigue siendo autoritativo.

## API Dependencies

- `GET /networking/me` — devuelve `{ "optIn": boolean, "links": [...] }`.
- `PUT /networking/me` — recibe `{ "optIn": boolean, "links": [...] }` y
  devuelve el carnet actualizado.
- `GET /networking/users/:userId` — devuelve el carnet publico visible para
  contactos y mensajes de chat.
  `[@test] ../../../test/services/networking_service_test.dart`
- Ambas rutas requieren el bearer token gestionado por `ApiClient`.

## Mock Data Elimination

No existen mocks de networking. La feature consume exclusivamente el backend.

## Verification

- `dart format` para archivos Dart modificados.
- `flutter analyze --no-pub` debe pasar sin errores nuevos.
- `flutter test --no-pub` debe pasar.
