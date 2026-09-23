// lib/pages/time_blocks/time_block_form_page.dart
// RF-BLQ-1 y RF-BLQ-2: el formulario de un bloque propio, en el orden que fija
// la spec: nombre, color, días, horas, desde y hasta.
//
// Los pickers y el estilo de los campos copian el único formulario con pickers
// del repo (lib/pages/teacher/create_advising_page.dart), con el título y los
// botones en español (D7). El selector de color son los doce círculos de
// kCoursePalette en dos filas: no se agrega ninguna dependencia de selector
// de color.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../configs/course_colors.dart';
import '../../configs/themes.dart';
import 'time_block_conflicts.dart';
import 'time_block_form_controller.dart';

class TimeBlockFormPage extends StatelessWidget {
  const TimeBlockFormPage({super.key});

  static const String tituloCrear = 'Nuevo bloque';
  static const String tituloEditar = 'Editar bloque';
  static const String guardarLabel = 'Guardar bloque';
  static const String cruceTitulo = 'Hay un cruce';
  static const String cruceVolver = 'Volver a editar';
  static const String cruceGuardar = 'Guardar igual';

  /// El título y los botones de los selectores de Flutter, en español (D7).
  /// Los nombres de los meses siguen en inglés: la app no carga
  /// flutter_localizations y esta funcionalidad no agrega dependencias.
  static const String pickerHoraTitulo = 'Elige la hora';
  static const String pickerFechaTitulo = 'Elige la fecha';
  static const String pickerCancelar = 'Cancelar';
  static const String pickerAceptar = 'Aceptar';

  static const Key nombreKey = Key('bloque-nombre');
  static const Key diasKey = Key('bloque-dias');
  static const Key horaInicioKey = Key('bloque-hora-inicio');
  static const Key horaFinKey = Key('bloque-hora-fin');
  static const Key desdeKey = Key('bloque-desde');
  static const Key hastaKey = Key('bloque-hasta');
  static const Key guardarKey = Key('bloque-guardar');
  static const Key avisoCruceKey = Key('bloque-aviso-cruce');

  /// Key del círculo de un color de la paleta, por su hex `#RRGGBB`.
  static Key colorKey(String hex) => Key('bloque-color-$hex');

  /// Etiquetas de los días, de lunes (1) a domingo (7).
  static const List<String> diasLabels = [
    'Lu',
    'Ma',
    'Mi',
    'Ju',
    'Vi',
    'Sá',
    'Do',
  ];

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TimeBlockFormController>();
    final brightness = Theme.brightnessOf(context);
    final labelColor = MaterialTheme.textPrimary(brightness);

    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 18),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
        );

    return Scaffold(
      backgroundColor: MaterialTheme.pageBg(brightness),
      appBar: AppBar(
        title: Text(c.editando ? tituloEditar : tituloCrear),
      ),
      body: Obx(() {
        // Mientras guarda no se sale (ni con la flecha, ni con el botón atrás
        // de Android, ni deslizando en iOS): el guardado termina cerrando ESTA
        // pantalla, y si el alumno ya hubiera vuelto cerraría la de abajo.
        return PopScope(
          canPop: !c.guardando.value,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Nombre
                label('Nombre'),
                TextField(
                  key: nombreKey,
                  controller: c.nombre,
                  decoration: InputDecoration(
                    hintText: 'Ej. Prácticas',
                    filled: true,
                    fillColor: MaterialTheme.cardBg(brightness),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: MaterialTheme.borderColor(brightness),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: MaterialTheme.borderColor(brightness),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: MaterialTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                // 2. Color
                label('Color'),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final color in kCoursePalette)
                      _CirculoColor(
                        hex: TimeBlockFormController.hexDeColor(color),
                        color: color,
                        elegido: c.colorHex.value ==
                            TimeBlockFormController.hexDeColor(color),
                        onTap: () => c.colorHex.value =
                            TimeBlockFormController.hexDeColor(color),
                      ),
                  ],
                ),

                // 3. Días
                label('Días'),
                SegmentedButton<int>(
                  key: diasKey,
                  multiSelectionEnabled: true,
                  emptySelectionAllowed: true,
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                    textStyle:
                        const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  segments: [
                    for (var d = 1; d <= 7; d++)
                      ButtonSegment(
                        value: d,
                        label: Text(
                          diasLabels[d - 1],
                          softWrap: false,
                          overflow: TextOverflow.fade,
                        ),
                      ),
                  ],
                  selected: c.dias.toSet(),
                  onSelectionChanged: c.dias.assignAll,
                ),

                // 4. Horas
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          label('Hora de inicio'),
                          TimeBlockPickerField(
                            key: horaInicioKey,
                            texto: c.inicioTexto ?? '--:--',
                            icono: Icons.schedule,
                            brightness: brightness,
                            onTap: () async {
                              final elegida = await showTimePicker(
                                context: context,
                                initialTime: c.inicio.value ??
                                    const TimeOfDay(hour: 14, minute: 0),
                                helpText: pickerHoraTitulo,
                                cancelText: pickerCancelar,
                                confirmText: pickerAceptar,
                              );
                              if (elegida != null) c.inicio.value = elegida;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          label('Hora de fin'),
                          TimeBlockPickerField(
                            key: horaFinKey,
                            texto: c.finTexto ?? '--:--',
                            icono: Icons.schedule,
                            brightness: brightness,
                            onTap: () async {
                              final elegida = await showTimePicker(
                                context: context,
                                initialTime: c.fin.value ??
                                    const TimeOfDay(hour: 18, minute: 0),
                                helpText: pickerHoraTitulo,
                                cancelText: pickerCancelar,
                                confirmText: pickerAceptar,
                              );
                              if (elegida != null) c.fin.value = elegida;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // 5. Desde y hasta
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          label('Desde'),
                          TimeBlockPickerField(
                            key: desdeKey,
                            texto: c.desdeTexto ?? 'Elegir',
                            icono: Icons.calendar_today_outlined,
                            brightness: brightness,
                            onTap: () async {
                              final elegida = await _elegirFecha(
                                context,
                                c.desde.value,
                              );
                              if (elegida != null) c.desde.value = elegida;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          label('Hasta'),
                          TimeBlockPickerField(
                            key: hastaKey,
                            texto: c.hastaTexto ?? 'Elegir',
                            icono: Icons.calendar_today_outlined,
                            brightness: brightness,
                            onTap: () async {
                              final elegida = await _elegirFecha(
                                context,
                                c.hasta.value ?? c.desde.value,
                              );
                              if (elegida != null) c.hasta.value = elegida;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (c.errorMessage.value != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      c.errorMessage.value!,
                      style: const TextStyle(
                        color: MaterialTheme.primaryDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    key: guardarKey,
                    onPressed:
                        c.guardando.value ? null : () => _alGuardar(context, c),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MaterialTheme.primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          MaterialTheme.primaryColor.withValues(alpha: 0.5),
                    ),
                    child: c.guardando.value
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.2,
                            ),
                          )
                        : const Text(
                            guardarLabel,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Future<DateTime?> _elegirFecha(BuildContext context, DateTime? actual) {
    final hoy = DateTime.now();
    final primera = DateTime(hoy.year - 1);
    final ultima = DateTime(hoy.year + 2, 12, 31);
    // `showDatePicker` revienta si la fecha inicial cae fuera del rango: un
    // bloque viejo que se edita puede traer una fecha anterior a `primera`.
    var inicial = actual ?? hoy;
    if (inicial.isBefore(primera)) inicial = primera;
    if (inicial.isAfter(ultima)) inicial = ultima;
    return showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: primera,
      lastDate: ultima,
      helpText: pickerFechaTitulo,
      cancelText: pickerCancelar,
      confirmText: pickerAceptar,
    );
  }

  /// Validar → avisar del cruce → guardar. El aviso NUNCA impide guardar
  /// (RF-BLQ-3): ofrece las dos salidas y el alumno decide.
  Future<void> _alGuardar(
    BuildContext context,
    TimeBlockFormController c,
  ) async {
    if (!c.validar()) return;

    final cruces = c.cruces();
    if (cruces.isNotEmpty) {
      final seguir = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          key: avisoCruceKey,
          title: const Text(cruceTitulo),
          content: Text(mensajeDeCruce(cruces)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(cruceVolver),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(cruceGuardar),
            ),
          ],
        ),
      );
      // Cerrar con el barrier o con back devuelve null: tampoco guarda.
      if (seguir != true) return;
    }

    final ok = await c.guardar();
    // `Navigator.pop` y no `Get.back`: con un snackbar abierto, `Get.back`
    // cierra el snackbar y deja al alumno en el formulario ya guardado.
    if (ok && context.mounted) Navigator.of(context).pop(true);
  }
}

/// Un círculo de la paleta. El elegido lleva un anillo y un check. 40 px con
/// 12 de separación: en un iPhone SE (343 px útiles) entran seis por fila y
/// la paleta queda en dos filas de seis (RF-BLQ-2, D7); en una pantalla más
/// ancha el `Wrap` pone más en la primera (7 y 5).
class _CirculoColor extends StatelessWidget {
  const _CirculoColor({
    required this.hex,
    required this.color,
    required this.elegido,
    required this.onTap,
  });

  final String hex;
  final Color color;
  final bool elegido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: TimeBlockFormPage.colorKey(hex),
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: elegido
              ? Border.all(color: MaterialTheme.primaryColor, width: 3)
              : null,
        ),
        child: elegido
            ? const Icon(Icons.check, size: 18, color: Colors.white)
            : null,
      ),
    );
  }
}

/// Campo que abre un picker. Público a propósito: la hoja de acciones de
/// RF-BLQ-5 reusa el mismo campo para cambiar la hora de un día suelto.
class TimeBlockPickerField extends StatelessWidget {
  const TimeBlockPickerField({
    super.key,
    required this.texto,
    required this.icono,
    required this.brightness,
    required this.onTap,
  });

  final String texto;
  final IconData icono;
  final Brightness brightness;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: MaterialTheme.cardBg(brightness),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MaterialTheme.borderColor(brightness)),
        ),
        child: Row(
          children: [
            Icon(icono, size: 18, color: MaterialTheme.textMuted(brightness)),
            const SizedBox(width: 10),
            // Expanded + ellipsis: en un iPhone SE cada campo de la fila mide
            // ~135 px y un texto largo desbordaba la fila.
            Expanded(
              child: Text(
                texto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  color: MaterialTheme.textPrimary(brightness),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
