import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/models/networking_model.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/networking_service.dart';

class _RecordingApiClient extends ApiClient {
  _RecordingApiClient() : super(configuredBaseUrl: 'http://example.test');

  String? getPath;
  String? putPath;
  Map<String, dynamic>? putBody;

  Map<String, dynamic> getResponse = <String, dynamic>{};
  Map<String, dynamic> putResponse = <String, dynamic>{};

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    String? token,
    Map<String, String?> query = const {},
    bool suppressSessionExpiry = false,
  }) async {
    getPath = path;
    return getResponse;
  }

  @override
  Future<Map<String, dynamic>> putJson(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    putPath = path;
    putBody = body;
    return putResponse;
  }
}

void main() {
  test('fetchMine consume GET /networking/me y mapea el DTO', () async {
    final api = _RecordingApiClient()
      ..getResponse = {'optIn': false, 'links': <Object>[]};
    final service = NetworkingService(apiClient: api);

    final result = await service.fetchMine();

    expect(api.getPath, '/networking/me');
    expect(result.optIn, isFalse);
    expect(result.links, isEmpty);
  });

  test('updateMine envía el payload exacto a PUT /networking/me', () async {
    final api = _RecordingApiClient()
      ..putResponse = {
        'optIn': true,
        'links': [
          {
            'platform': 'website',
            'url': 'https://alumna.dev',
            'label': 'Portafolio',
          },
        ],
      };
    final service = NetworkingService(apiClient: api);
    const card = NetworkingCardDto(
      optIn: true,
      links: [
        SocialLinkDto(
          platform: 'website',
          url: 'https://alumna.dev',
          label: 'Portafolio',
        ),
      ],
    );

    final result = await service.updateMine(card);

    expect(api.putPath, '/networking/me');
    expect(api.putBody, card.toJson());
    expect(result.link?.label, 'Portafolio');
  });
}
