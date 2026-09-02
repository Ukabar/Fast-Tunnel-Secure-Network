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
    required this.adsCanBeRequested,
    required this.privacyOptionsRequired,
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
      adsCanBeRequested: false,
      privacyOptionsRequired: false,
    );
  }

  final RemoteAdsConfig config;
  final String source;
  final DateTime? lastRefresh;
  final DateTime? expiresAt;
  final bool fromCache;
  final bool sdkInitialized;
  final bool adsCanBeRequested;
  final bool privacyOptionsRequired;
  final bool lastRefreshFailed;

  bool get effectiveTestMode => kDebugMode || config.testMode;

  bool get supportsAdsPlatform =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  bool get adsEnabled =>
      adsCanBeRequested &&
      sdkInitialized &&
      supportsAdsPlatform &&
      config.anyAdsEnabled;

  String adUnitIdFor(AdFormat format) {
    return config.adUnitIdFor(format, effectiveTestMode: effectiveTestMode);
  }

  bool isFormatEnabled(AdFormat format) {
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        format == AdFormat.native) {
      return false;
    }
    return adsCanBeRequested &&
        sdkInitialized &&
        supportsAdsPlatform &&
        config.isFormatEnabled(format);
  }

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
    bool? adsCanBeRequested,
    bool? privacyOptionsRequired,
    bool? lastRefreshFailed,
  }) {
    return AdsState(
      config: config ?? this.config,
      source: source ?? this.source,
      lastRefresh: lastRefresh ?? this.lastRefresh,
      expiresAt: expiresAt ?? this.expiresAt,
      fromCache: fromCache ?? this.fromCache,
      sdkInitialized: sdkInitialized ?? this.sdkInitialized,
      adsCanBeRequested: adsCanBeRequested ?? this.adsCanBeRequested,
      privacyOptionsRequired:
          privacyOptionsRequired ?? this.privacyOptionsRequired,
      lastRefreshFailed: lastRefreshFailed ?? this.lastRefreshFailed,
    );
  }
}

class AdsController extends AsyncNotifier<AdsState> {
  @override
  Future<AdsState> build() async {
    final repository = await ref.watch(adsConfigRepositoryProvider.future);
    final privacy = await ref.watch(adsPrivacyServiceProvider).prepareForAds();
    if (!privacy.canRequestAds) {
      return AdsState.disabled().copyWith(
        privacyOptionsRequired: privacy.privacyOptionsRequired,
      );
    }
    final initializer = ref.watch(mobileAdsInitializerProvider);
    final sdkInitialized = await initializer.initialize();
    final cached = await repository.loadCached();
    final initial = cached == null
        ? AdsState.disabled().copyWith(
            sdkInitialized: sdkInitialized,
            adsCanBeRequested: true,
            privacyOptionsRequired: privacy.privacyOptionsRequired,
          )
        : _fromSnapshot(
            cached,
            sdkInitialized: sdkInitialized,
            privacyOptionsRequired: privacy.privacyOptionsRequired,
          );
    unawaited(refreshRemote());
    return initial;
  }

  Future<void> refreshRemote() async {
    try {
      final repository = await ref.read(adsConfigRepositoryProvider.future);
      final result = await repository.fetchRemoteWithJson();
      await repository.save(result.snapshot, result.rawJson);
      final current = state.maybeWhen(
        data: (value) => value,
        orElse: AdsState.disabled,
      );
      if (!current.adsCanBeRequested) return;
      final sdkInitialized = await ref
          .read(mobileAdsInitializerProvider)
          .initialize();
      state = AsyncData(
        _fromSnapshot(
          result.snapshot,
          sdkInitialized: sdkInitialized,
          privacyOptionsRequired: current.privacyOptionsRequired,
        ),
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
    required bool privacyOptionsRequired,
  }) {
    return AdsState(
      config: snapshot.config,
      source: snapshot.source,
      lastRefresh: snapshot.lastRefresh,
      expiresAt: snapshot.expiresAt,
      fromCache: snapshot.fromCache,
      sdkInitialized: sdkInitialized,
      adsCanBeRequested: true,
      privacyOptionsRequired: privacyOptionsRequired,
    );
  }
}

String adUnitForTestFallback(AdFormat format) {
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
