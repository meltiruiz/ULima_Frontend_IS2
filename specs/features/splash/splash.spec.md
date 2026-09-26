---
name: Splash animado
description: Splash nativo que no corta el logo y una intro animada en Flutter con tres variantes al azar, Ensamble, Incremento y Código, que corre mientras carga la app y termina en /home abierto en la pestaña Horario o, sin sesión o sin especialidad elegida, en el traspaso a la bienvenida con Ulises
targets:
  - ../../../lib/main.dart
  - ../../../lib/pages/splash/**
  - ../../../lib/components/logo/**
  - ../../../lib/services/splash_variante_service.dart
  - ../../../lib/services/session_navigation.dart
  - ../../../lib/components/header/app_header.dart
  - ../../../lib/pages/home/home_page.dart
  - ../../../pubspec.yaml
  - ../../../assets/splash/**
  - ../../../android/app/src/main/res/drawable*/**
  - ../../../android/app/src/main/res/values*/styles.xml
  - ../../../ios/Runner/Assets.xcassets/LaunchImage.imageset/**
  - ../../../ios/Runner/Assets.xcassets/LaunchBackground.imageset/**
  - ../../../ios/Runner/Base.lproj/LaunchScreen.storyboard
  - ../../../ios/Runner/Info.plist
  - ../../../web/index.html
  - ../../../web/splash/**
  - ../../../test/splash/**
  - ../../../test/components/header/app_header_test.dart
  - ../../../docs/images/UI/splash/**
  - ../../../docs/images/UI/bienvenida/**
  - ../../../README.md
---

# Splash animado

> Estado. **Aprobada por el dueño el 2026-09-26 e implementada el 2026-09-26.** La revisión
> manual de «Verificación» queda pendiente. Diseñada el
> 2026-09-25, corregida el mismo día con los hallazgos de dos revisiones y enmendada también ese
> día con dos decisiones del dueño.
> El dueño aprueba la spec con «aplica» y lo confirma como «Arranque: todas las recomendadas».
> Aprueba S-1 a S-34 en la opción que la spec toma por defecto, salvo S-29, donde elige la opción
> que cumple mejor sus pedidos de que el logo no se pierda y de ver el horario después del splash.
> El alumno con cuenta que todavía no elige su especialidad ya no va al asistente de carrera. Va a
> la conversación con Ulises, que le toma el test ahí mismo con el logo en la cabecera y después
> lo lleva a su horario (RF-SPL-12). La misma aprobación elige la opción gemela de B-10 y cambia
> B-9 en la spec de la bienvenida.
> Tres decisiones quedan explícitas en su opción por defecto. Todos los roles abren en Horario
> (S-24), el splash y la bienvenida se publican juntos (S-30) y la animación se ve siempre
> completa (S-6).
> El ajuste del 2026-09-26 por S-29 reescribe RF-SPL-12, que pasa a ser el relevo con sesión, y
> toca «Contexto», RF-SPL-4, RF-SPL-10, RF-SPL-13, RF-SPL-15, RF-SPL-17, RF-SPL-19 a RF-SPL-21, las
> filas S-6, S-9, S-10, S-22 y S-29, «Cambios en otras specs», «Qué NO entra», «Verificación» y
> los targets, de los que sale `setup_carrera_page.dart`.
> «Decisiones» reúne primero los pedidos del dueño y después cada punto, con la opción aprobada,
> en dos tablas. La primera reúne las que cambian lo que ve el alumno, que decide el dueño, y la
> segunda las técnicas, que propone el equipo.
> Las decisiones de esta spec llevan el prefijo S y las de la spec de la bienvenida, el prefijo
> B, así que S-29 y B-10 nunca se confunden aunque las dos specs numeren desde 1.
> La enmienda del 2026-09-25 suma dos requisitos. Con sesión, `/home` abre en la pestaña Horario
> (RF-SPL-20), porque el dueño quiere que quien tiene sesión vea su horario después del splash.
> Sin sesión, la intro ya no termina en la tarjeta del login. El logo se queda entero en el centro
> y la bienvenida con Ulises toma el relevo sin salto (RF-SPL-21). Esa bienvenida es la versión
> combinada de «Ulises te recibe» que el dueño elige ese día, y la describe su propia spec,
> `specs/features/bienvenida/bienvenida.spec.md`, que el dueño aprueba con esta el 2026-09-26. Su
> maqueta queda en `docs/images/UI/bienvenida/` (RF-SPL-19).
> El pedido del dueño del 2026-09-25 es reparar el splash de Android, que corta el logo, y
> volverlo animado e innovador con el logo y los «++». Se le muestran tres conceptos animados y
> responde que le gustan todos y que quiere «que se puedan randomizar siempre que la app se
> abra». Los tres son A «Ensamble», B «Incremento» y C «Código», y sus maquetas quedan en
> `docs/images/UI/splash/` (RF-SPL-19).
> La spec es propia y no una sección de `specs/features/app-shell/app-shell.spec.md`, porque el
> splash corre antes de la sesión y toca los recursos nativos, `pubspec.yaml` y el arranque de
> `main.dart`, mientras app-shell cubre el shell autenticado. Es el mismo reparto de la spec del
> chat, que vive aparte y suma a app-shell solo lo que cambia en el shell. Aquí esos cambios son
> BR-SHELL-F-04, la estrella junto a «ULIMA++», y la pestaña inicial de BR-SHELL-F-02 con su
> orientación en BR-SHELL-F-00 («Cambios en otras specs»).
> Las referencias `archivo:línea` apuntan a `41ff0a6`, la base de la rama `feat/splash-animado`, y
> siguen valiendo en `19fed1b`, el main que la rama trae el 2026-09-25, porque ninguno de esos
> archivos cambia entre los dos commits.
> Las que nombran un paquete apuntan a la versión que fija `pubspec.lock`, como get 4.7.3, y las
> del engine o de flutter_tools, al SDK de Flutter 3.47.2 instalado en la Mac del equipo.
> Los `[@test]` apuntan a la prueba que fija cada requisito, escrita con la implementación.
> Donde esta spec y las maquetas difieren, manda la spec, y `docs/images/UI/splash/README.md` lo
> dice junto a ellas. Difieren en el arranque de Ensamble (RF-SPL-7), que ya muestra
> `ensamble-adaptada.html`, en el tamaño único de la estrella del primer cuadro (RF-SPL-1) y en la
> geometría única del logo (RF-SPL-2). También difieren en el destello de Ensamble, sin
> desenfoque (RF-SPL-7), en la página de destino, que aparece entera y no por tarjetas
> escalonadas (RF-SPL-11), en el radio y la letra de Código (RF-SPL-9) y en la salida de
> Incremento, que no espera el fin de un tic (RF-SPL-10). La maqueta de la bienvenida difiere
> además en la burbuja de Ulises, que con sesión aparece con un rebote después de la salida
> (decisión S-28), y `docs/images/UI/bienvenida/README.md` lo dice junto a ella.

## User Stories

- Como alumno o docente, quiero ver el logo completo al abrir la app, sin puntas ni «++»
  cortados y sin un cuadrado de otro naranja detrás.
- Como alumno, quiero que el arranque se sienta vivo y distinto de una vez a otra, con una
  animación que no dure más de 1,8 s.
- Como persona que usa «reducir movimiento» o un lector de pantalla, quiero un arranque
  tranquilo que se anuncie una sola vez.
- Como alumno o docente con sesión, quiero ver mi horario apenas termina el arranque.
- Como alumno sin sesión, quiero que el logo se quede en pantalla y que Ulises me reciba, sin un
  corte entre el arranque y la bienvenida.
- Como alumno con cuenta que todavía no elige su especialidad, quiero que Ulises me tome el test
  sin que el logo se pierda y me lleve después a mi horario.

## Contexto

El diagnóstico del 2026-09-25 sobre `41ff0a6` es lo que motiva la spec.

- **El recorte.** `flutter_native_splash` usa `assets/images/UL_fondo_naranja_grande.png`, el
  ícono de la app de 1539 px, como `image` y como `android_12.image` (`pubspec.yaml:79-84`).
  Android 12 o superior muestra el ícono del splash en un lienzo de 288 dp y lo enmascara a un
  círculo de 192 dp de diámetro, es decir, de radio 1/3 del lado. En ese PNG los «++» llegan a
  0,47 del lado desde el centro y las puntas de la estrella a 0,37, así que el círculo corta las
  dos cosas. La captura recortada de `docs/images/UI/splash/splash-actual-recorte.jpg` lo muestra.
- **El cuadrado.** El fondo del ícono tiene textura y varía alrededor de `#E77330` (entre
  `#E4722F` y `#E77433` en una muestra de puntos), mientras el fondo del splash es `#E77330`
  plano, y el borde del ícono se nota. En Android anterior a 12 y en iOS el mismo PNG entra como
  imagen 4x y mide 385 dp, o 385 pt en iOS, más que el ancho de un teléfono de 360 dp o de un
  iPhone SE de 375 pt.
- **El arranque.** `main()` espera la orientación (`main.dart:60-62`), Firebase (`:63`),
  `StorageService` (`:67-70`), el registro de servicios (`:71-81`), `tryRestoreSession`, que
  llama a la red (`:84`), y `fetchAlerts` para alumnos, que también llama a la red (`:91-97`).
  Solo después llama a `runApp` (`:102`). Mientras tanto, el splash nativo queda quieto.
- **Las alertas se piden dos veces.** `HomeController.onInit` ya llama a `fetchAlerts` al
  montarse (`home_controller.dart:38-44`), y la campana se actualiza sola cuando llegan
  (`app_header.dart:94-98`).
- **Sin red.** `tryRestoreSession` atrapa cualquier error de `GET /auth/me` y de lo que carga
  después, también uno de red, borra la sesión y devuelve `false` (`auth_service.dart:196-215`),
  así que un arranque sin red termina hoy en `/login` y sin sesión guardada. La lectura del token
  en flutter_secure_storage va antes del `try` (`:193`), así que un error del almacén de claves
  no se atrapa y hoy deja la app sin `runApp`. Esta spec no cambia cómo se restaura la sesión
  («Qué NO entra»).
- **El 401 en el arranque.** Un 401 de esas llamadas borra la sesión en `ApiClient` y llama a
  `offAllToLogin` (`api_client.dart:143-160`), que hoy no navega porque `Get.context` es null
  antes de `runApp` (`session_navigation.dart:32-38`). Por eso hoy no hay snackbar «Sesión
  expirada» en el arranque y la ruta sale de `tryRestoreSession`.
- **La cabecera.** `AppHeader` muestra solo el texto «ULIMA++» (`app_header.dart:79-88`) y el
  `SvgPicture` de `logo.svg` está comentado (`:161-168`). Las tres maquetas terminan con la
  estrella junto a «ULIMA++».
- **La barra de estado.** Ningún archivo de `lib/` fija un `SystemUiOverlayStyle`, y Flutter
  conserva el último estilo que se aplica aunque desaparezca la región que lo pide.
- **Los destinos.** `postLoginRoute` devuelve `/home` para docentes y para alumnos con la
  configuración completa, y `/setup-carrera` para los demás (`post_login_route.dart:11-14`); sin
  sesión, la ruta es `/login` (`main.dart:98-100`). Las tres `GetPage` usan la transición por
  defecto (`main.dart:129-172`).
  - `/home` usa `AppHeader`, con fondo `headerColor`, que es `#FF6600` en claro y
    `rgb(30, 30, 36)` en oscuro (`themes.dart:21-25`), y un borde inferior de 2 dp en
    `primaryContainer` (`app_header.dart:58-65`). El docente no tiene campana y ocupa su lugar un
    espacio de 30 dp (`:149-150`).
  - `/setup-carrera` no usa `AppHeader`. Su cabecera es `_WizardHeader`, `#FF6600` en los dos
    temas, dentro de un `SafeArea` y sobre un fondo `#F7F7F8` fijo
    (`setup_carrera_page.dart:20-25` y `:47-95`), así que la franja bajo la barra de estado es
    gris claro y la cabecera naranja empieza debajo. El 2026-09-26 el dueño elige que la intro ya
    no lleve a esa pantalla (RF-SPL-12 y decisión S-29).
  - `/login` no tiene cabecera. Es una página `#FF6600` con una tarjeta blanca en claro, y
    `#262626` con una tarjeta `#050505` en oscuro (`login_page.dart:464-465` y `:485-486`). La
    tarjeta lleva el ícono de la app en 96 dp con esquinas de 22 dp (`login_page.dart:80-88`).
    El 2026-09-25 el dueño elige reemplazar esa tarjeta, como primera pantalla sin sesión, por la
    bienvenida con Ulises (RF-SPL-21).
- **La pestaña inicial.** `HomePage` abre siempre en el índice 0 (`home_page.dart:36`), que es
  Malla para el alumno y Secciones para el docente, y no lee argumentos de ruta. Ya busca la
  pestaña Horario por su etiqueta (`:42-43`), que es la tercera para el alumno y el delegado y la
  tercera o la segunda para el docente, según tenga o no la pestaña Calificar
  (`home_shell_config.dart:33-78`). Al montarse pide sus orientaciones, que en Horario incluyen
  las horizontales (`home_page.dart:56-66`), y en Horario horizontal oculta la cabecera y el
  footer (`:109-118` y `:138`).

## Requisitos

Dos medidas se repiten. **u** es la unidad de `assets/images/Universidad_de_Lima_logo.svg`, cuya
estrella tiene centro (590,2; 394,3) y radio nominal de 354,8 u hasta la punta. **R** es ese radio
en el primer cuadro, 90 dp, así que una unidad mide R/354,8 dp. Los tiempos se cuentan desde que
la intro empieza a moverse (RF-SPL-6).

### RF-SPL-1. El splash nativo no corta el logo

- Un solo splash nativo para las tres variantes, porque el nativo es una imagen estática que
  queda definida al compilar. Muestra la estrella completa, blanca y sin «++», centrada, sobre
  `#E77330` plano de borde a borde (decisión S-1).
- La imagen es `assets/splash/splash_estrella.png`, de 1152 × 1152 px, con fondo transparente y la
  estrella dibujada desde la geometría de RF-SPL-2 con R = 360 px. Como `flutter_native_splash`
  la toma como 4x, mide 288 dp y la estrella llega a R = 90 dp. Con el retraimiento de la
  rendija, las puntas quedan a 88,5 dp del centro, dentro del círculo de 96 dp de radio que
  Android 12 o superior deja ver.
- `pubspec.yaml` apunta `image` y `android_12.image` a esa imagen y deja `color` y
  `android_12.color` en `#E77330`, sin `icon_background_color` ni variantes oscuras
  (decisión S-2). El mismo PNG sirve en Android 12 o superior, en Android anterior, en iOS y en
  web, y en los temas claro y oscuro.
- `assets/splash/` no entra en los assets de Flutter (`pubspec.yaml:106-107` solo declara
  `assets/images/`), así que la imagen no se empaqueta dos veces.
- El ícono del launcher no cambia y sigue en `UL_fondo_naranja_grande.png`
  (`pubspec.yaml:68-74`), igual que el logo de la tarjeta del login.
- Los recursos nativos se regeneran con `dart run flutter_native_splash:create`.

`[@test] ../../../test/splash/splash_png_nativo_test.dart`

### RF-SPL-2. Una sola geometría del logo

- Un solo archivo Dart en `lib/components/logo/` guarda la geometría. La usan la intro, la
  estrella de la cabecera (BR-SHELL-F-04 de app-shell) y la generación del PNG (RF-SPL-3).
- Los ocho rombos son los polígonos de `Universidad_de_Lima_logo.svg` y la estrella central es el
  polígono de 16 vértices que forman sus vértices interiores. Cada polígono se retrae 3,5 u, lo
  que deja la rendija naranja de 7 u que tiene el ícono. Los polígonos retraídos son los de
  `docs/images/UI/splash/ensamble.html`.
- La silueta sin retraer, que es la unión de los polígonos originales del SVG, recorta el
  destello de Ensamble (RF-SPL-7).
- Cada «+» es una cruz de 72,8 u de punta a punta y 17,4 u de grosor, medida en el ícono. Sus
  centros están a (308,7; −133,8) u y (402,5; −133,8) u del centro de la estrella, arriba a la
  derecha, como en el ícono.
- Los caminos se construyen una sola vez y no en cada cuadro.

`[@test] ../../../test/splash/splash_geometria_test.dart`

### RF-SPL-3. Cómo se genera el PNG del splash

- El PNG lo escribe una prueba de golden que pinta la estrella con la geometría de RF-SPL-2 sobre
  un lienzo transparente de 1152 × 1152 px (decisión S-16). Se genera con
  `flutter test --update-goldens test/splash/splash_png_nativo_test.dart` y después con
  `dart run flutter_native_splash:create`.
- La misma prueba, sin la bandera, comprueba que el PNG del repo coincide con la geometría, que
  mide 1152 × 1152 px, que sus esquinas son transparentes y que ningún píxel blanco queda a más de
  384 px del centro.
- La comparación con la geometría usa un comparador con la tolerancia de RF-SPL-5 y no la
  comparación exacta de `matchesGoldenFile`, porque el antialiasing cambia entre macOS y Linux.
  La CI de hoy (`.github/workflows/build-apk.yml`) no corre pruebas, así que la prueba corre en
  la Mac del equipo, igual que el resto de la suite.
- No se agrega ningún paquete ni herramienta fuera del SDK de Flutter.

`[@test] ../../../test/splash/splash_png_nativo_test.dart`

### RF-SPL-4. `runApp` inmediato y la carga en paralelo

- `main()` llama a `runApp` justo después de `WidgetsFlutterBinding.ensureInitialized` y del
  bloqueo en vertical, que hoy ya van primero (`main.dart:59-62`). En web no hay intro y `main()`
  conserva el orden de hoy (decisión S-22), porque `WidgetsApp` usa la ruta de la URL antes que
  `initialRoute` y una recarga en `/#/home` construiría `HomePage`, con `AuthService.to` en sus
  campos, antes de que existan los servicios. El único cambio en web es la ruta inicial del alumno
  sin especialidad, que pasa de `/setup-carrera` a `/login` (RF-SPL-12).
- La carga pasa a una función que devuelve la ruta de destino y corre en paralelo con la intro.
  Da los mismos pasos que hoy y en el mismo orden, con Firebase (`main.dart:63`), la línea de
  `LucideIcons` (`:64`), `StorageService` (`:67-70`), el registro de los servicios permanentes
  (`:71-81`), `tryRestoreSession` (`:84`) y la ruta de `postLoginRoute` o `/login`
  (`:85-100`). Solo cambian las alertas del punto siguiente.
- Por defecto, `fetchAlerts` sale de la carga (`main.dart:91-97`), porque `HomeController` ya
  la pide al montarse y la campana se actualiza sola (decisión S-7).
- La intro recibe la carga inyectada, como una `Future<String> Function()`, igual que recibe el
  `Random` (RF-SPL-6). Así las pruebas la reemplazan sin llamar a `Firebase.initializeApp` ni a
  flutter_secure_storage.
- `GetMaterialApp` arranca en `/arranque`, una página vacía de color `#E77330`. Su `builder`
  pone la capa de la intro encima del `Navigator`.
- **La capa es permanente.** La capa es una pieza fija del `builder`, montada en todas las
  plataformas, también en web, donde no hay intro y queda inactiva desde el principio. En esta
  spec, que la capa se retire quiere decir que queda inactiva, sin pintar nada, sin bloquear
  toques y fuera de la semántica, y no que se desmonte. Por defecto atiende a dos clientes
  (decisión B-33 de la bienvenida).
  - **La intro**, con todo lo que dice esta spec.
  - **El paso al horario de la bienvenida** (RF-BIEN-11), que la usa porque la página de la
    bienvenida sale del árbol con `Get.offAll` y la capa no. Tiene una entrada propia por la que
    la bienvenida le entrega lo que dibuja, que son la franja, el sello, a Ulises y una imagen de
    la conversación. Con ella, la capa mide la cabecera y `ChatbotBubble` como en RF-SPL-11,
    bloquea los toques, lleva la semántica «ULIMA++» sin «cargando» (RF-SPL-15) y avisa a
    `HomePage` cuando se retira, para que Horario pida sus orientaciones (RF-SPL-20). Cuando
    mide `ChatbotBubble`, le dice si hay un aterrizaje de Ulises en curso, lo que solo pasa en
    este paso, y la intro nunca se lo dice (decisiones S-28 y B-16).
- El estado de la capa vive en el `State` de su widget y no en un `GetxController` registrado
  con `Get.put` mientras la ruta actual es `/arranque`. GetX liga esa instancia a la ruta y la
  borra cuando la navegación retira `/arranque`, en plena salida (`get_instance.dart:199-210` y
  `router_report.dart` de get 4.7.3). Los servicios permanentes que registra la carga también
  quedan ligados a `/arranque`, y al retirarla GetX se niega a borrarlos y solo deja un aviso en
  el registro, que es esperado.
- Cuando terminan la entrada de la variante y la carga, la capa navega sin transición, espera el
  primer cuadro de la página ya montada debajo, mide la cabecera de destino (RF-SPL-11) y
  reproduce la salida. Al terminar, la capa se retira y la página queda tal cual. Hacia la
  bienvenida no hay salida, y la capa se retira en cuanto la bienvenida pinta su primer cuadro
  (RF-SPL-21).
- **Navegación sin transición.** En get 4.7.3, `Get.offAllNamed` no acepta transición
  (`extension_navigation.dart:778-792`), y como las `GetPage` de los dos destinos, `/home` y
  `/login`, no fijan ninguna, correría la transición por defecto de 300 ms del
  `PageTransitionsTheme` (`get_transition_mixin.dart`, caso `default`), que en iOS es un
  deslizamiento lateral. En el primer cuadro la página estaría transformada y la capa mediría
  posiciones erradas. Por eso la intro navega con `Get.offAll`, con el `page` y el `binding` de la
  misma `GetPage` del destino, `routeName` igual a la ruta, `Transition.noTransition` y
  `opaque: true` (decisión S-19). Lleva además el argumento de ruta de cada destino, que es la
  pestaña de `/home` (RF-SPL-20) o la pose del logo para la bienvenida (RF-SPL-21). `Get.offAll`
  acepta `arguments` y los guarda en el `RouteSettings` de la ruta
  (`extension_navigation.dart:957-990` de get 4.7.3). Las `GetPage` se declaran una sola vez en
  `main.dart` y la intro las toma de ahí, así que el binding no se duplica. `Get.currentRoute` queda
  en el nombre de la ruta, como hoy, y el login, el logout y el resto de la navegación conservan su
  transición.
- **La bienvenida siempre por `offAllToLogin`.** Sin sesión, y con la sesión de un alumno sin
  especialidad (RF-SPL-12), la intro navega a la bienvenida, que ocupa la ruta `/login` (decisión
  S-32), por `offAllToLogin` de `session_navigation.dart`. Esa función suma la opción de navegar sin
  transición de la misma manera y con el argumento de la pose (RF-SPL-21). La intro nunca navega con
  `Get.offAllNamed('/login')` directo, como pide ese archivo (`session_navigation.dart:4-19`).
- **Un 401 durante la carga.** Con `runApp` inmediato, `/arranque` ya está montada, así que un
  401 de `GET /auth/me` o de los catálogos dentro de `tryRestoreSession`, que no usa
  `suppressSessionExpiry` (`auth_service.dart:197` y `:430-446`), navegaría a `/login` bajo la
  capa y mostraría el snackbar «Sesión expirada», que seguiría visible tras la salida. Después la
  intro navegaría otra vez a `/login`, que es la doble ruta que prohíbe
  `session_navigation.dart:4-19`. Para que el arranque siga igual que hoy, `offAllToLogin` no
  navega y devuelve `false` mientras la ruta actual es `/arranque`, salvo cuando la llama la
  intro (decisión S-20). Así el interceptor de `api_client.dart:143-160` borra la sesión como hoy,
  no muestra el snackbar, `tryRestoreSession` devuelve `false` y la intro navega una sola vez a
  la bienvenida.
- Si la ruta de debajo cambia durante la salida, por ejemplo por un 401 de las peticiones que la
  página de destino hace al montarse, la capa deja la salida y termina con el fundido de 300 ms
  de RF-SPL-11.
- Mientras la capa cubre la pantalla, ningún toque llega a la página de debajo.
- **La barra de estado.** Mientras la capa cubre la pantalla, la barra de estado usa íconos
  claros sobre el naranja. Como Flutter conserva el último estilo, cada destino declara el suyo
  con un `AnnotatedRegion<SystemUiOverlayStyle>` en su raíz, que rige desde que la capa se
  retira y también cuando se llega por otro camino. `AppHeader`, y con ella `/home`, usa íconos
  claros en los dos temas, y la bienvenida declara el suyo según su spec (RF-SPL-21). La intro ya
  no llega a `/setup-carrera` (RF-SPL-12), así que esa pantalla no declara nada con esta spec.
- El destino se decide igual que hoy, con tres cambios. `/home` abre en la pestaña Horario
  (RF-SPL-20), sin sesión la bienvenida con Ulises toma el lugar de la tarjeta del login
  (RF-SPL-21) y el alumno con sesión y sin especialidad va también a la bienvenida, donde Ulises
  le toma el test, en lugar del asistente de carrera (RF-SPL-12). Un docente o un alumno con la
  configuración completa nunca ve la bienvenida un instante.

`[@test] ../../../test/splash/splash_arranque_test.dart`

### RF-SPL-5. El primer cuadro es idéntico al splash nativo

- El primer cuadro de Flutter pinta `#E77330` de borde a borde y la estrella de RF-SPL-1, con R =
  90 dp, sin «++» y sin giro.
- **El centro.** La spec toma como centro del nativo el de la pantalla física, porque el splash
  se dibuja en la ventana completa, y la grabación lo confirma. En Android 15 o superior con
  targetSdk 36, que Flutter fija por defecto (`FlutterExtension.kt:34` de flutter_tools), el
  sistema fuerza el modo de borde a borde, la vista de Flutter cubre la pantalla entera y su
  centro es el mismo. En iOS pasa igual. En Android 12 a 14, Flutter solo pone
  `LAYOUT_STABLE | LAYOUT_FULLSCREEN` (`PlatformPlugin.java:38-39` del engine), así que la vista
  arranca bajo la barra de estado pero termina sobre la barra de navegación, y con tres botones su
  centro queda más arriba que el de la pantalla. En ese caso `viewPadding.bottom` vale 0 y no
  sirve para medir la barra. Por eso la intro centra la estrella en la mitad del alto de la
  pantalla física, `View.of(context).display.size` dividido por `devicePixelRatio` y medido desde
  el borde superior de la vista, y no en la mitad de la vista (decisión S-21). Donde la vista cubre
  la pantalla, las dos medidas coinciden y no hay corrección.
- Si la grabación de «Verificación» muestra que el nativo de Android 12 a 14 no se centra en la
  pantalla física, la implementación se detiene y el cambio vuelve a esta spec antes de
  corregirlo.
- Las tres variantes arrancan de ese mismo cuadro, así que el primer cuadro no depende de la
  variante.
- **Guarda de regresión.** Una prueba compara el primer cuadro, pintado a 4x, con
  `assets/splash/splash_estrella.png` compuesto sobre `#E77330`, con una tolerancia para el
  antialiasing (decisión S-18). Como el PNG sale del mismo painter (RF-SPL-3), la prueba solo
  detecta que la estrella de uno cambie sin la del otro. La equivalencia real, con el centrado de
  la ventana frente a la vista y el remuestreo por densidad, la comprueba la grabación.

`[@test] ../../../test/splash/splash_primer_cuadro_test.dart`

### RF-SPL-6. Una variante al azar en cada arranque en frío

- Hay intro en cada arranque en frío, es decir, cada vez que corre `main()`. Al volver de segundo
  plano con la app viva no corre `main()` y no hay intro, y si el sistema cierra la app en
  segundo plano, la siguiente apertura es en frío y sí la tiene (decisión S-5).
- Hasta Android 15, salir con el botón atrás desde la primera pantalla cierra la actividad y la
  siguiente apertura tiene intro. En Android 16 con targetSdk 36 el atrás predictivo viene
  activo, Flutter no registra `OnBackInvokedCallback` en la ruta raíz
  (`FlutterActivity.java:730-735` del engine) y el sistema manda la tarea al fondo sin terminarla,
  así que al reabrir no corre `main()` y no hay intro.
- La variante sale al azar con probabilidad pareja y sin repetir la del arranque anterior
  (decisión S-4). Con una última variante guardada, sale una de las otras dos con probabilidad 1/2
  cada una. Sin una última válida (la primera vez, un valor desconocido o un error al leer), sale
  una de las tres con probabilidad 1/3. A la larga, cada variante sale en un tercio de los
  arranques.
- La elección es una función pura que recibe la última variante y un `Random`, que las pruebas
  inyectan.
- La última variante se guarda en `shared_preferences` con la clave `splash_ultima_variante` y
  los valores `ensamble`, `incremento` o `codigo`. Es una preferencia de interfaz y no un dato
  académico. Se escribe apenas se elige, y el cierre de sesión no la borra, porque
  `clearSession` solo quita las claves de la sesión (`storage_service.dart:206-218`).
- El servicio de `lib/services/splash_variante_service.dart` lee y escribe la clave, porque los
  widgets no tocan el almacenamiento. Lo hace con su propia instancia de `SharedPreferences` y no
  por `StorageService.to`, que la carga registra después de `Firebase.initializeApp`, así que la
  lectura no espera a la carga.
- Hasta que la variante está elegida, la estrella queda quieta, igual que en el primer cuadro, y
  en ese momento empieza a correr el tiempo de la intro. Si la lectura falla, la variante sale
  entre las tres y no se guarda.

`[@test] ../../../test/splash/splash_seleccion_test.dart`

### RF-SPL-7. Variante A, «Ensamble»

La maqueta de referencia es `docs/images/UI/splash/ensamble-adaptada.html`, que parte del nativo
de RF-SPL-1. `ensamble.html` conserva el concepto que ve el dueño, que arranca desde la estrella
central sola. Por la decisión S-3, Ensamble arranca desde la estrella completa del nativo. Los
rombos se abren juntos, así que el logo queda desarmado, y vuelven a encajar uno a uno en sentido
horario con el paso de 50 ms y el rebote de la maqueta original. El logo se arma frente al alumno
y desde ahí sigue la maqueta.

| Fase | Tiempo (ms) | Qué pasa | Curva |
| --- | --- | --- | --- |
| Quieta | 0 a 80 | La estrella completa, igual al nativo | Ninguna |
| Apertura | 80 a 260 | Los ocho rombos se abren a la vez. Cada uno se aleja 200 u del centro, gira −60° alrededor del centro y baja a escala 0,6 y opacidad 0,4, así que el logo queda desarmado alrededor de la estrella central | easeOutCubic |
| Encaje | Rombo k (k = 0 arriba y luego en sentido horario) desde 260 + 50·k y durante 264 ms, hasta 874 el último | Vuelve a su lugar, con el giro de vuelta a 0°, la escala a 1 y la opacidad a 1 en los primeros 50 ms | Desplazamiento con easeOutBack (s = 1,25); giro y escala con easeOutCubic |
| Compresión | 119 ms después del inicio de cada encaje | La estrella central se contrae hasta 2,2 % y vuelve | Seno de 190 ms |
| Destello | 720 a 1080 | Una banda blanca con degradado cruza el logo en diagonal. Va recortada a la silueta del logo con los polígonos sin retraer (RF-SPL-2) y se dibuja detrás de los rombos y de la estrella central, así que solo asoma por las rendijas. Una banda tenue, aparte, cruza el fondo naranja. Ninguna de las dos lleva desenfoque (decisión S-17) | Seno |
| Anillo | 720 a 1260 | Un anillo blanco crece de 370 u a 640 u, con trazo de 16 u a 3 u y opacidad de 0,35 a 0 | easeOutCubic |
| Primer y segundo «+» | 860 a 1160 y 930 a 1230 | Cada cruz aparece en su lugar girando de −90° a 0° con un rebote de escala, y deja una onda de 48 u a 120 u | Giro con easeOutCubic; escala con easeOutBack (s = 2,4) |
| Fin de la entrada | 1250 | El logo completo con sus «++» | Ninguna |

La salida hacia `/home` dura 530 ms (RF-SPL-11). Si la carga sigue al terminar la entrada, una
onda recorre los rombos en sentido horario, con un período de 1100 ms y hasta 20 u hacia afuera
(RF-SPL-10).

`[@test] ../../../test/splash/splash_ensamble_test.dart`

### RF-SPL-8. Variante B, «Incremento»

La maqueta es `docs/images/UI/splash/incremento.html`, que ya arranca desde la estrella completa
con R = 90 dp.

| Fase | Tiempo (ms) | Qué pasa | Curva |
| --- | --- | --- | --- |
| Giro | 0 a 500 | La estrella gira 45° y, por su simetría de orden ocho, termina igual | `SpringSimulation` con masa 1, rigidez 246,7 y amortiguación 17,3 (ω0 = 15,7 rad/s y ζ = 0,55) |
| Latido | 180 a 560 | Los rombos salen 24 u y la estrella central baja a 95 %, con la subida en el primer 32 % | easeOutCubic al subir y easeInOutCubic al volver |
| Onda | 230 a 790 | Un anillo va de 250 u a 540 u, con trazo de 13,5 u a 1,5 u y opacidad de 0,42 a 0 | easeOutCubic |
| Primer «+» | 480 a 920 | Sale de detrás de la estrella, de x = 190 u a x = 309 u, y su escala va de 0,72 a 1. Hasta 920 ms las cruces solo se ven a la derecha de x = 236 u, así que nacen detrás del rombo derecho | easeOutBack (s = 1,6) |
| Segundo «+» | 700 a 1120 | Nace del primero, se corre 94 u y su escala va de 0,8 a 1, como `i++` | easeOutBack (s = 1,5) |
| Corrimiento | 480 a 1060 | Todo el conjunto se corre −36 u en x para quedar centrado con sus «++» | easeInOutCubic |
| Fin de la entrada | 1150 | El logo completo con sus «++» | Ninguna |

La salida hacia `/home` dura 620 ms (RF-SPL-11). Si la carga sigue, desde 1400 ms hay un tic de
45° cada 1300 ms, y la salida absorbe el tic en curso (RF-SPL-10).

`[@test] ../../../test/splash/splash_incremento_test.dart`

### RF-SPL-9. Variante C, «Código»

La maqueta es `docs/images/UI/splash/codigo.html`. En ella R mide 86 dp y aquí mide 90 dp, así
que sus medidas se escalan con R.

| Fase | Tiempo (ms) | Qué pasa | Curva |
| --- | --- | --- | --- |
| Subida | 0 a 320 | La estrella sube 0,66 R y se achica a 0,82 R | easeOutCubic |
| Cursor | Aparece de 160 a 240 y se desvanece con el texto de 790 a 960 | Un cursor sigue al texto. Avanza con cada letra y cada «+» y retrocede dos posiciones a los 780 ms, cuando los «++» saltan | Lineal |
| Tecleo | 250, 318, 386, 454 y 522 | Se escribe «ULima» en letra monoespaciada de 0,34 R, con la línea base a 0,81 R bajo el centro y el renglón «ULima++» centrado | Ninguna |
| «+» tecleados | 610 y 680 | Cada «+» aparece en `#FFE7A3` con un rebote de escala de 0,55 a 1 en 110 ms | easeOutBack |
| Vuelo de los «+» | 780 a 1160 y 830 a 1210 | Cada «+» salta en arco hacia arriba hasta su lugar junto a la estrella, gira 90°, se engruesa hasta la cruz del logo y pasa a blanco | easeInOutCubic sobre una Bézier cuadrática |
| Regreso | 820 a 1210 | La estrella vuelve al centro y a R. El texto se desvanece y baja 0,12 R entre 790 y 960 | easeInOutCubic |
| Aterrizaje | 150 ms desde que llega cada «+» | Rebote de escala de 12 % | Seno |
| Pulso | 1210 a 1330 | La estrella late 3,5 % cuando el segundo «+» ya está en su lugar | Seno |
| Anillo | 1190 a 1410 | Un anillo sale de 1,02 R a 1,5 R con opacidad de 0,38 a 0. Si la salida empieza a los 1330 ms, el anillo sigue en el centro de la pantalla mientras la estrella vuela y se apaga a los 1410 ms | easeOutCubic |
| Fin de la entrada | 1330 | El logo completo con sus «++» | Ninguna |

- La letra monoespaciada es la del sistema, `monospace` en Android y `Menlo` en iOS, sin archivos
  de fuente nuevos (decisión S-15). El texto no escala con el tamaño de letra del sistema, porque
  es parte del dibujo.
- La salida hacia `/home` dura 420 ms (RF-SPL-11). Si la carga sigue, un cursor parpadea junto a
  los «++» (RF-SPL-10).

`[@test] ../../../test/splash/splash_codigo_test.dart`

### RF-SPL-10. La espera en bucle si la carga tarda

- Si la carga termina antes que la entrada, la salida empieza al terminar la entrada. Si no, la
  variante repite su bucle hasta que la carga termina, y la salida empieza en ese momento, en las
  tres variantes.
- Sin sesión, o con la sesión de un alumno sin especialidad, no hay salida. El traspaso a la
  bienvenida ocurre en esos mismos momentos, salvo que la carga termine durante el bucle, porque
  entonces el bucle vuelve antes al reposo (RF-SPL-12 y RF-SPL-21).
- **A.** Una onda recorre los rombos en sentido horario, con un período de 1100 ms y hasta 20 u
  hacia afuera (forma de seno a la sexta). Entra en 300 ms y se apaga en el primer tercio de la
  salida.
- **B.** Desde 1400 ms y cada 1300 ms, la estrella da un tic de 45° con un resorte de rigidez 158
  y amortiguación 18,1. Con cada tic, los rombos laten 8 u durante 420 ms, con forma de seno, y
  cada «+» asiente con un 14 % de escala en 320 ms, el primero 60 ms después del inicio del tic y
  el segundo 110 ms después del primero.
- La salida de B puede empezar a mitad de un tic y lo absorbe. Su giro parte del ángulo de ese
  momento y termina 45° más allá del destino del tic, que por la simetría de orden ocho se ve
  igual, y el latido y el asentimiento que falten se apagan en los primeros 150 ms de la salida.
  Así B no suma espera después de la carga. La maqueta todavía espera 700 ms desde el inicio del
  tic, y en eso manda la spec.
- **C.** Un cursor parpadea a la derecha de los «++». Entra en 200 ms y después sigue un coseno
  de 1060 ms. Cuando la carga termina, se apaga en 120 ms mientras empieza la salida.
- El bucle no tiene tope propio (decisión S-8). Sigue mientras la carga siga, como hoy sigue el
  splash nativo quieto.

`[@test] ../../../test/splash/splash_arranque_test.dart`

### RF-SPL-11. La salida hacia `/home`, con cabecera

Vale para el alumno y para el docente, cuyo `/home` usa la misma cabecera sin campana. La página
que aparece debajo es la pestaña Horario (RF-SPL-20), y la salida no cambia por eso, porque la
cabecera es la misma en todas las pestañas (BR-SHELL-F-03 de app-shell).

- **Lo común.** El panel naranja se recoge desde la pantalla completa hasta el rectángulo de la
  cabecera, borde inferior incluido, y su color va de `#E77330` a `headerColor` del tema. La
  estrella vuela hasta la estrella de la cabecera (BR-SHELL-F-04) y se achica a 26 dp. Los «++»
  terminan sobre los «++» del texto «ULIMA++», con un fundido cruzado en el último 25 % de la
  salida, porque la cruz dibujada y el glifo de la fuente no son idénticos.
- La capa dibuja una réplica del texto «ULIMA» con el mismo estilo de la cabecera para revelarlo
  como pide cada variante. El estilo vive en un solo lugar de `app_header.dart`. La campana y el
  resto de la cabecera aparecen con un fundido del panel sobre la cabecera en los últimos 100 ms.
- La cabecera informa dónde quedan su estrella y su texto una vez que se dibuja, sin una
  `GlobalKey` compartida que falle si dos cabeceras conviven un instante. Como la navegación va
  sin transición (RF-SPL-4), en ese primer cuadro la página ya está en su lugar final.
- La página sube y aparece como un todo, sin animar sus partes. Detrás de ella va el color de
  fondo del tema, así que no hay destello blanco ni negro.
- **A (530 ms, easeInOutCubic).** El borde inferior del panel se curva y se abomba hasta unos 130
  dp a mitad de la salida. El logo vuela en una curva cuadrática, cada «+» vuela por su cuenta, el
  segundo un 4 % después, y se inclina hasta −12° para igualar la cursiva. «ULIMA» se revela de
  izquierda a derecha desde el 68 % de la salida. La página sube 20 dp y aparece entre el 30 % y el
  70 %.
- **B (620 ms, curva enfatizada de Material, `Cubic(0.2, 0, 0, 1)`).** La estrella vuela en un
  arco que entra a la cabecera desde abajo y gira otros 45°, más lo que falte del tic en curso
  (RF-SPL-10). Los «++» viajan pegados a la estrella hasta los 150 ms y después se sueltan hacia
  los glifos en 450 ms. El panel se recoge con las esquinas inferiores redondeadas hasta 75 dp de
  radio. La página sube 32 dp y el texto de la cabecera aparece entre el 62 % y el 95 % del vuelo.
- **C (420 ms, easeInOutCubic).** El panel se recoge con el borde recto y la estrella vuela en
  una curva de Bézier. «ULIMA» se teclea en la cabecera desde el 55 % de la salida, una letra cada
  7 %. Los «++» sueltan la estrella al 45 % y aterrizan al final de la palabra con una
  inclinación de −10°. La página sube 20 dp y aparece desde el 35 %.
- En el último cuadro de la salida la capa muestra lo mismo que la página de debajo, así que al
  retirarla la pantalla no cambia.
- Si la cabecera no se puede medir, la salida es un fundido de 300 ms.
- Sin la estrella en la cabecera (alternativa de la decisión S-11), la estrella se achica hasta la
  altura del texto y se disuelve a su izquierda.

`[@test] ../../../test/splash/splash_salida_test.dart`

### RF-SPL-12. Con sesión y sin especialidad, el relevo a la conversación con Ulises

El dueño elige el 2026-09-26 que el alumno con cuenta que todavía no elige su especialidad no vaya
al asistente de carrera. Como el alumno sin sesión, pasa a la conversación con Ulises, que le toma
el test ahí mismo con el logo en la cabecera y después lo lleva a su horario (decisión S-29, que el
dueño aprueba junto con B-10 de la bienvenida). Así se cumplen sus dos pedidos, que el logo no se
pierda y que quien tiene sesión vea su horario después del splash.

- **Quién.** El alumno con sesión y la configuración a medias, al que `postLoginRoute` manda a
  `/setup-carrera` (`post_login_route.dart:11-14`). `postLoginRoute` no cambia, así que la carga
  sigue devolviendo esa ruta y la intro la traduce en el relevo. El docente nunca llega aquí,
  porque `postLoginRoute` siempre lo manda a `/home`.
- **Sin salida.** Con esa ruta, la intro no reproduce ninguna salida. Hace el relevo de
  RF-SPL-21, igual que sin sesión, con la pose del logo como argumento, por `offAllToLogin` y sin
  transición (RF-SPL-4), y desde el bucle vuelve antes al reposo como allí (decisión S-34).
- **La sesión sigue.** El relevo no borra ni cambia la sesión y no pasa ningún argumento nuevo. La
  bienvenida reconoce la sesión al empezar su visita y sigue con Ulises y el test hasta el paso al
  horario (RF-BIEN-21, RF-BIEN-10 y RF-BIEN-11 de la bienvenida).
- **El logo no se pierde.** Como en RF-SPL-21, el logo sigue entero a la vista desde que la
  entrada muestra los «++» hasta que la bienvenida lo recibe, y desde ahí sigue en el sello hasta
  la cabecera de `/home`.
- **Web.** Sin intro (decisión S-22), `main()` conserva el orden de hoy, salvo que, cuando
  `postLoginRoute` da `/setup-carrera`, la ruta inicial es `/login`. La bienvenida arranca sin
  pose y reconoce la sesión igual (RF-BIEN-3 y RF-BIEN-21).
- **Un 401 durante la carga.** No cambia. `tryRestoreSession` devuelve `false`, no queda sesión y
  el relevo es el de RF-SPL-21 sin sesión (RF-SPL-4).
- **Lo que sale.** La salida hacia `/setup-carrera` de la versión anterior de esta spec ya no
  existe, igual que la salida hacia `/login`. Esa salida duraba 420 ms, recogía el panel hasta la
  cabecera del asistente y desvanecía el logo junto al ícono del saludo. `setup_carrera_page.dart`
  sale de los targets, y `/setup-carrera` sigue registrada en `main.dart` sin llegadas desde el
  arranque («Qué NO entra»).

`[@test] ../../../test/splash/splash_traspaso_test.dart`

### RF-SPL-13. Modo oscuro

- El splash nativo y la entrada no cambian en oscuro y siguen en `#E77330` (decisión S-2).
- La salida hacia `/home` funde el panel al `headerColor` de cada tema, que es `rgb(30, 30, 36)`
  en la cabecera oscura.
- Sin sesión, o con la sesión de un alumno sin especialidad, el traspaso es igual en los dos
  temas, con `#E77330` y el logo blanco, y el paso a los colores del tema oscuro es de la
  bienvenida (RF-SPL-12 y RF-SPL-21).
- En `/home` oscuro, el borde inferior de 2 dp de la cabecera, en `primaryContainer`, aparece con
  el fundido final de RF-SPL-11.
- La estrella y los «++» siguen blancos, que es el color del texto de la cabecera en los dos
  temas.
- Con la alternativa de la decisión S-2, el nativo y la entrada van sobre fondo oscuro en el tema
  oscuro, con su propia imagen nativa, y esta regla se reescribe antes de implementar.

`[@test] ../../../test/splash/splash_salida_test.dart`

### RF-SPL-14. Reducir movimiento

- Con `MediaQuery.disableAnimationsOf(context)` en `true`, que Flutter toma de «Quitar
  animaciones» en Android y de «Reducir movimiento» en iOS, no hay variante (decisión S-12). No se
  lee ni se escribe `splash_ultima_variante`.
- La estrella queda fija en el centro. Los «++» aparecen en su lugar con un fundido de 200 ms, sin
  desplazamiento.
- Cuando la carga termina, la intro navega sin transición (RF-SPL-4) y la capa se desvanece en
  250 ms sobre la página de destino, que ya está montada debajo.
- Hacia la bienvenida, la estrella queda en el centro con sus «++» en su lugar, y la capa se
  retira sin fundido, porque el primer cuadro de la bienvenida ya es igual al suyo
  (RF-SPL-21). Lo que sigue con reducir movimiento lo fija la spec de la bienvenida.
- Nada se mueve, gira ni cambia de escala en ningún momento.

`[@test] ../../../test/splash/splash_reducir_movimiento_test.dart`

### RF-SPL-15. Accesibilidad

- Durante la intro, la capa es un solo nodo de semántica con la etiqueta fija «ULIMA++, cargando»
  (decisión S-13). En el paso al horario de la bienvenida, su etiqueta es «ULIMA++», sin
  «cargando», también fija y sin región viva (RF-BIEN-16). Inactiva, queda fuera de la
  semántica.
  El dibujo queda fuera de la semántica, y el texto de Código también, porque es decorativo.
- La etiqueta no cambia durante la intro ni durante la espera, y la capa no es una región viva ni
  llama a `SemanticsService.announce`, así que el lector la anuncia una sola vez y no anuncia cada
  cuadro.
- Mientras la capa está encima, el lector no ve la página de debajo. Al retirarse la capa, el
  lector pasa a la página de destino, que sin sesión, o con la sesión de un alumno sin
  especialidad, es la bienvenida.

`[@test] ../../../test/splash/splash_accesibilidad_test.dart`

### RF-SPL-16. Háptica

- Por defecto no hay háptica (decisión S-14). La intro no responde a ningún toque, y una vibración
  que no acompaña un gesto de la persona, en cada arranque en frío y varias veces al día, deja de
  informar y pasa a molestar.
- Si el dueño la enciende, suena un `HapticFeedback.selectionClick()` cuando cada «+» llega por
  primera vez a su tamaño y a su lugar finales, y nunca con reducir movimiento. En Ensamble es
  cuando la escala de cada cruz llega a 1, hacia los 950 y 1020 ms. En Incremento es cuando cada
  «+» llega a su lugar, hacia los 650 y 870 ms. En Código es cuando cada «+» aterriza junto a la
  estrella, a los 1160 y 1210 ms.

`[@test] ../../../test/splash/splash_arranque_test.dart`

### RF-SPL-17. Rendimiento y tiempo hasta la app lista

- Sin paquetes nuevos. La intro usa solo el SDK, con `CustomPainter`, `AnimationController`,
  `SpringSimulation`, `Curves` y `TextPainter`. `flutter_native_splash` sigue en
  `dev_dependencies`.
- El dibujo se repinta con el `repaint` del controlador, sin reconstruir widgets en cada cuadro.
  El destello de Ensamble es un degradado recortado a la silueta del logo y no un desenfoque
  (decisión S-17), y la opacidad sobre la página solo se usa durante la salida.
- **Duración.** Con una carga más corta que la entrada, la animación completa dura 1,8 s o menos.
  Las entradas duran 1250, 1150 y 1330 ms y las salidas hacia `/home` 530, 620 y 420 ms, para
  totales de 1780, 1770 y 1750 ms. Sin sesión, o con la sesión de un alumno sin especialidad, no
  hay salida, y la bienvenida toma el relevo al terminar la entrada, a los 1250, 1150 y 1330 ms,
  más el primer cuadro de la bienvenida (RF-SPL-12 y RF-SPL-21).
- **Fluidez.** Se mide en modo perfil con la línea de tiempo de DevTools, en un Android de gama de
  entrada con pantalla de 60 Hz y en el iPhone SE del dueño, con tres arranques en frío por
  variante (decisión S-17). Dos cuadros quedan fuera de la medida, porque su costo no depende de la
  intro. Uno es el primero después de `runApp`, que construye `GetMaterialApp` y el tema. El otro
  es el que construye la página de destino bajo la capa, como `HomePage` con
  `Get.put(HomeController())`, sus pestañas y la cabecera (`home_page.dart:33-34`), que abierta en
  Horario construye además `HorarioPage` y su controlador (RF-SPL-20). Ese cuadro ocurre siempre
  entre el fin de la entrada y el inicio de la salida, con el logo quieto o en su bucle de
  espera, y nunca durante la entrada ni la salida. Hacia la bienvenida, el cuadro que la
  construye queda fuera por la misma razón, y lo que sigue lo mide su spec.
- La respuesta del horario puede llegar durante la salida hacia `/home` y reconstruir la página
  bajo la capa. Ese cuadro sí entra en la medida (decisión S-27).
- Fuera de esos dos cuadros, en cada arranque a lo sumo un cuadro pasa de 16,7 ms en el hilo de
  UI o en el de raster, y ninguno pasa de 33,4 ms. El hilo de UI incluye el trabajo Dart de la
  carga, que corre en el mismo isolate, y desde Flutter 3.29 es el mismo hilo de la plataforma. En
  pantallas de 90 o 120 Hz la intro sigue el refresco y el límite es el de su cuadro.
- **Tiempo hasta la app lista.** La app queda lista cuando la capa se retira. Con E la entrada,
  C la carga, P el primer cuadro de la página de destino, que la capa espera antes de medir
  (RF-SPL-4), y S la salida, eso ocurre en máx(E, C) + P + S desde el primer cuadro de Flutter.
  Hacia la bienvenida no hay S, así que el relevo ocurre en máx(E, C) + P. Hoy la app queda
  lista en C + A + P desde que corre `main()`, donde A son las alertas del alumno, y el primer
  cuadro de Flutter llega recién ahí. Hacia `/home`, ninguna variante suma espera después de la
  carga, porque la salida de Incremento absorbe el tic en curso
  (RF-SPL-10). Hacia la bienvenida, si la carga termina durante el bucle, su vuelta al reposo
  suma a lo sumo 300 ms en Ensamble, 700 ms en Incremento y 120 ms en Código (decisión S-34).
- Con la intro el arranque se ve antes, porque el primer cuadro ya no espera la carga, pero la app
  queda lista más tarde que hoy en casi todos los casos. Las diferencias por destino son
  estimaciones que la medición de «Verificación» confirma.
  - La bienvenida sin sesión guardada. `tryRestoreSession` vuelve sin llamar a la red
    (`auth_service.dart:193-194`), así que C es solo Firebase y el almacenamiento y hoy el login
    aparece apenas terminan. Con la intro, la bienvenida toma el relevo de 1,15 a 1,33 s después
    del primer cuadro, hasta E − C después de cuando hoy aparece el login, cerca de 1 s según lo
    que tarden Firebase y el almacenamiento. Los dos botones llegan después, cuando Ulises
    aterriza y saluda. El que vuelve puede tocar «Sí, entrar» de 3,5 a 3,7 s después del primer
    cuadro, unos 3 s más tarde que hoy la tarjeta del login (RF-BIEN-2 y decisiones S-6 y B-2).
  - `/home` del alumno con sesión. Con una carga más corta que la entrada, la app queda lista
    hasta E + S − C − A después que hoy, entre unas décimas y algo más de 1 s según lo que tarde
    la red. Con una carga más larga, queda lista S − A después, una salida menos las alertas que
    la decisión S-7 saca de la carga.
  - La bienvenida del alumno con sesión y sin especialidad. Hoy el asistente de carrera aparece en
    C + A + P, y con la intro el relevo ocurre en máx(E, C) + P, sin salida. La invitación al test
    llega después, unos 3,6 s tras el relevo más lo que tarde el contenido del test, porque antes
    Ulises aterriza y la estrella sube al sello (RF-BIEN-21 y decisión S-29).
  - `/home` del docente con sesión. Hoy no pide alertas, así que con una carga larga queda lista
    una salida después que hoy, de 420 a 620 ms, y con una corta, hasta E + S − C después.
- La animación se ve siempre completa, también cuando la carga ya está lista antes, y ningún
  toque la acorta ni la salta (decisión S-6, que el dueño confirma el 2026-09-26).

`[@test] ../../../test/splash/splash_ensamble_test.dart`
`[@test] ../../../test/splash/splash_incremento_test.dart`
`[@test] ../../../test/splash/splash_codigo_test.dart`

### RF-SPL-18. Fallos de la carga y tope de tiempo

- **Sin red.** Todo sigue como hoy. `tryRestoreSession` devuelve `false` y la ruta es la de la
  bienvenida, `/login` (`auth_service.dart:209-215` y decisión S-32), y la intro hace el
  traspaso por `offAllToLogin` al terminar su entrada (RF-SPL-21).
- **Una excepción antes de registrar los servicios.** Si fallan `Firebase.initializeApp` o
  `StorageService`, no hay una ruta segura, porque la bienvenida y el home necesitan esos
  servicios. La intro termina su entrada y queda en su bucle, como hoy queda quieto el splash
  nativo cuando `runApp` nunca llega, y el error queda en el registro con `debugPrint`.
- **Una excepción después de registrarlos.** `tryRestoreSession` atrapa los errores de
  `GET /auth/me` y de lo que carga después, pero la lectura del token en flutter_secure_storage va
  antes del `try` (`auth_service.dart:193`), así que un `PlatformException` del almacén de claves
  se propaga, y hoy deja la app sin `runApp`. Si esa u otra excepción llega a la intro después
  del registro de los servicios, la intro la registra con `debugPrint` y hace el traspaso a la
  bienvenida por `offAllToLogin`, sin borrar nada que hoy no se borre.
- **Tope.** La intro no tiene un tope de navegación propio (decisión S-8). Un tope que lleve a la
  bienvenida mientras `tryRestoreSession` sigue corriendo choca con ese método, que borra la sesión
  si falla tarde, incluso después de que la persona vuelve a entrar. Un tope real de red va en un
  cambio aparte de auth y de platform-runtime («Qué NO entra»).

`[@test] ../../../test/splash/splash_arranque_test.dart`

### RF-SPL-19. Las maquetas quedan en el repo

- `docs/images/UI/splash/` guarda las maquetas como referencia visual, con su línea de tiempo en
  milisegundos, sin datos reales. Están en el repo desde `b720d70`, como parte de esta spec, y el
  dueño las aprueba con ella el 2026-09-26 (decisión S-23).
  - `ensamble.html`, `incremento.html` y `codigo.html` son los tres conceptos. Se abren solos en un
    navegador y tienen Repetir, carga lenta y sin movimiento.
  - `ensamble-adaptada.html` es Ensamble con el arranque de RF-SPL-7, desde la estrella completa
    del nativo, el destello sin desenfoque y la página que aparece entera. Su casilla «Arranque
    alternativo» muestra la alternativa de la decisión S-3.
  - `splash-conceptos.html` es la página que ve el dueño el 2026-09-25, con los tres conceptos,
    el diagnóstico y las mejoras comunes, dentro de un marco mínimo que la abre fuera del
    compañero de brainstorming. Queda como constancia y no se corrige.
  - `splash-actual-recorte.jpg` es el centro de la captura del splash actual, sin la barra de
    estado del teléfono.
  - `README.md` dice que, donde una maqueta y esta spec difieren, manda la spec, y lista las
    diferencias.
- `docs/images/UI/bienvenida/` guarda, desde la enmienda del 2026-09-25, la maqueta que elige el
  dueño para el arranque sin sesión. Es de la spec de la bienvenida, y esta spec la toma como
  referencia de RF-SPL-20 y RF-SPL-21 (decisión S-23).
  - `ulises-te-recibe-combinada.html` es la versión combinada de «Ulises te recibe». Con sesión
    muestra la salida de cada intro hacia `/home` abierto en Horario, y sin sesión, el traspaso,
    el vuelo de Ulises y la conversación hasta el horario. Tiene los recorridos «Con sesión»,
    «Soy nuevo» y «Ya tengo cuenta», la intro al azar o elegida, Repetir, modo oscuro y reducir
    movimiento. Lee la imagen de Ulises de `assets/images/ulises_chatbot.png` con una ruta
    relativa, así que se abre desde su carpeta del repo.
  - `README.md` dice que manda la spec, lista las diferencias y deja a la spec de la bienvenida
    todo lo que pasa después del relevo.
  - La maqueta no tiene el recorrido del alumno con sesión y sin especialidad (RF-SPL-12). Su
    relevo es el de «Soy nuevo» y «Ya tengo cuenta», y lo que sigue lo fija RF-BIEN-21.
- Las tarjetas, los cursos y las aulas de las maquetas son inventados, igual que el código
  `20230001`, la alumna Valeria y el código del autenticador de la maqueta de la bienvenida.

Sin prueba automática, porque es documentación.

### RF-SPL-20. Con sesión, `/home` abre en la pestaña Horario

El dueño lo pide el 2026-09-25 con estas palabras, «Me gusta que cuando un usuario esté logueado,
luego de ver el splash dinámico, pueda ver su horario».

- **Cómo se pasa.** La intro navega a `/home` con el argumento de ruta `{'pestana': 'horario'}`,
  en el mismo `Get.offAll` de RF-SPL-4 (decisión S-31). `HomePage` lee el argumento de su propia
  ruta (`RouteSettings.arguments`) una sola vez, al montarse, y empieza en la pestaña Horario, que
  ya encuentra por su etiqueta (`home_page.dart:42-43`), en lugar del índice 0 fijo de hoy
  (`:36`). Sin argumento, o con otro valor, abre en la primera pestaña, como hoy, así que las
  demás llegadas a `/home` no cambian (decisión S-25).
- No se usa un parámetro de consulta como `/home?pestana=horario`, porque get 4.7.3 solo llena
  `Get.parameters` en la navegación por nombre (`route_middleware.dart:259`). Con `Get.offAll`,
  la consulta quedaría en el nombre de la ruta y `Get.currentRoute` dejaría de ser `/home`.
- **Los roles.** Todos los roles abren en Horario (decisión S-24, que el dueño confirma el
  2026-09-26). El alumno, el
  delegado y el subdelegado la tienen en la tercera pestaña, porque Delegado va después de Chats
  (`home_shell_config.dart:58-78`). El profesor titular la tiene en la tercera y el jefe de
  práctica en la segunda, porque sin `canGrade` no hay Calificar (`:33-54`). Como la pestaña se
  busca por su etiqueta, el mismo argumento sirve para todos, y `canGrade` ya se conoce al
  navegar, porque la carga pide las secciones del docente dentro de `tryRestoreSession`
  (`auth_service.dart:201-205`).
- **Qué llegadas lo pasan.** Lo pasan la intro, con esta spec, y la bienvenida cuando el que
  vuelve entra, cuando el nuevo termina su cuenta y su test y cuando el alumno sin especialidad
  termina su test, porque el dueño pide que todos lleguen a su horario. Lo segundo lo fija la spec
  de la bienvenida. El final del asistente de carrera (`setup_carrera_controller.dart:103` y
  RF-TEST-9 de la spec del test) sigue sin argumento y abre en la primera pestaña (decisión S-25),
  aunque la intro y la bienvenida ya no llevan a ese asistente (RF-SPL-12).
- **La orientación.** Horario permite girar (BR-SHELL-F-00 de app-shell), y hoy `HomePage` pide
  sus orientaciones al montarse (`home_page.dart:56-66`). Mientras la capa cubre la pantalla, la
  app sigue en vertical, y `HomePage` abierta en Horario pide las orientaciones de Horario recién
  cuando la capa se retira. Así la salida mide la cabecera en vertical, y un teléfono que está en
  horizontal gira con la página ya a la vista (decisión S-26). Si girara bajo la capa, `HomePage`
  ocultaría la cabecera y el footer (`:109-118` y `:138`), y la salida caería en el fundido de
  300 ms de RF-SPL-11.
- **El horario.** `HorarioPage` crea su controlador en su primer `build` (`horario.dart:1087`), así
  que el horario se pide cuando la página se monta bajo la capa, como hoy al tocar la pestaña, y
  la carga no lo espera (decisión S-27). Si la respuesta llega durante la salida, la página pasa del
  esqueleto al horario bajo la capa. Un alumno sin el ciclo cargado ve el aviso de carga sobre el
  horario vacío (`home_page.dart:119-127`), como hoy al abrir la pestaña.
- **Ulises.** La burbuja de Ulises aparece con la página, como hoy, con su latido y solo para el
  alumno (`home_page.dart:112`). La maqueta la muestra con un rebote después de la salida
  (decisión S-28, que se decide junto con B-16 de la bienvenida). La intro nunca le pide a la
  burbuja que espere a Ulises, así que aparece siempre con la página (RF-SPL-4).
- La prueba «la app abre en Malla, en vertical» de `test/HU23_jeff/chats_pestana_test.dart:463-479`
  monta `HomePage` sin argumento, así que sigue valiendo con la opción por defecto de las
  decisiones S-25 y S-31.

`[@test] ../../../test/splash/home_pestana_inicial_test.dart`

### RF-SPL-21. Sin sesión, el traspaso a la bienvenida con Ulises

El dueño elige el 2026-09-25 la versión combinada de «Ulises te recibe» para el arranque sin
sesión. Tras la intro al azar, la estrella grande con sus «++» se queda en el centro, entera y sin
nada encima, y la bienvenida con Ulises toma el relevo sin salto. Esta spec cubre solo el relevo.
Todo lo que sigue es de `specs/features/bienvenida/bienvenida.spec.md`, que el dueño aprueba con
esta el 2026-09-26. Esa bienvenida no es la del test de especialidad (RF-TEST-3). Desde esa
aprobación, el mismo relevo lleva también al alumno con sesión y sin especialidad (RF-SPL-12).

- **La ruta.** La bienvenida reemplaza a la tarjeta del login como pantalla sin sesión y ocupa
  la ruta `/login`, que conserva su nombre, porque `offAllToLogin`, el 401 del
  `ApiClient`, el cierre de sesión y el restablecimiento de contraseña navegan a ese nombre
  (`session_navigation.dart:32-38` y decisión S-32).
- **Sin salida.** Cuando terminan la entrada y la carga, el logo queda completo y quieto con sus
  «++», en la pose en que lo deja la entrada de su variante, con la estrella en el centro de la
  pantalla (RF-SPL-5) y sin nada encima. En Incremento es la pose corrida −36 u de RF-SPL-8, con
  la estrella y sus «++» centrados como conjunto.
- **Desde el bucle.** Si la carga termina durante el bucle de espera (RF-SPL-10), la variante
  vuelve antes a esa pose. Ensamble apaga su onda en 300 ms, Incremento termina el tic en curso, a
  lo sumo 700 ms desde su inicio, como la maqueta, y Código apaga su cursor en 120 ms
  (decisión S-34).
- **La pose.** La intro hace el traspaso por `offAllToLogin`, sin transición (RF-SPL-4), y le
  pasa a la bienvenida como argumento de ruta la pose del logo, que es el centro de la estrella en
  coordenadas de la vista, su radio, su giro y el centro y la escala de cada «+» (decisión S-33). No
  le pasa la variante, porque la bienvenida no la necesita.
- **Sin salto.** El primer cuadro de la bienvenida es idéntico al último de la intro, con
  `#E77330` de borde a borde y el logo blanco en esa pose, pintado con la geometría de RF-SPL-2,
  en los temas claro y oscuro. La bienvenida avisa a la capa cuando pinta ese cuadro, como la
  cabecera avisa dónde quedan su estrella y su texto (RF-SPL-11), y la capa se retira sin
  fundido, así que la pantalla no cambia.
- **El logo no se pierde.** Desde que la entrada muestra los «++», el logo sigue entero a la
  vista hasta que la bienvenida lo recibe, como pide el dueño. El splash nativo no lleva los «++»,
  porque Android los corta (decisión S-1).
- **Ulises.** Antes del traspaso, la intro precarga `assets/images/ulises_chatbot.png` con
  `precacheImage`, porque Ulises entra volando apenas la bienvenida toma el relevo.
- **Después del relevo.** En la maqueta, la estrella sigue en el centro, Ulises entra volando y
  aterriza a su lado sin taparla, el fondo pasa del `#E77330` del splash al naranja de la
  conversación, y al responder «¿Ya usas ULima++?» la estrella sube al sello junto a «ULIMA++».
  Esta spec no fija nada de eso, ni la barra de estado de la bienvenida, que declara la suya
  (RF-SPL-4).
- **Sin pose.** En web, que no tiene intro (decisión S-22), y cuando se llega a la bienvenida por un
  cierre de sesión, un 401 o un restablecimiento de contraseña, no hay pose, y la bienvenida
  arranca con su recibimiento corto o directo en «Sí, entrar» (RF-BIEN-3).
- **Orden de publicación.** El splash y la bienvenida se publican juntos, en el mismo push a
  `main`, y el splash nunca sale con el final hacia la tarjeta del login de hoy (decisión S-30,
  que el dueño confirma el 2026-09-26). La spec de la bienvenida dice lo mismo en su
  «Verificación».

`[@test] ../../../test/splash/splash_traspaso_test.dart`

## Textos nuevos

«ULIMA++, cargando» es la etiqueta de semántica de la capa (RF-SPL-15). «ULima» y los «++» de
Código son parte del dibujo y quedan fuera de la semántica (RF-SPL-9). La intro no muestra ningún
otro texto. Los textos de Ulises y de la bienvenida son de su spec (RF-SPL-21).

## Contrato que se consume

Ninguno nuevo. La carga llama a lo mismo que hoy a través de `tryRestoreSession`, con
`GET /auth/me` y, después, los catálogos del alumno o, para el docente,
`GET /official-grades/teacher/sections` (`auth_service.dart:201-205` y `:416-425`).
`GET /alerts/me` pasa de la carga al montaje del home (decisión S-7), que ya lo pide hoy. El
horario lo pide `HorarioController` cuando `/home` se monta en Horario, con las mismas llamadas de
hoy al abrir la pestaña (RF-SPL-20).

## Cambios en otras specs

- **App shell.** Suma BR-SHELL-F-04, la estrella junto a «ULIMA++» en la cabecera, que el dueño
  aprueba con esta spec el 2026-09-26 (decisión S-11). La misma regla dice que la cabecera declara
  íconos claros en la barra de estado (RF-SPL-4), que no depende de esa decisión. La enmienda del
  2026-09-25 cambia además BR-SHELL-F-02, que hoy dice que la aplicación abre en la primera
  pestaña. Sin argumento sigue así, y con el argumento de RF-SPL-20 abre en Horario (decisiones
  S-24, S-25 y S-31). BR-SHELL-F-00 suma que, abierta en Horario bajo la capa, la orientación de
  Horario rige desde que la capa se retira (decisión S-26). El dueño aprueba las dos enmiendas el
  2026-09-26. BR-SHELL-F-01 y BR-SHELL-F-03 no cambian, y el enlace de BR-SHELL-F-01 sigue siendo
  solo el texto.
- **Auth.** BR-AUTH-F-03 sigue siendo cierta, porque el arranque sigue llamando a
  `tryRestoreSession`, ahora desde la carga en paralelo. No cambia. `offAllToLogin` suma la
  guarda de `/arranque`, la navegación sin transición de la intro y el argumento de la pose
  (RF-SPL-4 y RF-SPL-21), y sus demás llamadores no cambian. La tarjeta del login deja de ser el
  destino sin sesión del splash, y el alumno con sesión y sin especialidad pasa a la bienvenida en
  lugar de `/setup-carrera` (RF-SPL-12). La enmienda de auth que trae la spec de la bienvenida,
  aprobada el 2026-09-26, recoge los dos cambios.
- **Academic profile.** Esta spec no cambia el asistente de `/setup-carrera`. Por la decisión
  S-29, la intro ya no lleva a él y no hay salida que lo mida ni barra de estado que declarar
  (RF-SPL-12). Que el asistente quede sin llegadas desde el arranque lo anota la spec de la
  bienvenida, que también deja de llevar a él («Cambios en otras specs» de esa spec).
- **Test de especialidad.** Esta spec no la cambia. El `Get.offAllNamed('/home')` de su
  RF-TEST-9 sigue sin argumento y abre en la primera pestaña (decisión S-25). La enmienda
  aprobada que trae la spec de la bienvenida anota que el alumno sin especialidad hace el test en
  la conversación y no en el asistente (RF-SPL-12 y RF-BIEN-21).
- **Schedule.** No cambia. La pestaña Horario solo pasa a ser la primera que se ve.
- **Bienvenida.** La bienvenida de `specs/features/bienvenida/bienvenida.spec.md` recibe la pose
  del logo y pinta un primer cuadro idéntico al último de la intro, avisa cuando lo pinta, declara
  su estilo de barra de estado y arranca también sin pose (RF-SPL-21, RF-BIEN-2, RF-BIEN-3 y
  RF-BIEN-17). Ocupa la ruta `/login` de la decisión S-32 y pasa el argumento de Horario al llegar a
  `/home` (RF-SPL-20 y RF-BIEN-11). Su paso al horario usa la capa de esta spec, que por eso es
  una pieza permanente del `builder` con una entrada para la bienvenida (RF-SPL-4 y decisión B-33
  de la bienvenida), y `lib/pages/splash/**` entra en los targets de esa spec. Con la sesión de
  un alumno sin especialidad, la bienvenida reconoce la sesión y le toma el test (RF-SPL-12 y
  RF-BIEN-21). El dueño aprueba juntas S-28 con B-16 y S-29 con B-10, y las dos specs se publican
  juntas (decisión S-30).
- **README.** La sección «El arranque» describe hoy doce pasos antes de `runApp`
  (`README.md:128-143`). La implementación la reescribe con el arranque nuevo.

## Qué NO entra

- Elegir o fijar una variante a mano, por ejemplo desde Perfil.
- Cambiar el ícono del launcher.
- Cambiar `tryRestoreSession`, que hoy borra la sesión ante cualquier error, también sin red
  (`auth_service.dart:209-215`), o sumar un tope de red a `ApiClient`, que hoy no tiene ninguno.
  Van en un cambio aparte de auth y de platform-runtime.
- Aislar un fallo de Firebase para que el resto de la app arranque sin él. Exige revisar antes cómo
  se comporta el chat sin Firebase (`chat_repository.dart:62-63`).
- Animar por partes el contenido de la página de destino, como las tarjetas escalonadas de las
  maquetas originales.
- Sonido.
- La intro en web (decisión S-22). En web, `main()` conserva el arranque de hoy, salvo la ruta
  inicial del alumno sin especialidad (RF-SPL-12).
- Quitar la animación de salida que Android 12 o superior puede reproducir sobre el primer cuadro,
  que exige `setOnExitAnimationListener` en `MainActivity.kt`, fuera de targets («Verificación»).
- Paquetes de animación como Lottie, Rive o `flutter_animate`.
- La bienvenida con Ulises, con su conversación y el inicio de sesión, el registro y el test
  dentro de ella, que son de su spec (RF-SPL-21).
- Cambiar la pestaña con la que abren las demás llegadas a `/home` (decisión S-25).
- Quitar la ruta `/setup-carrera` y el asistente de carrera, que quedan sin llegadas desde el
  arranque (RF-SPL-12). Van en un cambio aparte, junto con el origen `asistente` de la spec del
  test.
- Las alternativas de «Decisiones», que el dueño descarta el 2026-09-26.

## Decisiones

El dueño aprueba las 34 el 2026-09-26, S-1 a S-34, en la opción que la spec toma por defecto,
salvo S-29, donde elige la opción que hasta entonces era la alternativa. Las decisiones S-24 a
S-34 llegan con la enmienda del 2026-09-25, y la corrección de una revisión, ese mismo día, deja
las tablas en palabras llanas y enlaza las decisiones gemelas de la bienvenida.

### Aprobación del dueño del 2026-09-26

El dueño aprueba la spec con «aplica» y lo confirma como «Arranque: todas las recomendadas». En la
misma aprobación cambia dos decisiones, porque cumplen mejor lo que pidió, «que no se pierda el
logo» y «con sesión, luego del splash, ver su horario».

- **S-29, junto con B-10 de la bienvenida.** El alumno con cuenta que todavía no elige su
  especialidad no va al asistente de carrera. Va a la conversación con Ulises, que le toma el test
  ahí mismo con el logo en la cabecera y después lo lleva a su horario (RF-SPL-12 y RF-BIEN-21).
- **B-9 de la bienvenida.** «¿Olvidaste tu contraseña?» conserva las pantallas de hoy, con el sello
  del logo ULima++ y sus «++» en su cabecera, para que el logo nunca se pierda (RF-BIEN-20). Esta
  spec no cambia por esa decisión.

Tres decisiones quedan además explícitas en su opción por defecto. Todos los roles abren en
Horario (S-24), el splash y la bienvenida se publican juntos (S-30) y la animación se ve siempre
completa (S-6).

### Pedidos del dueño del 2026-09-25

La spec recoge estos pedidos del dueño, y el dueño aprueba su texto con el resto el 2026-09-26.
Con S-29 y B-9 en la opción que elige ese día, las opciones aprobadas cumplen cada pedido entero.

- Tres variantes, Ensamble adaptada, Incremento y Código, al azar en cada arranque en frío
  (RF-SPL-6 a RF-SPL-9). Con «reducir movimiento» activado en el teléfono no hay variante, y la
  estrella queda quieta (S-12).
- Con sesión, después del splash se ve el horario (RF-SPL-20), en todos los roles (S-24) y en las
  llegadas de S-25. El alumno que tiene cuenta pero todavía no elige su especialidad hace antes el
  test con Ulises y termina en su horario (S-29, que el dueño elige junto con B-10 de la
  bienvenida).
- Sin sesión, «Ulises te recibe» en su versión combinada. La estrella con sus «++» se queda entera
  en el centro, Ulises aterriza a su lado y la conversación sigue hasta el horario, sin que el
  logo se pierda en ningún momento (RF-SPL-21 y la spec de la bienvenida). El logo tampoco se deja
  de ver con el alumno sin especialidad, que sigue en la conversación con el logo en el sello (S-29
  y B-10), ni en las pantallas de «¿Olvidaste tu contraseña?», que llevan el sello en su cabecera
  (B-9 de la bienvenida).

### Para el dueño

Cambian lo que ve el alumno. La columna «Opción aprobada» dice la opción que el dueño aprueba el
2026-09-26, que en todas salvo S-29 es la que la spec toma por defecto, y «Qué ve el alumno» la
describe. Las dos primeras columnas de texto y la alternativa van en palabras llanas. Los códigos,
los archivos y los nombres de las maquetas quedan en «Dónde queda». Una decisión que el dueño
aprueba junto con otra de la spec de la bienvenida lo dice en su fila.

| # | Decisión | Opción aprobada | Qué ve el alumno | Alternativa | Dónde queda |
| --- | --- | --- | --- | --- | --- |
| S-1 | Imagen fija al tocar el ícono | La estrella completa, blanca y sin «++», sobre el mismo naranja de fondo y un poco más chica que hoy, para que Android no la corte | Ve la estrella entera, sin puntas cortadas ni un cuadrado de otro naranja. Los «++» llegan con la animación | La misma estrella algo más chica, con más aire hasta el borde del círculo que Android deja ver | RF-SPL-1 |
| S-2 | Modo oscuro | Todo el arranque en naranja en los dos temas, y al final el naranja se funde con el color oscuro de la pantalla de destino | Con el teléfono en oscuro, la apertura se ve naranja, igual que en claro, y la app aparece oscura | La imagen fija y la animación sobre fondo oscuro en el tema oscuro, con la estrella blanca | RF-SPL-1 y RF-SPL-13 |
| S-3 | Cómo empieza Ensamble | Los ocho rombos se abren juntos desde la estrella completa y vuelven a encajar uno a uno en sentido horario | La estrella se desarma y se vuelve a armar frente a él, pieza por pieza | Los rombos se apagan en su sitio y vuelven a entrar uno a uno en espiral desde afuera, como en la maqueta original | RF-SPL-7. La opción por defecto es `ensamble-adaptada.html` y la alternativa, su casilla «Arranque alternativo» |
| S-4 | Azar | Cada apertura elige una de las tres animaciones sin repetir la de la vez anterior | Nunca ve la misma dos veces seguidas, y a la larga ve las tres por igual | Cada apertura elige entre las tres, así que a veces se repite | RF-SPL-6 |
| S-5 | Cuándo hay animación | Cada vez que la app se abre desde cero | La ve al abrir la app cerrada. Al volver a la app que sigue abierta en segundo plano no la ve, salvo que el teléfono la haya cerrado en segundo plano para liberar memoria. Hasta Android 15, salir con el botón atrás cierra la app y la siguiente apertura tiene animación; desde Android 16 la app queda en segundo plano y no la tiene | También al volver a la app después de 30 minutos o más en segundo plano, sobre la pantalla en que está, lo que pide un final más para la animación | RF-SPL-6 |
| S-6 | Cuánto dura si la app carga rápido. Confirmada de forma explícita el 2026-09-26 | La animación completa siempre, cerca de 1,8 s hasta el horario, y de 1,15 a 1,33 s hasta que Ulises toma el relevo sin sesión o sin especialidad | La ve entera en cada apertura. Sin sesión guardada, Ulises toma el relevo cerca de 1 s después de cuando hoy aparece el login, y el que vuelve puede tocar «Sí, entrar» de 3,5 a 3,7 s después de abrir la app, unos 3 s más tarde que hoy la tarjeta del login (B-2). Con sesión, el horario aparece entre unas décimas y algo más de 1 s después que hoy, según la red | Un toque en la pantalla salta al final en cuanto la app termina de cargar, o una animación abreviada a unos 600 ms cuando la app ya está cargada | RF-SPL-17 y RF-BIEN-2 |
| S-7 | El número de la campana | La app entra sin esperar las alertas, y el inicio las pide al abrirse, como ya hace hoy | Entra al inicio antes, y el número de la campana puede aparecer un momento después | La app espera también las alertas, y el número está desde el primer momento, a cambio de entrar más tarde | RF-SPL-4 y RF-SPL-17 |
| S-8 | Si la carga no termina | La animación sigue en su espera hasta que la app responde | Sin red va a la conversación con Ulises, como hoy va al login. Si la red se cuelga sin fallar, ve la espera animada todo lo que dure, como hoy ve la imagen fija | A los 10 s va a la conversación con Ulises, lo que pide cambiar antes cómo se restaura la sesión para que un fallo tardío no cierre la sesión nueva | RF-SPL-10 y RF-SPL-18 |
| S-9 | Cómo termina según la pantalla | Al llegar al horario, del alumno o del docente, cada animación termina a su manera. Sin sesión, o con cuenta y sin especialidad (S-29), no hay final, porque el logo se queda y Ulises toma el relevo, como decide el dueño | Al llegar al horario, cada animación tiene su final. En los demás casos, las tres dejan el logo entero en el centro para Ulises | Un final propio de cada animación también en el asistente de carrera. Desde S-29 la animación ya no llega al asistente, así que no tiene objeto | RF-SPL-11, RF-SPL-12 y RF-SPL-21 |
| S-10 | La franja de arriba del asistente de carrera | Queda gris claro, como hoy | Nada distinto. Desde S-29 la animación ya no llega al asistente, que queda como hoy | Pintarla de naranja, para que la cabecera llegue hasta arriba | RF-SPL-12. Sin efecto en esta spec desde S-29 |
| S-11 | Estrella en la cabecera | La estrella blanca a la izquierda de «ULIMA++», como adorno | La cabecera muestra la estrella junto al nombre, y la estrella de la animación aterriza en ella | Solo el texto, como hoy, y la estrella de la animación se disuelve junto a él. Como el sello de la conversación con Ulises también termina en esta cabecera, su estrella se disuelve igual | BR-SHELL-F-04 de app-shell, RF-SPL-11, RF-SPL-21 y RF-BIEN-4 |
| S-12 | Reducir movimiento | Sin animación. La estrella queda quieta, los «++» aparecen con un fundido corto y la app aparece con otro. Sin sesión, Ulises toma el relevo sin fundido | Con «Quitar animaciones» o «Reducir movimiento» activado en el teléfono, nada se mueve ni gira | Ni siquiera fundidos, y la app aparece de golpe cuando termina de cargar | RF-SPL-14 |
| S-13 | Lector de pantalla | Anuncia «ULIMA++, cargando» una sola vez | Con TalkBack o VoiceOver oye esa frase una vez y después la pantalla de destino, sin repeticiones mientras carga | Anuncia solo «ULIMA++» | RF-SPL-15 |
| S-14 | Vibración | Sin vibración | El teléfono no vibra al abrir la app | Una vibración muy leve cuando aparece cada «+», nunca con reducir movimiento | RF-SPL-16 |
| S-15 | Letra de Código | La letra de máquina de escribir que trae el teléfono | La palabra «ULima» que se escribe en Código se ve un poco distinta en Android y en iPhone | Una letra propia, JetBrains Mono, de licencia libre, para que se vea igual en los dos | RF-SPL-9 |
| S-24 | Quién abre en Horario. Confirmada de forma explícita el 2026-09-26 | Todos los roles, alumno, delegado, subdelegado, profesor titular y jefe de práctica | Con sesión, después del splash ve su horario, sea alumno o docente | Solo los alumnos, delegados incluidos, y el docente sigue abriendo en Secciones | RF-SPL-20 |
| S-25 | Qué llegadas al inicio abren en Horario | Las que vienen de la animación y de la conversación con Ulises. Al terminar el asistente de carrera se sigue abriendo en Malla, como hoy | Ve su horario al abrir la app con sesión y al entrar o crear su cuenta con Ulises. Al terminar el asistente de carrera ve Malla | Que también abra en Horario al terminar el asistente de carrera, o cada vez que se llega al inicio | RF-SPL-20 y BR-SHELL-F-02 de app-shell. La primera alternativa cambia RF-TEST-9 de la spec del test, y la segunda, la prueba «la app abre en Malla» de `chats_pestana_test.dart` |
| S-26 | Girar el teléfono al abrir en Horario | La app sigue en vertical mientras corre el final de la animación y gira después, si el teléfono está de lado | Ve el final completo en vertical y, con el teléfono de lado, el horario gira apenas termina | Girar desde que aparece el inicio, y con el teléfono de lado el final es un fundido, sin la cabecera | RF-SPL-20 y BR-SHELL-F-00 de app-shell |
| S-27 | El horario al aparecer | La página pide el horario al aparecer, como hoy al tocar la pestaña, y la animación no lo espera | Con red lenta puede ver el esqueleto del horario un momento, durante el final de la animación o después | La animación espera también el horario, así que aparece completo, a cambio de una espera animada más larga | RF-SPL-20 y RF-SPL-17 |
| S-28 | Ulises al llegar al horario desde la animación. Aprobada junto con B-16 | Su burbuja aparece con la página, como hoy, con su latido | Ulises ya está en su esquina cuando termina la animación | Aparece con un rebote después de la animación, como en la maqueta de la bienvenida | RF-SPL-20. La alternativa cambia `chatbot_bubble.dart`, que está en los targets de la bienvenida y no en los de esta spec |
| S-29 | El alumno con cuenta que todavía no elige su especialidad, al abrir la app. Elegida por el dueño el 2026-09-26, junto con B-10 | La animación deja el logo entero en el centro, como sin sesión, y Ulises le toma el test en la conversación, con el logo en la cabecera, antes de llevarlo a su horario | Ve aterrizar a Ulises junto al logo, el logo sube a la cabecera y Ulises lo invita al test. Al terminar ve su horario, y en ningún momento deja de ver el logo | La opción por defecto anterior, que el dueño descarta. Iba al asistente de carrera de hoy, y el logo se achicaba hacia el ícono del saludo y se desvanecía | RF-SPL-12 y RF-SPL-21, y RF-BIEN-21 de la bienvenida. Es la misma opción de B-10 |
| S-30 | Orden de publicación. Confirmada de forma explícita el 2026-09-26 | El splash y la conversación con Ulises se publican juntos, en la misma actualización | Sin sesión, el arranque siempre termina en Ulises | El splash primero, con un fundido corto hacia el login de hoy mientras falte la conversación con Ulises | RF-SPL-21 y «Verificación» de la bienvenida |

### Técnicas (las propone el equipo)

No cambian lo que ve el alumno, salvo donde la columna lo dice. El dueño las aprueba el 2026-09-26
en la propuesta del equipo.

| # | Decisión | Propuesta del equipo | Alternativa | Qué ve el alumno | Dónde queda |
| --- | --- | --- | --- | --- | --- |
| S-16 | Cómo se genera el PNG del nativo | Una prueba de golden que pinta con la geometría de la app, seguida de `flutter_native_splash:create` | Un script de Python con Pillow que lee el SVG | Nada distinto | RF-SPL-3 |
| S-17 | Rendimiento y su medida | Solo el SDK; el destello de Ensamble es un degradado recortado a la silueta, sin desenfoque; la fluidez se mide en perfil, sin el primer cuadro ni el de la navegación, con a lo sumo un cuadro sobre 16,7 ms por arranque y ninguno sobre 33,4 ms | Un desenfoque en el destello, como en la maqueta original, si el perfil lo permite | El destello de Ensamble sin el halo difuso de la maqueta original | RF-SPL-7 y RF-SPL-17 |
| S-18 | Prueba del primer cuadro | Un golden contra el PNG del nativo, con tolerancia, como guarda de regresión, y la equivalencia real con la grabación | Solo la grabación | Nada distinto | RF-SPL-5 |
| S-19 | Navegar sin transición | `Get.offAll` con el `page` y el `binding` de la `GetPage` del destino, `Transition.noTransition` y el argumento de ruta del destino, solo desde la intro | `transition` en las `GetPage` de los tres destinos, que quita también la transición del login y del logout, o medir al terminar la transición de 300 ms y sumarla a la animación | Nada distinto. Con la primera alternativa, el login y el logout pierden su transición; con la segunda, la animación dura 300 ms más | RF-SPL-4 |
| S-20 | Un 401 durante la carga | `offAllToLogin` no navega mientras la ruta es `/arranque`, salvo desde la intro | Las llamadas de `tryRestoreSession` con `suppressSessionExpiry`, que cambia `auth_service.dart` y exige sumarlo a `fetchTeacherSections` | Con la sesión vencida va a la bienvenida sin el aviso «Sesión expirada», como hoy va al login | RF-SPL-4 |
| S-21 | Centro de la estrella en Android 12 a 14 | La mitad del alto de la pantalla física (`display.size`), medido desde el borde superior de la vista | Activar el modo de borde a borde en toda la app, que es un cambio global | Nada distinto. Con la alternativa, todas las pantallas llegan bajo la barra de navegación | RF-SPL-5 |
| S-22 | Web | Sin intro en web, con el arranque de hoy, así que la bienvenida arranca sin pose. Desde S-29, la ruta inicial del alumno sin especialidad pasa de `/setup-carrera` a `/login` (RF-SPL-12) | Forzar `/arranque` como ruta inicial en web, también al recargar en otra ruta | Nada en Android ni en iOS. Web no se despliega (`README.md:701`) | RF-SPL-4 |
| S-23 | Lugar de la spec y de las maquetas | Spec propia en `specs/features/splash/`, BR-SHELL-F-04 y la enmienda de BR-SHELL-F-02 en app-shell, maquetas en `docs/images/UI/splash/`, que están en el repo desde `b720d70`, y la maqueta de la bienvenida en `docs/images/UI/bienvenida/`, para la spec nueva `specs/features/bienvenida/bienvenida.spec.md` | La spec dentro de app-shell, o la maqueta de la bienvenida junto a las del splash | Nada distinto | Estado y RF-SPL-19 |
| S-31 | Cómo se pasa la pestaña | El argumento de ruta `{'pestana': 'horario'}`, que `HomePage` lee una sola vez al montarse | El parámetro `/home?pestana=horario`, que solo sirve con la navegación por nombre, o `HomePage` siempre en Horario, sin argumento | Nada distinto. Con la segunda alternativa, toda llegada al inicio abre en Horario (decisión S-25) | RF-SPL-20 |
| S-32 | Ruta de la bienvenida | `/login`, que conserva su nombre y todos sus llamadores | Una ruta nueva `/bienvenida`, con `offAllToLogin` y sus llamadores cambiados | Nada distinto | RF-SPL-4 y RF-SPL-21 |
| S-33 | Cómo recibe la bienvenida el logo | La pose como argumento de ruta, con el centro, el radio, el giro y los «+» | Las tres variantes terminan en una sola pose, sin argumento, así que Incremento deshace su corrimiento de −36 u antes del relevo | Nada distinto. Con la alternativa, en Incremento el logo se corre 36 u antes de que llegue Ulises | RF-SPL-21 |
| S-34 | Relevo desde el bucle | El bucle vuelve al reposo antes del relevo. Ensamble tarda 300 ms, Incremento termina el tic en curso, hasta 700 ms, y Código tarda 120 ms | Cortar el bucle con una vuelta al reposo de 150 ms en las tres | Con la red lenta, hasta 700 ms más de espera en Incremento antes de que llegue Ulises | RF-SPL-17 y RF-SPL-21 |

## Verificación

- Antes de aprobar, el dueño abre `docs/images/UI/splash/ensamble-adaptada.html`, con y sin
  «Arranque alternativo», para decidir la decisión S-3 sobre lo que se construye, y
  `docs/images/UI/bienvenida/ulises-te-recibe-combinada.html` para ver el horario con sesión y el
  relevo sin sesión (RF-SPL-20 y RF-SPL-21). Aprueba el 2026-09-26, y las dos maquetas siguen
  como referencia de la revisión manual.
- `dart format` sobre los archivos Dart que cambien.
- `flutter analyze --no-pub`.
- `flutter test --no-pub`, con la suite completa, porque `main.dart`, `app_header.dart`,
  `home_page.dart` y `session_navigation.dart` los usan otras features. Incluye `test/splash`,
  `test/components/header/app_header_test.dart` y `test/HU23_jeff/chats_pestana_test.dart`, que
  sigue abriendo en Malla sin argumento. `splash_arranque_test` cubre el 401 durante la carga, sin
  snackbar y con una sola navegación a la bienvenida. `home_pestana_inicial_test` cubre Horario con
  el argumento para el alumno, el delegado, el profesor titular y el jefe de práctica, la primera
  pestaña sin argumento y la orientación vertical hasta que la capa se retira.
  `splash_traspaso_test` cubre la pose que recibe la bienvenida en cada variante, sin sesión y con
  la sesión de un alumno sin especialidad, sin salida hacia el asistente y sin tocar la sesión.
  Cubre también la vuelta al reposo desde el bucle y que la capa se retira sin cambiar la pantalla y
  queda montada e inactiva, sin pintar, sin bloquear toques y fuera de la semántica, lista para el
  paso al horario de la bienvenida (RF-SPL-4).
- `flutter test --update-goldens test/splash/splash_png_nativo_test.dart` y
  `dart run flutter_native_splash:create` después de cambiar la geometría, y un `git diff` que solo
  muestre los recursos del splash.
- Una revisión manual en un Android 12 a 14 con barra de tres botones, en un Android 15 o superior,
  en un Android anterior a 12 (puede ser un emulador) y en el iPhone SE del dueño, en claro y en
  oscuro, con cada variante y con cada destino. Una grabación de pantalla a 60 fps, revisada
  cuadro a cuadro, comprueba que la estrella no salta entre el nativo y el primer cuadro de
  Flutter ni al retirarse la capa, que en el relevo a la bienvenida el logo no se mueve ni
  parpadea, también con la carga lenta, y que la barra de estado queda legible en cada destino.
- En la misma revisión, con sesión, el alumno, el delegado, el profesor titular y el jefe de
  práctica abren en Horario, con el teléfono en vertical y en horizontal, y un alumno de prueba
  con cuenta y sin especialidad pasa por el relevo a Ulises, sin ver el asistente de carrera.
- En Android 12 o superior, el sistema puede reproducir su animación de salida del splash, un
  fundido o un revelado, encima del primer cuadro de Flutter. Si la grabación la muestra, quitarla
  exige `setOnExitAnimationListener` en `MainActivity.kt`, que no está en targets, y el cambio
  vuelve a esta spec antes de tocarlo.
- iOS guarda en caché la pantalla de lanzamiento, así que antes de revisar el splash nativo en el
  iPhone SE se borra y se reinstala la app, o se reinicia el teléfono.
- La misma revisión con reducir movimiento, con TalkBack y con VoiceOver.
- La medición de RF-SPL-17 en modo perfil con la línea de tiempo. Para la fluidez, tres arranques
  en frío por variante. Para el tiempo hasta la app lista, cinco arranques en frío por destino,
  contra `main` en `41ff0a6` y con la misma red.
