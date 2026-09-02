import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/privacy_preserving_ad_request.dart';

class AppOpenAdService {
  const AppOpenAdService();

  Future<AppOpenAd> load(String adUnitId) {
    final completer = Completer<AppOpenAd>();
    AppOpenAd.load(
      adUnitId: adUnitId,
      request: privacyPreservingAdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: completer.complete,
        onAdFailedToLoad: completer.completeError,
      ),
    );
    return completer.future;
  }
}
