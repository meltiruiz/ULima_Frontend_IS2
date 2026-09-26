// lib/pages/specialty_test/widgets/welcome_view.dart
// La bienvenida del test (RF-TEST-3), pantalla 1 de la maqueta.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../components/skeleton.dart';
import '../../../configs/themes.dart';
import '../../../models/specialty_test_models.dart';
import '../specialty_test_controller.dart';
import '../specialty_test_logic.dart';
import 'test_buttons.dart';
import 'ulises_bubble.dart';

/// Tinta del héroe, igual en los dos temas (decisión abierta 13).
const Color _tintaHeroe = Color(0xFF1A0E05);

class WelcomeView extends GetView<SpecialtyTestController> {
  const WelcomeView({super.key});

  /// Marca el esqueleto para las pruebas. Con `SkeletonPulse` en pantalla no
  /// se puede usar `pumpAndSettle`.
  static const Key skeletonKey = Key('bienvenida-esqueleto');

  /// Marca el héroe, que baja a 200 px desde la escala 1,3 (RF-TEST-13).
  static const Key heroKey = Key('bienvenida-heroe');

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return ColoredBox(
      color: MaterialTheme.pageBg(b),
      child: Column(
        children: [
          // Cada Obx lee sus Rx dentro de su función, para quedar suscrito.
          Obx(
            () =>
                _Heroe(especialidades: controller.contenido.value?.specialties),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Obx(
                () => _Cuerpo(
                  carga: controller.carga.value,
                  lineas: controller.contenido.value?.ulises.welcome,
                  enAsistente: controller.enAsistente,
                  onRetry: controller.reintentarCarga,
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Obx(
                () => _Botones(
                  lista: controller.carga.value == EstadoDeCarga.lista,
                  avance: controller.hayAvance,
                  controller: controller,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Heroe extends StatefulWidget {
  const _Heroe({required this.especialidades});

  final List<TestSpecialty>? especialidades;

  @override
  State<_Heroe> createState() => _HeroeState();
}

class _HeroeState extends State<_Heroe> with SingleTickerProviderStateMixin {
  late final AnimationController _vaiven = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Con menos movimiento no hay vaivén de Ulises ni de los orbes.
    if (MediaQuery.disableAnimationsOf(context)) {
      _vaiven.stop();
      _vaiven.value = 0;
    } else if (!_vaiven.isAnimating) {
      _vaiven.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _vaiven.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final escala = MediaQuery.textScalerOf(context).scale(1);
    final alto = escala >= 1.3 ? 200.0 : 284.0;
    final arriba = MediaQuery.paddingOf(context).top;
    final lado = escala >= 1.3 ? 104.0 : 136.0;
    final especialidades = widget.especialidades ?? const <TestSpecialty>[];
    // Posiciones de los cuatro orbes, en fracciones del héroe.
    const lugares = <Offset>[
      Offset(0.06, 0.45),
      Offset(0.80, 0.37),
      Offset(0.79, 0.66),
      Offset(0.11, 0.70),
    ];
    return SizedBox(
      key: WelcomeView.heroKey,
      height: alto + arriba,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, 0.16),
              radius: 0.95,
              colors: [
                Color(0xFFFFA35E),
                Color(0xFFFF7A1A),
                Color(0xFFFF6600),
                Color(0xFFE25A00),
              ],
              stops: [0, 0.40, 0.68, 1],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, box) {
              return AnimatedBuilder(
                animation: _vaiven,
                builder: (context, _) {
                  final t = Curves.easeInOut.transform(_vaiven.value);
                  return Stack(
                    children: [
                      for (var i = 0; i < 4; i++)
                        Positioned(
                          left: box.maxWidth * lugares[i].dx,
                          top: arriba + alto * lugares[i].dy - 4 * t,
                          child: _Orbe(
                            especialidad: i < especialidades.length
                                ? especialidades[i]
                                : null,
                          ),
                        ),
                      Align(
                        alignment: Alignment(0, arriba / (alto + arriba) + 0.1),
                        child: Transform.translate(
                          offset: Offset(0, -5 * t),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Color(0xEBFFFFFF),
                              shape: BoxShape.circle,
                            ),
                            child: UlisesAvatar(size: lado),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        top: arriba + 12,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(8, 6, 11, 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ExcludeSemantics(
                                  child: Icon(
                                    LucideIcons.compass,
                                    size: 15,
                                    color: _tintaHeroe,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Test de especialidad',
                                    style: TextStyle(
                                      color: _tintaHeroe,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Un orbe blanco de 42 px con el ícono de una especialidad en su color
/// claro, sin nombre. Es decorativo.
class _Orbe extends StatelessWidget {
  const _Orbe({required this.especialidad});

  final TestSpecialty? especialidad;

  @override
  Widget build(BuildContext context) {
    final e = especialidad;
    return ExcludeSemantics(
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x735A1E00),
              blurRadius: 14,
              offset: Offset(0, 6),
              spreadRadius: -4,
            ),
          ],
        ),
        child: e == null
            ? null
            : Icon(
                iconoDelTest(e.icon),
                size: 21,
                color:
                    colorDeHex(e.colorLight) ??
                    MaterialTheme.testTaskIconInk(Brightness.light),
              ),
      ),
    );
  }
}

class _Cuerpo extends StatelessWidget {
  const _Cuerpo({
    required this.carga,
    required this.lineas,
    required this.enAsistente,
    required this.onRetry,
  });

  final EstadoDeCarga carga;
  final List<String>? lineas;
  final bool enAsistente;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final lineas = this.lineas;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 35, bottom: 5),
          child: Text(
            'Ulises',
            style: TextStyle(
              color: MaterialTheme.testMuted(b),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (carga == EstadoDeCarga.error)
          TestErrorMessage(text: 'No pudimos cargar el test.', onRetry: onRetry)
        else if (carga == EstadoDeCarga.cargando || lineas == null)
          const SkeletonPulse(
            key: WelcomeView.skeletonKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 35),
                  child: SkeletonBox(width: 230, height: 54, borderRadius: 18),
                ),
                SizedBox(height: 6),
                Padding(
                  padding: EdgeInsets.only(left: 35),
                  child: SkeletonBox(width: 180, height: 38, borderRadius: 18),
                ),
              ],
            ),
          )
        else
          Semantics(
            container: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < lineas.length; i++) ...[
                  if (i > 0) const SizedBox(height: 4),
                  UlisesBubble(text: lineas[i], showAvatar: i > 0),
                ],
              ],
            ),
          ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 35),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              const _Pastilla(icono: LucideIcons.clock, texto: '3 a 4 min'),
              if (enAsistente)
                const _Pastilla(
                  icono: LucideIcons.rotateCcw,
                  texto: 'Rehazlo en Perfil',
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Pastilla extends StatelessWidget {
  const _Pastilla({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 30),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
        decoration: BoxDecoration(
          color: MaterialTheme.testAccentSoft(b),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(
                icono,
                size: 15,
                color: MaterialTheme.testAccentText(b),
              ),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                texto,
                style: TextStyle(
                  color: MaterialTheme.testAccentDeep(b),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Botones extends StatelessWidget {
  const _Botones({
    required this.lista,
    required this.avance,
    required this.controller,
  });

  final bool lista;
  final bool avance;
  final SpecialtyTestController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TestPrimaryButton(
          label: avance ? 'Seguir el test' : 'Empezar el test',
          icon: LucideIcons.arrowRight,
          onPressed: lista ? controller.empezar : null,
        ),
        const SizedBox(height: 4),
        if (avance)
          TestSecondaryButton(
            label: 'Empezar de nuevo',
            onPressed: lista ? controller.empezarDeNuevo : null,
          ),
        if (controller.enAsistente)
          TestSecondaryButton(
            label: 'Saltar y elegir por mi cuenta',
            onPressed: controller.saltar,
          )
        else
          TestSecondaryButton(label: 'Ahora no', onPressed: controller.ahoraNo),
      ],
    );
  }
}
