import 'package:fast_tunnel_network_test/src/core/ads/providers/ad_providers.dart';
import 'package:fast_tunnel_network_test/src/core/ads/services/ads_privacy_service.dart';
import 'package:fast_tunnel_network_test/src/core/ads/services/mobile_ads_initializer.dart';
import 'package:fast_tunnel_network_test/src/core/ads/utils/privacy_preserving_ad_request.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('iOS ad requests are explicitly non-personalized', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    expect(privacyPreservingAdRequest().nonPersonalizedAds, isTrue);
  });

  test('Android ad request behavior remains unchanged', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    expect(privacyPreservingAdRequest().nonPersonalizedAds, isNull);
  });

  test('Mobile Ads is not initialized when UMP blocks ad requests', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final initializer = _RecordingMobileAdsInitializer();
    final container = ProviderContainer(
      overrides: [
        adsPrivacyServiceProvider.overrideWithValue(
          const _FakeAdsPrivacyService(canRequestAds: false),
        ),
        mobileAdsInitializerProvider.overrideWithValue(initializer),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(adsControllerProvider.future);

    expect(initializer.initializeCalls, 0);
    expect(state.adsCanBeRequested, isFalse);
    expect(state.sdkInitialized, isFalse);
    expect(state.adsEnabled, isFalse);
  });
}

class _RecordingMobileAdsInitializer extends MobileAdsInitializer {
  var initializeCalls = 0;

  @override
  Future<bool> initialize() async {
    initializeCalls++;
    return true;
  }
}

class _FakeAdsPrivacyService implements AdsPrivacyService {
  const _FakeAdsPrivacyService({required this.canRequestAds});

  final bool canRequestAds;

  @override
  Future<AdsPrivacyStatus> prepareForAds() async {
    return AdsPrivacyStatus(
      canRequestAds: canRequestAds,
      privacyOptionsRequired: false,
    );
  }

  @override
  Future<void> showPrivacyOptions() async {}
}
