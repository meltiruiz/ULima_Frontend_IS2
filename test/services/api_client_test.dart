import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/services/api_client.dart';

void main() {
  test('normaliza API_BASE_URL configurada removiendo slash final', () {
    final client = ApiClient(
      configuredBaseUrl: 'https://u-lima-backend-is-2-one.vercel.app/',
    );

    expect(client.baseUrl, 'https://u-lima-backend-is-2-one.vercel.app');
  });
}
