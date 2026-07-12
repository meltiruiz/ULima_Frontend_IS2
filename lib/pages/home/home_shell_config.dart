import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../components/footer/app_footer.dart';
import '../../models/user_model.dart';
import '../calculadora/calculadora_page.dart';
import '../delegado/delegado_cursos/delegado_cursos_page.dart';
import '../horario/horario.dart';
import '../malla/malla_list_page.dart';
import '../perfil/perfil.dart';
import '../teacher/teacher_home_page.dart';
import '../teacher/teacher_sections_page.dart';
import '../teacher/teacher_grades_page.dart';

class HomeShellConfig {
  const HomeShellConfig({required this.pages, required this.footerItems});

  final List<Widget> pages;
  final List<AppFooterItem> footerItems;

  factory HomeShellConfig.forUser(UserModel? user) {
    if (user?.isTeacher ?? false) return HomeShellConfig.teacher();
    return HomeShellConfig.student(user);
  }

  factory HomeShellConfig.teacher() {
    return const HomeShellConfig(
      pages: [
        TeacherSectionsPage(),
        TeacherGradesPage(),
        HorarioPage(),
        TeacherHomePage(embedded: true),
        ProfilePage(),
      ],
      footerItems: [
        AppFooterItem(icon: LucideIcons.layers, label: 'Secciones'),
        AppFooterItem(icon: LucideIcons.clipboardList, label: 'Calificar'),
        AppFooterItem(icon: LucideIcons.calendar, label: 'Horario'),
        AppFooterItem(icon: LucideIcons.calendarPlus, label: 'Asesorias'),
        AppFooterItem(icon: LucideIcons.user, label: 'Perfil'),
      ],
    );
  }

  factory HomeShellConfig.student(UserModel? user) {
    return HomeShellConfig(
      pages: [
        const MallaListPage(),
        const CalculadoraPage(),
        const HorarioPage(),
        if (user?.isDelegate ?? false) DelegadoCursosPage(),
        const ProfilePage(),
      ],
      footerItems: [
        const AppFooterItem(icon: LucideIcons.network, label: 'Malla'),
        const AppFooterItem(icon: LucideIcons.calculator, label: 'Notas'),
        const AppFooterItem(icon: LucideIcons.calendar, label: 'Horario'),
        if (user?.isDelegate ?? false)
          const AppFooterItem(icon: LucideIcons.shield, label: 'Delegado'),
        const AppFooterItem(icon: LucideIcons.user, label: 'Perfil'),
      ],
    );
  }
}
