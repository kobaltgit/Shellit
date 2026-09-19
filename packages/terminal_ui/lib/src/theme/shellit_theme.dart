import 'package:flutter/material.dart';

/// Design system color constants and Theme configuration for Shellit.
class ShellitColors {
  const ShellitColors._();

  // Backgrounds
  static const Color obsidianBackground = Color(0xFF151824);
  static const Color obsidianCard = Color(0xFF1E2235);
  static const Color obsidianCardHover = Color(0xFF262B42);
  static const Color obsidianSidebar = Color(0xFF11141F);
  static const Color obsidianHeader = Color(0xFF191D2C);

  // Borders & Dividers
  static const Color border = Color(0xFF2A2F4C);
  static const Color borderLight = Color(0xFF383F66);
  static const Color borderFocus = Color(0xFF3B82F6);

  // Accent & Brand Colors
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentPurple = Color(0xFF8B5CF6);

  // Status & Health Colors
  static const Color statusGreen = Color(0xFF10B981); // Ping < 50ms, OK
  static const Color statusYellow = Color(0xFFF59E0B); // Ping < 200ms, STAGE
  static const Color statusOrange = Color(0xFFF97316); // Ping >= 200ms, Slow
  static const Color statusRed =
      Color(0xFFEF4444); // PROD, Ping offline / timeout, Error
  static const Color statusGrey = Color(0xFF6B7280); // Offline / unreachable

  // Environment badge colors
  static const Color envProdBg = Color(0x33EF4444);
  static const Color envProdText = Color(0xFFEF4444);
  static const Color envStageBg = Color(0x33F59E0B);
  static const Color envStageText = Color(0xFFF59E0B);
  static const Color envDevBg = Color(0x333B82F6);
  static const Color envDevText = Color(0xFF60A5FA);

  // Text Colors
  static const Color textPrimary = Color(0xFFF3F4F6);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textDark = Color(0xFF111827);
}

/// Theme provider & factory for Shellit.
class ShellitTheme {
  const ShellitTheme._();

  static ThemeData get obsidianDarkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: ShellitColors.obsidianBackground,
      colorScheme: const ColorScheme.dark(
        primary: ShellitColors.accentBlue,
        secondary: ShellitColors.accentCyan,
        surface: ShellitColors.obsidianCard,
        error: ShellitColors.statusRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: ShellitColors.textPrimary,
        onError: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: ShellitColors.obsidianCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: ShellitColors.border, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: ShellitColors.border,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ShellitColors.obsidianHeader,
        foregroundColor: ShellitColors.textPrimary,
        elevation: 0,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: ShellitColors.textPrimary,
        displayColor: ShellitColors.textPrimary,
        fontFamily: 'JetBrains Mono',
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ShellitColors.obsidianCard,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle:
            const TextStyle(color: ShellitColors.textMuted, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ShellitColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ShellitColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: ShellitColors.accentBlue, width: 1.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ShellitColors.obsidianCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: ShellitColors.border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ShellitColors.obsidianCard,
        contentTextStyle: const TextStyle(
          color: ShellitColors.textPrimary,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: ShellitColors.border),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
