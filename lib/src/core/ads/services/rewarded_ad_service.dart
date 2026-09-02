import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/privacy_preserving_ad_request.dart';

class RewardedAdService {
  const RewardedAdService();

  Future<RewardedAd> load(String adUnitId) {
    final completer = Completer<RewardedAd>();
    RewardedAd.load(
      adUnitId: adUnitId,
      request: privacyPreservingAdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: completer.complete,
        onAdFailedToLoad: completer.completeError,
      ),
    );
    return completer.future;
  }
}
