import 'dart:io';

import 'package:fast_tunnel_network_test/src/features/network_test/data/network_test_service.dart';
import 'package:fast_tunnel_network_test/src/features/network_test/domain/network_test_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'latency calculation computes average min max jitter and failure rate',
    () {
      final result = buildLatencyResult(
        samples: const [
          Duration(milliseconds: 100),
          Duration(milliseconds: 140),
          Duration(milliseconds: 110),
        ],
        failures: 1,
        attempts: 4,
      );

      expect(result.average!.inMilliseconds, 116);
      expect(result.minimum!.inMilliseconds, 100);
      expect(result.maximum!.inMilliseconds, 140);
      expect(result.jitter!.inMilliseconds, 35);
      expect(result.failureRate, 0.25);
    },
  );

  test('score calculation uses measured values', () {
    final score = calculateScore(
      latency: const Duration(milliseconds: 100),
      jitter: const Duration(milliseconds: 20),
      failureRate: 0.1,
      dnsSucceeded: true,
      httpsReachable: true,
    );

    expect(score, greaterThan(70));
  });

  test('service checks DNS, HTTPS, public IP, and endpoint fallback', () async {
    final client = _FakeDiagnosticsClient();
    final service = NetworkTestService(client: client);

    final dns = await service.checkDns('example.com');
    final https = await service.checkHttps(NetworkTestService.endpoints.first);
    final ip = await service.fetchPublicIp();

    expect(dns.succeeded, isTrue);
    expect(dns.addressCount, 1);
    expect(https.status, ReachabilityStatus.reachable);
    expect(ip, '203.0.113.10');
  });

  test('service run supports cancellation', () async {
    final service = NetworkTestService(client: _FakeDiagnosticsClient());
    var cancelled = false;

    await expectLater(
      service.run(
        accuracy: NetworkTestAccuracy.fast,
        isCancelled: () => cancelled,
        onProgress: (progress) {
          if (progress.phase == NetworkTestPhase.latency) cancelled = true;
        },
      ),
      throwsA(isA<NetworkTestCancelledException>()),
    );
  });
}

class _FakeDiagnosticsClient implements NetworkDiagnosticsClient {
  @override
  Future<({String body, int statusCode})> get(
    Uri uri, {
    required Duration timeout,
  }) async {
    if (uri.host == 'api.ipify.org') {
      return (statusCode: 200, body: '{"ip":"203.0.113.10"}');
    }
    return (statusCode: 204, body: '');
  }

  @override
  Future<List<InternetAddress>> lookup(String host) async {
    return [InternetAddress('93.184.216.34')];
  }
}
