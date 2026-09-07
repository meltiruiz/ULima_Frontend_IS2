import 'package:flutter/material.dart';

/// Foto de perfil, con las iniciales como respaldo.
///
/// Recibe las iniciales YA calculadas a propósito: cada pantalla las deriva a
/// su manera —el perfil usa el nombre completo, la tarjeta de contacto usa las
/// partes que manda el backend— y unificar ese cálculo aquí cambiaría lo que
/// hoy se ve para quien no tiene foto. Este widget solo agrega la imagen encima.
///
/// Si la foto falla al cargar, vuelve a las iniciales en vez de dejar un icono
/// roto: una red intermitente no debe dejar la lista de contactos llena de
/// cuadros grises.
class AvatarUsuario extends StatelessWidget {
  const AvatarUsuario({
    super.key,
    required this.iniciales,
    this.avatarUrl,
    this.size = 50,
    this.fontSize,
    this.background,
    this.foreground,
    this.borderRadius,
  });

  final String iniciales;

  /// URL ya transformada que manda el backend, o null si la persona no subió
  /// foto. Nunca se construye en el cliente.
  final String? avatarUrl;

  final double size;
  final double? fontSize;
  final Color? background;
  final Color? foreground;

  /// Redondeo. Null = círculo. El perfil usa un rectángulo redondeado, así que
  /// el widget respeta la forma de cada pantalla en vez de imponer la suya.
  final BorderRadius? borderRadius;

  bool get _tieneFoto => (avatarUrl ?? '').trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fondo = background ?? colors.surfaceContainerHighest;
    final texto = foreground ?? colors.onSurfaceVariant;

    final respaldo = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fondo,
        shape: borderRadius == null ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: borderRadius,
      ),
      alignment: Alignment.center,
      child: Text(
        iniciales,
        style: TextStyle(
          color: texto,
          fontSize: fontSize ?? size * 0.4,
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    if (!_tieneFoto) return respaldo;

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(size / 2),
      child: Image.network(
        avatarUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        // Mientras carga se ven las iniciales, no un hueco: el avatar no
        // cambia de tamaño ni salta la lista.
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : respaldo,
        errorBuilder: (context, error, stack) => respaldo,
      ),
    );
  }
}
