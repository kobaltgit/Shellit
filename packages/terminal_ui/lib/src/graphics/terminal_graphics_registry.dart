import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:xterm/xterm.dart';
import 'kitty_graphics_types.dart';

/// Positioned terminal image entry on the grid.
class TerminalImagePlacement {
  final int id;
  final ui.Image image;
  final int column;
  final int row;
  final int widthCells;
  final int heightCells;
  final BufferLine? bufferLine;

  const TerminalImagePlacement({
    required this.id,
    required this.image,
    required this.column,
    required this.row,
    required this.widthCells,
    required this.heightCells,
    this.bufferLine,
  });

  void dispose() {
    image.dispose();
  }
}

/// Registry that manages in-terminal images, multi-chunk decoding,
/// grid cell placement, and scrollback lifecycle.
class TerminalGraphicsRegistry extends ChangeNotifier {
  final List<TerminalImagePlacement> _placements = [];
  final Map<int, BytesBuilder> _chunkAccumulator = {};
  int _nextInternalId = 1;

  List<TerminalImagePlacement> get placements => List.unmodifiable(_placements);

  /// Processes an extracted [KittyImageCommand] with reference to the active [terminal].
  Future<void> handleCommand(
      KittyImageCommand command, Terminal terminal) async {
    switch (command.action) {
      case KittyAction.transmitAndDisplay:
      case KittyAction.transmitDisplayAndSet:
        await _handleTransmit(command, terminal);
        break;

      case KittyAction.delete:
        _handleDelete(command);
        break;

      case KittyAction.put:
      case KittyAction.query:
        // Query or re-put: handled as no-op or state query
        break;
    }
  }

  Future<void> _handleTransmit(
    KittyImageCommand command,
    Terminal terminal,
  ) async {
    final imageId = command.imageId ?? _nextInternalId++;

    if (command.payload != null && command.payload!.isNotEmpty) {
      _chunkAccumulator.putIfAbsent(imageId, () => BytesBuilder(copy: false));
      _chunkAccumulator[imageId]!.add(command.payload!);
    }

    if (command.hasMoreChunks) {
      // More chunks are coming, wait for m=0
      return;
    }

    // All chunks arrived: compile full byte array
    final accumulated = _chunkAccumulator.remove(imageId);
    final fullBytes =
        accumulated != null ? accumulated.takeBytes() : command.payload;
    if (fullBytes == null || fullBytes.isEmpty) return;

    try {
      final ui.Image decodedImage = await _decodeImage(
          fullBytes, command.format, command.width, command.height);

      final col = terminal.buffer.cursorX;
      final row = terminal.buffer.absoluteCursorY;

      // Determine dimensions in cells
      final widthCells =
          command.columns ?? ((decodedImage.width / 14).ceil().clamp(1, 120));
      final heightCells =
          command.rows ?? ((decodedImage.height / 24).ceil().clamp(1, 60));

      final lines = terminal.buffer.lines;
      final bufferLine = (row >= 0 && row < lines.length) ? lines[row] : null;

      final placement = TerminalImagePlacement(
        id: imageId,
        image: decodedImage,
        column: col,
        row: row,
        widthCells: widthCells,
        heightCells: heightCells,
        bufferLine: bufferLine,
      );

      _placements.add(placement);
      notifyListeners();
    } catch (_) {
      // Silently discard corrupted or unreadable images
    }
  }

  Future<ui.Image> _decodeImage(
    Uint8List bytes,
    KittyFormat format,
    int? width,
    int? height,
  ) async {
    if (format == KittyFormat.png || bytes.length >= 8 && _isPngHeader(bytes)) {
      final codec = await ui.instantiateImageCodec(bytes);
      final frameInfo = await codec.getNextFrame();
      return frameInfo.image;
    }

    // RGBA / RGB raw fallback: wrap as PNG-compatible or decode directly
    final codec = await ui.instantiateImageCodec(bytes);
    final frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }

  bool _isPngHeader(Uint8List bytes) {
    return bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47;
  }

  void _handleDelete(KittyImageCommand command) {
    if (command.imageId != null) {
      final toRemove =
          _placements.where((p) => p.id == command.imageId).toList();
      for (final p in toRemove) {
        p.dispose();
        _placements.remove(p);
      }
    } else {
      // Delete all images
      clearAll();
    }
    notifyListeners();
  }

  /// Removes all placements and disposes native image textures.
  void clearAll() {
    for (final p in _placements) {
      p.dispose();
    }
    _placements.clear();
    _chunkAccumulator.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    clearAll();
    super.dispose();
  }
}
