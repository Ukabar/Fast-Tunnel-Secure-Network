import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/privacy_preserving_ad_request.dart';

class NativeAdService {
  const NativeAdService();

  static const factoryId = 'fastTunnelNativeAd';

  NativeAd create({
    required String adUnitId,
    required NativeAdListener listener,
  }) {
    return NativeAd(
      adUnitId: adUnitId,
      factoryId: factoryId,
      request: privacyPreservingAdRequest(),
      listener: listener,
    );
  }
}
