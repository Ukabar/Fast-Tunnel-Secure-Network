import 'package:flutter/material.dart';

import '../../network_test/domain/network_test_models.dart';

class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.onboardingCompleted,
    required this.notifyForPlannedPremium,
    required this.testAccuracy,
    this.favoriteLocationIds = const [],
    this.preferredLocationId,
  });

  final ThemeMode themeMode;
  final bool onboardingCompleted;
  final bool notifyForPlannedPremium;
  final NetworkTestAccuracy testAccuracy;
  final List<String> favoriteLocationIds;
  final String? preferredLocationId;

  static const defaults = AppSettings(
    themeMode: ThemeMode.system,
    onboardingCompleted: false,
    notifyForPlannedPremium: false,
    testAccuracy: NetworkTestAccuracy.accurate,
    favoriteLocationIds: ['us-nyc', 'gb-lon', 'sg-sin'],
  );

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? onboardingCompleted,
    bool? notifyForPlannedPremium,
    NetworkTestAccuracy? testAccuracy,
    List<String>? favoriteLocationIds,
    String? preferredLocationId,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      notifyForPlannedPremium:
          notifyForPlannedPremium ?? this.notifyForPlannedPremium,
      testAccuracy: testAccuracy ?? this.testAccuracy,
      favoriteLocationIds: favoriteLocationIds ?? this.favoriteLocationIds,
      preferredLocationId: preferredLocationId ?? this.preferredLocationId,
    );
  }
}
