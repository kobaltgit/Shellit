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

    testWidgets('SftpConflictDialog returns overwrite decision and applyToAll flag',
        (tester) async {
      SftpConflictResult? conflictResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  conflictResult = await showDialog<SftpConflictResult>(
                    context: context,
                    builder: (_) => SftpConflictDialog(
                      fileName: 'conflict_file.txt',
                      sourceSizeBytes: 2048,
                      sourceModified: DateTime(2026, 9, 21, 10, 0),
                      destSizeBytes: 1024,
                      destModified: DateTime(2026, 9, 20, 10, 0),
                    ),
                  );
                },
                child: const Text('Open Conflict Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Conflict Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('File Conflict: conflict_file.txt'), findsOneWidget);
      expect(find.textContaining('2.0 KB'), findsOneWidget);
      expect(find.textContaining('1.0 KB'), findsOneWidget);

      // Toggle Apply to all
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Tap Overwrite
      await tester.tap(find.widgetWithText(ElevatedButton, 'Overwrite'));
      await tester.pumpAndSettle();

      expect(conflictResult, isNotNull);
      expect(conflictResult!.decision, equals(SftpConflictDecision.overwrite));
      expect(conflictResult!.applyToAll, isTrue);
    });

    testWidgets('SftpConflictDialog returns skip decision', (tester) async {
      SftpConflictResult? conflictResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  conflictResult = await showDialog<SftpConflictResult>(
                    context: context,
                    builder: (_) => const SftpConflictDialog(
                      fileName: 'skip_file.txt',
                    ),
                  );
                },
                child: const Text('Open Skip Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Skip Dialog'));
      await tester.pumpAndSettle();

      // Tap Skip
      await tester.tap(find.widgetWithText(OutlinedButton, 'Skip'));
      await tester.pumpAndSettle();

      expect(conflictResult, isNotNull);
      expect(conflictResult!.decision, equals(SftpConflictDecision.skip));
    });
  });
}
