import 'package:flutter/material.dart';

class AppPalette {
  const AppPalette._();

  static const navy = Color(0xFF061A2E);
  static const navyRaised = Color(0xFF0D2B48);
  static const blue = Color(0xFF1266F1);
  static const cyan = Color(0xFF27C7F7);
  static const teal = Color(0xFF087F92);
  static const ice = Color(0xFFF3F8FC);
  static const iceRaised = Color(0xFFEAF2F7);
  static const ink = Color(0xFF102A3B);
  static const mutedInk = Color(0xFF58707E);
}

class AppGradients {
  const AppGradients._();

  static const brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppPalette.cyan, AppPalette.blue],
  );

  static const home = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A3556), AppPalette.navy],
  );

  static const testCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF167FAA), Color(0xFF114E91), Color(0xFF0B315B)],
  );
}

class AppSpacing {
  const AppSpacing._();

  static const xs = 6.0;
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 22.0;
  static const xl = 30.0;
}

class AppRadii {
  const AppRadii._();

  static const card = 18.0;
  static const control = 12.0;
  static const pill = 999.0;
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    const colors = ColorScheme.light(
      primary: AppPalette.teal,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFD5F3F8),
      onPrimaryContainer: AppPalette.ink,
      secondary: AppPalette.blue,
      onSecondary: Colors.white,
      surface: AppPalette.ice,
      onSurface: AppPalette.ink,
      surfaceContainerHighest: AppPalette.iceRaised,
      onSurfaceVariant: AppPalette.mutedInk,
      outline: Color(0xFF8AA0AC),
      outlineVariant: Color(0xFFD5E1E8),
      error: Color(0xFFBA1A1A),
    );
    return _base(colors);
  }

  static ThemeData dark() {
    const colors = ColorScheme.dark(
      primary: AppPalette.cyan,
      onPrimary: AppPalette.navy,
      primaryContainer: Color(0xFF0B455A),
      onPrimaryContainer: Color(0xFFD9F7FF),
      secondary: Color(0xFF80B5FF),
      onSecondary: AppPalette.navy,
      surface: AppPalette.navy,
      onSurface: Color(0xFFEAF5FC),
      surfaceContainerHighest: AppPalette.navyRaised,
      onSurfaceVariant: Color(0xFFA9C1D2),
      outline: Color(0xFF6D8495),
      outlineVariant: Color(0xFF24435D),
      error: Color(0xFFFFB4AB),
    );
    return _base(colors);
  }

  static ThemeData _base(ColorScheme colors) {
    final base = ThemeData(colorScheme: colors, useMaterial3: true);
    final appliedTextTheme = base.textTheme.apply(
      bodyColor: colors.onSurface,
      displayColor: colors.onSurface,
    );
    TextStyle? zeroSpacing(TextStyle? style) =>
        style?.copyWith(letterSpacing: 0);
    final textTheme = appliedTextTheme.copyWith(
      displayLarge: zeroSpacing(appliedTextTheme.displayLarge),
      displayMedium: zeroSpacing(appliedTextTheme.displayMedium),
      displaySmall: zeroSpacing(appliedTextTheme.displaySmall),
      headlineLarge: zeroSpacing(appliedTextTheme.headlineLarge),
      headlineMedium: zeroSpacing(appliedTextTheme.headlineMedium),
      headlineSmall: zeroSpacing(appliedTextTheme.headlineSmall),
      titleLarge: zeroSpacing(appliedTextTheme.titleLarge),
      titleMedium: zeroSpacing(appliedTextTheme.titleMedium),
      titleSmall: zeroSpacing(appliedTextTheme.titleSmall),
      bodyLarge: zeroSpacing(appliedTextTheme.bodyLarge),
      bodyMedium: zeroSpacing(appliedTextTheme.bodyMedium),
      bodySmall: zeroSpacing(appliedTextTheme.bodySmall),
      labelLarge: zeroSpacing(appliedTextTheme.labelLarge),
      labelMedium: zeroSpacing(appliedTextTheme.labelMedium),
      labelSmall: zeroSpacing(appliedTextTheme.labelSmall),
    );

    return base.copyWith(
      scaffoldBackgroundColor: colors.surface,
      visualDensity: VisualDensity.standard,
      textTheme: textTheme.copyWith(
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.brightness == Brightness.light
            ? Colors.white
            : AppPalette.navyRaised,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        elevation: 0,
        backgroundColor: colors.brightness == Brightness.light
            ? const Color(0xFFF4F9FC)
            : const Color(0xFF0A2035),
        indicatorColor: colors.primary.withValues(alpha: 0.18),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? colors.primary
                : colors.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colors.primary
                : colors.onSurfaceVariant,
          );
        }),
      ),
      dividerTheme: DividerThemeData(color: colors.outlineVariant),
    );
  }
}
