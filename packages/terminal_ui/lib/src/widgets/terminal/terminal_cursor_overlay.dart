import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

/// Lightweight overlay widget that isolates terminal cursor rendering into its own
/// [RepaintBoundary].
///
/// Designed to eliminate idle CPU drain (BUG-052):
/// When [blinkNotifier] toggles every 550ms, only the cursor's [CustomPainter]
/// invalidates, leaving the entire underlying text canvas and font cache untouched.
class TerminalCursorOverlay extends StatelessWidget {
  /// Coordinates of the cursor relative to the top-left corner of the terminal canvas.
  final Offset cursorOffset;

  /// Width and height of a single terminal character cell.
  final Size cellSize;

  /// Visual shape of the cursor (block, underline, or vertical bar).
  final TerminalCursorType cursorType;

  /// Primary color for the cursor.
  final Color cursorColor;

  /// Controls the blinking phase (true = visible, false = hidden).
  final ValueListenable<bool> blinkNotifier;

  /// Whether the parent terminal currently holds keyboard focus.
  /// When false, the cursor is rendered as a hollow outline box without blinking.
  final bool hasFocus;

  /// Visibility flag reflecting VT100 cursor mode (`\x1b[?25h` / `\x1b[?25l`).
  final bool isVisible;

  const TerminalCursorOverlay({
    super.key,
    required this.cursorOffset,
    required this.cellSize,
    this.cursorType = TerminalCursorType.block,
    required this.cursorColor,
    required this.blinkNotifier,
    this.hasFocus = true,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _CursorPainter(
            cursorOffset: cursorOffset,
            cellSize: cellSize,
            cursorType: cursorType,
            cursorColor: cursorColor,
            blinkNotifier: blinkNotifier,
            hasFocus: hasFocus,
            isVisible: isVisible,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

/// Custom painter for rendering the cursor on its own dedicated raster layer.
class _CursorPainter extends CustomPainter {
  final Offset cursorOffset;
  final Size cellSize;
  final TerminalCursorType cursorType;
  final Color cursorColor;
  final ValueListenable<bool> blinkNotifier;
  final bool hasFocus;
  final bool isVisible;

  _CursorPainter({
    required this.cursorOffset,
    required this.cellSize,
    required this.cursorType,
    required this.cursorColor,
    required this.blinkNotifier,
    required this.hasFocus,
    this.isVisible = true,
  }) : super(repaint: blinkNotifier);

  @override
  void paint(Canvas canvas, Size size) {
    if (!isVisible) {
      return;
    }

    if (cellSize.isEmpty || cellSize.width <= 0 || cellSize.height <= 0) {
      return;
    }

    // Clip / skip if cursor is completely outside available bounds
    if (size.width > 0 && size.height > 0) {
      if (cursorOffset.dx + cellSize.width <= 0 ||
          cursorOffset.dx >= size.width ||
          cursorOffset.dy + cellSize.height <= 0 ||
          cursorOffset.dy >= size.height) {
        return;
      }
    }

    // When focused, blinkNotifier controls visibility
    if (hasFocus && !blinkNotifier.value) {
      return;
    }

    final paint = Paint()
      ..color = cursorColor
      ..strokeWidth = 1.0;

    if (!hasFocus) {
      // Unfocused cursor is rendered as a hollow outline box
      paint.style = PaintingStyle.stroke;
      canvas.drawRect(cursorOffset & cellSize, paint);
      return;
    }

    switch (cursorType) {
      case TerminalCursorType.block:
        paint.style = PaintingStyle.fill;
        canvas.drawRect(cursorOffset & cellSize, paint);
        break;
      case TerminalCursorType.underline:
        canvas.drawLine(
          Offset(cursorOffset.dx, cursorOffset.dy + cellSize.height - 1.0),
          Offset(cursorOffset.dx + cellSize.width,
              cursorOffset.dy + cellSize.height - 1.0),
          paint,
        );
        break;
      case TerminalCursorType.verticalBar:
        canvas.drawLine(
          Offset(cursorOffset.dx, cursorOffset.dy),
          Offset(cursorOffset.dx, cursorOffset.dy + cellSize.height),
          paint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _CursorPainter oldDelegate) {
    return oldDelegate.cursorOffset != cursorOffset ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.cursorType != cursorType ||
        oldDelegate.cursorColor != cursorColor ||
        oldDelegate.blinkNotifier != blinkNotifier ||
        oldDelegate.hasFocus != hasFocus ||
        oldDelegate.isVisible != isVisible;
  }
}
