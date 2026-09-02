import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../storage/preferences_provider.dart';
import '../controllers/ads_controller.dart';
import '../controllers/app_open_controller.dart';
import '../controllers/full_screen_ad_coordinator.dart';
import '../controllers/interstitial_controller.dart';
import '../controllers/rewarded_controller.dart';
import '../data/ads_config_repository.dart';
import '../data/embedded_ads_config_repository.dart';
import '../services/app_open_ad_service.dart';
import '../services/ads_privacy_service.dart';
import '../services/banner_ad_service.dart';
import '../services/interstitial_ad_service.dart';
import '../services/mobile_ads_initializer.dart';
import '../services/native_ad_service.dart';
import '../services/rewarded_ad_service.dart';

final sharedPreferencesForAdsProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return ref.watch(sharedPreferencesProvider.future);
});

final mobileAdsInitializerProvider = Provider<MobileAdsInitializer>((ref) {
  return MobileAdsInitializer();
});

final adsPrivacyServiceProvider = Provider<AdsPrivacyService>((ref) {
  return UmpAdsPrivacyService();
});

final adsConfigRepositoryProvider = FutureProvider<AdsConfigRepository>((
  ref,
) async {
  return EmbeddedAdsConfigRepository();
});

final adsControllerProvider = AsyncNotifierProvider<AdsController, AdsState>(
  AdsController.new,
);

final bannerAdServiceProvider = Provider<BannerAdService>((ref) {
  return const BannerAdService();
});

final interstitialAdServiceProvider = Provider<InterstitialAdService>((ref) {
  return const InterstitialAdService();
});

final appOpenAdServiceProvider = Provider<AppOpenAdService>((ref) {
  return const AppOpenAdService();
});

final nativeAdServiceProvider = Provider<NativeAdService>((ref) {
  return const NativeAdService();
});

final rewardedAdServiceProvider = Provider<RewardedAdService>((ref) {
  return const RewardedAdService();
});

final fullScreenAdCoordinatorProvider = Provider<FullScreenAdCoordinator>((
  ref,
) {
  return FullScreenAdCoordinator();
});

final interstitialControllerProvider =
    AsyncNotifierProvider<InterstitialController, InterstitialAdDebugState>(
      InterstitialController.new,
    );

final appOpenControllerProvider =
    AsyncNotifierProvider<AppOpenController, AppOpenAdDebugState>(
      AppOpenController.new,
    );

final rewardedControllerProvider = NotifierProvider<RewardedController, void>(
  RewardedController.new,
);
