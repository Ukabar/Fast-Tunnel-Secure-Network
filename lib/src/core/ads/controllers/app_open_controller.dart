import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../features/network_test/application/network_test_providers.dart';
import '../models/remote_ads_config.dart';
import '../providers/ad_providers.dart';

class AppOpenAdDebugState {
  const AppOpenAdDebugState({required this.dailyCount});

  final int dailyCount;
}

class AppOpenController extends AsyncNotifier<AppOpenAdDebugState> {
  static const _dailyCountKey = 'ads_app_open_daily_count';
  static const _dailyDateKey = 'ads_app_open_daily_date';

  SharedPreferences? _prefs;
  AppOpenAd? _loadedAd;
  DateTime? _backgroundedAt;
  var _hasColdLaunched = false;
  var _loading = false;

  @override
  Future<AppOpenAdDebugState> build() async {
    _prefs = await ref.watch(sharedPreferencesForAdsProvider.future);
    _hasColdLaunched = true;
    ref.onDispose(() => _loadedAd?.dispose());
    _resetDailyIfNeeded();
    return _debugState();
  }

  void onBackgrounded() {
    _backgroundedAt = DateTime.now();
  }

  Future<void> onResumed() async {
    if (!_hasColdLaunched || _backgroundedAt == null) return;
    final ads = ref
        .read(adsControllerProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    if (ads == null || !ads.isFormatEnabled(AdFormat.appOpen)) return;
    final backgroundDuration = DateTime.now().difference(_backgroundedAt!);
    _backgroundedAt = null;
    if (backgroundDuration.inSeconds <
        ads.config.appOpen.minimumBackgroundSeconds) {
      return;
    }
    final testProgress = ref
        .read(networkTestControllerProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    if (testProgress?.isRunning ?? false) {
      return;
    }
    final prefs = await _preferences();
    _resetDailyIfNeeded();
    if ((prefs.getInt(_dailyCountKey) ?? 0) >=
        ads.config.appOpen.maximumPerDay) {
      return;
    }
    await _preloadIfEligible();
    final ad = _loadedAd;
    if (ad == null) return;
    final coordinator = ref.read(fullScreenAdCoordinatorProvider);
    if (!coordinator.acquire()) return;
    _loadedAd = null;
    var released = false;
    void release() {
      if (released) return;
      released = true;
      coordinator.release();
      ad.dispose();
      unawaited(_preloadIfEligible());
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) => release(),
      onAdFailedToShowFullScreenContent: (_, error) => release(),
    );
    try {
      await ad.show();
      await prefs.setInt(
        _dailyCountKey,
        (prefs.getInt(_dailyCountKey) ?? 0) + 1,
      );
      state = AsyncData(_debugState());
    } catch (_) {
      release();
    }
  }

  Future<void> _preloadIfEligible() async {
    final ads = ref
        .read(adsControllerProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    if (ads == null ||
        !ads.isFormatEnabled(AdFormat.appOpen) ||
        !ads.sdkInitialized ||
        _loadedAd != null ||
        _loading) {
      return;
    }
    _loading = true;
    try {
      _loadedAd = await ref
          .read(appOpenAdServiceProvider)
          .load(ads.adUnitIdFor(AdFormat.appOpen));
    } catch (_) {
      if (kDebugMode) debugPrint('App Open preload failed.');
    } finally {
      _loading = false;
    }
  }

  Future<SharedPreferences> _preferences() async {
    final existing = _prefs;
    if (existing != null) return existing;
    final loaded = await ref.read(sharedPreferencesForAdsProvider.future);
    _prefs = loaded;
    return loaded;
  }

  void _resetDailyIfNeeded() {
    final prefs = _prefs;
    if (prefs == null) return;
    final today = _dateKey(DateTime.now());
    if (prefs.getString(_dailyDateKey) != today) {
      prefs.setString(_dailyDateKey, today);
      prefs.setInt(_dailyCountKey, 0);
    }
  }

  AppOpenAdDebugState _debugState() {
    return AppOpenAdDebugState(dailyCount: _prefs?.getInt(_dailyCountKey) ?? 0);
  }

  String _dateKey(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }
}
