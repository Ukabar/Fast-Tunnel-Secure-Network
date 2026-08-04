import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF116A7B),
      brightness: Brightness.light,
    );

    return _base(colorScheme);
  }

  static ThemeData dark() {
    const base = ColorScheme.dark(
      primary: Color(0xFF36C5F0),
      onPrimary: Color(0xFF001F2A),
      primaryContainer: Color(0xFF093A4A),
      onPrimaryContainer: Color(0xFFD8F7FF),
      secondary: Color(0xFF7DD3FC),
      surface: Color(0xFF07111F),
      onSurface: Color(0xFFE7F0F8),
      surfaceContainerHighest: Color(0xFF122338),
      outline: Color(0xFF587083),
      outlineVariant: Color(0xFF21354A),
      error: Color(0xFFFF7A90),
    );
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: base.primary,
          brightness: Brightness.dark,
        ).copyWith(
          surface: base.surface,
          surfaceContainerHighest: base.surfaceContainerHighest,
        );

    return _base(colorScheme);
  }

  static ThemeData _base(ColorScheme colorScheme) {
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: colorScheme.surface,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(48, 44),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(48, 44),
        ),
      ),
    );
  }
}
