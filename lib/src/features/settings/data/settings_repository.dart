import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_settings.dart';

abstract interface class SettingsRepository {
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);
}

class SharedPreferencesSettingsRepository implements SettingsRepository {
  const SharedPreferencesSettingsRepository(this._preferences);

  static const themeModeKey = 'settings_theme_mode';
  static const onboardingCompletedKey = 'settings_onboarding_completed';
  static const notifyPremiumKey = 'settings_notify_premium';
  static const connectionAnimationKey = 'settings_connection_animation';
  static const preferredLocationKey = 'settings_preferred_location';
  static const favoriteLocationIdsKey = 'settings_favorite_locations';

  final SharedPreferences _preferences;

  @override
  Future<AppSettings> load() async {
    return AppSettings(
      themeMode: _themeModeFromName(_preferences.getString(themeModeKey)),
      onboardingCompleted:
          _preferences.getBool(onboardingCompletedKey) ?? false,
      notifyForPlannedPremium: _preferences.getBool(notifyPremiumKey) ?? false,
      connectionAnimationEnabled:
          _preferences.getBool(connectionAnimationKey) ?? true,
      preferredLocationId: _preferences.getString(preferredLocationKey),
      favoriteLocationIds:
          _preferences.getStringList(favoriteLocationIdsKey) ??
          AppSettings.defaults.favoriteLocationIds,
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _preferences.setString(themeModeKey, settings.themeMode.name);
    await _preferences.setBool(
      onboardingCompletedKey,
      settings.onboardingCompleted,
    );
    await _preferences.setBool(
      notifyPremiumKey,
      settings.notifyForPlannedPremium,
    );
    await _preferences.setBool(
      connectionAnimationKey,
      settings.connectionAnimationEnabled,
    );
    final preferred = settings.preferredLocationId;
    if (preferred == null) {
      await _preferences.remove(preferredLocationKey);
    } else {
      await _preferences.setString(preferredLocationKey, preferred);
    }
    await _preferences.setStringList(
      favoriteLocationIdsKey,
      settings.favoriteLocationIds,
    );
  }

  ThemeMode _themeModeFromName(String? name) {
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => ThemeMode.system,
    );
  }
}
