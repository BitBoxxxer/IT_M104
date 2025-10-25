import 'package:flutter/material.dart';
// TODO: разобраться с темой чуть позже - Ди

ThemeData get blueTheme {
  final darkTheme = ThemeData.dark();
  return darkTheme.copyWith(
    colorScheme: darkTheme.colorScheme.copyWith(
      primary: Colors.blue,
      secondary: Colors.lightBlue,
      surface: const Color(0xFF1E2A3A),
      background: const Color(0xFF15202B),
    ),
    scaffoldBackgroundColor: const Color(0xFF15202B),
    cardColor: const Color(0xFF1E2A3A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E2A3A),
      elevation: 0,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.blue[700],
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: const Color(0xFF1E2A3A),
      selectedItemColor: Colors.blue[200],
      unselectedItemColor: Colors.grey[600],
    ),
  );
}