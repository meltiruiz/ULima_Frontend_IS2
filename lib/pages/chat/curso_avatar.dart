// lib/pages/chat/curso_avatar.dart
//
// El círculo del curso (RF-CHAT-8): del color del curso y con sus iniciales,
// en blanco o en negro según cuál contraste más. Es el mismo widget para la
// fila de la bandeja (42 px) y para el AppBar del chat (36 px).

import 'package:flutter/material.dart';

import 'chat_linea_tiempo.dart';

class CursoAvatar extends StatelessWidget {
  const CursoAvatar({
    super.key,
    required this.nombre,
    required this.color,
    this.size = 42,
  });

  /// Nombre del curso tal como llega; de él salen las iniciales.
  final String nombre;

  /// Color del curso, el mismo de la grilla del horario.
  final Color color;

  /// Diámetro del círculo.
  final double size;

  @override
  Widget build(BuildContext context) {
    final iniciales = inicialesDeCurso(nombre);
    // Decorativo: junto al círculo siempre va el nombre del curso, así que el
    // lector de pantalla no repite las iniciales.
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        padding: EdgeInsets.all(size * 0.16),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: iniciales.isEmpty
            ? null
            : FittedBox(
                // Con el texto agrandado del sistema, las iniciales se achican
                // antes que salirse del círculo.
                fit: BoxFit.scaleDown,
                child: Text(
                  iniciales,
                  maxLines: 1,
                  style: TextStyle(
                    color: colorDeIniciales(color),
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
      ),
    );
  }
}
