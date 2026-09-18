/// Utilities for parsing and stripping ANSI escape sequences and terminal control codes.
class AnsiUtils {
  AnsiUtils._();

  /// Regex pattern matching ANSI CSI, OSC, and single-char escape codes.
  static final RegExp _ansiRegex = RegExp(
    r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~]|\].*?(?:\x07|\x1B\\))',
  );

  /// Strips all ANSI escape sequences from [input], returning clean plain text.
  static String stripAnsi(String input) {
    if (input.isEmpty) return input;
    return input.replaceAll(_ansiRegex, '');
  }

  /// Normalizes terminal newlines (\r\n -> \n, stray \r -> \n).
  static String normalizeLineEndings(String input) {
    return input.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  }

  /// Cleans terminal output for human-readable logs by stripping ANSI codes
  /// and normalizing newlines.
  static String cleanTerminalOutput(String input) {
    return normalizeLineEndings(stripAnsi(input));
  }
}
