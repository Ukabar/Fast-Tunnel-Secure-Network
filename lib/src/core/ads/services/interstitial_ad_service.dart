import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/privacy_preserving_ad_request.dart';

class InterstitialAdService {
  const InterstitialAdService();

  Future<InterstitialAd> load(String adUnitId) {
    final completer = Completer<InterstitialAd>();
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: privacyPreservingAdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: completer.complete,
        onAdFailedToLoad: completer.completeError,
      ),
    );
    return completer.future;
  }
}
