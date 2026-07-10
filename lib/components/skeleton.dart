// lib/components/skeleton.dart
// Bloques skeleton con pulso de opacidad para estados de carga de contenido.
// Sin dependencias externas: usa AnimationController + FadeTransition.
//
// Uso típico:
//   SkeletonCardList(count: 4)                       // lista de cards fantasma
//   SkeletonPulse(child: SkeletonBox(height: 16))    // bloque suelto

import 'package:flutter/material.dart';

import '../configs/themes.dart';

/// Pulso de opacidad compartido por todos los bloques hijos.
/// Un solo AnimationController por subtree (más barato que uno por bloque).
class SkeletonPulse extends StatefulWidget {
  const SkeletonPulse({super.key, required this.child});

  final Widget child;

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(
    begin: 0.45,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

/// Bloque rectangular gris con esquinas redondeadas. No anima por sí solo:
/// envuélvelo (o a su contenedor) en [SkeletonPulse].
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius = 8,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.brightnessOf(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: MaterialTheme.progressBg(brightness),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Card fantasma que imita una card de lista (avatar + título + 2 líneas).
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.showAvatar = true});

  /// Muestra el círculo tipo icono/avatar a la izquierda.
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.brightnessOf(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MaterialTheme.cardBg(brightness),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showAvatar) ...[
            const SkeletonBox(width: 44, height: 44, borderRadius: 22),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: 160, height: 16),
                SizedBox(height: 10),
                SkeletonBox(height: 12),
                SizedBox(height: 6),
                SkeletonBox(width: 220, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista vertical de [count] cards skeleton con un solo pulso compartido.
/// Reemplaza al CircularProgressIndicator central en áreas de contenido.
class SkeletonCardList extends StatelessWidget {
  const SkeletonCardList({
    super.key,
    this.count = 4,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.showAvatar = true,
  });

  final int count;
  final EdgeInsetsGeometry padding;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: ListView.separated(
        padding: padding,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => SkeletonCard(showAvatar: showAvatar),
      ),
    );
  }
}
