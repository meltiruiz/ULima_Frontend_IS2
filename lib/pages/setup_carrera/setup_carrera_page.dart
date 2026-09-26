// lib/pages/setup_carrera/setup_carrera_page.dart
// Asistente de configuración inicial (primer login), con la carrera, el test
// de especialidad, que es una ruta aparte, y la selección manual (RF-TEST-1).
// Los colores son tokens de MaterialTheme, en claro y en oscuro.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../configs/themes.dart';
import '../../services/auth_service.dart';
import '../specialty_test/widgets/test_buttons.dart';
import 'setup_carrera_controller.dart';

class SetupCarreraPage extends GetView<SetupCarreraController> {
  const SetupCarreraPage({super.key});

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final user = AuthService.to.currentUser;
    return Scaffold(
      backgroundColor: MaterialTheme.pageBg(b),
      body: SafeArea(
        child: Column(
          children: [
            _WizardHeader(name: user?.firstName ?? 'Alumno'),
            Expanded(
              child: Obx(() {
                switch (controller.step.value) {
                  case SetupStep.carrera:
                    // Sin PopScope, porque el asistente es la única ruta de
                    // la pila y el atrás del sistema sale de la app, como
                    // hoy.
                    return _CarreraStep(controller: controller);
                  case SetupStep.seleccion:
                    return PopScope(
                      canPop: false,
                      onPopInvokedWithResult: (didPop, _) {
                        if (!didPop) controller.volverACarrera();
                      },
                      child: _SeleccionStep(controller: controller),
                    );
                }
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

/// En `headerColor`, con el texto y el ícono en blanco en los dos temas, como
/// el header de la app (decisión 9).
class _WizardHeader extends StatelessWidget {
  const _WizardHeader({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: BoxDecoration(
        color: MaterialTheme.headerColor(b),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.13),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sparkles, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Hola, $name',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Antes de empezar, cuéntanos qué estás estudiando.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Paso 1: Carrera ───────────────────────────────────────────────────────────

class _CarreraStep extends StatelessWidget {
  const _CarreraStep({required this.controller});
  final SetupCarreraController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SectionLabel(
                  icon: LucideIcons.graduationCap,
                  title: 'Tu carrera',
                  subtitle: 'Se asigna automáticamente según tu cuenta ULima.',
                ),
                const SizedBox(height: 14),
                Obx(() {
                  // Sin el catálogo de carreras, el aviso y «Reintentar»
                  // (RF-TEST-1). Si solo fallan las especialidades, la
                  // carrera ya tiene nombre y su tarjeta se queda, igual
                  // que la selección solo avisa sin opciones. La carrera
                  // sale del usuario, así que «Continuar» sigue activo.
                  if (controller.catalogoFallido &&
                      controller.selectedCarreraName.isEmpty) {
                    return TestErrorMessage(
                      text: 'No pudimos cargar tu carrera.',
                      onRetry: controller.reintentarCatalogos,
                    );
                  }
                  return _TarjetaDeCarrera(
                    nombre: controller.selectedCarreraName,
                  );
                }),
              ],
            ),
          ),
        ),
        _BottomButton(
          label: 'Continuar',
          icon: LucideIcons.arrowRight,
          onPressed: controller.continuar,
        ),
      ],
    );
  }
}

class _TarjetaDeCarrera extends StatelessWidget {
  const _TarjetaDeCarrera({required this.nombre});
  final String nombre;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MaterialTheme.cardBg(b),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MaterialTheme.borderColor(b)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: MaterialTheme.specialtyBg(b),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              LucideIcons.graduationCap,
              color: MaterialTheme.iconoNaranja(b),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Carrera asignada',
                  style: TextStyle(
                    color: MaterialTheme.textSecondary(b),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nombre,
                  style: TextStyle(
                    color: MaterialTheme.textPrimary(b),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: MaterialTheme.tagBg(b),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: MaterialTheme.textSecondary(b),
                ),
                const SizedBox(width: 4),
                Text(
                  'Fija',
                  style: TextStyle(
                    color: MaterialTheme.textSecondary(b),
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

// ── Paso 2: Selección manual ──────────────────────────────────────────────────

class _SeleccionStep extends StatelessWidget {
  const _SeleccionStep({required this.controller});
  final SetupCarreraController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final opciones = controller.especialidadesDisponibles;
      final fallo = controller.catalogoFallido;
      final principal = controller.selectedPrincipal.value;
      final intereses = controller.selectedInteres.toSet();
      final saving = controller.saving.value;

      return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SectionLabel(
                    icon: LucideIcons.bookmark,
                    title: 'Especialización principal',
                    subtitle: 'Elige una mención como tu diploma principal.',
                  ),
                  const SizedBox(height: 16),
                  // Un catálogo que llega vacío por un fallo muestra el
                  // aviso en lugar de la lista en blanco (RF-TEST-1).
                  if (fallo && opciones.isEmpty)
                    TestErrorMessage(
                      text: 'No pudimos cargar las especialidades.',
                      onRetry: controller.reintentarCatalogos,
                    ),
                  ...opciones.map((esp) {
                    final id = int.tryParse(esp['id']?.toString() ?? '') ?? 0;
                    final name = esp['name'] as String;
                    final desc = esp['description'] as String? ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _EspecialidadCard(
                        name: name,
                        desc: desc,
                        isPrincipal: principal == id,
                        isInteres: intereses.contains(id),
                        onTapPrincipal: () => controller.setPrincipal(id),
                        onTapInteres: () => controller.toggleInteres(id),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  _ErrorBanner(controller: controller),
                ],
              ),
            ),
          ),
          _BottomButton(
            label: (principal == null && intereses.isEmpty)
                ? 'Saltar por ahora'
                : 'Finalizar configuración',
            icon: LucideIcons.arrowRight,
            onPressed: saving ? null : controller.finish,
            loading: saving,
          ),
        ],
      );
    });
  }
}

class _EspecialidadCard extends StatefulWidget {
  const _EspecialidadCard({
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
  State<_EspecialidadCard> createState() => _EspecialidadCardState();
}

class _EspecialidadCardState extends State<_EspecialidadCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final active = widget.isPrincipal || widget.isInteres;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: widget.isPrincipal
            ? MaterialTheme.testAccentSoft(b)
            : widget.isInteres
            ? MaterialTheme.espInteresBg(b)
            : MaterialTheme.cardBg(b),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.isPrincipal
              ? MaterialTheme.testAccent(b)
              : widget.isInteres
              ? MaterialTheme.textSecondary(b)
              : MaterialTheme.borderColor(b),
          width: active ? 1.6 : 1,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: TextStyle(
                          color: widget.isPrincipal
                              ? MaterialTheme.testAccentDeep(b)
                              : MaterialTheme.textPrimary(b),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (widget.isPrincipal)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Principal',
                            style: TextStyle(
                              color: MaterialTheme.testAccentDeep(b),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else if (widget.isInteres)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Me interesa',
                            style: TextStyle(
                              color: MaterialTheme.textSecondary(b),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      _expanded
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      size: 16,
                      color: MaterialTheme.textMuted(b),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_expanded && widget.desc.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(
                widget.desc,
                style: TextStyle(
                  color: MaterialTheme.textSecondary(b),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          Divider(height: 1, thickness: 1, color: MaterialTheme.borderColor(b)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: _ActionChip(
                    label: widget.isPrincipal
                        ? 'Quitar principal'
                        : 'Principal',
                    icon: widget.isPrincipal ? LucideIcons.x : LucideIcons.star,
                    active: widget.isPrincipal,
                    onTap: widget.onTapPrincipal,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionChip(
                    label: widget.isInteres ? 'Quitar interés' : 'Me interesa',
                    icon: widget.isInteres ? LucideIcons.x : LucideIcons.heart,
                    active: widget.isInteres,
                    onTap: widget.isPrincipal ? null : widget.onTapInteres,
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

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final disabled = onTap == null;
    final Color tinta;
    if (disabled) {
      // El chip desactivado va sin relleno, con el borde gris sobre la
      // tarjeta de la principal, y así se distingue del chip inactivo sin
      // bajar la tinta. La etiqueta en `testMuted` llega a 4,5:1 sobre
      // `testAccentSoft` en los dos temas (RF-TEST-12), con 5,76:1 en claro
      // y 5,64:1 en oscuro.
      tinta = MaterialTheme.testMuted(b);
    } else if (active) {
      tinta = MaterialTheme.testAccentDeep(b);
    } else {
      tinta = MaterialTheme.chipInactiveText(b);
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: disabled
              ? null
              : active
              ? MaterialTheme.testAccentSoft(b)
              : MaterialTheme.chipDisabledBg(b),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active && !disabled
                ? MaterialTheme.testAccent(b)
                : MaterialTheme.chipDisabledBorder(b),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: tinta),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: tinta,
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

// ── Compartidos ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: MaterialTheme.specialtyBg(b),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: MaterialTheme.iconoNaranja(b), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: MaterialTheme.textPrimary(b),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: MaterialTheme.textSecondary(b),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.controller});
  final SetupCarreraController controller;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Obx(() {
      final msg = controller.errorMessage.value;
      if (msg == null) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: MaterialTheme.testAccentSoft(b),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: MaterialTheme.testAccent(b)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              size: 16,
              color: MaterialTheme.testAccentDeep(b),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: TextStyle(
                  color: MaterialTheme.testAccentDeep(b),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// El botón inferior con el estilo del botón principal del test, a lo ancho,
/// con 52 px de alto y texto en tinta sobre naranja, así que «Finalizar
/// configuración» cabe entero.
class _BottomButton extends StatelessWidget {
  const _BottomButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: TestPrimaryButton(
          label: label,
          icon: icon,
          onPressed: onPressed,
          loading: loading,
        ),
      ),
    );
  }
}
