enum NetworkTestPhase {
  idle,
  preparing,
  dns,
  https,
  latency,
  publicIp,
  calculating,
  completed,
  cancelled,
  failed,
}

enum NetworkTestAccuracy {
  fast(10),
  balanced(20),
  accurate(30),
  maximum(40);

  const NetworkTestAccuracy(this.attempts);

  final int attempts;

  String get label {
    return switch (this) {
      NetworkTestAccuracy.fast => 'Fast',
      NetworkTestAccuracy.balanced => 'Balanced',
      NetworkTestAccuracy.accurate => 'Accurate',
      NetworkTestAccuracy.maximum => 'Maximum',
    };
  }
}

enum ReachabilityStatus { reachable, unavailable, timeout, serverError }

class DiagnosticEndpoint {
  const DiagnosticEndpoint({
    required this.id,
    required this.name,
    required this.provider,
    required this.region,
    required this.uri,
  });

  final String id;
  final String name;
  final String provider;
  final String region;
  final Uri uri;
}

class DnsCheckResult {
  const DnsCheckResult({
    required this.host,
    required this.succeeded,
    required this.duration,
    required this.addressCount,
  });

  final String host;
  final bool succeeded;
  final Duration duration;
  final int addressCount;

  String get label => succeeded ? 'Resolved' : 'Unavailable';
}

class HttpsCheckResult {
  const HttpsCheckResult({
    required this.status,
    required this.duration,
    this.statusCode,
  });

  final ReachabilityStatus status;
  final Duration duration;
  final int? statusCode;

  bool get reachable => status == ReachabilityStatus.reachable;

  String get label {
    return switch (status) {
      ReachabilityStatus.reachable => 'Reachable',
      ReachabilityStatus.unavailable => 'Unavailable',
      ReachabilityStatus.timeout => 'Timeout',
      ReachabilityStatus.serverError => 'Server error',
    };
  }
}

class LatencyResult {
  const LatencyResult({
    required this.successfulSamples,
    required this.failedAttempts,
    required this.totalAttempts,
    required this.average,
    required this.minimum,
    required this.maximum,
    required this.jitter,
    required this.failureRate,
  });

  final List<Duration> successfulSamples;
  final int failedAttempts;
  final int totalAttempts;
  final Duration? average;
  final Duration? minimum;
  final Duration? maximum;
  final Duration? jitter;
  final double failureRate;

  bool get hasSamples => successfulSamples.isNotEmpty;
}

class NetworkTestResult {
  const NetworkTestResult({
    required this.id,
    required this.completedAt,
    required this.endpoint,
    required this.dns,
    required this.https,
    required this.latency,
    required this.publicIp,
    required this.score,
  });

  final String id;
  final DateTime completedAt;
  final DiagnosticEndpoint endpoint;
  final DnsCheckResult dns;
  final HttpsCheckResult https;
  final LatencyResult latency;
  final String? publicIp;
  final int score;

  String get scoreLabel {
    if (score >= 85) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 50) return 'Fair';
    return 'Poor';
  }
}

class NetworkTestProgress {
  const NetworkTestProgress({
    required this.phase,
    this.result,
    this.message,
    this.completedAttempts = 0,
    this.totalAttempts = 0,
  });

  const NetworkTestProgress.idle()
    : phase = NetworkTestPhase.idle,
      result = null,
      message = null,
      completedAttempts = 0,
      totalAttempts = 0;

  final NetworkTestPhase phase;
  final NetworkTestResult? result;
  final String? message;
  final int completedAttempts;
  final int totalAttempts;

  bool get isRunning {
    return switch (phase) {
      NetworkTestPhase.preparing ||
      NetworkTestPhase.dns ||
      NetworkTestPhase.https ||
      NetworkTestPhase.latency ||
      NetworkTestPhase.publicIp ||
      NetworkTestPhase.calculating => true,
      _ => false,
    };
  }

  String get statusLabel {
    return switch (phase) {
      NetworkTestPhase.idle => 'Ready',
      NetworkTestPhase.preparing => 'Preparing test...',
      NetworkTestPhase.dns => 'Checking DNS...',
      NetworkTestPhase.https => 'Checking HTTPS...',
      NetworkTestPhase.latency => 'Measuring latency...',
      NetworkTestPhase.publicIp => 'Checking public IP...',
      NetworkTestPhase.calculating => 'Calculating results...',
      NetworkTestPhase.completed => 'Test completed',
      NetworkTestPhase.cancelled => 'Test cancelled',
      NetworkTestPhase.failed => 'Test failed',
    };
  }
}
