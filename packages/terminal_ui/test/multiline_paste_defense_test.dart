import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/src/theme/shellit_theme.dart';
import 'package:terminal_ui/src/widgets/terminal/multiline_paste_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final devHost = HostEntity(
    id: 'host-dev',
    label: 'Dev-Box',
    hostname: '192.168.1.100',
    port: 22,
    username: 'developer',
    authType: HostAuthType.password,
    environment: HostEnvironment.development,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final prodHost = HostEntity(
    id: 'host-prod',
    label: 'Prod-Database',
    hostname: '10.0.0.1',
    port: 22,
    username: 'root',
    authType: HostAuthType.password,
    environment: HostEnvironment.production,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  group('MultilinePasteDialog Widget Tests', () {
    testWidgets('renders dialog with line count badge and code preview on dev host',
        (tester) async {
      String? pasteResult;
      const textToPaste = 'echo "Starting deploy"\ncd /var/www\ngit pull\n';

      await tester.pumpWidget(
        MaterialApp(
          theme: ShellitTheme.obsidianDarkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  pasteResult = await MultilinePasteDialog.show(
                    context: context,
                    text: textToPaste,
                    host: devHost,
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify title and line count
      expect(find.byType(MultilinePasteDialog), findsOneWidget);
      expect(find.text('Multiline Paste Warning'), findsOneWidget);
      expect(find.text('4 lines'), findsOneWidget);

      // Verify code preview lines
      expect(find.text('echo "Starting deploy"'), findsOneWidget);
      expect(find.text('cd /var/www'), findsOneWidget);
      expect(find.text('git pull'), findsOneWidget);

      // Verify strip trailing newline checkbox is present and checked by default
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox).first);
      expect(checkbox.value, isTrue);

      // Tap Paste button
      await tester.tap(find.text('Paste 4 lines'));
      await tester.pumpAndSettle();

      // Verify returned text has stripped trailing newline
      expect(pasteResult, isNotNull);
      expect(pasteResult, 'echo "Starting deploy"\ncd /var/www\ngit pull');
    });

    testWidgets(
        'PROD host displays safety banner, detects dangerous command, and requires checkbox confirmation',
        (tester) async {
      String? pasteResult;
      const dangerousScript =
          'systemctl stop nginx\nrm -rf /var/cache/*\nsystemctl start nginx';

      await tester.pumpWidget(
        MaterialApp(
          theme: ShellitTheme.obsidianDarkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  pasteResult = await MultilinePasteDialog.show(
                    context: context,
                    text: dangerousScript,
                    host: prodHost,
                    isProduction: true,
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify PROD badges
      expect(find.text('PROD'), findsOneWidget);
      expect(find.text('PROD GUARD'), findsOneWidget); // Dangerous command indicator

      // Find the Paste button and verify it is initially disabled
      final submitButtonFinder = find.widgetWithText(ElevatedButton, 'Paste 3 lines');
      expect(submitButtonFinder, findsOneWidget);

      final submitBtnBefore = tester.widget<ElevatedButton>(submitButtonFinder);
      expect(submitBtnBefore.onPressed, isNull); // Disabled!

      // Find and check the PROD confirmation checkbox
      final prodConfirmCheckboxFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Checkbox &&
            widget.activeColor == ShellitColors.statusRed,
      );
      expect(prodConfirmCheckboxFinder, findsOneWidget);

      await tester.tap(prodConfirmCheckboxFinder);
      await tester.pumpAndSettle();

      // Verify the Paste button is now enabled
      final submitBtnAfter = tester.widget<ElevatedButton>(submitButtonFinder);
      expect(submitBtnAfter.onPressed, isNotNull);

      // Tap Paste button
      await tester.tap(submitButtonFinder);
      await tester.pumpAndSettle();

      expect(pasteResult, isNotNull);
      expect(pasteResult, contains('rm -rf /var/cache/*'));
    });

    testWidgets('Cancel button dismisses dialog with null result',
        (tester) async {
      String? pasteResult = 'initial';

      await tester.pumpWidget(
        MaterialApp(
          theme: ShellitTheme.obsidianDarkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  pasteResult = await MultilinePasteDialog.show(
                    context: context,
                    text: 'line 1\nline 2',
                    host: devHost,
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(pasteResult, isNull);
    });
  });
}
