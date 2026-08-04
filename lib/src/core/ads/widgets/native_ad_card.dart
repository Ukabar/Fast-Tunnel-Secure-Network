import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../models/remote_ads_config.dart';
import '../providers/ad_providers.dart';

class NativeAdCard extends ConsumerStatefulWidget {
  const NativeAdCard({super.key});

  @override
  ConsumerState<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends ConsumerState<NativeAdCard> {
  NativeAd? _ad;
  var _loaded = false;
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
    if (ads == null || !ads.isFormatEnabled(AdFormat.native)) {
      _disposeAd();
      return const SizedBox.shrink();
    }
    if (!_loading && !_loaded && !_failed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load(ads.adUnitIdFor(AdFormat.native));
      });
    }
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: 112,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Text('Advertisement'),
            ),
            Expanded(child: AdWidget(ad: _ad!)),
          ],
        ),
      ),
    );
  }

  Future<void> _load(String adUnitId) async {
    _loading = true;
    final ad = ref
        .read(nativeAdServiceProvider)
        .create(
          adUnitId: adUnitId,
          listener: NativeAdListener(
            onAdLoaded: (ad) {
              if (!mounted) {
                ad.dispose();
                return;
              }
              setState(() {
                _ad = ad as NativeAd;
                _loaded = true;
                _loading = false;
              });
            },
            onAdFailedToLoad: (ad, error) {
              ad.dispose();
              if (!mounted) return;
              setState(() {
                _failed = true;
                _loading = false;
              });
            },
          ),
        );
    try {
      await ad.load();
    } catch (_) {
      ad.dispose();
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  void _disposeAd() {
    _ad?.dispose();
    _ad = null;
    _loaded = false;
  }
}
