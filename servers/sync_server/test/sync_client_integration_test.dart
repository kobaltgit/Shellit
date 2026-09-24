import 'dart:convert';
import 'package:core_foundation/core_foundation.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shellit_sync_server/sync_server.dart';
import 'package:storage_vault/storage_vault.dart';
import 'package:test/test.dart';

void main() {
  group('E2EE Sync Client <-> Server Integration', () {
    late SyncDatabase serverDb;
    late WsHub wsHub;
    late SyncApi api;
    late dynamic server;
    late String serverUrl;

    setUp(() async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      serverDb = SyncDatabase.inMemory();
      wsHub = WsHub();
      api = SyncApi(
        db: serverDb,
        wsHub: wsHub,
        registrationToken: 'my-token',
      );
      server = await io.serve(api.handler, '127.0.0.1', 0);
      serverUrl = 'http://${server.address.host}:${server.port}';
    });

    tearDown(() async {
      await server.close(force: true);
      serverDb.close();
    });

    test(
        'Full bidirectional sync: Laptop creates host -> Server -> Phone receives -> Phone edits -> Laptop updates',
        () async {
      final cryptoService = VaultCryptoService(
        argon2Memory: 1024,
        argon2Iterations: 2,
        argon2Parallelism: 1,
        argon2HashLength: 32,
      );

      // 1. Setup Laptop DB & Repositories (Master Password: LaptopPassword123)
      final laptopDb = VaultDatabaseConnection.inMemory();
      final laptopSecurity = VaultSecurityContext();
      final laptopVaultRepo = VaultRepository(
        db: laptopDb,
        cryptoService: cryptoService,
        securityContext: laptopSecurity,
      );
      await laptopVaultRepo.initializeVault('LaptopPassword123');
      final laptopHostRepo =
          HostRepository(db: laptopDb, securityContext: laptopSecurity);
      final laptopSnippetRepo =
          SnippetRepository(db: laptopDb, securityContext: laptopSecurity);
      final laptopKeyManager = KeyManager(
        db: laptopDb,
        cryptoService: cryptoService,
        securityContext: laptopSecurity,
      );
      final laptopSyncManager = SyncManager(
        db: laptopDb,
        syncCrypto: SyncCrypto(cryptoService: cryptoService),
        cryptoService: cryptoService,
        securityContext: laptopSecurity,
      );

      // 2. Setup Phone DB & Repositories (Different Master Password: PhonePassword456)
      final phoneDb = VaultDatabaseConnection.inMemory();
      final phoneSecurity = VaultSecurityContext();
      final phoneVaultRepo = VaultRepository(
        db: phoneDb,
        cryptoService: cryptoService,
        securityContext: phoneSecurity,
      );
      await phoneVaultRepo.initializeVault('PhonePassword456');
      final phoneHostRepo =
          HostRepository(db: phoneDb, securityContext: phoneSecurity);
      final phoneSnippetRepo =
          SnippetRepository(db: phoneDb, securityContext: phoneSecurity);
      final phoneKeyManager = KeyManager(
        db: phoneDb,
        cryptoService: cryptoService,
        securityContext: phoneSecurity,
      );
      final phoneSyncManager = SyncManager(
        db: phoneDb,
        syncCrypto: SyncCrypto(cryptoService: cryptoService),
        cryptoService: cryptoService,
        securityContext: phoneSecurity,
      );

      const vaultId = 'team-vault-1';
      const syncPassphrase = 'e2ee-shared-secret-passphrase';

      // 3. Laptop creates a host, snippet, and SSH key
      final now = DateTime.now();
      await laptopHostRepo.saveHost(HostEntity(
        id: 'host-k8s-prod',
        label: 'Production Cluster',
        hostname: 'k8s.company.internal',
        port: 6443,
        username: 'admin',
        authType: HostAuthType.password,
        createdAt: now,
        updatedAt: now,
      ));

      await laptopSnippetRepo.saveSnippet(SnippetEntity(
        id: 'snip-get-pods',
        title: 'Get Pods',
        command: 'kubectl get pods -A',
        createdAt: now,
        updatedAt: now,
      ));

      await laptopKeyManager.encryptAndSaveKey(
        id: 'key-test-1',
        label: 'Prod Key',
        keyType: KeyType.ed25519,
        rawPrivateKey: utf8.encode('super_secret_ssh_private_key_bytes'),
        publicKey: 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI...',
        rawPassphrase: 'key_passphrase_secret',
      );

      // 4. Laptop runs sync
      final laptopSync1 = await laptopSyncManager.synchronize(
        serverUrl: serverUrl,
        vaultId: vaultId,
        passphrase: syncPassphrase,
        registrationToken: 'my-token',
      );
      expect(laptopSync1.isSuccess, isTrue);
      expect(laptopSync1.valueOrNull!.pushedCount, equals(3));

      // Verify server data is encrypted (zero knowledge)
      final rawItems =
          serverDb.getItemsSince(vaultId: vaultId, sinceRevision: 0);
      expect(rawItems.length, equals(3));
      for (final item in rawItems) {
        // Must NOT contain plaintext
        expect(item['encryptedBlob'], isNot(contains('Production Cluster')));
        expect(item['encryptedBlob'], isNot(contains('kubectl get pods')));
        expect(item['encryptedBlob'],
            isNot(contains('super_secret_ssh_private_key_bytes')));
      }

      // 5. Phone syncs from server
      final phoneSync1 = await phoneSyncManager.synchronize(
        serverUrl: serverUrl,
        vaultId: vaultId,
        passphrase: syncPassphrase,
        registrationToken: 'my-token',
      );
      expect(phoneSync1.isSuccess, isTrue);
      expect(phoneSync1.valueOrNull!.pulledCount, equals(3));

      // Verify Phone now has the decrypted host and snippet
      final phoneHosts = await phoneHostRepo.getAllHosts();
      expect(phoneHosts.length, equals(1));
      expect(phoneHosts.first.id, equals('host-k8s-prod'));
      expect(phoneHosts.first.label, equals('Production Cluster'));
      expect(phoneHosts.first.port, equals(6443));

      // Verify Phone can decrypt the SSH key using its OWN master key!
      final phonePrivRes =
          await phoneKeyManager.getDecryptedPrivateKey('key-test-1');
      expect(phonePrivRes.isSuccess, isTrue);
      expect(utf8.decode(phonePrivRes.valueOrNull!),
          equals('super_secret_ssh_private_key_bytes'));

      final phonePassRes =
          await phoneKeyManager.getDecryptedPassphrase('key-test-1');
      expect(phonePassRes.isSuccess, isTrue);
      expect(phonePassRes.valueOrNull, equals('key_passphrase_secret'));

      final phoneSnippets = await phoneSnippetRepo.getAllSnippets();
      expect(phoneSnippets.length, equals(1));
      expect(phoneSnippets.first.command, equals('kubectl get pods -A'));

      // 6. Phone modifies host (changes port to 9443) and deletes the snippet
      final later = now.add(const Duration(seconds: 10));
      await phoneHostRepo.saveHost(phoneHosts.first.copyWith(
        port: 9443,
        label: 'Production Cluster Updated',
        updatedAt: later,
      ));
      await phoneSnippetRepo.deleteSnippet('snip-get-pods');

      // 7. Phone pushes changes
      final phoneSync2 = await phoneSyncManager.synchronize(
        serverUrl: serverUrl,
        vaultId: vaultId,
        passphrase: syncPassphrase,
      );
      expect(phoneSync2.isSuccess, isTrue);

      // 8. Laptop syncs again to pull Phone's changes
      final laptopSync2 = await laptopSyncManager.synchronize(
        serverUrl: serverUrl,
        vaultId: vaultId,
        passphrase: syncPassphrase,
      );
      expect(laptopSync2.isSuccess, isTrue);

      // 9. Verify Laptop's host is updated and snippet is deleted
      final laptopUpdatedHost =
          await laptopHostRepo.getHostById('host-k8s-prod');
      expect(laptopUpdatedHost, isNotNull);
      expect(laptopUpdatedHost!.port, equals(9443));
      expect(laptopUpdatedHost.label, equals('Production Cluster Updated'));

      final laptopSnippets = await laptopSnippetRepo.getAllSnippets();
      expect(laptopSnippets.isEmpty, isTrue);

      // Cleanup
      await laptopDb.close();
      await phoneDb.close();
    });
  });
}
