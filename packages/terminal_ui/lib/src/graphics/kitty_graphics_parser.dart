import 'dart:convert';
import 'dart:typed_data';
import 'kitty_graphics_types.dart';

/// Filter and parser that intercepts Kitty Graphics Protocol escape sequences
/// (`\x1b_G ... \x1b\` or `\x1b_G ... \x07`) from the terminal byte stream.
///
/// Strips the large base64 image data before it enters xterm.dart's text buffer,
/// preventing UI freezes, terminal corruption, or buffer flooding.
class KittyGraphicsStreamFilter {
  final List<int> _holdBuffer = [];

  /// Processes an incoming [chunk] of terminal bytes.
  /// Returns a tuple with [cleanBytes] to pass to `_terminal.write()` and
  /// any extracted [commands] for image rendering.
  KittyFilterResult processBytes(Uint8List chunk) {
    final List<int> input =
        _holdBuffer.isEmpty ? chunk : [..._holdBuffer, ...chunk];
    _holdBuffer.clear();

    final List<int> cleanBytes = [];
    final List<KittyImageCommand> commands = [];

    int i = 0;
    final int len = input.length;

    while (i < len) {
      // Check for ESC _ G prefix (0x1B, 0x5F, 0x47)
      if (input[i] == 0x1B &&
          i + 2 < len &&
          input[i + 1] == 0x5F &&
          input[i + 2] == 0x47) {
        final int startIndex = i;
        int endIndex = -1;
        int terminatorLen = 0;

        // Scan for terminator: ST (ESC \ = 0x1B, 0x5C) or BEL (0x07) or 8-bit ST (0x9C)
        for (int j = i + 3; j < len; j++) {
          if (input[j] == 0x07) {
            endIndex = j;
            terminatorLen = 1;
            break;
          } else if (input[j] == 0x9C) {
            endIndex = j;
            terminatorLen = 1;
            break;
          } else if (input[j] == 0x1B && j + 1 < len && input[j + 1] == 0x5C) {
            endIndex = j;
            terminatorLen = 2;
            break;
          }
        }

        if (endIndex == -1) {
          // Incomplete Kitty sequence split across chunks: hold from startIndex onwards
          _holdBuffer.addAll(input.sublist(startIndex));
          break;
        }

        // Full sequence found: extract content between prefix and terminator
        final sequenceBytes = input.sublist(startIndex + 3, endIndex);
        final command = _parseKittySequence(sequenceBytes);
        if (command != null) {
          commands.add(command);
        }

        i = endIndex + terminatorLen;
      } else {
        cleanBytes.add(input[i]);
        i++;
      }
    }

    return KittyFilterResult(
      cleanBytes: Uint8List.fromList(cleanBytes),
      commands: commands,
    );
  }

  /// Parses the internal payload of `ESC _ G ... ST`
  KittyImageCommand? _parseKittySequence(List<int> bytes) {
    try {
      final text = utf8.decode(bytes, allowMalformed: true);
      final semicolonIdx = text.indexOf(';');
      final String controlString;
      final String payloadString;

      if (semicolonIdx != -1) {
        controlString = text.substring(0, semicolonIdx);
        payloadString = text.substring(semicolonIdx + 1).trim();
      } else {
        controlString = text;
        payloadString = '';
      }

      // Parse control parameters: key=val,key=val...
      final Map<String, String> params = {};
      for (final pair in controlString.split(',')) {
        final eqIdx = pair.indexOf('=');
        if (eqIdx != -1) {
          final k = pair.substring(0, eqIdx).trim();
          final v = pair.substring(eqIdx + 1).trim();
          params[k] = v;
        }
      }

      // 1. Action
      final actionStr = params['a'] ?? 't';
      final KittyAction action;
      switch (actionStr) {
        case 't':
          action = KittyAction.transmitAndDisplay;
          break;
        case 'T':
          action = KittyAction.transmitDisplayAndSet;
          break;
        case 'p':
          action = KittyAction.put;
          break;
        case 'd':
          action = KittyAction.delete;
          break;
        case 'q':
          action = KittyAction.query;
          break;
        default:
          action = KittyAction.transmitAndDisplay;
      }

      // 2. Format
      final formatStr = params['f'] ?? '32';
      final KittyFormat format;
      switch (formatStr) {
        case '100':
          format = KittyFormat.png;
          break;
        case '24':
          format = KittyFormat.rgb24;
          break;
        case '32':
        default:
          format = KittyFormat.rgba32;
          break;
      }

      final imageId = int.tryParse(params['i'] ?? '');
      final placementId = int.tryParse(params['p'] ?? '');
      final columns = int.tryParse(params['c'] ?? '');
      final rows = int.tryParse(params['r'] ?? '');
      final width = int.tryParse(params['s'] ?? '');
      final height = int.tryParse(params['v'] ?? '');
      final hasMoreChunks = params['m'] == '1';
      final quiet = int.tryParse(params['q'] ?? '') ?? 0;

      Uint8List? payload;
      if (payloadString.isNotEmpty) {
        try {
          payload = base64.decode(payloadString);
        } catch (_) {
          // Fallback if base64 has whitespace or invalid characters
          final cleanBase64 = payloadString.replaceAll(RegExp(r'\s+'), '');
          payload = base64.decode(cleanBase64);
        }
      }

      return KittyImageCommand(
        action: action,
        imageId: imageId,
        placementId: placementId,
        format: format,
        columns: columns,
        rows: rows,
        width: width,
        height: height,
        hasMoreChunks: hasMoreChunks,
        payload: payload,
        quiet: quiet,
      );
    } catch (_) {
      return null;
    }
  }

  void reset() {
    _holdBuffer.clear();
  }
}

/// Result of filtering terminal bytes.
class KittyFilterResult {
  final Uint8List cleanBytes;
  final List<KittyImageCommand> commands;

  const KittyFilterResult({
    required this.cleanBytes,
    required this.commands,
  });
}
