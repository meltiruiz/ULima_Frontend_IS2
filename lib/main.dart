// TERMINAL - flutter pub get

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '/configs/themes.dart';
import '/firebase_options.dart';
import '/services/auth_service.dart';
import '/services/alert_service.dart';
import '/services/malla_service.dart';
import '/services/post_login_route.dart';
import '/services/storage_service.dart';
import 'pages/home/home_page.dart';
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
import 'pages/mis_notas/mis_notas_binding.dart';
import 'pages/mis_notas/mis_notas_page.dart';
import 'pages/login/login_page.dart';
import 'pages/malla/malla_controller.dart';
import 'pages/malla/malla_list_controller.dart';
import 'pages/malla/malla_page.dart';
import 'pages/login/login_binding.dart';
import 'pages/password_reset/forgot_password_controller.dart';
import 'pages/password_reset/reset_password_controller.dart';
import 'pages/password_reset/forgot_password_page.dart';
import 'pages/password_reset/reset_password_page.dart';
import 'pages/setup_carrera/setup_carrera_page.dart';
import 'pages/silabo/silabo_viewer_controller.dart';
import 'pages/silabo/silabo_viewer_page.dart';
import 'pages/chatbot/chatbot_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  LucideIcons.info.codePoint;

  // Servicios globales permanentes.
  await Get.putAsync<StorageService>(
    () => StorageService().init(),
    permanent: true,
  );
  Get.put<AuthService>(AuthService(), permanent: true);
  Get.put<AlertService>(AlertService(), permanent: true);
  Get.put<MallaService>(MallaService(), permanent: true);


  // Intentar restaurar sesión guardada.
  final restored = await AuthService.to.tryRestoreSession();
  String initialRoute;
  if (restored) {
    final user = AuthService.to.currentUser!;
    initialRoute = postLoginRoute(user);
    // Las alertas son de alumno (endpoint /alerts/me con requireRole de
    // alumno): no se piden para docentes (recibirían 403).
    if (!user.isTeacher) {
      try {
        await AlertService.to.fetchAlerts();
      } catch (e) {
        print('Error loading alerts at startup: $e');
      }
    }
  } else {
    initialRoute = '/login';
  }

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.initialRoute});
  final String initialRoute;

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
      getPages: [
        // Bindings por ruta: asocian cada controller a SU ruta de forma
        // explícita. Sin esto, Get.put dentro del build podía asociarlo al
        // overlay del snackbar activo durante la transición, y al descartarse
        // el snackbar GetX eliminaba el controller de la página visible
        // (crash "TextEditingController was used after being disposed").
        GetPage(
          name: '/login',
          page: () => const LoginPage(),
          // LoginController PERMANENTE (ver LoginBinding): evita el "tipeo
          // fantasma" cuando se navega a /login con una /login previa aún en el
          // stack (flujo reset de contraseña). Cubre todos los caminos a /login.
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
        GetPage(name: '/setup-carrera', page: () => const SetupCarreraPage()),
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
        GetPage(
          name: '/chatbot',
          page: () => const ChatbotPage(),
        ),
      ],
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
