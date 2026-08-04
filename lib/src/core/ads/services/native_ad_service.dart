import 'package:google_mobile_ads/google_mobile_ads.dart';

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
      request: const AdRequest(),
      listener: listener,
    );
  }
}
