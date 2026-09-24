import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/src/widgets/terminal/terminal_session_registry.dart';
import 'package:terminal_ui/terminal_ui.dart';
import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TerminalScreen Read-Only badge and UX tests', () {
    late FakeTerminalSession session;
    String? mockClipboardText;

    setUp(() {
      TerminalSessionRegistry.instance.clear();
      session = FakeTerminalSession(id: 'sess-ro-1', hostId: 'host-ro-1');
      mockClipboardText = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform,
              (MethodCall call) async {
        if (call.method == 'Clipboard.setData') {
          mockClipboardText = (call.arguments as Map)['text'] as String?;
          return null;
        }
        if (call.method == 'Clipboard.getData') {
          return mockClipboardText == null ? null : {'text': mockClipboardText};
        }
        if (call.method == 'Clipboard.hasStrings') {
          return {'value': mockClipboardText != null};
        }
        return null;
      });
    });

    tearDown(() async {
      TerminalSessionRegistry.instance.clear();
      await session.terminate();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('Displays [🔒 Read-Only] badge when isReadOnly is true',
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
                  isReadOnly: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('terminal_read_only_badge')), findsOneWidget);
      expect(find.text('Read-Only'), findsOneWidget);
      expect(find.text('🔒'), findsOneWidget);
    });

    testWidgets('Displays [🔒 Read-Only] badge when host.isReadOnly is true',
        (tester) async {
      final now = DateTime.now();
      final readOnlyHost = HostEntity(
        id: 'host-ro-flag',
        label: 'Production Staging (Audit)',
        hostname: 'audit.internal',
        username: 'auditor',
        authType: HostAuthType.password,
        isReadOnly: true,
        createdAt: now,
        updatedAt: now,
      );

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
                  host: readOnlyHost,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('terminal_read_only_badge')), findsOneWidget);
      expect(find.text('Read-Only'), findsOneWidget);
    });

    testWidgets('Does NOT display Read-Only badge when session is writable',
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
                  isReadOnly: false,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('terminal_read_only_badge')), findsNothing);
      expect(find.text('Read-Only'), findsNothing);
    });

    testWidgets('Blocks keyboard input when session is read-only',
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
                  isReadOnly: true,
                  autoFocus: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Send keystroke 'a'
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA, character: 'a');
      await tester.pump();

      // Nothing should have been sent to remote session
      expect(session.receivedInputs, isEmpty);

      // Warning snackbar or toast should appear
      expect(find.textContaining('Read-Only'), findsWidgets);
    });
  });
}
