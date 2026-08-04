enum PublicIpStatus {
  available,
  malformedResponse,
  noInternet,
  serverFailure,
  timeout,
}

class PublicIpResult {
  const PublicIpResult.available(this.ip)
    : status = PublicIpStatus.available,
      message = null;

  const PublicIpResult.unavailable({
    required this.status,
    required this.message,
  }) : ip = null;

  final PublicIpStatus status;
  final String? ip;
  final String? message;

  bool get isAvailable => status == PublicIpStatus.available && ip != null;
}
