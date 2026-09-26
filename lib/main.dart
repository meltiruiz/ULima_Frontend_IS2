// TERMINAL - flutter pub get

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/services.dart';

import '/configs/themes.dart';
import '/firebase_options.dart';
import '/services/auth_service.dart';
import '/services/alert_service.dart';
import '/services/malla_service.dart';
import '/services/academic_record_service.dart';
import '/services/specialty_test_service.dart';
import '/services/time_blocks_service.dart';
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
import 'pages/academic_record/academic_record_binding.dart';
import 'pages/academic_record/academic_record_page.dart';
import 'pages/mis_notas/mis_notas_binding.dart';
import 'pages/portal_sync/portal_sync_binding.dart';
import 'pages/portal_sync/portal_sync_page.dart';
import 'pages/registro/registro_binding.dart';
import 'pages/registro/registro_page.dart';
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
  // Estado único del récord (RF-REC-5), compartido por la tarjeta del Perfil y
  // /mi-record. No carga nada al arrancar: la tarjeta lo pide al montarse.
  Get.put<AcademicRecordService>(AcademicRecordService(), permanent: true);
  // Estado único de los bloques de horario propios (RF-BLQ-7). Permanente
  // como MallaService: la pantalla de horario es una tab del shell y el
  // formulario de /bloque escribe sobre este mismo estado. Tampoco carga nada
  // al arrancar: el horario pide su ventana al montarse.
  Get.put<TimeBlocksService>(TimeBlocksService(), permanent: true);
  // Capa de datos del test de especialidad (RF-TEST-2). Permanente porque
  // guarda en memoria la copia del contenido de la sesión, un test en pausa
  // y el último resultado. Tampoco carga nada al arrancar.
  Get.put<SpecialtyTestService>(SpecialtyTestService(), permanent: true);

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
        // Alta de cuenta contra miUlima (HU33). Binding por ruta, como el
        // resto: `lazyPut` sin `fenix` garantiza que GetX elimine el controller
        // al salir y que `onClose` borre las credenciales del portal.
        GetPage(
          name: '/registro',
          page: () => const RegistroPage(),
          binding: RegistroBinding(),
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
