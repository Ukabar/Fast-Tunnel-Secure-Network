import '../../network_test/data/network_test_service.dart';
import '../../network_test/domain/network_test_models.dart';

class SessionHistoryEntry {
  const SessionHistoryEntry({
    required this.id,
    required this.completedAt,
    required this.score,
    required this.scoreLabel,
    required this.averageLatencyMs,
    required this.minimumLatencyMs,
    required this.maximumLatencyMs,
    required this.jitterMs,
    required this.failureRate,
    required this.dnsSucceeded,
    required this.dnsDurationMs,
    required this.dnsAddressCount,
    required this.httpsStatus,
    required this.httpsDurationMs,
    required this.publicIp,
    required this.endpointName,
    required this.endpointProvider,
    required this.endpointRegion,
  });

  factory SessionHistoryEntry.fromResult(NetworkTestResult result) {
    return SessionHistoryEntry(
      id: result.id,
      completedAt: result.completedAt,
      score: result.score,
      scoreLabel: result.scoreLabel,
      averageLatencyMs: result.latency.average?.inMilliseconds,
      minimumLatencyMs: result.latency.minimum?.inMilliseconds,
      maximumLatencyMs: result.latency.maximum?.inMilliseconds,
      jitterMs: result.latency.jitter?.inMilliseconds,
      failureRate: result.latency.failureRate,
      dnsSucceeded: result.dns.succeeded,
      dnsDurationMs: result.dns.duration.inMilliseconds,
      dnsAddressCount: result.dns.addressCount,
      httpsStatus: result.https.label,
      httpsDurationMs: result.https.duration.inMilliseconds,
      publicIp: result.publicIp,
      endpointName: result.endpoint.name,
      endpointProvider: result.endpoint.provider,
      endpointRegion: result.endpoint.region,
    );
  }

  factory SessionHistoryEntry.fromJson(Map<String, Object?> json) {
    return SessionHistoryEntry(
      id: json['id'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      score: json['score'] as int,
      scoreLabel: json['scoreLabel'] as String,
      averageLatencyMs: json['averageLatencyMs'] as int?,
      minimumLatencyMs: json['minimumLatencyMs'] as int?,
      maximumLatencyMs: json['maximumLatencyMs'] as int?,
      jitterMs: json['jitterMs'] as int?,
      failureRate: (json['failureRate'] as num).toDouble(),
      dnsSucceeded: json['dnsSucceeded'] as bool,
      dnsDurationMs: json['dnsDurationMs'] as int,
      dnsAddressCount: json['dnsAddressCount'] as int,
      httpsStatus: json['httpsStatus'] as String,
      httpsDurationMs: json['httpsDurationMs'] as int,
      publicIp: json['publicIp'] as String?,
      endpointName: json['endpointName'] as String,
      endpointProvider: json['endpointProvider'] as String,
      endpointRegion: json['endpointRegion'] as String,
    );
  }

  final String id;
  final DateTime completedAt;
  final int score;
  final String scoreLabel;
  final int? averageLatencyMs;
  final int? minimumLatencyMs;
  final int? maximumLatencyMs;
  final int? jitterMs;
  final double failureRate;
  final bool dnsSucceeded;
  final int dnsDurationMs;
  final int dnsAddressCount;
  final String httpsStatus;
  final int httpsDurationMs;
  final String? publicIp;
  final String endpointName;
  final String endpointProvider;
  final String endpointRegion;

  String get failureRateLabel => '${(failureRate * 100).round()}%';

  NetworkTestResult toResult() {
    final endpoint = DiagnosticEndpoint(
      id: endpointName,
      name: endpointName,
      provider: endpointProvider,
      region: endpointRegion,
      uri: NetworkTestService.endpoints.first.uri,
    );
    return NetworkTestResult(
      id: id,
      completedAt: completedAt,
      endpoint: endpoint,
      dns: DnsCheckResult(
        host: endpoint.uri.host,
        succeeded: dnsSucceeded,
        duration: Duration(milliseconds: dnsDurationMs),
        addressCount: dnsAddressCount,
      ),
      https: HttpsCheckResult(
        status: _statusFromLabel(httpsStatus),
        duration: Duration(milliseconds: httpsDurationMs),
      ),
      latency: buildLatencyResult(
        samples: [
          if (averageLatencyMs != null)
            Duration(milliseconds: averageLatencyMs!),
        ],
        failures: (failureRate * 1000).round(),
        attempts: 1000,
      ),
      publicIp: publicIp,
      score: score,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'completedAt': completedAt.toIso8601String(),
      'score': score,
      'scoreLabel': scoreLabel,
      'averageLatencyMs': averageLatencyMs,
      'minimumLatencyMs': minimumLatencyMs,
      'maximumLatencyMs': maximumLatencyMs,
      'jitterMs': jitterMs,
      'failureRate': failureRate,
      'dnsSucceeded': dnsSucceeded,
      'dnsDurationMs': dnsDurationMs,
      'dnsAddressCount': dnsAddressCount,
      'httpsStatus': httpsStatus,
      'httpsDurationMs': httpsDurationMs,
      'publicIp': publicIp,
      'endpointName': endpointName,
      'endpointProvider': endpointProvider,
      'endpointRegion': endpointRegion,
    };
  }
}

ReachabilityStatus _statusFromLabel(String label) {
  return switch (label) {
    'Reachable' => ReachabilityStatus.reachable,
    'Timeout' => ReachabilityStatus.timeout,
    'Server error' => ReachabilityStatus.serverError,
    _ => ReachabilityStatus.unavailable,
  };
}
