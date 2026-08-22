import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../features/network_test/application/network_test_providers.dart';
import '../models/remote_ads_config.dart';
import '../providers/ad_providers.dart';
import 'ads_controller.dart';

class InterstitialAdDebugState {
  const InterstitialAdDebugState({
    required this.completedSessionCounter,
    required this.dailyCount,
    required this.lastShownAt,
  });

  final int completedSessionCounter;
  final int dailyCount;
  final DateTime? lastShownAt;
}

class InterstitialController extends AsyncNotifier<InterstitialAdDebugState> {
  static const _counterKey = 'ads_interstitial_completed_counter';
  static const _processedKey = 'ads_interstitial_processed_sessions';
  static const _lastShownKey = 'ads_interstitial_last_shown_ms';
  static const _dailyCountKey = 'ads_interstitial_daily_count';
  static const _dailyDateKey = 'ads_interstitial_daily_date';
  static const _maxProcessedIds = 80;

  SharedPreferences? _prefs;
  InterstitialAd? _loadedAd;
  Future<void>? _loadInProgress;

  @override
  Future<InterstitialAdDebugState> build() async {
    _prefs = await ref.watch(sharedPreferencesForAdsProvider.future);
    ref.onDispose(() {
      _loadedAd?.dispose();
      _loadedAd = null;
    });
    _resetDailyIfNeeded();
    await ref.watch(adsControllerProvider.future);
    unawaited(_preloadIfEligible());
    return _debugState();
  }

  Future<void> recordCompletedTest({required String testId}) {
    return _recordCompletedEvent(eventId: testId, canShow: true);
  }

  Future<void> recordCompletedSession({
    required String sessionId,
    required bool tunnelActive,
  }) {
    return _recordCompletedEvent(eventId: sessionId, canShow: !tunnelActive);
  }

  Future<void> _recordCompletedEvent({
    required String eventId,
    required bool canShow,
  }) async {
    final prefs = await _preferences();
    final processed = prefs.getStringList(_processedKey) ?? const [];
    if (processed.contains(eventId)) {
      _log('[ADS] Interstitial skipped: completion already processed.');
      return;
    }
    final nextProcessed = [...processed, eventId];
    final trimmed = nextProcessed.length > _maxProcessedIds
        ? nextProcessed.sublist(nextProcessed.length - _maxProcessedIds)
        : nextProcessed;
    await prefs.setStringList(_processedKey, trimmed);

    final counter = prefs.getInt(_counterKey) ?? 0;
    await prefs.setInt(_counterKey, counter + 1);
    state = AsyncData(_debugState());

    _log('[TEST] Network test completed: $eventId');
    if (canShow) {
      await _showIfEligible();
    } else {
      _log('[ADS] Interstitial skipped: another session is still active.');
    }
  }

  Future<void> _preloadIfEligible() async {
    final ads = ref
        .read(adsControllerProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    if (ads == null) {
      _log('[ADS] Interstitial preload skipped: configuration not ready.');
      return;
    }
    if (!ads.isFormatEnabled(AdFormat.interstitial)) {
      _log('[ADS] Interstitial preload skipped: format disabled.');
      return;
    }
    if (!ads.sdkInitialized) {
      _log('[ADS] Interstitial preload skipped: AdMob SDK unavailable.');
      return;
    }
    if (_loadedAd != null) {
      return;
    }
    final existingLoad = _loadInProgress;
    if (existingLoad != null) {
      await existingLoad;
      return;
    }

    final load = _loadInterstitial(ads);
    _loadInProgress = load;
    try {
      await load;
    } finally {
      if (identical(_loadInProgress, load)) {
        _loadInProgress = null;
      }
    }
  }

  Future<void> _loadInterstitial(AdsState ads) async {
    _log('[ADS] Loading interstitial...');
    try {
      _loadedAd = await ref
          .read(interstitialAdServiceProvider)
          .load(ads.adUnitIdFor(AdFormat.interstitial));
      _log('[ADS] Interstitial loaded.');
    } catch (error) {
      _log('[ADS] Interstitial failed to load: $error');
    }
  }

  Future<void> _showIfEligible() async {
    final ads = ref
        .read(adsControllerProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    if (ads == null || !ads.isFormatEnabled(AdFormat.interstitial)) {
      _log('[ADS] Interstitial skipped: format unavailable.');
      return;
    }
    final testProgress = ref
        .read(networkTestControllerProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    if (testProgress?.isRunning ?? false) {
      _log('[ADS] Interstitial skipped: network test is still running.');
      return;
    }
    final prefs = await _preferences();
    _resetDailyIfNeeded();
    final config = ads.config.interstitial;
    final counter = prefs.getInt(_counterKey) ?? 0;
    if (counter % config.showEveryCompletedSessions != 0) {
      _log(
        '[ADS] Interstitial skipped: frequency cap not reached '
        '($counter/${config.showEveryCompletedSessions} completed tests).',
      );
      return;
    }
    if ((prefs.getInt(_dailyCountKey) ?? 0) >= config.maximumPerDay) {
      _log('[ADS] Interstitial skipped: daily cap reached.');
      return;
    }
    final lastShownMs = prefs.getInt(_lastShownKey);
    if (lastShownMs != null &&
        DateTime.now()
                .difference(DateTime.fromMillisecondsSinceEpoch(lastShownMs))
                .inSeconds <
            config.minimumIntervalSeconds) {
      _log('[ADS] Interstitial skipped: cooldown is active.');
      return;
    }
    await _preloadIfEligible();
    final ad = _loadedAd;
    if (ad == null) {
      _log('[ADS] Interstitial unavailable after preload attempt.');
      return;
    }
    final coordinator = ref.read(fullScreenAdCoordinatorProvider);
    if (!coordinator.acquire()) {
      _log('[ADS] Interstitial skipped: another full-screen ad is active.');
      return;
    }
    _log('[ADS] Attempting to show interstitial.');
    _loadedAd = null;
    var released = false;
    void release() {
      if (released) return;
      released = true;
      coordinator.release();
      ad.dispose();
      _log('[ADS] Loading next interstitial.');
      unawaited(_preloadIfEligible());
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _log('[ADS] Interstitial shown.');
        unawaited(_recordShown(prefs));
      },
      onAdDismissedFullScreenContent: (_) {
        _log('[ADS] Interstitial dismissed.');
        release();
      },
      onAdFailedToShowFullScreenContent: (_, error) {
        _log('[ADS] Interstitial failed to show: $error');
        release();
      },
    );
    try {
      await ad.show();
    } catch (error) {
      _log('[ADS] Interstitial show threw an exception: $error');
      release();
    }
  }

  Future<void> _recordShown(SharedPreferences prefs) async {
    final now = DateTime.now();
    await prefs.setInt(_lastShownKey, now.millisecondsSinceEpoch);
    await prefs.setInt(_dailyCountKey, (prefs.getInt(_dailyCountKey) ?? 0) + 1);
    state = AsyncData(_debugState());
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

  InterstitialAdDebugState _debugState() {
    final prefs = _prefs;
    final lastShownMs = prefs?.getInt(_lastShownKey);
    return InterstitialAdDebugState(
      completedSessionCounter: prefs?.getInt(_counterKey) ?? 0,
      dailyCount: prefs?.getInt(_dailyCountKey) ?? 0,
      lastShownAt: lastShownMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastShownMs),
    );
  }

  String _dateKey(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }
}
