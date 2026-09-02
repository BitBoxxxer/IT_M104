import 'package:flutter/material.dart';
import 'package:glassmorphic_ui/glassmorphic_ui.dart';

/// Единая палитра и вспомогательные декорации для футуристичного
/// ("HUD / стекло + неон") стиля приложения.
///
/// Идея: тёмный фон, полупрозрачные "стеклянные" панели с тонкой рамкой
/// и мягким свечением акцентного цвета, минимум теней в духе Material,
/// моноширинный акцент на цифрах (время, даты).
class FuturisticColors {
  FuturisticColors._();

  // Фон
  static const Color bgTop = Color(0xFF0A0E17);
  static const Color bgBottom = Color(0xFF10182B);

  // Поверхности
  static const Color panel = Color(0xFF141B2E);
  static const Color panelHi = Color(0xFF1B2540);

  // Акценты
  static const Color cyan = Color(0xFF37E7FF);
  static const Color violet = Color(0xFF8B7CFF);
  static const Color magenta = Color(0xFFFF5FBF);
  static const Color amber = Color(0xFFFFB454);
  static const Color green = Color(0xFF4CF2A6);
  static const Color red = Color(0xFFFF5C6C);

  // Текст
  static const Color textHi = Color(0xFFEAF2FF);
  static const Color textMid = Color(0xFFA9B6D6);
  static const Color textLo = Color(0xFF6E7A9C);

  static const Color border = Color(0x33A9C6FF);
}

/// Фоновый градиент "космос / HUD", на который кладутся стеклянные панели.
const BoxDecoration futuristicBackground = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [FuturisticColors.bgTop, FuturisticColors.bgBottom],
  ),
);

/// Декорация "стеклянной" панели с тонкой рамкой и мягким свечением.
BoxDecoration glassPanelDecoration({
  Color glow = FuturisticColors.cyan,
  double radius = 16,
  double glowOpacity = 0.12,
  bool border = true,
}) {
  return BoxDecoration(
    color: FuturisticColors.panel.withOpacity(0.72),
    borderRadius: BorderRadius.circular(radius),
    border: border
        ? Border.all(color: glow.withOpacity(0.35), width: 1)
        : null,
    boxShadow: [
      BoxShadow(
        color: glow.withOpacity(glowOpacity),
        blurRadius: 20,
        spreadRadius: -4,
      ),
    ],
  );
}

const TextStyle futHeading = TextStyle(
  color: FuturisticColors.textHi,
  fontSize: 16,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.2,
);

const TextStyle futTitle = TextStyle(
  color: FuturisticColors.textHi,
  fontSize: 20,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.4,
);

const TextStyle futBody = TextStyle(
  color: FuturisticColors.textHi,
  fontSize: 14,
  fontWeight: FontWeight.w500,
);

const TextStyle futMuted = TextStyle(
  color: FuturisticColors.textMid,
  fontSize: 13,
  fontWeight: FontWeight.w500,
);

/// Полная ThemeData на случай, если экран хочет отдать её в MaterialApp/Scaffold
/// напрямую, а не просто использовать точечные декорации/стили выше.
ThemeData get futuristicTheme {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: FuturisticColors.bgTop,
    colorScheme: base.colorScheme.copyWith(
      primary: FuturisticColors.cyan,
      secondary: FuturisticColors.violet,
      surface: FuturisticColors.panel,
      error: FuturisticColors.red,
      onSurface: FuturisticColors.textHi,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: futTitle,
      iconTheme: IconThemeData(color: FuturisticColors.cyan),
    ),
    cardTheme: CardThemeData(
      color: FuturisticColors.panel.withOpacity(0.78),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: FuturisticColors.border),
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: FuturisticColors.textHi,
      displayColor: FuturisticColors.textHi,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: FuturisticColors.cyan.withOpacity(0.16),
        foregroundColor: FuturisticColors.cyan,
        elevation: 0,
        side: BorderSide(color: FuturisticColors.cyan.withOpacity(0.5)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    dividerColor: FuturisticColors.border,
    iconTheme: const IconThemeData(color: FuturisticColors.textMid),
    extensions: const [
      LiquidGlassTheme(
        defaultBlurSigma: 24,
        defaultTintColor: FuturisticColors.cyan,
        defaultTintOpacity: 0.12,
      ),
    ],
  );
}

ThemeData get futuristicLightTheme {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: const Color(0xFFE8F3FA),
    colorScheme: ColorScheme.fromSeed(
      seedColor: FuturisticColors.cyan,
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFF087F9B),
      secondary: const Color(0xFF6750A4),
      surface: const Color(0xFFF4FAFF),
      onSurface: const Color(0xFF10202B),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Color(0xFF10202B),
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: Color(0xFF087F9B)),
    ),
    cardTheme: const CardThemeData(
      color: Color(0xCCF4FAFF),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: Color(0x5587B8C8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x5587B8C8)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0x220087A8),
        foregroundColor: const Color(0xFF087F9B),
        elevation: 0,
        side: const BorderSide(color: Color(0x88087F9B)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    dividerColor: const Color(0x3387B8C8),
    extensions: const [
      LiquidGlassTheme(
        defaultBlurSigma: 24,
        defaultTintColor: Color(0xFF087F9B),
        defaultTintOpacity: 0.10,
      ),
    ],
  );
}
