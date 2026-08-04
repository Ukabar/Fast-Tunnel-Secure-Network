import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ads_config_repository.dart';
import '../models/remote_ads_config.dart';
import '../utils/google_test_ad_ids.dart';
import '../providers/ad_providers.dart';

class AdsState {
  const AdsState({
    required this.config,
    required this.source,
    required this.lastRefresh,
    required this.expiresAt,
    required this.fromCache,
    required this.sdkInitialized,
    this.lastRefreshFailed = false,
  });

  factory AdsState.disabled() {
    return const AdsState(
      config: RemoteAdsConfig.disabled(),
      source: 'disabled',
      lastRefresh: null,
      expiresAt: null,
      fromCache: false,
      sdkInitialized: false,
    );
  }

  final RemoteAdsConfig config;
  final String source;
  final DateTime? lastRefresh;
  final DateTime? expiresAt;
  final bool fromCache;
  final bool sdkInitialized;
  final bool lastRefreshFailed;

  bool get effectiveTestMode => kDebugMode || config.testMode;

  bool get adsEnabled => config.anyAdsEnabled;

  String adUnitIdFor(AdFormat format) {
    return config.adUnitIdFor(format, effectiveTestMode: effectiveTestMode);
  }

  bool isFormatEnabled(AdFormat format) => config.isFormatEnabled(format);

  bool isBannerEnabledFor(String screenId) {
    return isFormatEnabled(AdFormat.banner) &&
        config.banner.screens.contains(screenId);
  }

  List<String> get enabledFormatLabels {
    final labels = <String>[];
    if (isFormatEnabled(AdFormat.appOpen)) labels.add('App Open');
    if (isFormatEnabled(AdFormat.banner)) labels.add('Banner');
    if (isFormatEnabled(AdFormat.interstitial)) labels.add('Interstitial');
    if (isFormatEnabled(AdFormat.native)) labels.add('Native');
    if (isFormatEnabled(AdFormat.rewarded)) labels.add('Rewarded');
    return labels;
  }

  AdsState copyWith({
    RemoteAdsConfig? config,
    String? source,
    DateTime? lastRefresh,
    DateTime? expiresAt,
    bool? fromCache,
    bool? sdkInitialized,
    bool? lastRefreshFailed,
  }) {
    return AdsState(
      config: config ?? this.config,
      source: source ?? this.source,
      lastRefresh: lastRefresh ?? this.lastRefresh,
      expiresAt: expiresAt ?? this.expiresAt,
      fromCache: fromCache ?? this.fromCache,
      sdkInitialized: sdkInitialized ?? this.sdkInitialized,
      lastRefreshFailed: lastRefreshFailed ?? this.lastRefreshFailed,
    );
  }
}

class AdsController extends AsyncNotifier<AdsState> {
  @override
  Future<AdsState> build() async {
    final repository = await ref.watch(adsConfigRepositoryProvider.future);
    final initializer = ref.watch(mobileAdsInitializerProvider);
    final sdkInitialized = await initializer.initialize();
    final cached = await repository.loadCached();
    final initial = cached == null
        ? AdsState.disabled().copyWith(sdkInitialized: sdkInitialized)
        : _fromSnapshot(cached, sdkInitialized: sdkInitialized);
    unawaited(refreshRemote());
    return initial;
  }

  Future<void> refreshRemote() async {
    try {
      final repository = await ref.read(adsConfigRepositoryProvider.future);
      final result = await repository.fetchRemoteWithJson();
      await repository.save(result.snapshot, result.rawJson);
      final sdkInitialized = await ref
          .read(mobileAdsInitializerProvider)
          .initialize();
      state = AsyncData(
        _fromSnapshot(result.snapshot, sdkInitialized: sdkInitialized),
      );
    } catch (_) {
      final current = state.maybeWhen(
        data: (value) => value,
        orElse: AdsState.disabled,
      );
      state = AsyncData(current.copyWith(lastRefreshFailed: true));
    }
  }

  AdsState _fromSnapshot(
    AdsConfigSnapshot snapshot, {
    required bool sdkInitialized,
  }) {
    return AdsState(
      config: snapshot.config,
      source: snapshot.source,
      lastRefresh: snapshot.lastRefresh,
      expiresAt: snapshot.expiresAt,
      fromCache: snapshot.fromCache,
      sdkInitialized: sdkInitialized,
    );
  }
}

String adUnitForTestFallback(AdFormat format) {
  return switch (format) {
    AdFormat.appOpen => GoogleTestAdIds.androidAppOpen,
    AdFormat.banner => GoogleTestAdIds.androidBanner,
    AdFormat.interstitial => GoogleTestAdIds.androidInterstitial,
    AdFormat.native => GoogleTestAdIds.androidNative,
    AdFormat.rewarded => GoogleTestAdIds.androidRewarded,
  };
}
