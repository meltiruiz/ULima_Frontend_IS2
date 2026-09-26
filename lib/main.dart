// TERMINAL - flutter pub get

import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';

import '/configs/themes.dart';
import '/services/auth_service.dart';
import '/services/alert_service.dart';
import 'pages/home/home_page.dart';
import 'pages/splash/arranque_page.dart';
import 'pages/splash/capa_de_arranque.dart';
import 'pages/splash/carga_del_arranque.dart';
import 'services/session_navigation.dart';
import 'services/splash_variante_service.dart';
import 'pages/teacher/teacher_home_binding.dart';
import 'pages/teacher/teacher_home_controller.dart';
import 'pages/teacher/teacher_home_page.dart';
import 'pages/teacher/teacher_sections_controller.dart';
import 'pages/teacher/create_advising_binding.dart';
import 'pages/teacher/create_advising_page.dart';
import 'pages/teacher/attendees_binding.dart';
import 'pages/teacher/attendees_page.dart';
import 'pages/teacher/teacher_grades_controller.dart';
import 'pages/teacher/teacher_grade_section_binding.dart';
import 'pages/teacher/teacher_grade_section_page.dart';
import 'pages/academic_record/academic_record_binding.dart';
import 'pages/academic_record/academic_record_page.dart';
import 'pages/mis_notas/mis_notas_binding.dart';
import 'pages/portal_sync/portal_sync_binding.dart';
import 'pages/portal_sync/portal_sync_page.dart';
import 'pages/mis_notas/mis_notas_page.dart';
import 'pages/malla/malla_controller.dart';
import 'pages/malla/malla_list_controller.dart';
import 'pages/malla/malla_page.dart';
import 'pages/bienvenida/bienvenida_page.dart';
import 'pages/login/login_binding.dart';
import 'pages/password_reset/forgot_password_controller.dart';
import 'pages/password_reset/reset_password_controller.dart';
import 'pages/password_reset/forgot_password_page.dart';
import 'pages/password_reset/reset_password_page.dart';
import 'pages/setup_carrera/setup_carrera_binding.dart';
import 'pages/setup_carrera/setup_carrera_page.dart';
import 'pages/specialty_test/specialty_test_binding.dart';
import 'pages/specialty_test/specialty_test_page.dart';
import 'pages/silabo/silabo_viewer_controller.dart';
import 'pages/silabo/silabo_viewer_page.dart';
import 'pages/chatbot/chatbot_page.dart';
import 'pages/networking/networking_binding.dart';
import 'pages/networking/networking_page.dart';
import 'pages/time_blocks/time_block_form_binding.dart';
import 'pages/time_blocks/time_block_form_page.dart';
import 'pages/time_blocks/time_block_list_binding.dart';
import 'pages/time_blocks/time_block_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
  if (kIsWeb) {
    // En web no hay intro y el arranque sigue en el orden de siempre, porque
    // una recarga en /#/home construiría HomePage antes que los servicios
    // (S-22). El único cambio es la ruta del alumno sin especialidad.
    final ruta = await cargarElArranque();
    final user = AuthService.to.currentUser;
    if (user != null && !user.isTeacher) {
      try {
        await AlertService.to.fetchAlerts();
      } catch (e) {
        debugPrint('Error loading alerts at startup: $e');
      }
    }
    runApp(MyApp(initialRoute: rutaInicialEnWeb(ruta)));
    return;
  }
  // runApp enseguida, y la carga corre en paralelo con la intro (RF-SPL-4).
  runApp(
    MyApp(
      intro: IntroDelArranque(
        carga: cargarElArranque,
        variantes: SplashVarianteService(),
        random: Random(),
      ),
    ),
  );
}

/// Las rutas de la app, declaradas una sola vez. La intro y la bienvenida
/// toman de aquí el page y el binding de /home y /login para navegar sin
/// transición (RF-SPL-4).
final List<GetPage<dynamic>> paginasDeLaApp = <GetPage<dynamic>>[
  GetPage(name: rutaDelArranque, page: () => const ArranquePage()),
  // Bindings por ruta: asocian cada controller a SU ruta de forma
  // explícita. Sin esto, Get.put dentro del build podía asociarlo al
  // overlay del snackbar activo durante la transición, y al descartarse
  // el snackbar GetX eliminaba el controller de la página visible
  // (crash "TextEditingController was used after being disposed").
  GetPage(
    name: '/login',
    // La bienvenida con Ulises (specs/features/bienvenida, RF-BIEN-1).
    page: () => const BienvenidaPage(),
    // LoginController y BienvenidaController PERMANENTES (ver
    // LoginBinding), que evitan el "tipeo fantasma" cuando se navega a
    // /login con una /login previa aún en el stack (flujo reset de
    // contraseña). Cubre todos los caminos a /login.
    binding: LoginBinding(),
  ),
  GetPage(
    name: '/forgot-password',
    page: () => const ForgotPasswordPage(),
    binding: BindingsBuilder(() {
      Get.lazyPut(() => ForgotPasswordController());
    }),
  ),
  GetPage(
    name: '/reset-password',
    page: () => const ResetPasswordPage(),
    binding: BindingsBuilder(() {
      Get.lazyPut(() => ResetPasswordController());
    }),
  ),
  // Asistente del alumno nuevo (RF-TEST-1). Binding por ruta, en lugar
  // del Get.put que tenía dentro de build.
  GetPage(
    name: '/setup-carrera',
    page: () => const SetupCarreraPage(),
    binding: SetupCarreraBinding(),
  ),
  // Test de especialidad (RF-TEST-1), con el argumento
  // {'origen': 'asistente'} o {'origen': 'perfil'}. Binding por ruta,
  // como el resto, así que el controlador muere al cerrar la ruta y
  // deja el avance en pausa.
  GetPage(
    name: SpecialtyTestPage.ruta,
    page: () => const SpecialtyTestPage(),
    binding: SpecialtyTestBinding(),
  ),
  GetPage(
    name: '/home',
    page: () => const HomePage(),
    // HU19: el controller de la tab Malla se asocia a la RUTA (no a un
    // Get.put dentro del build de la tab) para que sobreviva al cambio
    // de pestañas y se elimine al salir de /home (logout).
    binding: BindingsBuilder(() {
      Get.lazyPut(() => MallaListController());
      Get.lazyPut(() => TeacherSectionsController());
      Get.lazyPut(() => TeacherHomeController());
      Get.lazyPut(() => TeacherGradesController());
    }),
  ),
  // TT07 (#103): la malla clásica vuelve como "Vista mapa (clásica)" de
  // SOLO LECTURA. El binding re-ejecuta lazyPut en cada entrada a la
  // ruta y GetX elimina el controller al salir, así que la vista se
  // hidrata fresca siempre (sin estado stale) y sin Get.put en builds.
  GetPage(
    name: '/malla-clasica',
    page: () => const MallaPage(),
    binding: BindingsBuilder(() {
      Get.lazyPut(() => MallaController());
    }),
  ),
  // HU21 (#105/#106): visor de sílabos in-app. Argumentos:
  // {'url': <silaboUrl de la BD>, 'titulo': <nombre del curso>}.
  // Binding por ruta (regla del repo: nada de Get.put en builds); el
  // controller se crea fresco en cada entrada y se elimina al salir.
  GetPage(
    name: '/silabo',
    page: () => const SilaboViewerPage(),
    binding: BindingsBuilder(() {
      Get.lazyPut(() => SilaboViewerController());
    }),
  ),
  // HU18: pantalla principal del docente (profesor/JP). Binding por ruta.
  GetPage(
    name: '/teacher-home',
    page: () => const TeacherHomePage(),
    binding: TeacherHomeBinding(),
  ),
  GetPage(
    name: '/teacher-advising-create',
    page: () => const CreateAdvisingPage(),
    binding: CreateAdvisingBinding(),
  ),
  GetPage(
    name: '/teacher-advising-attendees',
    page: () => const AttendeesPage(),
    binding: AttendeesBinding(),
  ),
  // Calificación oficial: grilla de una sección (docente). Binding por ruta.
  GetPage(
    name: '/teacher-grade-section',
    page: () => const TeacherGradeSectionPage(),
    binding: TeacherGradeSectionBinding(),
  ),
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
  // Carga de ciclo desde miUlima. Binding por ruta, como el resto: un
  // Get.put dentro de build() ataría el controller al overlay del
  // snackbar y GetX destruiría sus TextEditingController.
  GetPage(
    name: '/portal-sync',
    page: () => const PortalSyncPage(),
    binding: PortalSyncBinding(),
  ),
  GetPage(name: '/chatbot', page: () => const ChatbotPage()),
  GetPage(
    name: '/networking',
    page: () => const NetworkingPage(),
    binding: NetworkingBinding(),
  ),
  // Bloques de horario propios (RF-BLQ-1, RF-BLQ-2). Sin argumento crea;
  // con un TimeBlockRule en `arguments` edita ese bloque. Binding por
  // ruta, como el resto.
  GetPage(
    name: '/bloque',
    page: () => const TimeBlockFormPage(),
    binding: TimeBlockFormBinding(),
  ),
  // «Mis bloques» (RF-BLQ-8): todos los bloques guardados de la alumna,
  // para editarlos o borrarlos. Binding por ruta, como /bloque.
  GetPage(
    name: '/mis-bloques',
    page: () => const TimeBlockListPage(),
    binding: TimeBlockListBinding(),
  ),
];

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.initialRoute = rutaDelArranque, this.intro});

  final String initialRoute;

  /// La intro del splash, o null en web (S-22).
  final IntroDelArranque? intro;

  @override
  Widget build(BuildContext context) {
    final materialTheme = MaterialTheme(Theme.of(context).textTheme);
    return GetMaterialApp(
      title: 'ULIMA++',
      theme: materialTheme.light(),
      darkTheme: materialTheme.dark(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      // Física de scroll uniforme en TODA la app: clamped (sin el rebote /
      // overscroll "infinito" de iOS). Las listas se detienen en los bordes del
      // contenido y no scrollean si todo cabe en pantalla.
      scrollBehavior: const AppScrollBehavior(),
      initialRoute: initialRoute,
      // La capa del arranque es una pieza fija del builder, montada en todas
      // las plataformas. En web queda inactiva desde el principio (RF-SPL-4).
      builder: (context, child) =>
          CapaDeArranque(intro: intro, child: child ?? const SizedBox.shrink()),
      getPages: paginasDeLaApp,
    );
  }
}

/// Física de scroll uniforme para toda la app: `ClampingScrollPhysics` (sin el
/// rebote/overscroll de iOS). Blinda el "scroll infinito" en TODAS las pantallas:
/// cualquier lista/scroll se detiene en los bordes del contenido y no scrollea
/// si el contenido cabe en pantalla. Se instala vía `GetMaterialApp.scrollBehavior`.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
}
