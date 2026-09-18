import 'dart:convert';
import 'package:core_foundation/core_foundation.dart';
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

    testWidgets('SplitMatrixView updates layout on didUpdateWidget',
        (tester) async {
      var currentLayout = SplitLayoutType.horizontal;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return ProviderScope(
              child: MaterialApp(
                theme: ShellitTheme.obsidianDarkTheme,
                home: Scaffold(
                  body: Column(
                    children: [
                      ElevatedButton(
                        key: const ValueKey('change-layout-btn'),
                        onPressed: () {
                          setState(() {
                            currentLayout = SplitLayoutType.grid2x2;
                          });
                        },
                        child: const Text('Change to 2x2'),
                      ),
                      Expanded(
                        child: SplitMatrixView(
                          sessions: [session1, session2, session3, session4],
                          initialLayout: currentLayout,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );

      expect(find.byType(TerminalScreen), findsNWidgets(2));

      // Trigger rebuild with new initialLayout
      await tester.tap(find.byKey(const ValueKey('change-layout-btn')));
      await tester.pumpAndSettle();

      expect(find.byType(TerminalScreen), findsNWidgets(4));
    });

    test(
        'SessionManagerNotifier.setSplitLayout converts tab to splitTerminal and aggregates open sessions',
        () {
      final notifier = SessionManagerNotifier();
      final now = DateTime.now();
      final hostA = HostEntity(
        id: 'h1',
        label: 'Hetzner',
        hostname: '65.108.57.255',
        username: 'kobalt',
        authType: HostAuthType.password,
        createdAt: now,
        updatedAt: now,
      );
      final hostB = HostEntity(
        id: 'h2',
        label: 'Senko',
        hostname: '144.31.19.22',
        username: 'root',
        authType: HostAuthType.password,
        createdAt: now,
        updatedAt: now,
      );

      final tab1Id = notifier.openTerminalTab(host: hostA, session: session1);
      final tab2Id = notifier.openTerminalTab(host: hostB, session: session2);

      expect(notifier.state.tabs.length, 2);
      expect(notifier.state.tabs[0].type, TabType.terminal);
      expect(notifier.state.tabs[1].type, TabType.terminal);

      // On Tab 2 (Senko), activate horizontal split
      notifier.setSplitLayout(tab2Id, SplitLayoutType.horizontal);

      final updatedTab2 = notifier.state.tabs.firstWhere((t) => t.id == tab2Id);
      expect(updatedTab2.type, TabType.splitTerminal);
      expect(updatedTab2.splitLayout, SplitLayoutType.horizontal);
      // It should keep ONLY session2 so other split pane slots start empty!
      expect(updatedTab2.splitSessions.length, 1);
      expect(updatedTab2.splitSessions[0], session2);

      // Now drag-and-drop Tab 1 into Tab 2's split
      notifier.moveTabToSplit(sourceTabId: tab1Id, targetTabId: tab2Id);
      final dockedTab2 = notifier.state.tabs.firstWhere((t) => t.id == tab2Id);
      expect(dockedTab2.splitSessions.length, 2);
      expect(dockedTab2.splitSessions[0], session2);
      expect(dockedTab2.splitSessions[1], session1);

      // Close pane 1 via closeSplitPane
      notifier.closeSplitPane(tabId: tab2Id, paneIndex: 1);
      final singleTab2 = notifier.state.tabs.firstWhere((t) => t.id == tab2Id);
      expect(singleTab2.type, TabType.terminal);
      expect(singleTab2.splitLayout, SplitLayoutType.single);
      expect(singleTab2.splitSessions.length, 1);
      expect(singleTab2.splitSessions[0], session2);
    });
  });
}
