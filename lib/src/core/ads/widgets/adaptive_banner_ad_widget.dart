import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../models/remote_ads_config.dart';
import '../providers/ad_providers.dart';

class AdaptiveBannerAdWidget extends ConsumerStatefulWidget {
  const AdaptiveBannerAdWidget({super.key, required this.screenId});

  final String screenId;

  @override
  ConsumerState<AdaptiveBannerAdWidget> createState() =>
      _AdaptiveBannerAdWidgetState();
}

class _AdaptiveBannerAdWidgetState
    extends ConsumerState<AdaptiveBannerAdWidget> {
  BannerAd? _ad;
  AdSize? _size;
  int? _loadedWidth;
  var _loading = false;
  var _failed = false;

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ads = ref
        .watch(adsControllerProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    if (ads == null || !ads.isBannerEnabledFor(widget.screenId)) {
      _disposeAd();
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.truncate();
        if (width > 0 &&
            !_loading &&
            (_ad == null ||
                (_loadedWidth != null && (width - _loadedWidth!).abs() > 24)) &&
            !_failed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _load(width, ads.adUnitIdFor(AdFormat.banner));
          });
        }
        final ad = _ad;
        final size = _size;
        if (ad == null || size == null) return const SizedBox.shrink();
        return SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: size.width.toDouble(),
              height: size.height.toDouble(),
              child: AdWidget(ad: ad),
            ),
          ),
        );
      },
    );
  }

  Future<void> _load(int width, String adUnitId) async {
    _loading = true;
    _failed = false;
    final service = ref.read(bannerAdServiceProvider);
    final size = await service.adaptiveSize(width);
    if (!mounted || size == null) {
      _loading = false;
      _failed = true;
      return;
    }
    _disposeAd();
    final ad = service.create(
      adUnitId: adUnitId,
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _ad = ad as BannerAd;
            _size = size;
            _loadedWidth = width;
            _loading = false;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _failed = true;
            _loading = false;
            _ad = null;
            _size = null;
          });
        },
      ),
    );
    try {
      await ad.load();
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
      ad.dispose();
    }
  }

  void _disposeAd() {
    _ad?.dispose();
    _ad = null;
    _size = null;
    _loadedWidth = null;
  }
}
