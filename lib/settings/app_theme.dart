import 'package:flutter/material.dart';

class AppColors {
  static const Color orange = Color(0xFFFF9800);
  static const Color green = Color(0xFF4CAF50);
  static const Color blue = Color(0xFF2196F3);

  static const Color background = Color(0xFFF5F5F5);
  static const Color darkText = Color(0xFF202124);
}

/// Central place for light/dark themes
class AppTheme {
  static ThemeData lightTheme(Locale locale) {
    final isArabic = locale.languageCode == 'ar';

    final base = ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.orange,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: isArabic ? 'Cairo' : null, // optional, if you added this font
      useMaterial3: true,
    );

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.orange,
        secondary: AppColors.green,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkText,
        elevation: 0.5,
        centerTitle: true,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.orange,
            width: 1.4,
          ),
        ),
      ),
      cardTheme: CardTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 3,
      ),
    );
  }

  static ThemeData darkTheme(Locale locale) {
    final isArabic = locale.languageCode == 'ar';

    final base = ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.orange,
      scaffoldBackgroundColor: const Color(0xFF101213),
      fontFamily: isArabic ? 'Cairo' : null,
      useMaterial3: true,
    );

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.orange,
        secondary: AppColors.green,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF151719),
        foregroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.orange,
            width: 1.4,
          ),
        ),
      ),
      cardTheme: CardTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 2,
      ),
    );
  }
}
