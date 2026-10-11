import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider holding the active terminal font family name.
/// Defaults to 'JetBrains Mono' and synchronizes with VaultSettings.
final terminalFontFamilyProvider = StateProvider<String>((ref) {
  return 'JetBrains Mono';
});

/// Standard fallback font family chain providing broad coverage for
/// Nerd Fonts glyphs (PUA U+E000..U+F8FF), CJK, and emojis.
const List<String> kTerminalFontFallbacks = [
  'JetBrainsMono Nerd Font',
  'JetBrainsMono NFM',
  'FiraCode Nerd Font',
  'FiraCode NFM',
  'Symbols Nerd Font Mono',
  'DejaVu Sans Mono',
  'Noto Sans Mono CJK SC',
  'Noto Color Emoji',
  'monospace',
];
