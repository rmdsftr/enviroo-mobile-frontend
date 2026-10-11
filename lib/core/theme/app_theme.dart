import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: false,
        fontFamily: AppText.family,
        scaffoldBackgroundColor: Colors.white,
        canvasColor: Colors.white,
        cardColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: AppColors.dark,
          secondary: AppColors.neon,
          surface: Colors.white,
          onSurface: AppColors.dark,
        ),
      );
}
