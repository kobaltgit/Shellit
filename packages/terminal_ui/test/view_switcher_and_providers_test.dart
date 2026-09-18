import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';
import 'test_helpers.dart';

void main() {
  group('VaultProvider tests', () {
    test('Initial vault is unlocked and can be locked', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final vaultState = container.read(vaultProvider);
      expect(vaultState.isUnlocked, isTrue);
      expect(vaultState.activeVaultName, 'Primary Vault');

      container.read(vaultProvider.notifier).lock();
      expect(container.read(vaultProvider).isUnlocked, isFalse);

      container.read(vaultProvider.notifier).unlockWithPassword('master-pwd');
      expect(container.read(vaultProvider).isUnlocked, isTrue);

      container.read(vaultProvider.notifier).selectVault('Work Vault');
      expect(container.read(vaultProvider).activeVaultName, 'Work Vault');
    });

    test(
        'changeMasterPassword updates master password and rejects invalid current password',
        () async {
      final fakeRepo = FakeVaultRepository();
      final container = ProviderContainer(
        overrides: [
          vaultRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      // Attempt change with incorrect old password
      final failRes =
          await container.read(vaultProvider.notifier).changeMasterPassword(
                currentPassword: 'wrong-password',
                newPassword: 'new-secret-pwd',
              );
      expect(failRes.isError, isTrue);
      expect(failRes.failureOrNull?.type,
          equals(VaultFailureType.invalidPassword));
      expect(fakeRepo.currentMasterPassword, 'old-master-pwd');

      // Successful change
      final successRes =
          await container.read(vaultProvider.notifier).changeMasterPassword(
                currentPassword: 'old-master-pwd',
                newPassword: 'new-secret-pwd',
              );
      expect(successRes.isSuccess, isTrue);
      expect(fakeRepo.currentMasterPassword, 'new-secret-pwd');

      // Verify lock and unlock with new password
      container.read(vaultProvider.notifier).lock();
      expect(container.read(vaultProvider).isUnlocked, isFalse);

      final oldUnlock = await container
          .read(vaultProvider.notifier)
          .unlockWithPassword('old-master-pwd');
      expect(oldUnlock, isFalse);

      final newUnlock = await container
          .read(vaultProvider.notifier)
          .unlockWithPassword('new-secret-pwd');
      expect(newUnlock, isTrue);
      expect(container.read(vaultProvider).isUnlocked, isTrue);
    });
  });

  group('HostsProvider and Filtering tests', () {
    test('Can add, update, delete and filter hosts', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialHosts = container.read(hostsProvider);
      expect(initialHosts.isNotEmpty, isTrue);

      final now = DateTime.now();
      final newHost = HostEntity(
        id: 'new-host-99',
        label: 'Custom Cluster Worker',
        hostname: 'k8s-node.cluster.lan',
        port: 22,
        username: 'kube',
        authType: HostAuthType.privateKey,
        tags: const ['k8s', 'cluster'],
        createdAt: now,
        updatedAt: now,
      );

      await container.read(hostsProvider.notifier).addHost(newHost);
      expect(container.read(hostsProvider).any((h) => h.id == 'new-host-99'),
          isTrue);

      // Filter by search query
      container.read(hostFilterProvider.notifier).state =
          const HostFilterState(searchQuery: 'Custom Cluster');
      final filtered = container.read(filteredHostsProvider);
      expect(filtered.length, 1);
      expect(filtered.first.id, 'new-host-99');

      // Filter by tag
      container.read(hostFilterProvider.notifier).state =
          const HostFilterState(selectedTag: 'cluster');
      expect(container.read(filteredHostsProvider).length, 1);

      // Delete host
      await container.read(hostsProvider.notifier).deleteHost('new-host-99');
      expect(container.read(hostsProvider).any((h) => h.id == 'new-host-99'),
          isFalse);
    });
  });

  group('SessionManagerProvider tests', () {
    test('Tabs management: open, switch, close', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final now = DateTime.now();
      final host = HostEntity(
        id: 'h1',
        label: 'Server 1',
        hostname: '1.2.3.4',
        port: 22,
        username: 'root',
        authType: HostAuthType.password,
        createdAt: now,
        updatedAt: now,
      );
      final fakeSession1 = FakeTerminalSession(id: 's1', hostId: 'h1');
      final fakeSession2 = FakeTerminalSession(id: 's2', hostId: 'h1');

      final sessionNotifier = container.read(sessionManagerProvider.notifier);

      final tab1 =
          sessionNotifier.openTerminalTab(host: host, session: fakeSession1);
      expect(container.read(sessionManagerProvider).tabs.length, 1);
      expect(container.read(sessionManagerProvider).activeTabId, tab1);

      final tab2 =
          sessionNotifier.openTerminalTab(host: host, session: fakeSession2);
      expect(container.read(sessionManagerProvider).tabs.length, 2);
      expect(container.read(sessionManagerProvider).activeTabId, tab2);

      sessionNotifier.setActiveTab(tab1);
      expect(container.read(sessionManagerProvider).activeTabId, tab1);

      sessionNotifier.closeTab(tab1);
      expect(container.read(sessionManagerProvider).tabs.length, 1);
      expect(container.read(sessionManagerProvider).activeTabId, tab2);

      sessionNotifier.closeTab(tab2);
      expect(container.read(sessionManagerProvider).tabs.isEmpty, isTrue);
      expect(container.read(sessionManagerProvider).activeTabId, isNull);
    });
  });

  group('HostViewsSwitcher widget tests', () {
    testWidgets('Toggles between Grid, Dense List and Folder Tree modes',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ShellitTheme.obsidianDarkTheme,
            home: const Scaffold(
              body: HostViewsSwitcher(),
            ),
          ),
        ),
      );

      // Initially in Grid View
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(ListView), findsNothing);

      // Switch to Dense List View
      await tester.tap(find.byTooltip('Dense List View'));
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsNothing);
      expect(find.byType(ListView), findsOneWidget);

      // Switch to Folder Tree View
      await tester.tap(find.byTooltip('Folder Tree View'));
      await tester.pumpAndSettle();

      expect(find.byType(ExpansionTile), findsWidgets);
    });

    testWidgets('Searches hosts via search textfield', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ShellitTheme.obsidianDarkTheme,
            home: const Scaffold(
              body: HostViewsSwitcher(),
            ),
          ),
        ),
      );

      expect(find.text('Production Web 01'), findsOneWidget);

      // Enter search term
      await tester.enterText(find.byType(TextField).first, 'Sandbox');
      await tester.pumpAndSettle();

      expect(find.text('Dev Sandbox'), findsOneWidget);
      expect(find.text('Production Web 01'), findsNothing);
    });
  });

  group('MobileAccessoryBar widget tests', () {
    testWidgets('Emits key sequences for Esc, Tab, arrows, and Ctrl modifiers',
        (tester) async {
      final emittedKeys = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          theme: ShellitTheme.obsidianDarkTheme,
          home: Scaffold(
            body: MobileAccessoryBar(
              onKeyPress: (key) => emittedKeys.add(key),
            ),
          ),
        ),
      );

      // Tap ESC
      await tester.tap(find.text('ESC'));
      await tester.pump();
      expect(emittedKeys.last, '\x1b');

      // Tap TAB
      await tester.tap(find.text('TAB'));
      await tester.pump();
      expect(emittedKeys.last, '\t');

      // Tap Up Arrow
      await tester.tap(find.text('↑'));
      await tester.pump();
      expect(emittedKeys.last, '\x1b[A');

      // Tap Ctrl modifier then /
      await tester.tap(find.text('Ctrl'));
      await tester.pump();
      await tester.tap(find.text('/'));
      await tester.pump();
      expect(emittedKeys.last, '/');
    });
  });
}
