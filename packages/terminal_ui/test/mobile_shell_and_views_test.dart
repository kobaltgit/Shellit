import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';
import 'test_helpers.dart';

class FakeSshClientService implements ISshClientService {
  @override
  Future<Result<int, NetworkFailure>> pingHost(String hostname, int port,
      {Duration timeout = const Duration(seconds: 2)}) async {
    return const Result.success(25);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final now = DateTime.now();
  final testHost1 = HostEntity(
    id: 'host-1',
    label: 'Production Web 01',
    hostname: 'web.prod.net',
    port: 22,
    username: 'root',
    authType: HostAuthType.password,
    environment: HostEnvironment.production,
    osType: OsType.ubuntu,
    lastPingLatencyMs: 25,
    createdAt: now,
    updatedAt: now,
  );

  group('MobileHostsView widget tests', () {
    testWidgets('Renders single-column host cards and handles tap to connect',
        (tester) async {
      HostEntity? connectedHost;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ShellitTheme.obsidianDarkTheme,
            home: Scaffold(
              body: MobileHostsView(
                onConnect: (host) => connectedHost = host,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify host cards exist from default state
      expect(find.text('Production Web 01'), findsOneWidget);
      expect(find.text('PROD'), findsOneWidget);

      // Tap on first host to connect
      await tester.tap(find.text('Production Web 01'));
      await tester.pump();
      expect(connectedHost, isNotNull);
    });

    testWidgets('Long press on host card opens BottomSheet with options',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ShellitTheme.obsidianDarkTheme,
            home: Scaffold(
              body: MobileHostsView(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Long press card
      await tester.longPress(find.text('Production Web 01'));
      await tester.pumpAndSettle();

      // BottomSheet options
      expect(find.text('Connect Terminal'), findsOneWidget);
      expect(find.text('Edit Host'), findsOneWidget);
      expect(find.text('Duplicate Host'), findsOneWidget);
      expect(find.text('Delete Host'), findsOneWidget);

      // Ensure NO desktop SFTP or Split screen options
      expect(find.text('SFTP'), findsNothing);
      expect(find.text('Split'), findsNothing);
    });
  });

  group('MobileAppShell widget tests', () {
    testWidgets(
        'Renders 3-item NavigationBar, FAB (+), and switches between sections',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sshClientServiceProvider.overrideWithValue(FakeSshClientService()),
          ],
          child: MaterialApp(
            theme: ShellitTheme.obsidianDarkTheme,
            home: MobileAppShell(
              sectionBuilder: (context, section) {
                if (section == SidebarSection.keychain) {
                  return const Center(child: Text('Keychain View Mock'));
                }
                if (section == SidebarSection.settings) {
                  return const Center(child: Text('Settings View Mock'));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check Bottom Navigation items
      expect(find.text('Hosts'), findsOneWidget);
      expect(find.text('Keychain'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Verify no Plugins, SFTP, Snippets, Tunnels tabs
      expect(find.text('Plugins'), findsNothing);
      expect(find.text('Snippets'), findsNothing);
      expect(find.text('Port Forwarding'), findsNothing);

      // FAB is present on Hosts tab
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Switch to Keychain
      await tester.tap(find.text('Keychain'));
      await tester.pumpAndSettle();
      expect(find.text('Keychain View Mock'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);

      // Switch to Settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Settings View Mock'), findsOneWidget);
    });

    testWidgets('Quick connect button in AppBar opens BottomSheet',
        (tester) async {
      String? quickTarget;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sshClientServiceProvider.overrideWithValue(FakeSshClientService()),
          ],
          child: MaterialApp(
            theme: ShellitTheme.obsidianDarkTheme,
            home: MobileAppShell(
              onQuickConnectSubmit: (target) => quickTarget = target,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap bolt icon
      await tester.tap(find.byIcon(Icons.bolt));
      await tester.pumpAndSettle();

      expect(find.text('Quick Connect'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Enter target and submit
      await tester.enterText(find.byType(TextField).last, 'root@10.0.0.1:22');
      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();

      expect(quickTarget, 'root@10.0.0.1:22');
    });
  });

  group('MobileTerminalScreen widget tests', () {
    testWidgets(
        'Renders header with host info, back prompts disconnect confirmation',
        (tester) async {
      final mockSession = FakeTerminalSession(id: 'sess-1', hostId: 'host-1');
      bool disconnected = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ShellitTheme.obsidianDarkTheme,
            home: MobileTerminalScreen(
              session: mockSession,
              host: testHost1,
              onDisconnect: () => disconnected = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header info
      expect(find.text('Production Web 01'), findsOneWidget);
      expect(find.text('PROD'), findsOneWidget);
      expect(find.text('25ms'), findsOneWidget);

      // Check MobileAccessoryBar with PASTE and HIDE
      expect(find.text('PASTE'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_hide_outlined), findsOneWidget);

      // Tap back button -> dialog appears
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Disconnect from Production Web 01?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Disconnect'), findsOneWidget);

      // Tap disconnect
      await tester.tap(find.text('Disconnect'));
      await tester.pumpAndSettle();
      expect(disconnected, isTrue);
    });
  });
}
