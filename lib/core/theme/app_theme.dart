import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// Thème global Material 3 de l'application
class AppTheme {
  AppTheme._();

  /// Barres système transparentes (edge-to-edge) avec icônes sombres.
  static const SystemUiOverlayStyle systemBarsStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
    systemStatusBarContrastEnforced: false,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.background,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.pageBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: systemBarsStyle,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(AppSizes.buttonHeightDefault),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontSize: AppSizes.fontDefault,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border, width: 1.2),
          minimumSize: const Size.fromHeight(AppSizes.buttonHeightDefault),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontSize: AppSizes.fontDefault,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: AppSizes.fontXxl,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          height: 1.25,
        ),
        titleLarge: TextStyle(
          fontSize: AppSizes.fontL,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: AppSizes.fontDefault,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: AppSizes.fontMd,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: AppSizes.fontSm,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontSize: AppSizes.fontXsm,
          color: AppColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: AppSizes.fontMd,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: TextStyle(
          fontSize: AppSizes.fontSm,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          fontSize: AppSizes.fontXxsm,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
