import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAdService {
  const RewardedAdService();

  Future<RewardedAd> load(String adUnitId) {
    final completer = Completer<RewardedAd>();
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: completer.complete,
        onAdFailedToLoad: completer.completeError,
      ),
    );
    return completer.future;
  }
}
