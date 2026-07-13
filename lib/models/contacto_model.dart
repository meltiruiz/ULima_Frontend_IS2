import 'package:ulima_plus/models/docente_model.dart';
import 'package:ulima_plus/models/user_model.dart';

import 'networking_model.dart';

class ContactosCursoResult {
  final Docente? docente;
  final Docente? jefePractica;
  final List<ContactoCurso> alumnos;

  const ContactosCursoResult({
    required this.alumnos,
    this.docente,
    this.jefePractica,
  });

  const ContactosCursoResult.empty()
    : docente = null,
      jefePractica = null,
      alumnos = const [];
}

class ContactoCurso {
  final UserModel user;
  final String roleInSection;
  final NetworkingCardDto? networking;

  ContactoCurso({
    required this.user,
    required this.roleInSection,
    this.networking,
  });
}
