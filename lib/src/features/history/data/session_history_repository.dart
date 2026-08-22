import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/session_history_entry.dart';

abstract interface class SessionHistoryRepository {
  Future<List<SessionHistoryEntry>> load();

  Future<void> save(SessionHistoryEntry entry);

  Future<void> delete(String id);

  Future<void> clear();
}

class SharedPreferencesSessionHistoryRepository
    implements SessionHistoryRepository {
  const SharedPreferencesSessionHistoryRepository(this._preferences);

  static const key = 'network_test_history_v1';
  static const maxItems = 50;

  final SharedPreferences _preferences;

  @override
  Future<List<SessionHistoryEntry>> load() async {
    final raw = _preferences.getStringList(key) ?? const [];
    final entries = <SessionHistoryEntry>[];
    var foundCorruptItem = false;

    for (final item in raw) {
      try {
        entries.add(
          SessionHistoryEntry.fromJson(
            jsonDecode(item) as Map<String, Object?>,
          ),
        );
      } on Object {
        foundCorruptItem = true;
      }
    }

    if (foundCorruptItem) {
      await _preferences.setStringList(key, [
        for (final entry in entries) jsonEncode(entry.toJson()),
      ]);
    }

    return entries;
  }

  @override
  Future<void> save(SessionHistoryEntry entry) async {
    final history = await load();
    final next = [
      entry,
      ...history.where((item) => item.id != entry.id),
    ].take(maxItems).toList();
    await _preferences.setStringList(key, [
      for (final item in next) jsonEncode(item.toJson()),
    ]);
  }

  @override
  Future<void> delete(String id) async {
    final history = await load();
    await _preferences.setStringList(key, [
      for (final item in history.where((item) => item.id != id))
        jsonEncode(item.toJson()),
    ]);
  }

  @override
  Future<void> clear() async {
    await _preferences.remove(key);
  }
}
