---
name: Chatbot Asistente Academico
description: Pantalla de chat conversacional con IA dentro de la app, accesible via FAB flotante. Permite al alumno hacer preguntas en lenguaje natural sobre toda su informacion academica y mantener multiples sesiones de conversacion.
targets:
  - ../../../lib/pages/chatbot/**
  - ../../../lib/services/chatbot_service.dart
  - ../../../lib/components/chatbot_fab.dart
  - ../../../lib/models/chatbot_models.dart
  - ../../../lib/pages/home/home_page.dart
---

# Chatbot Asistente Academico

Pantalla de chat con IA (ULimaBot) accesible mediante un FAB flotante visible en toda la app para alumnos autenticados. Soporta multiples sesiones de conversacion, historial persistente en backend, y envio de notas locales para consultas de calificaciones.

> Ajustada el 2026-09-25 por la spec del truco del 67 (`specs/features/six-seven/six-seven.spec.md`,
> RF-67-5). Un mensaje que es un 67 no llega al backend. La pantalla agrega en local la burbuja del
> alumno y la de Ulises con «SIX SEVEN!!!» e inclina toda la pantalla del chat unos 2 s, también el
> AppBar con su título, sin gastar el límite de preguntas ni guardar nada en el historial. En
> pantalla ancha, con conversaciones, la barra superior se parte en dos tramos del mismo alto y
> color, el de la lista con la flecha de volver y el del chat con Ulises, su título y el botón
> «Nueva conversación», y solo se inclina el panel del chat con su tramo (D4 de esa spec).
> `ChatbotController` acepta además un `ChatbotService` inyectable para pruebas. Aprobada por el
> dueño el 2026-09-25, junto con la spec del truco del 67, con la elección de «toda la pantalla» en
> D4, e implementada el 2026-09-25. El resto de esta spec no cambia.

## Requirements

- HU-CHATBOT-01: El alumno puede hacer preguntas en lenguaje natural sobre sus notas, horario, examenes, malla curricular, anuncios, companeros, alertas academicas y conversaciones del chat de su seccion.
- HU-CHATBOT-02: El alumno puede crear multiples sesiones de chat, cambiar entre ellas, y eliminar sesiones.

## UI Behavior

### FAB (Floating Action Button)

- Visible en TODAS las pantallas principales donde el alumno esta autenticado: home, horario, malla, notas, perfil, descripcion de cursos, alertas, chat de seccion, delegado.
- NO visible en pantallas de login, setup de carrera, ni en pantallas del profesor.
- Icono: `MessageCircle` (lucide_icons_flutter).
- Color: `MaterialTheme.primaryColor` (naranja `#FF6600`) con icono blanco.
- Comportamiento: al presionarlo navega a `/chatbot` via `Get.toNamed`.
- Si ya existe el FAB en una pantalla (ej. malla tiene "Simular mi avance", delegado tiene "Nuevo anuncio"), se usa un `Stack` con ambos FABs (el de chatbot abajo, el original arriba) o el chatbot reemplaza el FAB existente. Decision: el chatbot usa el mismo `floatingActionButton` del `Scaffold`; si la pantalla ya tiene FAB, se wrappea en una `Column` con ambos botones (chatbot abajo).

### Pantalla de Chat (`ChatbotPage`)

Diseno de dos paneles en desktop/tablet, o navegacion apilada en movil:

```
┌──────────────────────────────────┐
│  ← Chatbot            + Nueva   │  AppBar
├────────────┬─────────────────────┤
│            │                     │
│ Sesion 1   │  Mensajes del chat  │
│ "Notas y   │  (burbujas estilo   │
│  horario"  │   chat)             │
│ 12/07      │                     │
│            │  User: texto        │
│ Sesion 2   │  Assistant: texto   │
│ "Malla"    │                     │
│ 10/07      │                     │
│            │                     │
│            │                     │
│            ├─────────────────────┤
│            │ [Escribe tu        │  Input bar
│            │  pregunta...]  ➤  │
└────────────┴─────────────────────┘
```

#### Estados

- **Loading inicial**: Skeleton de lista de sesiones + area de chat vacia con SkeletonPulse.
- **Sin sesiones**: Estado vacio con ilustracion/icono y texto "No tienes conversaciones. Crea una nueva para empezar." + boton "Nueva conversacion".
- **Sesion activa con mensajes**: Lista de sesiones a la izquierda, chat activo a la derecha con historial de mensajes.
- **Cargando respuesta**: Indicador de "escribiendo..." (tres puntos animados) en la burbuja del assistant mientras se espera la respuesta del backend.
- **Error**: Snackbar con mensaje de error ("No se pudo obtener respuesta. Intenta de nuevo.") + el mensaje del usuario permanece en el chat (no se pierde).
- **Rate limit**: Snackbar con "Demasiadas preguntas. Intenta de nuevo en X minutos."

#### Navegacion

- Ruta: `/chatbot` en `getPages`.
- Al entrar, carga la lista de sesiones desde `GET /chatbot/sessions`.
- Si hay sesiones, selecciona automaticamente la mas reciente (primera de la lista).
- El boton "+" en el AppBar crea una nueva sesion (`POST /chatbot/sessions`) y la selecciona.
- Al seleccionar una sesion, carga sus mensajes (`GET /chatbot/sessions/:id`).
- Swipe left en una sesion de la lista muestra opcion "Eliminar" (rojo) con confirmacion.

#### Input de pregunta

- TextField con hint "Escribe tu pregunta..." y boton de enviar (icono `Send` o `ArrowUp`).
- El boton se deshabilita mientras se espera respuesta (evita doble envio).
- Maximo 500 caracteres (enforced en frontend + backend).
- Al enviar:
  1. Se agrega la pregunta como mensaje `user` en la UI (optimista).
  2. Se muestra indicador de "escribiendo...".
  3. Se llama a `POST /chatbot/sessions/:id/ask` con `{ question, localGrades }`.
  4. Al recibir respuesta, se reemplaza el indicador con el mensaje `assistant`.
  5. Si es error, se muestra snackbar y se mantiene el mensaje del usuario.
- Si la pregunta es un 67 (RF-67-1 de `specs/features/six-seven/six-seven.spec.md`), se da solo
  el paso 1, con la burbuja local del alumno, y no se dan los pasos 2 a 5. Rige RF-67-5 de esa
  spec, que suma en el mismo instante la burbuja local de Ulises con «SIX SEVEN!!!».

`[@test] ../../../test/six_seven/chatbot_seis_siete_test.dart`

### Logica de notas locales

- Antes de cada llamada a `POST /chatbot/sessions/:id/ask`, el `ChatbotController` carga las notas del alumno desde `NotasService.cargarNotas()`.
- Las notas se serializan y se envian en el campo `localGrades` del body.
- Si no hay notas guardadas, se omite el campo `localGrades`.
- Estructura enviada:
  ```json
  [
    {
      "id": "sectionId",
      "nombre": "INGENIERIA DE SOFTWARE II",
      "notas": [
        { "titulo": "Parcial 1", "peso": 30, "valor": 16.0 }
      ]
    }
  ]
  ```

## API Dependencies

| Metodo | Endpoint | Uso |
| --- | --- | --- |
| `POST` | `/chatbot/sessions` | Crear nueva sesion |
| `GET` | `/chatbot/sessions` | Listar sesiones del alumno |
| `GET` | `/chatbot/sessions/:id` | Cargar mensajes de una sesion |
| `DELETE` | `/chatbot/sessions/:id` | Eliminar sesion |
| `POST` | `/chatbot/sessions/:id/ask` | Enviar pregunta y recibir respuesta |

## Modelos

### ChatbotSession

```dart
class ChatbotSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ChatbotSession.fromJson(Map<String, dynamic> json);
}
```

### ChatbotMessage

```dart
class ChatbotMessage {
  final String id;
  final String role; // "user" | "assistant"
  final String content;
  final DateTime createdAt;

  factory ChatbotMessage.fromJson(Map<String, dynamic> json);
}
```

## Componentes nuevos

- `lib/components/chatbot_fab.dart`: Widget del FAB flotante. Recibe `onPressed` y se integra en el `Scaffold` de cada pagina.
- `lib/pages/chatbot/chatbot_page.dart`: Pantalla principal del chatbot con diseno de dos paneles.
- `lib/pages/chatbot/chatbot_controller.dart`: GetX controller con estado reactivo (sesiones, mensajes, loading, error, sesion activa).
- `lib/services/chatbot_service.dart`: Servicio que encapsula las llamadas a la API del chatbot (hereda patron de `api_client.dart`).
- `lib/models/chatbot_models.dart`: Modelos `ChatbotSession` y `ChatbotMessage`.

## Integracion en HomePage

El `HomePage` (scaffold principal) debe incluir el `ChatbotFab` en su `floatingActionButton`. Las paginas hijas que se muestran dentro del shell del `HomePage` **no** necesitan su propio FAB individual; el FAB del chatbot vive en el `Scaffold` del `HomePage` y es visible en todos los tabs.

Las paginas independientes (fuera del home shell) que tienen su propio `Scaffold` deben incluir el `ChatbotFab` manualmente.

## Verificacion

- `flutter analyze` sin errores nuevos.
- Verificar que el FAB aparece en home, horario, malla, notas, perfil, cursos, alertas, chat de seccion, delegado.
- Verificar que el FAB NO aparece en login, setup-carrera, ni pantallas de profesor.
- Verificar que al crear una sesion se navega al chat vacio.
- Verificar que una pregunta simple ("Cual es mi promedio?") recibe respuesta y se muestra en el chat.
- Verificar que el indicador de "escribiendo..." aparece mientras se espera la respuesta.
- Verificar que eliminar una sesion la remueve de la lista.
- Verificar que el historial de mensajes se mantiene al cambiar de sesion y volver.
- Verificar manejo de error: si el backend devuelve 503, se muestra snackbar de error.
- Verificar limite de 500 caracteres en el input.
