import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/remote_ads_config.dart';
import '../utils/ad_screen_ids.dart';
import '../utils/google_test_ad_ids.dart';
import 'ads_config_repository.dart';

class EmbeddedAdsConfigRepository implements AdsConfigRepository {
  EmbeddedAdsConfigRepository({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  @override
  Future<AdsConfigSnapshot?> loadCached() async => _snapshot(fromCache: false);

  @override
  Future<AdsConfigSnapshot> fetchRemote() async => _snapshot(fromCache: false);

  @override
  Future<AdsConfigFetchResult> fetchRemoteWithJson() async {
    final snapshot = _snapshot(fromCache: false);
    return AdsConfigFetchResult(
      snapshot: snapshot,
      rawJson: jsonEncode(_embeddedAdsConfigJson),
    );
  }

  @override
  Future<void> save(AdsConfigSnapshot snapshot, String rawJson) async {}

  AdsConfigSnapshot _snapshot({required bool fromCache}) {
    final now = _now();
    return AdsConfigSnapshot(
      config: RemoteAdsConfig.fromJson(_embeddedAdsConfigJson),
      source: 'embedded',
      lastRefresh: now,
      expiresAt: null,
      fromCache: fromCache,
    );
  }
}

Map<String, Object?> get _embeddedAdsConfigJson {
  final ios = defaultTargetPlatform == TargetPlatform.iOS;
  return {
    'version': 1,
    'ads_enabled': true,
    'test_mode': !ios,
    'cache_duration_minutes': 360,
    'admob': {
      'enabled': true,
      'app_open_id': ios
          ? 'ca-app-pub-7416708332505708/6203802459'
          : GoogleTestAdIds.androidAppOpen,
      'banner_id': ios
          ? 'ca-app-pub-7416708332505708/7648746066'
          : GoogleTestAdIds.androidBanner,
      'interstitial_id': ios
          ? 'ca-app-pub-7416708332505708/4511446833'
          : GoogleTestAdIds.androidInterstitial,
      'native_id': ios
          ? 'ca-app-pub-7416708332505708/7516884120'
          : GoogleTestAdIds.androidNative,
      'rewarded_id': ios
          ? 'ca-app-pub-7416708332505708/3577639114'
          : GoogleTestAdIds.androidRewarded,
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
        'enabled': true,
        'provider': 'admob',
        'minimum_background_seconds': 30,
        'maximum_per_day': 2,
      },
      'banner': {
        'enabled': true,
        'provider': 'admob',
        'screens': [
          AdScreenIds.home,
          AdScreenIds.history,
          AdScreenIds.settings,
        ],
      },
      'interstitial': {
        'enabled': true,
        'provider': 'admob',
        'show_every_completed_sessions': 3,
        'minimum_interval_seconds': 180,
        'maximum_per_day': 5,
      },
      'native': {'enabled': false, 'provider': 'admob'},
      'rewarded': {'enabled': false, 'provider': 'admob'},
    },
  };
}
