import 'package:ulima_plus/models/user_model.dart';

import 'networking_model.dart';

class ContactoCurso {
  final UserModel user;
  final String roleInSection;
  final NetworkingCardDto? networking;

  ContactoCurso({
    required this.user,
    required this.roleInSection,
    this.networking,
  });

  void operator [](String other) {}
}

/// Delegado o subdelegado que el portal miUlima publica para la sección pero
/// que todavía NO tiene cuenta en ULima++.
///
/// No es un [ContactoCurso] y no puede serlo: un contacto exige correo,
/// carrera y carnet de networking, que de esta persona no existen y no se
/// pueden inventar. Por eso llega en una clave hermana de `alumnos` y se
/// pinta aparte.
///
/// `contactable` viene siempre en false desde el backend: habla de una
/// capacidad —la app no debe ofrecer escribirle a alguien que no está— y no
/// de la persona.
class RepresentantePendiente {
  final String code;
  final String firstName;
  final String lastName;

  /// `delegate` | `subdelegate`, tal como los nombra el backend.
  final String position;
  final bool contactable;

  const RepresentantePendiente({
    required this.code,
    required this.firstName,
    required this.lastName,
    required this.position,
    this.contactable = false,
  });

  factory RepresentantePendiente.fromJson(Map<String, dynamic> json) =>
      RepresentantePendiente(
        code: json['code']?.toString() ?? '',
        firstName: json['firstName']?.toString() ?? '',
        lastName: json['lastName']?.toString() ?? '',
        position: json['position']?.toString() ?? '',
        contactable: json['contactable'] == true,
      );

  /// El mismo vocabulario que `roleInSection` usa para los alumnos con cuenta,
  /// para que la tarjeta pinte el badge igual sin saber de dónde salió.
  String get rolEnEspanol =>
      position == 'delegate' ? 'delegado' : 'subdelegado';
}
