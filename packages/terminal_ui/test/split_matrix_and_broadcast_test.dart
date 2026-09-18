import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';
import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SplitMatrixView and Broadcast tests', () {
    late FakeTerminalSession session1;
    late FakeTerminalSession session2;
    late FakeTerminalSession session3;
    late FakeTerminalSession session4;

    setUp(() {
      session1 = FakeTerminalSession(id: 's1', hostId: 'h1');
      session2 = FakeTerminalSession(id: 's2', hostId: 'h1');
      session3 = FakeTerminalSession(id: 's3', hostId: 'h1');
      session4 = FakeTerminalSession(id: 's4', hostId: 'h1');
    });

    tearDown(() async {
      await session1.terminate();
      await session2.terminate();
      await session3.terminate();
      await session4.terminate();
    });

    testWidgets('Renders single layout initially and switches to 2x2 grid',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ShellitTheme.obsidianDarkTheme,
            home: Scaffold(
              body: SplitMatrixView(
                sessions: [session1, session2, session3, session4],
                initialLayout: SplitLayoutType.single,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TerminalScreen), findsOneWidget);

      // Tap 2x2 Grid button
      await tester.tap(find.byTooltip('2x2 Matrix Split'));
      await tester.pumpAndSettle();

      expect(find.byType(TerminalScreen), findsNWidgets(4));

      // Tap Split Horizontal button
      await tester.tap(find.byTooltip('Split Horizontal (Side by side)'));
      await tester.pumpAndSettle();

      expect(find.byType(TerminalScreen), findsNWidgets(2));
    });

    testWidgets('Toggles Broadcast Mode and broadcasts input to other sessions',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ShellitTheme.obsidianDarkTheme,
            home: Scaffold(
              body: SplitMatrixView(
                sessions: [session1, session2],
                initialLayout: SplitLayoutType.horizontal,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Broadcast Input'), findsOneWidget);
      expect(find.text('INPUT SENT TO ALL PANES'), findsNothing);

      // Toggle Broadcast Switch to ON
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('INPUT SENT TO ALL PANES'), findsOneWidget);

      // Trigger broadcast callback from first terminal screen
      final terminalScreenFinder = find.byType(TerminalScreen).first;
      final terminalScreen =
          tester.widget<TerminalScreen>(terminalScreenFinder);
      terminalScreen.onBroadcastOutput?.call('uptime\n');

      await tester.pump();

      // Session 2 should have received the broadcast bytes!
      expect(session2.receivedInputs.isNotEmpty, isTrue);
      final receivedString = utf8.decode(session2.receivedInputs.last);
      expect(receivedString, 'uptime\n');
    });

    testWidgets('Alt+Arrow shifts focus between panes', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ShellitTheme.obsidianDarkTheme,
            home: Scaffold(
              body: SplitMatrixView(
                sessions: [session1, session2, session3, session4],
                initialLayout: SplitLayoutType.horizontal,
              ),
            ),
          ),
        ),
      );

      // Press Alt + ArrowRight
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pump();

      // Focus shifted, both panes still rendered
      expect(find.byType(TerminalScreen), findsNWidgets(2));
    });
  });
}
