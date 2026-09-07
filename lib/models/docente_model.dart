import 'networking_model.dart';

class Docente {
  final String code;
  final String firstName;
  final String lastName;

  /// Foto del docente, si tiene cuenta en ULima++. Los docentes sin cuenta no
  /// tienen dónde guardar una foto.
  final String? avatarUrl;
  final NetworkingCardDto? networking;

  Docente({
    required this.code,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    this.networking,
  });

  String get fullName => '$firstName $lastName';

  // Convierte JSON a objeto
  factory Docente.fromJson(Map<String, dynamic> json) {
    return Docente(
      code: json['code']?.toString() ?? 'Sin código',
      firstName: json['firstName']?.toString() ?? 'No',
      lastName: json['lastName']?.toString() ?? 'Asignado',
      avatarUrl: json['avatarUrl']?.toString(),
      networking: _parseNetworking(json['networking']),
    );
  }

  static NetworkingCardDto? _parseNetworking(dynamic value) {
    if (value is! Map) return null;
    try {
      return NetworkingCardDto.fromJson(Map<String, dynamic>.from(value));
    } on FormatException {
      return null;
    }
  }
}
