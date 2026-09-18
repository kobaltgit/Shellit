import 'package:core_foundation/core_foundation.dart';
import 'package:storage_vault/storage_vault.dart';
import 'package:test/test.dart';

void main() {
  late VaultDatabase db;
  late VaultCryptoService cryptoService;
  late VaultBackupService backupService;
  late VaultSecurityContext securityContext;
  late HostRepository hostRepo;
  late SnippetRepository snippetRepo;

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() async {
    db = VaultDatabaseConnection.inMemory();
    cryptoService = VaultCryptoService();
    securityContext = VaultSecurityContext();
    backupService = VaultBackupService(db: db, cryptoService: cryptoService);
    hostRepo = HostRepository(db: db, securityContext: securityContext);
    snippetRepo = SnippetRepository(db: db, securityContext: securityContext);

    final salt = cryptoService.generateRandomBytes(16);
    final key =
        await cryptoService.deriveMasterKey(password: "master123", salt: salt);
    securityContext.unlock(key);
  });

  tearDown(() async {
    await db.close();
  });

  test('Exports and imports encrypted vault backup successfully', () async {
    // 1. Populate some data
    final host = HostEntity(
      id: 'host-100',
      label: 'Production DB',
      hostname: '10.0.0.5',
      port: 2222,
      username: 'dbadmin',
      authType: HostAuthType.password,
      environment: HostEnvironment.production,
      tags: const ['db', 'postgres'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await hostRepo.saveHost(host);

    final snippet = SnippetEntity(
      id: 'snip-100',
      title: 'Docker Logs',
      command: 'docker logs -f app',
      tags: const ['docker'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await snippetRepo.saveSnippet(snippet);

    // 2. Export backup
    final exportRes =
        await backupService.exportEncryptedBackup('backup-pass-789');
    expect(exportRes.isSuccess, isTrue);
    final backupBytes = exportRes.valueOrNull!;
    expect(backupBytes.length, greaterThan(50));

    // 3. Clear database
    await db.delete(db.hostsTable).go();
    await db.delete(db.snippetsTable).go();
    expect((await hostRepo.getAllHosts()).isEmpty, isTrue);
    expect((await snippetRepo.getAllSnippets()).isEmpty, isTrue);

    // 4. Attempt import with wrong password -> fails
    final wrongPassRes = await backupService.importEncryptedBackup(
      backupBytes: backupBytes,
      backupPassword: 'wrong-password',
    );
    expect(wrongPassRes.isError, isTrue);

    // 5. Restore with correct password -> succeeds
    final restoreRes = await backupService.importEncryptedBackup(
      backupBytes: backupBytes,
      backupPassword: 'backup-pass-789',
    );
    expect(restoreRes.isSuccess, isTrue);
    expect(restoreRes.valueOrNull, equals(2)); // 1 host + 1 snippet

    // 6. Verify restored data
    final restoredHosts = await hostRepo.getAllHosts();
    expect(restoredHosts.length, equals(1));
    expect(restoredHosts.first.label, equals('Production DB'));
    expect(restoredHosts.first.port, equals(2222));

    final restoredSnippets = await snippetRepo.getAllSnippets();
    expect(restoredSnippets.length, equals(1));
    expect(restoredSnippets.first.title, equals('Docker Logs'));
  });
}
