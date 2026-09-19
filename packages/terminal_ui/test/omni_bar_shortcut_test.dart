import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

class _FakeSshClientService implements ISshClientService {
  @override
  Future<Result<int, NetworkFailure>> pingHost(String hostname, int port,
      {Duration timeout = const Duration(seconds: 2)}) async {
    return const Result.success(15);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Omni-Bar Ctrl+K shortcut tests (BUG-022)', () {
    testWidgets('Ctrl+K with LogicalKeyboardKey.keyK opens OmniSearchModal',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sshClientServiceProvider
                .overrideWithValue(_FakeSshClientService()),
          ],
          child: MaterialApp(
            theme: ShellitTheme.obsidianDarkTheme,
            home: const ShellitAppShell(
              forceMobile: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify OmniSearchModal is not open yet
      expect(find.byType(OmniSearchModal), findsNothing);

      // Send Ctrl+K
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyK,
          physicalKey: PhysicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyK,
          physicalKey: PhysicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      // Verify OmniSearchModal is now open
      expect(find.byType(OmniSearchModal), findsOneWidget);

      // Press Escape to close
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(OmniSearchModal), findsNothing);
    });

    testWidgets(
        'Ctrl+K with PhysicalKeyboardKey.keyK (Russian layout: logicalKey "л") opens OmniSearchModal',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sshClientServiceProvider
                .overrideWithValue(_FakeSshClientService()),
          ],
          child: MaterialApp(
            theme: ShellitTheme.obsidianDarkTheme,
            home: const ShellitAppShell(
              forceMobile: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When non-English layout is active, logical key is NOT keyK (e.g. keyL or Cyrillic),
      // but physicalKey is PhysicalKeyboardKey.keyK.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(
        LogicalKeyboardKey.keyL,
        physicalKey: PhysicalKeyboardKey.keyK,
      );
      await tester.sendKeyUpEvent(
        LogicalKeyboardKey.keyL,
        physicalKey: PhysicalKeyboardKey.keyK,
      );
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      // Verify OmniSearchModal is opened successfully via physical key
      expect(find.byType(OmniSearchModal), findsOneWidget);
    });
  });
}
