bool networkingPlatformRequiresLabel(String platform) {
  return platform == 'website' || platform == 'other';
}

String? validateNetworkingUrl(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return 'Ingresa el enlace de tu red.';

  final uri = Uri.tryParse(trimmed);
  final isHttp = uri?.scheme == 'http' || uri?.scheme == 'https';
  if (uri == null || !isHttp || uri.host.isEmpty) {
    return 'Ingresa un enlace completo que empiece con http:// o https://.';
  }

  return null;
}

String? validateNetworkingLabel(String platform, String? value) {
  if (!networkingPlatformRequiresLabel(platform)) return null;
  if ((value ?? '').trim().isEmpty) {
    return 'Escribe un nombre visible para este enlace.';
  }
  return null;
}
