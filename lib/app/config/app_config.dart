enum Environment { development, staging, production }

class AppConfig {
  AppConfig._();

  static const String appName = 'CarrierDirect Driver';
  static const String appVersion = '1.0.0';
  static const Environment environment = Environment.development;

  static bool get isDev => environment == Environment.development;
  static bool get isProd => environment == Environment.production;
}
