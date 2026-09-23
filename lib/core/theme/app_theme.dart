import 'package:flutter/material.dart';

/// Tema aplikasi.
///
/// Saat ini masih memegang nilai yang sama persis seperti sebelumnya di
/// `main.dart`. Design token (warna & text style) belum dipindahkan ke sini —
/// itu ruang lingkup refactor tampilan yang terpisah.
class AppTheme {
  const AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: false,
        scaffoldBackgroundColor: Colors.white,
        canvasColor: Colors.white,
        cardColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF013236),
          secondary: Color(0xFF94DF0C),
          surface: Colors.white,
          onSurface: Color(0xFF013236),
        ),
      );
}
