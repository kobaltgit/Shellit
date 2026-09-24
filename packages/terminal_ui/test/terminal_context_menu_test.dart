import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/src/widgets/terminal/terminal_context_menu.dart';
import 'package:terminal_ui/src/widgets/terminal/terminal_link_detector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TerminalContextMenu Widget Tests', () {
    testWidgets('renders Open URL and Copy Link items when detectedLink is URL',
        (tester) async {
      bool openedLink = false;
      bool copiedLink = false;

      const detectedUrl = TerminalLinkMatch(
        text: 'https://shellit.dev',
        rawText: 'https://shellit.dev',
        type: TerminalLinkType.url,
        startIndex: 0,
        endIndex: 19,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  TerminalContextMenu.show(
                    context: context,
                    globalPosition: const Offset(100, 100),
                    hasSelection: false,
                    detectedLink: detectedUrl,
                    onOpenLink: () => openedLink = true,
                    onCopyLink: () => copiedLink = true,
                    onCopy: () {},
                    onPaste: () {},
                    onSelectAll: () {},
                    onClear: () {},
                    onShowShortcuts: () {},
                  );
                },
                child: const Text('Show Menu'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      expect(find.text('Open URL: https://shellit.dev'), findsOneWidget);
      expect(find.text('Copy Link Address'), findsOneWidget);

      await tester.tap(find.text('Open URL: https://shellit.dev'));
      await tester.pumpAndSettle();

      expect(openedLink, isTrue);
      expect(copiedLink, isFalse);
    });

    testWidgets(
        'renders Open File and Copy File Path when detectedLink is FilePath',
        (tester) async {
      bool openedFile = false;

      const detectedFile = TerminalLinkMatch(
        text: '/var/log/nginx/access.log',
        rawText: '/var/log/nginx/access.log',
        type: TerminalLinkType.filePath,
        startIndex: 0,
        endIndex: 25,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  TerminalContextMenu.show(
                    context: context,
                    globalPosition: const Offset(100, 100),
                    hasSelection: false,
                    detectedLink: detectedFile,
                    onOpenLink: () => openedFile = true,
                    onCopyLink: () {},
                    onCopy: () {},
                    onPaste: () {},
                    onSelectAll: () {},
                    onClear: () {},
                    onShowShortcuts: () {},
                  );
                },
                child: const Text('Show Menu'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      expect(find.text('Open File: /var/log/nginx/access.log'), findsOneWidget);
      expect(find.text('Copy File Path'), findsOneWidget);

      await tester.tap(find.text('Open File: /var/log/nginx/access.log'));
      await tester.pumpAndSettle();

      expect(openedFile, isTrue);
    });
  });
}
