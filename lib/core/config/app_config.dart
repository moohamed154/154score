import '../errors/exceptions.dart';

class AppConfig {
  AppConfig._();

  static const String defaultApiBaseUrl =
      'https://154score-api.medohs770.workers.dev';

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultApiBaseUrl,
  );

  static const String apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: '154s_790029b3321ece28ede82f76dd1c2436',
  );

  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0+1',
  );

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
