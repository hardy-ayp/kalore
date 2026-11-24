/// API Configuration for Kalore.
///
/// For open-source security, no real API keys are hardcoded in source code.
/// Configure your API keys using standard Flutter compilation defines:
///
/// 1. Via compile-time flags:
///    ```bash
///    flutter run --dart-define=GEMINI_API_KEY=your_gemini_key \
///                --dart-define=CALORIE_API_KEY=your_calorie_api_key \
///                --dart-define=CALORIE_NINJAS_KEY=your_ninjas_key
///    ```
///
/// 2. Via `env.json` (see `env.json.example`):
///    ```bash
///    flutter run --dart-define-from-file=env.json
///    ```
///
/// 3. In-App User Settings:
///    Users can also configure their personal Gemini API key directly
///    within the Kalore settings screen.
class ApiConfig {
  /// Google Gemini AI API Key
  static const String defaultGeminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// CalorieAPI (CalorieApiAdmin) API Key
  static const String defaultCalorieApiKey = String.fromEnvironment(
    'CALORIE_API_KEY',
    defaultValue: '',
  );

  /// CalorieNinjas API Key
  static const String defaultCalorieNinjasKey = String.fromEnvironment(
    'CALORIE_NINJAS_KEY',
    defaultValue: '',
  );

  /// Helper to check if any AI service is configured
  static bool get hasAnyCloudKey =>
      defaultGeminiApiKey.isNotEmpty ||
      defaultCalorieApiKey.isNotEmpty ||
      defaultCalorieNinjasKey.isNotEmpty;

  /// Application version definitions
  static const String appVersion = '1.3.0+5';
  static const String appVersionName = '1.3.0';
  static const int appBuildNumber = 5;
}
