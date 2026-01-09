import 'package:flutter/material.dart';

/// Signal app color palette
class SignalColors {
  SignalColors._();

  // Brand colors
  static const signalBlue = Color(0xFF3A76F0);
  static const signalBlueDark = Color(0xFF2C6BED);

  // Dark theme colors (Signal style)
  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1B1B1B);
  static const darkSurfaceElevated = Color(0xFF2C2C2C);
  static const darkDivider = Color(0xFF3D3D3D);

  // Light theme colors
  static const lightBackground = Color(0xFFF6F6F6);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceElevated = Color(0xFFFFFFFF);
  static const lightDivider = Color(0xFFE0E0E0);

  // Text colors
  static const textPrimaryDark = Color(0xFFFFFFFF);
  static const textSecondaryDark = Color(0xFFB0B0B0);
  static const textPrimaryLight = Color(0xFF121212);
  static const textSecondaryLight = Color(0xFF5E5E5E);

  // Status colors
  static const destructive = Color(0xFFD93838);
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFA726);
}

/// Signal app theme
class SignalTheme {
  SignalTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: SignalColors.signalBlue,
      scaffoldBackgroundColor: SignalColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: SignalColors.signalBlue,
        secondary: SignalColors.signalBlue,
        error: SignalColors.destructive,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: SignalColors.lightSurface,
        foregroundColor: SignalColors.textPrimaryLight,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: SignalColors.textPrimaryLight,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: SignalColors.lightDivider,
        thickness: 1,
        space: 0,
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: SignalColors.lightSurface,
        iconColor: SignalColors.textSecondaryLight,
        textColor: SignalColors.textPrimaryLight,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return SignalColors.signalBlue;
          }
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return SignalColors.signalBlue.withValues(alpha: 0.5);
          }
          return Colors.grey.withValues(alpha: 0.3);
        }),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: SignalColors.signalBlue,
      scaffoldBackgroundColor: SignalColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: SignalColors.signalBlue,
        secondary: SignalColors.signalBlue,
        surface: SignalColors.darkSurface,
        error: SignalColors.destructive,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: SignalColors.darkSurface,
        foregroundColor: SignalColors.textPrimaryDark,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: SignalColors.textPrimaryDark,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: SignalColors.darkDivider,
        thickness: 1,
        space: 0,
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: SignalColors.darkSurface,
        iconColor: SignalColors.textSecondaryDark,
        textColor: SignalColors.textPrimaryDark,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return SignalColors.signalBlue;
          }
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return SignalColors.signalBlue.withValues(alpha: 0.5);
          }
          return Colors.grey.withValues(alpha: 0.3);
        }),
      ),
    );
  }
}
