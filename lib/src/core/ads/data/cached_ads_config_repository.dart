import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/remote_ads_config.dart';
import 'ads_config_repository.dart';
import 'remote_ads_config_repository.dart';

class CachedAdsConfigRepository implements AdsConfigRepository {
  CachedAdsConfigRepository({
    required this.preferences,
    RemoteAdsConfigRepository? remote,
    DateTime Function()? now,
  }) : _remote = remote ?? RemoteAdsConfigRepository(now: now),
       _now = now ?? DateTime.now;

  static const _jsonKey = 'ads_config_last_valid_json';
  static const _timestampKey = 'ads_config_last_success_ms';
  static const _sourceKey = 'ads_config_source';
  static const _expiresKey = 'ads_config_expires_ms';
  static const maxStaleAge = Duration(days: 7);

  final SharedPreferences preferences;
  final RemoteAdsConfigRepository _remote;
  final DateTime Function() _now;

  @override
  Future<AdsConfigSnapshot?> loadCached() async {
    final rawJson = preferences.getString(_jsonKey);
    final successMs = preferences.getInt(_timestampKey);
    final expiresMs = preferences.getInt(_expiresKey);
    final source = preferences.getString(_sourceKey);
    if (rawJson == null ||
        rawJson.isEmpty ||
        successMs == null ||
        expiresMs == null ||
        source == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, Object?>) return null;
      final config = RemoteAdsConfig.fromJson(decoded);
      final lastRefresh = DateTime.fromMillisecondsSinceEpoch(successMs);
      if (_now().difference(lastRefresh) > maxStaleAge) return null;
      return AdsConfigSnapshot(
        config: config,
        source: source,
        lastRefresh: lastRefresh,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresMs),
        fromCache: true,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AdsConfigSnapshot> fetchRemote() async {
    final result = await _remote.fetch();
    return _remote.snapshotFor(result.config, result.source);
  }

  @override
  Future<AdsConfigFetchResult> fetchRemoteWithJson() async {
    final result = await _remote.fetch();
    return AdsConfigFetchResult(
      snapshot: _remote.snapshotFor(result.config, result.source),
      rawJson: result.rawJson,
    );
  }

  @override
  Future<void> save(AdsConfigSnapshot snapshot, String rawJson) async {
    await preferences.setString(_jsonKey, rawJson);
    if (snapshot.lastRefresh != null) {
      await preferences.setInt(
        _timestampKey,
        snapshot.lastRefresh!.millisecondsSinceEpoch,
      );
    }
    if (snapshot.expiresAt != null) {
      await preferences.setInt(
        _expiresKey,
        snapshot.expiresAt!.millisecondsSinceEpoch,
      );
    }
    await preferences.setString(_sourceKey, snapshot.source);
  }
}
