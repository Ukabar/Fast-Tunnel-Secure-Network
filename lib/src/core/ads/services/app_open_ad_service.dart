import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

class AppOpenAdService {
  const AppOpenAdService();

  Future<AppOpenAd> load(String adUnitId) {
    final completer = Completer<AppOpenAd>();
    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: completer.complete,
        onAdFailedToLoad: completer.completeError,
      ),
    );
    return completer.future;
  }
}
