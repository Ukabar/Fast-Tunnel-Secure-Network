import '../models/remote_ads_config.dart';

class AdsConfigSnapshot {
  const AdsConfigSnapshot({
    required this.config,
    required this.source,
    required this.lastRefresh,
    required this.expiresAt,
    required this.fromCache,
  });

  final RemoteAdsConfig config;
  final String source;
  final DateTime? lastRefresh;
  final DateTime? expiresAt;
  final bool fromCache;
}

class AdsConfigFetchResult {
  const AdsConfigFetchResult({required this.snapshot, required this.rawJson});

  final AdsConfigSnapshot snapshot;
  final String rawJson;
}

abstract interface class AdsConfigRepository {
  Future<AdsConfigSnapshot?> loadCached();

  Future<AdsConfigSnapshot> fetchRemote();

  Future<AdsConfigFetchResult> fetchRemoteWithJson();

  Future<void> save(AdsConfigSnapshot snapshot, String rawJson);
}
