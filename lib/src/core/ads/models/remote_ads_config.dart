import 'package:flutter/foundation.dart';

import 'ad_format_config.dart';
import '../utils/ad_id_validator.dart';
import '../utils/ad_screen_ids.dart';
import '../utils/google_test_ad_ids.dart';

enum AdFormat { appOpen, banner, interstitial, native, rewarded }

class AdMobConfig {
  const AdMobConfig({
    required this.enabled,
    required this.appOpenId,
    required this.bannerId,
    required this.interstitialId,
    required this.nativeId,
    required this.rewardedId,
  });

  const AdMobConfig.disabled()
    : enabled = false,
      appOpenId = '',
      bannerId = '',
      interstitialId = '',
      nativeId = '',
      rewardedId = '';

  final bool enabled;
  final String appOpenId;
  final String bannerId;
  final String interstitialId;
  final String nativeId;
  final String rewardedId;

  String idFor(AdFormat format, {required bool effectiveTestMode}) {
    if (effectiveTestMode) {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return switch (format) {
          AdFormat.appOpen => GoogleTestAdIds.iosAppOpen,
          AdFormat.banner => GoogleTestAdIds.iosBanner,
          AdFormat.interstitial => GoogleTestAdIds.iosInterstitial,
          AdFormat.native => GoogleTestAdIds.iosNative,
          AdFormat.rewarded => GoogleTestAdIds.iosRewarded,
        };
      }
      return switch (format) {
        AdFormat.appOpen => GoogleTestAdIds.androidAppOpen,
        AdFormat.banner => GoogleTestAdIds.androidBanner,
        AdFormat.interstitial => GoogleTestAdIds.androidInterstitial,
        AdFormat.native => GoogleTestAdIds.androidNative,
        AdFormat.rewarded => GoogleTestAdIds.androidRewarded,
      };
    }
    return switch (format) {
      AdFormat.appOpen => appOpenId,
      AdFormat.banner => bannerId,
      AdFormat.interstitial => interstitialId,
      AdFormat.native => nativeId,
      AdFormat.rewarded => rewardedId,
    };
  }
}

class AppLovinConfig {
  const AppLovinConfig({
    required this.enabled,
    required this.sdkKey,
    required this.bannerId,
    required this.appOpenId,
    required this.interstitialId,
    required this.nativeId,
    required this.rewardedId,
  });

  const AppLovinConfig.disabled()
    : enabled = false,
      sdkKey = '',
      bannerId = '',
      appOpenId = '',
      interstitialId = '',
      nativeId = '',
      rewardedId = '';

  final bool enabled;
  final String sdkKey;
  final String bannerId;
  final String appOpenId;
  final String interstitialId;
  final String nativeId;
  final String rewardedId;
}

class RemoteAdsConfig {
  const RemoteAdsConfig({
    required this.version,
    required this.adsEnabled,
    required this.testMode,
    required this.cacheDurationMinutes,
    required this.admob,
    required this.applovin,
    required this.appOpen,
    required this.banner,
    required this.interstitial,
    required this.native,
    required this.rewarded,
  });

  const RemoteAdsConfig.disabled()
    : version = 1,
      adsEnabled = false,
      testMode = true,
      cacheDurationMinutes = 360,
      admob = const AdMobConfig.disabled(),
      applovin = const AppLovinConfig.disabled(),
      appOpen = const AppOpenAdFormatConfig.disabled(),
      banner = const BannerAdFormatConfig.disabled(),
      interstitial = const InterstitialAdFormatConfig.disabled(),
      native = const SimpleAdFormatConfig.disabled(),
      rewarded = const SimpleAdFormatConfig.disabled();

  final int version;
  final bool adsEnabled;
  final bool testMode;
  final int cacheDurationMinutes;
  final AdMobConfig admob;
  final AppLovinConfig applovin;
  final AppOpenAdFormatConfig appOpen;
  final BannerAdFormatConfig banner;
  final InterstitialAdFormatConfig interstitial;
  final SimpleAdFormatConfig native;
  final SimpleAdFormatConfig rewarded;

  bool get anyAdsEnabled {
    return adsEnabled &&
        admob.enabled &&
        (appOpen.enabled ||
            banner.enabled ||
            interstitial.enabled ||
            native.enabled ||
            rewarded.enabled);
  }

  bool isFormatEnabled(AdFormat format) {
    if (!adsEnabled || !admob.enabled) return false;
    return switch (format) {
      AdFormat.appOpen => appOpen.enabled,
      AdFormat.banner => banner.enabled,
      AdFormat.interstitial => interstitial.enabled,
      AdFormat.native => native.enabled,
      AdFormat.rewarded => rewarded.enabled,
    };
  }

  String adUnitIdFor(AdFormat format, {required bool effectiveTestMode}) {
    return admob.idFor(format, effectiveTestMode: effectiveTestMode);
  }

  static RemoteAdsConfig fromJson(Map<String, Object?> json) {
    if (json['version'] != 1) {
      throw const FormatException('Unsupported ads config version.');
    }
    final cacheMinutes = _requiredIntInRange(
      json['cache_duration_minutes'],
      5,
      1440,
    );
    final admob = _parseAdMob(json['admob']);
    final applovin = _parseAppLovin(json['applovin']);
    final formats = json['formats'];
    if (formats is! Map<String, Object?>) {
      throw const FormatException('Missing formats.');
    }

    final adsEnabled = json['ads_enabled'] == true;
    final testMode = json['test_mode'] == true;

    var appOpen = _parseAppOpen(formats['app_open'], admob);
    var banner = _parseBanner(formats['banner'], admob);
    var interstitial = _parseInterstitial(formats['interstitial'], admob);
    var native = _parseSimple(formats['native'], admob, AdFormat.native);
    var rewarded = _parseSimple(formats['rewarded'], admob, AdFormat.rewarded);

    if (!adsEnabled || !admob.enabled) {
      appOpen = const AppOpenAdFormatConfig.disabled();
      banner = const BannerAdFormatConfig.disabled();
      interstitial = const InterstitialAdFormatConfig.disabled();
      native = const SimpleAdFormatConfig.disabled();
      rewarded = const SimpleAdFormatConfig.disabled();
    }

    return RemoteAdsConfig(
      version: 1,
      adsEnabled: adsEnabled,
      testMode: testMode,
      cacheDurationMinutes: cacheMinutes,
      admob: admob,
      applovin: applovin,
      appOpen: appOpen,
      banner: banner,
      interstitial: interstitial,
      native: native,
      rewarded: rewarded,
    );
  }

  static AdMobConfig _parseAdMob(Object? value) {
    if (value is! Map<String, Object?>) return const AdMobConfig.disabled();
    return AdMobConfig(
      enabled: value['enabled'] == true,
      appOpenId: _string(value['app_open_id']),
      bannerId: _string(value['banner_id']),
      interstitialId: _string(value['interstitial_id']),
      nativeId: _string(value['native_id']),
      rewardedId: _string(value['rewarded_id']),
    );
  }

  static AppLovinConfig _parseAppLovin(Object? value) {
    if (value is! Map<String, Object?>) return const AppLovinConfig.disabled();
    return AppLovinConfig(
      enabled: value['enabled'] == true,
      sdkKey: _string(value['sdk_key']),
      bannerId: _string(value['banner_id']),
      appOpenId: _string(value['app_open_id']),
      interstitialId: _string(value['interstitial_id']),
      nativeId: _string(value['native_id']),
      rewardedId: _string(value['rewarded_id']),
    );
  }

  static AppOpenAdFormatConfig _parseAppOpen(Object? value, AdMobConfig admob) {
    if (value is! Map<String, Object?>) {
      return const AppOpenAdFormatConfig.disabled();
    }
    final provider = _string(value['provider'], fallback: 'admob');
    final enabled = value['enabled'] == true;
    if (!enabled ||
        provider != 'admob' ||
        !isValidProvider(provider) ||
        !isValidAdMobAdUnitId(admob.appOpenId)) {
      return AppOpenAdFormatConfig(
        enabled: false,
        provider: provider,
        minimumBackgroundSeconds: 30,
        maximumPerDay: 0,
      );
    }
    return AppOpenAdFormatConfig(
      enabled: true,
      provider: provider,
      minimumBackgroundSeconds: _intInRange(
        value['minimum_background_seconds'],
        0,
        86400,
      ),
      maximumPerDay: _intInRange(value['maximum_per_day'], 0, 50),
    );
  }

  static BannerAdFormatConfig _parseBanner(Object? value, AdMobConfig admob) {
    if (value is! Map<String, Object?>) {
      return const BannerAdFormatConfig.disabled();
    }
    final provider = _string(value['provider'], fallback: 'admob');
    final enabled = value['enabled'] == true;
    final rawScreens = value['screens'];
    final screens = rawScreens is List
        ? rawScreens
              .whereType<String>()
              .where(AdScreenIds.supportedBannerScreens.contains)
              .toSet()
        : <String>{};
    if (!enabled ||
        provider != 'admob' ||
        !isValidProvider(provider) ||
        screens.isEmpty ||
        !isValidAdMobAdUnitId(admob.bannerId)) {
      return BannerAdFormatConfig(
        enabled: false,
        provider: provider,
        screens: screens,
      );
    }
    return BannerAdFormatConfig(
      enabled: true,
      provider: provider,
      screens: screens,
    );
  }

  static InterstitialAdFormatConfig _parseInterstitial(
    Object? value,
    AdMobConfig admob,
  ) {
    if (value is! Map<String, Object?>) {
      return const InterstitialAdFormatConfig.disabled();
    }
    final provider = _string(value['provider'], fallback: 'admob');
    final enabled = value['enabled'] == true;
    if (!enabled ||
        provider != 'admob' ||
        !isValidProvider(provider) ||
        !isValidAdMobAdUnitId(admob.interstitialId)) {
      return InterstitialAdFormatConfig(
        enabled: false,
        provider: provider,
        showEveryCompletedSessions: 1,
        minimumIntervalSeconds: 0,
        maximumPerDay: 0,
      );
    }
    return InterstitialAdFormatConfig(
      enabled: true,
      provider: provider,
      showEveryCompletedSessions: _intInRange(
        value['show_every_completed_sessions'],
        1,
        50,
      ),
      minimumIntervalSeconds: _intInRange(
        value['minimum_interval_seconds'],
        0,
        86400,
      ),
      maximumPerDay: _intInRange(value['maximum_per_day'], 0, 50),
    );
  }

  static SimpleAdFormatConfig _parseSimple(
    Object? value,
    AdMobConfig admob,
    AdFormat format,
  ) {
    if (value is! Map<String, Object?>) {
      return const SimpleAdFormatConfig.disabled();
    }
    final provider = _string(value['provider'], fallback: 'admob');
    final enabled = value['enabled'] == true;
    final id = switch (format) {
      AdFormat.native => admob.nativeId,
      AdFormat.rewarded => admob.rewardedId,
      _ => '',
    };
    if (!enabled ||
        provider != 'admob' ||
        !isValidProvider(provider) ||
        !isValidAdMobAdUnitId(id)) {
      return SimpleAdFormatConfig(enabled: false, provider: provider);
    }
    return SimpleAdFormatConfig(enabled: true, provider: provider);
  }

  static int _requiredIntInRange(Object? value, int min, int max) {
    if (value is! int || value < min || value > max) {
      throw FormatException('Expected integer between $min and $max.');
    }
    return value;
  }

  static int _intInRange(Object? value, int min, int max) {
    if (value is! int || value < min || value > max) {
      return min;
    }
    return value;
  }

  static String _string(Object? value, {String fallback = ''}) {
    return value is String ? value.trim() : fallback;
  }
}
