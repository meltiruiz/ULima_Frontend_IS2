import 'package:ulima_plus/models/contacto_model.dart';
import 'package:ulima_plus/models/docente_model.dart';
import 'package:ulima_plus/models/networking_model.dart';
import 'package:ulima_plus/models/user_model.dart';

import 'api_client.dart';

class ContactoService {
  // Inyectable para poder probar el parseo sin red, igual que PortalSyncService.
  // Por defecto arma el suyo, así que ningún llamador existente cambia.
  ContactoService({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  // No atrapa el error: propaga la ApiException para que el caller distinga
  // "falló la carga" de "sin contactos" (ver docs/AUDITORIA_TECNICA.md §6.1).
  // Incluye el carnet de networking (opt-in) de cada contacto.
  Future<Map<String, dynamic>> fetchContactos(String idSeccion) async {
    final data = await _api.getJson(
      '/course-detail/sections/$idSeccion/contacts',
    );
    final docenteRaw = data['docente'];
    final docente = docenteRaw == null
        ? null
        : Docente.fromJson(Map<String, dynamic>.from(docenteRaw as Map));
    // HU18: jefe de práctica de la sección (0 o 1).
    final jpRaw = data['jefePractica'];
    final jefePractica = jpRaw == null
        ? null
        : Docente.fromJson(Map<String, dynamic>.from(jpRaw as Map));
    final List<dynamic> alumnosRaw = data['alumnos'] ?? [];
    final contactos = alumnosRaw.map((raw) {
      final json = Map<String, dynamic>.from(raw as Map);
      return ContactoCurso(
        user: UserModel.fromJson(
          Map<String, dynamic>.from(json['user'] as Map),
        ),
        roleInSection: json['roleInSection']?.toString() ?? 'estudiante',
        networking: _parseNetworking(json['networking']),
      );
    }).toList();

    contactos.sort((a, b) {
      final compare = _rolePriority(
        a.roleInSection,
      ).compareTo(_rolePriority(b.roleInSection));

      if (compare == 0) {
        return a.user.lastName.compareTo(b.user.lastName);
      }

      return compare;
    });

    // Clave hermana de `alumnos`: los representantes que el portal publica pero
    // que aún no son usuarios. Si el backend es viejo y no la manda, la lista
    // queda vacía y la pantalla se comporta como antes.
    final List<dynamic> pendientesRaw = data['representantesPendientes'] ?? [];
    final pendientes = pendientesRaw
        .map(
          (raw) => RepresentantePendiente.fromJson(
            Map<String, dynamic>.from(raw as Map),
          ),
        )
        .toList();

    return {
      'docente': docente,
      'jefePractica': jefePractica,
      'alumnos': contactos,
      'representantesPendientes': pendientes,
    };
  }

  int _rolePriority(String role) {
    switch (role) {
      case 'delegado':
        return 0;
      case 'subdelegado':
        return 1;
      default:
        return 2;
    }
  }

  NetworkingCardDto? _parseNetworking(dynamic value) {
    if (value is! Map) return null;
    try {
      return NetworkingCardDto.fromJson(Map<String, dynamic>.from(value));
    } on FormatException {
      return null;
    }
  }
}
