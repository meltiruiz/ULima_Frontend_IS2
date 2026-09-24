// lib/pages/chat/chats_inbox_page.dart
//
// La bandeja de la pestaña Chats del alumno (RF-CHAT-6): una fila por cada
// sección matriculada, que abre el chat de esa sección. No hace pedidos
// propios: lee las secciones y sus colores de HorarioController, el mismo que
// carga el horario.
//
// El archivo define además TarjetaDeChat, la tarjeta de cada fila, que
// Secciones del docente también usa para abrir el chat (RF-CHAT-13).

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../configs/themes.dart';
import '../../services/chat_repository.dart';
import '../horario/horario_controller.dart';
import 'chat_linea_tiempo.dart';
import 'chat_page.dart';
import 'curso_avatar.dart';

class ChatsInboxPage extends StatelessWidget {
  const ChatsInboxPage({super.key, this.repository});

  /// Inyectable para tests: se le pasa a cada `ChatPage` que abre la bandeja.
  /// En producción es null y `ChatPage` usa el repositorio real.
  final ChatRepositoryContract? repository;

  @override
  Widget build(BuildContext context) {
    // Como el horario (horario.dart), la bandeja registra el controller al
    // construirse. Si ya existe, Get.put devuelve ese y no pide nada; si no,
    // su onInit hace la primera carga.
    final controller = Get.put(HorarioController());
    final brillo = Theme.of(context).brightness;

    return ColoredBox(
      color: MaterialTheme.pageBg(brillo),
      child: Obx(() {
        if (!controller.seccionesCargadas.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final cursos = controller.uniqueEnrolledCourses;
        if (cursos.isEmpty) return _BandejaVacia(brillo: brillo);
        final colores = controller.colorPorCurso;

        return ListView.builder(
          // Abajo quedan 96 px para la burbuja de Ulises, de 60 x 60 con
          // 12 px de margen, que el shell pone encima abajo a la izquierda:
          // al final de la lista la última fila queda por encima de ella.
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          itemCount: cursos.length,
          itemBuilder: (context, index) {
            final curso = cursos[index];
            final idSeccion = curso['idSeccion'].toString();
            final nombre = curso['curso']?.toString() ?? '';
            final codigo = curso['codigoSeccion']?.toString();
            // colorPorCurso reparte la paleta entre las mismas secciones que
            // lista uniqueEnrolledCourses, con la misma clave, así que siempre
            // trae uno (RF-CHAT-6). El único respaldo de color es el de
            // ChatPage (RF-CHAT-8), para quien la abre sin color.
            final color = colores[idSeccion]!;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FilaDeChat(
                brillo: brillo,
                nombre: nombre,
                codigo: codigo,
                color: color,
                onTap: () => Get.to<void>(
                  () => ChatPage(
                    sectionId: idSeccion,
                    courseName: nombre,
                    sectionCode: codigo,
                    courseColor: color,
                    repository: repository,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

/// Una fila de la bandeja, que pone en una [TarjetaDeChat] el círculo del
/// curso, su nombre, «Sección N» o «Sin sección» y un chevron.
class _FilaDeChat extends StatelessWidget {
  const _FilaDeChat({
    required this.brillo,
    required this.nombre,
    required this.codigo,
    required this.color,
    required this.onTap,
  });

  final Brightness brillo;
  final String nombre;

  /// El código de la sección tal como llega, que puede ser nulo o vacío.
  final String? codigo;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TarjetaDeChat(
      brillo: brillo,
      nombreDelCurso: nombre,
      codigoDeSeccion: codigo,
      onTap: onTap,
      child: Row(
        children: [
          CursoAvatar(nombre: nombre, color: color, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: MaterialTheme.textPrimary(brillo),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  etiquetaDeSeccion(codigo),
                  style: TextStyle(
                    color: MaterialTheme.textSecondary(brillo),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            LucideIcons.chevronRight,
            size: 20,
            color: MaterialTheme.textMuted(brillo),
          ),
        ],
      ),
    );
  }
}

/// La tarjeta que abre el chat de un curso. La usan la fila de la bandeja
/// (RF-CHAT-6) y la tarjeta de Secciones del docente (RF-CHAT-13), que la
/// spec pide iguales, así que la forma, la semántica y el relleno viven solo
/// aquí y cada página pone su contenido.
///
/// Es un botón con la etiqueta `Abrir el chat de <curso>, sección <N>`, o
/// `…, sin sección` (`etiquetaParaAbrirElChat`), y el lector de pantalla lee
/// solo esa etiqueta, con la acción de toque del `InkWell`, porque el
/// contenido queda callado. La sección va en la etiqueta para que dos
/// secciones del mismo curso se distingan.
class TarjetaDeChat extends StatelessWidget {
  const TarjetaDeChat({
    super.key,
    required this.brillo,
    required this.nombreDelCurso,
    required this.codigoDeSeccion,
    required this.onTap,
    required this.child,
  });

  final Brightness brillo;

  /// El nombre del curso tal como llega, que va en la etiqueta accesible.
  final String nombreDelCurso;

  /// El código de la sección tal como llega, que también va en la etiqueta
  /// accesible. Nulo, vacío o con solo espacios, la etiqueta dice «sin
  /// sección».
  final String? codigoDeSeccion;

  final VoidCallback onTap;

  /// El contenido visible de la tarjeta, dentro de un relleno de 16 px.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: MaterialTheme.borderColor(brillo)),
    );

    // El Material lleva el color y la forma de la tarjeta para que el ripple
    // del InkWell se vea, ya que un Container decorado encima lo taparía.
    return Semantics(
      container: true,
      button: true,
      label: etiquetaParaAbrirElChat(nombreDelCurso, codigoDeSeccion),
      child: Material(
        color: MaterialTheme.cardBg(brillo),
        shape: forma,
        child: InkWell(
          customBorder: forma,
          onTap: onTap,
          child: ExcludeSemantics(
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      ),
    );
  }
}

/// El estado vacío de «Mis chats», sin cambios: sin secciones matriculadas, o
/// si la carga falló, porque el controller se traga el error.
class _BandejaVacia extends StatelessWidget {
  const _BandejaVacia({required this.brillo});

  final Brightness brillo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 48,
              color: MaterialTheme.textMuted(brillo),
            ),
            const SizedBox(height: 12),
            Text(
              'No hay cursos matriculados.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: MaterialTheme.textSecondary(brillo),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
