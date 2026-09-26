// lib/pages/specialty_test/widgets/electives_sheet.dart
// La hoja de electivos del resultado (RF-TEST-8). Con empate trae una
// sección por especialidad.

import 'package:flutter/material.dart';

import '../../../configs/themes.dart';
import '../../../models/specialty_test_models.dart';

/// Abre la hoja con los electivos de [especialidades].
Future<void> mostrarElectivos(
  BuildContext context,
  List<TestSpecialty> especialidades,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ElectivesSheet(especialidades: especialidades),
  );
}

class ElectivesSheet extends StatelessWidget {
  const ElectivesSheet({super.key, required this.especialidades});

  final List<TestSpecialty> especialidades;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final gris = MaterialTheme.testMuted(b);
    final tinta = MaterialTheme.textPrimary(b);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: MaterialTheme.sheetBg(b),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: MaterialTheme.sheetHandle(b),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              for (final e in especialidades) ...[
                const SizedBox(height: 16),
                Semantics(
                  header: true,
                  child: Text(
                    'Electivos de ${e.name}',
                    style: TextStyle(
                      color: tinta,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (e.tagline != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    e.tagline!,
                    style: TextStyle(color: gris, fontSize: 12.5, height: 1.35),
                  ),
                ],
                const SizedBox(height: 8),
                for (final electivo in e.electives)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: MaterialTheme.testLine(b)),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          electivo.displayName,
                          style: TextStyle(
                            color: tinta,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          electivo.credits == null
                              ? electivo.code
                              : '${electivo.code} · ${electivo.credits} '
                                    'créditos',
                          style: TextStyle(color: gris, fontSize: 12),
                        ),
                        if (electivo.prerequisite != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            electivo.prerequisite!,
                            style: TextStyle(
                              color: gris,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
