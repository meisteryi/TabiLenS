import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvKeys {
  static const String geminiApiKey = 'GEMINI_API_KEY';

  /// Securely retrieves the Gemini API Key:
  /// 1. Prioritizes compile-time environment variable (--dart-define / --dart-define-from-file)
  /// 2. Falls back to dotenv (.env file loaded in development)
  static String get apiKey {
    const fromEnv = String.fromEnvironment(geminiApiKey);
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    return dotenv.env[geminiApiKey] ?? '';
  }
}
