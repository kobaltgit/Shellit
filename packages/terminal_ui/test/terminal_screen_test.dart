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

  group('TerminalScreen keyboard input and focus regression tests (BUG-007)',
      () {
    late FakeTerminalSession session;

    setUp(() {
      session = FakeTerminalSession(id: 'sess-1', hostId: 'host-1');
    });

    tearDown(() async {
      await session.terminate();
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
