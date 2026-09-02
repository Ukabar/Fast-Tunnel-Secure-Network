import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

AdRequest privacyPreservingAdRequest() {
  return AdRequest(
    nonPersonalizedAds: defaultTargetPlatform == TargetPlatform.iOS
        ? true
        : null,
  );
}
