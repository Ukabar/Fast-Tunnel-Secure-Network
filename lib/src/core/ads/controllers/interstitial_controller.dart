import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../features/tunnel/application/tunnel_providers.dart';
import '../../../features/tunnel/domain/tunnel_service.dart';
import '../models/remote_ads_config.dart';
import '../providers/ad_providers.dart';

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
  var _loading = false;

  @override
  Future<InterstitialAdDebugState> build() async {
    _prefs = await ref.watch(sharedPreferencesForAdsProvider.future);
    ref.onDispose(() {
      _loadedAd?.dispose();
      _loadedAd = null;
    });
    _resetDailyIfNeeded();
    unawaited(_preloadIfEligible());
    return _debugState();
  }

  Future<void> recordCompletedSession({
    required String sessionId,
    required bool tunnelActive,
  }) async {
    final prefs = await _preferences();
    final processed = prefs.getStringList(_processedKey) ?? const [];
    if (processed.contains(sessionId)) return;
    final nextProcessed = [...processed, sessionId];
    final trimmed = nextProcessed.length > _maxProcessedIds
        ? nextProcessed.sublist(nextProcessed.length - _maxProcessedIds)
        : nextProcessed;
    await prefs.setStringList(_processedKey, trimmed);

    final counter = prefs.getInt(_counterKey) ?? 0;
    await prefs.setInt(_counterKey, counter + 1);
    state = AsyncData(_debugState());

    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!tunnelActive) {
      await _showIfEligible();
    }
  }

  Future<void> _preloadIfEligible() async {
    final ads = ref
        .read(adsControllerProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    if (ads == null ||
        !ads.isFormatEnabled(AdFormat.interstitial) ||
        !ads.sdkInitialized ||
        _loadedAd != null ||
        _loading) {
      return;
    }
    _loading = true;
    try {
      _loadedAd = await ref
          .read(interstitialAdServiceProvider)
          .load(ads.adUnitIdFor(AdFormat.interstitial));
    } catch (_) {
      if (kDebugMode) debugPrint('Interstitial preload failed.');
    } finally {
      _loading = false;
    }
  }

  Future<void> _showIfEligible() async {
    final ads = ref
        .read(adsControllerProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    if (ads == null || !ads.isFormatEnabled(AdFormat.interstitial)) return;
    final tunnel = ref.read(tunnelServiceProvider).current;
    if (tunnel.status == TunnelStatus.preparing ||
        tunnel.status == TunnelStatus.connecting ||
        tunnel.status == TunnelStatus.connected ||
        tunnel.status == TunnelStatus.disconnecting) {
      return;
    }
    final prefs = await _preferences();
    _resetDailyIfNeeded();
    final config = ads.config.interstitial;
    final counter = prefs.getInt(_counterKey) ?? 0;
    if (counter % config.showEveryCompletedSessions != 0) return;
    if ((prefs.getInt(_dailyCountKey) ?? 0) >= config.maximumPerDay) return;
    final lastShownMs = prefs.getInt(_lastShownKey);
    if (lastShownMs != null &&
        DateTime.now()
                .difference(DateTime.fromMillisecondsSinceEpoch(lastShownMs))
                .inSeconds <
            config.minimumIntervalSeconds) {
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
      final now = DateTime.now();
      await prefs.setInt(_lastShownKey, now.millisecondsSinceEpoch);
      await prefs.setInt(
        _dailyCountKey,
        (prefs.getInt(_dailyCountKey) ?? 0) + 1,
      );
      state = AsyncData(_debugState());
    } catch (_) {
      release();
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
}
