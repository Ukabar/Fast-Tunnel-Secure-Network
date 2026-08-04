import 'dart:convert';

import 'package:fast_tunnel_network_test/src/core/ads/models/remote_ads_config.dart';
import 'package:fast_tunnel_network_test/src/core/ads/utils/ad_screen_ids.dart';
import 'package:fast_tunnel_network_test/src/core/ads/utils/google_test_ad_ids.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RemoteAdsConfig', () {
    test('parses valid JSON', () {
      final config = RemoteAdsConfig.fromJson(_validConfig());

      expect(config.adsEnabled, isTrue);
      expect(config.admob.enabled, isTrue);
      expect(config.banner.enabled, isTrue);
      expect(config.banner.screens, contains(AdScreenIds.locations));
      expect(config.interstitial.showEveryCompletedSessions, 4);
    });

    test('rejects invalid JSON root shape', () {
      expect(
        () =>
            RemoteAdsConfig.fromJson(jsonDecode('[]') as Map<String, Object?>),
        throwsA(isA<TypeError>()),
      );
    });

    test('rejects unsupported version', () {
      final json = _validConfig()..['version'] = 2;

      expect(
        () => RemoteAdsConfig.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects missing required fields', () {
      final json = _validConfig()..remove('formats');

      expect(
        () => RemoteAdsConfig.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('invalid AdMob ID disables affected format', () {
      final json = _validConfig();
      (json['admob']! as Map<String, Object?>)['banner_id'] = 'invalid';

      final config = RemoteAdsConfig.fromJson(json);

      expect(config.banner.enabled, isFalse);
      expect(config.interstitial.enabled, isTrue);
    });

    test('invalid provider disables affected format', () {
      final json = _validConfig();
      ((json['formats']! as Map<String, Object?>)['interstitial']!
              as Map<String, Object?>)['provider'] =
          'unknown';

      final config = RemoteAdsConfig.fromJson(json);

      expect(config.interstitial.enabled, isFalse);
      expect(config.banner.enabled, isTrue);
    });

    test('AppLovin provider stays unavailable', () {
      final json = _validConfig();
      ((json['formats']! as Map<String, Object?>)['banner']!
              as Map<String, Object?>)['provider'] =
          'applovin';

      final config = RemoteAdsConfig.fromJson(json);

      expect(config.banner.enabled, isFalse);
    });

    test('invalid banner screen names are ignored', () {
      final json = _validConfig();
      ((json['formats']! as Map<String, Object?>)['banner']!
          as Map<String, Object?>)['screens'] = [
        'home',
        'locations',
      ];

      final config = RemoteAdsConfig.fromJson(json);

      expect(config.banner.screens, {AdScreenIds.locations});
    });

    test('global kill switch disables all formats', () {
      final json = _validConfig()..['ads_enabled'] = false;

      final config = RemoteAdsConfig.fromJson(json);

      expect(config.anyAdsEnabled, isFalse);
      expect(config.banner.enabled, isFalse);
      expect(config.interstitial.enabled, isFalse);
    });

    test('malformed format values disable safely to minimum behavior', () {
      final json = _validConfig();
      ((json['formats']! as Map<String, Object?>)['interstitial']!
              as Map<String, Object?>)['minimum_interval_seconds'] =
          'bad';

      final config = RemoteAdsConfig.fromJson(json);

      expect(config.interstitial.enabled, isTrue);
      expect(config.interstitial.minimumIntervalSeconds, 0);
    });

    test('test mode uses official Google test IDs', () {
      final config = RemoteAdsConfig.fromJson(_validConfig());

      expect(
        config.adUnitIdFor(AdFormat.banner, effectiveTestMode: true),
        GoogleTestAdIds.androidBanner,
      );
      expect(
        config.adUnitIdFor(AdFormat.banner, effectiveTestMode: false),
        'ca-app-pub-1234567890123456/2222222222',
      );
    });
  });
}

Map<String, Object?> _validConfig() {
  return {
    'version': 1,
    'ads_enabled': true,
    'test_mode': false,
    'cache_duration_minutes': 360,
    'admob': {
      'enabled': true,
      'app_open_id': 'ca-app-pub-1234567890123456/1111111111',
      'banner_id': 'ca-app-pub-1234567890123456/2222222222',
      'interstitial_id': 'ca-app-pub-1234567890123456/3333333333',
      'native_id': 'ca-app-pub-1234567890123456/4444444444',
      'rewarded_id': 'ca-app-pub-1234567890123456/5555555555',
    },
    'applovin': {
      'enabled': false,
      'sdk_key': '',
      'banner_id': '',
      'app_open_id': '',
      'interstitial_id': '',
      'native_id': '',
      'rewarded_id': '',
    },
    'formats': {
      'app_open': {
        'enabled': false,
        'provider': 'admob',
        'minimum_background_seconds': 30,
        'maximum_per_day': 2,
      },
      'banner': {
        'enabled': true,
        'provider': 'admob',
        'screens': ['locations', 'history', 'settings'],
      },
      'interstitial': {
        'enabled': true,
        'provider': 'admob',
        'show_every_completed_sessions': 4,
        'minimum_interval_seconds': 180,
        'maximum_per_day': 5,
      },
      'native': {'enabled': false, 'provider': 'admob'},
      'rewarded': {'enabled': false, 'provider': 'admob'},
    },
  };
}
