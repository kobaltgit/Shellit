import 'dart:async';
import 'dart:typed_data';
import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:storage_vault/storage_vault.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shellit/src/di/app_providers.dart';
import 'package:shellit/src/shellit_app.dart';
import 'package:terminal_ui/terminal_ui.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  testWidgets(
    'ShellitApp smoke test: boots, builds AppShell and navigation sidebar',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vaultRepositoryProvider.overrideWith(
              (ref) => ref.watch(appVaultRepositoryProvider),
            ),
            hostRepositoryProvider.overrideWith(
              (ref) => ref.watch(appHostRepositoryProvider),
            ),
          ],
          child: const ShellitApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify App Shell components are present
      expect(find.byType(ShellitAppShell), findsOneWidget);
      expect(find.byType(NavigationSidebar), findsOneWidget);
      expect(find.byType(TopBarTabs), findsOneWidget);

      // Initial view should be Host Catalog
      expect(find.byType(HostViewsSwitcher), findsOneWidget);
    },
  );

  testWidgets('ShellitApp switches to Keychain and Settings screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vaultRepositoryProvider.overrideWith(
            (ref) => ref.watch(appVaultRepositoryProvider),
          ),
          hostRepositoryProvider.overrideWith(
            (ref) => ref.watch(appHostRepositoryProvider),
          ),
        ],
        child: const ShellitApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on Keychain entry in sidebar
    final keychainText = find.text('Keychain');
    expect(keychainText, findsOneWidget);
    await tester.tap(keychainText);
    await tester.pumpAndSettle();

    // Verify Keychain screen header
    expect(find.text('SSH Keychain & Certificates'), findsOneWidget);

    // Tap on Settings entry in sidebar
    final settingsText = find.text('Settings');
    expect(settingsText, findsOneWidget);
    await tester.tap(settingsText);
    await tester.pumpAndSettle();

    // Verify Settings screen header
    expect(find.text('Settings & Security'), findsOneWidget);
    expect(find.text('Auto-Lock Timeout'), findsOneWidget);
    expect(find.text('Export Encrypted Vault Backup'), findsOneWidget);

    // Tap on Snippets entry in sidebar
    final snippetsText = find.text('Snippets');
    expect(snippetsText, findsOneWidget);
    await tester.tap(snippetsText);
    await tester.pumpAndSettle();

    // Verify Snippets screen header
    expect(find.text('Command Snippets Library'), findsOneWidget);
  });

  testWidgets(
    'ShellitApp preserves open session tabs and allows navigating back to Hosts and other sections',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
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

      // Verify initial state has Pinned Hosts tab and + button
      expect(find.text('Hosts'), findsWidgets);
      expect(find.byTooltip('New Tab (Open Hosts Catalog)'), findsOneWidget);

      // Simulate opening a terminal tab
      final now = DateTime.now();
      final hostA = HostEntity(
        id: 'h-alpha',
        label: 'Alpha Node',
        hostname: 'alpha.local',
        port: 22,
        username: 'root',
        authType: HostAuthType.password,
        createdAt: now,
        updatedAt: now,
      );

      // Add session tab via provider
      final tabId = container
          .read(sessionManagerProvider.notifier)
          .openTerminalTab(host: hostA, session: _SimpleFakeTerminalSession());
      await tester.pumpAndSettle();

      // Tab "Alpha Node" should be visible in TopBarTabs
      expect(find.text('Alpha Node'), findsOneWidget);
      // TerminalScreen should be rendered in the workspace
      expect(find.byType(TerminalScreen), findsOneWidget);

      // Tap on Pinned "Hosts" in TopBarTabs to view catalog without closing tab
      final hostsTabs = find.text('Hosts');
      // First one is in the TopBarTabs pinned tab or Sidebar
      await tester.tap(hostsTabs.first);
      await tester.pumpAndSettle();

      // Hosts catalog is now active in IndexedStack
      expect(container.read(sessionManagerProvider).isCatalogActive, true);
      // Tab "Alpha Node" is STILL in the tab bar!
      expect(find.text('Alpha Node'), findsOneWidget);

      // Tap on "Alpha Node" tab in TopBarTabs -> switches back to terminal!
      await tester.tap(find.text('Alpha Node'));
      await tester.pumpAndSettle();
      expect(container.read(sessionManagerProvider).activeTabId, tabId);

      // Tap on "Keychain" in NavigationSidebar -> switches to Keychain without closing tab
      await tester.tap(find.text('Keychain'));
      await tester.pumpAndSettle();
      expect(find.text('SSH Keychain & Certificates'), findsOneWidget);
      expect(find.text('Alpha Node'), findsOneWidget); // Tab still alive!

      // Tap "+" button in TopBarTabs -> switches to Hosts catalog
      await tester.tap(find.byTooltip('New Tab (Open Hosts Catalog)'));
      await tester.pumpAndSettle();
      expect(container.read(sessionManagerProvider).isCatalogActive, true);
    },
  );
}

class _SimpleFakeTerminalSession implements ITerminalSession {
  @override
  String get id => 'simple_fake_term';
  @override
  String get hostId => 'h-alpha';
  @override
  SessionState get currentState => SessionState.ready;
  @override
  Stream<SessionState> get stateStream => Stream.value(SessionState.ready);
  @override
  Stream<Uint8List> get outputStream => const Stream.empty();
  @override
  Sink<Uint8List> get inputStream => StreamController<Uint8List>().sink;
  @override
  void resize(TerminalDimensions dimensions) {}
  @override
  Future<void> terminate() async {}
  @override
  dynamic get underlyingClient => null;
}
