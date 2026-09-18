import 'dart:io';
import 'package:core_foundation/core_foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shellit/src/di/app_providers.dart';
import 'package:terminal_ui/terminal_ui.dart';

void main() {
  late Directory tempDir;
  late File testDbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'shellit_persistence_test_',
    );
    testDbFile = File('${tempDir.path}/test_vault.db');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'Host added to hostsProvider persists to database file across restarts',
    () async {
      final testHost = HostEntity(
        id: 'host-persistence-01',
        label: 'Persistent Prod Server',
        hostname: 'prod.example.com',
        port: 22,
        username: 'root',
        authType: HostAuthType.password,
        environment: HostEnvironment.production,
        osType: OsType.ubuntu,
        tags: const ['prod', 'web'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 1. First session: open DB and add host
      {
        final container1 = ProviderContainer(
          overrides: [
            vaultDatabaseFileProvider.overrideWithValue(testDbFile),
            vaultRepositoryProvider.overrideWith(
              (ref) => ref.watch(appVaultRepositoryProvider),
            ),
            hostRepositoryProvider.overrideWith(
              (ref) => ref.watch(appHostRepositoryProvider),
            ),
          ],
        );

        // Trigger initialization
        container1.read(vaultProvider.notifier);
        final hostsNotifier = container1.read(hostsProvider.notifier);

        // Wait a tick for async _init
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final saveResult = await hostsNotifier.addHost(testHost);
        expect(saveResult.isSuccess, isTrue);

        final currentHosts = container1.read(hostsProvider);
        expect(currentHosts.any((h) => h.id == testHost.id), isTrue);

        // Dispose container to flush and close DB connection
        container1.dispose();
      }

      expect(await testDbFile.exists(), isTrue);

      // 2. Second session (Simulate restart): open same DB file and verify host is loaded
      {
        final container2 = ProviderContainer(
          overrides: [
            vaultDatabaseFileProvider.overrideWithValue(testDbFile),
            vaultRepositoryProvider.overrideWith(
              (ref) => ref.watch(appVaultRepositoryProvider),
            ),
            hostRepositoryProvider.overrideWith(
              (ref) => ref.watch(appHostRepositoryProvider),
            ),
          ],
        );

        container2.read(hostsProvider.notifier);
        // Wait for async _loadHosts()
        await Future<void>.delayed(const Duration(milliseconds: 100));

        final loadedHosts = container2.read(hostsProvider);
        expect(loadedHosts.any((h) => h.id == testHost.id), isTrue);

        final loadedHost = loadedHosts.firstWhere((h) => h.id == testHost.id);
        expect(loadedHost.label, 'Persistent Prod Server');
        expect(loadedHost.hostname, 'prod.example.com');
        expect(loadedHost.environment, HostEnvironment.production);

        container2.dispose();
      }
    },
  );
}
