import 'package:core_foundation/core_foundation.dart';
import 'package:test/test.dart';

void main() {
  group('AnsiUtils Tests', () {
    test('stripAnsi removes 256-color, cursor, and mode sequences', () {
      const raw = '\x1B[?2004l\x1B[>c\x1B[>4m\x1B[=0;1u\x1B[?1049h\x1B[?25l'
          'Welcome to the \x1B[38;5;69mAntigravity CLI\x1B[0m. You are currently not signed in.';

      final cleaned = AnsiUtils.stripAnsi(raw);
      expect(
        cleaned,
        equals(
            'Welcome to the Antigravity CLI. You are currently not signed in.'),
      );
    });

    test('normalizeLineEndings converts \r\n and \r to \n', () {
      const raw = 'Line 1\r\nLine 2\rLine 3\n';
      expect(AnsiUtils.normalizeLineEndings(raw),
          equals('Line 1\nLine 2\nLine 3\n'));
    });

    test('cleanTerminalOutput handles mixed escape codes and newlines cleanly',
        () {
      const raw = '\x1B[32mSigning In...\x1B[0m\r\n'
          '\x1B[38;5;149;48;5;113mantigravity\x1B[0m\r\n';

      final cleaned = AnsiUtils.cleanTerminalOutput(raw);
      expect(cleaned, equals('Signing In...\nantigravity\n'));
    });
  });
}
