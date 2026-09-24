import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../components/footer/app_footer.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../calculadora/calculadora_page.dart';
import '../chat/chats_inbox_page.dart';
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
    if (user?.isTeacher ?? false) {
      // La pestaña "Calificar" solo la ve el Profesor titular. Un JP (jefe de
      // práctica) no califica, así que se omite. `canGrade` = tiene ≥1 sección
      // donde es teacher_id (derivado del backend en AuthService).
      return HomeShellConfig.teacher(canGrade: AuthService.to.canGrade);
    }
    return HomeShellConfig.student(user);
  }

  factory HomeShellConfig.teacher({required bool canGrade}) {
    return HomeShellConfig(
      pages: [
        const TeacherSectionsPage(),
        if (canGrade) const TeacherGradesPage(),
        const HorarioPage(),
        const TeacherHomePage(embedded: true),
        const ProfilePage(),
      ],
      footerItems: [
        const AppFooterItem(icon: LucideIcons.layers, label: 'Secciones'),
        if (canGrade)
          const AppFooterItem(
            icon: LucideIcons.clipboardList,
            label: 'Calificar',
          ),
        const AppFooterItem(icon: LucideIcons.calendar, label: 'Horario'),
        const AppFooterItem(icon: LucideIcons.calendarPlus, label: 'Asesorias'),
        const AppFooterItem(icon: LucideIcons.user, label: 'Perfil'),
      ],
    );
  }

  /// Malla, Notas, Horario, Chats y Perfil; un delegado suma Delegado justo
  /// antes de Perfil (RF-CHAT-5 y BR-SHELL-F-02).
  factory HomeShellConfig.student(UserModel? user) {
    return HomeShellConfig(
      pages: [
        const MallaListPage(),
        const CalculadoraPage(),
        const HorarioPage(),
        const ChatsInboxPage(),
        if (user?.isDelegate ?? false) DelegadoCursosPage(),
        const ProfilePage(),
      ],
      footerItems: [
        const AppFooterItem(icon: LucideIcons.network, label: 'Malla'),
        const AppFooterItem(icon: LucideIcons.calculator, label: 'Notas'),
        const AppFooterItem(icon: LucideIcons.calendar, label: 'Horario'),
        const AppFooterItem(icon: LucideIcons.messagesSquare, label: 'Chats'),
        if (user?.isDelegate ?? false)
          const AppFooterItem(icon: LucideIcons.shield, label: 'Delegado'),
        const AppFooterItem(icon: LucideIcons.user, label: 'Perfil'),
      ],
    );
  }
}
