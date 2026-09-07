import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/auth_service.dart';
import '../../services/avatar_service.dart';
import 'avatar_usuario.dart';

/// Insignia de cámara que avisa que el avatar se puede tocar.
///
/// Sin ella el cuadro de iniciales del perfil se ve idéntico al de las nueve
/// pantallas donde la foto NO se puede cambiar, así que la función queda
/// escondida: el 2026-09-07, con la app ya instalada en el teléfono, el propio
/// usuario no encontró dónde cambiarse la foto. El `Semantics` que ya existía
/// solo la anuncia a los lectores de pantalla, no a la vista.
///
/// Va solo en [AvatarPerfil]. Ponerla en [AvatarUsuario] prometería algo que
/// esas pantallas no pueden cumplir.
class AvatarEditBadge extends StatelessWidget {
  const AvatarEditBadge({
    super.key,
    required this.avatarSize,
    this.background,
    this.foreground,
  });

  final double avatarSize;
  final Color? background;
  final Color? foreground;

  /// Proporcional al avatar, pero con cotas: por debajo de 14 px el icono no se
  /// distingue y por encima de 28 la insignia se come el cuadro de 48 del perfil.
  double get diameter => (avatarSize * 0.36).clamp(14.0, 28.0);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: background ?? colors.primary,
        shape: BoxShape.circle,
        // El borde del color del fondo despega la insignia del avatar aunque la
        // foto que haya debajo sea del mismo tono.
        border: Border.all(color: colors.surface, width: 1.5),
      ),
      child: Icon(
        Icons.photo_camera_rounded,
        size: diameter * 0.58,
        color: foreground ?? colors.onPrimary,
      ),
    );
  }
}

/// El avatar del perfil, con la subida encima.
///
/// Es el único punto de la app donde se cambia la foto. Al tocarlo ofrece
/// cámara, galería y —si ya hay foto— quitarla.
///
/// La imagen se reduce ANTES de subir: se pinta a 48 px acá y a 40 en las
/// listas, así que mandar los 4000 px de la cámara gastaría datos móviles del
/// alumno sin que se note en pantalla.
class AvatarPerfil extends StatefulWidget {
  const AvatarPerfil({
    super.key,
    required this.iniciales,
    required this.size,
    this.borderRadius,
    this.background,
    this.foreground,
    this.avatarService,
    this.picker,
  });

  final String iniciales;
  final double size;
  final BorderRadius? borderRadius;
  final Color? background;
  final Color? foreground;

  /// Inyectables para poder probar el flujo sin cámara ni red.
  final AvatarService? avatarService;
  final ImagePicker? picker;

  @override
  State<AvatarPerfil> createState() => _AvatarPerfilState();
}

class _AvatarPerfilState extends State<AvatarPerfil> {
  late final AvatarService _servicio = widget.avatarService ?? AvatarService();
  late final ImagePicker _picker = widget.picker ?? ImagePicker();
  bool _ocupado = false;

  static const int _ladoMaximo = 512;
  static const int _calidad = 85;

  Future<void> _elegir(ImageSource origen) async {
    final archivo = await _picker.pickImage(
      source: origen,
      maxWidth: _ladoMaximo.toDouble(),
      maxHeight: _ladoMaximo.toDouble(),
      imageQuality: _calidad,
    );
    if (archivo == null) return;                     // el usuario canceló
    await _conAviso(() async {
      await _servicio.subir(bytes: await archivo.readAsBytes(), nombreArchivo: archivo.name);
    }, exito: 'Foto actualizada');
  }

  Future<void> _quitar() =>
      _conAviso(_servicio.quitar, exito: 'Foto eliminada');

  /// Ejecuta la acción mostrando el resultado y refrescando al usuario. Los
  /// errores se muestran; no se tragan en silencio ni tumban la pantalla.
  Future<void> _conAviso(Future<void> Function() accion, {required String exito}) async {
    setState(() => _ocupado = true);
    String mensaje = exito;
    try {
      await accion();
      // El avatarUrl viaja en /auth/me: refrescar es lo que hace que la foto
      // nueva aparezca sin reiniciar la app.
      await AuthService.to.refreshCurrentUser();
    } on AvatarFailure catch (e) {
      mensaje = e.message;
    } catch (_) {
      mensaje = 'No se pudo completar la operación. Revisa tu conexión.';
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
    }
  }

  void _abrirOpciones() {
    final tieneFoto = (AuthService.to.currentUser?.avatarUrl ?? '').isNotEmpty;
    showModalBottomSheet<void>(
      context: context,
      builder: (hoja) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar una foto'),
              onTap: () { Navigator.pop(hoja); _elegir(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () { Navigator.pop(hoja); _elegir(ImageSource.gallery); },
            ),
            if (tieneFoto)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Quitar mi foto'),
                onTap: () { Navigator.pop(hoja); _quitar(); },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.to.currentUser;
    return Semantics(
      button: true,
      label: 'Cambiar foto de perfil',
      child: InkWell(
        onTap: _ocupado ? null : _abrirOpciones,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(widget.size / 2),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AvatarUsuario(
              iniciales: widget.iniciales,
              avatarUrl: user?.avatarUrl,
              size: widget.size,
              borderRadius: widget.borderRadius,
              background: widget.background,
              foreground: widget.foreground,
            ),
            if (_ocupado)
              SizedBox(
                width: widget.size * 0.4,
                height: widget.size * 0.4,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Positioned(
                right: 0,
                bottom: 0,
                child: AvatarEditBadge(avatarSize: widget.size),
              ),
          ],
        ),
      ),
    );
  }
}
