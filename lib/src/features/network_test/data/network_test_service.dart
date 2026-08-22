import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../domain/network_test_models.dart';

abstract interface class NetworkDiagnosticsClient {
  Future<({int statusCode, String body})> get(
    Uri uri, {
    required Duration timeout,
  });

  Future<List<InternetAddress>> lookup(String host);
}

class DartIoNetworkDiagnosticsClient implements NetworkDiagnosticsClient {
  const DartIoNetworkDiagnosticsClient();

  @override
  Future<({int statusCode, String body})> get(
    Uri uri, {
    required Duration timeout,
  }) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.getUrl(uri).timeout(timeout);
      request.followRedirects = false;
      final response = await request.close().timeout(timeout);
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(timeout);
      return (statusCode: response.statusCode, body: body);
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<List<InternetAddress>> lookup(String host) {
    return InternetAddress.lookup(host);
  }
}

class NetworkTestCancelledException implements Exception {
  const NetworkTestCancelledException();
}

class NetworkTestService {
  const NetworkTestService({
    this.client = const DartIoNetworkDiagnosticsClient(),
    this.timeout = const Duration(seconds: 4),
    this.now = DateTime.now,
  });

  final NetworkDiagnosticsClient client;
  final Duration timeout;
  final DateTime Function() now;

  static final endpoints = [
    DiagnosticEndpoint(
      id: 'google-204',
      name: 'Lightweight HTTPS',
      provider: 'Google',
      region: 'Global',
      uri: Uri.parse('https://www.google.com/generate_204'),
    ),
    DiagnosticEndpoint(
      id: 'cloudflare-trace',
      name: 'Trace reachability',
      provider: 'Cloudflare',
      region: 'Global',
      uri: Uri.parse('https://www.cloudflare.com/cdn-cgi/trace'),
    ),
    DiagnosticEndpoint(
      id: 'cloudflare-204',
      name: 'Connectivity check',
      provider: 'Cloudflare',
      region: 'Global',
      uri: Uri.parse('https://cp.cloudflare.com/generate_204'),
    ),
  ];

  Future<NetworkTestResult> run({
    required NetworkTestAccuracy accuracy,
    required bool Function() isCancelled,
    required void Function(NetworkTestProgress progress) onProgress,
  }) async {
    void checkCancelled() {
      if (isCancelled()) throw const NetworkTestCancelledException();
    }

    onProgress(
      const NetworkTestProgress(
        phase: NetworkTestPhase.preparing,
        message: 'Preparing test...',
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 150));
    checkCancelled();

    final endpoint = await _selectEndpoint();
    checkCancelled();

    onProgress(
      const NetworkTestProgress(
        phase: NetworkTestPhase.dns,
        message: 'Checking DNS...',
      ),
    );
    final dns = await checkDns(endpoint.uri.host);
    checkCancelled();

    onProgress(
      const NetworkTestProgress(
        phase: NetworkTestPhase.https,
        message: 'Checking HTTPS...',
      ),
    );
    final https = await checkHttps(endpoint);
    checkCancelled();

    onProgress(
      NetworkTestProgress(
        phase: NetworkTestPhase.latency,
        message: 'Measuring latency...',
        totalAttempts: accuracy.attempts,
      ),
    );
    final latency = await measureLatency(
      endpoint: endpoint,
      attempts: accuracy.attempts,
      isCancelled: isCancelled,
      onAttempt: (completed) => onProgress(
        NetworkTestProgress(
          phase: NetworkTestPhase.latency,
          message: 'Measuring latency...',
          completedAttempts: completed,
          totalAttempts: accuracy.attempts,
        ),
      ),
    );
    checkCancelled();

    onProgress(
      const NetworkTestProgress(
        phase: NetworkTestPhase.publicIp,
        message: 'Checking public IP...',
      ),
    );
    final publicIp = await fetchPublicIp();
    checkCancelled();

    onProgress(
      const NetworkTestProgress(
        phase: NetworkTestPhase.calculating,
        message: 'Calculating results...',
      ),
    );
    final score = calculateScore(
      latency: latency.average,
      jitter: latency.jitter,
      failureRate: latency.failureRate,
      dnsSucceeded: dns.succeeded,
      httpsReachable: https.reachable,
    );

    return NetworkTestResult(
      id: 'NT-${now().microsecondsSinceEpoch}',
      completedAt: now(),
      endpoint: endpoint,
      dns: dns,
      https: https,
      latency: latency,
      publicIp: publicIp,
      score: score,
    );
  }

  Future<DiagnosticEndpoint> _selectEndpoint() async {
    for (final endpoint in endpoints) {
      final health = await checkHttps(endpoint);
      if (health.reachable) return endpoint;
    }
    return endpoints.first;
  }

  Future<DnsCheckResult> checkDns(String host) async {
    final watch = Stopwatch()..start();
    try {
      final addresses = await client.lookup(host).timeout(timeout);
      watch.stop();
      return DnsCheckResult(
        host: host,
        succeeded: addresses.isNotEmpty,
        duration: watch.elapsed,
        addressCount: addresses.length,
      );
    } on Object {
      watch.stop();
      return DnsCheckResult(
        host: host,
        succeeded: false,
        duration: watch.elapsed,
        addressCount: 0,
      );
    }
  }

  Future<HttpsCheckResult> checkHttps(DiagnosticEndpoint endpoint) async {
    final watch = Stopwatch()..start();
    try {
      final response = await client.get(endpoint.uri, timeout: timeout);
      watch.stop();
      final code = response.statusCode;
      if (code >= 200 && code < 400) {
        return HttpsCheckResult(
          status: ReachabilityStatus.reachable,
          duration: watch.elapsed,
          statusCode: code,
        );
      }
      return HttpsCheckResult(
        status: ReachabilityStatus.serverError,
        duration: watch.elapsed,
        statusCode: code,
      );
    } on TimeoutException {
      watch.stop();
      return HttpsCheckResult(
        status: ReachabilityStatus.timeout,
        duration: watch.elapsed,
      );
    } on Object {
      watch.stop();
      return HttpsCheckResult(
        status: ReachabilityStatus.unavailable,
        duration: watch.elapsed,
      );
    }
  }

  Future<LatencyResult> measureLatency({
    required DiagnosticEndpoint endpoint,
    required int attempts,
    required bool Function() isCancelled,
    required void Function(int completed) onAttempt,
  }) async {
    final samples = <Duration>[];
    var failures = 0;

    for (var i = 0; i < attempts; i++) {
      if (isCancelled()) throw const NetworkTestCancelledException();
      final watch = Stopwatch()..start();
      try {
        final response = await client.get(endpoint.uri, timeout: timeout);
        watch.stop();
        if (response.statusCode >= 200 && response.statusCode < 400) {
          samples.add(watch.elapsed);
        } else {
          failures++;
        }
      } on Object {
        watch.stop();
        failures++;
      }
      onAttempt(i + 1);
      await Future<void>.delayed(const Duration(milliseconds: 35));
    }

    return buildLatencyResult(
      samples: samples,
      failures: failures,
      attempts: attempts,
    );
  }

  Future<String?> fetchPublicIp() async {
    try {
      final response = await client.get(
        Uri.parse('https://api.ipify.org?format=json'),
        timeout: timeout,
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, Object?>) return null;
      final ip = decoded['ip'];
      if (ip is! String || InternetAddress.tryParse(ip.trim()) == null) {
        return null;
      }
      return ip.trim();
    } on Object {
      return null;
    }
  }
}

LatencyResult buildLatencyResult({
  required List<Duration> samples,
  required int failures,
  required int attempts,
}) {
  final average = samples.isEmpty
      ? null
      : Duration(
          microseconds:
              samples
                  .map((item) => item.inMicroseconds)
                  .reduce((a, b) => a + b) ~/
              samples.length,
        );
  final minimum = samples.isEmpty
      ? null
      : samples.reduce((a, b) => a < b ? a : b);
  final maximum = samples.isEmpty
      ? null
      : samples.reduce((a, b) => a > b ? a : b);
  final jitter = _calculateJitter(samples);
  return LatencyResult(
    successfulSamples: List.unmodifiable(samples),
    failedAttempts: failures,
    totalAttempts: attempts,
    average: average,
    minimum: minimum,
    maximum: maximum,
    jitter: jitter,
    failureRate: attempts == 0 ? 1 : failures / attempts,
  );
}

Duration? _calculateJitter(List<Duration> samples) {
  if (samples.length < 2) return samples.isEmpty ? null : Duration.zero;
  var totalDelta = 0;
  for (var i = 1; i < samples.length; i++) {
    totalDelta += (samples[i].inMicroseconds - samples[i - 1].inMicroseconds)
        .abs();
  }
  return Duration(microseconds: totalDelta ~/ (samples.length - 1));
}

int calculateScore({
  required Duration? latency,
  required Duration? jitter,
  required double failureRate,
  required bool dnsSucceeded,
  required bool httpsReachable,
}) {
  final latencyScore = latency == null
      ? 0.0
      : _inverseScore(latency.inMilliseconds, best: 60, worst: 900);
  final jitterScore = jitter == null
      ? 0.0
      : _inverseScore(jitter.inMilliseconds, best: 10, worst: 250);
  final failureScore = (1 - failureRate).clamp(0.0, 1.0) * 100;
  final reachabilityScore =
      ((dnsSucceeded ? 50 : 0) + (httpsReachable ? 50 : 0)).toDouble();

  return (latencyScore * 0.45 +
          jitterScore * 0.25 +
          failureScore * 0.20 +
          reachabilityScore * 0.10)
      .round()
      .clamp(0, 100);
}

double _inverseScore(int value, {required int best, required int worst}) {
  if (value <= best) return 100;
  if (value >= worst) return 0;
  return (1 - ((value - best) / (worst - best))) * 100;
}
