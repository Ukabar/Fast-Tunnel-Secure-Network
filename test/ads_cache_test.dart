import 'dart:convert';

import 'package:fast_tunnel_network_test/src/core/ads/data/cached_ads_config_repository.dart';
import 'package:fast_tunnel_network_test/src/core/ads/data/remote_ads_config_repository.dart';
import 'package:fast_tunnel_network_test/src/core/ads/models/remote_ads_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('CachedAdsConfigRepository', () {
    test('uses valid cache immediately', () async {
      final now = DateTime(2026, 8, 3, 12);
      SharedPreferences.setMockInitialValues(_cacheValues(now));
      final prefs = await SharedPreferences.getInstance();
      final repository = CachedAdsConfigRepository(
        preferences: prefs,
        now: () => now,
      );

      final cached = await repository.loadCached();

      expect(cached, isNotNull);
      expect(cached!.fromCache, isTrue);
      expect(cached.config.banner.enabled, isTrue);
    });

    test('expired cache within seven days is still usable', () async {
      final now = DateTime(2026, 8, 3, 12);
      SharedPreferences.setMockInitialValues(
        _cacheValues(now.subtract(const Duration(hours: 8))),
      );
      final prefs = await SharedPreferences.getInstance();
      final repository = CachedAdsConfigRepository(
        preferences: prefs,
        now: () => now,
      );

      final cached = await repository.loadCached();

      expect(cached, isNotNull);
    });

    test('seven-day stale cache is ignored', () async {
      final now = DateTime(2026, 8, 3, 12);
      SharedPreferences.setMockInitialValues(
        _cacheValues(now.subtract(const Duration(days: 8))),
      );
      final prefs = await SharedPreferences.getInstance();
      final repository = CachedAdsConfigRepository(
        preferences: prefs,
        now: () => now,
      );

      expect(await repository.loadCached(), isNull);
    });

    test('remote refresh can replace cache', () async {
      final now = DateTime(2026, 8, 3, 12);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final remote = _FakeRemoteRepository(
        config: RemoteAdsConfig.fromJson(_validConfig()),
        rawJson: jsonEncode(_validConfig()),
      );
      final repository = CachedAdsConfigRepository(
        preferences: prefs,
        remote: remote,
        now: () => now,
      );

      final result = await repository.fetchRemoteWithJson();
      await repository.save(result.snapshot, result.rawJson);

      expect((await repository.loadCached())!.config.anyAdsEnabled, isTrue);
    });

    test('failed refresh preserves valid cache', () async {
      final now = DateTime(2026, 8, 3, 12);
      SharedPreferences.setMockInitialValues(_cacheValues(now));
      final prefs = await SharedPreferences.getInstance();
      final repository = CachedAdsConfigRepository(
        preferences: prefs,
        remote: _FakeRemoteRepository(error: StateError('offline')),
        now: () => now,
      );

      expect(repository.fetchRemoteWithJson(), throwsStateError);
      expect((await repository.loadCached())!.config.banner.enabled, isTrue);
    });
  });
}

class _FakeRemoteRepository extends RemoteAdsConfigRepository {
  _FakeRemoteRepository({this.config, this.rawJson, this.error})
    : super(endpoint: 'https://example.com/ads_config.json');

  final RemoteAdsConfig? config;
  final String? rawJson;
  final Object? error;

  @override
  Future<({RemoteAdsConfig config, String rawJson, String source})>
  fetch() async {
    final failure = error;
    if (failure != null) throw failure;
    return (
      config: config!,
      rawJson: rawJson!,
      source: 'https://example.com/ads_config.json',
    );
  }
}

Map<String, Object> _cacheValues(DateTime lastRefresh) {
  return {
    'ads_config_last_valid_json': jsonEncode(_validConfig()),
    'ads_config_last_success_ms': lastRefresh.millisecondsSinceEpoch,
    'ads_config_expires_ms': lastRefresh
        .add(const Duration(hours: 6))
        .millisecondsSinceEpoch,
    'ads_config_source': 'https://example.com/ads_config.json',
  };
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
