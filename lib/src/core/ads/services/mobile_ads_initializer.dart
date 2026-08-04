import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class MobileAdsInitializer {
  MobileAdsInitializer();

  Future<InitializationStatus>? _initialization;
  Object? _lastError;

  Object? get lastError => _lastError;

  Future<bool> initialize() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      _initialization ??= MobileAds.instance.initialize();
      await _initialization;
      _lastError = null;
      return true;
    } catch (error) {
      _lastError = error;
      if (kDebugMode) {
        debugPrint('Mobile Ads initialization failed.');
      }
      return false;
    }
  }
}
