---
name: Bienvenida con Ulises
description: Pantalla sin sesión que reemplaza a la tarjeta del login por una conversación con Ulises, con el logo entero en todo momento, en la que el que vuelve inicia sesión, el nuevo crea su cuenta y hace su test de especialidad y el alumno con cuenta que todavía no elige su especialidad hace el test, sin cortes hasta su horario, y que pone el sello del logo en las pantallas de «¿Olvidaste tu contraseña?»
targets:
  - ../../../lib/main.dart
  - ../../../lib/pages/bienvenida/**
  - ../../../lib/domain/bienvenida/**
  - ../../../lib/pages/login/**
  - ../../../lib/pages/registro/**
  - ../../../lib/pages/specialty_test/**
  - ../../../lib/pages/password_reset/**
  - ../../../lib/pages/perfil/perfil.dart
  - ../../../lib/services/session_navigation.dart
  - ../../../lib/services/api_client.dart
  - ../../../lib/components/google_sign_in_button.dart
  - ../../../lib/components/google_sign_in_button_stub.dart
  - ../../../lib/components/google_sign_in_button_web.dart
  - ../../../lib/components/chatbot_bubble.dart
  - ../../../lib/components/logo/**
  - ../../../lib/components/portal_consent/portal_consent_view.dart
  - ../../../lib/pages/splash/**
  - ../../../lib/services/auth_service.dart
  - ../../../lib/configs/themes.dart
  - ../../../test/bienvenida/**
  - ../../../test/HU01_jeff/**
  - ../../../test/HU20_jeff/**
  - ../../../test/HU33_jeff/**
  - ../../../test/HU34_jeff/registro_consent_test.dart
  - ../../../docs/images/UI/bienvenida/**
  - ../../../README.md
---

# Bienvenida con Ulises

> Estado. **Aprobada por el dueño el 2026-09-26 e implementada el 2026-09-26.** La revisión
> manual de «Verificación» queda pendiente. Diseñada el
> 2026-09-25 y corregida ese mismo día con los hallazgos de una revisión.
> El dueño aprueba la spec con «aplica» y lo confirma como «Arranque: todas las recomendadas».
> Aprueba B-1 a B-35 en la opción que la spec toma por defecto, salvo B-9 y B-10, donde elige las
> opciones que cumplen mejor sus pedidos, «que no se pierda el logo» y «con sesión, luego del
> splash, ver su horario». Por B-10, que va junto con S-29 del splash, el alumno con cuenta que
> todavía no elige su especialidad no va al asistente de carrera. Pasa a la conversación con
> Ulises, que le toma el test ahí mismo con el logo en la cabecera y después lo lleva a su horario
> (RF-BIEN-21). Por B-9, «¿Olvidaste tu contraseña?» conserva las pantallas de hoy, con el sello
> del logo ULima++ y sus «++» en su cabecera, para que el logo nunca se pierda (RF-BIEN-20).
> La misma aprobación deja explícitas tres decisiones del splash en su opción por defecto. Todos
> los roles abren en Horario (S-24), el splash y la bienvenida se publican juntos (S-30) y la
> animación se ve siempre completa (S-6).
> El ajuste del 2026-09-26 por B-9 y B-10 suma RF-BIEN-20 y RF-BIEN-21 y toca «Contexto», RF-BIEN-1
> a RF-BIEN-6, RF-BIEN-10, RF-BIEN-11, RF-BIEN-13, RF-BIEN-15, RF-BIEN-16 y RF-BIEN-19. Toca también
> «Textos nuevos», «Contrato que se consume», «Pantallas y archivos», «Cambios en otras specs», «Qué
> NO entra», «Decisiones», las pruebas, «Verificación» y los targets, a los que entran las pantallas
> de `lib/pages/password_reset/**`, una línea de `perfil.dart` y `test/HU20_jeff/**`.
> «Decisiones» reúne primero los pedidos del dueño y después cada punto, con la opción aprobada,
> en dos tablas. La primera reúne las que cambian lo que ve el alumno, que decide el dueño, y la
> segunda las técnicas, que propone el equipo.
> El dueño elige el 2026-09-25 la versión combinada de «Ulises te recibe» para el arranque sin
> sesión, cuya maqueta es `docs/images/UI/bienvenida/ulises-te-recibe-combinada.html`. Esta spec
> describe todo lo que pasa después del relevo que fija RF-SPL-21 de
> `specs/features/splash/splash.spec.md`, que el dueño aprueba con esta el 2026-09-26.
> Enmienda `specs/features/auth/auth.spec.md`, `specs/features/registro/registro.spec.md` y
> `specs/features/specialty-test/specialty-test.spec.md`, esta última aprobada el 2026-09-25 en la
> rama `feat/test-especialidad-fe`, donde su implementación empieza ese mismo día («Cambios en otras
> specs»). El dueño aprueba las tres enmiendas con esta spec el 2026-09-26. La del test queda
> anotada aquí como enmienda aprobada, y desde el 2026-09-26 está escrita al final de la spec del
> test, que llega a `main` con su implementación en `87403a1`. Password Reset no tiene spec, así
> que el sello de sus pantallas vive en esta (RF-BIEN-20).
> Las decisiones de esta spec llevan el prefijo B y las de la spec del splash, el prefijo S, así
> que B-10 y S-29 nunca se confunden aunque las dos specs numeren desde 1.
> Las referencias `archivo:línea` apuntan a `4e2a0b2`, la punta de `feat/splash-animado` el
> 2026-09-25, cuyo código sigue igual en la rama el 2026-09-26. Las de la spec del test apuntan a
> `e718c29` de `feat/test-especialidad-fe`, el último commit que cambia esa spec, porque los
> siguientes solo suman su implementación. Las de `google_sign_in_web` apuntan a la versión 0.12.4+4
> y las de GetX a la 4.7.3, que fija `pubspec.lock`.
> Los `[@test]` apuntan a la prueba que fija cada requisito, escrita con la implementación.
> Donde esta spec y la maqueta difieren, manda la spec, y `docs/images/UI/bienvenida/README.md`
> lista las diferencias.
> Enmienda técnica del 2026-09-26 a los targets, que no cambia ningún comportamiento aprobado.
> Suma `lib/components/google_sign_in_button.dart` y `lib/components/google_sign_in_button_stub.dart`,
> la fachada del botón de Google y su rama de Android e iOS. El botón de Google que aprueba B-25,
> el oficial de GIS en web con su logo, recibe su configuración por la firma de esa fachada
> (RF-BIEN-6 y decisión B-35), así que las dos ramas de la fachada cambian con ella. En Android e
> iOS la rama sigue sin dibujar nada, porque ahí va el botón propio con el logo oficial.

## User Stories

- Como alumno que vuelve, quiero que Ulises me reciba con el logo entero y me deje entrar con mi
  código o con Google, para llegar a mi horario.
- Como alumno nuevo, quiero crear mi cuenta y hacer mi test de especialidad en una sola
  conversación, sin pantallas que se corten, hasta ver mi horario.
- Como alumno con cuenta que todavía no elige su especialidad, quiero que Ulises me tome el test
  en la conversación, al abrir la app o al entrar, y me lleve después a mi horario.
- Como alumno que olvidó su contraseña, quiero restablecerla sin perder de vista el logo.
- Como docente, quiero entrar con mi usuario o con Google desde la misma pantalla.
- Como persona que usa lector de pantalla, texto grande, teclado o menos movimiento, quiero
  seguir la conversación igual que los demás.
- Como alumno, quiero que la app no deje averiguar qué códigos tienen cuenta.

## Contexto

El diagnóstico sobre `4e2a0b2` es lo que la spec reemplaza o conserva.

- **La pantalla sin sesión.** `/login` muestra hoy una tarjeta de 340 dp sobre `#FF6600` en claro
  y sobre `#262626`, con la tarjeta en `#050505`, en oscuro (`login_page.dart:51-164` y
  `:459-502`). Lleva el ícono de la app en 96 dp (`:79-90`), el campo «Código» con la pista «Tu
  código o usuario» (`:94-106`), «Contraseña» (`:108-131`), «Entrar» (`:282-327`), «¿Olvidaste tu
  contraseña?» (`:329-351`), «¿No tienes cuenta? Créala» (`:353-381`) y el botón de Google
  (`:383-436`).
- **El controlador del login es permanente.** `LoginBinding` registra `LoginController` con
  `permanent: true` para evitar el «tipeo fantasma», y al volver a entrar limpia los campos
  después del cuadro (`login_binding.dart:25-38`). Todo camino que termina la sesión navega a
  `/login` por `offAllToLogin`, que no navega si `/login` ya es la ruta actual
  (`session_navigation.dart:32-39`), y una prueba prohíbe `Get.offAllNamed('/login')` fuera de ese
  archivo (`test/HU02_jeff/session_navigation_guard_test.dart`).
- **Quién llega a `/login`.** El arranque sin sesión (`main.dart:98-100`), el cierre de sesión
  del Perfil y del docente, el botón «Volver a iniciar sesión» del Perfil cuando no carga sus
  datos (`perfil.dart:97`, con `onPressed: offAllToLogin`), el 401 del `ApiClient` con el aviso
  «Sesión expirada» (`api_client.dart:143-160`) y el restablecimiento de contraseña, que al
  terminar cierra la sesión y llama a `offAllToLogin` con el aviso «Contraseña actualizada»
  (`reset_password_controller.dart:150-166`). Con la spec del splash, el arranque sin sesión llega
  además con la pose del logo como argumento de ruta (RF-SPL-21).
- **Los avisos arriba.** «Sesión expirada» (`api_client.dart:159`), «Contraseña actualizada»
  (`reset_password_controller.dart:162-165`) y el aviso «Estamos creando tu cuenta» del registro
  (`registro_page.dart:73-78`) son `Get.snackbar`, que en GetX sale arriba si no se dice otra
  cosa (`extension_navigation.dart:434`, `SnackPosition.TOP`).
- **El docente.** Entra con un usuario alfanumérico, así que el campo usa teclado de texto y la
  pista «Tu código o usuario» (`login_page.dart:94-106`).
- **El login con código.** `LoginController.submit` valida que ningún campo esté vacío, llama a
  `AuthService.login` y navega con `postLoginRoute` (`login_controller.dart:61-84`).
  `AuthService.login` solo atrapa `ApiException` (`auth_service.dart:218-250`), así que un fallo
  de red sale crudo, `submit` no llega a apagar `submitting` y el botón «Entrar» queda girando.
  Además, `login` guarda el token antes de cargar los catálogos (`auth_service.dart:235-242`), así
  que un fallo de red en ese tramo deja el token guardado sin `currentUser`, y el siguiente
  arranque en frío restaura esa sesión.
- **Google.** En Android y en iOS, el botón propio dice «Google» junto al logo oficial de
  `assets/images/google_logo.svg` (`login_page.dart:401-434`) y llama a `loginWithGoogle`
  (`auth_service.dart:255-268`). En web va el botón oficial de Google Identity Services, que se
  dibuja con `renderButton()` sin configuración (`google_sign_in_button_web.dart:29`), y la cuenta
  llega por `onCurrentUserChanged` (`login_controller.dart:24-47`). `renderButton` acepta un
  `GSIButtonConfiguration` con el tipo, el tema, el tamaño, el texto `continueWith`, la forma, la
  alineación del logo, el ancho mínimo y el idioma, y ningún otro estilo
  (`button_configuration.dart:30-81` y `:88-169` de `google_sign_in_web`). Google no crea
  cuentas, y sus errores tienen mensajes propios (`auth_service.dart:305-317`).
- **El registro.** `/registro` es una sola ruta con seis estados, `datos`, `consentimiento`,
  `verificar`, `enviando`, `listo` e `incierto` (`registro_controller.dart:11`). `RegistroBinding`
  usa `lazyPut` sin `fenix`, para que salir de la ruta borre las cinco credenciales en `onClose`
  (`registro_binding.dart:12-17` y `registro_controller.dart:149-163`). El paso de datos no llama
  al backend (`:165-184`), el consentimiento usa los textos de `PortalConsentView`
  (`portal_consent_view.dart:41-56`), el envío corre hasta 120 s (`registro_service.dart:28` y
  `:36-94`) con la advertencia «Puede tomar un par de minutos: no cierres la app.»
  (`registro_page.dart:301-302`), un `PopScope` impide salir mientras se envía
  (`registro_page.dart:40-62`) y los estados `listo` e `incierto` cierran el recorrido
  (`:311-369` y `:393-462`). `listo` muestra tres cifras, «Cursos matriculados», «Clases en tu
  horario» y «Cursos de tu avance» (`:335-337`). El enlace «Ya tengo cuenta» vuelve al login con
  `Get.back` (`:195-202`). Si la red falla antes de la respuesta, `RegistroService` lo traduce a
  `SIN_CONEXION` (`registro_service.dart:65-71`) y el controlador vuelve a `verificar`
  (`registro_controller.dart:283-285`). Solo el plazo vencido lleva a `incierto`.
- **Después del registro.** Una cuenta nueva llega con `setupComplete` en `false` y
  `postLoginRoute` la manda a `/setup-carrera` (`post_login_route.dart:11-14`). La spec del test,
  aprobada en su rama, pone ahí la carrera, el test en la ruta `/test-especialidad` y la
  selección manual (RF-TEST-1). Su contenido exige el token del alumno, porque el servidor
  resuelve cada `specialtyId` con la carrera del alumno (RS-BE-38 de la spec del backend, rama
  `feat/test-especialidad`). La ruta crea su controlador con `SpecialtyTestBinding`, un `lazyPut`
  sin `fenix`, y en ese controlador viven la regla de una sola evaluación en vuelo, el descarte
  del paso tras un atrás desde la espera y los guardados de uno en uno (RF-TEST-4, RF-TEST-7 y
  RF-TEST-9). Sin `careerId`, el asistente de hoy no guarda y dice «No se pudo determinar tu
  carrera.» (`setup_carrera_controller.dart:91-94`).
- **Los bindings y los avisos.** `main.dart:124-128` recuerda que un `Get.put` fuera de un
  binding, con un aviso abierto, puede atar el controlador a la ruta del aviso, que GetX borra al
  cerrarlo, y con él sus `TextEditingController`.
- **Ulises.** Su imagen es `assets/images/ulises_chatbot.png`, recortada en círculo. En `/home`,
  `ChatbotBubble` lo pone abajo a la izquierda (`chatbot_bubble.dart:73-75`), solo para el alumno
  (`home_page.dart:112`), y sin latido con reducir movimiento (`chatbot_bubble.dart:43-51`).
- **El nombre.** El backend manda el nombre como «APELLIDOS NOMBRES», y `firstName` no es el
  nombre de pila (`user_model.dart:52-65` y `:115-143`). Por eso la spec del test no agrega el
  nombre del alumno a las líneas de Ulises (su decisión abierta 8).
- **La cabecera.** `AppHeader` mide 50 dp de relleno arriba, la fila de 30 dp y 20 dp abajo, más
  un borde de 2 dp, con «ULIMA++» en 20 sp, cursiva y negrita, en blanco
  (`app_header.dart:57-88`). BR-SHELL-F-04, aprobada con la spec del splash, le suma la estrella de
  26 dp.
- **Las pantallas de «¿Olvidaste tu contraseña?».** `/forgot-password` pide el código de alumno o el
  correo, y `/reset-password`, el código de verificación y la contraseña nueva
  (`forgot_password_page.dart` y `reset_password_page.dart`). Las dos usan `PasswordResetScaffold`,
  con fondo `#FF6600` en claro y `#262626` en oscuro, una tarjeta centrada de 340 dp como máximo y
  la flecha «Volver» arriba a la izquierda, y ninguna lleva el logo (`password_reset_ui.dart:36-76`
  y `:100-163`). `/reset-password` también se abre desde el Perfil, con el correo enmascarado
  (`perfil.dart:768-779`), y Portal Sync reusa el mismo scaffold (`portal_sync_page.dart:24`). Sus
  avisos «Solicitud enviada» (`forgot_password_controller.dart:35`), «Código reenviado»
  (`reset_password_controller.dart:196`) y «Código enviado» del Perfil (`perfil.dart:774-779`) son
  `Get.snackbar` arriba.
- **El alumno sin especialidad.** Un alumno con `setupComplete` en `false` abre hoy
  `/setup-carrera` al arrancar con la sesión guardada o al entrar, porque `postLoginRoute` lo manda
  ahí (`post_login_route.dart:11-14`, `main.dart:88` y `login_controller.dart:46`). Suele ser el
  alumno que crea su cuenta y cierra la app antes de elegir su especialidad.

## Requisitos

Los tiempos de la maqueta se cuentan en milisegundos y sus medidas en píxeles de una pantalla de
306 × 646. Por defecto, la app las lleva a dp con un solo criterio (B-27).

- **El dibujo se escala por 1,2.** La maqueta dibuja la estrella de R = 90 dp con 75 px, así que
  lo que se dibuja junto a ella, que es Ulises con su vuelo, su sombra, su estela, sus partículas
  y su salto, se multiplica por 1,2 y guarda la proporción de la maqueta aprobada.
- **La interfaz va en dp iguales a sus píxeles.** La tarjeta del saludo, los botones, las
  burbujas, el compositor, sus textos, sus rellenos y sus márgenes miden en dp o en sp lo mismo
  que en la maqueta, como el resto de la conversación, porque su texto crece con la escala del
  sistema y sus controles tienen el mínimo de 48 dp de RF-BIEN-16. Frente a la estrella se ven un
  poco más chicos que en la maqueta.
- **Las posiciones se anclan.** No se escalan con la pantalla. Cada requisito dice a qué se
  ancla cada pieza, como la estrella al centro de la pantalla (RF-SPL-5) o los botones al borde
  inferior.
- Donde la spec fija una medida propia, manda la spec.

### RF-BIEN-1. La ruta de la bienvenida y quién llega a ella

- **La ruta.** La bienvenida ocupa `/login`, que conserva su nombre y todos sus llamadores
  (decisión S-32). La `GetPage` de `/login` pasa a mostrar la bienvenida, y la tarjeta
  de `login_page.dart` sale de la app, también en web (decisión B-25).
- **Los controladores.** `LoginBinding` sigue registrando `LoginController` como permanente, con
  sus campos, `submit`, `loginWithGoogle` y la escucha de web, y registra también el controlador
  de la bienvenida como permanente (decisión B-19). `LoginBinding` corre dentro del build de la
  ruta (`_getChild` de `default_route.dart`), así que ahí no reinicia nada.
- **Cada montaje es una visita.** Cada vez que la página de la bienvenida se monta, su `State`
  crea un identificador de visita nuevo. Estas son las reglas.
  - El primer cuadro sale solo de los argumentos de la ruta y de ese identificador, que son la
    pose, el motivo o ninguno (RF-BIEN-2 y RF-BIEN-3), y nunca del estado del controlador
    permanente. Mientras el controlador no atiende esa visita, la página pinta ese primer cuadro
    y no lee el estado que queda de la visita anterior, como la franja con el sello tras un
    cierre de sesión.
  - Después de ese cuadro, la página le pide al controlador que empiece su visita. El controlador
    borra la conversación, cierra los tramos del registro y del test si siguen abiertos (RF-BIEN-9 y
    RF-BIEN-10) y mira si hay una sesión puesta, que decide la llegada con sesión (RF-BIEN-21).
    Desde ahí la página pinta su estado. El reinicio no se pinta nunca antes de ese cuadro.
    `LoginController` limpia sus campos también después del cuadro, como hoy
    (`login_binding.dart:28-34`).
  - El `dispose` de la página le avisa al controlador que su visita termina, y el controlador
    lo ignora si ya atiende una visita más nueva. Así, en el restablecimiento de contraseña,
    donde por un momento conviven dos `/login` (`reset_password_controller.dart:159-161`), la
    página vieja no toca la visita nueva.
  - Ese `dispose` es el gancho que cierra los tramos cuando la bienvenida sale del árbol, porque
    GetX nunca retira un controlador permanente con la ruta.
- **La navegación queda en la bienvenida.** `LoginController` deja de navegar. Sus tres caminos,
  el código, Google en Android e iOS y Google en web, devuelven a la bienvenida si la sesión quedó
  puesta o el mensaje del error, y la bienvenida decide el turno siguiente (RF-BIEN-6).
- **`/registro` sale.** Salen la ruta, `RegistroPage` y `RegistroBinding` (decisión B-23).
  `RegistroController`, sus validadores y `RegistroService` siguen y los usa la bienvenida
  (RF-BIEN-7).
- **El motivo de la llegada.** `offAllToLogin` suma un parámetro opcional `motivo`, que viaja como
  argumento de ruta junto a la pose del splash (RF-SPL-21 y decisión B-21). El interceptor del 401
  pasa `expirada` y el restablecimiento de contraseña pasa `restablecida`. El cierre de sesión del
  Perfil y del docente y el botón «Volver a iniciar sesión» del Perfil no pasan ningún motivo y
  no cambian. Como los parámetros nuevos son nombrados y opcionales, `onPressed: offAllToLogin`
  de `perfil.dart:97` sigue compilando. La prueba que prohíbe navegar a `/login` fuera de
  `session_navigation.dart` sigue igual.

| Llegada | Argumentos | Cómo empieza | Requisito |
| --- | --- | --- | --- |
| Arranque en frío sin sesión | La pose del logo | El recibimiento | RF-BIEN-2 |
| Web, que no tiene intro (decisión S-22) | Ninguno | El recibimiento corto | RF-BIEN-3 |
| Cierre de sesión del Perfil o del docente | Ninguno | El recibimiento corto (decisión B-7) | RF-BIEN-3 |
| «Volver a iniciar sesión» del Perfil sin datos | Ninguno | El recibimiento corto (decisión B-7) | RF-BIEN-3 |
| Un 401 con el aviso «Sesión expirada» | `motivo: expirada` | Directo a «Sí, entrar» (decisión B-8) | RF-BIEN-3 |
| Contraseña restablecida | `motivo: restablecida` | Directo a «Sí, entrar» (decisión B-8) | RF-BIEN-3 |
| Arranque en frío con la sesión de un alumno sin especialidad | La pose del logo, o ninguno en web, con la sesión puesta | La llegada con sesión, sin la pregunta ni los dos botones, hasta la invitación al test (decisión B-10) | RF-BIEN-21 |

- **Las salidas.** La bienvenida sale hacia `/home` por el paso al horario (RF-BIEN-11) y hacia
  `/forgot-password`, que se abre encima con `Get.toNamed`, como hoy, con el sello en su cabecera
  (decisión B-9 y RF-BIEN-20). Volver de `/forgot-password` deja la conversación como estaba. Al
  salir hacia `/home`, la bienvenida borra el historial y `LoginController` vacía sus dos campos
  (RF-BIEN-5). Nunca sale hacia `/setup-carrera`, porque el alumno sin especialidad hace el test
  en la conversación (decisión B-10 y RF-BIEN-21).
- **La orientación.** Vertical, como toda ruta fuera de Horario (BR-SHELL-F-00 de app-shell).

`[@test] ../../../test/bienvenida/bienvenida_ruta_test.dart`

### RF-BIEN-2. El recibimiento después del splash

Es lo que ve el alumno sin sesión al abrir la app, entre el relevo del splash y su primera
respuesta. La maqueta lo muestra en las funciones `welcome` y `ulisesLlega`. Con la sesión de un
alumno sin especialidad, el recibimiento es el mismo hasta el aterrizaje de Ulises y cambia desde
ahí (RF-BIEN-21).

- **El primer cuadro.** La bienvenida recibe la pose del logo como argumento de ruta (RF-SPL-21 y
  decisión S-33) y pinta en su primer cuadro `#E77330` de borde a borde y el logo blanco
  en esa pose, con la geometría de RF-SPL-2, en los dos temas. Avisa a la capa del splash cuando
  lo pinta, y la capa se retira sin fundido, así que la pantalla no cambia.
- **Quieto.** Durante 160 ms nada se mueve.
- **El vuelo de Ulises.** Ulises, recortado en círculo, entra desde arriba a la derecha, fuera de
  la pantalla, con 62 dp y una inclinación de −26°. Recorre en 1300 ms, con la curva seno, una
  curva de Bézier cúbica hasta su lugar. Sus puntos son los de la maqueta medidos desde el punto
  de aterrizaje y multiplicados por 1,2, así que el inicio queda a (+353, −578) dp del aterrizaje
  y los de control a (+221, −478) y (−187, −226) dp. En la maqueta la curva va de (360, −44) a
  (66, 438), con los de control en (250, 40) y (−90, 250). Si el inicio cae dentro de la
  pantalla, como en una tableta, se corre hacia arriba y a la derecha hasta quedar fuera de ella.
  Se inclina según su velocidad, hasta 14° a mitad del vuelo, se comprime cinco veces como un
  aleteo, crece hasta 70 dp y deja una estela de puntos blancos de 7 dp que se apagan en 560 ms, a
  lo sumo 30 por vuelo. Su sombra en el suelo crece al acercarse.
- **El aterrizaje.** Se posa con un rebote de 480 ms que lo aplasta contra el suelo y lo estira
  antes de asentarse, y suelta seis partículas blancas. Enseguida asiente en 320 ms, con un giro
  de −6° y un 6 % más de escala, mientras aparece su saludo.
- **El fondo.** Mientras Ulises vuela, el fondo pasa en 1100 ms, con la curva seno, de `#E77330`
  al color de la franja, que es `#FF6600` en claro y `#262626` en oscuro (RF-BIEN-14). El logo
  sigue blanco y quieto.
- **Dónde queda cada cosa.** Con la opción por defecto de B-27, las posiciones se calculan una
  vez, al empezar el vuelo, con la escala de texto de ese momento.
  - La estrella se queda en su pose, entera y sin nada encima, con un margen libre de 12 dp
    alrededor de su círculo.
  - Ulises aterriza abajo a la izquierda de la estrella, con 70 dp y su centro 104 dp a la
    izquierda y 138 dp debajo del centro de la estrella, que es su lugar en la maqueta,
    (−87, +115) px, multiplicado por 1,2.
  - La tarjeta del saludo va a su derecha, desde 11 dp después del borde derecho de Ulises hasta
    12 dp del borde derecho de la columna (RF-BIEN-17), con su borde superior 22 dp arriba del
    centro de Ulises, radio de 18 dp y relleno de 9 dp arriba, 13 dp a los lados y 11 dp abajo.
    Su pico es un cuadrado de 14 dp girado 45°, que asoma 5 dp por la izquierda a 17 dp del borde
    superior, hacia Ulises.
  - Los dos botones van abajo, a 22 dp de los lados y 26 dp sobre el borde inferior del área
    segura, con 10 dp entre ellos y un alto de 50 dp como mínimo, que crece si el texto lo pide,
    «Sí, entrar» arriba y «Soy nuevo» abajo.
- **En el iPhone SE del dueño.** Con 375 × 667 dp, sin barra inferior y con el texto al 100 %, la
  estrella queda en el centro, a 333,5 dp del borde superior, y no se mueve. Ulises aterriza con
  su centro a (83,5; 471,5) dp, el borde superior de la tarjeta queda unos 14 dp por debajo del
  margen de la estrella y su borde inferior, unos 22 dp por encima de los botones, que empiezan
  a 531 dp. Con el texto al 130 %, si el saludo pasa a dos líneas, la estrella sube unos 15 dp,
  y al 200 % sube unos 95 dp (B-28). Son estimaciones con los altos de línea de «El saludo», y
  `bienvenida_recibimiento_test` las fija en 375 × 667.
- **Si no cabe (B-28).** Si el borde inferior de Ulises o de la tarjeta queda a menos de 16 dp de
  los botones, por una pantalla baja o por la escala de texto, Ulises y la tarjeta suben juntos lo
  justo. Si al subir entran en el margen de la estrella, la estrella sube lo justo antes de que
  Ulises aterrice, en 300 ms con easeInOutCubic, sin acercarse a menos de 24 dp del área segura de
  arriba, y si aun así no cabe, su radio baja en el mismo movimiento, hasta 60 dp como mínimo. Si
  ni así cabe, no hay tarjeta ni botones grandes, y al aterrizar Ulises la estrella sube al sello
  y la conversación empieza con su primer grupo, «¡Craa! Hola, soy Ulises 👋» y «¿Ya usas
  ULima++?», y las respuestas rápidas «Sí, entrar» y «Soy nuevo». Nada tapa nunca la estrella.
- **El saludo.** La tarjeta entra en 360 ms con un leve rebote, con «¡Craa! Hola, soy Ulises 👋»
  en 12 sp, seminegrita y alto de línea 1,4, y debajo, a 1 dp, «¿Ya usas ULima++?» en 17 sp,
  negrita y alto de línea 1,25. Una línea que no cabe a lo ancho pasa a dos. 380 ms después
  entran los botones, en 400 ms, desde 18 dp más abajo (decisión B-2). Los toques cuentan desde
  que los botones empiezan a entrar, y antes no hacen nada.
- **Los botones.** «Sí, entrar» va relleno y «Soy nuevo» con borde, en 16 sp y negrita, con radio
  de 16 dp y los colores de RF-BIEN-14 (decisión B-3). Cada uno se oscurece un 7 % al tocarlo.
- **Al responder.** La tarjeta y los botones se van en 280 ms, el logo sube al sello (RF-BIEN-4)
  y Ulises salta a su avatar en la conversación, que ya trae su primer grupo con el nombre
  «Ulises», las burbujas «¡Craa! Hola, soy Ulises 👋» y «¿Ya usas ULima++?» y la respuesta del
  alumno, «Sí, entrar» o «Soy nuevo» (RF-BIEN-5).
- **El salto de Ulises.** Empieza 120 ms después del toque. Se agacha en 190 ms y salta en 720 ms
  hasta su avatar de 40 dp, en un arco con los puntos de control 144 dp sobre su lugar y 132 dp
  sobre el avatar, que son los 120 y 110 px de la maqueta multiplicados por 1,2, y se posa con el
  rebote al 60 %. Al posarse, su avatar queda en la conversación y el nombre «Ulises» aparece en
  250 ms. 650 ms después empieza el primer turno de la rama elegida.
- **Tiempo.** La tarjeta aparece 1,94 s después del relevo y los botones empiezan a entrar a los
  2,32 s, enteros a los 2,72 s. Sumada la entrada del splash, de 1,15 a 1,33 s, el que vuelve
  puede tocar «Sí, entrar» de 3,5 a 3,7 s después del primer cuadro de Flutter, unos 3 s más
  tarde que hoy la tarjeta del login, que aparece apenas terminan Firebase y el almacenamiento
  (decisiones B-2 y S-6).

`[@test] ../../../test/bienvenida/bienvenida_recibimiento_test.dart`

### RF-BIEN-3. Llegar sin pose

- **Recibimiento corto.** Sin argumentos, el primer cuadro es `#E77330` de borde a borde con el
  logo completo en su pose de reposo, la estrella de R = 90 dp centrada en la pantalla física
  (RF-SPL-5) y los «++» en su lugar (RF-SPL-2). Es la llegada de web, del cierre de sesión y del
  botón «Volver a iniciar sesión» del Perfil (decisión B-7), y también la del alumno con sesión y
  sin especialidad en web (RF-BIEN-21). En web la estrella se centra en la vista, porque en el
  navegador `display.size` da el tamaño del monitor y no el de la ventana. Desde ahí sigue igual
  que RF-BIEN-2, desde «Quieto», o que RF-BIEN-21 si hay una sesión puesta. La bienvenida precarga
  la imagen de Ulises al montarse, porque sin pose no la precargó el splash.
- **Directo a «Sí, entrar».** Con `motivo: expirada` o `motivo: restablecida`, la bienvenida
  abre con la franja y el sello ya en su lugar (RF-BIEN-4), el primer grupo de Ulises con
  «¡Craa! Hola, soy Ulises 👋» y el primer turno de «Sí, entrar» (RF-BIEN-6), sin la pregunta ni
  los dos botones grandes (decisión B-8). «Soy nuevo» queda en el compositor, como en todo turno de
  esa rama (RF-BIEN-9). Los avisos «Sesión expirada» y «Contraseña actualizada» conservan su
  texto de hoy y salen abajo, no sobre el sello (B-29).
- En los dos casos, el sello y su logo están enteros desde el primer cuadro.

`[@test] ../../../test/bienvenida/bienvenida_recibimiento_test.dart`

### RF-BIEN-4. El sello, el latido y el pulso

- **La franja.** Mide lo mismo que la cabecera de `/home` (`app_header.dart:57-65`), va de borde
  a borde desde el borde superior de la pantalla, detrás de la barra de estado, y tiene las
  esquinas inferiores redondeadas en 26 dp, en el color de la franja (RF-BIEN-14).
- **El sello.** Es la estrella de BR-SHELL-F-04 y el texto «ULIMA++» de la cabecera, los dos a
  1,22 veces su tamaño, centrados a lo ancho y a la altura de la fila de la cabecera. «ULIMA» usa
  el estilo único de `app_header.dart` (RF-SPL-11), así que sigue la escala de texto del sistema
  como la cabecera, y los «++» son las cruces del logo (RF-SPL-2), inclinadas −12°.
- **La subida.** Empieza 90 ms después de la respuesta y dura 900 ms, con easeInOutCubic. El fondo
  de pantalla completa se recoge hasta la franja y sus esquinas inferiores pasan de 0 a 26 dp. La
  estrella va de su pose a su lugar en el sello, se achica hasta 1,22 × 26 dp de punta a punta y
  gira 45°, que por su simetría de orden ocho se ve igual. Cada «+» sale al 22 % del tiempo, el
  segundo un 6 % después, salta en un arco de 18 dp y cae tras «ULIMA», que se revela de
  izquierda a derecha desde el 55 %.
- **El logo no se pierde.** Desde el relevo del splash hasta el paso al horario, la estrella y
  sus «++» están enteros y a la vista, sin nada encima, también con el teclado abierto, durante
  el envío, en cualquier error y con reducir movimiento, donde cada cambio es un fundido cruzado
  que deja siempre un logo a la vista (RF-BIEN-15). Ningún aviso, confeti ni capa pasa sobre el
  sello. Los avisos de GetX salen abajo (B-29), y el confeti del test se dibuja bajo la franja
  (RF-BIEN-10).
- **En todo recorrido.** Con B-9 y B-10 en la opción que el dueño elige el 2026-09-26, el logo no
  se deja de ver en ningún recorrido. Las pantallas de «¿Olvidaste tu contraseña?» llevan el sello
  en su cabecera (RF-BIEN-20), y el alumno con cuenta que todavía no elige su especialidad hace el
  test en la conversación, con el logo en el sello, en lugar de ir al asistente de carrera
  (RF-BIEN-21).
- **El latido.** Con cada respuesta del alumno y al posarse el sello, la estrella late durante
  380 ms. Su escala sube un 13 % en el primer 42 % del latido y un 5 % entre el 48 % y el 92 %,
  cada vez con la forma de medio seno, y un anillo blanco crece de 0,62 a 1,5 veces el radio de
  la estrella, con easeOutCubic, mientras su opacidad baja de 0,55 a 0. Los «++» y «ULIMA» no
  laten.
- **El pulso.** Mientras se envía el registro (RF-BIEN-8), un pulso recorre los ocho rombos en
  sentido horario desde el de arriba, con un período de 1100 ms. La opacidad de cada rombo es
  0,42 + 0,58 × máx(0; 1 − d / 2,4), donde d es la distancia circular, en rombos, entre ese rombo y
  la posición del pulso. La estrella central y los «++» quedan enteros. Con cualquier desenlace
  del envío, los rombos vuelven a la opacidad plena en 200 ms.
- **Semántica.** El sello es un encabezado con la etiqueta «ULIMA++», que el lector anuncia una
  vez. El dibujo queda fuera de la semántica.
- **Sin estrella en la cabecera.** Con la alternativa de la decisión S-11, el sello
  conserva su estrella, y en el paso al horario la estrella se achica hasta la altura del texto y
  se disuelve a su izquierda, como en RF-SPL-11.

`[@test] ../../../test/bienvenida/bienvenida_sello_test.dart`

### RF-BIEN-5. La conversación

- **Las partes.** De arriba abajo van la franja con el sello, la conversación, que desplaza, y el
  compositor, fijo abajo y sobre el teclado. La píldora de estado del registro flota centrada, 8 dp
  bajo la franja (RF-BIEN-8). El fondo de la conversación es `pageBg`.
- **Los grupos de Ulises.** El primer grupo lleva el avatar de 40 dp y el nombre «Ulises» en
  11 sp, negrita y `testMuted`. Los siguientes llevan el avatar de 28 dp, sin nombre, arriba a la
  izquierda de sus burbujas. Cada burbuja va en `cardBg` con borde de 1 dp en `testLine`, radio de
  18 dp, con la esquina superior izquierda de la primera del grupo en 6 dp, relleno de 7 × 12 dp,
  texto de 14 sp en `textPrimary` y un ancho de hasta el 74 % de la columna.
- **Las respuestas del alumno.** Van a la derecha, en `bienvenidaPropia` con el texto en
  `bienvenidaPropiaTinta` y negrita, con radio de 18 dp y la esquina inferior derecha en 6 dp, y
  un ancho de hasta el 72 % de la columna. Un dato secreto se muestra como un candado y un rótulo,
  nunca con su valor (RF-BIEN-9).
- **El ritmo.** Dentro de un turno, cada burbuja de Ulises entra 850 ms después de la anterior y
  el compositor 500 ms después de la última. Cada burbuja entra en 340 ms, subiendo 8 dp y de
  98 % a 100 % de escala con un leve rebote, y la conversación se desplaza en 450 ms hasta el
  final. No hay puntos de «escribiendo», como en el test (RF-TEST-4). Con lector de pantalla, las
  burbujas de un turno entran juntas (RF-BIEN-16).
- **El compositor.** Va en `cardBg`, con un borde superior de 1 dp en `testLine` y un relleno de
  10, 12 y 24 dp más el área segura inferior. Entra en 300 ms, subiendo 8 dp. Mide hasta el 60 % del
  alto disponible sobre el teclado y, si su contenido es más alto, desplaza por dentro. Sus
  piezas son estas.

| Pieza | Cómo es |
| --- | --- |
| Rótulo | 11,5 sp, negrita, en `testInk2`, 5 dp sobre su campo |
| Campo | 48 dp de alto como mínimo, radio de 14 dp, fondo `testChipBg` y texto de 15 sp en `textPrimary`. Con foco, fondo `cardBg` y borde de 2 dp en `bienvenidaFoco`. La pista va en `testMuted` y no en el `#8A94A6` de la maqueta, que da 2,72:1 |
| Ojo de la contraseña | Botón de 48 dp dentro del campo, con el ícono de hoy (`registro_page.dart:107-127`) en `testMuted` |
| Botón de envío | Círculo de 48 dp a la derecha del último campo, con la flecha en `testAccentInk` sobre el degradado de `testAccentHi` a `testAccent`. Inactivo, al 40 %, mientras el campo está vacío |
| Respuestas rápidas | Píldoras de 48 dp de alto, alineadas a la derecha, con borde de 1,5 dp en `testAccent` y texto de 14 sp en negrita y `testAccentText`. La principal va rellena con el degradado y el texto en `testAccentInk` |
| Botón principal | A lo ancho, 48 dp de alto, radio de 15 dp, relleno con el degradado y texto de 15 sp en negrita y `testAccentInk`. Mientras espera, un indicador de 20 dp en su lugar |
| Enlace secundario | Texto de 13 sp en negrita y `testAccentText`, centrado, con 48 dp de alto táctil. «¿Olvidaste tu contraseña?» va en `testMuted`, como en la maqueta |
| Error local | Bajo el campo, 12 sp en `testAccentText` con el ícono `LucideIcons.circleAlert`, como región viva |

- **Al responder.** El compositor se cierra, entra la burbuja del alumno, el sello late y 650 ms
  después empieza el turno siguiente.
- **Los errores de Ulises.** Un error del backend o de la red es una burbuja de Ulises con el
  ícono `LucideIcons.circleAlert` en `testAccentText` a la izquierda del texto (RF-BIEN-12). Un
  error de validación local va bajo el campo y no entra en la conversación.
- **El historial.** Vive solo en la memoria del controlador de la bienvenida, como el texto de las
  burbujas. No se guarda en disco y se borra al reiniciar la bienvenida, también tras el 401 de
  RF-BIEN-12, y al salir de ella por el paso al horario. Es de solo lectura, y tocar una burbuja
  no hace nada.
- **Los campos del login al salir.** En esas mismas salidas y en ese reinicio, `LoginController`
  vacía el código y la contraseña. Hoy la contraseña de ULima++ queda en `passwordController`
  durante toda la sesión, porque `resetFields` solo corre al volver a `/login`, y la bienvenida
  deja de arrastrarla.
- **El teclado.** Cuando el compositor trae un campo, el campo toma el foco y el teclado se abre,
  salvo con lector de pantalla (RF-BIEN-16). La conversación se encoge, la franja queda arriba y
  el último mensaje a la vista. La acción «Siguiente» del teclado pasa de «Contraseña» a «Repetir
  contraseña», y «Listo» o Intro envían. Arrastrar la conversación cierra el teclado, como hoy en
  el login (`login_page.dart:30`).

`[@test] ../../../test/bienvenida/bienvenida_conversacion_test.dart`

### RF-BIEN-6. «Sí, entrar»

Es el inicio de sesión dentro de la conversación, con las reglas de BR-AUTH-F-01 a BR-AUTH-F-10
de auth, enmendadas («Cambios en otras specs»).

| Turno | Ulises dice | Compositor | Respuesta del alumno |
| --- | --- | --- | --- |
| E1, código | «¡Qué bueno verte! ¿Cuál es tu código o usuario?» | Rótulo «Código», campo con la pista «Tu código o usuario», teclado de texto y el botón de envío. Debajo, el separador «o», el botón «Continuar con Google» y el enlace «Soy nuevo» | El código o usuario tal como se escribió, recortado |
| E2, contraseña | «Y tu contraseña de ULima++.» | Rótulo «Contraseña», campo con la pista «Tu contraseña» y el ojo, el botón principal «Entrar» y los enlaces «¿Olvidaste tu contraseña?» y «Soy nuevo» | Un candado y «Contraseña lista» |
| E3, despedida | «¡Hola de nuevo! Te llevo a tu horario 🪶» | Ninguno | Ninguna. Sigue el paso al horario (RF-BIEN-11) |

- **Los campos.** Son los `TextEditingController` de `LoginController`, con las pistas de
  autocompletado de hoy, usuario en E1 y contraseña en E2 (`login_page.dart:105` y `:117`). El
  campo de E1 acepta el usuario alfanumérico del docente y no valida dígitos. El botón de envío de
  E1 y «Entrar» quedan inactivos mientras su campo está vacío, así que el mensaje «Ingresa tu
  código y contraseña.» sigue en `LoginController` solo como defensa.
- **El autocompletado.** Los campos de E1 y de E2 van en un mismo `AutofillGroup`. Durante E2, el
  campo de E1 sigue montado dentro del grupo, invisible y fuera de la semántica, para que el
  llavero de iOS y el gestor de contraseñas de Google emparejen el usuario con la contraseña.
  Cuando la sesión queda puesta, la bienvenida llama a `TextInput.finishAutofillContext()` antes
  de vaciar los campos, para que el sistema ofrezca guardarlos. Si la revisión manual de
  «Verificación» muestra que no los emparejan o no ofrecen guardarlos, la implementación se
  detiene y el cambio vuelve a esta spec.
- **Entrar.** «Entrar» llama a `AuthService.login` por `LoginController`. Mientras espera, el
  botón muestra su indicador y el compositor no responde (BR-AUTH-F-08). Si la sesión queda
  puesta, el compositor se cierra, entra la respuesta del alumno, el sello late, Ulises dice la
  despedida y, 900 ms después, empieza el paso al horario. Con la configuración a medias, en lugar
  de la despedida sigue el test, como dice «Adónde va».
- **El error del login.** Ulises dice el mensaje de hoy (`auth_service.dart:28-36`) y la
  conversación vuelve a E1, con el código escrito y la contraseña vacía (decisión B-6). Ese mensaje
  nunca ofrece crear una cuenta (RF-BIEN-9).
- **Sin conexión.** `LoginController.submit` atrapa el fallo crudo de la red que
  `AuthService.login` no atrapa, con un `finally` que apaga `submitting` en todos los casos, y le
  devuelve a la bienvenida el resultado «sin conexión». Ulises dice «No hay conexión. Revisa tu
  internet e inténtalo de nuevo.» y E2 sigue abierto con la contraseña escrita. El botón deja de
  girar, lo que corrige el defecto de hoy, y en web `_onGoogleUserChanged`
  (`login_controller.dart:36`) no queda bloqueado por un `submitting` colgado. Si el fallo llega
  después de que `login` guarde el token y antes de los catálogos, el token queda guardado sin
  usuario, una deuda previa que anota «Qué NO entra».
- **Google en Android e iOS.** «Continuar con Google» es el botón propio, con el logo oficial de
  `google_logo.svg` en 20 dp, 48 dp de alto, radio de 12 dp y los colores de la marca de Google
  (RF-BIEN-14), y llama a `loginWithGoogle`. Si la persona cancela el selector, no pasa nada. Si
  la sesión queda puesta, la respuesta del alumno es una burbuja con el logo de Google y
  «Continuar con Google», y sigue E3 o, con la configuración a medias, el test (RF-BIEN-21). Un
  error se dice como burbuja de Ulises y E1 sigue abierto.
- **Google en web.** Va el botón oficial de GIS en lugar del propio, con el texto `continueWith`,
  el idioma `es`, el tema `outline` en claro y `filledBlack` en oscuro, la forma rectangular, el
  logo a la izquierda y el ancho del compositor hasta 400 px, el máximo de GIS (decisión B-25).
  Esos valores salen de una función pura de `lib/domain/bienvenida/` (decisión B-35).
  - **La cuenta.** Sigue llegando por `onCurrentUserChanged`, sin nadie que espere un resultado.
    `LoginController` publica el desenlace de `finishGoogleLogin`, la sesión puesta o el mensaje
    del error, en un resultado observable, que la bienvenida escucha mientras E1 está abierto y
    trata igual que el de Android e iOS.
  - **El tema.** La configuración queda fija al dibujar el botón, así que un cambio del tema del
    sistema con E1 abierto lo vuelve a dibujar. El aviso de GIS por un `initialize()` repetido
    que eso puede dejar en la consola se acepta, porque web no se despliega.
- **«¿Olvidaste tu contraseña?».** Abre `/forgot-password` encima de la bienvenida, como hoy, y
  sus dos pantallas llevan el sello en su cabecera (decisión B-9 y RF-BIEN-20).
- **«Soy nuevo».** Está en E1 y en E2. Al tocarlo, entra la respuesta «Soy nuevo», los campos del
  login se vacían y empieza el primer turno de RF-BIEN-7. Lo escrito no pasa de una rama a la
  otra, como hoy entre `/login` y `/registro`.
- **Adónde va.** Con la sesión puesta, un docente o un alumno con la configuración completa va al
  paso al horario, con E3. Un alumno con la configuración a medias sigue en la conversación con
  el test, y en lugar de E3 Ulises dice «¡Hola de nuevo! Te falta elegir tu especialidad.» y,
  650 ms después, empieza T0 (decisión B-10 y RF-BIEN-21). La bienvenida decide con
  `postLoginRoute`, que no cambia y sigue dando `/setup-carrera` para ese alumno, sin navegar a
  esa ruta.

`[@test] ../../../test/bienvenida/bienvenida_entrar_test.dart`

### RF-BIEN-7. «Soy nuevo», los datos de la cuenta

Es el registro de hoy, con sus reglas BR-REG-F-01 a BR-REG-F-11, repartido en turnos. El orden es
el de BR-REG-F-01, con el consentimiento antes del portal y el código del authenticator al final,
justo antes del botón que envía.

| Turno | Ulises dice | Compositor | Respuesta del alumno |
| --- | --- | --- | --- |
| N1, código | «¡Genial! Tu cuenta se crea aquí mismo.» y «¿Cuál es tu código de alumno?» | Rótulo «Código de alumno», campo con la pista «Tu código de alumno», teclado numérico y el botón de envío. Debajo, el enlace «Ya tengo cuenta» | El código, recortado |
| N2, contraseña de ULima++ | «Ahora elige la contraseña con la que entrarás a ULima++. No es la de miUlima.» | Rótulo «Contraseña», campo con la pista «Al menos 8 caracteres» y el ojo, rótulo «Repetir contraseña», campo con la pista «La misma otra vez» y el botón de envío. Debajo, los enlaces «Volver» y «Ya tengo cuenta» | Un candado y «Contraseña de ULima++ lista» |
| N3, consentimiento | «Para traer tus cursos entro a miUlima una sola vez. Antes, lee esto 👇» y la tarjeta del consentimiento | Las respuestas rápidas «Volver» y «Acepto», la principal, y el enlace «Ya tengo cuenta» | «Acepto» o «Volver» |
| N4, contraseña de miUlima | «Tu contraseña de miUlima, la del portal.» | Rótulo «Contraseña de miUlima», campo con la pista «Tu contraseña del portal», el ojo y el botón de envío. Debajo, «Volver» y «Ya tengo cuenta» | Un candado y «Contraseña de miUlima lista» |
| N5, authenticator | «Último paso. El código de tu authenticator.» | Rótulo «Código del authenticator», el campo de seis casillas de hoy (`PasswordResetOtpField`), la nota «El código de 6 dígitos que cambia cada 30 segundos.» y el botón principal «Crear mi cuenta». Debajo, «Volver» y «Ya tengo cuenta» | Un candado y «Código del authenticator listo» |

- **La tarjeta del consentimiento.** Es una burbuja ancha de Ulises con los textos literales de
  `PortalConsentView`, tomados de sus constantes, que son el título «Antes de entrar a miUlima»,
  la introducción, los cuatro datos importados como lista, la finalidad y «Tu contraseña se usa
  una sola vez y no se guarda.» en negrita (`portal_consent_view.dart:41-56`). Así dice lo mismo
  que la pantalla de Portal Sync (RF-REC-6).
- **La validación.** Cada turno valida lo suyo en local, con los validadores de hoy, antes de
  cerrar el compositor y sin llamar a la red (BR-REG-F-03). N1 usa `validarCodigo`, N2 usa
  `validateNewPassword` y `validatePasswordConfirmation`, N4 usa `validarPortalPassword` y N5 usa
  `validarPasscode`, que acepta de 6 a 8 dígitos. Sus mensajes van bajo el campo.
- **El envío es un botón.** N5 no envía solo al completar las seis casillas, porque SecurID da 8
  dígitos con el PIN delante y cada envío fallido gasta uno de los cinco intentos por hora
  (decisión B-5).
- **«Volver».** Reabre el turno anterior con lo que se escribió, como hoy entre pasos
  (BR-REG-F-05). Entra la respuesta «Volver» y Ulises repite la pregunta de ese turno. Aceptado
  una vez, el consentimiento dura lo que dura la rama, así que al volver a avanzar desde N2 se
  pasa directo a N4, como hace hoy `continuar` (`registro_controller.dart:181-183`).
- **«Ya tengo cuenta».** Está en todos los turnos antes del envío. Al tocarlo, entra la respuesta
  «Ya tengo cuenta», el tramo del registro se cierra y borra sus cinco campos (RF-BIEN-9) y
  empieza E1 de RF-BIEN-6.
- **El paso a `verificar`.** Al aceptar en N3 se llama a `aceptarConsentimiento`, y al enviar en
  N5 se llama a `enviar`, con el código recortado y el consentimiento, como hoy.

`[@test] ../../../test/bienvenida/bienvenida_registro_test.dart`

### RF-BIEN-8. El envío del registro y sus desenlaces

- **Mientras se envía.** Se cierra el compositor, entra la respuesta de N5 y Ulises dice «Estoy
  creando tu cuenta y trayendo tu ciclo.» y, en otra burbuja, la advertencia de hoy, «Puede tomar
  un par de minutos: no cierres la app.» (`registro_page.dart:301-302` y decisión B-17). La
  píldora «Creando tu cuenta…», con su indicador, aparece bajo la franja y el pulso recorre los
  rombos del sello (RF-BIEN-4). No hay «Volver» ni «Ya tengo cuenta».
- **El plazo.** Es el de `RegistroService`, 120 s, y su vencimiento no es un fallo (BR-REG-F-08).
- **No se sale.** Un `PopScope` de la bienvenida veta el atrás del sistema mientras se envía y
  muestra el aviso de hoy, «Estamos creando tu cuenta» con «No cierres la app: si sales ahora
  podrías quedarte con una cuenta a medias.» (BR-REG-F-09 y `registro_page.dart:73-78`), que por
  defecto sale abajo y no sobre el sello (decisión B-29).
- **Un 201.** Se para el pulso, la píldora pasa a verde con un visto y «Cuenta creada», y Ulises
  dice en una sola burbuja, como en la maqueta, «¡Craa! Tu cuenta ya está lista.» seguido de la
  frase del conteo. Con N cursos en el resumen, la frase es «Traje tus N cursos del ciclo.» y con
  uno es «Traje tu curso del ciclo.». Con 0 cursos no va, y tampoco sin `summary`, porque
  entonces `RegistroResult.fromJson` deja el conteo en 0 (`registro_models.dart:41-52`). El
  nombre no se agrega (decisión B-4). Las cifras «Clases en tu horario» y «Cursos de tu avance»
  del resumen de hoy no aparecen (decisión B-31). La píldora se va 900 ms después.
- **Los avisos del 201.** Si la respuesta trae `warnings`, Ulises suma una burbuja con «Algunas
  cosas que notamos» en negrita y cada `message` tal cual en su línea, precedido de «· », como hoy
  en `listo` (`registro_page.dart:339-354`). Un 201 con avisos es un éxito (BR-REG-F-07).
- **Después del 201.** `adoptarSesion` guarda la sesión como hoy, con los catálogos tolerantes a
  fallos, y nada de lo que pase después se convierte en un error (BR-REG-F-10). El tramo del
  registro se cierra y borra sus campos (RF-BIEN-9), y sigue el test (RF-BIEN-10). No hay botón
  «Entrar».
- **Un error del backend.** Ulises dice el mensaje de `RegistroService.mensajeDeError`, con los
  textos de hoy, y el compositor vuelve al turno que corresponde, sin repetir la pregunta. Los
  códigos que hoy vuelven a `datos` (`USER_ALREADY_EXISTS`, `INVALID_REQUEST_BODY` e
  `INVALID_JSON_BODY`) vuelven a N1, y los que vuelven a `verificar`, a N5
  (`registro_controller.dart:265-286`). Todo lo escrito se conserva salvo el código del
  authenticator, que se borra (BR-REG-F-05). Desde N5, «Volver» lleva a N4 con la contraseña de
  miUlima intacta.
- **Sin conexión.** Si la red falla antes de que llegue la respuesta, también porque el sistema
  corta la conexión con la app en segundo plano, `RegistroService` lo traduce a `SIN_CONEXION`
  (`registro_service.dart:65-71`). Ulises dice «No hay conexión. Revisa tu internet e inténtalo de
  nuevo.» y el compositor vuelve a N5, como hoy vuelve a `verificar`
  (`registro_controller.dart:283-285`). Como el pedido pudo llegar al servidor, un reenvío puede
  recibir el 409 de la fila siguiente, que confirma que la cuenta existe (decisión B-32).
- **Ya existe una cuenta.** Con `USER_ALREADY_EXISTS`, Ulises dice el texto de hoy, «Ya existe una
  cuenta con ese código. Inicia sesión o recupera tu contraseña.», y el compositor vuelve a N1,
  que trae «Ya tengo cuenta». Ese enlace lleva a iniciar sesión y, desde E2, a «¿Olvidaste tu
  contraseña?». El texto no nombra el enlace, y se deja así como riesgo conocido para no cambiar
  `RegistroService`.
- **Incierto.** Con el plazo vencido, Ulises dice «No pudimos confirmar si tu cuenta se creó.» y
  «Es posible que sí se haya creado. Prueba entrar con el código y la contraseña que acabas de
  elegir.». Con `SIN_TOKEN`, el 201 ya llegó, y dice «Tu cuenta ya está creada.» y «Entra con el
  código y la contraseña que acabas de elegir.», más el mensaje del error si no repite el título
  (`registro_page.dart:405-433`). Los dos títulos son los de hoy con un punto final. El
  compositor trae las respuestas rápidas «Volver a intentar el registro» e «Iniciar sesión», la
  principal (BR-REG-F-11), y debajo el enlace «Ya tengo cuenta», que cierra el tramo del registro
  y lleva a E1 (decisión B-30).
- **«Iniciar sesión» desde incierto.** Llama a `intentarIniciarSesion`, con la píldora principal
  en espera y sin segundo toque. Si entra, la cuenta existía y sigue el test (RF-BIEN-10), o el
  paso al horario si la configuración ya está completa. Si no entra, Ulises dice «Seguimos sin
  poder confirmarlo. Puedes volver a intentar el registro: si te dice que ya existe una cuenta
  con ese código, es que sí se creó y puedes recuperar la contraseña con “Ya tengo cuenta”.», o
  el mensaje sin conexión, y el turno sigue igual. El texto de hoy termina en «desde el login»
  (`registro_controller.dart:321-323`), una pantalla que ya no existe, y por defecto nombra el
  enlace que el alumno tiene a la vista (decisión B-30).
- **«Volver a intentar el registro».** Vuelve a N5 con el código del authenticator borrado y la
  contraseña de miUlima intacta.

`[@test] ../../../test/bienvenida/bienvenida_registro_test.dart`

### RF-BIEN-9. Las credenciales y la enumeración de cuentas

- **Los cinco campos.** El código, la contraseña de ULima++, su repetición, la contraseña de
  miUlima y el código del authenticator viven en los `TextEditingController` de
  `RegistroController` (RS-FE-6). Las dos contraseñas, la repetición y el código del
  authenticator no entran nunca en un `Rx`, en el historial, en un registro ni en el disco, y el
  historial solo guarda sus rótulos, como «Contraseña de ULima++ lista». El código de alumno es
  la excepción, porque su burbuja lo muestra, como en la maqueta. Entra en el historial como texto
  y muere con él (RF-BIEN-5), igual que el código o usuario de E1. Hoy el comentario de
  `registro_controller.dart:100-102` deja fuera de todo `Rx` también el código, y la enmienda del
  registro lo anota.
- **Quién crea y cierra el controlador.** La bienvenida crea `RegistroController` al empezar N1 y
  lo cierra ella misma, sin `Get.put`, porque un aviso abierto, como «Sesión expirada», ataría el
  controlador a la ruta del aviso (`main.dart:124-128`). Cerrarlo borra los cinco campos con
  `clear` enseguida, como `onClose`, y el `dispose` de sus `TextEditingController` va después del
  cuadro en que el campo del compositor ya no está en el árbol, para no reabrir el error de un
  `TextEditingController` usado después de su `dispose` (decisión B-20).
- **Cuándo se cierra.** Al tocar «Ya tengo cuenta», también desde `incierto`, al pasar al test
  después de adoptar la sesión, al reiniciar la bienvenida, también tras el 401 de RF-BIEN-12, y
  en el `dispose` de la página de la bienvenida, guardado por la visita (RF-BIEN-1). GetX nunca lo
  cierra con la ruta, porque el controlador de la bienvenida es permanente. Las contraseñas de
  miUlima y el código del authenticator se borran además apenas se usan, como hoy
  (`registro_controller.dart:244-246`). La contraseña de ULima++ vive en `passwordCtrl` desde N2
  hasta que el tramo se cierra, y en `incierto` es la que usa «Iniciar sesión» (BR-REG-F-11).
- **Las dos contraseñas nunca a la vez.** La de ULima++ y la de miUlima van en turnos distintos
  del compositor, con el consentimiento en medio, y el compositor de una se cierra antes de que
  aparezca el de la otra (RS-FE-2).
- **Sin oráculo de cuentas.** «Soy nuevo» está siempre en los turnos de «Sí, entrar», y «Ya
  tengo cuenta» en todos los turnos del registro antes del envío y en `incierto`, fijos, como hoy
  los enlaces del login y del registro (RS-FE-3 y BR-REG-F-02). Ningún texto de Ulises ofrece
  crear una cuenta ni cambia según por qué falló un login, también tras «Tu correo no está
  registrado en el sistema.» de Google. Ningún turno anterior al envío consulta al backend por un
  código, y la pregunta «¿Ya usas ULima++?» no depende de nada guardado en el teléfono.
- **La deuda de hoy.** El `409 USER_ALREADY_EXISTS` del backend sigue distinguiendo por sí mismo
  si un código tiene cuenta, como anota la spec del registro en «Deuda conocida». La bienvenida
  no lo agrava ni lo arregla.

`[@test] ../../../test/bienvenida/bienvenida_credenciales_test.dart`

### RF-BIEN-10. El test dentro de la conversación

El alumno nuevo, y el que tiene cuenta y todavía no elige su especialidad (RF-BIEN-21), hacen el
test de especialidad sin salir de la conversación, con el mismo servicio, el mismo contenido y las
mismas reglas de la spec del test (RF-TEST-2 y RF-TEST-4 a RF-TEST-14), dibujados como turnos. Es
la enmienda a esa spec que el dueño aprueba el 2026-09-26 («Cambios en otras specs»).

- **Cuándo empieza.** Después del 201 y de adoptar la sesión, después de entrar desde
  `incierto` o con «Sí, entrar» con la configuración a medias, o al llegar con la sesión de un
  alumno sin especialidad (RF-BIEN-21). El contenido exige el token, así que el test no empieza
  mientras se crea la cuenta (decisión B-1).
- **El controlador del test.** Es el mismo que usa la ruta `/test-especialidad`, con la regla de
  una sola evaluación en vuelo, el descarte del paso tras un atrás desde la espera y los guardados
  de uno en uno (RF-TEST-4, RF-TEST-7 y RF-TEST-9). En `/login` no existe `SpecialtyTestBinding`,
  así que la bienvenida lo crea ella misma al empezar T0, sin `Get.put`, por el mismo riesgo de
  `main.dart:124-128` que en el registro, y lo cierra ella misma al pasar al horario, al
  reiniciarse, también tras el 401 de RF-BIEN-12, y en el `dispose` de su página, guardado por la
  visita (RF-BIEN-1 y decisión B-34). Al cerrarlo, el tramo del test queda terminado, y una
  evaluación o un `PUT` que responde después se descarta sin tocar la conversación. Lo que ese
  `PUT` guarda en el servidor queda allí, como en RF-TEST-9, y el `clear()` de `logout()` y la
  guarda por dueño del service siguen como en RF-TEST-2.
- **T0, la invitación.** Al empezar, la bienvenida pide el contenido una vez con
  `SpecialtyTestService.fetchContent`. Mientras llega, Ulises muestra una burbuja de
  `SkeletonPulse`. Cuando llega, dice «¿Empezamos tu test de especialidad? Son T preguntas
  cortas.», donde T es el número de preguntas del contenido, y el compositor trae «Saltar y elegir
  por mi cuenta» y «Empezar el test», la principal. El paso de carrera no aparece, porque la
  carrera sale del usuario (decisión B-11), y tampoco las líneas `welcome` del contenido, porque
  Ulises ya se presentó (decisión B-12).
- **Si el contenido no llega.** Sin conexión, con el plazo vencido, con un contenido no válido o
  con otro error, Ulises dice «No pudimos cargar el test.» y el compositor trae «Saltar y elegir
  por mi cuenta» y «Reintentar». Con `404 SPECIALTY_TEST_NOT_AVAILABLE`, la conversación pasa a la
  selección manual sin aviso (RF-TEST-1).
- **Cada pregunta es un turno.** Ulises dice las líneas que manda RF-TEST-4, que son `duelHelp`
  antes de la pregunta 1, la reacción a la respuesta anterior, `scaleHelp` antes de la primera
  escala y el `blockClose` con el sello «Cierra el bloque k de B» junto a su burbuja, y después el
  `prompt` de la pregunta en su propia burbuja. En una escala, esa burbuja lleva primero la tarea
  en negrita y debajo el `prompt`, como en la maqueta.
- **El duelo en el compositor.** Arriba, el rótulo «Esto o aquello · N de T» en 10,5 sp,
  mayúsculas y `testAccentText`. Debajo, las dos tarjetas apiladas con la moneda «o» entre ellas y,
  en dos columnas, «Me gustan las dos» y «Ninguna me llama», con las etiquetas de `duelOptions`,
  una debajo de otra desde la escala de texto 1,3. Las tarjetas son las de la maqueta, de 56 dp de
  alto como mínimo, con la baldosa de 40 dp y el ícono de la tarea en 22 dp (decisión B-13), y
  siguen las reglas de RF-TEST-5 para quedar neutras hasta el toque, encenderse en el color de su
  especialidad, llevar la insignia del visto y apagar la otra.
- **La escala en el compositor.** El rótulo «Escala de gusto · N de T» y las cuatro opciones de
  `scaleOptions` con sus emojis, en una fila o en dos por dos según RF-TEST-6. La escala no lleva
  el ícono de la tarea, que en RF-TEST-6 es decorativo.
- **Al elegir.** A los 350 ms, o con «Siguiente» si hay lector de pantalla (RF-TEST-5), el
  compositor se cierra y entra la respuesta del alumno, que es el texto de la tarea elegida, «Me
  gustan las dos», «Ninguna me llama» o, en una escala, el emoji y la etiqueta, como «🤩 Me
  encantaría». El sello late.
- **«Pregunta anterior».** Es un enlace del compositor desde la pregunta 2, en los desempates y en
  la espera. Entra la respuesta «Pregunta anterior» y Ulises repite el paso previo con la
  respuesta previa marcada, con las reglas de RF-TEST-4 sobre los desempates y la evaluación en
  vuelo. Desde la pregunta 1 lleva a T0.
- **La espera.** Ulises dice `ulises.loading` con un indicador de 16 dp en `testAccent` a su
  lado (RF-TEST-7). El compositor queda vacío, y no hay barra ni plumas llenas, porque en la
  conversación no hay barra (enmienda aprobada a RF-TEST-7).
- **El desempate.** Ulises dice la `ulisesLine` del servidor, y el compositor trae el duelo con el
  rótulo «Desempate 1» o «Desempate 2».
- **El resultado.** Entra el confeti una vez con `HapticFeedback.heavyImpact`, dibujado bajo la
  franja, así que nunca pasa sobre el sello (RF-BIEN-4), y Ulises dice
  `headline` y, si llega, `tiebreakOutcome` (RF-TEST-8). Debajo van, a lo ancho de la columna, la
  tarjeta de la número uno con las piezas de RF-TEST-8 y una segunda tarjeta con los electivos y
  «También te puede interesar», con sus corazones de 48 dp. El compositor trae «Elegir como
  principal», a lo ancho, y debajo, en dos columnas, «Decidir después» y «Rehacer el test». El
  resultado queda en la conversación, que desplaza (decisión B-15).
- **Guardar.** Rigen las reglas de RF-TEST-9, con un guardado a la vez, el plazo de 15 s, los
  corazones que guardan enseguida y el primer guardado que completa la configuración. Si «Elegir
  como principal» o «Decidir después» guardan, entra su respuesta, Ulises dice «¡Listo! Te llevo
  a tu horario 🪶» y, 900 ms después, empieza el paso al horario (RF-BIEN-11). Si fallan o vencen,
  Ulises dice el aviso de RF-TEST-11 y el compositor vuelve a responder.
- **Sin carrera.** `completeSetup` exige un `careerId` entero. Si `user.careerId` llega nulo, la
  bienvenida no lo llama, Ulises dice «No se pudo determinar tu carrera.», el mensaje de hoy del
  asistente (`setup_carrera_controller.dart:91-94`), y el compositor vuelve a responder. Es el
  mismo punto muerto que hoy tiene el asistente, y queda como riesgo conocido.
- **«Rehacer el test».** Entra su respuesta y la conversación vuelve a la pregunta 1 con el mismo
  contenido, sin pasar por T0.
- **La selección manual.** Con «Saltar y elegir por mi cuenta» o el `404`, Ulises dice «Elige una
  mención como tu diploma principal.» y el compositor trae la lista oficial con «Principal» y «Me
  interesa» y el botón de hoy, «Saltar por ahora» o «Finalizar configuración», con las reglas de
  RF-TEST-1 y RF-TEST-14. Si el catálogo no carga, dice «No pudimos cargar las especialidades.»
  con «Reintentar». Al guardar sigue la despedida de «Guardar». El atrás del sistema en este turno
  lleva a T0 si el test está disponible.
- **Sin pausa.** No hay botón de pausa ni de salto dentro de las preguntas, porque en la
  conversación no hay un asistente al que volver (decisión B-14). Cerrar la app a mitad deja la
  configuración a medias, y al abrirla otra vez Ulises retoma al alumno en T0, con el test desde
  cero (RF-BIEN-13 y RF-BIEN-21).
- **Lo que no aparece.** El héroe de RF-TEST-3 con sus pastillas «3 a 4 min» y «Rehazlo en
  Perfil», la barra de 52 px de RF-TEST-4 con las plumas, el historial plegado y la pausa. El
  contador de preguntas pasa al rótulo del compositor y el historial es la propia conversación.
- **El docente.** Nunca ve el test, igual que en RF-TEST-1.

`[@test] ../../../test/bienvenida/bienvenida_test_especialidad_test.dart`

### RF-BIEN-11. El paso al horario

Cierra la conversación del que vuelve, la del nuevo y la del alumno sin especialidad (RF-BIEN-21).
La maqueta lo muestra en `toHorario` y `flyDock`.

- **La navegación.** La bienvenida navega a `/home` con `Get.offAll`, con el `page` y el `binding`
  de su `GetPage`, `routeName: '/home'`, `Transition.noTransition` y el argumento
  `{'pestana': 'horario'}` de RF-SPL-20, igual que la intro del splash (RF-SPL-4).
- **La capa.** La página de la bienvenida sale del árbol con `Get.offAll`, así que el paso lo
  dibuja la capa del `builder` de `GetMaterialApp`, la misma que usa la intro, que la spec del
  splash declara como pieza permanente y que tiene una entrada para la bienvenida (RF-SPL-4 y
  decisión B-33). Antes de navegar, la bienvenida le entrega por esa entrada la franja, el sello,
  a Ulises en su último avatar y una imagen de la conversación y del compositor para
  desvanecerla. Después cierra los tramos del registro y del test si siguen abiertos, borra el
  historial y vacía los campos de `LoginController` (RF-BIEN-5). La capa dibuja encima mientras
  `/home` se monta debajo, bloquea los toques, mide la cabecera y `ChatbotBubble` como en
  RF-SPL-11, lleva la semántica de RF-BIEN-16 y avisa a `HomePage` cuando se retira, para que
  Horario pida sus orientaciones (RF-SPL-20). La imagen se descarta al retirarse la capa. La capa
  está montada en todas las plataformas, también en web, donde no hay intro (decisión S-22).
- **La franja y el sello.** En 1050 ms, las esquinas de la franja pasan de 26 dp a 0 en el primer
  40 % con easeInOutCubic y su color va al `headerColor` del tema. La conversación y el compositor
  se desvanecen en el primer 35 %. La página de `/home` aparece entre el 22 % y el 55 %, y su
  cuerpo entre el 32 % y el 75 %, subiendo 24 dp. La campana y el resto de la cabecera aparecen
  entre el 70 % y el 100 %. El sello va a la cabecera con easeInOutCubic, la estrella a su lugar
  de 26 dp junto a «ULIMA++» (BR-SHELL-F-04) y los «++» con un salto de 6 dp. En el último 25 %,
  las cruces dibujadas se funden con los glifos del texto, como en RF-SPL-11.
- **Ulises vuela a su burbuja.** Al mismo tiempo, Ulises sale de su último avatar de la
  conversación, se oculta ese avatar y vuela en 1150 ms, con la curva seno, por la derecha y hacia
  arriba en una Bézier que baja a la esquina de `ChatbotBubble`. Crece hasta 1,6 veces en el
  primer 45 % y se achica hasta 56 dp, con un aleteo que se apaga al final y una inclinación de
  hasta 12°. Se posa en 420 ms con un aplastamiento, y en ese cuadro aparece la burbuja real, con
  su latido (decisión B-16).
- **Dónde aterriza.** En el lugar inicial de `ChatbotBubble`, que la burbuja informa una vez que
  se dibuja, como la cabecera informa su estrella (RF-SPL-11). La burbuja queda oculta hasta que
  Ulises aterriza, y solo cuando la capa, al medirla, le avisa de un aterrizaje en curso, lo que
  pasa únicamente en este paso con la opción por defecto de B-16. En cualquier otra llegada a
  `/home`, como la del splash (decisión S-28), la burbuja aparece con la página, como hoy. Si la
  burbuja no se puede medir, aparece con la página y Ulises se desvanece con la conversación.
- **El docente.** No tiene burbuja en `/home` (`home_page.dart:112`), así que Ulises se desvanece
  con la conversación en el primer 35 %.
- **El último cuadro.** La capa muestra lo mismo que la página de debajo, y al retirarse la
  pantalla no cambia.
- **La orientación.** Mientras la capa cubre la pantalla, la app sigue en vertical, y Horario pide
  sus orientaciones cuando la capa se retira, como con la intro (decisión S-26).
- **Si algo falla.** Si la cabecera no se puede medir o si la ruta de debajo cambia, por ejemplo
  por un 401 de las peticiones de `/home`, el paso es un fundido cruzado de 300 ms en el que la
  capa se desvanece sobre `/home`, ya montada debajo, así que la estrella de su cabecera se ve
  durante todo el fundido.
- **Durante el paso.** Ningún toque llega a la página de debajo ni a la conversación.

`[@test] ../../../test/bienvenida/bienvenida_horario_test.dart`

### RF-BIEN-12. Errores y sin conexión

El recibimiento y los turnos antes de un envío no usan la red, así que una caída solo se nota al
entrar, al enviar el registro, en el test y al guardar. Cada error del backend o de la red es
una burbuja de Ulises (RF-BIEN-5).

| Momento | Caso | Qué ve el alumno |
| --- | --- | --- |
| Recibimiento y turnos sin envío | Sin conexión | Nada |
| E2 | `401 USER_NOT_FOUND` o `INVALID_PASSWORD` | «Código o contraseña incorrectos.» y vuelta a E1 con el código (decisión B-6) |
| E2 | `403 NOT_ENROLLED` | «No tienes una matrícula activa.» y vuelta a E1 con el código |
| E2 | Otro error del backend | Su mensaje y vuelta a E1 con el código |
| E2 | Sin conexión | «No hay conexión. Revisa tu internet e inténtalo de nuevo.», con E2 abierto y la contraseña escrita |
| E1, Google | La persona cancela | Nada |
| E1, Google | `403 INVALID_DOMAIN` | «Debes usar tu correo @aloe.ulima.edu.pe o @ulima.edu.pe.» |
| E1, Google | `401 USER_NOT_FOUND` | «Tu correo no está registrado en el sistema.», sin ofrecer crear la cuenta |
| E1, Google | Sin `idToken` u otro fallo | «No se obtuvo información de Google.» o «No se pudo iniciar sesión con Google.» |
| N1 a N5 | Validación local | Los mensajes de hoy bajo el campo |
| Envío | Cada código de la tabla de la spec del registro | Su mensaje y vuelta a N1 o a N5 según esa tabla (RF-BIEN-8) |
| Envío | Sin conexión, también si el sistema corta la conexión en segundo plano | «No hay conexión. Revisa tu internet e inténtalo de nuevo.» y vuelta a N5 (decisión B-32) |
| Envío | 120 s sin respuesta | `incierto` con el plazo vencido |
| Envío | 201 sin token o ilegible | `incierto` con la cuenta confirmada |
| `incierto` | «Iniciar sesión» no entra | «Seguimos sin poder confirmarlo…», con «Ya tengo cuenta» a la vista (decisión B-30) |
| Después del 201 | Los catálogos fallan | Nada, como en BR-REG-F-10 |
| T0 | El contenido no llega | «No pudimos cargar el test.», con «Reintentar» |
| Test | Cada fila de RF-TEST-11 | Su texto como burbuja de Ulises y la misma salida que allí |
| Cualquier turno con sesión | Un 401 | «Tu sesión caducó o iniciaste sesión en otro dispositivo.» y E1 |
| Paso al horario | La cabecera no se mide o la ruta de debajo cambia | El fundido cruzado de 300 ms |
| Paso al horario | La burbuja no se mide | Ulises se desvanece y la burbuja aparece con la página |

- **El 401 con sesión.** Después de adoptar la sesión, `/login` sigue siendo la ruta actual, así que
  el interceptor del 401 borra la sesión y `offAllToLogin` no navega (`api_client.dart:143-160`).
  Tras cada fallo de un turno con sesión, la bienvenida comprueba si el token guardado sigue ahí
  (decisión B-22). Si ya no está, hace la misma limpieza local que `AuthService.logout`, sin
  llamar al backend porque no hay token, y Ulises dice «Tu sesión caducó o iniciaste sesión en otro
  dispositivo.», que es el texto del aviso «Sesión expirada», que en `/login` no aparece. Después
  vuelve a E1. Ese reinicio cierra los tramos del registro y del test, borra el historial anterior
  al 401 y vacía los campos de `LoginController` (RF-BIEN-5). Las respuestas del test en memoria
  se pierden, como al cerrar sesión (RF-TEST-2).

`[@test] ../../../test/bienvenida/bienvenida_errores_test.dart`

### RF-BIEN-13. Volver atrás, segundo plano y cerrar la app a mitad

- **El atrás del sistema.** Hace lo mismo que el enlace secundario del turno.

| Dónde | Qué hace el atrás |
| --- | --- |
| Recibimiento, también el de la llegada con sesión antes de T0, y E1 | Sale de la app, como hoy en `/login` |
| E2 | Vuelve a E1 con el código escrito |
| N1 | «Ya tengo cuenta» |
| N2 a N5 | «Volver» |
| Envío | Nada, con el aviso de BR-REG-F-09 |
| `incierto` | «Volver a intentar el registro» |
| T0 y el resultado | Nada, porque la cuenta ya existe y las respuestas del compositor deciden |
| Preguntas, desempates y espera | «Pregunta anterior», y desde la pregunta 1, T0 |
| Selección manual | T0 si el test está disponible, y nada si no |
| Paso al horario | Nada |

- **Segundo plano.** La conversación queda como está y sus animaciones se pausan. Si el sistema
  corta la conexión del registro mientras la app está en segundo plano, `http` lanza una excepción
  de red, `RegistroService` la traduce a `SIN_CONEXION` (`registro_service.dart:65-71`) y el
  controlador vuelve a `verificar` (`registro_controller.dart:283-285`), así que la conversación
  vuelve a N5 con «No hay conexión.», como hoy. El plazo de 120 s solo lleva a `incierto` cuando
  la conexión sigue abierta sin respuesta. Como el pedido pudo llegar al servidor, un reenvío
  desde N5 puede recibir el 409, y la decisión B-32 abre la opción de tratar ese corte como
  `incierto`.
- **Cerrar la app a mitad.** Nada de la conversación se guarda, así que el siguiente arranque en
  frío pasa por el splash y decide con la sesión guardada.

| Cuándo se cierra | Qué pasa al abrirla |
| --- | --- |
| En el recibimiento, en «Sí, entrar» o en el registro antes del envío | La bienvenida desde el principio. Las credenciales murieron con el proceso |
| Durante el envío | La bienvenida desde el principio. La cuenta puede existir, y si la persona repite el registro recibe «Ya existe una cuenta con ese código. Inicia sesión o recupera tu contraseña.», que es el riesgo que RS-FE-5 acepta |
| Con sesión y antes de guardar la especialidad, sea después del 201 o en el test del alumno sin especialidad | La sesión está guardada con la configuración a medias, así que el splash hace el relevo con la sesión y Ulises retoma al alumno en T0, con el test desde cero (decisión B-10, RF-BIEN-21 y RF-TEST-8) |
| Después del primer corazón o de guardar | La configuración está completa y abre `/home` en Horario |

`[@test] ../../../test/bienvenida/bienvenida_atras_test.dart`

### RF-BIEN-14. Modo oscuro y contraste

- **Tema.** La bienvenida sigue `Theme.of(context).brightness`. Sus widgets no llevan hex sueltos,
  y sus colores son tokens de `MaterialTheme`. Reusa `pageBg`, `cardBg`, `textPrimary`,
  `headerColor` y los tokens del test (RF-TEST-12), que son `testInk2`, `testMuted`, `testLine`,
  `testChipBg`, `testAccent`, `testAccentHi`, `testAccentInk`, `testAccentText` y
  `testAccentSoft` (decisión B-24).
- **Tokens nuevos.** Salen de la paleta de la maqueta, salvo donde la tabla dice otra cosa.

| Token | Claro | Oscuro | Uso |
| --- | --- | --- | --- |
| `bienvenidaFranja` | `#FF6600` | `#262626` | La franja del sello y el fondo del recibimiento después del relevo |
| `bienvenidaPropia` | `#FFE7D4` | `#3A2A22` | Fondo de las respuestas del alumno |
| `bienvenidaPropiaTinta` | `#6B2D00` | `#FFC49A` | Texto de las respuestas del alumno |
| `bienvenidaSaludo` | `#FFFFFF` | `#33333B` | Tarjeta del saludo del recibimiento |
| `bienvenidaSaludoTinta` | `#1A0E05` | `#F5F5F7` | «¿Ya usas ULima++?» |
| `bienvenidaSaludoSub` | `#7A3300` | `#FFC49A` | «¡Craa! Hola, soy Ulises 👋» en la tarjeta |
| `bienvenidaEntrarFondo` | `#FFFFFF` | `#FF8C42` | Botón «Sí, entrar» |
| `bienvenidaEntrarTinta` | `#1A0E05` | `#16161C` | Texto de «Sí, entrar» |
| `bienvenidaNuevoFondo` | `#B84A00` | transparente | Botón «Soy nuevo», con la decisión B-3 (la maqueta usa blanco al 14 %) |
| `bienvenidaNuevoBorde` | `#FFFFFF` | `#5A5A66` | Borde de 1,5 dp de «Soy nuevo» |
| `bienvenidaNuevoTinta` | `#FFFFFF` | `#EDEDF3` | Texto de «Soy nuevo» |
| `bienvenidaPildora` | `#0F172A` | `#33333B` | Píldora «Creando tu cuenta…» |
| `bienvenidaPildoraLista` | `#15803D` | `#15803D` | Píldora «Cuenta creada» |
| `bienvenidaGoogleFondo` | `#FFFFFF` | `#131314` | Botón «Continuar con Google», colores de la marca de Google |
| `bienvenidaGoogleBorde` | `#747775` | `#8E918F` | Borde de 1 dp del botón de Google |
| `bienvenidaGoogleTinta` | `#1F1F1F` | `#E3E3E3` | Texto del botón de Google |
| `bienvenidaFoco` | `#D45500` | `#FF8C42` | Borde del campo con foco y anillo de foco del teclado (la maqueta usa `#FF6600`, que da 2,94:1) |

- **Contraste.** Todo texto llega a 4,5:1 contra su fondo en los dos temas y todo ícono que da
  información, o borde de foco, a 3:1, con las dos excepciones de la tabla.

| Par | Claro | Oscuro |
| --- | --- | --- |
| Texto de las burbujas sobre `cardBg` | 17,85:1 | 14,22:1 |
| Nombre «Ulises» en `testMuted` sobre `pageBg` | 6,09:1 | 7,42:1 |
| Respuesta del alumno | 8,81:1 | 8,87:1 |
| «¿Ya usas ULima++?» sobre la tarjeta | 18,94:1 | 11,50:1 |
| «¡Craa! Hola, soy Ulises 👋» sobre la tarjeta | 9,13:1 | 8,12:1 |
| «Sí, entrar» | 18,94:1 | 7,79:1 |
| «Soy nuevo» sobre su fondo | 5,23:1 | 12,98:1 sobre `#262626` |
| Pista del campo en `testMuted` sobre `testChipBg` | 5,67:1 | 6,34:1 |
| Enlaces en `testAccentText` sobre `cardBg` | 5,23:1 | 7,91:1 |
| Texto sobre las píldoras y botones rellenos con `testAccent` | 6,45:1 | 7,79:1 |
| Píldora «Creando tu cuenta…» y «Cuenta creada», en blanco | 17,85:1 y 5,02:1 | 12,52:1 y 5,02:1 |
| Botón de Google | 16,48:1, borde 4,53:1 | 14,47:1, borde 5,21:1 sobre `cardBg` |
| Borde de foco sobre `cardBg` | 4,12:1 | 7,17:1 |
| «ULIMA++» y el sello en blanco sobre la franja | 2,94:1, riesgo conocido | 15,13:1 |
| Logo blanco sobre `#E77330` en el primer cuadro | 3,05:1, decorativo | 3,05:1, decorativo |

- **Las excepciones.** El blanco sobre `#FF6600` del sello es el mismo de la cabecera de toda la
  app, un riesgo conocido que el dueño acepta el 2026-09-25 para la cabecera del asistente
  (decisión 9 de la spec del test). El logo del primer cuadro es un dibujo sin texto.
- **El recibimiento en oscuro.** Después del relevo, el fondo pasa de `#E77330` a `#262626`, el
  logo sigue blanco y la tarjeta y los botones toman sus tokens oscuros. La conversación usa
  `#16161C` de fondo y `#1E1E24` en las burbujas y el compositor.
- **El test.** Dentro de la conversación rigen los colores y la guarda de contraste de RF-TEST-12.

`[@test] ../../../test/bienvenida/bienvenida_contraste_test.dart`

### RF-BIEN-15. Reducir movimiento

Con `MediaQuery.disableAnimationsOf(context)` en `true`, nada se mueve, gira ni cambia de escala.
Cada cambio del logo es un fundido cruzado, en el que el logo que llega aparece encima mientras
el que se va sigue entero debajo hasta quedar cubierto, así que ningún cuadro queda sin logo
(RF-BIEN-4).

- **El recibimiento.** Ulises no vuela. Aparece en su lugar con un fundido de 160 ms, 120 ms
  después del relevo, sin sombra, estela ni partículas. El fondo cambia en 150 ms. La tarjeta y los
  botones aparecen con fundidos de 180 ms, sin desplazamiento.
- **Si no cabe.** La estrella no se desliza. Si RF-BIEN-2 la sube o la achica, la estrella en su
  lugar nuevo aparece encima en 220 ms mientras la del centro sigue entera debajo, y después la
  del centro se quita.
- **La subida al sello.** La franja con el sello entero y la conversación aparecen encima en
  220 ms, mientras el fondo de pantalla completa y el logo grande siguen enteros debajo hasta
  quedar cubiertos, y después se quitan. Ulises pasa a su avatar con un fundido de 140 ms.
- **El sello.** No late. Durante el envío no hay pulso, y la píldora con «Creando tu cuenta…»
  dice sola que se espera, con su indicador quieto.
- **La conversación.** Las burbujas y el compositor entran con un fundido de 200 ms, sin subir, y
  la conversación salta al final sin desplazarse. El cursor del campo no parpadea.
- **El ritmo se queda.** Las pausas entre burbujas no son movimiento, así que siguen.
- **El test.** Rige RF-TEST-13, sin confeti, giro ni crecimiento.
- **El paso al horario.** `/home` se monta entera bajo la capa, con la estrella y «ULIMA++» en su
  cabecera, y la capa, con la franja, el sello, la conversación y el compositor, se desvanece
  encima en 220 ms, así que el sello y la estrella de la cabecera se ven a la vez durante todo el
  fundido. La burbuja de Ulises aparece en su lugar, sin latido.
- **La llegada con sesión.** Como el recibimiento, sin la tarjeta ni los botones. La subida al
  sello es el fundido cruzado de arriba, y Ulises pasa a su avatar con el mismo fundido de 140 ms
  (RF-BIEN-21).
- **Las pantallas de la contraseña.** El sello de su cabecera no se mueve, con reducir movimiento
  o sin él (RF-BIEN-20).
- **La maqueta.** Con «Reducir movimiento», sus funciones `toSeal` y `toHorario` apagan el logo y
  lo vuelven a encender, y en eso manda esta spec (RF-BIEN-19).

`[@test] ../../../test/bienvenida/bienvenida_movimiento_test.dart`

### RF-BIEN-16. Accesibilidad

- **La estructura.** El sello es un encabezado, «ULIMA++». La conversación es una lista en orden.
  Cada grupo de Ulises se lee como «Ulises» seguido de sus burbujas, y cada respuesta del alumno
  como «Tú, <texto>». Los candados, los emojis de las respuestas, la imagen de Ulises, sus vuelos,
  la estela, las partículas y el anillo del latido quedan fuera de la semántica.
- **El recibimiento.** Mientras la capa del splash está encima, el lector solo ve su etiqueta
  «ULIMA++, cargando» (RF-SPL-15). Con un lector de pantalla activo
  (`MediaQuery.accessibleNavigation`), la tarjeta y los botones aparecen con el relevo, sin
  esperar el aterrizaje, y el foco del lector pasa a la tarjeta, que se lee «¡Craa! Hola, soy
  Ulises. ¿Ya usas ULima++?», y después a los dos botones.
- **El paso al horario.** Mientras la capa hace el paso, el lector solo ve su nodo «ULIMA++», sin
  «cargando», que no es región viva, y al retirarse la capa pasa a `/home` (RF-SPL-15).
- **La llegada con sesión.** Con un lector de pantalla activo, la conversación empieza con el
  relevo, sin esperar el aterrizaje, y el foco del lector pasa a la primera burbuja de Ulises
  (RF-BIEN-21).
- **Las pantallas de la contraseña.** El sello de su cabecera es un encabezado «ULIMA++», que el
  lector lee después de la flecha «Volver» y antes de la tarjeta, y su dibujo queda fuera de la
  semántica (RF-BIEN-20).
- **Cada turno.** Con lector de pantalla, las burbujas de un turno entran juntas, y el foco del
  lector pasa a la primera burbuja nueva de Ulises. El orden de lectura sigue por las burbujas y
  termina en el compositor. El campo no toma el foco del teclado solo, y el lector anuncia su
  rótulo y su pista al llegar a él.
- **Regiones vivas.** La píldora del registro y el error local bajo un campo son regiones vivas,
  así que se anuncian «Creando tu cuenta…», «Cuenta creada» y cada error. Las burbujas de Ulises no
  lo son, porque el foco ya las lee, y así nada se anuncia dos veces.
- **Los controles.** Los dos botones del recibimiento, las respuestas rápidas, el botón principal
  y los enlaces son botones con su texto. El botón de envío se lee «Enviar», y el ojo, «Mostrar
  contraseña» u «Ocultar contraseña», con su estado. La tarjeta del consentimiento se lee entera
  en su orden. En el test rigen las etiquetas de RF-TEST-13.
- **Blancos táctiles.** Todo control mide al menos 48 dp de alto, y los de ícono, 48 × 48.
- **El teclado físico y la web.** El orden de foco va del campo al botón de envío y después a los
  enlaces. Intro envía. El foco del teclado se ve con el anillo de 2 dp en `bienvenidaFoco`.
- **Tamaño de texto.** Todo respeta `MediaQuery.textScaler` hasta el 200 %. Ningún contenedor de
  texto tiene alto fijo. Las burbujas crecen, el compositor desplaza por dentro cuando pasa del
  60 % del alto y el recibimiento aplica su regla «Si no cabe» (RF-BIEN-2 y decisión B-28). A
  375 × 667, con 1,0, 1,3 y 2,0, nada desborda, y con 1,0 la estrella no se mueve.
- **Sin límite de tiempo.** Ningún turno vence, salvo la vigencia propia del código del
  authenticator, que no depende de la app. Las pausas del ritmo no quitan tiempo para responder.
- **El color nunca va solo.** Los errores llevan su ícono y su texto, y la respuesta elegida en el
  test lleva los estados de RF-TEST-13.

`[@test] ../../../test/bienvenida/bienvenida_accesibilidad_test.dart`

### RF-BIEN-17. Barra de estado, orientación y pantallas anchas

- **La barra de estado.** La bienvenida declara íconos claros en los dos temas con un
  `AnnotatedRegion<SystemUiOverlayStyle>` en su raíz, porque arriba siempre hay `#E77330`, la
  franja naranja o la franja `#262626` (RF-SPL-4). La barra de navegación del sistema queda como
  en el resto de la app.
- **La orientación.** Vertical en toda la bienvenida (RF-BIEN-1).
- **Pantallas anchas.** En tabletas y en web, la conversación, el compositor, Ulises, la tarjeta
  del saludo y los botones del recibimiento van en una columna de 600 dp como máximo, centrada.
  La franja va de borde a borde, y la estrella sigue en el centro de la pantalla física
  (RF-SPL-5), salvo en web, donde se centra en la vista (RF-BIEN-3). Ulises aterriza medido desde
  la estrella y la tarjeta llega hasta 12 dp del borde derecho de la columna (RF-BIEN-2).

`[@test] ../../../test/bienvenida/bienvenida_barra_estado_test.dart`

### RF-BIEN-18. Rendimiento

- **Sin paquetes nuevos.** La bienvenida usa solo el SDK de Flutter y los paquetes que ya están,
  con `CustomPainter`, `AnimationController`, `Curves` y `TextPainter`.
- **El logo.** El sello y el logo del recibimiento se pintan con la geometría de RF-SPL-2, cuyos
  caminos se construyen una vez. El latido y el pulso repintan solo el pintor del sello, con su
  `repaint`, sin reconstruir widgets en cada cuadro.
- **Ulises.** Su imagen está en caché antes del relevo (RF-SPL-21 y RF-BIEN-3). Su vuelo es una
  transformación de una capa aislada con `RepaintBoundary`. La estela y las partículas no pasan de
  36 puntos vivos a la vez, y no hay desenfoques ni `BackdropFilter`.
- **La conversación.** Es una lista perezosa con una clave por burbuja, así que una burbuja nueva
  no reconstruye las anteriores. Una conversación completa, con el registro y 14 preguntas, ronda
  las 80 burbujas.
- **Fluidez.** Se mide en modo perfil con la línea de tiempo de DevTools, en un Android de gama de
  entrada con pantalla de 60 Hz y en el iPhone SE del dueño, en el recibimiento, la subida al
  sello, el pulso y el paso al horario. En cada tramo, a lo sumo un cuadro pasa de 16,7 ms en el
  hilo de UI o en el de raster y ninguno pasa de 33,4 ms. Queda fuera de la medida el cuadro que
  construye `/home` bajo la capa, como en RF-SPL-17.
- **El teclado.** Abrir y cerrar el teclado no reconstruye la franja ni el sello.

Sin prueba automática. La medición va en «Verificación».

### RF-BIEN-19. La maqueta

- `docs/images/UI/bienvenida/ulises-te-recibe-combinada.html` queda como referencia visual, con los
  recorridos «Con sesión», «Soy nuevo» y «Ya tengo cuenta», la intro al azar o elegida, Repetir,
  modo oscuro y reducir movimiento. Está en el repo desde `026107d`.
- `docs/images/UI/bienvenida/README.md` dice que manda esta spec y lista las diferencias entre la
  maqueta y la spec.
- Sus datos son ficticios. El código `20230001`, la alumna Valeria, el código del authenticator
  `482913`, los cursos y las aulas son inventados.
- La maqueta difiere de la spec en estos puntos.
  - El test empieza mientras se crea la cuenta, con «Mientras tanto, ¿empezamos tu test de
    especialidad? Son 14 preguntas cortas.», «Prefiero esperar» y «Empezar el test»
    (decisión B-1).
  - El código del authenticator se envía solo al completar las seis casillas (decisión B-5).
  - «Soy nuevo» usa blanco al 14 % sobre el naranja (decisión B-3), la pista de los campos usa
    `#8A94A6` y el foco usa `#FF6600` (RF-BIEN-14).
  - Ulises llama «Valeria» a la alumna (decisión B-4).
  - Mientras se crea la cuenta, Ulises dice «Tarda cerca de un minuto.». Por defecto la spec usa
    la advertencia de hoy, «Puede tomar un par de minutos: no cierres la app.» (decisión B-17).
  - Con la cuenta creada, la burbuja dice «¡Craa! Tu cuenta ya está lista, Valeria. Traje tus 6
    cursos del ciclo.». La spec la deja sin el nombre (decisión B-4) y sin las otras dos cifras
    del resumen de hoy (decisión B-31).
  - Ulises mide 52 y 58 px, y la tarjeta y los botones miden en px lo mismo que en la app en dp.
    En la app el dibujo se escala por 1,2 y la interfaz no, así que Ulises mide 62 y 70 dp y la
    tarjeta y los botones se ven un poco más chicos frente a la estrella. Ulises aterriza medido
    desde la estrella y no en un porcentaje de la pantalla, y la maqueta no tiene la regla «Si no
    cabe» (RF-BIEN-2 y decisiones B-27 y B-28).
  - Con «Reducir movimiento», la subida al sello y el paso al horario apagan el logo y lo vuelven
    a encender. En la app son fundidos cruzados que nunca dejan la pantalla sin logo
    (RF-BIEN-15).
  - E2 no trae «Soy nuevo», N2, N4 y N5 no traen «Volver» ni «Ya tengo cuenta», y no hay turno de
    error, de `incierto` ni de sesión expirada.
  - El duelo no trae «Me gustan las dos» ni «Ninguna me llama», y el resultado dice «Elegir
    Software como principal», sin «Rehacer el test», los electivos ni «También te puede
    interesar». Manda la spec del test (sus decisiones abiertas 3 y 4).
  - Las líneas de Ulises dentro del test, como «Primera práctica y te dejan escoger. ¿Cuál te
    pides?» o «¡Craa! Lo tuyo es esto, Valeria 👇», son ilustrativas. Mandan las del contenido
    (decisión abierta 8 de la spec del test).
  - El marcador «12 preguntas después» es un atajo de la maqueta y no existe en la app.
  - Los campos, las píldoras y los enlaces miden menos de 48 dp.
  - La franja mide 100 px y la cabecera 96 px. En la app miden lo mismo (RF-BIEN-4).
  - No tiene la llegada con la sesión de un alumno sin especialidad (RF-BIEN-21 y decisión B-10)
    ni las pantallas de «¿Olvidaste tu contraseña?» con el sello en su cabecera (RF-BIEN-20 y
    decisión B-9). Esas dos partes no tienen maqueta, y mandan sus requisitos.

Sin prueba automática, porque es documentación.

### RF-BIEN-20. El sello en las pantallas de «¿Olvidaste tu contraseña?»

El dueño elige el 2026-09-26 conservar las pantallas de hoy de «¿Olvidaste tu contraseña?», con el
sello del logo ULima++ y sus «++» en su cabecera, para que el logo nunca se pierda (decisión B-9).

- **Lo que no cambia.** `/forgot-password` y `/reset-password` conservan sus rutas, sus campos, sus
  textos, sus pasos, sus validaciones, su servicio y sus errores, dentro de la tarjeta de hoy. La
  bienvenida abre `/forgot-password` encima de la conversación con `Get.toNamed`, como hoy, y
  volver deja la conversación como estaba (RF-BIEN-1).
- **La cabecera.** Arriba de cada pantalla va el sello de RF-BIEN-4, con la estrella de
  BR-SHELL-F-04 y «ULIMA++» a 1,22 veces su tamaño. Queda centrado a lo ancho y a la altura de la
  fila de la cabecera de `/home`, en el mismo lugar y del mismo tamaño que en la franja de la
  conversación. La cabecera mide lo mismo que esa franja y va desde el borde superior de la
  pantalla, detrás de la barra de estado. No tiene color propio, porque el fondo de estas pantallas
  ya es el de la franja, `#FF6600` en claro y `#262626` en oscuro (`password_reset_ui.dart:36-76` y
  `bienvenidaFranja` de RF-BIEN-14).
- **El sello quieto.** No late, no pulsa ni se mueve. «ULIMA» sigue la escala de texto del
  sistema, como en la franja.
- **La flecha y el sello.** La flecha «Volver» sigue arriba a la izquierda, donde está hoy
  (`password_reset_ui.dart:149-157`). El sello nunca queda bajo ella, porque cabe entre dos márgenes
  laterales de 56 dp. Si con letra grande no cabe, «ULIMA» deja de crecer en el tamaño que sí
  cabe.
- **La tarjeta.** Se centra en el espacio que queda bajo la cabecera y, con el teclado abierto,
  desplaza por debajo de ella, sin pasar nunca sobre el sello.
- **Dónde vive.** El sello es un widget de `lib/components/logo/`, que usan la conversación y estas
  dos pantallas, pintado con la geometría de RF-SPL-2 y con el estilo único de «ULIMA» de
  `app_header.dart` (RF-SPL-11). `PasswordResetScaffold` suma una opción para la cabecera con el
  sello, apagada por defecto, que solo encienden `forgot_password_page.dart` y
  `reset_password_page.dart`. Portal Sync (`portal_sync_page.dart:24`) no la enciende y no cambia.
- **En todas sus llegadas.** `/reset-password` lleva el sello también cuando se abre desde el
  Perfil con el correo enmascarado (`perfil.dart:768-779`), porque es la misma pantalla.
- **Los avisos abajo.** «Solicitud enviada» (`forgot_password_controller.dart:35`), «Código
  reenviado» (`reset_password_controller.dart:196`) y «Código enviado» del Perfil
  (`perfil.dart:774-779`) salen sobre estas pantallas. Por eso salen abajo, con su texto de hoy,
  como los de la decisión B-29, y no tapan el sello. «Contraseña actualizada» ya sale abajo sobre
  la bienvenida (RF-BIEN-3). Los avisos «Error» del Perfil (`perfil.dart:781-783`) salen sobre el
  Perfil y no cambian.
- **Al abrir y al cerrar.** Las dos pantallas se abren y se cierran con la transición de hoy. Como
  el sello de cada pantalla y el de la conversación están en el mismo lugar y cada uno se mueve con
  su página, en cada cuadro de la transición queda un sello a la vista. Si la grabación de
  «Verificación» muestra un cuadro sin sello, la implementación se detiene y el cambio vuelve a
  esta spec.
- **Al terminar.** El restablecimiento llega a la bienvenida con `motivo: restablecida`, directo a
  «Sí, entrar», con el sello en su lugar desde el primer cuadro (RF-BIEN-3).
- **La barra de estado.** Las dos pantallas declaran íconos claros en los dos temas con un
  `AnnotatedRegion<SystemUiOverlayStyle>` en su raíz, como la bienvenida (RF-BIEN-17), porque
  arriba siempre hay `#FF6600` o `#262626`.
- **Semántica y contraste.** El sello es un encabezado «ULIMA++» (RF-BIEN-16). El blanco sobre
  `#FF6600` da 2,94:1, el riesgo conocido del sello y de la cabecera de toda la app (RF-BIEN-14).
- **Sin textos nuevos.** Las pantallas no suman ningún texto, y el sello dice «ULIMA++».

`[@test] ../../../test/bienvenida/bienvenida_restablecer_test.dart`

### RF-BIEN-21. El alumno con cuenta que todavía no elige su especialidad

El dueño elige el 2026-09-26 que este alumno no vaya al asistente de carrera. Va a la conversación
con Ulises, que le toma el test ahí mismo con el logo en la cabecera y después lo lleva a su
horario (decisión B-10, junto con S-29 del splash).

- **Quién.** Un alumno con sesión y `setupComplete` en `false`, al que `postLoginRoute` manda a
  `/setup-carrera` (`post_login_route.dart:11-14`). `postLoginRoute` no cambia, y la intro y la
  bienvenida traducen esa ruta en el test de la conversación, sin navegar a ella. El docente nunca
  es este caso, porque `postLoginRoute` siempre lo manda a `/home`.
- **Cuándo.** Al abrir la app con la sesión guardada, al entrar con «Sí, entrar» y al entrar con
  «Iniciar sesión» desde `incierto`. En los tres casos sigue en la conversación hasta el test
  (RF-BIEN-10) y termina en el paso al horario (RF-BIEN-11), sin ver el asistente de carrera.
- **La sesión puesta.** Al empezar una visita, después de su primer cuadro, la bienvenida mira si
  hay una sesión puesta, que es un token guardado y `AuthService.to.currentUser`. Con ella, la
  visita sigue lo que diga `postLoginRoute`, como tras «Sí, entrar» (RF-BIEN-6). Hoy solo este
  alumno llega así, porque el cierre de sesión, el 401 y el restablecimiento de contraseña borran
  el token antes de navegar (`api_client.dart:143-160` y `reset_password_controller.dart:159-161`).
  `offAllToLogin` no suma ningún motivo para esta llegada.
- **El primer cuadro.** Es el mismo que sin sesión, con la pose que pasa el splash (RF-BIEN-2) o,
  en web, el del recibimiento corto (RF-BIEN-3), así que sale solo de los argumentos (RF-BIEN-1).
- **El recibimiento.** Sigue RF-BIEN-2 desde «Quieto» hasta el aterrizaje de Ulises, con el vuelo,
  el fondo y las medidas de siempre, pero sin la tarjeta del saludo ni los dos botones. Sin ellos,
  la regla «Si no cabe» no aplica y la estrella no se mueve hasta subir al sello.
- **La subida.** El fin del rebote del aterrizaje hace de respuesta, sin el asentimiento. El logo
  sube al sello 90 ms después (RF-BIEN-4), y Ulises salta a su avatar 120 ms después, como en «El
  salto de Ulises» (RF-BIEN-2). La conversación ya trae el primer grupo de Ulises, con su nombre y
  las burbujas «¡Craa! Hola de nuevo 👋» y «Te falta elegir tu especialidad.», sin respuesta del
  alumno. El sello late al posarse.
- **T0.** Empieza 650 ms después de que Ulises se posa en su avatar, con la invitación al test y
  sus dos respuestas (RF-BIEN-10).
- **Tiempo.** Contado desde el relevo, Ulises se posa a los 1,46 s y su rebote termina a los
  1,94 s. La subida al sello va de 2,03 a 2,93 s, Ulises llega a su avatar a los 2,97 s y T0
  empieza a los 3,62 s. «Empezar el test» aparece 500 ms después de la invitación, unos 4,1 s
  después del relevo más lo que tarde el contenido, que Ulises cubre con su burbuja de
  `SkeletonPulse` (RF-BIEN-10).
- **Tras «Sí, entrar».** Con la sesión puesta y la configuración a medias, entra la respuesta del
  alumno y el sello late. En lugar de E3, Ulises dice «¡Hola de nuevo! Te falta elegir tu
  especialidad.» y, 650 ms después, empieza T0 (RF-BIEN-6). Con Google pasa lo mismo.
- **Tras «Iniciar sesión» desde `incierto`.** Sigue T0, como ya dice RF-BIEN-8.
- **En web.** Sin intro (decisión S-22), `main()` pone `/login` como ruta inicial cuando
  `postLoginRoute` da `/setup-carrera` (RF-SPL-12). La bienvenida arranca con el recibimiento
  corto y sigue igual.
- **Reducir movimiento y lector de pantalla.** Rigen RF-BIEN-15 y RF-BIEN-16. Ulises aparece con
  un fundido, la subida al sello es un fundido cruzado y, con lector de pantalla, la conversación
  empieza con el relevo y el foco pasa a la primera burbuja de Ulises.
- **El atrás, un 401 y cerrar la app.** Antes de T0, el atrás sale de la app, como en el
  recibimiento, y desde T0 rige RF-BIEN-13. Un 401 sigue RF-BIEN-12, con la limpieza local y la
  vuelta a E1. Si el alumno cierra la app antes de guardar su especialidad, al abrirla vuelve
  aquí, con el test desde cero (RF-BIEN-13).
- **El asistente.** `/setup-carrera` sigue registrada en `main.dart`, pero ni el arranque ni la
  bienvenida llevan a ella. Quitarla, con el origen `asistente` de la spec del test, va en un
  cambio aparte («Qué NO entra»).

`[@test] ../../../test/bienvenida/bienvenida_sin_especialidad_test.dart`

## Textos nuevos

Los textos de Ulises y de los botones de la bienvenida salen de la maqueta. Los del registro, los
del login y los de los errores son los de hoy, y los del test son los de su spec y del contenido.

- **Recibimiento.** «¡Craa! Hola, soy Ulises 👋», «¿Ya usas ULima++?», «Sí, entrar» y «Soy
  nuevo».
- **Sí, entrar.** «¡Qué bueno verte! ¿Cuál es tu código o usuario?», «o», «Continuar con Google»,
  «Y tu contraseña de ULima++.», «Contraseña lista» y «¡Hola de nuevo! Te llevo a tu horario 🪶».
- **Sin especialidad.** «¡Craa! Hola de nuevo 👋», «Te falta elegir tu especialidad.» y «¡Hola de
  nuevo! Te falta elegir tu especialidad.» (RF-BIEN-21).
- **Soy nuevo.** «¡Genial! Tu cuenta se crea aquí mismo.», «¿Cuál es tu código de alumno?»,
  «Código de alumno», «Ahora elige la contraseña con la que entrarás a ULima++. No es la de
  miUlima.», «Contraseña de ULima++ lista», «Para traer tus cursos entro a miUlima una sola vez.
  Antes, lee esto 👇», «Tu contraseña de miUlima, la del portal.», «Contraseña de miUlima lista»,
  «Último paso. El código de tu authenticator.» y «Código del authenticator listo».
- **Envío.** «Estoy creando tu cuenta y trayendo tu ciclo.», «Cuenta creada», «¡Craa! Tu cuenta
  ya está lista.», «Traje tus N cursos del ciclo.» y «Traje tu curso del ciclo.».
- **`incierto`.** «Seguimos sin poder confirmarlo. Puedes volver a intentar el registro: si te
  dice que ya existe una cuenta con ese código, es que sí se creó y puedes recuperar la contraseña
  con “Ya tengo cuenta”.», que cambia el final del texto de hoy (decisión B-30).
- **Test.** «¿Empezamos tu test de especialidad? Son T preguntas cortas.», «Esto o aquello · N de
  T», «Escala de gusto · N de T» y «¡Listo! Te llevo a tu horario 🪶».
- **Sesión.** «Tu sesión caducó o iniciaste sesión en otro dispositivo.», que hoy es el texto del
  aviso «Sesión expirada».
- **Semántica.** «Tú, <texto>», «Enviar», «Mostrar contraseña» y «Ocultar contraseña».

Las pantallas de «¿Olvidaste tu contraseña?» no suman textos, y su sello dice «ULIMA++»
(RF-BIEN-20).

No son nuevos y siguen con su texto de hoy «Puede tomar un par de minutos: no cierres la app.»,
que pasa de la bajada del envío a una burbuja de Ulises, «Creando tu cuenta…», que pasa del
título a la píldora, y los dos títulos de `incierto`, «No pudimos confirmar si tu cuenta se creó» y
«Tu cuenta ya está creada», que pasan a burbujas con un punto final.

Salen de la app «¿No tienes cuenta? Créala», «O inicia sesión con» y el «Google» del botón de
Android e iOS. De la pantalla del registro salen sus títulos y bajadas, que son «Crea tu cuenta
de ULima++», «Elige la contraseña con la que entrarás al app. No es la de miUlima.»,
«Verificamos que eres alumno», «Entramos a miUlima con tus datos una sola vez, para traer tus
cursos y tu avance. No los guardamos.», la primera frase de la bajada del envío, «Estamos
entrando a miUlima y trayendo tus cursos, tu horario y tu avance.», «Listo, <nombre>», «Listo, ya
tienes cuenta», las filas del resumen, «Cursos matriculados», «Clases en tu horario» y «Cursos de
tu avance» (decisión B-31), y sus botones «Continuar» y «Entrar».

## Contrato que se consume

Ninguno nuevo.

- `POST /auth/login` y `POST /auth/google` para «Sí, entrar», como hoy.
- `POST /auth/register` para el registro, y después `GET /academic-profile/careers` y
  `GET /academic-profile/specialties` dentro de `adoptarSesion`, como hoy.
- `GET /specialty-test/content`, `POST /specialty-test/me/evaluate` y
  `PUT /academic-profile/me/specialties` para el test, como en su spec.
- Las mismas rutas del test para el alumno sin especialidad, con la sesión que restaura el
  arranque o que pone «Sí, entrar» (RF-BIEN-21).
- Las rutas de `/password-reset/**` siguen en sus pantallas de hoy, que llevan el sello en su
  cabecera (decisión B-9 y RF-BIEN-20).

El dueño descarta la alternativa de la decisión B-1, que daba el contenido del test antes del
token y cambiaba RS-BE-38 del backend y `docs/specs/api-contracts.md`.

## Pantallas y archivos

### Se crean

| Archivo | Qué tiene |
| --- | --- |
| `lib/pages/bienvenida/bienvenida_page.dart` | La página de `/login` con el recibimiento, la franja, la conversación y el compositor |
| `lib/pages/bienvenida/bienvenida_controller.dart` | El recorrido, los turnos, el historial, el motivo de la llegada, la llegada con sesión, los tramos del login, del registro y del test y el paso al horario (RF-BIEN-21) |
| `lib/pages/bienvenida/widgets/**` | El recibimiento, la franja, las burbujas, el compositor, el vuelo de Ulises y el paso al horario |
| `lib/components/logo/**` | El sello, con la estrella y «ULIMA++», que usan la franja de la conversación y la cabecera de las pantallas de «¿Olvidaste tu contraseña?» (RF-BIEN-4 y RF-BIEN-20), junto a la geometría del logo de la spec del splash |
| `lib/domain/bienvenida/bienvenida_turnos.dart` | Funciones puras de los turnos, el turno de cada error, el atrás, el conteo de cursos, la fórmula del pulso y del latido, las medidas del recibimiento, la regla «Si no cabe» y la configuración del botón de GIS en web como valores simples (decisiones B-26, B-27, B-28 y B-35) |
| `test/bienvenida/*.dart` | Las pruebas de «Pruebas por requisito» |

### Cambian

| Archivo | Qué cambia |
| --- | --- |
| `lib/main.dart` | `/login` muestra la bienvenida y sale `/registro`. En web, la ruta inicial del alumno sin especialidad pasa de `/setup-carrera` a `/login` (RF-SPL-12 y RF-BIEN-21) |
| `lib/pages/login/login_binding.dart` | Registra también el controlador de la bienvenida, permanente, sin reiniciar nada dentro del build. Cada visita empieza después del primer cuadro de su página (RF-BIEN-1) |
| `lib/pages/login/login_controller.dart` | Deja de navegar y devuelve el resultado a la bienvenida, también el de Google en web por un resultado observable. `submit` atrapa el fallo crudo de la red con un `finally` que apaga `submitting`. Vacía sus campos al salir la bienvenida (RF-BIEN-5 y RF-BIEN-6) |
| `lib/pages/registro/registro_controller.dart` | Suma un cierre propio que borra sus cinco campos enseguida y hace el `dispose` después de que el campo del compositor sale del árbol, para que la bienvenida lo cierre sin GetX. El texto de `intentarIniciarSesion` nombra «Ya tengo cuenta» (decisión B-30). Sus reglas no cambian |
| `lib/services/session_navigation.dart` | `offAllToLogin` suma el parámetro `motivo` |
| `lib/services/api_client.dart` | El interceptor del 401 pasa `motivo: expirada` y su aviso sale abajo (decisión B-29). El comentario de `esRuta401Exenta` deja de nombrar la pantalla de registro |
| `lib/pages/password_reset/reset_password_controller.dart` | Pasa `motivo: restablecida`, y sus avisos «Contraseña actualizada» y «Código reenviado» salen abajo (decisión B-29 y RF-BIEN-20) |
| `lib/pages/password_reset/forgot_password_controller.dart` | Su aviso «Solicitud enviada» sale abajo (RF-BIEN-20) |
| `lib/pages/password_reset/password_reset_ui.dart` | `PasswordResetScaffold` suma la opción de la cabecera con el sello, apagada por defecto, y la tarjeta queda bajo esa cabecera (RF-BIEN-20) |
| `lib/pages/password_reset/forgot_password_page.dart` y `reset_password_page.dart` | Encienden la cabecera con el sello y declaran íconos claros en la barra de estado (RF-BIEN-20) |
| `lib/pages/perfil/perfil.dart` | Solo la posición del aviso «Código enviado», que sale abajo porque aparece sobre `/reset-password` (RF-BIEN-20) |
| `lib/components/google_sign_in_button_web.dart` | `renderButton` con el `GSIButtonConfiguration` que sale de los valores de `lib/domain/bienvenida/`, y vuelve a dibujarse si cambia el tema (RF-BIEN-6) |
| `lib/components/google_sign_in_button.dart` y `google_sign_in_button_stub.dart` | La firma de `googleSignInButton` recibe la configuración de GIS. En Android e iOS la rama del stub sigue sin dibujar nada (enmienda técnica del 2026-09-26 a los targets, RF-BIEN-6 y decisión B-25) |
| `lib/components/chatbot_bubble.dart` | Informa su lugar y queda oculta hasta que Ulises aterriza solo cuando la capa se lo pide en el paso al horario (decisión B-16 y RF-BIEN-11) |
| `lib/pages/splash/**` | La capa permanente del `builder` suma su entrada para el paso al horario de la bienvenida (decisión B-33 y RF-SPL-4) |
| `lib/components/portal_consent/portal_consent_view.dart` | Solo el comentario de cabecera, que nombra `/registro`. La bienvenida usa sus constantes y Portal Sync sigue usando la pantalla |
| `lib/services/auth_service.dart` | Solo el comentario de `adoptarSesion` que nombra `/registro` (`:151-159`). `login`, `loginWithGoogle`, `finishGoogleLogin`, `adoptarSesion` y `logout` siguen igual |
| `lib/configs/themes.dart` | Los tokens de RF-BIEN-14 |
| `lib/pages/specialty_test/**` | Las piezas del duelo, la escala, la espera y el resultado se pueden dibujar dentro del compositor y de la conversación, y su controlador se puede crear y cerrar fuera de `SpecialtyTestBinding` (decisión B-34 y enmienda aprobada a la spec del test) |
| `README.md` | Las secciones del login, del registro y de la ruta post-login |
| `test/HU01_jeff/**`, `test/HU33_jeff/**` y `test/HU34_jeff/registro_consent_test.dart` | Pasan a montar la bienvenida donde montaban la tarjeta del login o la pantalla del registro |
| `test/HU20_jeff/**` | Se ajustan solo si alguna prueba depende de la posición de los avisos o del árbol de `PasswordResetScaffold` (RF-BIEN-20) |

### Salen

| Archivo | Por qué |
| --- | --- |
| `lib/pages/login/login_page.dart` | La bienvenida reemplaza a la tarjeta |
| `lib/pages/registro/registro_page.dart` y `lib/pages/registro/registro_binding.dart` | El registro corre dentro de la conversación (decisión B-23) |
| `test/HU33_jeff/registro_page_test.dart` | Sus casos pasan a `bienvenida_registro_test.dart` |

### No cambian

| Archivo | Por qué |
| --- | --- |
| `lib/services/registro_service.dart` | El plazo de 120 s y los mensajes siguen igual, también el de `USER_ALREADY_EXISTS` y el `SIN_CONEXION` de un corte durante el envío (decisión B-32) |
| `lib/services/post_login_route.dart` | Sigue decidiendo entre `/home` y `/setup-carrera`. La intro y la bienvenida traducen `/setup-carrera` en el test de la conversación (RF-SPL-12 y RF-BIEN-21) |
| `lib/pages/setup_carrera/**` | El asistente de carrera no cambia y queda sin llegadas desde el arranque y la bienvenida (decisión B-10) |
| `lib/services/password_reset_service.dart` y `lib/pages/password_reset/password_reset_validators.dart` | El restablecimiento conserva su servicio, sus rutas y sus validaciones (decisión B-9) |
| `lib/pages/portal_sync/portal_sync_page.dart` y `test/HU34_jeff/portal_sync_consent_test.dart` | Portal Sync sigue con `PasswordResetScaffold` sin el sello (RF-BIEN-20) |
| `test/HU02_jeff/session_navigation_guard_test.dart` | Sigue prohibiendo navegar a `/login` fuera de `session_navigation.dart` |

## Cambios en otras specs

- **Auth.** Enmienda en `specs/features/auth/auth.spec.md`, que el dueño aprueba con esta spec el
  2026-09-26. El formulario pasa a los turnos E1 y E2, `LoginController` deja de navegar, atrapa
  el fallo de red y deja de colgar el botón, la tarjeta sale, el botón de Google de Android e iOS
  dice «Continuar con Google», el de web se configura con `continueWith`, `/login` recibe el
  motivo de la llegada y el aviso «Sesión expirada» sale abajo. El alumno con la configuración a
  medias sigue en la conversación con el test, al entrar y al arrancar con la sesión guardada
  (decisión B-10), y «¿Olvidaste tu contraseña?» abre las pantallas de hoy con el sello (decisión
  B-9). BR-AUTH-F-01 a BR-AUTH-F-10 siguen en todo lo demás.
- **Registro.** Enmienda en `specs/features/registro/registro.spec.md`, que el dueño aprueba con
  esta spec el 2026-09-26. RS-FE-1 a RS-FE-6 y BR-REG-F-01 a BR-REG-F-11 siguen, aplicadas a los
  turnos de la conversación. Salen la ruta `/registro`, la pantalla de seis estados y su botón
  «Entrar», y `listo` pasa directo al test. `incierto` suma «Ya tengo cuenta», y su texto nombra
  ese enlace en lugar del login (decisión B-30).
- **Password Reset.** No tiene spec, y el índice la marca «Implementado sin spec» (fila 10). Esta
  spec cubre lo que cambia en sus pantallas, el sello en la cabecera y la posición de sus avisos
  (RF-BIEN-20), y el índice lo anota en esa fila.
- **Test de especialidad (enmienda aprobada a una spec aprobada).** La spec vive en
  `feat/test-especialidad-fe`, aprobada el 2026-09-25, con su último cambio en `e718c29` y la
  implementación en curso desde ese día. El dueño aprueba la enmienda el 2026-09-26 con esta
  spec, con B-10 en la opción que elige ese día, y queda anotada aquí como enmienda aprobada. Esa
  rama la suma a su spec con estos puntos, ya como aprobada. Como la implementación avanza, la
  enmienda puede tocar código ya escrito, como el controlador del test. El 2026-09-26, con la
  rama ya en `main` (`87403a1`), la enmienda queda escrita al final de esa spec, en «Enmienda de
  la bienvenida con Ulises».
  - **RF-TEST-1.** Suma un origen `bienvenida`. El alumno que crea su cuenta en la conversación,
    y el que tiene cuenta y todavía no elige su especialidad, hacen el test en ella, sin la ruta
    `/test-especialidad`, sin el paso de carrera y sin `/setup-carrera` (decisión B-10 y
    RF-BIEN-21). Ni el arranque ni la bienvenida llevan al asistente, que queda sin llegadas y
    sigue en el código hasta un cambio aparte. El punto «Destino tras el login» cambia así,
    porque `postLoginRoute` sigue igual pero la intro y la bienvenida traducen `/setup-carrera`
    en la conversación (RF-SPL-12). El Perfil sigue abriendo la ruta con `origen: perfil`. Con
    origen `bienvenida`, el controlador del test no lo crea
    `SpecialtyTestBinding`. Lo crea la bienvenida al empezar T0, sin `Get.put`, y lo cierra ella
    al pasar al horario, al reiniciarse, también tras un 401, y en el `dispose` de su página. Las
    reglas que viven en ese controlador, una sola evaluación en vuelo, el descarte del paso tras
    un atrás desde la espera y los guardados de uno en uno, no cambian (decisión B-34).
  - **RF-TEST-2.** Con origen `bienvenida`, el contenido se pide una vez en T0 y no hay precarga.
    Las respuestas siguen solo en memoria. Una evaluación o un `PUT` que responde después del
    cierre del controlador se descarta sin tocar la pantalla, y la guarda por dueño y
    el `clear()` de `logout()` siguen igual.
  - **RF-TEST-3.** Con origen `bienvenida` no hay pantalla de bienvenida del test. Su papel lo
    toma T0, con «¿Empezamos tu test de especialidad? Son T preguntas cortas.», «Empezar el test» y
    «Saltar y elegir por mi cuenta», y sus estados de carga, error y no disponible pasan a
    burbujas de Ulises (RF-BIEN-10). No hay «Seguir el test» ni «Empezar de nuevo», porque no hay
    pausa.
  - **RF-TEST-4.** Con origen `bienvenida` no hay barra de 52 px, plumas, historial plegado ni
    pausa. La franja con el sello hace de cabecera, el contador va en el rótulo del compositor,
    «Pregunta anterior» es un enlace del compositor y la conversación entera es el historial. Las
    reglas de las líneas de Ulises, del sello de bloque y del atrás no cambian.
  - **RF-TEST-5 y RF-TEST-6.** El duelo y la escala se dibujan también en el compositor, con las
    tarjetas compactas de la maqueta (decisión B-13) y la tarea de la escala en la burbuja de
    Ulises.
  - **RF-TEST-7.** Con origen `bienvenida`, la espera no tiene «la barra y las plumas llenas»,
    porque no hay barra. Es la burbuja con `ulises.loading` y su indicador, con el compositor
    vacío.
  - **RF-TEST-8.** Con origen `bienvenida`, el resultado va dentro de la conversación, que
    desplaza, y la regla «sin scroll» no aplica (decisión B-15). El atrás del sistema no hace nada,
    como en el asistente. El confeti se dibuja bajo la franja del sello.
  - **RF-TEST-9.** Con origen `bienvenida`, «Elegir como principal» y «Decidir después» terminan
    con la despedida y el paso al horario de RF-BIEN-11, en lugar de `Get.offAllNamed('/home')`.
  - **RF-TEST-11.** Con origen `bienvenida`, los textos de la tabla son burbujas de Ulises, y la
    fila del 401 sigue RF-BIEN-12, porque en `/login` el interceptor no navega.
  - **RF-TEST-13.** Con origen `bienvenida`, la burbuja de Ulises no es región viva y el foco del
    lector pasa a la primera burbuja nueva (RF-BIEN-16).
  - **«Textos nuevos» y «Pantallas y archivos».** Suman el origen `bienvenida` y los widgets que
    se dibujan en el compositor.
- **Splash.** RF-SPL-21 ya tiene su spec, aprobada con esta el 2026-09-26. La bienvenida recibe
  la pose, avisa al pintar su primer cuadro, declara su barra de estado y arranca sin pose
  (RF-BIEN-2, RF-BIEN-3 y RF-BIEN-17). Con la sesión de un alumno sin especialidad, el splash hace
  el mismo relevo y la bienvenida reconoce la sesión (RF-SPL-12 y RF-BIEN-21). El dueño aprueba
  juntas B-16 con S-28, sobre cómo aparece Ulises en `/home`, y B-10 con S-29, sobre el alumno que
  todavía no elige su especialidad. Las tablas «Para el dueño» de las dos specs lo dicen en cada
  fila. El paso al horario usa la capa del `builder`, que la spec del
  splash declara como pieza permanente con una entrada para la bienvenida (RF-SPL-4 y decisión
  B-33), y su manera de medir la cabecera (RF-SPL-11). Por eso `lib/pages/splash/**` está en los
  targets de esta spec. Las dos specs se publican juntas, en el mismo push a `main`
  («Verificación» y decisión S-30).
- **App shell.** La estrella de BR-SHELL-F-04 forma el sello, en la conversación y en las
  pantallas de «¿Olvidaste tu contraseña?», y es su destino en el paso al horario. La pestaña
  Horario la abre el argumento de BR-SHELL-F-02 enmendado. El dueño aprueba las dos con la spec
  del splash el 2026-09-26, y no cambia nada más.
- **Récord académico.** RF-REC-6 habla de una sola pantalla de consentimiento. En la
  conversación, el consentimiento es una tarjeta con los mismos textos y los botones «Acepto» y
  «Volver» (RF-BIEN-7). El dueño aprueba esta spec el 2026-09-26, y la nota queda escrita en esa
  spec el mismo día, en «Nota de la bienvenida con Ulises».
- **Perfil académico.** Con la decisión B-10, ningún alumno pasa por el asistente de carrera
  desde el arranque ni desde la bienvenida, así que `/setup-carrera` queda sin llegadas y no
  cambia (RF-BIEN-21). La nota queda escrita en esa spec el 2026-09-26, en «Nota de la bienvenida
  con Ulises», sobre la versión con la enmienda del test que ya está en `main`.
- **Chatbot.** `ChatbotBubble` informa su lugar y espera a Ulises solo en el paso al horario de
  la bienvenida (decisión B-16 y RF-BIEN-11). En las demás llegadas a `/home` aparece como hoy. La
  nota queda escrita en esa spec el 2026-09-26, en «Nota de la bienvenida con Ulises».
- **Maquetas de `docs/images/UI`.** `InicioSesion.png` queda superada por la bienvenida. `AGENTS.md`
  pide respetar esas maquetas salvo un cambio aprobado, así que la aprobación de esta spec es ese
  cambio. La imagen no se toca.
- **Índice.** `docs/specs/feature-index.md` suma la fila 24 de esta spec, anota las enmiendas en
  las filas de Auth, Registro y Splash y anota el sello en la fila de Password Reset. El
  2026-09-26 esas filas registran la aprobación.

## Qué NO entra

- Endpoints nuevos o cambios en el backend.
- Arreglar que `POST /auth/register` distinga por sí mismo si un código tiene cuenta, que es de la
  spec del backend (RF-BIEN-9).
- Recuperar la contraseña dentro de la conversación, alternativa que el dueño descarta el
  2026-09-26 (decisión B-9).
- Cambiar los textos, los pasos, las rutas o el servicio del restablecimiento de contraseña, que
  solo suma el sello y baja sus avisos (RF-BIEN-20).
- Arreglar que `AuthService.login` guarde el token antes de cargar los catálogos
  (`auth_service.dart:235-242`). Un fallo de red en ese tramo deja el token sin `currentUser`, y
  el siguiente arranque en frío restaura esa sesión aunque Ulises haya dicho «No hay conexión.».
  Es una deuda previa a esta spec, que va en un cambio aparte de auth.
- Guardar la conversación, retomarla en otro arranque o recordar qué rama eligió el teléfono.
- Ulises con IA. Sus líneas son textos fijos de esta spec y del contenido del test, y la
  bienvenida no llama al servicio del chatbot.
- Cambiar o quitar el asistente de `/setup-carrera`, que queda sin llegadas desde el arranque y
  la bienvenida (RF-BIEN-21), o la ruta del test que abre el Perfil. Quitar el asistente, con el
  origen `asistente` de la spec del test, va en un cambio aparte.
- Pasar lo escrito de una rama a la otra.
- Vibración nueva fuera de la del test.
- Sonido.
- Desplegar la app en web.
- Las alternativas de «Decisiones», que el dueño descarta el 2026-09-26.

## Decisiones

Son 35, 23 para el dueño y 12 técnicas. El dueño las aprueba todas el 2026-09-26 en la opción que
la spec toma por defecto, salvo B-9 y B-10, donde elige otra opción. Las B-27 a B-35 llegan el
2026-09-25 con la corrección de una revisión, que abre como decisión lo que la versión anterior
daba por hecho.

### Aprobación del dueño del 2026-09-26

El dueño aprueba la spec con «aplica» y lo confirma como «Arranque: todas las recomendadas». En la
misma aprobación cambia dos decisiones, porque cumplen mejor lo que pidió, «que no se pierda el
logo» y «con sesión, luego del splash, ver su horario».

- **B-10, junto con S-29 del splash.** El alumno con cuenta que todavía no elige su especialidad
  no va al asistente de carrera. Va a la conversación con Ulises, que le toma el test ahí mismo
  con el logo en la cabecera y después lo lleva a su horario (RF-BIEN-21).
- **B-9.** «¿Olvidaste tu contraseña?» conserva las pantallas de hoy, con el sello del logo
  ULima++ y sus «++» en su cabecera, para que el logo nunca se pierda (RF-BIEN-20).

Tres decisiones del splash quedan además explícitas en su opción por defecto. Todos los roles
abren en Horario (S-24), el splash y la bienvenida se publican juntos (S-30) y la animación se ve
siempre completa (S-6).

### Pedidos del dueño del 2026-09-25

La spec recoge estos pedidos del dueño, y el dueño aprueba su texto con el resto el 2026-09-26.
Con B-9 y B-10 en la opción que elige ese día, las opciones aprobadas cumplen cada pedido entero.

- Tras la intro al azar del splash, la estrella grande con sus «++» queda en el centro, entera y
  sin nada encima, y Ulises entra volando y aterriza a su lado (RF-BIEN-2). En su iPhone SE con
  la letra al 100 %, la estrella no se mueve. Con letra más grande, o en una pantalla más baja,
  sube un poco para que Ulises y su saludo quepan sin taparla (B-28).
- Ulises saluda con «¿Ya usas ULima++?» y dos botones grandes, «Sí, entrar» y «Soy nuevo», y al
  responder la estrella sube al sello junto a «ULIMA++» y sigue una conversación (RF-BIEN-2,
  RF-BIEN-4 y RF-BIEN-5).
- El que vuelve inicia sesión dentro de la conversación, con su código, su contraseña, «¿Olvidaste
  tu contraseña?» y «Continuar con Google» con el logo oficial de colores, y va a su horario
  (RF-BIEN-6 y RF-BIEN-11). «¿Olvidaste tu contraseña?» lleva a las pantallas de hoy, con el
  sello en su cabecera (B-9 y RF-BIEN-20). El alumno que tiene cuenta pero todavía no elige su
  especialidad hace antes el test con Ulises y termina en su horario (B-10, que el dueño elige
  junto con S-29, y RF-BIEN-21).
- El nuevo crea su cuenta dentro de la conversación con el registro que ya existe y, sin cortar la
  conversación, sigue con el test de especialidad con Ulises hasta su horario (RF-BIEN-7,
  RF-BIEN-8, RF-BIEN-10 y RF-BIEN-11). Si cierra la app después de crear la cuenta y antes de
  elegir su especialidad, al volver Ulises lo retoma en la invitación al test (B-10, B-14 y
  RF-BIEN-21).
- El sello late con cada respuesta y un pulso recorre los rombos mientras se crea la cuenta
  (RF-BIEN-4). Con «reducir movimiento» activado en el teléfono no late ni pulsa, y la píldora
  «Creando tu cuenta…» dice sola que se espera (RF-BIEN-15).
- «Soy nuevo» y «Ya tengo cuenta» quedan siempre visibles, para no revelar qué códigos tienen
  cuenta (RF-BIEN-9). La excepción es el envío del registro, que no se puede abandonar, y después
  de creada la cuenta ya no hacen falta.
- El logo ULima++ con sus «++» no se pierde en ningún momento (RF-BIEN-4). Tampoco mientras el
  alumno cambia su contraseña, porque las pantallas de «¿Olvidaste tu contraseña?» llevan el
  sello (B-9 y RF-BIEN-20), ni con el alumno que todavía no elige su especialidad, que sigue en
  la conversación con el logo en el sello (B-10, S-29 y RF-BIEN-21).

### Para el dueño

Cambian lo que ve el alumno. La columna «Opción aprobada» dice la opción que el dueño aprueba el
2026-09-26, que en todas salvo B-9 y B-10 es la que la spec toma por defecto, y «Qué ve el alumno»
la describe. Las dos primeras columnas de texto y la alternativa van en palabras llanas. Los
códigos, los archivos y los contrastes quedan en «Dónde queda». Una decisión que el dueño aprueba
junto con otra de la spec del splash lo dice en su fila.

| # | Decisión | Opción aprobada | Qué ve el alumno | Alternativa | Dónde queda |
| --- | --- | --- | --- | --- | --- |
| B-1 | Cuándo empieza el test del alumno nuevo | Cuando la cuenta ya está creada, porque el servidor solo entrega el test a quien ya tiene sesión | Mientras se crea la cuenta, hasta un par de minutos, ve a Ulises, la píldora «Creando tu cuenta…» y los rombos del logo que se encienden por turnos. Después Ulises lo invita al test | Como en la maqueta, el test empieza mientras se crea la cuenta, con «Mientras tanto, ¿empezamos…?», «Prefiero esperar» y «Empezar el test». Pide cambiar el servidor para que entregue el test sin sesión, y decidir qué pasa con las respuestas si la cuenta no llega a crearse, por ejemplo por un código del authenticator vencido o porque el portal no muestra matrícula | RF-BIEN-8 y RF-BIEN-10. El contenido exige el token (RS-BE-38 del backend). La alternativa sirve el contenido sin token y sin `specialtyId`, enmienda RS-BE-38 y `docs/specs/api-contracts.md`, y descarta el test con `NOT_ENROLLED`. El envío dura hasta 120 s (B-17) |
| B-2 | Cuándo aparecen los dos botones | Como en la maqueta, después del aterrizaje de Ulises | Ve el vuelo completo. El que vuelve puede tocar «Sí, entrar» de 3,5 a 3,7 s después de abrir la app, unos 3 s más tarde que hoy la tarjeta del login | Los botones aparecen apenas termina la animación del logo, mientras Ulises todavía vuela, y el que vuelve puede tocar «Sí, entrar» unos 2 s antes | RF-BIEN-2 y S-6. Los botones empiezan a entrar a los 2,32 s del relevo |
| B-3 | Color de «Soy nuevo» con el teléfono en claro | Un botón naranja oscuro, con el borde y el texto blancos | Un botón naranja más oscuro que el fondo, que se lee bien | El blanco translúcido de la maqueta, que sobre el naranja cuesta leer | RF-BIEN-14. Por defecto `#B84A00`, con 5,23:1. La alternativa da 2,59:1, bajo el 4,5:1 que pide la app |
| B-4 | El nombre en las frases de Ulises | Sin nombre, porque el servidor manda primero los apellidos y la app no sabe cuál es el nombre de pila | «¡Craa! Tu cuenta ya está lista.» y «¡Hola de nuevo!» | Suponer que el nombre de pila son las palabras después de las dos primeras, lo que falla con un solo apellido o con apellidos compuestos | RF-BIEN-6 y RF-BIEN-8 (`user_model.dart:52-65`) |
| B-5 | Cómo se envía el código del authenticator | Con el botón «Crear mi cuenta», como hoy | Escribe los seis dígitos y toca el botón | Se envía solo al completar las seis casillas, como en la maqueta, lo que deja fuera los códigos de ocho dígitos y gasta uno de los cinco intentos por hora con cada error de tipeo | RF-BIEN-7 |
| B-6 | Qué pasa tras un login rechazado | Ulises dice el error y vuelve a pedir el código, ya escrito, con la contraseña vacía | Puede corregir el código o la contraseña | Se queda en el paso de la contraseña, con el error debajo y la contraseña escrita, como hoy la tarjeta | RF-BIEN-6 y RF-BIEN-12 |
| B-7 | Llegar después de cerrar sesión | Ulises lo vuelve a recibir, con el logo en el centro, el vuelo y la pregunta | Tras cerrar sesión ve el recibimiento completo, porque el teléfono puede cambiar de manos | La conversación directa, con la pregunta como respuestas rápidas y sin el vuelo | RF-BIEN-3 |
| B-8 | Llegar con la sesión vencida o con la contraseña recién cambiada | Directo a «¿Cuál es tu código o usuario?», con «Soy nuevo» a la vista | Escribe su código sin volver a responder la pregunta | Igual que tras cerrar sesión | RF-BIEN-3 (`motivo: expirada` y `motivo: restablecida`) |
| B-9 | «¿Olvidaste tu contraseña?». Elegida por el dueño el 2026-09-26 | Las pantallas de hoy, encima de la conversación, con el sello del logo ULima++ y sus «++» en su cabecera | Cambia su contraseña en las pantallas de hoy, con el logo arriba en el mismo lugar que en la conversación, así que nunca lo pierde de vista. Los avisos de esas pantallas salen abajo | La opción por defecto anterior, las pantallas de hoy sin el sello, o la recuperación dentro de la conversación con los textos de hoy. El dueño descarta las dos | RF-BIEN-6 y RF-BIEN-20 (`/forgot-password` y `/reset-password`). Suma a los targets `lib/pages/password_reset/**` y la línea del aviso «Código enviado» de `perfil.dart` |
| B-10 | El alumno con cuenta que todavía no elige su especialidad, al abrir la app o al entrar. Elegida por el dueño el 2026-09-26, junto con S-29 | Sigue en la conversación con Ulises, que le toma el test ahí mismo con el logo en la cabecera y después lo lleva a su horario | Al abrir la app, Ulises aterriza junto al logo, el logo sube a la cabecera y Ulises lo invita al test. Al entrar con su código, Ulises le dice que le falta elegir su especialidad y lo invita al test. Al terminar ve su horario, y en ningún momento deja de ver el logo | La opción por defecto anterior, que el dueño descarta. Iba al asistente de carrera de hoy, y el logo se desvanecía | RF-BIEN-6, RF-BIEN-10, RF-BIEN-13 y RF-BIEN-21, y RF-SPL-12 del splash. `/setup-carrera` queda sin llegadas desde el arranque y la bienvenida. Es la misma opción de S-29 |
| B-11 | La carrera dentro de la conversación | No se pregunta ni se menciona, porque hay una sola carrera y la app ya la conoce por la cuenta | Pasa de la cuenta creada a la invitación al test | Ulises dice la carrera en una burbuja antes de la invitación | RF-BIEN-10 |
| B-12 | La presentación de Ulises al empezar el test | No se repite, porque Ulises ya se presentó | «¿Empezamos tu test de especialidad? Son T preguntas cortas.» | Las frases de bienvenida del test antes de la invitación, aunque repitan «Soy Ulises» | RF-BIEN-10 (las líneas `welcome` del contenido) |
| B-13 | El tamaño de las tarjetas de «esto o aquello» en la conversación | Las compactas de la maqueta | Las dos opciones caben abajo con la pregunta a la vista | Las tarjetas grandes del test en su pantalla propia, casi el doble de altas, que obligan a desplazar la zona de respuesta | RF-BIEN-10. Las compactas miden 56 dp con la baldosa de 40 dp, y las de RF-TEST-5, 104 dp con la de 80 dp |
| B-14 | Salir del test a mitad | Sin botón de pausa ni de salto dentro de las preguntas | Termina el test o cierra la app, y al volver Ulises lo retoma en la invitación al test (B-10) | «Saltar y elegir por mi cuenta» también en cada pregunta | RF-BIEN-10 y RF-BIEN-21 |
| B-15 | El resultado del test | Dentro de la conversación, que se desplaza | Ve el resultado debajo de su última respuesta y desplaza para verlo entero | Una hoja encima de la conversación que muestra el resultado entero sin desplazar, como el test en su pantalla propia | RF-BIEN-10. La alternativa cumple la regla «sin scroll» de RF-TEST-8 |
| B-16 | Ulises al llegar al horario desde la conversación. Aprobada junto con S-28 | Vuela a su burbuja de siempre, como en la maqueta | Ulises se mueve de la conversación a su esquina del inicio | Se desvanece y su burbuja aparece con la página, como la opción por defecto de S-28 | RF-BIEN-11. Cambia `chatbot_bubble.dart` |
| B-17 | Qué dice Ulises del tiempo que tarda crear la cuenta | «Estoy creando tu cuenta y trayendo tu ciclo.» y, en otra burbuja, la frase de hoy, «Puede tomar un par de minutos: no cierres la app.» | Sabe que puede tardar hasta un par de minutos y que no debe salir, como hoy en la pantalla del registro | La frase de la maqueta, «Tarda cerca de un minuto.», que promete menos de lo que puede durar y todavía no tiene una medición que la respalde. Si tarda más, el alumno puede creer que la app está colgada, cerrarla y quedarse con la cuenta a medias. O una frase que diga el tope, como «Puede tardar hasta dos minutos. No cierres la app.» | RF-BIEN-8. El plazo es de 120 s (`registro_service.dart:28` y BR-REG-F-08), la frase de hoy está en `registro_page.dart:301-302` y el envío real todavía no se mide contra el portal |
| B-27 | El tamaño de Ulises, la tarjeta y los botones del recibimiento frente a la maqueta | Ulises crece junto con la estrella y guarda su proporción, y la tarjeta y los botones quedan del tamaño de la maqueta, como el resto de la conversación | Ulises junto a la estrella como en la maqueta, y la tarjeta y los botones un poco más chicos frente a ellos. En su iPhone SE, con la letra al 100 %, todo cabe y la estrella se queda en el centro | Todo crece igual que la estrella, también la letra de la tarjeta y los botones. Se ve como la maqueta, pero en el iPhone SE ya no cabe y la estrella tiene que subir unos 4 mm con la letra al 100 % | «Requisitos» y RF-BIEN-2. El dibujo se escala por 1,2 (90 dp frente a 75 px) y la interfaz va en dp iguales a sus px. Ulises mide 62 y 70 dp |
| B-28 | Qué pasa si Ulises y su saludo no caben junto a la estrella, con letra grande o en una pantalla baja | La estrella sube lo justo antes de que Ulises aterrice y, si hace falta, se achica. Si ni así cabe, Ulises saluda ya en la conversación | En su iPhone SE, con la letra al 100 %, la estrella no se mueve. Con la letra al 130 % puede subir unos milímetros, y al 200 %, cerca de 1,5 cm | La estrella nunca se mueve ni se achica, y cuando no cabe, Ulises saluda ya en la conversación, con el logo en el sello y la pregunta como respuestas rápidas | RF-BIEN-2 y RF-BIEN-16. Sube a lo sumo hasta 24 dp del borde de arriba y se achica hasta R = 60 dp. Unos 15 dp al 130 % y 95 dp al 200 % en 375 × 667 |
| B-29 | Dónde salen los avisos «Sesión expirada», «Contraseña actualizada» y «Estamos creando tu cuenta» | Abajo en la pantalla, con su texto de hoy, para no tapar el logo | Ve el aviso abajo, sobre la zona de respuesta, y el logo arriba entero | Que los diga Ulises en una burbuja de la conversación en lugar del aviso | RF-BIEN-3, RF-BIEN-4 y RF-BIEN-8. Hoy son `Get.snackbar` arriba (`extension_navigation.dart:434`), en `api_client.dart:159`, `reset_password_controller.dart:162-165` y `registro_page.dart:73-78`. RF-BIEN-20 aplica la misma regla a «Solicitud enviada», «Código reenviado» y «Código enviado», que salen sobre las pantallas con el sello |
| B-30 | Cómo recupera su contraseña quien queda en la duda de si su cuenta existe | Ulises dice que puede recuperarla con «Ya tengo cuenta», y ese enlace está a la vista en ese momento | Toca «Ya tengo cuenta», escribe su código y, en la contraseña, toca «¿Olvidaste tu contraseña?» | El texto de hoy, que dice «desde el login», una pantalla que ya no existe, y el enlace solo aparece después de tocar «Volver a intentar el registro» | RF-BIEN-8, RF-BIEN-9 y BR-REG-F-11 (`registro_controller.dart:321-323`) |
| B-31 | Lo que dice Ulises cuando la cuenta está lista | Una burbuja con la cuenta lista y cuántos cursos del ciclo trae, como en la maqueta | «¡Craa! Tu cuenta ya está lista. Traje tus 6 cursos del ciclo.» Ya no ve cuántas clases hay en su horario ni cuántos cursos tiene su avance, cifras que hoy muestra la pantalla del registro | Ulises suma otra burbuja con esas dos cifras, con textos nuevos | RF-BIEN-8. Hoy son las filas «Clases en tu horario» y «Cursos de tu avance» (`registro_page.dart:335-337`) |
| B-32 | Si la conexión se corta mientras se crea la cuenta, también con la app en segundo plano | Como hoy, Ulises dice «No hay conexión…» y vuelve a pedir el código del authenticator | Puede reenviar. Si la cuenta sí existe, el reenvío le dice que ya existe una cuenta con ese código, y entra con «Ya tengo cuenta» | Tratarlo como la duda de cuando vence el plazo, con «No pudimos confirmar si tu cuenta se creó» y la opción de iniciar sesión, porque el pedido pudo llegar al servidor. Un corte antes de enviar también caería en esa duda | RF-BIEN-8 y RF-BIEN-13 (`registro_service.dart:65-71` y `registro_controller.dart:283-285`). La alternativa cambia `RegistroService` |

### Técnicas (las propone el equipo)

No cambian lo que ve el alumno, salvo donde la columna lo dice. El dueño las aprueba el 2026-09-26
en la propuesta del equipo.

| # | Decisión | Propuesta del equipo | Alternativa | Qué ve el alumno | Dónde queda |
| --- | --- | --- | --- | --- | --- |
| B-18 | Dónde vive la conversación | Una sola ruta, `/login`, con los tramos del login, del registro y del test dentro | Las rutas `/login`, `/registro` y `/test-especialidad` con un andamio común y sin transición, con el historial pasado como argumento y el envío del registro sobreviviendo al cambio de ruta | Nada distinto | RF-BIEN-1 |
| B-19 | Vida del controlador de la bienvenida | Permanente, como `LoginController`, con una visita por cada montaje de su página. El primer cuadro sale de los argumentos de la ruta, el reinicio va después de ese cuadro y el `dispose` de la página vieja no toca la visita nueva | Uno por visita con `lazyPut`, que expone de nuevo el «tipeo fantasma» si dos `/login` conviven | Nada distinto | RF-BIEN-1 |
| B-20 | Vida del controlador del registro | La bienvenida lo crea y lo cierra ella misma, sin `Get.put`. Al cerrarlo borra los campos enseguida y hace el `dispose` cuando el campo del compositor ya no está en el árbol | `Get.put` con una etiqueta y `Get.delete` al cerrar, con el riesgo de atarlo a la ruta de un aviso | Nada distinto | RF-BIEN-9 |
| B-21 | Cómo sabe la bienvenida por qué llega | El parámetro `motivo` de `offAllToLogin`, como argumento de ruta | Un campo en un service que la bienvenida lee y borra | Nada distinto | RF-BIEN-1 |
| B-22 | El 401 dentro de la conversación | Comprobar el token guardado tras cada fallo de un turno con sesión | Un aviso desde el interceptor de `ApiClient` a la bienvenida | Nada distinto | RF-BIEN-12 |
| B-23 | La ruta `/registro` | Sale con `RegistroPage` y `RegistroBinding` | Se queda sin enlaces que la abran | Nada distinto | RF-BIEN-1 |
| B-24 | Los colores | Los tokens del test y los nuevos de RF-BIEN-14 | Tokens propios para todo | Nada distinto | RF-BIEN-14 |
| B-25 | Web | La bienvenida también en web, con el botón oficial de GIS configurado con `continueWith`, `es` y el tema del sistema | La tarjeta de hoy en web | En web, la conversación en lugar de la tarjeta. Web no se despliega (`README.md:701`) | RF-BIEN-1 y RF-BIEN-6 |
| B-26 | Dónde va la lógica pura | `lib/domain/bienvenida/`, como la del truco del 67 | Dentro de `lib/pages/bienvenida/` | Nada distinto | «Pantallas y archivos» |
| B-33 | Quién dibuja el paso al horario | La capa del splash, que pasa a ser una pieza permanente del `builder` de `GetMaterialApp`, montada también en web, con una entrada para la bienvenida que cubre lo que se dibuja, la medición de la cabecera y de `ChatbotBubble`, el bloqueo de toques, su semántica «ULIMA++» sin «cargando» y el aviso a `HomePage` para las orientaciones | Una capa propia de la bienvenida en el `builder`, que duplica esa medición, el bloqueo de toques, la semántica y el aviso a `HomePage` | Nada distinto | RF-BIEN-11 y RF-SPL-4. Suma `lib/pages/splash/**` a los targets |
| B-34 | Vida del controlador del test en la conversación | La bienvenida lo crea al empezar T0 y lo cierra ella misma, sin `Get.put`, y descarta la evaluación o el `PUT` que responde después de cerrarlo | `Get.put` con una etiqueta y `Get.delete` al cerrar, con el riesgo de atarlo a la ruta de un aviso (`main.dart:124-128`) | Nada distinto | RF-BIEN-10 y enmienda aprobada a RF-TEST-1 y RF-TEST-2 |
| B-35 | Cómo se prueba la configuración del botón de Google en web | Una función pura de `lib/domain/bienvenida/` da los valores, que la VM prueba con `flutter test --no-pub`. La llamada a `renderButton` queda sin prueba automática y la comprueba la revisión manual en Chrome | La prueba del widget de web con `flutter test --platform chrome`, como paso aparte de «Verificación», porque `google_sign_in_button_web.dart` solo compila en web | Nada distinto | RF-BIEN-6 |

## Pruebas por requisito

Todas se crean con la implementación y hoy no existen. Las de widget usan dobles escritos a mano,
un `ApiClient` falso y datos inventados, con el alumno de prueba 20230001.

| Requisito | Pruebas | Qué fijan |
| --- | --- | --- |
| RF-BIEN-1 | `bienvenida_ruta_test.dart` | `/login` muestra la bienvenida; `LoginController` y la bienvenida permanentes; la visita por montaje, con el primer cuadro sacado de los argumentos y sin nada de la visita anterior tras un cierre de sesión que deja la franja con el sello; el restablecimiento con dos `/login` a la vez, sin `setState` durante el build y sin que el `dispose` de la página vieja toque la visita nueva; la navegación en la bienvenida y no en `LoginController`; sin `/registro`; el motivo de cada llegada, también el botón «Volver a iniciar sesión» del Perfil; la guarda de `session_navigation_guard_test.dart` en verde |
| RF-BIEN-2 | `bienvenida_recibimiento_test.dart` | El primer cuadro idéntico a la pose recibida, en claro y en oscuro; el aviso a la capa; Ulises de 62 y 70 dp y su lugar medido desde la estrella; las medidas de la tarjeta y los botones; los tiempos de la tarjeta y de los botones; los toques ignorados antes de que los botones empiecen a entrar; a 375 × 667, la estrella quieta con 1,0 y nada dentro de su margen ni encima de los botones con 1,0, 1,3 y 2,0; la subida y el achique de la estrella cuando no cabe y el paso directo a la conversación como último recurso; el primer grupo con las dos burbujas y la respuesta |
| RF-BIEN-3 | `bienvenida_recibimiento_test.dart` | El recibimiento corto sin argumentos; la estrella centrada en la vista en web; directo a E1 con `expirada` y con `restablecida`; «Soy nuevo» a la vista; el sello entero desde el primer cuadro |
| RF-BIEN-4 | `bienvenida_sello_test.dart` | El sello a 1,22 veces la cabecera; el latido con cada respuesta y al posarse; el pulso solo durante el envío y su fórmula; la vuelta a la opacidad plena con cada desenlace; el encabezado «ULIMA++»; los avisos «Sesión expirada», «Contraseña actualizada» y «Estamos creando tu cuenta» abajo, sin tapar el sello; el confeti bajo la franja |
| RF-BIEN-5 | `bienvenida_conversacion_test.dart` | Los grupos y las respuestas; el ritmo de 850 y 500 ms; el compositor y sus piezas; el botón de envío inactivo con el campo vacío; el historial sin secretos, borrado al reiniciar, tras el 401 y al pasar al horario; los campos de `LoginController` vacíos en esas salidas; el teclado |
| RF-BIEN-6 | `bienvenida_entrar_test.dart` | E1, E2 y E3 con sus textos; el usuario alfanumérico; el `AutofillGroup` con el campo de E1 montado durante E2 y `finishAutofillContext` antes de vaciar; el error que vuelve a E1; el fallo de red atrapado en `LoginController`, con `submitting` apagado; Google en Android e iOS con «Continuar con Google» y la cancelación; el resultado de Google en web por el canal observable, con una cuenta falsa; los valores de la configuración de GIS, que salen de la función pura y se prueban en la VM (decisión B-35); «¿Olvidaste tu contraseña?» abre `/forgot-password` encima; «Soy nuevo» en E1 y E2; el destino según el rol y la configuración, con la configuración a medias que sigue con «¡Hola de nuevo! Te falta elegir tu especialidad.» y T0, sin navegar a `/setup-carrera` |
| RF-BIEN-7 y RF-BIEN-8 | `bienvenida_registro_test.dart` | N1 a N5 con sus textos; los validadores por turno sin red; la tarjeta del consentimiento literal; «Volver» y el consentimiento que no se repite; el envío solo con el botón; las dos burbujas del envío con la frase de hoy; el plazo de 120 s; el `PopScope` y su aviso; cada código de error con su turno de destino y el código del authenticator borrado; el fallo de red durante el envío que vuelve a N5; `incierto` con sus dos títulos, sus salidas, «Ya tengo cuenta» y el texto que lo nombra; el 201 en una burbuja con el conteo, sin frase con 0 cursos o sin `summary`, y los avisos; el paso al test |
| RF-BIEN-9 | `bienvenida_credenciales_test.dart` | Los cinco campos fuera de todo `Rx` y del historial; el cierre al tocar «Ya tengo cuenta», también desde `incierto`, al pasar al test, al reiniciar, tras el 401 y en el `dispose` de la página, guardado por la visita; los campos borrados enseguida y el `dispose` después de que el campo sale del árbol, sin error de `TextEditingController`; el controlador creado sin `Get.put` con un aviso abierto; las dos contraseñas nunca a la vez; ningún pedido al backend antes del envío; «Soy nuevo» y «Ya tengo cuenta» fijos, también tras un login rechazado y tras `USER_NOT_FOUND` de Google |
| RF-BIEN-10 | `bienvenida_test_especialidad_test.dart` | El controlador del test creado sin `Get.put` y cerrado al pasar al horario, al reiniciar, tras el 401 y en el `dispose`; la evaluación y el `PUT` que responden después, descartados; T0 con T del contenido; la carga, el error y el `404`; las líneas de Ulises por pregunta; el duelo y la escala en el compositor; las respuestas del alumno; «Pregunta anterior»; la espera y el desempate; el resultado con sus tres botones; la despedida y el paso al horario; «Rehacer el test»; la selección manual; `careerId` nulo sin llamar a `completeSetup`; el confeti bajo la franja; sin pausa; el docente sin test |
| RF-BIEN-11 | `bienvenida_horario_test.dart` | `Get.offAll` a `/home` con el argumento de Horario y sin transición; la entrada de la capa permanente, que sigue montada tras la navegación; el historial, el registro y el test cerrados antes; Ulises en la burbuja del alumno y desvanecido para el docente; la burbuja oculta hasta el aterrizaje solo en este paso, y visible con la página al llegar desde el splash; el fundido cruzado cuando algo no se mide; los toques bloqueados; la orientación vertical hasta que la capa se retira |
| RF-BIEN-12 | `bienvenida_errores_test.dart` | Cada fila de la tabla; el 401 en un turno con sesión, con la limpieza local y la vuelta a E1 |
| RF-BIEN-13 | `bienvenida_atras_test.dart` | Cada fila de la tabla del atrás; el envío que no se abandona; el corte de la conexión en segundo plano, que vuelve a N5 y no a `incierto`; el atrás antes de T0 en la llegada con sesión, que sale de la app; la sesión guardada con la configuración a medias, que al abrir la app vuelve a T0 con el test desde cero |
| RF-BIEN-14 | `bienvenida_contraste_test.dart` | Cada token en los dos temas; cada par de la tabla de contraste; el recibimiento oscuro |
| RF-BIEN-15 | `bienvenida_movimiento_test.dart` | Sin vuelo, estela, latido, pulso ni desplazamiento con reducir movimiento; los fundidos y sus tiempos; en la subida al sello, en el paso al horario y en «Si no cabe», un logo a opacidad plena en cada cuadro; las pausas del ritmo que se quedan |
| RF-BIEN-16 | `bienvenida_accesibilidad_test.dart` | El encabezado, los grupos y «Tú, <texto>»; el recibimiento sin espera con lector de pantalla; el nodo «ULIMA++» sin «cargando» durante el paso al horario; las burbujas de un turno juntas y el foco en la primera; las regiones vivas; las etiquetas «Enviar», «Mostrar contraseña» y «Ocultar contraseña»; los blancos de 48 dp; el orden de foco con teclado físico; sin desborde con 1,0, 1,3 y 2,0 |
| RF-BIEN-17 | `bienvenida_barra_estado_test.dart` | Los íconos claros en los dos temas; la columna de 600 dp en una pantalla ancha |
| RF-BIEN-18 | Ninguna | La medición manual de «Verificación» |
| RF-BIEN-19 | Ninguna | Es documentación |
| RF-BIEN-20 | `bienvenida_restablecer_test.dart` | El sello en la cabecera de `/forgot-password` y de `/reset-password`, en claro y en oscuro, en el mismo lugar y del mismo tamaño que en la franja de la conversación; también en `/reset-password` abierta desde el Perfil; el sello quieto; a 375 × 667, con 1,0, 1,3 y 2,0, el sello fuera de la zona de la flecha y la tarjeta bajo la cabecera, también con el teclado abierto; «Solicitud enviada», «Código reenviado» y «Código enviado» abajo, sin tapar el sello; los íconos claros; el encabezado «ULIMA++»; `PasswordResetScaffold` sin el sello cuando no se enciende, como en Portal Sync |
| RF-BIEN-21 | `bienvenida_sin_especialidad_test.dart` | La llegada con la pose y con la sesión de un alumno sin especialidad, con el primer cuadro idéntico a la pose; sin la tarjeta ni los botones; la subida al sello al terminar el rebote, el salto de Ulises y el primer grupo con sus dos burbujas; T0 a los 3,62 s del relevo; en web, el recibimiento corto con la sesión; tras «Sí, entrar» y con Google, «¡Hola de nuevo! Te falta elegir tu especialidad.» y T0; sin sesión o con `motivo: expirada`, la llegada de siempre aunque `currentUser` quede en memoria; el test hasta el paso al horario; nunca `/setup-carrera` |

Además, siguen en verde y se ajustan a la bienvenida
`test/HU01_jeff/login_navigation_paths_test.dart` y `login_relogin_regression_test.dart`, que cubren
los caminos a `/login` y el «tipeo fantasma»; `test/HU33_jeff/registro_controller_test.dart`,
`registro_service_test.dart` y `api_client_401_test.dart`, que cubren las reglas del registro; y los
casos 10 a 12 de `test/HU34_jeff/registro_consent_test.dart`, que pasan a montar la conversación.
También siguen en verde `test/HU20_jeff/**`, que cubre el restablecimiento de contraseña, y
`test/HU34_jeff/portal_sync_consent_test.dart`, que monta `PasswordResetScaffold` sin el sello.

## Verificación

- Antes de aprobar, el dueño abre `docs/images/UI/bienvenida/ulises-te-recibe-combinada.html`
  para ver los recorridos «Soy nuevo» y «Ya tengo cuenta», en claro y en oscuro, con y sin reducir
  movimiento, y la lista de diferencias de su `README.md`. Aprueba el 2026-09-26, y la maqueta
  sigue como referencia de la revisión manual.
- `dart format` sobre los archivos Dart que cambien.
- `flutter analyze --no-pub`.
- `flutter test --no-pub` con la suite completa, porque cambian `main.dart`,
  `session_navigation.dart`, `api_client.dart` y `LoginController`, que usan otras
  funcionalidades. Incluye `test/bienvenida`, `test/HU01_jeff`, `test/HU02_jeff`, `test/HU20_jeff`,
  `test/HU33_jeff` y `test/HU34_jeff`.
- La bienvenida y el splash se publican juntos, en el mismo push a `main`, porque la bienvenida
  recibe la pose del splash y usa su capa, y el splash sin sesión termina en la bienvenida
  (decisión S-30). Tampoco se publica antes que el test de especialidad, cuyas piezas dibuja.
  Cada push a `main` publica el APK (`.github/workflows/build-apk.yml`).
- Una revisión manual en un Android 12 a 14 con barra de tres botones, en un Android 15 o superior y
  en el iPhone SE del dueño, en claro y en oscuro, con los recorridos «Sí, entrar» con código y con
  Google, un docente, «Soy nuevo» hasta el horario, un error de cada tramo y el modo avión durante
  el envío. Suma un alumno de prueba con cuenta y sin especialidad, al abrir la app y al entrar con
  su código, hasta el horario, y «¿Olvidaste tu contraseña?» hasta entrar con la contraseña nueva,
  además del restablecimiento desde el Perfil. La misma revisión con TalkBack, con VoiceOver, con el
  texto al 200 %, con un teclado físico y con reducir movimiento. Comprueba además que el llavero de
  iOS y el gestor de contraseñas de Google ofrecen la contraseña guardada en E2, aunque el código
  vaya en E1, y que ofrecen guardarlos al entrar. Si no, se aplica la regla de «El autocompletado»
  (RF-BIEN-6).
- En el iPhone SE del dueño, con el texto al 100 %, la estrella no se mueve durante el
  recibimiento, y con el texto al 200 % nada se tapa (RF-BIEN-2).
- En Chrome, la bienvenida de web dibuja el botón oficial de Google con `continueWith`, `es`, el
  tema del sistema y el ancho del compositor, y lo vuelve a dibujar al cambiar el tema, porque
  esa llamada no tiene prueba automática (decisión B-35).
- Una grabación de pantalla a 60 fps, revisada cuadro a cuadro, comprueba que el logo no salta en
  el relevo del splash, que nada tapa la estrella mientras Ulises aterriza y que el paso al
  horario termina sin cambio al retirarse la capa. Comprueba también que en cada cuadro de la
  apertura y del cierre de `/forgot-password` y de `/reset-password` hay un sello a la vista, y
  que el sello de esas pantallas queda donde está el de la conversación (RF-BIEN-20).
- Un registro real contra el backend desplegado, con una cuenta que el dueño elija y que no esté
  en la base, hasta el horario. Lo hace el dueño con sus datos, que nunca entran al repo.
- La medición de RF-BIEN-18 en modo perfil, con tres recorridos por tramo.
