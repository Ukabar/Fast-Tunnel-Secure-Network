import 'package:google_mobile_ads/google_mobile_ads.dart';

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
      request: const AdRequest(),
      listener: listener,
    );
  }
}
