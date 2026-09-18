import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

void main() {
  final testHost = HostEntity(
    id: 'host-test-1',
    label: 'Test Server',
    hostname: 'test.example.com',
    port: 22,
    username: 'testuser',
    authType: HostAuthType.password,
    environment: HostEnvironment.production,
    osType: OsType.ubuntu,
    tags: const ['test', 'prod'],
    folderId: 'folder-1',
    lastPingLatencyMs: 42,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final testFolders = [
    const FolderEntity(id: 'folder-1', name: 'Database Cluster'),
    const FolderEntity(id: 'folder-2', name: 'Web Frontend'),
  ];

  Widget buildTestApp(
      {required Widget child, List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: ShellitTheme.obsidianDarkTheme,
        home: Scaffold(body: child),
      ),
    );
  }

  group('HostCard Context Menu & Actions Tests', () {
    testWidgets('Opens context menu via "..." button on Grid Card',
        (tester) async {
      bool editCalled = false;

      await tester.pumpWidget(
        buildTestApp(
          child: HostCard(
            host: testHost,
            onEdit: () => editCalled = true,
          ),
        ),
      );

      // Verify card rendered
      expect(find.text('Test Server'), findsOneWidget);

      // Find and tap the "..." more actions button
      final moreBtn = find.byTooltip('More Actions');
      expect(moreBtn, findsOneWidget);
      await tester.tap(moreBtn);
      await tester.pumpAndSettle();

      // Verify context menu items are displayed
      expect(find.text('Quick Connect'), findsOneWidget);
      expect(find.text('Connect'), findsOneWidget);
      expect(find.text('Edit Host Details'), findsOneWidget);
      expect(find.text('Move to Folder'), findsOneWidget);
      expect(find.text('Duplicate'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);

      // Tap Edit Host Details
      await tester.tap(find.text('Edit Host Details'));
      await tester.pumpAndSettle();

      expect(editCalled, isTrue);
    });

    testWidgets('Opens context menu via Secondary Tap (RMB)', (tester) async {
      bool duplicateCalled = false;

      await tester.pumpWidget(
        buildTestApp(
          child: HostCard(
            host: testHost,
            onDuplicate: () => duplicateCalled = true,
          ),
        ),
      );

      // Simulate right-click (secondary tap)
      await tester.tap(find.text('Test Server'),
          buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();

      // Context menu should appear
      expect(find.text('Duplicate'), findsOneWidget);

      await tester.tap(find.text('Duplicate'));
      await tester.pumpAndSettle();

      expect(duplicateCalled, isTrue);
    });

    testWidgets(
        'Keyboard shortcuts: Enter triggers onConnect, E triggers onEdit',
        (tester) async {
      bool connectCalled = false;
      bool editCalled = false;

      await tester.pumpWidget(
        buildTestApp(
          child: HostCard(
            host: testHost,
            autofocus: true,
            onConnect: () => connectCalled = true,
            onEdit: () => editCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Now send KeyDownEvent for Enter
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(connectCalled, isTrue);

      // Now send KeyDownEvent for 'E'
      await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
      await tester.pump();
      expect(editCalled, isTrue);
    });
  });

  group('HostFormDialog Folder Selection Tests', () {
    testWidgets('Displays folders in dropdown and creates a new folder',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      HostEntity? savedHost;

      await tester.pumpWidget(
        buildTestApp(
          child: Center(
            child: SizedBox(
              width: 600,
              height: 750,
              child: HostFormDialog(
                initialHost: testHost,
                availableFolders: testFolders,
                onCreateFolder: (name) async {
                  return FolderEntity(id: 'folder-new', name: name);
                },
                onSave: (host, password) {
                  savedHost = host;
                },
              ),
            ),
          ),
        ),
      );

      // Verify the dialog has initial folder selected
      expect(find.text('Database Cluster'), findsOneWidget);

      // Verify the "+ Create New Folder" icon button exists
      final newFolderBtn = find.byTooltip('Create New Folder');
      expect(newFolderBtn, findsOneWidget);

      // Tap to open folder creation dialog
      await tester.tap(newFolderBtn);
      await tester.pumpAndSettle();

      expect(find.text('Create New Folder'), findsOneWidget);

      // Enter new folder name
      await tester.enterText(find.byType(TextField).last, 'Analytics Pipeline');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Submit the host form
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(savedHost, isNotNull);
      expect(savedHost!.folderId, equals('folder-new'));
    });
  });
}
