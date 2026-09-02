import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../components/networking/networking_profile_entry_card.dart';
import '../../configs/themes.dart';
import '../../models/malla_models.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/malla_service.dart';
import '../../services/password_reset_service.dart';
import '../../services/session_navigation.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final user = AuthService.to.currentUser;
    return Scaffold(
      backgroundColor: MaterialTheme.pageBg(brightness),
      body: SafeArea(
        top: false,
        // HU15: si no hay datos de perfil disponibles (sesión perdida o carga
        // fallida), mostrar un estado de error en vez de campos vacíos.
        child: user == null
            ? const _ProfileErrorState()
            : Column(
                children: [
                  const _ProfileHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                           NetworkingProfileEntryCard(
                            onTap: () => Get.toNamed('/networking'),
                          ),
                          const SizedBox(height: 16),
                          if (!user.isTeacher) ...[
                            const _CarreraCard(),
                            const SizedBox(height: 16),
                            const _ConfigAcademicaSection(),
                            const SizedBox(height: 16),
                          ],
                          const _SeguridadSection(),
                          const SizedBox(height: 28),
                          const _LogoutButton(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Estado de error (HU15) ────────────────────────────────────────────────────

class _ProfileErrorState extends StatelessWidget {
  const _ProfileErrorState();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 48,
              color: MaterialTheme.textMuted(brightness),
            ),
            const SizedBox(height: 12),
            Text(
              'No se pudieron cargar tus datos de perfil.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: MaterialTheme.textSecondary(brightness),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: offAllToLogin,
              child: const Text('Volver a iniciar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  String _initialsFromAcademicName(
    String fullName,
    String firstName,
    String lastName,
  ) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length >= 3) {
      return '${parts[2][0]}${parts[0][0]}'.toUpperCase();
    }

    if (parts.length == 2) {
      return '${parts[1][0]}${parts[0][0]}'.toUpperCase();
    }

    return ((firstName.isNotEmpty ? firstName[0] : '') +
            (lastName.isNotEmpty ? lastName[0] : ''))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.to.currentUser;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final initials = _initialsFromAcademicName(
      user?.fullName ?? '',
      user?.firstName ?? '',
      user?.lastName ?? '',
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262630) : const Color(0xFFFFF2EC),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF343440) : const Color(0xFFE5E5E5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: MaterialTheme.primaryColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: MaterialTheme.primaryDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? '',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF2D2D2D),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user?.code ?? '',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFB0B0C0)
                        : const Color(0xFF666666),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // HU15: correo institucional (criterio de #68).
                if ((user?.email ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    user!.email,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFB0B0C0)
                          : const Color(0xFF666666),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Carrera (info, no editable) ───────────────────────────────────────────────

class _CarreraCard extends StatelessWidget {
  const _CarreraCard();

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.to;
    final carreraName = auth.getCareerName(auth.currentUser?.careerId);
    final brightness = Theme.of(context).brightness;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MaterialTheme.cardBg(brightness),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MaterialTheme.borderColor(brightness)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: MaterialTheme.espPrincipalBg(brightness),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(
              LucideIcons.graduationCap,
              color: MaterialTheme.primaryDark,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Carrera',
                  style: TextStyle(
                    color: MaterialTheme.labelColor(brightness),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  carreraName.isNotEmpty ? carreraName : '—',
                  style: TextStyle(
                    color: MaterialTheme.textPrimary(brightness),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: MaterialTheme.tagBg(brightness),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 13,
                  color: MaterialTheme.labelColor(brightness),
                ),
                const SizedBox(width: 4),
                Text(
                  'Fija',
                  style: TextStyle(
                    color: MaterialTheme.labelColor(brightness),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sección "Configuración académica" ─────────────────────────────────────────

class _ConfigAcademicaSection extends StatelessWidget {
  const _ConfigAcademicaSection();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            'Configuración académica',
            style: TextStyle(
              color: MaterialTheme.textPrimary(brightness),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const _EspecialidadCard(),
      ],
    );
  }
}

// ── Tarjeta de especialización ────────────────────────────────────────────────

class _EspecialidadCard extends StatelessWidget {
  const _EspecialidadCard();

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _EspecialidadSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.to;
    final brightness = Theme.of(context).brightness;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MaterialTheme.cardBg(brightness),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MaterialTheme.borderColor(brightness)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: MaterialTheme.espPrincipalBg(brightness),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  LucideIcons.bookmark,
                  color: MaterialTheme.primaryDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Especialización',
                  style: TextStyle(
                    color: MaterialTheme.textPrimary(brightness),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _openSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: MaterialTheme.espPrincipalBg(brightness),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: MaterialTheme.primaryColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.pencil,
                        size: 12,
                        color: MaterialTheme.primaryDark,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Editar',
                        style: TextStyle(
                          color: MaterialTheme.primaryDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Obx(() {
            final user = auth.currentUser;
            final principal = user?.especialidadPrincipal;
            final interes = user?.especialidadesInteres ?? [];

            if (principal == null && interes.isEmpty) {
              return Text(
                'Sin especialización seleccionada',
                style: TextStyle(
                  color: MaterialTheme.placeholderText(brightness),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (principal != null) ...[
                  Text(
                    'Principal',
                    style: TextStyle(
                      color: MaterialTheme.labelColor(brightness),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _PrincipalChip(espId: principal),
                  if (interes.isNotEmpty) const SizedBox(height: 12),
                ],
                if (interes.isNotEmpty) ...[
                  Text(
                    'También me interesa',
                    style: TextStyle(
                      color: MaterialTheme.labelColor(brightness),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: interes
                        .map((id) => _InteresChip(espId: id))
                        .toList(),
                  ),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _PrincipalChip extends StatelessWidget {
  const _PrincipalChip({required this.espId});
  final int espId;

  int _pendingCount(int id) {
    final auth = AuthService.to;
    final malla = MallaService.to;
    final user = auth.currentUser;
    if (user == null) return 0;
    final espName = auth.getEspecialidadName(id);
    if (espName.isEmpty) return 0;
    final normalized = malla.normalizeSpecialty(espName);
    final statuses = malla.computeStatuses(user);
    return malla.courses.where((c) {
      if (!c.isElective) return false;
      if (!c.specialties.contains(normalized)) return false;
      final s = statuses[c.id];
      return s == CourseStatus.locked || s == CourseStatus.unlocked;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final name = AuthService.to.getEspecialidadName(espId);
    final pending = _pendingCount(espId);
    final brightness = Theme.of(context).brightness;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: MaterialTheme.espPrincipalBg(brightness),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: MaterialTheme.primaryColor.withValues(alpha: 0.6),
          width: 1.4,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.star,
            size: 13,
            color: MaterialTheme.primaryColor,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: MaterialTheme.primaryDark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (pending > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: MaterialTheme.primaryColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$pending pendientes',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InteresChip extends StatelessWidget {
  const _InteresChip({required this.espId});
  final int espId;

  @override
  Widget build(BuildContext context) {
    final name = AuthService.to.getEspecialidadName(espId);
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: MaterialTheme.espInteresBg(brightness),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFF0EA5E9).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.heart, size: 11, color: Color(0xFF0EA5E9)),
          const SizedBox(width: 5),
          Text(
            name,
            style: TextStyle(
              color: brightness == Brightness.light
                  ? const Color(0xFF0369A1)
                  : const Color(0xFF38BDF8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sección "Seguridad" ───────────────────────────────────────────────────────

class _SeguridadSection extends StatelessWidget {
  const _SeguridadSection();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            'Seguridad',
            style: TextStyle(
              color: MaterialTheme.textPrimary(brightness),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const _ResetPasswordCard(),
        // Solo alumnos: portal-sync exige rol de alumno y un docente
        // recibiría 403 del backend.
        if (!(AuthService.to.currentUser?.isTeacher ?? false)) ...[
          const SizedBox(height: 10),
          const _CargarDesdeMiUlimaCard(),
        ],
      ],
    );
  }
}

/// Tarjeta "Actualizar desde miUlima": repite la carga de ciclo cuando ya se
/// hizo una vez (por ejemplo tras una matrícula complementaria). El aviso del
/// Home solo aparece cuando el alumno no tiene cursos, así que sin esta entrada
/// no habría forma de volver a cargar.
class _CargarDesdeMiUlimaCard extends StatelessWidget {
  const _CargarDesdeMiUlimaCard();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return GestureDetector(
      onTap: () => Get.toNamed<dynamic>('/portal-sync'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MaterialTheme.cardBg(brightness),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MaterialTheme.borderColor(brightness)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: MaterialTheme.espPrincipalBg(brightness),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(
                LucideIcons.refreshCw,
                color: MaterialTheme.primaryDark,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Actualizar desde miUlima',
                    style: TextStyle(
                      color: MaterialTheme.textPrimary(brightness),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Vuelve a traer tus cursos, horario y avance del ciclo',
                    style: TextStyle(
                      color: MaterialTheme.textSecondary(brightness),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: MaterialTheme.textMuted(brightness),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta "Restablecer contraseña": pide el código al backend (requestMe),
/// muestra el correo enmascarado y lleva directo al paso 2 del flujo.
class _ResetPasswordCard extends StatefulWidget {
  const _ResetPasswordCard();

  @override
  State<_ResetPasswordCard> createState() => _ResetPasswordCardState();
}

class _ResetPasswordCardState extends State<_ResetPasswordCard> {
  bool _sending = false;

  /// Pide confirmación (mismo patrón que "Cerrar sesión") antes de disparar el
  /// envío del código, para evitar toques accidentales.
  Future<void> _confirmAndStart(BuildContext context) async {
    if (_sending) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restablecer contraseña'),
        content: const Text(
          'Te enviaremos un código de verificación a tu correo institucional '
          'para restablecer tu contraseña. ¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Enviar código',
              style: TextStyle(
                color: MaterialTheme.primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    await _start();
  }

  Future<void> _start() async {
    final user = AuthService.to.currentUser;
    if (user == null || _sending) return;

    setState(() => _sending = true);
    try {
      final result = await PasswordResetService().requestMe();
      final maskedEmail = result.maskedEmail;
      Get.toNamed(
        '/reset-password',
        arguments: {'identifier': user.code, 'maskedEmail': maskedEmail},
      );
      Get.snackbar(
        'Código enviado',
        maskedEmail.isEmpty
            ? result.message
            : 'Enviamos un código de verificación a $maskedEmail.',
      );
    } on ApiException catch (e) {
      Get.snackbar('Error', e.message);
    } catch (_) {
      Get.snackbar('Error', 'No se pudo enviar el código. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return GestureDetector(
      onTap: () => _confirmAndStart(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MaterialTheme.cardBg(brightness),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MaterialTheme.borderColor(brightness)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: MaterialTheme.espPrincipalBg(brightness),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(
                LucideIcons.keyRound,
                color: MaterialTheme.primaryDark,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Restablecer contraseña',
                    style: TextStyle(
                      color: MaterialTheme.textPrimary(brightness),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Te enviaremos un código a tu correo institucional',
                    style: TextStyle(
                      color: MaterialTheme.labelColor(brightness),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (_sending)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: MaterialTheme.primaryColor,
                ),
              )
            else
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: MaterialTheme.labelColor(brightness),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom sheet de edición ───────────────────────────────────────────────────

class _EspecialidadSheet extends StatefulWidget {
  const _EspecialidadSheet();

  @override
  State<_EspecialidadSheet> createState() => _EspecialidadSheetState();
}

class _EspecialidadSheetState extends State<_EspecialidadSheet> {
  late int? _principal;
  late Set<int> _interes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = AuthService.to.currentUser;
    _principal = user?.especialidadPrincipal;
    _interes = Set.of(user?.especialidadesInteres ?? []);
    // Sanear estado heredado inconsistente (principal duplicada como interés
    // por datos antiguos): el backend lo rechaza con 409 DUPLICATE_PRIMARY.
    if (_principal != null) _interes.remove(_principal);
  }

  List<Map<String, dynamic>> get _opciones {
    final auth = AuthService.to;
    final cId = auth.currentUser?.careerId;
    if (cId == null) return const [];
    final list = auth.especialidades
        .where((e) => e['carrera_id'] == cId && e['is_active'] == true)
        .toList();
    list.sort((a, b) {
      final oA = (a['display_order'] as num?)?.toInt() ?? 999;
      final oB = (b['display_order'] as num?)?.toInt() ?? 999;
      return oA.compareTo(oB);
    });
    return list;
  }

  void _setPrincipal(int id) {
    setState(() {
      if (_principal == id) {
        _principal = null;
      } else {
        _principal = id;
        _interes.remove(id);
      }
    });
  }

  void _toggleInteres(int id) {
    if (_principal == id) return;
    setState(() {
      if (_interes.contains(id)) {
        _interes.remove(id);
      } else {
        _interes.add(id);
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final auth = AuthService.to;
    try {
      await auth.completeSetup(
        careerId: auth.currentUser!.careerId!,
        especialidadPrincipal: _principal,
        especialidadesInteres: _interes.toList(),
      );
      if (mounted) Navigator.of(context).pop();
      Get.snackbar(
        'Especialidades actualizadas',
        'Tu selección se guardó correctamente.',
      );
    } on ApiException catch (e) {
      Get.snackbar('No se pudo guardar', e.message);
    } catch (_) {
      Get.snackbar('No se pudo guardar', 'Intenta de nuevo en unos minutos.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final opciones = _opciones;
    final brightness = Theme.of(context).brightness;

    return Container(
      decoration: BoxDecoration(
        color: MaterialTheme.sheetBg(brightness),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: MaterialTheme.sheetHandle(brightness),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: MaterialTheme.espPrincipalBg(brightness),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        LucideIcons.bookmark,
                        color: MaterialTheme.primaryDark,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Especialización',
                            style: TextStyle(
                              color: MaterialTheme.textPrimary(brightness),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Elige principal, intereses o ninguna.',
                            style: TextStyle(
                              color: MaterialTheme.labelColor(brightness),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
              ],
            ),
          ),
          if (opciones.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No hay especializaciones disponibles para tu carrera.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: MaterialTheme.placeholderText(brightness),
                  fontSize: 13,
                ),
              ),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  children: opciones.map((esp) {
                    final id = int.tryParse(esp['id']?.toString() ?? '') ?? 0;
                    final name = esp['name'] as String;
                    final desc = esp['description'] as String? ?? '';
                    final isPrincipal = _principal == id;
                    final isInteres = _interes.contains(id);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SheetEspecialidadRow(
                        name: name,
                        desc: desc,
                        isPrincipal: isPrincipal,
                        isInteres: isInteres,
                        onTapPrincipal: () => _setPrincipal(id),
                        onTapInteres: () => _toggleInteres(id),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.2,
                        ),
                      )
                    : const Icon(LucideIcons.check, size: 18),
                label: const Text(
                  'Guardar',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MaterialTheme.primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: MaterialTheme.primaryColor
                      .withValues(alpha: 0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetEspecialidadRow extends StatelessWidget {
  const _SheetEspecialidadRow({
    required this.name,
    required this.desc,
    required this.isPrincipal,
    required this.isInteres,
    required this.onTapPrincipal,
    required this.onTapInteres,
  });

  final String name;
  final String desc;
  final bool isPrincipal;
  final bool isInteres;
  final VoidCallback onTapPrincipal;
  final VoidCallback onTapInteres;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: isPrincipal
            ? MaterialTheme.espPrincipalBg(brightness)
            : isInteres
            ? MaterialTheme.espInteresBg(brightness)
            : MaterialTheme.sheetRowBg(brightness),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPrincipal
              ? MaterialTheme.primaryColor
              : isInteres
              ? const Color(0xFF0EA5E9)
              : MaterialTheme.borderColor(brightness),
          width: (isPrincipal || isInteres) ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: isPrincipal
                            ? MaterialTheme.primaryDark
                            : MaterialTheme.textPrimary(brightness),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isPrincipal)
                      const Text(
                        'Principal',
                        style: TextStyle(
                          color: MaterialTheme.primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    else if (isInteres)
                      const Text(
                        'Me interesa',
                        style: TextStyle(
                          color: Color(0xFF0EA5E9),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (desc.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: MaterialTheme.descText(brightness),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            )
          else
            const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SheetChip(
                  label: isPrincipal ? 'Quitar principal' : 'Principal',
                  icon: isPrincipal ? LucideIcons.x : LucideIcons.star,
                  active: isPrincipal,
                  color: MaterialTheme.primaryColor,
                  onTap: onTapPrincipal,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SheetChip(
                  label: isInteres ? 'Quitar interés' : 'Me interesa',
                  icon: isInteres ? LucideIcons.x : LucideIcons.heart,
                  active: isInteres,
                  color: const Color(0xFF0EA5E9),
                  onTap: isPrincipal ? null : onTapInteres,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetChip extends StatelessWidget {
  const _SheetChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final brightness = Theme.of(context).brightness;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: disabled
              ? MaterialTheme.chipDisabledBg(brightness)
              : active
              ? color.withValues(alpha: 0.12)
              : MaterialTheme.chipDisabledBg(brightness),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: disabled
                ? MaterialTheme.chipDisabledBorder(brightness)
                : active
                ? color.withValues(alpha: 0.5)
                : MaterialTheme.chipDisabledBorder(brightness),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 13,
              color: disabled
                  ? MaterialTheme.chipDisabledText(brightness)
                  : active
                  ? color
                  : MaterialTheme.chipInactiveText(brightness),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: disabled
                      ? MaterialTheme.chipDisabledText(brightness)
                      : active
                      ? color
                      : MaterialTheme.chipInactiveText(brightness),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Logout ────────────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () async {
          // HU02: confirmar antes de cerrar sesión (evita salidas accidentales).
          final confirmar = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Cerrar sesión'),
              content: const Text('¿Seguro que quieres cerrar sesión?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text(
                    'Cerrar sesión',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
          if (confirmar != true) return;

          await AuthService.to.logout();
          // offAllToLogin: si el /auth/logout respondió 401 (token ya
          // invalidado) y el interceptor ya nos dejó en el login, NO apilar
          // una segunda ruta /login: eso destruía el LoginController de la
          // pantalla visible y sus campos dejaban de repintar al teclear
          // (ver services/session_navigation.dart).
          offAllToLogin();
        },
        icon: const Icon(LucideIcons.logOut, size: 18),
        label: const Text(
          'Cerrar sesión',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: const BorderSide(color: Colors.redAccent, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
