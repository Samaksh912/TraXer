import 'package:flutter/material.dart';

class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color background;
  final Color surface;
  final Color primaryText;
  final Color accent;
  final Color income;
  final Color expense;
  
  const AppThemeColors({
    required this.background,
    required this.surface,
    required this.primaryText,
    required this.accent,
    required this.income,
    required this.expense,
  });

  @override
  ThemeExtension<AppThemeColors> copyWith({
    Color? background,
    Color? surface,
    Color? primaryText,
    Color? accent,
    Color? income,
    Color? expense,
  }) {
    return AppThemeColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      primaryText: primaryText ?? this.primaryText,
      accent: accent ?? this.accent,
      income: income ?? this.income,
      expense: expense ?? this.expense,
    );
  }

  @override
  ThemeExtension<AppThemeColors> lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) {
      return this;
    }
    return AppThemeColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
    );
  }
}

class AppTheme {
  static const _lightAppColors = AppThemeColors(
    background: Color(0xFFF2EFE9),
    surface: Color(0xFFFAF8F5),
    primaryText: Color(0xFF2D2B2A),
    accent: Color(0xFFD96C4A),
    income: Color(0xFF597465),
    expense: Color(0xFF8B3A36),
  );

  static const _darkAppColors = AppThemeColors(
    background: Color(0xFF1A1918),
    surface: Color(0xFF262423),
    primaryText: Color(0xFFE3E1DE),
    accent: Color(0xFFE2876A),
    income: Color(0xFF769684),
    expense: Color(0xFFB45C58),
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: _lightAppColors.accent,
        surface: _lightAppColors.surface,
        onSurface: _lightAppColors.primaryText,
      ),
      scaffoldBackgroundColor: _lightAppColors.background,
      cardColor: _lightAppColors.surface,
      textTheme: Typography.material2021(platform: TargetPlatform.android).black.apply(
        bodyColor: _lightAppColors.primaryText,
        displayColor: _lightAppColors.primaryText,
      ),
      extensions: const <ThemeExtension<dynamic>>[
        _lightAppColors,
      ],
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: _darkAppColors.accent,
        surface: _darkAppColors.surface,
        onSurface: _darkAppColors.primaryText,
      ),
      scaffoldBackgroundColor: _darkAppColors.background,
      cardColor: _darkAppColors.surface,
      textTheme: Typography.material2021(platform: TargetPlatform.android).white.apply(
        bodyColor: _darkAppColors.primaryText,
        displayColor: _darkAppColors.primaryText,
      ),
      extensions: const <ThemeExtension<dynamic>>[
        _darkAppColors,
      ],
    );
  }
}

extension AppThemeExtension on BuildContext {
  AppThemeColors get appColors => Theme.of(this).extension<AppThemeColors>()!;
}
