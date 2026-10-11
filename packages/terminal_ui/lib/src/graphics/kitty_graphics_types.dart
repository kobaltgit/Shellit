import 'dart:typed_data';

/// Action requested by a Kitty Graphics Protocol escape sequence.
enum KittyAction {
  /// Transmit image data and display it at current cursor position (a=t).
  transmitAndDisplay,

  /// Transmit, display, and set image as current (a=T).
  transmitDisplayAndSet,

  /// Put / display a previously transmitted image (a=p).
  put,

  /// Delete one or all images (a=d).
  delete,

  /// Query terminal for graphics support (a=q).
  query,
}

/// Image data format specified in Kitty protocol.
enum KittyFormat {
  /// 32-bit RGBA (f=32).
  rgba32,

  /// 24-bit RGB (f=24).
  rgb24,

  /// Standard PNG format (f=100) — universally preferred by Yazi, Chafa, Ranger.
  png,
}

/// Parsed Kitty Graphics Protocol command.
class KittyImageCommand {
  final KittyAction action;
  final int? imageId;
  final int? placementId;
  final KittyFormat format;
  final int? columns;
  final int? rows;
  final int? width;
  final int? height;
  final bool hasMoreChunks;
  final Uint8List? payload;
  final int quiet;

  const KittyImageCommand({
    this.action = KittyAction.transmitAndDisplay,
    this.imageId,
    this.placementId,
    this.format = KittyFormat.png,
    this.columns,
    this.rows,
    this.width,
    this.height,
    this.hasMoreChunks = false,
    this.payload,
    this.quiet = 0,
  });

  @override
  String toString() {
    return 'KittyImageCommand(action: $action, id: $imageId, format: $format, cols: $columns, rows: $rows, chunks: $hasMoreChunks, bytes: ${payload?.length})';
  }
}
