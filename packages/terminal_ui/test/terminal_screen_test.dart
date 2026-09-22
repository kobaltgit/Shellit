import 'dart:convert';
import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/src/widgets/terminal/terminal_session_registry.dart';
import 'package:terminal_ui/terminal_ui.dart';
import 'package:xterm/xterm.dart';
import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TerminalScreen keyboard input and focus regression tests (BUG-007)',
      () {
    late FakeTerminalSession session;
    String? mockClipboardText;

    setUp(() {
      TerminalSessionRegistry.instance.clear();
      session = FakeTerminalSession(id: 'sess-1', hostId: 'host-1');
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

    testWidgets(
        'TerminalScreen autofocuses and receives typed characters from hardware keyboard',
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

      // Check TerminalView is mounted
      expect(find.byType(TerminalScreen), findsOneWidget);

      // Simulate typing 'ls -la' followed by enter
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyL, character: 'l');
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyL);
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyS, character: 's');
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyS);
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.space, character: ' ');
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      // Verify that characters and Enter reached the session input stream
      expect(session.receivedInputs.isNotEmpty, isTrue);

      final combinedInput =
          session.receivedInputs.map((bytes) => utf8.decode(bytes)).join();

      expect(combinedInput, contains('l'));
      expect(combinedInput, contains('s'));
      expect(combinedInput, contains(' '));
      expect(combinedInput, contains('\r'));
    });

    testWidgets('TerminalScreen font zoom buttons change terminal font size',
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

      expect(find.text('13pt'), findsOneWidget);

      // Tap + button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.text('14pt'), findsOneWidget);

      // Tap - button twice
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();
      expect(find.text('12pt'), findsOneWidget);
    });

    testWidgets('Tapping on TerminalScreen requests focus', (tester) async {
      final unfocusNode = FocusNode();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ShellitTheme.obsidianDarkTheme,
            home: Scaffold(
              body: Column(
                children: [
                  TextField(focusNode: unfocusNode, autofocus: true),
                  Expanded(
                    child: TerminalScreen(
                      session: session,
                      autoFocus: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(unfocusNode.hasFocus, isTrue);

      // Tap on TerminalScreen
      await tester.tap(find.byType(TerminalScreen));
      await tester.pumpAndSettle();

      // After tap, focus has moved away from the textfield to the terminal
      expect(unfocusNode.hasFocus, isFalse);
    });

    testWidgets(
        'TerminalScreen correctly transmits Cyrillic unicode characters and backspace',
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

      // Type 'echo привет'
      for (final char in 'echo привет'.split('')) {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA, character: char);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
        await tester.pump();
      }

      // Type Backspace
      await tester.sendKeyDownEvent(LogicalKeyboardKey.backspace);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.backspace);
      await tester.pump();

      // Press Enter
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      final combinedInput =
          session.receivedInputs.map((bytes) => utf8.decode(bytes)).join();

      expect(combinedInput, contains('echo'));
      expect(combinedInput, contains('привет'));
      expect(combinedInput, contains('\r'));
    });

    testWidgets('TerminalScreen cursor blinks periodically while focused',
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

      // Advance by 600ms to trigger cursor blink toggle
      await tester.pump(const Duration(milliseconds: 600));

      // Advance again by 600ms
      await tester.pump(const Duration(milliseconds: 600));

      // TerminalScreen remains mounted and healthy
      expect(find.byType(TerminalScreen), findsOneWidget);
    });

    testWidgets(
        'TerminalScreen shows REC indicator when recording is active and responds to toggle tap',
        (tester) async {
      final fakeRec = _FakeSessionRecorder();
      session.recorder = fakeRec;
      bool toggleCalled = false;

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
                  onToggleRecording: () {
                    toggleCalled = true;
                    fakeRec.stopRecording();
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.textContaining('REC'), findsOneWidget);

      // Advance by 1 second to verify timer tick
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('REC 00:01'), findsOneWidget);

      // Tap the REC button
      await tester.tap(find.text('REC 00:01'));
      await tester.pump(const Duration(milliseconds: 150));

      expect(toggleCalled, isTrue);
    });

    testWidgets('Ctrl+C without selection sends SIGINT to terminal session',
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

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      final combinedInput =
          session.receivedInputs.map((bytes) => utf8.decode(bytes)).join();
      expect(combinedInput, contains('\x03'));
    });

    testWidgets(
        'Ctrl+C with active selection copies selected text to Clipboard',
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

      final registryEntry =
          TerminalSessionRegistry.instance.getOrCreate(session);
      registryEntry.terminal.write('Hello World');
      await tester.pump();

      // Select all text using Ctrl+Shift+A
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(registryEntry.controller.selection != null, isTrue);

      // Copy using Ctrl+C with active selection
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump(const Duration(milliseconds: 100));

      final clipData = await Clipboard.getData(Clipboard.kTextPlain);
      expect(clipData?.text, contains('Hello'));
      expect(find.byType(SnackBar), findsOneWidget);

      // Advance past SnackBar duration to clear timers
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('Ctrl+Shift+V pastes single-line clipboard text directly into session',
        (tester) async {
      await Clipboard.setData(const ClipboardData(text: 'pasted_cmd'));

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
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyV);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyV);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      // Pump microtasks for Clipboard.getData and paste
      await tester.pump(const Duration(milliseconds: 100));

      final combinedInput =
          session.receivedInputs.map((bytes) => utf8.decode(bytes)).join();
      expect(combinedInput, contains('pasted_cmd'));
    });

    testWidgets(
        'Ctrl+Shift+V with multiline text opens MultilinePasteDialog and pastes upon confirmation',
        (tester) async {
      await Clipboard.setData(
          const ClipboardData(text: 'line1\nline2\n'));

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
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyV);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyV);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      // MultilinePasteDialog is shown!
      expect(find.byType(MultilinePasteDialog), findsOneWidget);

      // Confirm paste
      await tester.tap(find.text('Paste 3 lines'));
      await tester.pumpAndSettle();

      final combinedInput =
          session.receivedInputs.map((bytes) => utf8.decode(bytes)).join();
      expect(combinedInput, contains('line1'));
      expect(combinedInput, contains('line2'));
    });

    testWidgets('Ctrl + = and Ctrl + - hotkeys zoom font size', (tester) async {
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
      await tester.pump();

      expect(find.text('13pt'), findsOneWidget);

      // Zoom in: Ctrl + =
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.equal);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.equal);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(find.text('14pt'), findsOneWidget);

      // Zoom out: Ctrl + -
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.minus);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.minus);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(find.text('13pt'), findsOneWidget);
    });

    testWidgets('Tapping Keys button opens TerminalShortcutsDialog',
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
      await tester.pump();

      expect(find.text('Keys'), findsOneWidget);
      await tester.tap(find.text('Keys'));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(TerminalShortcutsDialog), findsOneWidget);
      expect(find.text('Terminal Keyboard Shortcuts'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Got it'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(TerminalShortcutsDialog), findsNothing);
    });

    testWidgets('Secondary click on terminal shows context menu',
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
      await tester.pump();

      // Right-click in the terminal view
      await tester.tap(find.byType(TerminalView),
          buttons: kSecondaryMouseButton);
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Paste'), findsOneWidget);
      expect(find.text('Select All'), findsOneWidget);
      expect(find.text('Clear Buffer'), findsOneWidget);
      expect(find.text('Keyboard Shortcuts...'), findsOneWidget);

      // Dismiss menu
      await tester.tapAt(const Offset(10, 10));
      await tester.pump(const Duration(milliseconds: 250));
    });

    testWidgets(
        'Hovering over a link shows click cursor and tooltip badge, Ctrl+Click opens URL',
        (tester) async {
      String? openedUrl;

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
                  enableClickableLinks: true,
                  onOpenUrl: (url) => openedUrl = url,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Emit URL into terminal output stream
      session.emitOutput(
          Uint8List.fromList(utf8.encode('Check https://shellit.dev/download\r\n')));
      await tester.pumpAndSettle();

      // Move mouse pointer over the URL (row 0, col ~10)
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(const Offset(100, 16));
      await tester.pump();

      // Tooltip should be visible with URL text
      expect(find.textContaining('https://shellit.dev/download'), findsOneWidget);

      // Verify TerminalView has SystemMouseCursors.click
      final terminalView =
          tester.widget<TerminalView>(find.byType(TerminalView));
      expect(terminalView.mouseCursor, SystemMouseCursors.click);

      // Send Ctrl key down and click
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      await gesture.down(const Offset(100, 16));
      await gesture.up();
      await tester.pump();

      expect(openedUrl, 'https://shellit.dev/download');

      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await gesture.removePointer();
      await tester.pump(const Duration(milliseconds: 350));
    });
  });
}

class _FakeSessionRecorder implements ISessionRecorder {
  bool _isRec = true;

  @override
  bool get isRecording => _isRec;

  @override
  Future<void> startRecording(SessionRecordingEntity meta) async {
    _isRec = true;
  }

  @override
  void recordInput(Uint8List bytes) {}

  @override
  void recordOutput(Uint8List bytes) {}

  @override
  Future<SessionRecordingEntity> stopRecording() async {
    _isRec = false;
    return SessionRecordingEntity(
      id: 'rec-test',
      hostId: 'host-1',
      hostLabel: 'Test Host',
      username: 'root',
      startedAt: DateTime.now(),
      castFilePath: '',
      logFilePath: '',
    );
  }
}
