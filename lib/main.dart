import 'dart:async';

import 'package:fast_tunnel_network_test/src/core/ads/services/mobile_ads_initializer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app/fast_tunnel_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(MobileAdsInitializer().initialize());
  runApp(const ProviderScope(child: FastTunnelApp()));
}
