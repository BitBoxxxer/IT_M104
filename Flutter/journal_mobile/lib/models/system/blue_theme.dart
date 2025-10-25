import 'package:flutter/material.dart';

ThemeData get blueTheme {
  final darkTheme = ThemeData.dark();
  return darkTheme.copyWith(
    colorScheme: darkTheme.colorScheme.copyWith(
      primary: Colors.blueAccent,
      secondary: Colors.lightBlueAccent,
      surface: const Color(0xFF1E2A3A),
      background: const Color(0xFF15202B),
      onSurface: Colors.blueGrey[100],
    ),
    scaffoldBackgroundColor: const Color(0xFF15202B),
    cardColor: const Color(0xFF1E2A3A),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1E2A3A),
      elevation: 1,
      titleTextStyle: TextStyle(
        color: Colors.blue[100],
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.blue[200]),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.blue[700],
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: const Color(0xFF1E2A3A),
      selectedItemColor: Colors.blue[200],
      unselectedItemColor: Colors.grey[600],
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),
    textTheme: darkTheme.textTheme.apply(
      bodyColor: Colors.blueGrey[100],
      displayColor: Colors.blue[100],
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
    ),
  );
}