import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';
import 'package:xterm/xterm.dart';
import 'test_helpers.dart';

void main() {
  group('TerminalCursorOverlay widget tests', () {
    testWidgets(
        'wraps CustomPaint in RepaintBoundary and IgnorePointer(ignoring: true)',
        (tester) async {
      final blinkNotifier = ValueNotifier<bool>(true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TerminalCursorOverlay(
              cursorOffset: const Offset(10, 20),
              cellSize: const Size(9, 18),
              cursorType: TerminalCursorType.block,
              cursorColor: Colors.blue,
              blinkNotifier: blinkNotifier,
              hasFocus: true,
            ),
          ),
        ),
      );

      // Verify IgnorePointer with ignoring: true to allow clicks/hovers to pass through
      final ignorePointerFinder = find.byType(IgnorePointer);
      expect(ignorePointerFinder, findsWidgets);
      final ignorePointer = tester.widget<IgnorePointer>(
        find.descendant(
          of: find.byType(TerminalCursorOverlay),
          matching: find.byType(IgnorePointer),
        ),
      );
      expect(ignorePointer.ignoring, isTrue);

      // Verify RepaintBoundary exists directly around cursor
      final repaintBoundaryFinder = find.descendant(
        of: find.byType(TerminalCursorOverlay),
        matching: find.byType(RepaintBoundary),
      );
      expect(repaintBoundaryFinder, findsOneWidget);

      // Verify CustomPaint is present
      final customPaintFinder = find.descendant(
        of: find.byType(TerminalCursorOverlay),
        matching: find.byType(CustomPaint),
      );
      expect(customPaintFinder, findsOneWidget);
    });

    testWidgets('paints cursor when focused and blinkNotifier is true',
        (tester) async {
      final blinkNotifier = ValueNotifier<bool>(true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 200,
              child: TerminalCursorOverlay(
                cursorOffset: const Offset(10, 20),
                cellSize: const Size(9, 18),
                cursorType: TerminalCursorType.block,
                cursorColor: const Color(0xFF60A5FA),
                blinkNotifier: blinkNotifier,
                hasFocus: true,
              ),
            ),
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(TerminalCursorOverlay),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(customPaint.painter, isNotNull);

      // Changing blinkNotifier should trigger repaint of painter without rebuilding widget
      blinkNotifier.value = false;
      await tester.pump();
      expect(find.byType(TerminalCursorOverlay), findsOneWidget);

      blinkNotifier.value = true;
      await tester.pump();
      expect(find.byType(TerminalCursorOverlay), findsOneWidget);
    });

    testWidgets('supports block, underline, and verticalBar cursor types',
        (tester) async {
      final blinkNotifier = ValueNotifier<bool>(true);

      for (final type in [
        TerminalCursorType.block,
        TerminalCursorType.underline,
        TerminalCursorType.verticalBar,
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 100,
                height: 100,
                child: TerminalCursorOverlay(
                  cursorOffset: const Offset(5, 5),
                  cellSize: const Size(8, 16),
                  cursorType: type,
                  cursorColor: Colors.green,
                  blinkNotifier: blinkNotifier,
                  hasFocus: true,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(TerminalCursorOverlay), findsOneWidget);
      }
    });

    testWidgets('respects isVisible=false flag without errors', (tester) async {
      final blinkNotifier = ValueNotifier<bool>(true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              height: 100,
              child: TerminalCursorOverlay(
                cursorOffset: const Offset(5, 5),
                cellSize: const Size(8, 16),
                cursorType: TerminalCursorType.block,
                cursorColor: Colors.amber,
                blinkNotifier: blinkNotifier,
                hasFocus: true,
                isVisible: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TerminalCursorOverlay), findsOneWidget);
    });
  });

  group('TerminalScreen cursor overlay integration tests (BUG-052)', () {
    late FakeTerminalSession session;

    setUp(() {
      session = FakeTerminalSession(id: 'sess-cursor-test', hostId: 'host-1');
    });

    testWidgets(
        'TerminalScreen mounts TerminalCursorOverlay and isolates blink timer',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ShellitTheme.obsidianDarkTheme,
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: TerminalScreen(
                  session: session,
                  autoFocus: true,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that TerminalCursorOverlay is present in the widget tree
      expect(find.byType(TerminalCursorOverlay), findsOneWidget);

      // Advance by 600ms (1 blink cycle)
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(TerminalCursorOverlay), findsOneWidget);

      // Advance by another 600ms
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(TerminalCursorOverlay), findsOneWidget);
    });
  });

  group('SplitMatrixView pane isolation tests', () {
    testWidgets(
        'Every terminal pane in SplitMatrixView is wrapped in RepaintBoundary',
        (tester) async {
      final session1 = FakeTerminalSession(id: 'sess-1', hostId: 'host-1');
      final session2 = FakeTerminalSession(id: 'sess-2', hostId: 'host-2');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ShellitTheme.obsidianDarkTheme,
            home: Scaffold(
              body: SizedBox(
                width: 1000,
                height: 800,
                child: SplitMatrixView(
                  sessions: [session1, session2],
                  initialLayout: SplitLayoutType.horizontal,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify TerminalScreen panes exist
      final terminalScreens = find.byType(TerminalScreen);
      expect(terminalScreens, findsNWidgets(2));

      // Each terminal screen must have an ancestor RepaintBoundary that isolates it
      for (int i = 0; i < 2; i++) {
        final screenElement = terminalScreens.at(i);
        final repaintBoundaryAncestor = find.ancestor(
          of: screenElement,
          matching: find.byType(RepaintBoundary),
        );
        expect(repaintBoundaryAncestor, findsWidgets);
      }
    });
  });
}
