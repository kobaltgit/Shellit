import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core_foundation/core_foundation.dart';
import 'package:terminal_ui/terminal_ui.dart';
import 'test_helpers.dart';

void main() {
  group('TerminalConnectingView Widget Tests', () {
    final testHost = HostEntity(
      id: 'test-host-1',
      label: 'Production Web 01',
      hostname: '192.168.1.100',
      port: 22,
      username: 'deploy',
      authType: HostAuthType.password,
      environment: HostEnvironment.production,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    testWidgets(
        'renders connecting state with spinner, host details, PROD badge and cancel button',
        (tester) async {
      bool cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ShellitTheme.obsidianDarkTheme,
          home: Scaffold(
            body: TerminalConnectingView(
              host: testHost,
              statusMessage: 'Authenticating as deploy...',
              isConnecting: true,
              onCancel: () => cancelCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('Production Web 01'), findsOneWidget);
      expect(find.text('deploy@192.168.1.100:22'), findsOneWidget);
      expect(find.text('PROD'), findsOneWidget);
      expect(find.text('Authenticating as deploy...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Cancel Connection'), findsOneWidget);

      await tester.tap(find.text('Cancel Connection'));
      await tester.pump();

      expect(cancelCalled, isTrue);
    });

    testWidgets(
        'renders error state with error message, retry, and close buttons',
        (tester) async {
      bool retryCalled = false;
      bool closeCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ShellitTheme.obsidianDarkTheme,
          home: Scaffold(
            body: TerminalConnectingView(
              host: testHost,
              errorMessage: 'Connection refused: port 22 unreachable',
              isConnecting: false,
              onRetry: () => retryCalled = true,
              onClose: () => closeCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('Connection Failed'), findsOneWidget);
      expect(
          find.text('Connection refused: port 22 unreachable'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Close Tab'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(retryCalled, isTrue);

      await tester.tap(find.text('Close Tab'));
      await tester.pump();
      expect(closeCalled, isTrue);
    });

    testWidgets(
        'renders master password required UI when error relates to locked vault',
        (tester) async {
      bool unlockCalled = false;
      bool closeCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ShellitTheme.obsidianDarkTheme,
          home: Scaffold(
            body: TerminalConnectingView(
              host: testHost,
              errorMessage:
                  'Vault is locked. Master password required to decrypt host credentials.',
              isConnecting: false,
              onUnlockVault: () => unlockCalled = true,
              onClose: () => closeCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('Master Password Required'), findsOneWidget);
      expect(
        find.text(
            'Credentials for this host (password or key) are encrypted in the vault. Enter master password to connect.'),
        findsOneWidget,
      );
      expect(find.text('Unlock Vault'), findsOneWidget);
      expect(find.text('Close Tab'), findsOneWidget);

      await tester.tap(find.text('Unlock Vault'));
      await tester.pump();
      expect(unlockCalled, isTrue);

      await tester.tap(find.text('Close Tab'));
      await tester.pump();
      expect(closeCalled, isTrue);
    });
  });

  group('SessionManagerNotifier Connecting Lifecycle Tests', () {
    late SessionManagerNotifier notifier;

    final testHost = HostEntity(
      id: 'test-host-2',
      label: 'Staging Server',
      hostname: '10.0.0.5',
      port: 2222,
      username: 'root',
      authType: HostAuthType.password,
      environment: HostEnvironment.staging,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setUp(() {
      notifier = SessionManagerNotifier();
    });

    test('openConnectingTerminalTab creates connecting tab and sets active',
        () {
      final tabId = notifier.openConnectingTerminalTab(host: testHost);

      expect(notifier.state.tabs.length, 1);
      final tab = notifier.state.tabs.first;
      expect(tab.id, tabId);
      expect(tab.isConnecting, isTrue);
      expect(tab.connectionStatus, 'Connecting...');
      expect(notifier.state.activeTabId, tabId);
    });

    test('updateTabConnectingStatus updates connection step text', () {
      final tabId = notifier.openConnectingTerminalTab(host: testHost);

      notifier.updateTabConnectingStatus(tabId, 'Authenticating as root...');

      final tab = notifier.state.tabs.first;
      expect(tab.connectionStatus, 'Authenticating as root...');
      expect(tab.isConnecting, isTrue);
    });

    test(
        'attachTerminalSession transitions tab to connected state with session',
        () {
      final tabId = notifier.openConnectingTerminalTab(host: testHost);
      final fakeSession =
          FakeTerminalSession(id: 'sess-123', hostId: testHost.id);

      notifier.attachTerminalSession(tabId: tabId, session: fakeSession);

      final tab = notifier.state.tabs.first;
      expect(tab.isConnecting, isFalse);
      expect(tab.connectionStatus, isNull);
      expect(tab.terminalSession, equals(fakeSession));
      expect(tab.splitSessions, contains(fakeSession));
    });

    test(
        'setTabConnectionError and setTabConnecting handle failure and retry cycle',
        () {
      final tabId = notifier.openConnectingTerminalTab(host: testHost);

      notifier.setTabConnectionError(
        tabId: tabId,
        errorMessage: 'Network timeout during handshake',
      );

      var tab = notifier.state.tabs.first;
      expect(tab.isConnecting, isFalse);
      expect(tab.connectionError, 'Network timeout during handshake');

      // Retry
      notifier.setTabConnecting(
          tabId: tabId, initialStatus: 'Retrying connection...');
      tab = notifier.state.tabs.first;
      expect(tab.isConnecting, isTrue);
      expect(tab.connectionStatus, 'Retrying connection...');
      expect(tab.connectionError, isNull);
    });

    test(
        'openConnectingSftpTab and attachSftpSession manage SFTP connecting lifecycle',
        () {
      final tabId = notifier.openConnectingSftpTab(host: testHost);

      expect(notifier.state.tabs.length, 1);
      var tab = notifier.state.tabs.first;
      expect(tab.type, TabType.sftp);
      expect(tab.isConnecting, isTrue);
      expect(tab.connectionStatus, 'Opening SFTP...');

      final fakeSftp = FakeSftpSession(id: 'sftp-123', hostId: testHost.id);
      notifier.attachSftpSession(tabId: tabId, session: fakeSftp);

      tab = notifier.state.tabs.first;
      expect(tab.isConnecting, isFalse);
      expect(tab.sftpSession, equals(fakeSftp));
    });
  });
}
