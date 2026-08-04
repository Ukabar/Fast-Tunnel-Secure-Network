import 'package:fast_tunnel_network_test/src/features/history/data/session_history_repository.dart';
import 'package:fast_tunnel_network_test/src/features/history/domain/session_history_entry.dart';
import 'package:fast_tunnel_network_test/src/features/settings/data/settings_repository.dart';
import 'package:fast_tunnel_network_test/src/features/settings/domain/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'session history keeps latest 100 items and supports deletion',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final repo = SharedPreferencesSessionHistoryRepository(preferences);

      for (var i = 0; i < 105; i++) {
        await repo.save(_entry(i));
      }

      final history = await repo.load();
      expect(history.length, 100);
      expect(history.first.id, '104');

      await repo.delete('104');
      final afterDelete = await repo.load();
      expect(afterDelete.any((item) => item.id == '104'), isFalse);
      expect(afterDelete.length, 99);
    },
  );

  test('settings and onboarding persistence round trip', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repo = SharedPreferencesSettingsRepository(preferences);

    await repo.save(
      const AppSettings(
        themeMode: ThemeMode.light,
        onboardingCompleted: true,
        notifyForPlannedPremium: false,
        connectionAnimationEnabled: false,
        preferredLocationId: 'gb-lon',
        favoriteLocationIds: ['gb-lon'],
      ),
    );

    final settings = await repo.load();
    expect(settings.themeMode, ThemeMode.light);
    expect(settings.onboardingCompleted, isTrue);
    expect(settings.connectionAnimationEnabled, isFalse);
    expect(settings.preferredLocationId, 'gb-lon');
    expect(settings.favoriteLocationIds, ['gb-lon']);
  });

  test('corrupted session history data is ignored without crashing', () async {
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

  test('session history clear removes all records', () async {
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
    location: 'New York, United States',
    startedAt: timestamp,
    endedAt: timestamp.add(const Duration(minutes: 4)),
    finalState: SessionFinalState.completed,
    sessionIdentifier: 'FT-$index',
  );
}
