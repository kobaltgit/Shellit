import 'package:core_foundation/core_foundation.dart';
import 'package:drift/native.dart';
import 'package:storage_vault/storage_vault.dart';
import 'package:test/test.dart';

void main() {
  late VaultDatabase db;
  late VaultCryptoService crypto;
  late VaultSecurityContext security;
  late VaultRepository repo;

  setUp(() async {
    db = VaultDatabase(NativeDatabase.memory());
    crypto = VaultCryptoService();
    security = VaultSecurityContext();

    repo = VaultRepository(
      db: db,
      cryptoService: crypto,
      securityContext: security,
    );

    // Initialize vault with a test password
    await repo.initializeVault('MasterPassword123!');
  });

  tearDown(() async {
    await db.close();
  });

  test('saves and retrieves Gemini API settings with encryption', () async {
    const originalSettings = VaultSettingsEntity(
      geminiApiKey: 'AIzaSyTestSecretKey987654321',
      geminiModelId: 'gemini-2.5-pro',
      isAiSnippetEnabled: true,
    );

    final saveResult = await repo.updateSettings(originalSettings);
    expect(saveResult.isSuccess, isTrue);

    // Create a second repository instance to ensure we read from database
    final repo2 = VaultRepository(
      db: db,
      cryptoService: crypto,
      securityContext: security,
    );

    final retrieved = await repo2.getSettings();
    expect(retrieved.geminiApiKey, equals('AIzaSyTestSecretKey987654321'));
    expect(retrieved.geminiModelId, equals('gemini-2.5-pro'));
    expect(retrieved.isAiSnippetEnabled, isTrue);

    // Direct DB check: ensure plaintext key is NOT stored in plain text column
    final rawRecord = await (db.select(db.vaultSettingsTable)
          ..where((t) => t.id.equals(1)))
        .getSingle();
    expect(rawRecord.geminiApiKey, isNull);
    expect(rawRecord.encryptedGeminiApiKey, isNotNull);
  });

  test(
      'saves and retrieves Gemini API settings when master password is not set (activeKey == null)',
      () async {
    // Uninitialized security context and repo without master password
    final uninitDb = VaultDatabase(NativeDatabase.memory());
    final uninitSecurity = VaultSecurityContext();
    final uninitRepo = VaultRepository(
      db: uninitDb,
      cryptoService: crypto,
      securityContext: uninitSecurity,
    );

    const settings = VaultSettingsEntity(
      geminiApiKey: 'AIzaSyPlainKey12345',
      geminiModelId: 'gemini-1.5-flash',
      isAiSnippetEnabled: true,
    );

    final saveResult = await uninitRepo.updateSettings(settings);
    expect(saveResult.isSuccess, isTrue);

    // Read with a new repository instance
    final uninitRepo2 = VaultRepository(
      db: uninitDb,
      cryptoService: crypto,
      securityContext: uninitSecurity,
    );

    final retrieved = await uninitRepo2.getSettings();
    expect(retrieved.geminiApiKey, equals('AIzaSyPlainKey12345'));
    expect(retrieved.geminiModelId, equals('gemini-1.5-flash'));
    expect(retrieved.isAiSnippetEnabled, isTrue);

    // Direct DB check: ensure plaintext column is populated and encrypted column is null
    final rawRecord = await (uninitDb.select(uninitDb.vaultSettingsTable)
          ..where((t) => t.id.equals(1)))
        .getSingle();
    expect(rawRecord.geminiApiKey, equals('AIzaSyPlainKey12345'));
    expect(rawRecord.encryptedGeminiApiKey, isNull);

    await uninitDb.close();
  });
}
