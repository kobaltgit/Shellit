import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

class DrawLineCall {
  final Offset p1;
  final Offset p2;
  final Color color;
  final double strokeWidth;
  final bool isAntiAlias;
  final StrokeCap strokeCap;

  DrawLineCall(this.p1, this.p2, Paint paint)
      : color = paint.color,
        strokeWidth = paint.strokeWidth,
        isAntiAlias = paint.isAntiAlias,
        strokeCap = paint.strokeCap;
}

class DrawPathCall {
  final Path path;
  final Color color;
  final double strokeWidth;

  DrawPathCall(this.path, Paint paint)
      : color = paint.color,
        strokeWidth = paint.strokeWidth;
}

class SpyCanvas extends Fake implements Canvas {
  final List<DrawLineCall> lineCalls = <DrawLineCall>[];
  final List<DrawPathCall> pathCalls = <DrawPathCall>[];

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {
    lineCalls.add(DrawLineCall(p1, p2, paint));
  }

  @override
  void drawPath(Path path, Paint paint) {
    pathCalls.add(DrawPathCall(path, paint));
  }

  void reset() {
    lineCalls.clear;
    lineCalls.clear();
    pathCalls.clear();
  }
}

void main() {
  const Offset cellOffset = Offset(10.0, 20.0);
  const Size cellSize = Size(10.0, 20.0);
  const Color testColor = Color(0xFF00FF88);

  const double left = 10.0;
  const double right = 20.0;
  const double top = 20.0;
  const double bottom = 40.0;
  const double xCenter = 15.0;
  const double yCenter = 30.0;

  group('BoxDrawingVectorRenderer - Codepoint Range & Boundary Checks', () {
    test('isBoxDrawing returns true for 0x2500 through 0x257F', () {
      for (int cp = 0x2500; cp <= 0x257F; cp++) {
        expect(
          BoxDrawingVectorRenderer.isBoxDrawing(cp),
          isTrue,
          reason:
              'Codepoint 0x${cp.toRadixString(16)} should be recognized as box drawing',
        );
      }
    });

    test('isBoxDrawing returns false outside 0x2500..0x257F boundaries', () {
      expect(BoxDrawingVectorRenderer.isBoxDrawing(0x24FE), isFalse);
      expect(BoxDrawingVectorRenderer.isBoxDrawing(0x24FF), isFalse);
      expect(BoxDrawingVectorRenderer.isBoxDrawing(0x2580), isFalse);
      expect(BoxDrawingVectorRenderer.isBoxDrawing(0x2581), isFalse);
      expect(BoxDrawingVectorRenderer.isBoxDrawing(0x0041), isFalse); // 'A'
      expect(BoxDrawingVectorRenderer.isBoxDrawing(0), isFalse);
      expect(BoxDrawingVectorRenderer.isBoxDrawing(-1), isFalse);
    });

    test('drawBoxChar returns false on invalid codepoints without drawing', () {
      final spy = SpyCanvas();
      final result1 = BoxDrawingVectorRenderer.drawBoxChar(
        spy,
        cellOffset,
        cellSize,
        0x24FF,
        testColor,
      );
      expect(result1, isFalse);
      expect(spy.lineCalls, isEmpty);
      expect(spy.pathCalls, isEmpty);

      final result2 = BoxDrawingVectorRenderer.drawBoxChar(
        spy,
        cellOffset,
        cellSize,
        0x2580,
        testColor,
      );
      expect(result2, isFalse);
      expect(spy.lineCalls, isEmpty);
      expect(spy.pathCalls, isEmpty);
    });

    test('All 128 characters from 0x2500 to 0x257F return true when drawn', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      for (int cp = 0x2500; cp <= 0x257F; cp++) {
        final ok = BoxDrawingVectorRenderer.drawBoxChar(
          canvas,
          cellOffset,
          cellSize,
          cp,
          testColor,
        );
        expect(
          ok,
          isTrue,
          reason: 'drawBoxChar failed for 0x${cp.toRadixString(16)}',
        );
      }

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });

  group('BoxDrawingVectorRenderer - Single & Heavy Orthogonal Lines', () {
    late SpyCanvas spy;

    setUp(() {
      spy = SpyCanvas();
    });

    test(
        '0x2500 (─ Light Horizontal) draws full line from left to right at yCenter',
        () {
      final ok = BoxDrawingVectorRenderer.drawBoxChar(
        spy,
        cellOffset,
        cellSize,
        0x2500,
        testColor,
        lightStrokeWidth: 1.0,
      );
      expect(ok, isTrue);
      expect(spy.lineCalls.length, equals(1));

      final call = spy.lineCalls.first;
      expect(call.p1, equals(const Offset(left, yCenter)));
      expect(call.p2, equals(const Offset(right, yCenter)));
      expect(call.color.toARGB32(), equals(testColor.toARGB32()));
      expect(call.strokeWidth, equals(1.0));
      expect(call.isAntiAlias, isFalse);
      expect(call.strokeCap, equals(StrokeCap.butt));
    });

    test('0x2501 (━ Heavy Horizontal) draws with heavyStrokeWidth', () {
      final ok = BoxDrawingVectorRenderer.drawBoxChar(
        spy,
        cellOffset,
        cellSize,
        0x2501,
        testColor,
        heavyStrokeWidth: 2.5,
      );
      expect(ok, isTrue);
      expect(spy.lineCalls.length, equals(1));

      final call = spy.lineCalls.first;
      expect(call.p1, equals(const Offset(left, yCenter)));
      expect(call.p2, equals(const Offset(right, yCenter)));
      expect(call.strokeWidth, equals(2.5));
    });

    test(
        '0x2502 (│ Light Vertical) draws full line from top to bottom at xCenter',
        () {
      final ok = BoxDrawingVectorRenderer.drawBoxChar(
        spy,
        cellOffset,
        cellSize,
        0x2502,
        testColor,
        lightStrokeWidth: 1.0,
      );
      expect(ok, isTrue);
      expect(spy.lineCalls.length, equals(1));

      final call = spy.lineCalls.first;
      expect(call.p1, equals(const Offset(xCenter, top)));
      expect(call.p2, equals(const Offset(xCenter, bottom)));
      expect(call.strokeWidth, equals(1.0));
      expect(call.isAntiAlias, isFalse);
      expect(call.strokeCap, equals(StrokeCap.butt));
    });

    test('0x2503 (┃ Heavy Vertical) draws with heavyStrokeWidth', () {
      final ok = BoxDrawingVectorRenderer.drawBoxChar(
        spy,
        cellOffset,
        cellSize,
        0x2503,
        testColor,
        heavyStrokeWidth: 3.0,
      );
      expect(ok, isTrue);
      expect(spy.lineCalls.length, equals(1));

      final call = spy.lineCalls.first;
      expect(call.p1, equals(const Offset(xCenter, top)));
      expect(call.p2, equals(const Offset(xCenter, bottom)));
      expect(call.strokeWidth, equals(3.0));
    });
  });

  group('BoxDrawingVectorRenderer - Corners, T-Junctions & Crosses', () {
    late SpyCanvas spy;

    setUp(() {
      spy = SpyCanvas();
    });

    test(
        '0x250C (┌ Light Down & Right) draws horizontal and vertical meeting at center with miter overlap',
        () {
      final ok = BoxDrawingVectorRenderer.drawBoxChar(
        spy,
        cellOffset,
        cellSize,
        0x250C,
        testColor,
        lightStrokeWidth: 1.0,
      );
      expect(ok, isTrue);
      expect(spy.lineCalls.length, equals(2));

      // Horizontal ray extends to right boundary
      final hLine = spy.lineCalls[0];
      expect(hLine.p1.dx, closeTo(xCenter - 0.5, 0.001));
      expect(hLine.p1.dy, equals(yCenter));
      expect(hLine.p2, equals(const Offset(right, yCenter)));

      // Vertical ray extends to bottom boundary
      final vLine = spy.lineCalls[1];
      expect(vLine.p1.dx, equals(xCenter));
      expect(vLine.p1.dy, closeTo(yCenter - 0.5, 0.001));
      expect(vLine.p2, equals(const Offset(xCenter, bottom)));
    });

    test(
        '0x2510 (┐ Light Down & Left) connects left boundary and bottom boundary',
        () {
      final ok = BoxDrawingVectorRenderer.drawBoxChar(
        spy,
        cellOffset,
        cellSize,
        0x2510,
        testColor,
      );
      expect(ok, isTrue);
      expect(spy.lineCalls.length, equals(2));

      final hLine = spy.lineCalls[0];
      expect(hLine.p1, equals(const Offset(left, yCenter)));
      final vLine = spy.lineCalls[1];
      expect(vLine.p2, equals(const Offset(xCenter, bottom)));
    });

    test('0x2514 (└ Light Up & Right) connects right boundary and top boundary',
        () {
      final ok = BoxDrawingVectorRenderer.drawBoxChar(
        spy,
        cellOffset,
        cellSize,
        0x2514,
        testColor,
      );
      expect(ok, isTrue);
      expect(spy.lineCalls.length, equals(2));

      final hLine = spy.lineCalls[0];
      expect(hLine.p2, equals(const Offset(right, yCenter)));
      final vLine = spy.lineCalls[1];
      expect(vLine.p1, equals(const Offset(xCenter, top)));
    });

    test('0x2518 (┘ Light Up & Left) connects left boundary and top boundary',
        () {
      final ok = BoxDrawingVectorRenderer.drawBoxChar(
        spy,
        cellOffset,
        cellSize,
        0x2518,
        testColor,
      );
      expect(ok, isTrue);
      expect(spy.lineCalls.length, equals(2));

      final hLine = spy.lineCalls[0];
      expect(hLine.p1, equals(const Offset(left, yCenter)));
      final vLine = spy.lineCalls[1];
      expect(vLine.p1, equals(const Offset(xCenter, top)));
    });

    test(
        '0x252C (┬ Light Down & Horizontal) draws through horizontal line and down ray',
        () {
      final ok = BoxDrawingVectorRenderer.drawBoxChar(
        spy,
        cellOffset,
        cellSize,
        0x252C,
        testColor,
      );
      expect(ok, isTrue);
      expect(spy.lineCalls.length, equals(2));

      // Through horizontal line from left to right
      final hLine = spy.lineCalls[0];
      expect(hLine.p1, equals(const Offset(left, yCenter)));
      expect(hLine.p2, equals(const Offset(right, yCenter)));

      // Down ray from center to bottom
      final vLine = spy.lineCalls[1];
      expect(vLine.p1, equals(const Offset(xCenter, yCenter)));
      expect(vLine.p2, equals(const Offset(xCenter, bottom)));
    });

    test(
        '0x2534 (┴ Light Up & Horizontal) draws through horizontal line and up ray',
        () {
      final ok = BoxDrawingVectorRenderer.drawBoxChar(
        spy,
        cellOffset,
        cellSize,
        0x2534,
        testColor,
      );
      expect(ok, isTrue);
      expect(spy.lineCalls.length, equals(2));

      final hLine = spy.lineCalls[0];
      expect(hLine.p1, equals(const Offset(left, yCenter)));
      expect(hLine.p2, equals(const Offset(right, yCenter)));

      final vLine = spy.lineCalls[1];
      expect(vLine.p1, equals(const Offset(xCenter, top)));
      expect(vLine.p2, equals(const Offset(xCenter, yCenter)));
    });

    test(
        '0x251C (├ Light Vertical & Right) draws through vertical line and right ray',
        () {
      final ok = BoxDrawingVectorRenderer.drawBoxChar(
        spy,
        cellOffset,
        cellSize,
        0x251C,
        testColor,
      );
      expect(ok, isTrue);
      expect(spy.lineCalls.length, equals(2));

      final vLine = spy.lineCalls[0];
      expect(vLine.p1, equals(const Offset(xCenter, top)));
      expect(vLine.p2, equals(const Offset(xCenter, bottom)));

      final hLine = spy.lineCalls[1];
      expect(hLine.p1, equals(const Offset(xCenter, yCenter)));
      expect(hLine.p2, equals(const Offset(right, yCenter)));
    });

    test(
        '0x2524 (┤ Light Vertical & Left) draws through vertical line and left ray',
        () {
      final ok = BoxDrawingVectorRenderer.drawBoxChar(
        spy,
        cellOffset,
        cellSize,
        0x2524,
        testColor,
      );
      expect(ok, isTrue);
      expect(spy.lineCalls.length, equals(2));

      final vLine = spy.lineCalls[0];
      expect(vLine.p1, equals(const Offset(xCenter, top)));
      expect(vLine.p2, equals(const Offset(xCenter, bottom)));

      final hLine = spy.lineCalls[1];
      expect(hLine.p1, equals(const Offset(left, yCenter)));
      expect(hLine.p2, equals(const Offset(xCenter, yCenter)));
    });

    test('0x253C (┼ Light Cross) draws through horizontal and vertical lines',
        () {
      final ok = BoxDrawingVectorRenderer.drawBoxChar(
        spy,
        cellOffset,
        cellSize,
        0x253C,
        testColor,
      );
      expect(ok, isTrue);
      expect(spy.lineCalls.length, equals(2));

      expect(spy.lineCalls[0].p1, equals(const Offset(left, yCenter)));
      expect(spy.lineCalls[0].p2, equals(const Offset(right, yCenter)));
      expect(spy.lineCalls[1].p1, equals(const Offset(xCenter, top)));
      expect(spy.lineCalls[1].p2, equals(const Offset(xCenter, bottom)));
    });

    test('0x254B (╋ Heavy Cross) draws heavy through lines', () {
      final ok = BoxDrawingVectorRenderer.drawBoxChar(
        spy,
        cellOffset,
        cellSize,
        0x254B,
        testColor,
        heavyStrokeWidth: 2.0,
      );
      expect(ok, isTrue);
      expect(spy.lineCalls.length, equals(2));
      expect(spy.lineCalls[0].strokeWidth, equals(2.0));
      expect(spy.lineCalls[1].strokeWidth, equals(2.0));
    });
  });

  group('BoxDrawingVectorRenderer - Double & Mixed Lines', () {
    late SpyCanvas spy;

    setUp(() {
      spy = SpyCanvas();
    });

    test(
        '0x2550 (═ Double Horizontal) draws two parallel lines across full width',
        () {
      final ok = BoxDrawingVectorRenderer.drawBoxChar(
        spy,
        cellOffset,
        cellSize,
        0x2550,
        testColor,
      );
      expect(ok, isTrue);
      expect(spy.lineCalls.length, equals(2));

      final line1 = spy.lineCalls[0];
      final line2 = spy.lineCalls[1];

      // Both span left to right
      expect(line1.p1.dx, equals(left));
      expect(line1.p2.dx, equals(right));
      expect(line2.p1.dx, equals(left));
      expect(line2.p2.dx, equals(right));

      // Symmetrically spaced above and below yCenter
      expect(line1.p1.dy, lessThan(yCenter));
      expect(line2.p1.dy, greaterThan(yCenter));
      expect((yCenter - line1.p1.dy), closeTo(line2.p1.dy - yCenter, 0.001));
    });

    test(
        '0x2551 (║ Double Vertical) draws two parallel lines across full height',
        () {
      final ok = BoxDrawingVectorRenderer.drawBoxChar(
        spy,
        cellOffset,
        cellSize,
        0x2551,
        testColor,
      );
      expect(ok, isTrue);
      expect(spy.lineCalls.length, equals(2));

      final line1 = spy.lineCalls[0];
      final line2 = spy.lineCalls[1];

      // Both span top to bottom
      expect(line1.p1.dy, equals(top));
      expect(line1.p2.dy, equals(bottom));
      expect(line2.p1.dy, equals(top));
      expect(line2.p2.dy, equals(bottom));

      // Symmetrically spaced left and right of xCenter
      expect(line1.p1.dx, lessThan(xCenter));
      expect(line2.p1.dx, greaterThan(xCenter));
      expect((xCenter - line1.p1.dx), closeTo(line2.p1.dx - xCenter, 0.001));
    });

    test(
        '0x2554 (╔ Double Down & Right) draws 4 segments forming double corner',
        () {
      final ok = BoxDrawingVectorRenderer.drawBoxChar(
        spy,
        cellOffset,
        cellSize,
        0x2554,
        testColor,
      );
      expect(ok, isTrue);
      expect(spy.lineCalls.length, equals(4));

      // Outer horizontal line reaches right boundary
      expect(spy.lineCalls[0].p2.dx, equals(right));
      // Outer vertical line reaches bottom boundary
      expect(spy.lineCalls[1].p2.dy, equals(bottom));
      // Inner horizontal reaches right
      expect(spy.lineCalls[2].p2.dx, equals(right));
      // Inner vertical reaches bottom
      expect(spy.lineCalls[3].p2.dy, equals(bottom));
    });

    test(
        '0x256C (╬ Double Cross) draws 8 segments maintaining open intersection',
        () {
      final ok = BoxDrawingVectorRenderer.drawBoxChar(
        spy,
        cellOffset,
        cellSize,
        0x256C,
        testColor,
      );
      expect(ok, isTrue);
      expect(spy.lineCalls.length, equals(8));
    });

    test(
        '0x255E (╞ Single Vert & Double Right) draws through single vertical and 2 right horizontals',
        () {
      final ok = BoxDrawingVectorRenderer.drawBoxChar(
        spy,
        cellOffset,
        cellSize,
        0x255E,
        testColor,
      );
      expect(ok, isTrue);
      expect(spy.lineCalls.length, equals(3));

      // Single vertical through line
      expect(spy.lineCalls[0].p1, equals(const Offset(xCenter, top)));
      expect(spy.lineCalls[0].p2, equals(const Offset(xCenter, bottom)));

      // Two right horizontal segments
      expect(spy.lineCalls[1].p2.dx, equals(right));
      expect(spy.lineCalls[2].p2.dx, equals(right));
    });
  });

  group('BoxDrawingVectorRenderer - Dashed Lines', () {
    late SpyCanvas spy;

    setUp(() {
      spy = SpyCanvas();
    });

    test(
        '0x2504 (┄ Light Triple Dash Horizontal) draws 3 collinear segments at yCenter',
        () {
      final ok = BoxDrawingVectorRenderer.drawBoxChar(
        spy,
        cellOffset,
        cellSize,
        0x2504,
        testColor,
      );
      expect(ok, isTrue);
      expect(spy.lineCalls.length, equals(3));

      for (final call in spy.lineCalls) {
        expect(call.p1.dy, equals(yCenter));
        expect(call.p2.dy, equals(yCenter));
        expect(call.p1.dx, greaterThanOrEqualTo(left));
        expect(call.p2.dx, lessThanOrEqualTo(right));
      }
    });

    test(
        '0x2508 (┈ Light Quadruple Dash Horizontal) draws 4 collinear segments',
        () {
      final ok = BoxDrawingVectorRenderer.drawBoxChar(
        spy,
        cellOffset,
        cellSize,
        0x2508,
        testColor,
      );
      expect(ok, isTrue);
      expect(spy.lineCalls.length, equals(4));
    });

    test('0x254C (╌ Light Double Dash Horizontal) draws 2 collinear segments',
        () {
      final ok = BoxDrawingVectorRenderer.drawBoxChar(
        spy,
        cellOffset,
        cellSize,
        0x254C,
        testColor,
      );
      expect(ok, isTrue);
      expect(spy.lineCalls.length, equals(2));
    });

    test(
        '0x2506 (┆ Light Triple Dash Vertical) draws 3 collinear segments at xCenter',
        () {
      final ok = BoxDrawingVectorRenderer.drawBoxChar(
        spy,
        cellOffset,
        cellSize,
        0x2506,
        testColor,
      );
      expect(ok, isTrue);
      expect(spy.lineCalls.length, equals(3));

      for (final call in spy.lineCalls) {
        expect(call.p1.dx, equals(xCenter));
        expect(call.p2.dx, equals(xCenter));
        expect(call.p1.dy, greaterThanOrEqualTo(top));
        expect(call.p2.dy, lessThanOrEqualTo(bottom));
      }
    });
  });

  group('BoxDrawingVectorRenderer - Arcs, Diagonals & Half-lines', () {
    late SpyCanvas spy;

    setUp(() {
      spy = SpyCanvas();
    });

    test('0x256D (╭ Light Arc Down & Right) draws a smooth Bezier path', () {
      final ok = BoxDrawingVectorRenderer.drawBoxChar(
        spy,
        cellOffset,
        cellSize,
        0x256D,
        testColor,
      );
      expect(ok, isTrue);
      expect(spy.pathCalls.length, equals(1));
      expect(
          spy.pathCalls.first.color.toARGB32(), equals(testColor.toARGB32()));
    });

    test(
        '0x2571 (╱ Light Diagonal UR to LL) draws line from right-top to left-bottom',
        () {
      final ok = BoxDrawingVectorRenderer.drawBoxChar(
        spy,
        cellOffset,
        cellSize,
        0x2571,
        testColor,
      );
      expect(ok, isTrue);
      expect(spy.lineCalls.length, equals(1));
      expect(spy.lineCalls.first.p1, equals(const Offset(right, top)));
      expect(spy.lineCalls.first.p2, equals(const Offset(left, bottom)));
    });

    test('0x2573 (╳ Light Diagonal Cross) draws two diagonal lines', () {
      final ok = BoxDrawingVectorRenderer.drawBoxChar(
        spy,
        cellOffset,
        cellSize,
        0x2573,
        testColor,
      );
      expect(ok, isTrue);
      expect(spy.lineCalls.length, equals(2));
    });

    test('0x2574 (╴ Light Left) draws single ray from left boundary to center',
        () {
      final ok = BoxDrawingVectorRenderer.drawBoxChar(
        spy,
        cellOffset,
        cellSize,
        0x2574,
        testColor,
      );
      expect(ok, isTrue);
      expect(spy.lineCalls.length, equals(1));
      expect(spy.lineCalls.first.p1, equals(const Offset(left, yCenter)));
      expect(spy.lineCalls.first.p2, equals(const Offset(xCenter, yCenter)));
    });

    test(
        '0x257C (╼ Light Left & Heavy Right) draws light left ray and heavy right ray',
        () {
      final ok = BoxDrawingVectorRenderer.drawBoxChar(
        spy,
        cellOffset,
        cellSize,
        0x257C,
        testColor,
        lightStrokeWidth: 1.0,
        heavyStrokeWidth: 3.0,
      );
      expect(ok, isTrue);
      expect(spy.lineCalls.length, equals(2));

      final leftCall = spy.lineCalls[0];
      final rightCall = spy.lineCalls[1];

      expect(leftCall.p1, equals(const Offset(left, yCenter)));
      expect(leftCall.p2, equals(const Offset(xCenter, yCenter)));
      expect(leftCall.strokeWidth, equals(1.0));

      expect(rightCall.p1, equals(const Offset(xCenter, yCenter)));
      expect(rightCall.p2, equals(const Offset(right, yCenter)));
      expect(rightCall.strokeWidth, equals(3.0));
    });
  });
}
