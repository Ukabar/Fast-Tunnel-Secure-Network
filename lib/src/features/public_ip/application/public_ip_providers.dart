import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/public_ip_service.dart';
import '../domain/public_ip_result.dart';

final publicIpServiceProvider = Provider<PublicIpService>((ref) {
  return const IpifyPublicIpService();
});

final currentPublicIpProvider = FutureProvider<PublicIpResult>((ref) {
  return ref.watch(publicIpServiceProvider).fetchPublicIp();
});
