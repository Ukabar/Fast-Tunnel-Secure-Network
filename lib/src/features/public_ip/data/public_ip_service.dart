import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../domain/public_ip_result.dart';

abstract interface class PublicIpService {
  Future<PublicIpResult> fetchPublicIp();
}

abstract interface class PublicIpHttpClient {
  Future<String> get(Uri uri, {required Duration timeout});
}

class DartIoPublicIpHttpClient implements PublicIpHttpClient {
  const DartIoPublicIpHttpClient();

  @override
  Future<String> get(Uri uri, {required Duration timeout}) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.getUrl(uri).timeout(timeout);
      final response = await request.close().timeout(timeout);
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Server returned HTTP ${response.statusCode}');
      }
      return body;
    } finally {
      client.close(force: true);
    }
  }
}

class IpifyPublicIpService implements PublicIpService {
  const IpifyPublicIpService({
    this.client = const DartIoPublicIpHttpClient(),
    this.endpoint = const String.fromEnvironment(
      'FAST_TUNNEL_PUBLIC_IP_ENDPOINT',
      defaultValue: 'https://api.ipify.org?format=json',
    ),
    this.timeout = const Duration(seconds: 4),
  });

  final PublicIpHttpClient client;
  final String endpoint;
  final Duration timeout;

  @override
  Future<PublicIpResult> fetchPublicIp() async {
    try {
      final body = await client.get(Uri.parse(endpoint), timeout: timeout);
      return parsePublicIpResponse(body);
    } on TimeoutException {
      return const PublicIpResult.unavailable(
        status: PublicIpStatus.timeout,
        message: 'Public IP lookup timed out.',
      );
    } on SocketException {
      return const PublicIpResult.unavailable(
        status: PublicIpStatus.noInternet,
        message: 'Public IP is unavailable without internet access.',
      );
    } on HttpException {
      return const PublicIpResult.unavailable(
        status: PublicIpStatus.serverFailure,
        message: 'The public IP service did not return a usable response.',
      );
    } on FormatException {
      return const PublicIpResult.unavailable(
        status: PublicIpStatus.malformedResponse,
        message: 'The public IP response could not be read.',
      );
    } on Object {
      return const PublicIpResult.unavailable(
        status: PublicIpStatus.serverFailure,
        message: 'Public IP is temporarily unavailable.',
      );
    }
  }
}

PublicIpResult parsePublicIpResponse(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('Expected JSON object.');
  }
  final ip = decoded['ip'];
  if (ip is! String || !_isValidIp(ip.trim())) {
    throw const FormatException('Missing or invalid IP.');
  }
  return PublicIpResult.available(ip.trim());
}

bool _isValidIp(String value) {
  return InternetAddress.tryParse(value) != null;
}
