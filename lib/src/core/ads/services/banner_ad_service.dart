import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/privacy_preserving_ad_request.dart';

class BannerAdService {
  const BannerAdService();

  Future<AdSize?> adaptiveSize(int width) {
    return AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
  }

  BannerAd create({
    required String adUnitId,
    required AdSize size,
    required BannerAdListener listener,
  }) {
    return BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: privacyPreservingAdRequest(),
      listener: listener,
    );
  }
}
