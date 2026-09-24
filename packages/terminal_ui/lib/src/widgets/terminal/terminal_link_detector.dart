import 'package:xterm/xterm.dart';

/// Type of link detected in terminal output.
enum TerminalLinkType {
  url,
  filePath,
}

/// Information about a detected link or file path in the terminal buffer.
class TerminalLinkMatch {
  final String text;
  final String rawText;
  final TerminalLinkType type;
  final int startIndex;
  final int endIndex;
  final int? lineNumber;
  final int? columnNumber;

  const TerminalLinkMatch({
    required this.text,
    required this.rawText,
    required this.type,
    required this.startIndex,
    required this.endIndex,
    this.lineNumber,
    this.columnNumber,
  });

  bool get isUrl => type == TerminalLinkType.url;
  bool get isFilePath => type == TerminalLinkType.filePath;

  @override
  String toString() =>
      'TerminalLinkMatch($type: "$text", line: $lineNumber, range: [$startIndex, $endIndex])';
}

/// Detection engine for URLs and file paths in the terminal buffer and strings.
class TerminalLinkDetector {
  TerminalLinkDetector._();

  // URL pattern: matches http, https, ftp, git, ssh
  static final RegExp _urlRegex = RegExp(
    r'(?:https?|ftp|git|ssh):\/\/[a-zA-Z0-9_\-\.\:\@\%\+~#=\?&/]+',
    caseSensitive: false,
  );

  // WWW URL pattern (www.example.com)
  static final RegExp _wwwRegex = RegExp(
    r"""(?:^|[\s\(\[\{"'])www\.[a-zA-Z0-9_\-\.\:\@\%\+~#=\?&/]+""",
    caseSensitive: false,
  );

  // File path patterns
  static final RegExp _unixAbsolutePathRegex = RegExp(
    r'(?:/[a-zA-Z0-9_.\-]+)+/?(?::\d+(?::\d+)?)?',
  );

  static final RegExp _unixHomePathRegex = RegExp(
    r'~/(?:[a-zA-Z0-9_.\-]+/?)+(?::\d+(?::\d+)?)?',
  );

  static final RegExp _relativePathRegex = RegExp(
    r'(?:\.\/|\.\.\/)(?:[a-zA-Z0-9_.\-]+/?)+(?::\d+(?::\d+)?)?',
  );

  static final RegExp _windowsPathRegex = RegExp(
    r'[a-zA-Z]:\\(?:[a-zA-Z0-9_.\- ]+\\?)+(?::\d+(?::\d+)?)?',
  );

  /// Cleans trailing punctuation often attached to URLs and file paths in logs.
  static String _trimTrailingPunctuation(String input) {
    var trimmed = input;
    const trailingChars = {
      '.',
      ',',
      ';',
      ':',
      '!',
      '?',
      ')',
      ']',
      '}',
      '"',
      "'",
      '`',
      '>'
    };
    while (trimmed.isNotEmpty &&
        trailingChars.contains(trimmed[trimmed.length - 1])) {
      // If closing bracket/paren, only trim if no matching open bracket in trimmed
      final last = trimmed[trimmed.length - 1];
      if (last == ')' && trimmed.contains('(')) break;
      if (last == ']' && trimmed.contains('[')) break;
      if (last == '}' && trimmed.contains('{')) break;
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  /// Extracts path and optional line/column number from string like "/var/log/syslog:42:10".
  static ({String cleanPath, int? line, int? col}) _extractPathAndLine(
      String raw) {
    final lineMatch = RegExp(r':(\d+)(?::(\d+))?$').firstMatch(raw);
    if (lineMatch != null) {
      final line = int.tryParse(lineMatch.group(1) ?? '');
      final col = int.tryParse(lineMatch.group(2) ?? '');
      final pathWithoutLine = raw.substring(0, lineMatch.start);
      return (cleanPath: pathWithoutLine, line: line, col: col);
    }
    return (cleanPath: raw, line: null, col: null);
  }

  /// Detects all URLs and file paths in a single string.
  static List<TerminalLinkMatch> detectLinks(String text) {
    if (text.trim().isEmpty) return const [];

    final matches = <TerminalLinkMatch>[];
    final occupiedRanges = <(int, int)>[];

    bool isOverlapping(int start, int end) {
      for (final range in occupiedRanges) {
        if (start < range.$2 && end > range.$1) return true;
      }
      return false;
    }

    // 1. Detect Web URLs first (higher priority than paths)
    for (final m in _urlRegex.allMatches(text)) {
      final raw = m.group(0)!;
      final clean = _trimTrailingPunctuation(raw);
      if (clean.length < 8) continue; // http://a is min 8 chars
      final end = m.start + clean.length;
      if (!isOverlapping(m.start, end)) {
        occupiedRanges.add((m.start, end));
        matches.add(
          TerminalLinkMatch(
            text: clean,
            rawText: raw,
            type: TerminalLinkType.url,
            startIndex: m.start,
            endIndex: end,
          ),
        );
      }
    }

    // 2. Detect WWW URLs (e.g. www.google.com)
    for (final m in _wwwRegex.allMatches(text)) {
      var raw = m.group(0)!;
      var start = m.start;
      // If matched leading boundary character, strip it
      if (raw.isNotEmpty &&
          (raw.startsWith(' ') ||
              raw.startsWith('\t') ||
              raw.startsWith('(') ||
              raw.startsWith('[') ||
              raw.startsWith('{') ||
              raw.startsWith('"') ||
              raw.startsWith("'"))) {
        raw = raw.substring(1);
        start += 1;
      }
      final clean = _trimTrailingPunctuation(raw);
      if (clean.length < 6) continue; // www.a.co
      final end = start + clean.length;
      if (!isOverlapping(start, end)) {
        occupiedRanges.add((start, end));
        matches.add(
          TerminalLinkMatch(
            text: 'https://$clean',
            rawText: raw,
            type: TerminalLinkType.url,
            startIndex: start,
            endIndex: end,
          ),
        );
      }
    }

    // 3. Detect Windows paths
    for (final m in _windowsPathRegex.allMatches(text)) {
      final raw = m.group(0)!;
      final clean = _trimTrailingPunctuation(raw);
      final parsed = _extractPathAndLine(clean);
      final end = m.start + clean.length;
      if (!isOverlapping(m.start, end) && parsed.cleanPath.length >= 4) {
        occupiedRanges.add((m.start, end));
        matches.add(
          TerminalLinkMatch(
            text: parsed.cleanPath,
            rawText: raw,
            type: TerminalLinkType.filePath,
            startIndex: m.start,
            endIndex: end,
            lineNumber: parsed.line,
            columnNumber: parsed.col,
          ),
        );
      }
    }

    // 4. Detect Unix Home paths (~/...)
    for (final m in _unixHomePathRegex.allMatches(text)) {
      final raw = m.group(0)!;
      final clean = _trimTrailingPunctuation(raw);
      final parsed = _extractPathAndLine(clean);
      final end = m.start + clean.length;
      if (!isOverlapping(m.start, end) && parsed.cleanPath.length >= 3) {
        occupiedRanges.add((m.start, end));
        matches.add(
          TerminalLinkMatch(
            text: parsed.cleanPath,
            rawText: raw,
            type: TerminalLinkType.filePath,
            startIndex: m.start,
            endIndex: end,
            lineNumber: parsed.line,
            columnNumber: parsed.col,
          ),
        );
      }
    }

    // 5. Detect Relative paths (./... or ../...)
    for (final m in _relativePathRegex.allMatches(text)) {
      final raw = m.group(0)!;
      final clean = _trimTrailingPunctuation(raw);
      final parsed = _extractPathAndLine(clean);
      final end = m.start + clean.length;
      if (!isOverlapping(m.start, end) && parsed.cleanPath.length >= 3) {
        occupiedRanges.add((m.start, end));
        matches.add(
          TerminalLinkMatch(
            text: parsed.cleanPath,
            rawText: raw,
            type: TerminalLinkType.filePath,
            startIndex: m.start,
            endIndex: end,
            lineNumber: parsed.line,
            columnNumber: parsed.col,
          ),
        );
      }
    }

    // 6. Detect Absolute Unix paths (/var/log/...)
    for (final m in _unixAbsolutePathRegex.allMatches(text)) {
      final raw = m.group(0)!;
      final clean = _trimTrailingPunctuation(raw);
      final parsed = _extractPathAndLine(clean);
      final end = m.start + clean.length;
      // Filter out root "/" alone or simple flags "/a"
      if (!isOverlapping(m.start, end) &&
          parsed.cleanPath.length >= 2 &&
          parsed.cleanPath != '/' &&
          parsed.cleanPath.split('/').where((s) => s.isNotEmpty).length >= 1) {
        // Exclude common cli flag false positives like /dev/null is ok, but not /v /f
        final segments =
            parsed.cleanPath.split('/').where((s) => s.isNotEmpty).toList();
        if (segments.length >= 2 ||
            (segments.length == 1 && segments.first.length > 2)) {
          occupiedRanges.add((m.start, end));
          matches.add(
            TerminalLinkMatch(
              text: parsed.cleanPath,
              rawText: raw,
              type: TerminalLinkType.filePath,
              startIndex: m.start,
              endIndex: end,
              lineNumber: parsed.line,
              columnNumber: parsed.col,
            ),
          );
        }
      }
    }

    matches.sort((a, b) => a.startIndex.compareTo(b.startIndex));
    return matches;
  }

  /// Finds link match at the specified [offset] within the [terminal] buffer.
  /// Seamlessly stitches together wrapped visual lines if line was broken across width.
  static TerminalLinkMatch? findMatchAtOffset(
      Terminal terminal, CellOffset offset) {
    final buffer = terminal.buffer;
    if (offset.y < 0 || offset.y >= buffer.lines.length) return null;

    // 1. Locate start of continuous logical line
    var startRow = offset.y;
    while (startRow > 0 && buffer.lines[startRow].isWrapped) {
      startRow--;
    }

    // 2. Locate end of continuous logical line
    var endRow = offset.y;
    while (endRow < buffer.lines.length - 1 &&
        buffer.lines[endRow + 1].isWrapped) {
      endRow++;
    }

    // 3. Assemble continuous logical text preserving exact column offsets
    final sb = StringBuffer();
    int cursorCharIndex = 0;

    for (var r = startRow; r <= endRow; r++) {
      final line = buffer.lines[r];
      final cols = (r < endRow) ? terminal.viewWidth : line.getTrimmedLength();

      if (r == offset.y && offset.x >= cols) {
        // Cursor is beyond content on this line
        return null;
      }

      for (var col = 0; col < cols; col++) {
        if (r == offset.y && col == offset.x) {
          cursorCharIndex = sb.length;
        }
        final cp = line.getCodePoint(col);
        sb.writeCharCode(cp == 0 ? 32 : cp);
      }
    }

    final fullLogicalText = sb.toString();
    if (fullLogicalText.trim().isEmpty) return null;

    final allMatches = detectLinks(fullLogicalText);
    for (final match in allMatches) {
      if (match.startIndex <= cursorCharIndex &&
          cursorCharIndex < match.endIndex) {
        return match;
      }
    }

    return null;
  }

  /// Finds match in selected or arbitrary text.
  static TerminalLinkMatch? findMatchInText(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final matches = detectLinks(text.trim());
    return matches.isNotEmpty ? matches.first : null;
  }
}
