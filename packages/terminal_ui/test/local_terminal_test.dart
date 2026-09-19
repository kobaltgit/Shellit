import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

void main() {
  group('LocalShellDetector and LocalShellsNotifier Tests', () {
    test('LocalShellDetector returns valid shells with isDefault marked',
        () async {
      const detector = LocalShellDetector();
      final shells = await detector.detectAvailableShells();

      expect(shells, isNotEmpty);
      expect(shells.any((s) => s.isDefault), isTrue);
      // Ensure IDs and executables are non-empty
      for (final s in shells) {
        expect(s.id, isNotEmpty);
        expect(s.executablePath, isNotEmpty);
      }
    });

    test('LocalShellsNotifier loads shells and allows setting default shell',
        () async {
      final notifier = LocalShellsNotifier();
      await notifier.loadShells();

      expect(notifier.state.profiles, isNotEmpty);
      final defaultShell = notifier.state.defaultProfile;
      expect(defaultShell, isNotNull);

      if (notifier.state.profiles.length > 1) {
        final otherShell =
            notifier.state.profiles.firstWhere((p) => p.id != defaultShell!.id);
        notifier.setDefaultShell(otherShell.id);

        expect(notifier.state.defaultProfile?.id, otherShell.id);
      }
    });
  });

  group('SessionManagerNotifier Local Terminal Tests', () {
    test('openLocalTerminalTab creates tab with TabType.localTerminal',
        () async {
      final notifier = SessionManagerNotifier();
      const profile = LocalShellProfile(
        id: 'test_shell',
        name: 'Test Shell',
        shellType: ShellType.custom,
        executablePath: 'cmd.exe',
      );

      final tabId = await notifier.openLocalTerminalTab(profile: profile);

      expect(notifier.state.tabs.length, 1);
      final tab = notifier.state.activeTab;
      expect(tab, isNotNull);
      expect(tab!.id, tabId);
      expect(tab.type, TabType.localTerminal);
      expect(tab.title, 'Terminal (Test Shell)');
      expect(tab.localShellProfile?.id, 'test_shell');
    });

    test('closeTab terminates and removes local terminal tab cleanly',
        () async {
      final notifier = SessionManagerNotifier();
      const profile = LocalShellProfile(
        id: 'test_shell',
        name: 'Test Shell',
        shellType: ShellType.custom,
        executablePath: 'cmd.exe',
      );

      final tabId = await notifier.openLocalTerminalTab(profile: profile);
      expect(notifier.state.tabs.length, 1);

      notifier.closeTab(tabId);
      expect(notifier.state.tabs, isEmpty);
      expect(notifier.state.activeTabId, isNull);
    });
  });

  group('LocalTerminalButton Widget Tests', () {
    testWidgets('renders split button with Terminal label and chevron',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LocalTerminalButton(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Terminal'), findsOneWidget);
      expect(find.byIcon(Icons.terminal), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });
  });

  group('LocalTerminalSession Tests', () {
    test('LocalTerminalSession outputStream supports multiple listeners and terminates cleanly', () async {
      try {
        const detector = LocalShellDetector();
        final shells = await detector.detectAvailableShells();
        expect(shells, isNotEmpty);
        final defaultShell = shells.firstWhere((s) => s.isDefault, orElse: () => shells.first);

        final session = await LocalTerminalSession.start(
          profile: defaultShell,
          initialDimensions: const TerminalDimensions(cols: 80, rows: 24),
        );

        expect(session.currentState, SessionState.ready);

        // Verify multiple concurrent listeners do not throw 'Bad state: Stream has already been listened to'
        final sub1 = session.outputStream.listen((_) {});
        final sub2 = session.outputStream.listen((_) {});

        await Future<void>.delayed(const Duration(milliseconds: 100));

        await sub1.cancel();
        await sub2.cancel();
        await session.terminate();

        expect(session.currentState, SessionState.disconnected);
      } on ArgumentError catch (e) {
        if (e.message.toString().contains('Failed to load dynamic library')) {
          // Skip live Pty instantiation if runner DLL is not in PATH
          return;
        }
        rethrow;
      }
    });
  });
}

