// lib/services/session_navigation.dart
// Navegación idempotente hacia la pantalla de login.
//
// TODOS los caminos que terminan la sesión (logout del Perfil, interceptor
// 401 del ApiClient, éxito del reset de contraseña) deben navegar por aquí,
// nunca con Get.offAllNamed('/login') directo.
//
// Motivo: si dos de esos caminos coinciden (p. ej. el POST /auth/logout
// responde 401 y el interceptor navega mientras el handler del botón de
// logout también va a hacerlo), un doble Get.offAllNamed('/login') apila DOS
// rutas /login. El binding de la segunda ruta no re-registra el
// LoginController (GetX ignora lazyPut si la instancia de la primera ruta
// sigue registrada), así que la página visible reutiliza ese controller; al
// desecharse la primera ruta, GetX lo elimina y dispone sus
// TextEditingControllers MIENTRAS la página visible los sigue usando. En
// release un ChangeNotifier disposed deja de notificar: el campo recibe cada
// tecla pero no repinta ("tipeo fantasma") hasta que otro evento (perder el
// foco) fuerza el rebuild; en debug revienta con "A TextEditingController
// was used after being disposed".
//
// Get.currentRoute se actualiza de forma síncrona en el didPush del
// observer, por lo que la guarda no tiene ventana de carrera entre dos
// llamadas consecutivas.
//
// La intro del splash llega a la bienvenida por aquí, sin transición y con la
// pose del logo, y mientras la ruta actual es /arranque nadie más navega a
// /login (RF-SPL-4 de specs/features/splash/splash.spec.md).

import 'package:get/get.dart';

import '../components/logo/escena_del_logo.dart';

/// La página vacía en la que arranca la app mientras corre la intro
/// (RF-SPL-4).
const String rutaDelArranque = '/arranque';

/// La clave del argumento con la pose del logo que la intro pasa a la
/// bienvenida (RF-SPL-21 y decisión S-33).
const String argumentoDePose = 'pose';

/// Por qué se llega a la bienvenida (B-21). El cierre de sesión y «Volver a
/// iniciar sesión» del Perfil no pasan ninguno.
enum MotivoDeLlegada { expirada, restablecida }

/// La clave del argumento con el motivo de la llegada.
const String argumentoDeMotivo = 'motivo';

/// Navega a [ruta] sin transición, con el `page` y el `binding` de la
/// `GetPage` que registró `main.dart`, así que el binding no se duplica
/// (decisión S-19). La usan la intro del splash y el paso al horario de la
/// bienvenida. Devuelve `false` si no hay navegador o la ruta no existe.
bool offAllSinTransicion(String ruta, {Object? arguments}) {
  if (Get.context == null) return false;
  final pagina = Get.routeTree.matchRoute(ruta).route;
  if (pagina == null) return false;
  Get.offAll<void>(
    pagina.page,
    routeName: ruta,
    binding: pagina.binding,
    arguments: arguments,
    transition: Transition.noTransition,
    duration: Duration.zero,
    opaque: true,
  );
  return true;
}

/// Limpia el stack y navega a /login una sola vez.
///
/// Devuelve `true` si efectivamente navegó y `false` si no había navegador
/// montado, si /login ya es la ruta actual (incluida una navegación a /login
/// aún en transición) o si la ruta actual es /arranque y no la llama la intro.
/// Así un 401 durante la carga borra la sesión en `ApiClient` sin navegar ni
/// mostrar «Sesión expirada», y la intro navega una sola vez (decisión S-20).
///
/// Desde la intro navega sin transición y con la [pose] del logo como
/// argumento (RF-SPL-4 y RF-SPL-21). El [motivo] viaja como argumento de
/// ruta, y lo pasan el 401 del ApiClient (`expirada`) y el restablecimiento
/// de contraseña (`restablecida`) (RF-BIEN-1 y B-21). El cierre de sesión y
/// «Volver a iniciar sesión» del Perfil no pasan ninguno, y
/// `onPressed: offAllToLogin` sigue compilando porque los parámetros son
/// nombrados y opcionales.
bool offAllToLogin({
  MotivoDeLlegada? motivo,
  PoseDelLogo? pose,
  bool desdeLaIntro = false,
}) {
  if (Get.context == null) return false;
  if (Get.currentRoute == rutaDelArranque && !desdeLaIntro) return false;
  final alreadyOnLogin =
      Get.currentRoute == '/login' || Get.currentRoute == '/LoginPage';
  if (alreadyOnLogin) return false;
  final argumentos = <String, Object>{
    argumentoDePose: ?pose,
    argumentoDeMotivo: ?motivo,
  };
  if (desdeLaIntro) {
    return offAllSinTransicion(
      '/login',
      arguments: argumentos.isEmpty ? null : argumentos,
    );
  }
  Get.offAllNamed('/login', arguments: argumentos.isEmpty ? null : argumentos);
  return true;
}
