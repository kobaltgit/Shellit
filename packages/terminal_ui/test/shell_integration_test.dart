import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_ui/src/widgets/terminal/terminal_session_registry.dart';
import 'package:terminal_ui/terminal_ui.dart';
import 'package:xterm/xterm.dart';
import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShellCommandBlock model tests', () {
    test('reports running state when command has started but exitCode is null',
        () {
      final block = ShellCommandBlock(
        id: 1,
        promptLine: 0,
        startTime: DateTime.now(),
      );
      expect(block.isRunning, isTrue);
      expect(block.isPendingPrompt, isFalse);
      expect(block.isSuccess, isFalse);
      expect(block.isFailure, isFalse);
      expect(block.formatDuration(), isEmpty);
    });

    test(
        'reports pending prompt state when prompt appeared but command not started',
        () {
      final block = ShellCommandBlock(id: 1, promptLine: 0);
      expect(block.isPendingPrompt, isTrue);
      expect(block.isRunning, isFalse);
    });

    test('reports success state when exitCode is 0', () {
      final now = DateTime.now();
      final block = ShellCommandBlock(
        id: 2,
        promptLine: 5,
        exitCode: 0,
        startTime: now.subtract(const Duration(milliseconds: 1400)),
        endTime: now,
      );
      expect(block.isRunning, isFalse);
      expect(block.isSuccess, isTrue);
      expect(block.isFailure, isFalse);
      expect(block.formatDuration(), '1.4s');
    });

    test('reports failure state when exitCode is non-zero', () {
      final now = DateTime.now();
      final block = ShellCommandBlock(
        id: 3,
        promptLine: 12,
        exitCode: 127,
        startTime: now.subtract(const Duration(milliseconds: 450)),
        endTime: now,
      );
      expect(block.isRunning, isFalse);
      expect(block.isSuccess, isFalse);
      expect(block.isFailure, isTrue);
      expect(block.formatDuration(), '450ms');
    });

    test('formats long duration in minutes and seconds', () {
      final now = DateTime.now();
      final block = ShellCommandBlock(
        id: 4,
        promptLine: 20,
        exitCode: 0,
        startTime: now.subtract(const Duration(minutes: 2, seconds: 15)),
        endTime: now,
      );
      expect(block.formatDuration(), '2m 15s');
    });
  });

  group('ShellIntegrationController OSC 133 processing tests', () {
    late ShellIntegrationController controller;
    late Terminal terminal;

    setUp(() {
      controller = ShellIntegrationController();
      terminal = Terminal(maxLines: 100);
    });

    tearDown(() {
      controller.dispose();
    });

    test(
        'processes complete lifecycle of successful command: A -> B -> C -> D;0',
        () {
      terminal.write('user@host:~\$ ');
      controller.handleOSC('133', ['A'], terminal);

      expect(controller.blocks.length, 1);
      final block = controller.currentBlock!;
      expect(block.id, 1);
      expect(block.isPendingPrompt, isTrue);

      // User presses enter
      terminal.write('echo hello\r\n');
      controller.handleOSC('133', ['B'], terminal);
      expect(block.startTime, isNotNull);
      expect(block.isRunning, isTrue);

      // Output starts
      controller.handleOSC('133', ['C'], terminal);
      expect(block.outputStartLine, isNotNull);

      terminal.write('hello\r\n');

      // Command finished with 0
      controller.handleOSC('133', ['D', '0'], terminal);
      expect(block.isRunning, isFalse);
      expect(block.isSuccess, isTrue);
      expect(block.exitCode, 0);
      expect(block.endTime, isNotNull);
    });

    test('processes failed command with non-zero exit code (OSC 133;D;127)',
        () {
      controller.handleOSC('133', ['A'], terminal);
      controller.handleOSC('133', ['B'], terminal);
      controller.handleOSC('133', ['C'], terminal);
      controller.handleOSC('133', ['D', '127'], terminal);

      expect(controller.blocks.length, 1);
      final block = controller.blocks.first;
      expect(block.exitCode, 127);
      expect(block.isFailure, isTrue);
      expect(block.isSuccess, isFalse);
    });

    test('extracts command property from OSC 133;P;cl=<cmd>', () {
      controller.handleOSC('133', ['A'], terminal);
      controller.handleOSC('133', ['P', 'cl=docker compose ps'], terminal);

      expect(controller.currentBlock?.command, 'docker compose ps');
    });

    test('tracks current working directory via OSC 7', () {
      controller.handleOSC('7', ['file://my-vps/var/log/nginx'], terminal);
      expect(controller.currentCwd, '/var/log/nginx');
    });

    test('extracts clean command output via getBlockOutput', () {
      controller.handleOSC('133', ['A'], terminal);
      terminal.write('uptime\r\n');
      controller.handleOSC('133', ['B'], terminal);
      controller.handleOSC('133', ['C'], terminal);
      terminal.write(' 14:02:10 up 45 days, 1 user, load: 0.05\r\n');
      controller.handleOSC('133', ['D', '0'], terminal);

      final block = controller.blocks.first;
      final output = controller.getBlockOutput(terminal, block);
      expect(output, contains('load: 0.05'));
    });

    test(
        'command hopping navigation accurately finds prev and next prompt lines',
        () {
      // Simulate 3 commands at different lines
      final b1 = ShellCommandBlock(id: 1, promptLine: 0, exitCode: 0);
      final b2 = ShellCommandBlock(id: 2, promptLine: 10, exitCode: 0);
      final b3 = ShellCommandBlock(id: 3, promptLine: 25, exitCode: 1);

      controller.addBlock(b1);
      controller.addBlock(b2);
      controller.addBlock(b3);

      // At line 30, prev should be 25
      expect(controller.getPreviousCommandPromptLine(30), 25);
      // At line 25, prev should be 10
      expect(controller.getPreviousCommandPromptLine(25), 10);
      // At line 10, prev should be 0
      expect(controller.getPreviousCommandPromptLine(10), 0);
      // At line 0, prev is null
      expect(controller.getPreviousCommandPromptLine(0), isNull);

      // Next from 0 is 10
      expect(controller.getNextCommandPromptLine(0), 10);
      // Next from 10 is 25
      expect(controller.getNextCommandPromptLine(10), 25);
      // Next from 25 is null
      expect(controller.getNextCommandPromptLine(25), isNull);
    });

    test('clear() resets blocks and current block', () {
      controller.handleOSC('133', ['A'], terminal);
      expect(controller.blocks, isNotEmpty);
      controller.clear();
      expect(controller.blocks, isEmpty);
      expect(controller.currentBlock, isNull);
    });

    test(
        'notifyCommandStarted sets startTime and allows duration calculation on finish',
        () async {
      terminal.write('PS C:\\Users> ');
      controller.handleOSC('133', ['A'], terminal);

      final block = controller.currentBlock!;
      expect(block.startTime, isNull);
      expect(block.isRunning, isFalse);

      // User presses Enter
      controller.notifyCommandStarted();
      expect(block.startTime, isNotNull);
      expect(block.isRunning, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 25));

      // Command finishes
      controller.handleOSC('133', ['D', '0'], terminal);
      expect(block.isRunning, isFalse);
      expect(block.isSuccess, isTrue);
      expect(block.duration, isNotNull);
      expect(block.formatDuration(), isNotEmpty);
    });
  });

  group('ShellIntegrationBootstrap scripts tests', () {
    test('generates valid bootstrap scripts for bash, zsh and fish', () {
      expect(ShellIntegrationBootstrap.bashSnippet, contains('133;A'));
      expect(ShellIntegrationBootstrap.bashSnippet, contains('133;B'));
      expect(ShellIntegrationBootstrap.bashSnippet, contains('133;D'));

      expect(ShellIntegrationBootstrap.zshSnippet,
          contains('add-zsh-hook precmd'));
      expect(ShellIntegrationBootstrap.zshSnippet, contains('133;A'));

      expect(ShellIntegrationBootstrap.fishSnippet, contains('fish_prompt'));
      expect(ShellIntegrationBootstrap.fishSnippet, contains('133;D'));

      expect(
          ShellIntegrationBootstrap.sessionSnippet, contains('BASH_VERSION'));
      expect(ShellIntegrationBootstrap.sessionSnippet, contains('ZSH_VERSION'));
      expect(ShellIntegrationBootstrap.sessionSnippet, contains('clear'));
      expect(ShellIntegrationBootstrap.permanentSnippet, contains('.bashrc'));
    });
  });

  group('TerminalSessionRegistry shell integration wiring tests', () {
    test(
        'creates TerminalSessionEntry with initialized ShellIntegrationController and OSC hook',
        () {
      final session = FakeTerminalSession(id: 's-osc-1', hostId: 'h-1');
      final entry = TerminalSessionRegistry.instance.getOrCreate(session);

      expect(entry.shellIntegration, isNotNull);
      expect(entry.terminal.onPrivateOSC, isNotNull);

      // Test driving OSC sequence through the terminal
      entry.terminal.onPrivateOSC!('133', ['A']);
      expect(entry.shellIntegration.blocks.length, 1);

      entry.terminal.onPrivateOSC!('133', ['D', '0']);
      expect(entry.shellIntegration.blocks.first.isSuccess, isTrue);

      TerminalSessionRegistry.instance.remove('s-osc-1');
    });

    test(
        'injectShellIntegration writes autoInjectSnippet into session input stream',
        () async {
      final session = FakeTerminalSession(id: 's-inject-test', hostId: 'h-1');
      final entry = TerminalSessionRegistry.instance.getOrCreate(session);

      expect(entry.isShellIntegrationInjected, isFalse);

      TerminalSessionRegistry.instance.injectShellIntegration(session, entry);

      expect(entry.isShellIntegrationInjected, isTrue);
      await Future.delayed(const Duration(milliseconds: 20));

      expect(session.receivedInputs, isNotEmpty);
      final decoded = utf8.decode(session.receivedInputs.first);
      expect(decoded, contains('BASH_VERSION'));

      TerminalSessionRegistry.instance.remove('s-inject-test');
    });
  });

  group('ShellCommandMarkersOverlay widget tests', () {
    testWidgets('renders success, error and running markers on scrollbar',
        (tester) async {
      final controller = ShellIntegrationController();
      final terminal = Terminal(maxLines: 100);

      // Add success, failure and running blocks
      final b1 = ShellCommandBlock(id: 1, promptLine: 5, exitCode: 0);
      final b2 = ShellCommandBlock(id: 2, promptLine: 20, exitCode: 1);
      final b3 = ShellCommandBlock(
        id: 3,
        promptLine: 40,
        startTime: DateTime.now(),
      ); // running

      controller.addBlock(b1);
      controller.addBlock(b2);
      controller.addBlock(b3);

      int? scrolledToLine;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 400,
              child: ShellCommandMarkersOverlay(
                controller: controller,
                terminal: terminal,
                onScrollToLine: (line) {
                  scrolledToLine = line;
                },
              ),
            ),
          ),
        ),
      );

      // Verify 3 markers rendered in tooltips
      expect(find.byType(Tooltip), findsNWidgets(3));

      // Tap on first marker
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      expect(scrolledToLine, 5);

      controller.dispose();
    });
  });

  group('ShellGutterMarkersOverlay widget tests', () {
    testWidgets(
        'renders gutter dots for visible prompt lines and handles clicks',
        (tester) async {
      final controller = ShellIntegrationController();
      final terminal = Terminal(maxLines: 100);
      final scrollController = ScrollController();

      // Add success, failure and running blocks
      final b1 = ShellCommandBlock(id: 1, promptLine: 0, exitCode: 0);
      final b2 = ShellCommandBlock(id: 2, promptLine: 3, exitCode: 1);
      final b3 = ShellCommandBlock(
        id: 3,
        promptLine: 6,
        startTime: DateTime.now(),
      ); // running

      controller.addBlock(b1);
      controller.addBlock(b2);
      controller.addBlock(b3);

      ShellCommandBlock? tappedBlock;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 400,
              child: ShellGutterMarkersOverlay(
                controller: controller,
                terminal: terminal,
                scrollController: scrollController,
                lineHeight: 20.0,
                onBlockTap: (b) {
                  tappedBlock = b;
                },
              ),
            ),
          ),
        ),
      );

      // Verify 3 markers rendered
      expect(find.byType(Tooltip), findsNWidgets(3));

      // Tap on first marker
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      expect(tappedBlock?.id, 1);

      controller.dispose();
      scrollController.dispose();
    });
  });

  group('TerminalScreen with Shell Integration integration tests', () {
    testWidgets(
        'TerminalScreen renders with markers off by default and opens setup dialog on tap',
        (tester) async {
      final session = FakeTerminalSession(id: 'test-si-screen', hostId: 'h-1');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TerminalScreen(
                session: session,
                autoFocus: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(TerminalScreen), findsOneWidget);
      // Off by default
      expect(find.byType(ShellGutterMarkersOverlay), findsNothing);
      expect(find.byType(ShellCommandMarkersOverlay), findsNothing);

      // Tap on Markers button (when no markers are active, opens setup dialog)
      await tester.tap(find.text('Markers'));
      await tester.pumpAndSettle();

      expect(find.byType(ShellIntegrationSetupDialog), findsOneWidget);
      expect(find.text('Activate in Current Session'), findsOneWidget);
      expect(find.text('Install Permanently (~/.bashrc)'), findsOneWidget);

      TerminalSessionRegistry.instance.remove('test-si-screen');
    });
  });

  group('Scrollback eviction tracking tests', () {
    test(
        'dynamically updates promptLine and detects eviction when circular buffer trims lines',
        () {
      final terminal = Terminal(maxLines: 30);
      final controller = ShellIntegrationController();

      terminal.write('cmd-1: ');
      controller.handleOSC('133', ['A'], terminal);

      final block = controller.currentBlock!;
      expect(block.isEvicted, isFalse);
      expect(block.promptLine, 0);

      // Write 40 lines to overflow the 30-line buffer completely
      for (int i = 0; i < 40; i++) {
        terminal.write('\r\nline $i');
      }

      // Initial prompt buffer line should now be evicted
      expect(block.isEvicted, isTrue);

      controller.dispose();
    });

    test('command hopping skips evicted command blocks', () {
      final controller = ShellIntegrationController();

      final b1 = ShellCommandBlock(
        id: 1,
        promptLine: 0,
        isEvicted: true,
        exitCode: 0,
      );
      final b2 = ShellCommandBlock(
        id: 2,
        promptLine: 10,
        isEvicted: false,
        exitCode: 0,
      );
      final b3 = ShellCommandBlock(
        id: 3,
        promptLine: 25,
        isEvicted: false,
        exitCode: 1,
      );

      controller.addBlock(b1);
      controller.addBlock(b2);
      controller.addBlock(b3);

      // When jumping back from 15, should hit b2 (10), and from 10 should return null (b1 is evicted)
      expect(controller.getPreviousCommandPromptLine(15), 10);
      expect(controller.getPreviousCommandPromptLine(10), isNull);

      // When jumping forward from 0, should hit b2 (10), skipping evicted b1
      expect(controller.getNextCommandPromptLine(0), 10);

      controller.dispose();
    });

    testWidgets(
        'ShellCommandMarkersOverlay renders evicted counter and hides evicted marker',
        (tester) async {
      final controller = ShellIntegrationController();
      final terminal = Terminal(maxLines: 50);

      final b1 = ShellCommandBlock(
        id: 1,
        promptLine: 2,
        isEvicted: true,
        exitCode: 0,
        startTime: DateTime.now(),
      );
      final b2 = ShellCommandBlock(
        id: 2,
        promptLine: 20,
        isEvicted: false,
        exitCode: 0,
        startTime: DateTime.now(),
      );

      controller.addBlock(b1);
      controller.addBlock(b2);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 12,
              height: 200,
              child: ShellCommandMarkersOverlay(
                controller: controller,
                terminal: terminal,
                onScrollToLine: (_) {},
              ),
            ),
          ),
        ),
      );

      // Evicted counter icon should be rendered at the top
      expect(find.byIcon(Icons.arrow_drop_up), findsOneWidget);
      // Tooltip should describe evicted count
      expect(
        find.byTooltip(
            '1 command(s) evicted from scrollback history (retaining last 50 lines)'),
        findsOneWidget,
      );

      controller.dispose();
    });

    testWidgets(
        'ShellGutterMarkersOverlay hides gutter marker for evicted block',
        (tester) async {
      final controller = ShellIntegrationController();
      final terminal = Terminal(maxLines: 50);
      final scrollController = ScrollController();

      final b1 = ShellCommandBlock(
        id: 1,
        promptLine: 2,
        isEvicted: true,
        exitCode: 0,
        startTime: DateTime.now(),
      );
      final b2 = ShellCommandBlock(
        id: 2,
        promptLine: 5,
        isEvicted: false,
        exitCode: 0,
        startTime: DateTime.now(),
      );

      controller.addBlock(b1);
      controller.addBlock(b2);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 22,
              height: 300,
              child: ShellGutterMarkersOverlay(
                controller: controller,
                terminal: terminal,
                scrollController: scrollController,
                lineHeight: 18.0,
              ),
            ),
          ),
        ),
      );

      // Only 1 gutter marker should be rendered (for b2), b1 should be skipped
      expect(find.byType(Tooltip), findsOneWidget);

      controller.dispose();
      scrollController.dispose();
    });
  });
}
