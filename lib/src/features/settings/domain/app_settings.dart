import 'package:flutter/material.dart';

class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.onboardingCompleted,
    required this.notifyForPlannedPremium,
    required this.connectionAnimationEnabled,
    this.favoriteLocationIds = const [],
    this.preferredLocationId,
  });

  final ThemeMode themeMode;
  final bool onboardingCompleted;
  final bool notifyForPlannedPremium;
  final bool connectionAnimationEnabled;
  final List<String> favoriteLocationIds;
  final String? preferredLocationId;

  static const defaults = AppSettings(
    themeMode: ThemeMode.system,
    onboardingCompleted: false,
    notifyForPlannedPremium: false,
    connectionAnimationEnabled: true,
    favoriteLocationIds: ['us-nyc', 'gb-lon', 'sg-sin'],
  );

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? onboardingCompleted,
    bool? notifyForPlannedPremium,
    bool? connectionAnimationEnabled,
    List<String>? favoriteLocationIds,
    String? preferredLocationId,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      notifyForPlannedPremium:
          notifyForPlannedPremium ?? this.notifyForPlannedPremium,
      connectionAnimationEnabled:
          connectionAnimationEnabled ?? this.connectionAnimationEnabled,
      favoriteLocationIds: favoriteLocationIds ?? this.favoriteLocationIds,
      preferredLocationId: preferredLocationId ?? this.preferredLocationId,
    );
  }
}
