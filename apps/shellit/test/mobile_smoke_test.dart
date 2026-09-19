import 'dart:async';
import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shellit/src/di/app_providers.dart';
import 'package:shellit/src/screens/keychain/keychain_screen.dart';
import 'package:shellit/src/screens/settings/settings_screen.dart';
import 'package:shellit/src/shellit_app.dart';
import 'package:storage_vault/storage_vault.dart';
import 'package:terminal_ui/terminal_ui.dart';

class _FakeMobileSshClientService implements ISshClientService {
  @override
  Future<Result<int, NetworkFailure>> pingHost(
    String hostname,
    int port, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    return const Result.success(30);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMobileTerminalSession implements ITerminalSession {
  final _outputController = StreamController<Uint8List>.broadcast();

  @override
  String get id => 'mobile_fake_term';
  @override
  String get hostId => 'h-mobile-1';
  @override
  SessionState get currentState => SessionState.ready;
  @override
  Stream<SessionState> get stateStream => Stream.value(SessionState.ready);
  @override
  Stream<Uint8List> get outputStream => _outputController.stream;
  @override
  Sink<Uint8List> get inputStream => StreamController<Uint8List>().sink;
  @override
  void resize(TerminalDimensions dimensions) {}
  @override
  Future<void> terminate() async {
    await _outputController.close();
  }
  @override
  ISessionRecorder? recorder;
  @override
  dynamic get underlyingClient => null;
}

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  testWidgets(
    'Mobile Shell Smoke Test: Renders MobileAppShell, 3-tab navigation, no plugins/snippets/tunnels',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer(
          overrides: [
            vaultRepositoryProvider.overrideWith(
              (ref) => ref.watch(appVaultRepositoryProvider),
            ),
            hostRepositoryProvider.overrideWith(
              (ref) => ref.watch(appHostRepositoryProvider),
            ),
            sshClientServiceProvider.overrideWithValue(
              _FakeMobileSshClientService(),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const ShellitApp(),
          ),
        );
        await tester.pumpAndSettle();

        // 1. MobileAppShell is rendered, NOT NavigationSidebar or TopBarTabs
        expect(find.byType(MobileAppShell), findsOneWidget);
        expect(find.byType(NavigationSidebar), findsNothing);
        expect(find.byType(TopBarTabs), findsNothing);

        // 2. NavigationBar is present with exactly 3 destinations (Hosts, Keychain, Settings)
        final navBar = find.byType(NavigationBar);
        expect(navBar, findsOneWidget);

        final destinations = find.byType(NavigationDestination);
        expect(destinations, findsNWidgets(3));

        // 3. Verify labels: Hosts, Keychain, Settings exist; Desktop items do NOT exist
        expect(find.text('Hosts'), findsWidgets);
        expect(find.text('Keychain'), findsWidgets);
        expect(find.text('Settings'), findsWidgets);

        expect(find.text('Plugins'), findsNothing);
        expect(find.text('Snippets'), findsNothing);
        expect(find.text('Port Tunnels'), findsNothing);
        expect(find.text('SFTP'), findsNothing);

        // 4. MobileHostsView is shown in initial state
        expect(find.byType(MobileHostsView), findsOneWidget);

        // 5. Switch to Keychain tab
        await tester.tap(find.text('Keychain'));
        await tester.pumpAndSettle();
        expect(find.byType(KeychainScreen), findsOneWidget);
        expect(find.widgetWithText(AppBar, 'Keychain'), findsOneWidget);

        // 6. Switch to Settings tab
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();
        expect(find.byType(SettingsScreen), findsOneWidget);
        expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
        // Ensure language selector is hidden on mobile
        expect(find.text('Language & Translation'), findsNothing);
        // Ensure logs & diagnostics is hidden on mobile
        expect(find.text('Logs & Diagnostics'), findsNothing);

        // 7. Switch back to Hosts tab
        await tester.tap(find.text('Hosts'));
        await tester.pumpAndSettle();
        expect(find.byType(MobileHostsView), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'Mobile Terminal Session: connects to host and opens full-screen MobileTerminalScreen',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer(
          overrides: [
            vaultRepositoryProvider.overrideWith(
              (ref) => ref.watch(appVaultRepositoryProvider),
            ),
            hostRepositoryProvider.overrideWith(
              (ref) => ref.watch(appHostRepositoryProvider),
            ),
            sshClientServiceProvider.overrideWithValue(
              _FakeMobileSshClientService(),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const ShellitApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Open a fake mobile terminal session
        final now = DateTime.now();
        final mobileHost = HostEntity(
          id: 'h-mobile-1',
          label: 'Mobile Production Server',
          hostname: 'mobile.prod.server',
          port: 22,
          username: 'ubuntu',
          authType: HostAuthType.password,
          environment: HostEnvironment.production,
          createdAt: now,
          updatedAt: now,
        );

        container
            .read(sessionManagerProvider.notifier)
            .openTerminalTab(host: mobileHost, session: _FakeMobileTerminalSession());
        await tester.pumpAndSettle();

        // Verify MobileTerminalScreen is rendered
        expect(find.byType(MobileTerminalScreen), findsOneWidget);
        expect(find.text('Mobile Production Server'), findsOneWidget);
        expect(find.text('PROD'), findsOneWidget);

        // Verify MobileAccessoryBar is present
        expect(find.byType(MobileAccessoryBar), findsOneWidget);
        expect(find.text('PASTE'), findsOneWidget);
        expect(find.byTooltip('Hide Keyboard'), findsOneWidget);

        // Verify disconnect button
        expect(find.byTooltip('Disconnect'), findsOneWidget);
        await tester.tap(find.byTooltip('Disconnect'));
        await tester.pumpAndSettle();

        // Confirmation dialog should appear
        expect(find.text('Disconnect from Mobile Production Server?'), findsOneWidget);
        await tester.tap(find.text('Disconnect'));
        await tester.pumpAndSettle();

        // Session closed -> back to MobileHostsView
        expect(find.byType(MobileTerminalScreen), findsNothing);
        expect(find.byType(MobileHostsView), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}
