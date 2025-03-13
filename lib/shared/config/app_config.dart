// lib/shared/config/app_config.dart

enum Flavor { dev, prod }

class AppConfig {
  final Flavor flavor;
  final String appName;
  final String apiBaseUrl;
  final bool enableAnalytics;
  final bool enableCrashlytics;
  final bool debugMode;

  static AppConfig? _instance;

  factory AppConfig({
    required Flavor flavor,
    required String appName,
    required String apiBaseUrl,
    bool enableAnalytics = true,
    bool enableCrashlytics = true,
  }) {
    _instance ??= AppConfig._internal(
      flavor: flavor,
      appName: appName,
      apiBaseUrl: apiBaseUrl,
      enableAnalytics: enableAnalytics,
      enableCrashlytics: enableCrashlytics,
      debugMode: flavor == Flavor.dev,
    );
    
    return _instance!;
  }

  AppConfig._internal({
    required this.flavor,
    required this.appName,
    required this.apiBaseUrl,
    required this.enableAnalytics,
    required this.enableCrashlytics,
    required this.debugMode,
  });

  static AppConfig get instance {
    if (_instance == null) {
      throw Exception("AppConfig has not been initialized");
    }
    return _instance!;
  }

  bool get isProduction => flavor == Flavor.prod;
  bool get isDevelopment => flavor == Flavor.dev;
}