import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colors.dart';

abstract final class AppTheme {
  static final _textTheme = TextTheme(
    headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w500),
    headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
    titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
    titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
    bodySmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.grey500,
    ),
    labelSmall: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: AppColors.grey500,
    ),
    labelLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w400,
      color: AppColors.grey500,
    ),
  );

  static final _inputDecorationTheme = InputDecorationTheme(
    hintStyle: TextStyle(
      // grey500 works for both light and dark themes
      color: AppColors.grey500,
      fontSize: 18.0,
      fontWeight: FontWeight.w400,
    ),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide(color: AppColors.orange, width: 1.0),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
  );

  static final _elevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.orange,
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      textStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
      minimumSize: Size(120, 56),
    ),
  );

  static final _outlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.grey500,
      backgroundColor: AppColors.disabledButtonBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      textStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
      minimumSize: Size(120, 56),
    ),
  );

  static final _cardTheme = CardThemeData(
    color: AppColors.darkCardBackground,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16.0),
    ),
    margin: EdgeInsets.zero,
  );

  // Light theme system UI overlay style
  static final _lightSystemUiOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark, // Dark icons for light theme
    statusBarBrightness: Brightness.light, // iOS status bar with dark content
    systemNavigationBarColor: AppColors.lightColorScheme.surface,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  // Dark theme system UI overlay style
  static final _darkSystemUiOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light, // Light icons for dark theme
    statusBarBrightness: Brightness.dark, // iOS status bar with light content
    systemNavigationBarColor: AppColors.darkColorScheme.surface,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static ThemeData lightTheme = _applyCommonTheme(
    ThemeData(
      brightness: Brightness.light,
      colorScheme: AppColors.lightColorScheme,
      textTheme: _textTheme,
      inputDecorationTheme: _inputDecorationTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        systemOverlayStyle: _lightSystemUiOverlayStyle,
        backgroundColor: AppColors.lightColorScheme.surface,
        foregroundColor: AppColors.lightColorScheme.onSurface,
        elevation: 0,
      ),
      scaffoldBackgroundColor: AppColors.lightColorScheme.surface,
      cardTheme: _cardTheme.copyWith(
        color: AppColors.lightColorScheme.surfaceContainerHighest,
      ),
    ),
  );

  static ThemeData darkTheme = _applyCommonTheme(
    ThemeData(
      brightness: Brightness.dark,
      colorScheme: AppColors.darkColorScheme,
      textTheme: _textTheme,
      inputDecorationTheme: _inputDecorationTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        systemOverlayStyle: _darkSystemUiOverlayStyle,
        backgroundColor: AppColors.darkColorScheme.surface,
        foregroundColor: AppColors.darkColorScheme.onSurface,
        elevation: 0,
      ),
      scaffoldBackgroundColor: AppColors.darkColorScheme.surface,
      cardTheme: _cardTheme,
    ),
  );

  // Common theme configurations
  static ThemeData _applyCommonTheme(ThemeData theme) {
    return theme.copyWith(
      // Splash and highlight settings
      splashColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
      highlightColor:
          theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
      splashFactory: InkRipple.splashFactory,

      // Optional: other interaction settings
      hoverColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.1),
      focusColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.1),
    );
  }
}
