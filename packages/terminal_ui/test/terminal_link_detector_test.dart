import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/src/widgets/terminal/terminal_link_detector.dart';
import 'package:xterm/xterm.dart';

void main() {
  group('TerminalLinkDetector string pattern detection tests', () {
    test('detects HTTP and HTTPS URLs', () {
      const text =
          'Server listening on http://127.0.0.1:8080/api/v1 and docs at https://github.com/kobaltgit/Shellit?tab=readme.';
      final matches = TerminalLinkDetector.detectLinks(text);

      expect(matches.length, 2);
      expect(matches[0].type, TerminalLinkType.url);
      expect(matches[0].text, 'http://127.0.0.1:8080/api/v1');

      expect(matches[1].type, TerminalLinkType.url);
      expect(
          matches[1].text, 'https://github.com/kobaltgit/Shellit?tab=readme');
    });

    test('trims trailing punctuation from URLs and paths in logs', () {
      const text =
          'Check (https://example.com/test), or file at "/var/log/syslog", and [./config.json].';
      final matches = TerminalLinkDetector.detectLinks(text);

      expect(matches.length, 3);
      expect(matches[0].text, 'https://example.com/test');
      expect(matches[1].text, '/var/log/syslog');
      expect(matches[2].text, './config.json');
    });

    test('detects Unix absolute paths and line numbers', () {
      const text = 'Exception thrown at /var/www/project/lib/main.dart:42:15';
      final matches = TerminalLinkDetector.detectLinks(text);

      expect(matches.length, 1);
      expect(matches[0].type, TerminalLinkType.filePath);
      expect(matches[0].text, '/var/www/project/lib/main.dart');
      expect(matches[0].lineNumber, 42);
      expect(matches[0].columnNumber, 15);
    });

    test('detects Unix home paths (~/)', () {
      const text = 'Identity stored in ~/.ssh/id_ed25519 for host';
      final matches = TerminalLinkDetector.detectLinks(text);

      expect(matches.length, 1);
      expect(matches[0].type, TerminalLinkType.filePath);
      expect(matches[0].text, '~/.ssh/id_ed25519');
    });

    test('detects relative paths (./ and ../)', () {
      const text = 'Run ./scripts/build.sh or check ../logs/deploy.log';
      final matches = TerminalLinkDetector.detectLinks(text);

      expect(matches.length, 2);
      expect(matches[0].text, './scripts/build.sh');
      expect(matches[1].text, '../logs/deploy.log');
    });

    test('detects Windows absolute paths', () {
      const text =
          r'Project located at D:\Projects\active\Shellit\pubspec.yaml';
      final matches = TerminalLinkDetector.detectLinks(text);

      expect(matches.length, 1);
      expect(matches[0].type, TerminalLinkType.filePath);
      expect(matches[0].text, r'D:\Projects\active\Shellit\pubspec.yaml');
    });

    test('ignores empty or unrelated text without false positives', () {
      const text =
          'Regular text with simple words, numbers 12345, / alone, or --flags';
      final matches = TerminalLinkDetector.detectLinks(text);

      expect(matches.isEmpty, isTrue);
    });
  });

  group('TerminalLinkDetector buffer offset detection tests', () {
    test('findMatchAtOffset locates URL at exact cell coordinates', () {
      final terminal = Terminal(maxLines: 100);
      terminal.write('Output: https://shellit.dev/download now\r\n');

      // 'https://shellit.dev/download' starts at column 8
      const cellInsideUrl = CellOffset(12, 0);
      final match =
          TerminalLinkDetector.findMatchAtOffset(terminal, cellInsideUrl);

      expect(match, isNotNull);
      expect(match!.isUrl, isTrue);
      expect(match.text, 'https://shellit.dev/download');

      // Click outside URL on word 'now' (around col 38)
      const cellOutsideUrl = CellOffset(2, 0);
      final outsideMatch =
          TerminalLinkDetector.findMatchAtOffset(terminal, cellOutsideUrl);
      expect(outsideMatch, isNull);
    });

    test('findMatchAtOffset locates file path at cell coordinates', () {
      final terminal = Terminal(maxLines: 100);
      terminal.write('Logs saved to /var/log/nginx/access.log\r\n');

      const cellInsidePath = CellOffset(20, 0);
      final match =
          TerminalLinkDetector.findMatchAtOffset(terminal, cellInsidePath);

      expect(match, isNotNull);
      expect(match!.isFilePath, isTrue);
      expect(match.text, '/var/log/nginx/access.log');
    });

    test('detects www links and prepends https://', () {
      const text = 'Visit www.shellit.dev or docs at (www.github.com)';
      final matches = TerminalLinkDetector.detectLinks(text);

      expect(matches.length, 2);
      expect(matches[0].text, 'https://www.shellit.dev');
      expect(matches[1].text, 'https://www.github.com');
    });

    test('findMatchAtOffset returns null when hovering past line content', () {
      final terminal = Terminal(maxLines: 100);
      terminal.write('Short: https://shellit.dev\r\n');

      // Col 60 is far past the line content
      const pastBounds = CellOffset(60, 0);
      final match =
          TerminalLinkDetector.findMatchAtOffset(terminal, pastBounds);
      expect(match, isNull);
    });
  });
}
