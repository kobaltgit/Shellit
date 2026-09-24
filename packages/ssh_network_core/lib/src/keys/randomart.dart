import 'dart:convert';
import 'dart:typed_data';

/// OpenSSH Drunken Bishop algorithm implementation for visual key fingerprint representation (Randomart).
///
/// Converts a raw cryptographic digest (e.g. SHA256, MD5) or a fingerprint string
/// into an ASCII art box, matching OpenSSH `ssh-keygen -lv` format.
class Randomart {
  /// Width of the inner field grid in characters (17 columns).
  static const int gridWidth = 17;

  /// Height of the inner field grid in characters (9 rows).
  static const int gridHeight = 9;

  /// Start column coordinate in the 17x9 grid (center).
  static const int startX = 8;

  /// Start row coordinate in the 17x9 grid (center).
  static const int startY = 4;

  /// Frequency augmentation symbols matching OpenSSH key.c.
  /// Each character corresponds to the number of visits to that position.
  static const String symbols = ' .o+=*BOX@%&#/^';

  /// Generates the randomart ASCII box string for raw byte values.
  ///
  /// [bytes] is the raw digest bytes (e.g., 16 bytes for MD5 or 32 bytes for SHA256).
  /// [title] is an optional top border label, such as `'ED25519 256'` or `'RSA 2048'`.
  /// [hashAlgorithm] is an optional bottom border label, such as `'SHA256'` or `'MD5'`.
  static String fromBytes(
    List<int> bytes, {
    String? title,
    String? hashAlgorithm,
  }) {
    final grid = List.generate(
      gridHeight,
      (_) => List.filled(gridWidth, 0),
    );

    var x = startX;
    var y = startY;

    for (final b in bytes) {
      var byteVal = b;
      for (var step = 0; step < 4; step++) {
        final dx = (byteVal & 0x1) != 0 ? 1 : -1;
        final dy = (byteVal & 0x2) != 0 ? 1 : -1;

        x = (x + dx).clamp(0, gridWidth - 1);
        y = (y + dy).clamp(0, gridHeight - 1);

        grid[y][x]++;
        byteVal >>= 2;
      }
    }

    final endX = x;
    final endY = y;

    final buffer = StringBuffer();
    buffer.writeln(_formatBorder(title));

    for (var r = 0; r < gridHeight; r++) {
      buffer.write('|');
      for (var c = 0; c < gridWidth; c++) {
        // If end and start land on the same square, 'E' takes precedence (OpenSSH order)
        if (c == endX && r == endY) {
          buffer.write('E');
        } else if (c == startX && r == startY) {
          buffer.write('S');
        } else {
          final count = grid[r][c];
          final char = count >= symbols.length
              ? symbols[symbols.length - 1]
              : symbols[count];
          buffer.write(char);
        }
      }
      buffer.writeln('|');
    }

    buffer.write(_formatBorder(hashAlgorithm));
    return buffer.toString();
  }

  /// Generates randomart from a fingerprint string.
  ///
  /// Supports:
  /// - OpenSSH format: `'SHA256:uTh/swJ...='` or unpadded `'SHA256:uTh/swJ...'`
  /// - Hex format with colons: `'fc:94:b0:c1:...'` or `'MD5:fc:94:b0:...'`
  /// - Raw base64 string or raw hex string.
  static String fromFingerprint(
    String fingerprint, {
    String? title,
    String? hashAlgorithm,
  }) {
    var raw = fingerprint.trim();
    if (raw.isEmpty) {
      throw ArgumentError.value(fingerprint, 'fingerprint', 'Cannot be empty');
    }

    String? detectedAlgo;
    final prefixMatch = RegExp(r'^([A-Za-z0-9_-]+):(.*)$').firstMatch(raw);
    if (prefixMatch != null) {
      final possiblePrefix = prefixMatch.group(1)!;
      final remainder = prefixMatch.group(2)!;
      if (['SHA256', 'SHA1', 'SHA512', 'MD5']
          .contains(possiblePrefix.toUpperCase())) {
        detectedAlgo = possiblePrefix.toUpperCase();
        raw = remainder.trim();
      }
    }

    final effectiveAlgo = hashAlgorithm ?? detectedAlgo;
    final bytes = _decodeFingerprintBytes(raw);

    return fromBytes(
      bytes,
      title: title,
      hashAlgorithm: effectiveAlgo ?? (bytes.length == 32 ? 'SHA256' : null),
    );
  }

  /// Alias for [fromBytes].
  static String generate(
    List<int> bytes, {
    String? title,
    String? hashAlgorithm,
  }) =>
      fromBytes(bytes, title: title, hashAlgorithm: hashAlgorithm);

  static Uint8List _decodeFingerprintBytes(String raw) {
    // 1. Colon or space separated hex: 'fc:94:b0:...' or 'fc 94 b0...'
    if (raw.contains(':') || raw.contains(' ')) {
      final parts = raw.split(RegExp(r'[:\s]+')).where((p) => p.isNotEmpty);
      try {
        final list = parts.map((p) => int.parse(p, radix: 16)).toList();
        return Uint8List.fromList(list);
      } catch (_) {
        // Not valid hex parts, fallback to other decoders
      }
    }

    // 2. Pure hex string (32 hex chars for 16-byte MD5, 64 hex chars for 32-byte SHA256)
    if (RegExp(r'^[0-9a-fA-F]+$').hasMatch(raw) && raw.length % 2 == 0) {
      // Check if it's likely hex (MD5=32 chars, SHA1=40, SHA256=64)
      if (raw.length == 32 || raw.length == 40 || raw.length == 64) {
        try {
          final bytes = <int>[];
          for (var i = 0; i < raw.length; i += 2) {
            bytes.add(int.parse(raw.substring(i, i + 2), radix: 16));
          }
          return Uint8List.fromList(bytes);
        } catch (_) {}
      }
    }

    // 3. Base64 string (with or without '=' padding)
    var b64 = raw;
    final remainder = b64.length % 4;
    if (remainder != 0) {
      b64 += '=' * (4 - remainder);
    }

    try {
      return Uint8List.fromList(base64.decode(b64));
    } catch (e) {
      throw ArgumentError.value(
        raw,
        'fingerprint',
        'Could not parse fingerprint as hex or base64: $e',
      );
    }
  }

  static String _formatBorder(String? text) {
    if (text == null || text.trim().isEmpty) {
      return '+${'-' * gridWidth}+';
    }

    final trimmed = text.trim();
    final maxContent = gridWidth - 2;
    final content = trimmed.length > maxContent
        ? trimmed.substring(0, maxContent)
        : trimmed;
    final tag = '[$content]';

    final remaining = gridWidth - tag.length;
    final left = remaining ~/ 2;
    final right = remaining - left;

    return '+${'-' * left}$tag${'-' * right}+';
  }
}
