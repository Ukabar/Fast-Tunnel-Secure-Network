import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../network_test/domain/network_test_models.dart';
import '../domain/app_settings.dart';

abstract interface class SettingsRepository {
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);
}

class SharedPreferencesSettingsRepository implements SettingsRepository {
  const SharedPreferencesSettingsRepository(this._preferences);

  static const themeModeKey = 'settings_theme_mode';
  static const onboardingCompletedKey = 'settings_onboarding_completed';
  static const testAccuracyKey = 'settings_test_accuracy';

  final SharedPreferences _preferences;

  @override
  Future<AppSettings> load() async {
    return AppSettings(
      themeMode: _themeModeFromName(_preferences.getString(themeModeKey)),
      onboardingCompleted:
          _preferences.getBool(onboardingCompletedKey) ?? false,
      testAccuracy: _accuracyFromName(_preferences.getString(testAccuracyKey)),
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _preferences.setString(themeModeKey, settings.themeMode.name);
    await _preferences.setBool(
      onboardingCompletedKey,
      settings.onboardingCompleted,
    );
    await _preferences.setString(testAccuracyKey, settings.testAccuracy.name);
  }

  ThemeMode _themeModeFromName(String? name) {
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => ThemeMode.system,
    );
  }

  NetworkTestAccuracy _accuracyFromName(String? name) {
    return NetworkTestAccuracy.values.firstWhere(
      (accuracy) => accuracy.name == name,
      orElse: () => NetworkTestAccuracy.accurate,
    );
  }
}
