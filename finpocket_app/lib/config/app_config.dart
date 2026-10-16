import 'package:flutter/foundation.dart' show kIsWeb;

enum AppEnvironment {
  development,
  test,
  demo,
  staging,
  production,
}

enum LogLevel {
  debug,
  info,
  warn,
  error,
}

class AppConfig {
  /// Environment baked in at build/run time — never edited in source:
  ///
  /// ```sh
  /// flutter run --dart-define=FINPOCKET_ENV=development   # default
  /// flutter build apk --dart-define=FINPOCKET_ENV=production
  /// ```
  /// Accepts: development, test, demo, staging, production.
  static AppEnvironment environment =
      _parseEnvironment(const String.fromEnvironment('FINPOCKET_ENV', defaultValue: 'development'));

  static AppEnvironment _parseEnvironment(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'production':
        return AppEnvironment.production;
      case 'staging':
        return AppEnvironment.staging;
      case 'test':
        return AppEnvironment.test;
      case 'demo':
        return AppEnvironment.demo;
      case 'development':
        return AppEnvironment.development;
      default:
        // Unknown values fall back to development (never silently "production"):
        // a typo must not switch on production-only fail-closed checks.
        return AppEnvironment.development;
    }
  }

  static String? customApiBaseUrl;

  /// Host override for the dev backend, set at build/run time without editing
  /// source:
  ///
  /// ```sh
  /// # Android emulator (host loopback):
  /// flutter run --dart-define=FINPOCKET_API_HOST=10.0.2.2
  /// # Physical device on the same LAN:
  /// flutter run --dart-define=FINPOCKET_API_HOST=192.168.1.7
  /// # Default — requires `adb reverse tcp:3001 tcp:3001`
  /// flutter run
  /// ```
  static const String apiHostOverride =
      String.fromEnvironment('FINPOCKET_API_HOST');

  // Environment checks
  static bool get isProduction => environment == AppEnvironment.production;
  static bool get isStaging => environment == AppEnvironment.staging;
  static bool get isDemo => environment == AppEnvironment.demo;
  static bool get isTest => environment == AppEnvironment.test;
  static bool get isDevelopment => environment == AppEnvironment.development;

  /// In production, demo auto-login or fallback is strictly prohibited (fails closed)
  static bool get allowDemoAutoLogin => (environment == AppEnvironment.demo || environment == AppEnvironment.development) && !isProduction;

  /// Fail-closed production check for local URLs
  static String get apiBaseUrl {
    // 1. Runtime override (host discovery stores COMPLETE base URLs such as
    //    `http://host:3001/api/v1`) — returned exactly as stored.
    if (customApiBaseUrl != null && customApiBaseUrl!.isNotEmpty) {
      if (isProduction && _isLoopbackLike(customApiBaseUrl!)) {
        throw StateError('Production build cannot connect to localhost or internal loopback IP addresses.');
      }
      return customApiBaseUrl!;
    }

    // 2. Build-time override (`--dart-define=FINPOCKET_API_HOST`) wins in
    //    EVERY environment, so release builds can point at any deployed
    //    backend without touching source. Production still refuses loopback.
    if (apiHostOverride.isNotEmpty) {
      if (isProduction && _isLoopbackLike(apiHostOverride)) {
        throw StateError('Production build cannot connect to localhost or internal loopback IP addresses.');
      }
      if (apiHostOverride.startsWith('http://') || apiHostOverride.startsWith('https://')) {
        // A full URL baked in at build time (`https://api.example.com`) is
        // used as-is: cloud backends serve TLS on 443 rather than plain :3001.
        return '${apiHostOverride.replaceAll(RegExp(r'/+$'), '')}/api/v1';
      }
      // Bare hostnames keep the dev convention.
      return 'http://$apiHostOverride:3001/api/v1';
    }

    // 3. Environment defaults.
    switch (environment) {
      case AppEnvironment.production:
        return 'https://api.finpocket.com/api/v1';
      case AppEnvironment.staging:
        return 'https://staging-api.finpocket.com/api/v1';
      case AppEnvironment.development:
      case AppEnvironment.demo:
      case AppEnvironment.test:
        if (kIsWeb) return 'http://localhost:3001/api/v1';
        return 'http://127.0.0.1:3001/api/v1';
    }
  }

  static bool _isLoopbackLike(String url) =>
      url.contains('localhost') || url.contains('127.0.0.1') || url.contains('10.0.2.2');

  // Feature Flags
  static bool featureGoogleSso = true;
  static bool featureFinancialTwin = true;
  static bool featureSpendGuard = true;
  static bool featureReceiptScanner = true;
  static bool featureSubscriptionIntelligence = true;
  static bool featureFamilySpaces = true;
  static bool featureFinancialEmergencyMode = true;
  static bool featureAiCopilot = true;
  static bool featureAnomalyRadar = true;
  static bool featureGoalAutopilot = true;

  // Logging level
  static LogLevel get loggingLevel {
    if (isProduction) return LogLevel.warn;
    return LogLevel.debug;
  }
}
