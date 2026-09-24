import 'dart:convert';
import 'dart:typed_data';
import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

class MockSftpSession implements ISftpSession {
  final Map<String, Uint8List> files = {};

  @override
  String get hostId => 'mock-host';

  @override
  String get id => 'mock-sftp-session';

  @override
  dynamic get underlyingClient => null;

  @override
  Future<Result<void, SftpFailure>> close() async => const Result.success(null);

  @override
  Future<Result<void, SftpFailure>> createDirectory(String remotePath) async =>
      const Result.success(null);

  @override
  Future<Result<void, SftpFailure>> createFile(String remotePath) async {
    files[remotePath] = Uint8List(0);
    return const Result.success(null);
  }

  @override
  Future<Result<void, SftpFailure>> deleteDirectory(String remotePath,
          {bool recursive = false}) async =>
      const Result.success(null);

  @override
  Future<Result<void, SftpFailure>> deleteFile(String remotePath) async {
    files.remove(remotePath);
    return const Result.success(null);
  }

  @override
  Stream<double> downloadFile(
      {required String remotePath, required String localPath}) async* {
    yield 1.0;
  }

  @override
  Future<Result<String, SftpFailure>> getDefaultPath() async =>
      const Result.success('/home/testuser');

  @override
  Future<Result<List<SftpItem>, SftpFailure>> listDirectory(
      String remotePath) async {
    return const Result.success([]);
  }

  @override
  Future<Result<Uint8List, SftpFailure>> readFile(String remotePath) async {
    final data = files[remotePath];
    if (data != null) {
      return Result.success(data);
    }
    return Result.error(SftpFailure.fileNotFound(remotePath));
  }

  @override
  Future<Result<void, SftpFailure>> rename(
          String oldPath, String newPath) async =>
      const Result.success(null);

  @override
  Future<Result<void, SftpFailure>> setPermissions(
          String remotePath, int permissions) async =>
      const Result.success(null);

  @override
  Stream<double> uploadFile(
      {required String localPath, required String remotePath}) async* {
    yield 1.0;
  }

  @override
  Future<Result<void, SftpFailure>> writeFile(
      String remotePath, Uint8List data) async {
    files[remotePath] = data;
    return const Result.success(null);
  }
}

void main() {
  group('SFTP Breadcrumbs Bar Tests', () {
    testWidgets('Renders remote breadcrumb segments and responds to click',
        (tester) async {
      String navigatedPath = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SftpBreadcrumbsBar(
              currentPath: '/var/log/nginx',
              isRemote: true,
              onNavigate: (path) => navigatedPath = path,
              onRefresh: () => navigatedPath = 'REFRESH',
              onNavigateUp: () => navigatedPath = 'UP',
              onNavigateHome: () => navigatedPath = 'HOME',
            ),
          ),
        ),
      );

      // Verify breadcrumb buttons exist
      expect(find.text('var'), findsOneWidget);
      expect(find.text('log'), findsOneWidget);
      expect(find.text('nginx'), findsOneWidget);

      // Tap 'var' segment
      await tester.tap(find.text('var'));
      await tester.pumpAndSettle();
      expect(navigatedPath, equals('/var'));

      // Tap Go Up icon
      await tester.tap(find.byIcon(Icons.arrow_upward));
      await tester.pumpAndSettle();
      expect(navigatedPath, equals('UP'));

      // Tap Home button
      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pumpAndSettle();
      expect(navigatedPath, equals('HOME'));

      // Tap Refresh button
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();
      expect(navigatedPath, equals('REFRESH'));
    });

    testWidgets('Toggles manual path text editing mode', (tester) async {
      String editedPath = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SftpBreadcrumbsBar(
              currentPath: '/etc/ssh',
              isRemote: true,
              onNavigate: (path) => editedPath = path,
              onRefresh: () {},
              onNavigateUp: () {},
              onNavigateHome: () {},
            ),
          ),
        ),
      );

      // Tap edit icon to switch to manual text entry
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);

      // Enter new path and press enter
      await tester.enterText(find.byType(TextField), '/var/www');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(editedPath, equals('/var/www'));
    });
  });

  group('SFTP Drag & Drop Payload Tests', () {
    test('Local and Remote payloads instantiate correctly', () {
      const local = SftpLocalDragPayload(['/tmp/file1.txt', '/tmp/file2.txt']);
      expect(local.paths.length, equals(2));
      expect(local.paths.first, equals('/tmp/file1.txt'));

      const remote = SftpRemoteDragPayload(['/root/cfg.json']);
      expect(remote.paths.length, equals(1));
      expect(remote.paths.first, equals('/root/cfg.json'));
    });
  });

  group('SFTP File Editor Dialog Tests', () {
    testWidgets('Loads remote file content and allows editing and saving',
        (tester) async {
      final mockSession = MockSftpSession();
      mockSession.files['/etc/nginx/nginx.conf'] =
          Uint8List.fromList(utf8.encode('server {\n  listen 80;\n}'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => SftpFileEditorDialog(
                      fileName: 'nginx.conf',
                      path: '/etc/nginx/nginx.conf',
                      isRemote: true,
                      session: mockSession,
                    ),
                  );
                },
                child: const Text('Open Editor'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Editor'));
      await tester.pumpAndSettle();

      // Verify file title and line numbers
      expect(find.textContaining('nginx.conf'), findsWidgets);
      expect(find.text('1'), findsWidgets);
      expect(find.text('2'), findsWidgets);

      // Save file
      await tester.tap(find.textContaining('Save'));
      await tester.pumpAndSettle();

      // Check that mock session received the file data
      expect(mockSession.files['/etc/nginx/nginx.conf'], isNotNull);
      final savedText =
          utf8.decode(mockSession.files['/etc/nginx/nginx.conf']!);
      expect(savedText, contains('listen 80;'));
    });
  });

  group('TransferQueueBar Cancellation Tests', () {
    testWidgets('Renders Cancel All button and emits onCancelAll callback',
        (tester) async {
      bool cancelAllCalled = false;

      final transfers = [
        const FileTransferItem(
          id: 't-1',
          fileName: 'big_archive.zip',
          sourcePath: '/tmp/big.zip',
          destinationPath: '/remote/big.zip',
          direction: TransferDirection.upload,
          progress: 0.35,
          status: TransferStatus.inProgress,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransferQueueBar(
              transfers: transfers,
              onCancelAll: () => cancelAllCalled = true,
            ),
          ),
        ),
      );

      // Verify Cancel All button exists and tap it
      expect(find.text('Cancel All'), findsOneWidget);
      await tester.tap(find.text('Cancel All'));
      await tester.pumpAndSettle();
      expect(cancelAllCalled, isTrue);
    });

    testWidgets(
        'Emits onCancelTransfer callback when closing individual transfer',
        (tester) async {
      String? cancelledId;

      final transfers = [
        const FileTransferItem(
          id: 't-1',
          fileName: 'single_file.tar',
          sourcePath: '/tmp/single.tar',
          destinationPath: '/remote/single.tar',
          direction: TransferDirection.upload,
          progress: 0.10,
          status: TransferStatus.inProgress,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransferQueueBar(
              transfers: transfers,
              onCancelTransfer: (id) => cancelledId = id,
            ),
          ),
        ),
      );

      // Tap individual item cancel button
      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(cancelledId, equals('t-1'));
    });
  });
}
