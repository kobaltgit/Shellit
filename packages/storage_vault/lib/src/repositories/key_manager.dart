import 'dart:convert';
import 'package:core_foundation/core_foundation.dart';
import 'package:drift/drift.dart';
import '../crypto/vault_crypto_service.dart';
import '../database/vault_database.dart';
import '../security/vault_security_context.dart';

/// Implementation of [IKeyManager] managing encrypted SSH key pairs and passphrases.
class KeyManager implements IKeyManager {
  final VaultDatabase _db;
  final VaultCryptoService _cryptoService;
  final VaultSecurityContext _securityContext;

  KeyManager({
    required VaultDatabase db,
    required VaultCryptoService cryptoService,
    required VaultSecurityContext securityContext,
  })  : _db = db,
        _cryptoService = cryptoService,
        _securityContext = securityContext;

  @override
  Future<List<KeyEntity>> getAllKeys() async {
    final query = _db.select(_db.keysTable)
      ..orderBy([(t) => OrderingTerm.asc(t.label)]);
    final records = await query.get();
    return records.map((r) => r.toEntity()).toList();
  }

  @override
  Stream<List<KeyEntity>> watchAllKeys() {
    final query = _db.select(_db.keysTable)
      ..orderBy([(t) => OrderingTerm.asc(t.label)]);
    return query
        .watch()
        .map((records) => records.map((r) => r.toEntity()).toList());
  }

  @override
  Future<KeyEntity?> getKeyById(String id) async {
    final query = _db.select(_db.keysTable)..where((t) => t.id.equals(id));
    final record = await query.getSingleOrNull();
    return record?.toEntity();
  }

  @override
  Future<Result<void, VaultFailure>> saveKey(KeyEntity key) async {
    if (!_securityContext.isUnlocked) {
      return Result.error(VaultFailure.locked());
    }

    try {
      await _db.into(_db.keysTable).insertOnConflictUpdate(
            KeysTableCompanion(
              id: Value(key.id),
              label: Value(key.label),
              keyType: Value(key.keyType.name),
              encryptedPrivateKey: Value(key.encryptedPrivateKey),
              publicKey: Value(key.publicKey),
              encryptedPassphrase: Value(key.encryptedPassphrase),
              fingerprint: Value(key.fingerprint),
              createdAt: Value(key.createdAt),
              updatedAt: Value(key.updatedAt),
            ),
          );
      try {
        await (_db.delete(_db.syncTombstonesTable)
              ..where((t) => t.entityId.equals(key.id)))
            .go();
      } catch (_) {
        // Non-critical: tombstone deletion error should not fail key saving
      }
      return const Result.success(null);
    } catch (e) {
      return Result.error(VaultFailure.corrupted(e));
    }
  }

  /// Convenience helper to encrypt raw private key & optional passphrase and save to database.
  Future<Result<KeyEntity, VaultFailure>> encryptAndSaveKey({
    required String id,
    required String label,
    required KeyType keyType,
    required List<int> rawPrivateKey,
    required String publicKey,
    String? rawPassphrase,
    String? fingerprint,
  }) async {
    if (!_securityContext.isUnlocked ||
        _securityContext.activeMasterKey == null) {
      return Result.error(VaultFailure.locked());
    }

    try {
      final masterKey = _securityContext.activeMasterKey!;
      final encryptedPrivKey = await _cryptoService.encryptBytes(
        clearText: rawPrivateKey,
        secretKey: masterKey,
      );

      Uint8List? encryptedPassphrase;
      if (rawPassphrase != null && rawPassphrase.isNotEmpty) {
        encryptedPassphrase = await _cryptoService.encryptBytes(
          clearText: utf8.encode(rawPassphrase),
          secretKey: masterKey,
        );
      }

      final now = DateTime.now();
      final entity = KeyEntity(
        id: id,
        label: label,
        keyType: keyType,
        encryptedPrivateKey: encryptedPrivKey,
        publicKey: publicKey,
        encryptedPassphrase: encryptedPassphrase,
        fingerprint: fingerprint,
        createdAt: now,
        updatedAt: now,
      );

      final saveResult = await saveKey(entity);
      if (saveResult.isError) {
        return Result.error(saveResult.failureOrNull!);
      }

      return Result.success(entity);
    } catch (e) {
      return Result.error(VaultFailure.corrupted(e));
    }
  }

  @override
  Future<Result<void, VaultFailure>> deleteKey(String id) async {
    if (!_securityContext.isUnlocked) {
      return Result.error(VaultFailure.locked());
    }

    try {
      await (_db.delete(_db.keysTable)..where((t) => t.id.equals(id))).go();
      try {
        await _db.into(_db.syncTombstonesTable).insertOnConflictUpdate(
              SyncTombstonesTableCompanion(
                entityId: Value(id),
                entityType: const Value('key'),
                deletedAt: Value(DateTime.now()),
              ),
            );
      } catch (_) {
        // Non-critical: tombstone insertion error should not fail key deletion
      }
      return const Result.success(null);
    } catch (e) {
      return Result.error(VaultFailure.corrupted(e));
    }
  }

  @override
  Future<Result<List<int>, VaultFailure>> getDecryptedPrivateKey(
      String keyId) async {
    if (!_securityContext.isUnlocked ||
        _securityContext.activeMasterKey == null) {
      return Result.error(VaultFailure.locked());
    }

    final key = await getKeyById(keyId);
    if (key == null) {
      return Result.error(
        VaultFailure(
          'SSH key with ID "$keyId" not found.',
          type: VaultFailureType.notFound,
        ),
      );
    }

    try {
      final decrypted = await _cryptoService.decryptBytes(
        encryptedData: key.encryptedPrivateKey,
        secretKey: _securityContext.activeMasterKey!,
      );
      return Result.success(decrypted);
    } catch (e) {
      return Result.error(
          VaultFailure.corrupted('Failed to decrypt private key: $e'));
    }
  }

  @override
  Future<Result<String?, VaultFailure>> getDecryptedPassphrase(
      String keyId) async {
    if (!_securityContext.isUnlocked ||
        _securityContext.activeMasterKey == null) {
      return Result.error(VaultFailure.locked());
    }

    final key = await getKeyById(keyId);
    if (key == null) {
      return Result.error(
        VaultFailure(
          'SSH key with ID "$keyId" not found.',
          type: VaultFailureType.notFound,
        ),
      );
    }

    if (key.encryptedPassphrase == null || key.encryptedPassphrase!.isEmpty) {
      return const Result.success(null);
    }

    try {
      final decryptedBytes = await _cryptoService.decryptBytes(
        encryptedData: key.encryptedPassphrase!,
        secretKey: _securityContext.activeMasterKey!,
      );
      final passphrase = utf8.decode(decryptedBytes);
      VaultCryptoService.zeroize(decryptedBytes);
      return Result.success(passphrase);
    } catch (e) {
      return Result.error(
          VaultFailure.corrupted('Failed to decrypt passphrase: $e'));
    }
  }

  @override
  Future<Result<void, VaultFailure>> savePasswordCredential({
    required String id,
    required String label,
    required String password,
  }) async {
    final res = await encryptAndSaveKey(
      id: id,
      label: label,
      keyType: KeyType.ed25519,
      rawPrivateKey: const [],
      publicKey: '',
      rawPassphrase: password,
    );
    return res.map((_) => null);
  }
}
