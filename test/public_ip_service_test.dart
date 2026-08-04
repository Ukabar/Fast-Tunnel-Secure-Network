import 'dart:async';

import 'package:fast_tunnel_network_test/src/features/public_ip/data/public_ip_service.dart';
import 'package:fast_tunnel_network_test/src/features/public_ip/domain/public_ip_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses valid public IP response', () {
    final result = parsePublicIpResponse('{"ip":"203.0.113.10"}');

    expect(result.ip, '203.0.113.10');
    expect(result.status, PublicIpStatus.available);
  });

  test('rejects malformed public IP response', () {
    expect(
      () => parsePublicIpResponse('{"ip":"not an ip"}'),
      throwsFormatException,
    );
  });

  test('maps public IP timeout to unavailable result', () async {
    final service = IpifyPublicIpService(client: _TimeoutClient());

    final result = await service.fetchPublicIp();

    expect(result.status, PublicIpStatus.timeout);
    expect(result.ip, isNull);
  });
}

class _TimeoutClient implements PublicIpHttpClient {
  @override
  Future<String> get(Uri uri, {required Duration timeout}) {
    throw TimeoutException('slow');
  }
}
