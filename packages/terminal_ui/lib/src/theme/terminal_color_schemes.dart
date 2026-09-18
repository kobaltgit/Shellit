import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

/// Predefined color schemes for the xterm terminal renderer.
class TerminalColorSchemes {
  const TerminalColorSchemes._();

  /// Default Obsidian Dark theme matching Shellit App Shell (#151824)
  static const TerminalTheme obsidianDark = TerminalTheme(
    cursor: Color(0xFF60A5FA),
    selection: Color(0x503B82F6),
    foreground: Color(0xFFE2E8F0),
    background: Color(0xFF151824),
    black: Color(0xFF1E2235),
    red: Color(0xFFEF4444),
    green: Color(0xFF10B981),
    yellow: Color(0xFFF59E0B),
    blue: Color(0xFF3B82F6),
    magenta: Color(0xFF8B5CF6),
    cyan: Color(0xFF06B6D4),
    white: Color(0xFFCBD5E1),
    brightBlack: Color(0xFF64748B),
    brightRed: Color(0xFFF87171),
    brightGreen: Color(0xFF34D399),
    brightYellow: Color(0xFFFBBF24),
    brightBlue: Color(0xFF60A5FA),
    brightMagenta: Color(0xFFA78BFA),
    brightCyan: Color(0xFF22D3EE),
    brightWhite: Color(0xFFF8FAFC),
    searchHitBackground: Color(0x60F59E0B),
    searchHitBackgroundCurrent: Color(0xFFF59E0B),
    searchHitForeground: Color(0xFF111827),
  );

  /// Dracula Theme
  static const TerminalTheme dracula = TerminalTheme(
    cursor: Color(0xFFF8F8F2),
    selection: Color(0x4444475A),
    foreground: Color(0xFFF8F8F2),
    background: Color(0xFF282A36),
    black: Color(0xFF21222C),
    red: Color(0xFFFF5555),
    green: Color(0xFF50FA7B),
    yellow: Color(0xFFF1FA8C),
    blue: Color(0xFFBD93F9),
    magenta: Color(0xFFFF79C6),
    cyan: Color(0xFF8BE9FD),
    white: Color(0xFFF8F8F2),
    brightBlack: Color(0xFF6272A4),
    brightRed: Color(0xFFFF6E6E),
    brightGreen: Color(0xFF69FF94),
    brightYellow: Color(0xFFFFFFA5),
    brightBlue: Color(0xFFD6ACFF),
    brightMagenta: Color(0xFFFF92DF),
    brightCyan: Color(0xFFA4FFFF),
    brightWhite: Color(0xFFFFFFFF),
    searchHitBackground: Color(0x60F1FA8C),
    searchHitBackgroundCurrent: Color(0xFFF1FA8C),
    searchHitForeground: Color(0xFF282A36),
  );

  /// Nord Theme
  static const TerminalTheme nord = TerminalTheme(
    cursor: Color(0xFFD8DEE9),
    selection: Color(0x444C566A),
    foreground: Color(0xFFD8DEE9),
    background: Color(0xFF2E3440),
    black: Color(0xFF3B4252),
    red: Color(0xFFBF616A),
    green: Color(0xFFA3BE8C),
    yellow: Color(0xFFEBCB8B),
    blue: Color(0xFF81A1C1),
    magenta: Color(0xFFB48EAD),
    cyan: Color(0xFF88C0D0),
    white: Color(0xFFE5E9F0),
    brightBlack: Color(0xFF4C566A),
    brightRed: Color(0xFFD08770),
    brightGreen: Color(0xFFA3BE8C),
    brightYellow: Color(0xFFEBCB8B),
    brightBlue: Color(0xFF81A1C1),
    brightMagenta: Color(0xFFB48EAD),
    brightCyan: Color(0xFF8FBCBB),
    brightWhite: Color(0xFFECEFF4),
    searchHitBackground: Color(0x6088C0D0),
    searchHitBackgroundCurrent: Color(0xFF88C0D0),
    searchHitForeground: Color(0xFF2E3440),
  );

  /// OLED True Black Theme (ideal for mobile OLED displays)
  static const TerminalTheme oledTrueBlack = TerminalTheme(
    cursor: Color(0xFF00FF66),
    selection: Color(0x44333333),
    foreground: Color(0xFFFFFFFF),
    background: Color(0xFF000000),
    black: Color(0xFF111111),
    red: Color(0xFFFF3333),
    green: Color(0xFF00FF66),
    yellow: Color(0xFFFFDD00),
    blue: Color(0xFF3399FF),
    magenta: Color(0xFFFF33CC),
    cyan: Color(0xFF00FFFF),
    white: Color(0xFFEEEEEE),
    brightBlack: Color(0xFF444444),
    brightRed: Color(0xFFFF6666),
    brightGreen: Color(0xFF66FF99),
    brightYellow: Color(0xFFFFFF66),
    brightBlue: Color(0xFF66B2FF),
    brightMagenta: Color(0xFFFF66DD),
    brightCyan: Color(0xFF66FFFF),
    brightWhite: Color(0xFFFFFFFF),
    searchHitBackground: Color(0x60FFDD00),
    searchHitBackgroundCurrent: Color(0xFFFFDD00),
    searchHitForeground: Color(0xFF000000),
  );

  /// Cyberpunk Neon Theme
  static const TerminalTheme cyberpunk = TerminalTheme(
    cursor: Color(0xFF00FF9F),
    selection: Color(0x44711C91),
    foreground: Color(0xFFFEE801),
    background: Color(0xFF0D0B18),
    black: Color(0xFF131124),
    red: Color(0xFFFF0055),
    green: Color(0xFF00FF9F),
    yellow: Color(0xFFFEE801),
    blue: Color(0xFF00E8FF),
    magenta: Color(0xFFD600FF),
    cyan: Color(0xFF00F0FF),
    white: Color(0xFFF1F1F1),
    brightBlack: Color(0xFF3B2F5C),
    brightRed: Color(0xFFFF3377),
    brightGreen: Color(0xFF33FFAF),
    brightYellow: Color(0xFFFFF033),
    brightBlue: Color(0xFF33ECFF),
    brightMagenta: Color(0xFFDE33FF),
    brightCyan: Color(0xFF33F3FF),
    brightWhite: Color(0xFFFFFFFF),
    searchHitBackground: Color(0x60FF0055),
    searchHitBackgroundCurrent: Color(0xFFFF0055),
    searchHitForeground: Color(0xFF0D0B18),
  );

  static final Map<String, TerminalTheme> allSchemes = {
    'Obsidian Dark': obsidianDark,
    'Dracula': dracula,
    'Nord': nord,
    'OLED True Black': oledTrueBlack,
    'Cyberpunk': cyberpunk,
  };
}
