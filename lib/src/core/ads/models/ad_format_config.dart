class AppOpenAdFormatConfig {
  const AppOpenAdFormatConfig({
    required this.enabled,
    required this.provider,
    required this.minimumBackgroundSeconds,
    required this.maximumPerDay,
  });

  const AppOpenAdFormatConfig.disabled()
    : enabled = false,
      provider = 'admob',
      minimumBackgroundSeconds = 30,
      maximumPerDay = 0;

  final bool enabled;
  final String provider;
  final int minimumBackgroundSeconds;
  final int maximumPerDay;
}

class BannerAdFormatConfig {
  const BannerAdFormatConfig({
    required this.enabled,
    required this.provider,
    required this.screens,
  });

  const BannerAdFormatConfig.disabled()
    : enabled = false,
      provider = 'admob',
      screens = const {};

  final bool enabled;
  final String provider;
  final Set<String> screens;
}

class InterstitialAdFormatConfig {
  const InterstitialAdFormatConfig({
    required this.enabled,
    required this.provider,
    required this.showEveryCompletedSessions,
    required this.minimumIntervalSeconds,
    required this.maximumPerDay,
  });

  const InterstitialAdFormatConfig.disabled()
    : enabled = false,
      provider = 'admob',
      showEveryCompletedSessions = 1,
      minimumIntervalSeconds = 0,
      maximumPerDay = 0;

  final bool enabled;
  final String provider;
  final int showEveryCompletedSessions;
  final int minimumIntervalSeconds;
  final int maximumPerDay;
}

class SimpleAdFormatConfig {
  const SimpleAdFormatConfig({required this.enabled, required this.provider});

  const SimpleAdFormatConfig.disabled() : enabled = false, provider = 'admob';

  final bool enabled;
  final String provider;
}
