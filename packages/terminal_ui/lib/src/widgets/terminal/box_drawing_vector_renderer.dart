import 'package:flutter/material.dart';

/// High-performance static vector renderer for Unicode Box Drawing characters
/// in the range `U+2500` through `U+257F` (BUG-054 resolution).
///
/// Bypasses font glyph rendering and rasterizes crisp, zero-gap vector lines
/// directly onto [Canvas] with geometric subpixel centering and border-snapped
/// line endpoints.
abstract final class BoxDrawingVectorRenderer {
  /// Checks whether [codepoint] falls within the Unicode Box Drawing block (0x2500..0x257F).
  ///
  /// Executes in O(1) time without allocations.
  static bool isBoxDrawing(int codepoint) {
    return codepoint >= 0x2500 && codepoint <= 0x257F;
  }

  /// Draws the Box Drawing character identified by [codepoint] onto [canvas]
  /// bounded by [cellOffset] and [cellSize].
  ///
  /// Returns `true` if the character was recognized and drawn, or `false`
  /// if [codepoint] is outside the supported range.
  ///
  /// Key guarantees:
  /// - Lines are aligned to the geometric cell center `(xCenter, yCenter)`.
  /// - Line endpoints extend exactly to the cell boundaries `(cellOffset.dx, cellOffset.dx + cellSize.width)`
  ///   and `(cellOffset.dy, cellOffset.dy + cellSize.height)`, guaranteeing 0px seams across cells.
  /// - Uses `isAntiAlias = false` with `StrokeCap.butt` to avoid fractional edge transparency.
  static bool drawBoxChar(
    Canvas canvas,
    Offset cellOffset,
    Size cellSize,
    int codepoint,
    Color color, {
    double lightStrokeWidth = 1.0,
    double heavyStrokeWidth = 2.0,
  }) {
    if (!isBoxDrawing(codepoint)) {
      return false;
    }

    final double left = cellOffset.dx;
    final double right = cellOffset.dx + cellSize.width;
    final double top = cellOffset.dy;
    final double bottom = cellOffset.dy + cellSize.height;
    final double xCenter = cellOffset.dx + cellSize.width / 2.0;
    final double yCenter = cellOffset.dy + cellSize.height / 2.0;

    final Paint lightPaint = Paint()
      ..color = color
      ..strokeWidth = lightStrokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = false;

    final Paint heavyPaint = Paint()
      ..color = color
      ..strokeWidth = heavyStrokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = false;

    // 1. Triple and Quadruple Dashed Lines (0x2504..0x250B)
    if (codepoint >= 0x2504 && codepoint <= 0x250B) {
      _drawDashedLine(
        canvas,
        codepoint,
        left,
        right,
        top,
        bottom,
        xCenter,
        yCenter,
        lightPaint,
        heavyPaint,
      );
      return true;
    }

    // 2. Double Dashed Lines (0x254C..0x254F)
    if (codepoint >= 0x254C && codepoint <= 0x254F) {
      _drawDoubleDashedLine(
        canvas,
        codepoint,
        left,
        right,
        top,
        bottom,
        xCenter,
        yCenter,
        lightPaint,
        heavyPaint,
      );
      return true;
    }

    // 3. Double and Mixed Single/Double Lines (0x2550..0x256C)
    if (codepoint >= 0x2550 && codepoint <= 0x256C) {
      _drawDoubleChar(
        canvas,
        codepoint,
        left,
        right,
        top,
        bottom,
        xCenter,
        yCenter,
        cellSize,
        lightPaint,
        lightStrokeWidth,
      );
      return true;
    }

    // 4. Rounded Arcs (0x256D..0x2570)
    if (codepoint >= 0x256D && codepoint <= 0x2570) {
      _drawArcChar(
        canvas,
        codepoint,
        left,
        right,
        top,
        bottom,
        xCenter,
        yCenter,
        color,
        lightStrokeWidth,
      );
      return true;
    }

    // 5. Diagonals (0x2571..0x2573)
    if (codepoint >= 0x2571 && codepoint <= 0x2573) {
      _drawDiagonalChar(
        canvas,
        codepoint,
        left,
        right,
        top,
        bottom,
        lightPaint,
      );
      return true;
    }

    // 6. Standard Single/Heavy Orthogonal Rays (0x2500..0x2503, 0x250C..0x254B, 0x2574..0x257F)
    final int rayConfig = _rayTable[codepoint - 0x2500];
    if (rayConfig != 0) {
      _drawRayChar(
        canvas,
        rayConfig,
        left,
        right,
        top,
        bottom,
        xCenter,
        yCenter,
        lightPaint,
        heavyPaint,
        lightStrokeWidth,
        heavyStrokeWidth,
      );
      return true;
    }

    return false;
  }

  // --- Dashed Lines Rendering ---

  static void _drawDashedLine(
    Canvas canvas,
    int codepoint,
    double left,
    double right,
    double top,
    double bottom,
    double xCenter,
    double yCenter,
    Paint lightPaint,
    Paint heavyPaint,
  ) {
    switch (codepoint) {
      case 0x2504: // Light triple dash horizontal
        _drawDashedHorizontal(canvas, left, right, yCenter, 3, lightPaint);
      case 0x2505: // Heavy triple dash horizontal
        _drawDashedHorizontal(canvas, left, right, yCenter, 3, heavyPaint);
      case 0x2506: // Light triple dash vertical
        _drawDashedVertical(canvas, top, bottom, xCenter, 3, lightPaint);
      case 0x2507: // Heavy triple dash vertical
        _drawDashedVertical(canvas, top, bottom, xCenter, 3, heavyPaint);
      case 0x2508: // Light quadruple dash horizontal
        _drawDashedHorizontal(canvas, left, right, yCenter, 4, lightPaint);
      case 0x2509: // Heavy quadruple dash horizontal
        _drawDashedHorizontal(canvas, left, right, yCenter, 4, heavyPaint);
      case 0x250A: // Light quadruple dash vertical
        _drawDashedVertical(canvas, top, bottom, xCenter, 4, lightPaint);
      case 0x250B: // Heavy quadruple dash vertical
        _drawDashedVertical(canvas, top, bottom, xCenter, 4, heavyPaint);
    }
  }

  static void _drawDoubleDashedLine(
    Canvas canvas,
    int codepoint,
    double left,
    double right,
    double top,
    double bottom,
    double xCenter,
    double yCenter,
    Paint lightPaint,
    Paint heavyPaint,
  ) {
    switch (codepoint) {
      case 0x254C: // Light double dash horizontal
        _drawDashedHorizontal(canvas, left, right, yCenter, 2, lightPaint);
      case 0x254D: // Heavy double dash horizontal
        _drawDashedHorizontal(canvas, left, right, yCenter, 2, heavyPaint);
      case 0x254E: // Light double dash vertical
        _drawDashedVertical(canvas, top, bottom, xCenter, 2, lightPaint);
      case 0x254F: // Heavy double dash vertical
        _drawDashedVertical(canvas, top, bottom, xCenter, 2, heavyPaint);
    }
  }

  static void _drawDashedHorizontal(
    Canvas canvas,
    double left,
    double right,
    double y,
    int dashCount,
    Paint paint,
  ) {
    final double totalWidth = right - left;
    final double step = totalWidth / dashCount;
    final double dashLen = step * 0.7;
    final double startOffset = (step - dashLen) / 2.0;
    for (int i = 0; i < dashCount; i++) {
      final double x1 = left + i * step + startOffset;
      final double x2 = x1 + dashLen;
      canvas.drawLine(Offset(x1, y), Offset(x2, y), paint);
    }
  }

  static void _drawDashedVertical(
    Canvas canvas,
    double top,
    double bottom,
    double x,
    int dashCount,
    Paint paint,
  ) {
    final double totalHeight = bottom - top;
    final double step = totalHeight / dashCount;
    final double dashLen = step * 0.7;
    final double startOffset = (step - dashLen) / 2.0;
    for (int i = 0; i < dashCount; i++) {
      final double y1 = top + i * step + startOffset;
      final double y2 = y1 + dashLen;
      canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
    }
  }

  // --- Arcs & Diagonals ---

  static void _drawArcChar(
    Canvas canvas,
    int codepoint,
    double left,
    double right,
    double top,
    double bottom,
    double xCenter,
    double yCenter,
    Color color,
    double strokeWidth,
  ) {
    final Paint arcPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true;

    final Path path = Path();
    switch (codepoint) {
      case 0x256D: // ╭ Light arc down and right
        path.moveTo(xCenter, bottom);
        path.quadraticBezierTo(xCenter, yCenter, right, yCenter);
      case 0x256E: // ╮ Light arc down and left
        path.moveTo(xCenter, bottom);
        path.quadraticBezierTo(xCenter, yCenter, left, yCenter);
      case 0x256F: // ╯ Light arc up and left
        path.moveTo(xCenter, top);
        path.quadraticBezierTo(xCenter, yCenter, left, yCenter);
      case 0x2570: // ╰ Light arc up and right
        path.moveTo(xCenter, top);
        path.quadraticBezierTo(xCenter, yCenter, right, yCenter);
    }
    canvas.drawPath(path, arcPaint);
  }

  static void _drawDiagonalChar(
    Canvas canvas,
    int codepoint,
    double left,
    double right,
    double top,
    double bottom,
    Paint paint,
  ) {
    switch (codepoint) {
      case 0x2571: // ╱ Light diagonal upper right to lower left
        canvas.drawLine(Offset(right, top), Offset(left, bottom), paint);
      case 0x2572: // ╲ Light diagonal upper left to lower right
        canvas.drawLine(Offset(left, top), Offset(right, bottom), paint);
      case 0x2573: // ╳ Light diagonal cross
        canvas.drawLine(Offset(right, top), Offset(left, bottom), paint);
        canvas.drawLine(Offset(left, top), Offset(right, bottom), paint);
    }
  }

  // --- Double & Mixed Double Lines ---

  static void _drawDoubleChar(
    Canvas canvas,
    int codepoint,
    double left,
    double right,
    double top,
    double bottom,
    double xCenter,
    double yCenter,
    Size cellSize,
    Paint paint,
    double strokeWidth,
  ) {
    final double dX = (cellSize.width * 0.2).clamp(1.5, 4.0);
    final double dY = (cellSize.height * 0.16).clamp(1.5, 4.0);
    final double halfStroke = strokeWidth / 2.0;

    switch (codepoint) {
      case 0x2550: // ═ Double horizontal
        canvas.drawLine(
            Offset(left, yCenter - dY), Offset(right, yCenter - dY), paint);
        canvas.drawLine(
            Offset(left, yCenter + dY), Offset(right, yCenter + dY), paint);

      case 0x2551: // ║ Double vertical
        canvas.drawLine(
            Offset(xCenter - dX, top), Offset(xCenter - dX, bottom), paint);
        canvas.drawLine(
            Offset(xCenter + dX, top), Offset(xCenter + dX, bottom), paint);

      case 0x2552: // ╒ Down single & right double
        canvas.drawLine(
            Offset(xCenter, yCenter - dY), Offset(xCenter, bottom), paint);
        canvas.drawLine(
            Offset(xCenter, yCenter - dY), Offset(right, yCenter - dY), paint);
        canvas.drawLine(
            Offset(xCenter, yCenter + dY), Offset(right, yCenter + dY), paint);

      case 0x2553: // ╓ Down double & right single
        canvas.drawLine(
            Offset(xCenter - dX, yCenter), Offset(xCenter - dX, bottom), paint);
        canvas.drawLine(
            Offset(xCenter + dX, yCenter), Offset(xCenter + dX, bottom), paint);
        canvas.drawLine(
            Offset(xCenter - dX, yCenter), Offset(right, yCenter), paint);

      case 0x2554: // ╔ Double down & right
        // Outer corner
        canvas.drawLine(Offset(xCenter - dX - halfStroke, yCenter - dY),
            Offset(right, yCenter - dY), paint);
        canvas.drawLine(Offset(xCenter - dX, yCenter - dY - halfStroke),
            Offset(xCenter - dX, bottom), paint);
        // Inner corner
        canvas.drawLine(Offset(xCenter + dX, yCenter + dY),
            Offset(right, yCenter + dY), paint);
        canvas.drawLine(Offset(xCenter + dX, yCenter + dY),
            Offset(xCenter + dX, bottom), paint);

      case 0x2555: // ╕ Down single & left double
        canvas.drawLine(
            Offset(xCenter, yCenter - dY), Offset(xCenter, bottom), paint);
        canvas.drawLine(
            Offset(left, yCenter - dY), Offset(xCenter, yCenter - dY), paint);
        canvas.drawLine(
            Offset(left, yCenter + dY), Offset(xCenter, yCenter + dY), paint);

      case 0x2556: // ╖ Down double & left single
        canvas.drawLine(
            Offset(xCenter - dX, yCenter), Offset(xCenter - dX, bottom), paint);
        canvas.drawLine(
            Offset(xCenter + dX, yCenter), Offset(xCenter + dX, bottom), paint);
        canvas.drawLine(
            Offset(left, yCenter), Offset(xCenter + dX, yCenter), paint);

      case 0x2557: // ╗ Double down & left
        // Outer corner
        canvas.drawLine(Offset(left, yCenter - dY),
            Offset(xCenter + dX + halfStroke, yCenter - dY), paint);
        canvas.drawLine(Offset(xCenter + dX, yCenter - dY - halfStroke),
            Offset(xCenter + dX, bottom), paint);
        // Inner corner
        canvas.drawLine(Offset(left, yCenter + dY),
            Offset(xCenter - dX, yCenter + dY), paint);
        canvas.drawLine(Offset(xCenter - dX, yCenter + dY),
            Offset(xCenter - dX, bottom), paint);

      case 0x2558: // ╘ Up single & right double
        canvas.drawLine(
            Offset(xCenter, top), Offset(xCenter, yCenter + dY), paint);
        canvas.drawLine(
            Offset(xCenter, yCenter - dY), Offset(right, yCenter - dY), paint);
        canvas.drawLine(
            Offset(xCenter, yCenter + dY), Offset(right, yCenter + dY), paint);

      case 0x2559: // ╙ Up double & right single
        canvas.drawLine(
            Offset(xCenter - dX, top), Offset(xCenter - dX, yCenter), paint);
        canvas.drawLine(
            Offset(xCenter + dX, top), Offset(xCenter + dX, yCenter), paint);
        canvas.drawLine(
            Offset(xCenter - dX, yCenter), Offset(right, yCenter), paint);

      case 0x255A: // ╚ Double up & right
        // Outer corner
        canvas.drawLine(Offset(xCenter - dX - halfStroke, yCenter + dY),
            Offset(right, yCenter + dY), paint);
        canvas.drawLine(Offset(xCenter - dX, top),
            Offset(xCenter - dX, yCenter + dY + halfStroke), paint);
        // Inner corner
        canvas.drawLine(Offset(xCenter + dX, yCenter - dY),
            Offset(right, yCenter - dY), paint);
        canvas.drawLine(Offset(xCenter + dX, top),
            Offset(xCenter + dX, yCenter - dY), paint);

      case 0x255B: // ╛ Up single & left double
        canvas.drawLine(
            Offset(xCenter, top), Offset(xCenter, yCenter + dY), paint);
        canvas.drawLine(
            Offset(left, yCenter - dY), Offset(xCenter, yCenter - dY), paint);
        canvas.drawLine(
            Offset(left, yCenter + dY), Offset(xCenter, yCenter + dY), paint);

      case 0x255C: // ╜ Up double & left single
        canvas.drawLine(
            Offset(xCenter - dX, top), Offset(xCenter - dX, yCenter), paint);
        canvas.drawLine(
            Offset(xCenter + dX, top), Offset(xCenter + dX, yCenter), paint);
        canvas.drawLine(
            Offset(left, yCenter), Offset(xCenter + dX, yCenter), paint);

      case 0x255D: // ╝ Double up & left
        // Outer corner
        canvas.drawLine(Offset(left, yCenter + dY),
            Offset(xCenter + dX + halfStroke, yCenter + dY), paint);
        canvas.drawLine(Offset(xCenter + dX, top),
            Offset(xCenter + dX, yCenter + dY + halfStroke), paint);
        // Inner corner
        canvas.drawLine(Offset(left, yCenter - dY),
            Offset(xCenter - dX, yCenter - dY), paint);
        canvas.drawLine(Offset(xCenter - dX, top),
            Offset(xCenter - dX, yCenter - dY), paint);

      case 0x255E: // ╞ Vert single & right double
        canvas.drawLine(Offset(xCenter, top), Offset(xCenter, bottom), paint);
        canvas.drawLine(
            Offset(xCenter, yCenter - dY), Offset(right, yCenter - dY), paint);
        canvas.drawLine(
            Offset(xCenter, yCenter + dY), Offset(right, yCenter + dY), paint);

      case 0x255F: // ╟ Vert double & right single
        canvas.drawLine(
            Offset(xCenter - dX, top), Offset(xCenter - dX, bottom), paint);
        canvas.drawLine(
            Offset(xCenter + dX, top), Offset(xCenter + dX, bottom), paint);
        canvas.drawLine(
            Offset(xCenter + dX, yCenter), Offset(right, yCenter), paint);

      case 0x2560: // ╠ Double vert & right
        canvas.drawLine(
            Offset(xCenter - dX, top), Offset(xCenter - dX, bottom), paint);
        canvas.drawLine(Offset(xCenter + dX, top),
            Offset(xCenter + dX, yCenter - dY), paint);
        canvas.drawLine(Offset(xCenter + dX, yCenter + dY),
            Offset(xCenter + dX, bottom), paint);
        canvas.drawLine(Offset(xCenter + dX, yCenter - dY),
            Offset(right, yCenter - dY), paint);
        canvas.drawLine(Offset(xCenter + dX, yCenter + dY),
            Offset(right, yCenter + dY), paint);

      case 0x2561: // ╡ Vert single & left double
        canvas.drawLine(Offset(xCenter, top), Offset(xCenter, bottom), paint);
        canvas.drawLine(
            Offset(left, yCenter - dY), Offset(xCenter, yCenter - dY), paint);
        canvas.drawLine(
            Offset(left, yCenter + dY), Offset(xCenter, yCenter + dY), paint);

      case 0x2562: // ╢ Vert double & left single
        canvas.drawLine(
            Offset(xCenter - dX, top), Offset(xCenter - dX, bottom), paint);
        canvas.drawLine(
            Offset(xCenter + dX, top), Offset(xCenter + dX, bottom), paint);
        canvas.drawLine(
            Offset(left, yCenter), Offset(xCenter - dX, yCenter), paint);

      case 0x2563: // ╣ Double vert & left
        canvas.drawLine(
            Offset(xCenter + dX, top), Offset(xCenter + dX, bottom), paint);
        canvas.drawLine(Offset(xCenter - dX, top),
            Offset(xCenter - dX, yCenter - dY), paint);
        canvas.drawLine(Offset(xCenter - dX, yCenter + dY),
            Offset(xCenter - dX, bottom), paint);
        canvas.drawLine(Offset(left, yCenter - dY),
            Offset(xCenter - dX, yCenter - dY), paint);
        canvas.drawLine(Offset(left, yCenter + dY),
            Offset(xCenter - dX, yCenter + dY), paint);

      case 0x2564: // ╤ Down single & horiz double
        canvas.drawLine(
            Offset(left, yCenter - dY), Offset(right, yCenter - dY), paint);
        canvas.drawLine(
            Offset(left, yCenter + dY), Offset(right, yCenter + dY), paint);
        canvas.drawLine(
            Offset(xCenter, yCenter + dY), Offset(xCenter, bottom), paint);

      case 0x2565: // ╥ Down double & horiz single
        canvas.drawLine(Offset(left, yCenter), Offset(right, yCenter), paint);
        canvas.drawLine(
            Offset(xCenter - dX, yCenter), Offset(xCenter - dX, bottom), paint);
        canvas.drawLine(
            Offset(xCenter + dX, yCenter), Offset(xCenter + dX, bottom), paint);

      case 0x2566: // ╦ Double down & horiz
        canvas.drawLine(
            Offset(left, yCenter - dY), Offset(right, yCenter - dY), paint);
        canvas.drawLine(Offset(left, yCenter + dY),
            Offset(xCenter - dX, yCenter + dY), paint);
        canvas.drawLine(Offset(xCenter + dX, yCenter + dY),
            Offset(right, yCenter + dY), paint);
        canvas.drawLine(Offset(xCenter - dX, yCenter + dY),
            Offset(xCenter - dX, bottom), paint);
        canvas.drawLine(Offset(xCenter + dX, yCenter + dY),
            Offset(xCenter + dX, bottom), paint);

      case 0x2567: // ╧ Up single & horiz double
        canvas.drawLine(
            Offset(left, yCenter - dY), Offset(right, yCenter - dY), paint);
        canvas.drawLine(
            Offset(left, yCenter + dY), Offset(right, yCenter + dY), paint);
        canvas.drawLine(
            Offset(xCenter, top), Offset(xCenter, yCenter - dY), paint);

      case 0x2568: // ╨ Up double & horiz single
        canvas.drawLine(Offset(left, yCenter), Offset(right, yCenter), paint);
        canvas.drawLine(
            Offset(xCenter - dX, top), Offset(xCenter - dX, yCenter), paint);
        canvas.drawLine(
            Offset(xCenter + dX, top), Offset(xCenter + dX, yCenter), paint);

      case 0x2569: // ╩ Double up & horiz
        canvas.drawLine(
            Offset(left, yCenter + dY), Offset(right, yCenter + dY), paint);
        canvas.drawLine(Offset(left, yCenter - dY),
            Offset(xCenter - dX, yCenter - dY), paint);
        canvas.drawLine(Offset(xCenter + dX, yCenter - dY),
            Offset(right, yCenter - dY), paint);
        canvas.drawLine(Offset(xCenter - dX, top),
            Offset(xCenter - dX, yCenter - dY), paint);
        canvas.drawLine(Offset(xCenter + dX, top),
            Offset(xCenter + dX, yCenter - dY), paint);

      case 0x256A: // ╪ Vert single & horiz double
        canvas.drawLine(
            Offset(left, yCenter - dY), Offset(right, yCenter - dY), paint);
        canvas.drawLine(
            Offset(left, yCenter + dY), Offset(right, yCenter + dY), paint);
        canvas.drawLine(Offset(xCenter, top), Offset(xCenter, bottom), paint);

      case 0x256B: // ╫ Vert double & horiz single
        canvas.drawLine(
            Offset(xCenter - dX, top), Offset(xCenter - dX, bottom), paint);
        canvas.drawLine(
            Offset(xCenter + dX, top), Offset(xCenter + dX, bottom), paint);
        canvas.drawLine(Offset(left, yCenter), Offset(right, yCenter), paint);

      case 0x256C: // ╬ Double vert & horiz
        canvas.drawLine(Offset(left, yCenter - dY),
            Offset(xCenter - dX, yCenter - dY), paint);
        canvas.drawLine(Offset(xCenter + dX, yCenter - dY),
            Offset(right, yCenter - dY), paint);
        canvas.drawLine(Offset(left, yCenter + dY),
            Offset(xCenter - dX, yCenter + dY), paint);
        canvas.drawLine(Offset(xCenter + dX, yCenter + dY),
            Offset(right, yCenter + dY), paint);
        canvas.drawLine(Offset(xCenter - dX, top),
            Offset(xCenter - dX, yCenter - dY), paint);
        canvas.drawLine(Offset(xCenter - dX, yCenter + dY),
            Offset(xCenter - dX, bottom), paint);
        canvas.drawLine(Offset(xCenter + dX, top),
            Offset(xCenter + dX, yCenter - dY), paint);
        canvas.drawLine(Offset(xCenter + dX, yCenter + dY),
            Offset(xCenter + dX, bottom), paint);
    }
  }

  // --- Single & Heavy Orthogonal Rays ---

  static void _drawRayChar(
    Canvas canvas,
    int rayConfig,
    double left,
    double right,
    double top,
    double bottom,
    double xCenter,
    double yCenter,
    Paint lightPaint,
    Paint heavyPaint,
    double lightStrokeWidth,
    double heavyStrokeWidth,
  ) {
    final int up = (rayConfig >> 12) & 0xF;
    final int down = (rayConfig >> 8) & 0xF;
    final int leftRay = (rayConfig >> 4) & 0xF;
    final int rightRay = rayConfig & 0xF;

    Paint paintFor(int weight) => weight == 2 ? heavyPaint : lightPaint;
    double strokeWidthFor(int weight) =>
        weight == 2 ? heavyStrokeWidth : lightStrokeWidth;

    // Fast-path 1: Full horizontal through line (no vertical)
    if (up == 0 &&
        down == 0 &&
        leftRay != 0 &&
        rightRay != 0 &&
        leftRay == rightRay) {
      canvas.drawLine(
          Offset(left, yCenter), Offset(right, yCenter), paintFor(leftRay));
      return;
    }

    // Fast-path 2: Full vertical through line (no horizontal)
    if (leftRay == 0 && rightRay == 0 && up != 0 && down != 0 && up == down) {
      canvas.drawLine(
          Offset(xCenter, top), Offset(xCenter, bottom), paintFor(up));
      return;
    }

    // Fast-path 3: Uniform 4-way cross or T-junctions with continuous through-axes
    final bool fullHoriz = leftRay != 0 && rightRay != 0 && leftRay == rightRay;
    final bool fullVert = up != 0 && down != 0 && up == down;

    if (fullHoriz && fullVert) {
      canvas.drawLine(
          Offset(left, yCenter), Offset(right, yCenter), paintFor(leftRay));
      canvas.drawLine(
          Offset(xCenter, top), Offset(xCenter, bottom), paintFor(up));
      return;
    }

    if (fullHoriz) {
      canvas.drawLine(
          Offset(left, yCenter), Offset(right, yCenter), paintFor(leftRay));
      if (up != 0) {
        canvas.drawLine(
            Offset(xCenter, top), Offset(xCenter, yCenter), paintFor(up));
      }
      if (down != 0) {
        canvas.drawLine(
            Offset(xCenter, yCenter), Offset(xCenter, bottom), paintFor(down));
      }
      return;
    }

    if (fullVert) {
      canvas.drawLine(
          Offset(xCenter, top), Offset(xCenter, bottom), paintFor(up));
      if (leftRay != 0) {
        canvas.drawLine(
            Offset(left, yCenter), Offset(xCenter, yCenter), paintFor(leftRay));
      }
      if (rightRay != 0) {
        canvas.drawLine(Offset(xCenter, yCenter), Offset(right, yCenter),
            paintFor(rightRay));
      }
      return;
    }

    // Corners (e.g. ┌, ┐, └, ┘ with identical or mixed weights)
    // Extend inner corner segment by half-stroke of the perpendicular line
    // to ensure 100% gapless miter corner coverage.
    if (up == 0 && leftRay == 0 && down != 0 && rightRay != 0) {
      // ┌ Down and Right
      final double halfV = strokeWidthFor(down) / 2.0;
      final double halfH = strokeWidthFor(rightRay) / 2.0;
      canvas.drawLine(Offset(xCenter - halfV, yCenter), Offset(right, yCenter),
          paintFor(rightRay));
      canvas.drawLine(Offset(xCenter, yCenter - halfH), Offset(xCenter, bottom),
          paintFor(down));
      return;
    }

    if (up == 0 && rightRay == 0 && down != 0 && leftRay != 0) {
      // ┐ Down and Left
      final double halfV = strokeWidthFor(down) / 2.0;
      final double halfH = strokeWidthFor(leftRay) / 2.0;
      canvas.drawLine(Offset(left, yCenter), Offset(xCenter + halfV, yCenter),
          paintFor(leftRay));
      canvas.drawLine(Offset(xCenter, yCenter - halfH), Offset(xCenter, bottom),
          paintFor(down));
      return;
    }

    if (down == 0 && leftRay == 0 && up != 0 && rightRay != 0) {
      // └ Up and Right
      final double halfV = strokeWidthFor(up) / 2.0;
      final double halfH = strokeWidthFor(rightRay) / 2.0;
      canvas.drawLine(Offset(xCenter - halfV, yCenter), Offset(right, yCenter),
          paintFor(rightRay));
      canvas.drawLine(
          Offset(xCenter, top), Offset(xCenter, yCenter + halfH), paintFor(up));
      return;
    }

    if (down == 0 && rightRay == 0 && up != 0 && leftRay != 0) {
      // ┘ Up and Left
      final double halfV = strokeWidthFor(up) / 2.0;
      final double halfH = strokeWidthFor(leftRay) / 2.0;
      canvas.drawLine(Offset(left, yCenter), Offset(xCenter + halfV, yCenter),
          paintFor(leftRay));
      canvas.drawLine(
          Offset(xCenter, top), Offset(xCenter, yCenter + halfH), paintFor(up));
      return;
    }

    // General ray fallback: draw each ray from boundary to center
    if (leftRay != 0) {
      canvas.drawLine(
          Offset(left, yCenter), Offset(xCenter, yCenter), paintFor(leftRay));
    }
    if (rightRay != 0) {
      canvas.drawLine(
          Offset(xCenter, yCenter), Offset(right, yCenter), paintFor(rightRay));
    }
    if (up != 0) {
      canvas.drawLine(
          Offset(xCenter, top), Offset(xCenter, yCenter), paintFor(up));
    }
    if (down != 0) {
      canvas.drawLine(
          Offset(xCenter, yCenter), Offset(xCenter, bottom), paintFor(down));
    }
  }

  // --- Ray Definitions Table (0x2500..0x257F) ---
  // Encoded as 16-bit int: 0xUDLR where U, D, L, R are:
  // 0 = none, 1 = light, 2 = heavy.
  // Entries with 0x0000 are handled by special routines (dashed, double, arc, diagonal).
  static const List<int> _rayTable = <int>[
    // 0x2500 - 0x2503
    0x0011, // 0x2500 ─
    0x0022, // 0x2501 ━
    0x1100, // 0x2502 │
    0x2200, // 0x2503 ┃
    // 0x2504 - 0x250B: Dashed lines (special)
    0x0000, 0x0000, 0x0000, 0x0000,
    0x0000, 0x0000, 0x0000, 0x0000,
    // 0x250C - 0x2513
    0x0101, // 0x250C ┌
    0x0102, // 0x250D ┍
    0x0201, // 0x250E ┎
    0x0202, // 0x250F ┏
    0x0110, // 0x2510 ┐
    0x0120, // 0x2511 ┑
    0x0210, // 0x2512 ┒
    0x0220, // 0x2513 ┓
    // 0x2514 - 0x251B
    0x1001, // 0x2514 └
    0x1002, // 0x2515 ┕
    0x2001, // 0x2516 ┖
    0x2002, // 0x2517 ┗
    0x1010, // 0x2518 ┘
    0x1020, // 0x2519 ┙
    0x2010, // 0x251A ┚
    0x2020, // 0x251B ┛
    // 0x251C - 0x2523
    0x1101, // 0x251C ├
    0x1102, // 0x251D ┝
    0x2101, // 0x251E ┞
    0x1201, // 0x251F ┟
    0x2201, // 0x2520 ┠
    0x2102, // 0x2521 ┡
    0x1202, // 0x2522 ┢
    0x2202, // 0x2523 ┣
    // 0x2524 - 0x252B
    0x1110, // 0x2524 ┤
    0x1120, // 0x2525 ┥
    0x2110, // 0x2526 ┦
    0x1210, // 0x2527 ┧
    0x2210, // 0x2528 ┨
    0x2120, // 0x2529 ┩
    0x1220, // 0x252A ┪
    0x2220, // 0x252B ┫
    // 0x252C - 0x2533
    0x0111, // 0x252C ┬
    0x0121, // 0x252D ┭
    0x0112, // 0x252E ┮
    0x0122, // 0x252F ┯
    0x0211, // 0x2530 ┰
    0x0221, // 0x2531 ┱
    0x0212, // 0x2532 ┲
    0x0222, // 0x2533 ┳
    // 0x2534 - 0x253B
    0x1011, // 0x2534 ┴
    0x1021, // 0x2535 ┵
    0x1012, // 0x2536 ┶
    0x1022, // 0x2537 ┷
    0x2011, // 0x2538 ┸
    0x2021, // 0x2539 ┹
    0x2012, // 0x253A ┺
    0x2022, // 0x253B ┻
    // 0x253C - 0x2543
    0x1111, // 0x253C ┼
    0x1121, // 0x253D ┽
    0x1112, // 0x253E ┾
    0x1122, // 0x253F ┿
    0x2111, // 0x2540 ╀
    0x1211, // 0x2541 ╁
    0x2211, // 0x2542 ╂
    0x2121, // 0x2543 ╃
    // 0x2544 - 0x254B
    0x2112, // 0x2544 ╄
    0x1221, // 0x2545 ╅
    0x1212, // 0x2546 ╆
    0x2122, // 0x2547 ╇
    0x1222, // 0x2548 ╈
    0x2221, // 0x2549 ╉
    0x2212, // 0x254A ╊
    0x2222, // 0x254B ╋
    // 0x254C - 0x254F: Double dashed (special)
    0x0000, 0x0000, 0x0000, 0x0000,
    // 0x2550 - 0x256C: Double & mixed double lines (special)
    0x0000, 0x0000, 0x0000, 0x0000,
    0x0000, 0x0000, 0x0000, 0x0000,
    0x0000, 0x0000, 0x0000, 0x0000,
    0x0000, 0x0000, 0x0000, 0x0000,
    0x0000, 0x0000, 0x0000, 0x0000,
    0x0000, 0x0000, 0x0000, 0x0000,
    0x0000, 0x0000, 0x0000, 0x0000,
    0x0000,
    // 0x256D - 0x2570: Arcs (special)
    0x0000, 0x0000, 0x0000, 0x0000,
    // 0x2571 - 0x2573: Diagonals (special)
    0x0000, 0x0000, 0x0000,
    // 0x2574 - 0x257F: Half-lines and mixed endings
    0x0010, // 0x2574 ╴ Light left
    0x1000, // 0x2575 ╵ Light up
    0x0001, // 0x2576 ╶ Light right
    0x0100, // 0x2577 ╷ Light down
    0x0020, // 0x2578 ╸ Heavy left
    0x2000, // 0x2579 ╹ Heavy up
    0x0002, // 0x257A ╺ Heavy right
    0x0200, // 0x257B ╻ Heavy down
    0x0012, // 0x257C ╼ Light left and heavy right
    0x1200, // 0x257D ╽ Light up and heavy down
    0x0021, // 0x257E ╾ Heavy left and light right
    0x2100, // 0x257F ╿ Heavy up and light down
  ];
}
