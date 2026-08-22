import 'package:fast_tunnel_network_test/src/features/history/data/session_history_repository.dart';
import 'package:fast_tunnel_network_test/src/features/history/domain/session_history_entry.dart';
import 'package:fast_tunnel_network_test/src/features/network_test/domain/network_test_models.dart';
import 'package:fast_tunnel_network_test/src/features/settings/data/settings_repository.dart';
import 'package:fast_tunnel_network_test/src/features/settings/domain/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('test history keeps latest 50 items and supports deletion', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repo = SharedPreferencesSessionHistoryRepository(preferences);

    for (var i = 0; i < 55; i++) {
      await repo.save(_entry(i));
    }

    final history = await repo.load();
    expect(history.length, 50);
    expect(history.first.id, '54');

    await repo.delete('54');
    final afterDelete = await repo.load();
    expect(afterDelete.any((item) => item.id == '54'), isFalse);
    expect(afterDelete.length, 49);
  });

  test('settings and onboarding persistence round trip', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repo = SharedPreferencesSettingsRepository(preferences);

    await repo.save(
      const AppSettings(
        themeMode: ThemeMode.light,
        onboardingCompleted: true,
        notifyForPlannedPremium: false,
        testAccuracy: NetworkTestAccuracy.maximum,
        preferredLocationId: 'legacy-id',
        favoriteLocationIds: ['legacy-id'],
      ),
    );

    final settings = await repo.load();
    expect(settings.themeMode, ThemeMode.light);
    expect(settings.onboardingCompleted, isTrue);
    expect(settings.testAccuracy, NetworkTestAccuracy.maximum);
    expect(settings.preferredLocationId, 'legacy-id');
    expect(settings.favoriteLocationIds, ['legacy-id']);
  });

  test('corrupted test history data is ignored without crashing', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesSessionHistoryRepository.key: ['not-json'],
    });
    final preferences = await SharedPreferences.getInstance();
    final repo = SharedPreferencesSessionHistoryRepository(preferences);

    final history = await repo.load();

    expect(history, isEmpty);
    expect(
      preferences.getStringList(SharedPreferencesSessionHistoryRepository.key),
      isEmpty,
    );
  });

  test('test history clear removes all records', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repo = SharedPreferencesSessionHistoryRepository(preferences);

    await repo.save(_entry(1));
    await repo.clear();

    expect(await repo.load(), isEmpty);
  });
}

SessionHistoryEntry _entry(int index) {
  final timestamp = DateTime(2026, 1, 1, 12).add(Duration(minutes: index));
  return SessionHistoryEntry(
    id: '$index',
    completedAt: timestamp,
    score: 88,
    scoreLabel: 'Excellent',
    averageLatencyMs: 120,
    minimumLatencyMs: 100,
    maximumLatencyMs: 160,
    jitterMs: 12,
    failureRate: 0,
    dnsSucceeded: true,
    dnsDurationMs: 20,
    dnsAddressCount: 2,
    httpsStatus: 'Reachable',
    httpsDurationMs: 90,
    publicIp: '203.0.113.10',
    endpointName: 'Lightweight HTTPS',
    endpointProvider: 'Google',
    endpointRegion: 'Global',
  );
}
