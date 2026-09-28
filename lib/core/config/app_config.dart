import '../errors/exceptions.dart';

class AppConfig {
  AppConfig._();

  static const String defaultApiBaseUrl =
      'https://moohamed154-154score-api.hf.space';

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultApiBaseUrl,
  );

  static const String apiKey = String.fromEnvironment('API_KEY');

  static String validateApiKey([String? providedKey]) {
    final key = (providedKey ?? apiKey).trim();
    if (key.isEmpty || key == 'null') {
      throw const ConfigurationException(
        'API configuration is missing. Provide --dart-define=API_KEY=YOUR_API_KEY.',
      );
    }
    return key;
  }
}
