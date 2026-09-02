import 'package:flutter/material.dart';

import '../../network_test/domain/network_test_models.dart';

class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.onboardingCompleted,
    required this.testAccuracy,
  });

  final ThemeMode themeMode;
  final bool onboardingCompleted;
  final NetworkTestAccuracy testAccuracy;

  static const defaults = AppSettings(
    themeMode: ThemeMode.system,
    onboardingCompleted: false,
    testAccuracy: NetworkTestAccuracy.accurate,
  );

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? onboardingCompleted,
    NetworkTestAccuracy? testAccuracy,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      testAccuracy: testAccuracy ?? this.testAccuracy,
    );
  }
}
