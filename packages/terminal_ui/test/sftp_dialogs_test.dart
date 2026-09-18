import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/src/widgets/sftp/sftp_dialogs.dart';

void main() {
  group('SFTP Dialogs Unit Tests', () {
    testWidgets('SftpChmodDialog calculates octal permissions accurately',
        (tester) async {
      int? resultMode;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  resultMode = await showDialog<int>(
                    context: context,
                    builder: (_) => const SftpChmodDialog(
                      fileName: 'test.sh',
                      initialPermissions: 0x1ED, // 0755
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Permissions: test.sh'), findsOneWidget);
      expect(find.text('0755'), findsOneWidget);

      // Tap Apply
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(resultMode, equals(0x1ED));
    });

    testWidgets('SftpRenameDialog submits new name', (tester) async {
      String? resultName;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  resultName = await showDialog<String>(
                    context: context,
                    builder: (_) =>
                        const SftpRenameDialog(currentName: 'old_file.txt'),
                  );
                },
                child: const Text('Rename Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Rename Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'new_file.txt');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Rename'));
      await tester.pumpAndSettle();

      expect(resultName, equals('new_file.txt'));
    });

    testWidgets('SftpDeleteConfirmDialog confirms or cancels deletion',
        (tester) async {
      bool? resultConfirm;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  resultConfirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => const SftpDeleteConfirmDialog(
                      name: 'important_dir',
                      isDirectory: true,
                    ),
                  );
                },
                child: const Text('Delete Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Delete Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Directory'), findsOneWidget);
      expect(
          find.text(
              'This will recursively delete the directory and all of its contents. This action cannot be undone.'),
          findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(resultConfirm, isTrue);
    });
  });
}
