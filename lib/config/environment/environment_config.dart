import 'app_environment.dart';

class EnvironmentConfig {
  final AppEnvironment environment;

  const EnvironmentConfig({
    required this.environment,
  });

  factory EnvironmentConfig.development() {
    return const EnvironmentConfig(
      environment: AppEnvironment.development,
    );
  }

  factory EnvironmentConfig.staging() {
    return const EnvironmentConfig(
      environment: AppEnvironment.staging,
    );
  }

  factory EnvironmentConfig.production() {
    return const EnvironmentConfig(
      environment: AppEnvironment.production,
    );
  }

  bool get isDev => environment == AppEnvironment.development;
  bool get isStaging => environment == AppEnvironment.staging;
  bool get isProd => environment == AppEnvironment.production;
}
