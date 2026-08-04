import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/remote_ads_config.dart';
import 'ads_config_repository.dart';

class RemoteAdsConfigRepository {
  RemoteAdsConfigRepository({
    HttpClient? httpClient,
    String? endpoint,
    DateTime Function()? now,
  }) : _httpClient = httpClient ?? HttpClient(),
       _endpoint = endpoint ?? _resolvedEndpoint,
       _now = now ?? DateTime.now;

  static const _overrideEndpoint = String.fromEnvironment('ADS_CONFIG_URL');
  static const _maxBytes = 64 * 1024;

  static String get _resolvedEndpoint {
    if (_overrideEndpoint.trim().isNotEmpty) return _overrideEndpoint.trim();
    return defaultAdsConfigUrl;
  }

  final HttpClient _httpClient;
  final String _endpoint;
  final DateTime Function() _now;

  String get endpoint => _endpoint;

  Future<({RemoteAdsConfig config, String rawJson, String source})>
  fetch() async {
    final uri = Uri.tryParse(_endpoint);
    if (uri == null || uri.scheme != 'https') {
      throw const FormatException('Ads config endpoint must be HTTPS.');
    }

    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final request = await _httpClient
            .getUrl(uri)
            .timeout(const Duration(seconds: 8));
        final response = await request.close().timeout(
          const Duration(seconds: 8),
        );
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw HttpException('HTTP ${response.statusCode}', uri: uri);
        }

        final bytes = <int>[];
        await for (final chunk in response.timeout(
          const Duration(seconds: 8),
        )) {
          bytes.addAll(chunk);
          if (bytes.length > _maxBytes) {
            throw const FormatException('Ads config response too large.');
          }
        }
        if (bytes.isEmpty) {
          throw const FormatException('Ads config response was empty.');
        }
        final rawJson = utf8.decode(bytes);
        final decoded = jsonDecode(rawJson);
        if (decoded is! Map<String, Object?>) {
          throw const FormatException('Ads config root must be an object.');
        }
        return (
          config: RemoteAdsConfig.fromJson(decoded),
          rawJson: rawJson,
          source: uri.toString(),
        );
      } catch (error) {
        lastError = error;
      }
    }
    Error.throwWithStackTrace(lastError!, StackTrace.current);
  }

  AdsConfigSnapshot snapshotFor(RemoteAdsConfig config, String source) {
    final lastRefresh = _now();
    return AdsConfigSnapshot(
      config: config,
      source: source,
      lastRefresh: lastRefresh,
      expiresAt: lastRefresh.add(
        Duration(minutes: config.cacheDurationMinutes),
      ),
      fromCache: false,
    );
  }
}
