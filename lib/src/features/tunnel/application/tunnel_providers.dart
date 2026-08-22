// Future-only tunnel provider.
//
// Do not use this provider from current production screens. The active v1.0
// product flow is the network test feature.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/tunnel_service.dart';

final tunnelServiceProvider = Provider<TunnelService>((ref) {
  return MockTunnelService();
});

final tunnelReadinessProvider = FutureProvider<TunnelReadiness>((ref) {
  return ref.watch(tunnelServiceProvider).readiness();
});

final tunnelStateProvider = StreamProvider<TunnelState>((ref) {
  return ref.watch(tunnelServiceProvider).watch();
});
