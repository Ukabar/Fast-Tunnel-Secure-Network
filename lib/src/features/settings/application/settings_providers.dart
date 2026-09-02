import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/preferences_provider.dart';
import '../../network_test/domain/network_test_models.dart';
import '../data/settings_repository.dart';
import '../domain/app_settings.dart';

final settingsRepositoryProvider = FutureProvider<SettingsRepository>((
  ref,
) async {
  final preferences = await ref.watch(sharedPreferencesProvider.future);
  return SharedPreferencesSettingsRepository(preferences);
});

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, AppSettings>(
      SettingsController.new,
    );

class SettingsController extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final repo = await ref.watch(settingsRepositoryProvider.future);
    return repo.load();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _update((settings) => settings.copyWith(themeMode: mode));
  }

  Future<void> completeOnboarding() async {
    await _update((settings) => settings.copyWith(onboardingCompleted: true));
  }

  Future<void> setTestAccuracy(NetworkTestAccuracy accuracy) async {
    await _update((settings) => settings.copyWith(testAccuracy: accuracy));
  }

  Future<void> _update(
    AppSettings Function(AppSettings settings) update,
  ) async {
    final current = state.when(
      data: (settings) => settings,
      error: (error, stackTrace) => AppSettings.defaults,
      loading: () => AppSettings.defaults,
    );
    final next = update(current);
    state = AsyncData(next);
    final repo = await ref.read(settingsRepositoryProvider.future);
    await repo.save(next);
  }
}
