import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../features/tunnel/application/tunnel_providers.dart';
import '../../../features/tunnel/domain/tunnel_service.dart';
import '../models/remote_ads_config.dart';
import '../providers/ad_providers.dart';

class RewardedController extends Notifier<void> {
  @override
  void build() {}

  Future<bool> showForFutureReward() async {
    final ads = ref
        .read(adsControllerProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    if (ads == null || !ads.isFormatEnabled(AdFormat.rewarded)) return false;
    final tunnel = ref.read(tunnelServiceProvider).current;
    if (tunnel.status == TunnelStatus.connected ||
        tunnel.status == TunnelStatus.preparing ||
        tunnel.status == TunnelStatus.connecting ||
        tunnel.status == TunnelStatus.disconnecting) {
      return false;
    }
    final coordinator = ref.read(fullScreenAdCoordinatorProvider);
    if (!coordinator.acquire()) return false;
    RewardedAd? ad;
    var earned = false;
    try {
      ad = await ref
          .read(rewardedAdServiceProvider)
          .load(ads.adUnitIdFor(AdFormat.rewarded));
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          coordinator.release();
          ad.dispose();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          coordinator.release();
          ad.dispose();
        },
      );
      await ad.show(
        onUserEarnedReward: (ad, reward) {
          earned = true;
        },
      );
      return earned;
    } catch (_) {
      coordinator.release();
      ad?.dispose();
      return false;
    }
  }
}
