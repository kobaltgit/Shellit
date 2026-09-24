import 'dart:convert';
import 'package:core_foundation/core_foundation.dart';
import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import '../crypto/crypto_utils.dart';
import '../crypto/vault_crypto_service.dart';
import '../security/vault_security_context.dart';
import '../database/vault_database.dart';
import 'sync_client.dart';
import 'sync_crypto.dart';
import 'sync_models.dart';

/// Summary result of a synchronization cycle.
class SyncSummary {
  final int pushedCount;
  final int pulledCount;
  final int serverRevision;
  final DateTime timestamp;

  const SyncSummary({
    required this.pushedCount,
    required this.pulledCount,
    required this.serverRevision,
    required this.timestamp,
  });
}

/// Orchestrates full, bidirectional E2EE synchronization between local Drift database
/// and a self-hosted Shellit Sync Server.
class SyncManager {
  final VaultDatabase _db;
  final SyncCrypto _syncCrypto;
  final VaultCryptoService _cryptoService;
  final VaultSecurityContext _securityContext;

  SyncManager({
    required VaultDatabase db,
    SyncCrypto? syncCrypto,
    VaultCryptoService? cryptoService,
    VaultSecurityContext? securityContext,
  })  : _db = db,
        _syncCrypto = syncCrypto ?? SyncCrypto(),
        _cryptoService = cryptoService ?? VaultCryptoService(),
        _securityContext = securityContext ?? VaultSecurityContext();

  Future<SecretKey?> _getActiveOrOpenKey() async {
    if (_securityContext.isUnlocked &&
        _securityContext.activeMasterKey != null) {
      return _securityContext.activeMasterKey;
    }
    final initializedRecord = await (_db.select(_db.vaultMetadataTable)
          ..where((t) => t.metaKey.equals('is_initialized')))
        .getSingleOrNull();
    final isInitialized = initializedRecord?.metaValue == 'true';
    if (!isInitialized) {
      final record = await (_db.select(_db.vaultMetadataTable)
            ..where((t) => t.metaKey.equals('open_session_key')))
          .getSingleOrNull();
      if (record != null && record.metaValue.isNotEmpty) {
        return SecretKey(CryptoUtils.hexToBytes(record.metaValue));
      }
      final keyBytes = _cryptoService.generateRandomBytes(32);
      await _db.into(_db.vaultMetadataTable).insert(
            VaultMetadataTableCompanion.insert(
              metaKey: 'open_session_key',
              metaValue: CryptoUtils.bytesToHex(keyBytes),
            ),
            mode: InsertMode.insertOrReplace,
          );
      final openKey = SecretKey(keyBytes);
      _securityContext.unlock(openKey);
      return openKey;
    }
    return null;
  }

  /// Performs a complete synchronization roundtrip:
  /// 1. Derives E2EE sync key & auth hash.
  /// 2. Ensures remote vault initialization.
  /// 3. Exports & encrypts local changes (including tombstones).
  /// 4. Pushes changes to server.
  /// 5. Fetches remote changes since last known revision.
  /// 6. Decrypts and merges remote changes using Last-Write-Wins (LWW).
  /// 7. Updates metadata (last revision and sync timestamp).
  Future<Result<SyncSummary, VaultFailure>> synchronize({
    required String serverUrl,
    required String vaultId,
    required String passphrase,
    String? registrationToken,
    bool allowInsecureCertificates = false,
  }) async {
    try {
      final initializedRecord = await (_db.select(_db.vaultMetadataTable)
            ..where((t) => t.metaKey.equals('is_initialized')))
          .getSingleOrNull();
      final isInitialized = initializedRecord?.metaValue == 'true';
      if (isInitialized && !_securityContext.isUnlocked) {
        return Result.error(VaultFailure.locked());
      }

      final syncClient =
          SyncClient(allowInsecureCertificates: allowInsecureCertificates);

      // 1. Derive zero-knowledge sync key and auth hash
      final syncKey = await _syncCrypto.deriveSyncKey(
        passphrase: passphrase,
        vaultId: vaultId,
      );
      final authHash = await _syncCrypto.computeAuthHash(
        syncKey: syncKey,
        vaultId: vaultId,
      );

      // 2. Ensure vault exists on server
      final initRes = await syncClient.initVault(
        baseUrl: serverUrl,
        vaultId: vaultId,
        authHash: authHash,
        registrationToken: registrationToken,
      );
      if (initRes.isError) {
        return Result.error(initRes.failureOrNull!);
      }

      // 3. Read last saved server revision from metadata
      final lastRevMeta = await (_db.select(_db.vaultMetadataTable)
            ..where((t) => t.metaKey.equals('sync_last_revision')))
          .getSingleOrNull();
      final lastRevision = int.tryParse(lastRevMeta?.metaValue ?? '0') ?? 0;

      // 4. STEP 1 (PULL): Fetch remote changes since last known revision first
      final fetchRes = await syncClient.fetchChanges(
        baseUrl: serverUrl,
        vaultId: vaultId,
        authHash: authHash,
        sinceRevision: lastRevision,
      );
      if (fetchRes.isError) {
        return Result.error(fetchRes.failureOrNull!);
      }

      final changes = fetchRes.valueOrNull!;
      int pulledCount = 0;
      int currentRev = changes.currentRevision > lastRevision
          ? changes.currentRevision
          : lastRevision;

      // Apply remote changes locally
      for (final item in changes.items) {
        if (item.isDeleted) {
          await _applyRemoteDeletion(item);
          pulledCount++;
        } else if (item.encryptedBlob.isNotEmpty) {
          try {
            final payload = await _syncCrypto.decryptPayload(
              encryptedBlob: item.encryptedBlob,
              syncKey: syncKey,
            );
            await _applyRemoteUpsert(item.entityType, payload, item.updatedAt);
            pulledCount++;
          } catch (e) {
            // Ignore decryption failure for corrupted blobs
          }
        }
      }

      // 5. STEP 2 (PUSH): Gather remaining local entities & tombstones
      final localItems = <SyncItem>[];

      // Hosts
      final hosts = await _db.select(_db.hostsTable).get();
      for (final h in hosts) {
        final payload = {
          'id': h.id,
          'label': h.label,
          'hostname': h.hostname,
          'port': h.port,
          'username': h.username,
          'authType': h.authType,
          'credentialRefId': h.credentialRefId,
          'folderId': h.folderId,
          'tags': h.tags,
          'environment': h.environment,
          'osType': h.osType,
          'keepAliveIntervalSeconds': h.keepAliveIntervalSeconds,
          'dangerousCommandProtection': h.dangerousCommandProtection,
          'createdAt': h.createdAt.toIso8601String(),
          'updatedAt': h.updatedAt.toIso8601String(),
        };
        final encrypted = await _syncCrypto.encryptPayload(
          payload: payload,
          syncKey: syncKey,
        );
        localItems.add(SyncItem(
          itemId: h.id,
          entityType: 'host',
          version: 1,
          isDeleted: false,
          encryptedBlob: encrypted,
          updatedAt: h.updatedAt,
        ));
      }

      // Keys
      final keys = await _db.select(_db.keysTable).get();
      final activeKey = await _getActiveOrOpenKey();

      for (final k in keys) {
        String? clearPrivateKeyBase64;
        String? clearPassphrase;

        if (activeKey != null) {
          try {
            final decryptedPriv = await _cryptoService.decryptBytes(
              encryptedData: k.encryptedPrivateKey,
              secretKey: activeKey,
            );
            clearPrivateKeyBase64 = base64Encode(decryptedPriv);
            VaultCryptoService.zeroize(decryptedPriv);

            if (k.encryptedPassphrase != null) {
              final decryptedPass = await _cryptoService.decryptBytes(
                encryptedData: k.encryptedPassphrase!,
                secretKey: activeKey,
              );
              clearPassphrase = utf8.decode(decryptedPass);
              VaultCryptoService.zeroize(decryptedPass);
            }
          } catch (_) {
            // Non-fatal: ignore key decryption errors during export
          }
        }

        final payload = {
          'id': k.id,
          'label': k.label,
          'keyType': k.keyType,
          'encryptedPrivateKey': base64Encode(k.encryptedPrivateKey),
          'publicKey': k.publicKey,
          'encryptedPassphrase': k.encryptedPassphrase != null
              ? base64Encode(k.encryptedPassphrase!)
              : null,
          'clearPrivateKey': clearPrivateKeyBase64,
          'clearPassphrase': clearPassphrase,
          'fingerprint': k.fingerprint,
          'createdAt': k.createdAt.toIso8601String(),
          'updatedAt': k.updatedAt.toIso8601String(),
        };
        final encrypted = await _syncCrypto.encryptPayload(
          payload: payload,
          syncKey: syncKey,
        );
        localItems.add(SyncItem(
          itemId: k.id,
          entityType: 'key',
          version: 1,
          isDeleted: false,
          encryptedBlob: encrypted,
          updatedAt: k.updatedAt,
        ));
      }

      // Folders
      final folders = await _db.select(_db.foldersTable).get();
      for (final f in folders) {
        final payload = {
          'id': f.id,
          'name': f.name,
          'parentId': f.parentId,
          'colorHex': f.colorHex,
          'iconName': f.iconName,
          'sortOrder': f.sortOrder,
        };
        final encrypted = await _syncCrypto.encryptPayload(
          payload: payload,
          syncKey: syncKey,
        );
        localItems.add(SyncItem(
          itemId: f.id,
          entityType: 'folder',
          version: 1,
          isDeleted: false,
          encryptedBlob: encrypted,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
        ));
      }

      // Snippets
      final snippets = await _db.select(_db.snippetsTable).get();
      for (final s in snippets) {
        final payload = {
          'id': s.id,
          'title': s.title,
          'command': s.command,
          'description': s.description,
          'tags': s.tags,
          'folderId': s.folderId,
          'createdAt': s.createdAt.toIso8601String(),
          'updatedAt': s.updatedAt.toIso8601String(),
        };
        final encrypted = await _syncCrypto.encryptPayload(
          payload: payload,
          syncKey: syncKey,
        );
        localItems.add(SyncItem(
          itemId: s.id,
          entityType: 'snippet',
          version: 1,
          isDeleted: false,
          encryptedBlob: encrypted,
          updatedAt: s.updatedAt,
        ));
      }

      // Tombstones
      final tombstones = await _db.select(_db.syncTombstonesTable).get();
      for (final t in tombstones) {
        localItems.add(SyncItem(
          itemId: t.entityId,
          entityType: t.entityType,
          version: 1,
          isDeleted: true,
          encryptedBlob: Uint8List(0),
          updatedAt: t.deletedAt,
        ));
      }

      // Push local state to server
      int pushedCount = 0;
      if (localItems.isNotEmpty) {
        final pushRes = await syncClient.pushChanges(
          baseUrl: serverUrl,
          vaultId: vaultId,
          authHash: authHash,
          items: localItems,
        );
        if (pushRes.isError) {
          return Result.error(pushRes.failureOrNull!);
        }
        currentRev = pushRes.valueOrNull ?? currentRev;
        pushedCount = localItems.length;
      }

      // 8. Update metadata
      final maxRev = changes.currentRevision > currentRev
          ? changes.currentRevision
          : currentRev;
      await _db.into(_db.vaultMetadataTable).insertOnConflictUpdate(
            VaultMetadataTableCompanion(
              metaKey: const Value('sync_last_revision'),
              metaValue: Value(maxRev.toString()),
            ),
          );

      final now = DateTime.now();
      await _db.into(_db.vaultMetadataTable).insertOnConflictUpdate(
            VaultMetadataTableCompanion(
              metaKey: const Value('sync_last_synced_at'),
              metaValue: Value(now.toIso8601String()),
            ),
          );

      // Update settings table with lastSyncedAt
      final existingSettings = await (_db.select(_db.vaultSettingsTable)
            ..where((t) => t.id.equals(1)))
          .getSingleOrNull();
      if (existingSettings != null) {
        await (_db.update(_db.vaultSettingsTable)..where((t) => t.id.equals(1)))
            .write(
          VaultSettingsTableCompanion(
            lastSyncedAt: Value(now),
            isSyncEnabled: const Value(true),
            syncServerUrl: Value(serverUrl),
            syncVaultId: Value(vaultId),
            allowInsecureCertificates: Value(allowInsecureCertificates),
          ),
        );
      }

      return Result.success(SyncSummary(
        pushedCount: pushedCount,
        pulledCount: pulledCount,
        serverRevision: maxRev,
        timestamp: now,
      ));
    } catch (e) {
      return Result.error(VaultFailure(
        'Synchronization failed: $e',
        type: VaultFailureType.corrupted,
      ));
    }
  }

  Future<void> _applyRemoteDeletion(SyncItem item) async {
    switch (item.entityType) {
      case 'host':
        await (_db.delete(_db.hostsTable)
              ..where((t) => t.id.equals(item.itemId)))
            .go();
        break;
      case 'key':
        await (_db.delete(_db.keysTable)
              ..where((t) => t.id.equals(item.itemId)))
            .go();
        break;
      case 'folder':
        await (_db.delete(_db.foldersTable)
              ..where((t) => t.id.equals(item.itemId)))
            .go();
        break;
      case 'snippet':
        await (_db.delete(_db.snippetsTable)
              ..where((t) => t.id.equals(item.itemId)))
            .go();
        break;
    }
    // Record tombstone locally to prevent resurrecting
    await _db.into(_db.syncTombstonesTable).insertOnConflictUpdate(
          SyncTombstonesTableCompanion(
            entityId: Value(item.itemId),
            entityType: Value(item.entityType),
            deletedAt: Value(item.updatedAt),
          ),
        );
  }

  Future<void> _applyRemoteUpsert(
    String entityType,
    Map<String, dynamic> data,
    DateTime remoteUpdatedAt,
  ) async {
    final id = data['id'] as String;

    // Clear local tombstone if entity is alive
    await (_db.delete(_db.syncTombstonesTable)
          ..where((t) => t.entityId.equals(id)))
        .go();

    switch (entityType) {
      case 'host':
        final existing = await (_db.select(_db.hostsTable)
              ..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        if (existing == null || remoteUpdatedAt.isAfter(existing.updatedAt)) {
          await _db.into(_db.hostsTable).insertOnConflictUpdate(
                HostsTableCompanion(
                  id: Value(id),
                  label: Value(data['label'] as String? ?? 'Host'),
                  hostname: Value(data['hostname'] as String? ?? 'localhost'),
                  port: Value(data['port'] as int? ?? 22),
                  username: Value(data['username'] as String? ?? 'root'),
                  authType: Value(data['authType'] as String? ?? 'password'),
                  credentialRefId: Value(data['credentialRefId'] as String?),
                  folderId: Value(data['folderId'] as String?),
                  tags: Value(data['tags'] as String? ?? '[]'),
                  environment:
                      Value(data['environment'] as String? ?? 'development'),
                  osType: Value(data['osType'] as String? ?? 'linux'),
                  keepAliveIntervalSeconds:
                      Value(data['keepAliveIntervalSeconds'] as int? ?? 30),
                  dangerousCommandProtection: Value(
                      data['dangerousCommandProtection'] as bool? ?? false),
                  createdAt: Value(
                      DateTime.tryParse(data['createdAt'] as String? ?? '') ??
                          DateTime.now()),
                  updatedAt: Value(remoteUpdatedAt),
                ),
              );
        }
        break;

      case 'key':
        final existing = await (_db.select(_db.keysTable)
              ..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        if (existing == null || remoteUpdatedAt.isAfter(existing.updatedAt)) {
          final activeKey = await _getActiveOrOpenKey();
          Uint8List? localEncryptedPrivateKey;
          Uint8List? localEncryptedPassphrase;

          if (activeKey != null) {
            if (data['clearPrivateKey'] != null) {
              final rawPrivBytes =
                  base64Decode(data['clearPrivateKey'] as String);
              localEncryptedPrivateKey = await _cryptoService.encryptBytes(
                clearText: rawPrivBytes,
                secretKey: activeKey,
              );
              VaultCryptoService.zeroize(rawPrivBytes);
            }
            if (data['clearPassphrase'] != null) {
              final rawPassBytes =
                  utf8.encode(data['clearPassphrase'] as String);
              localEncryptedPassphrase = await _cryptoService.encryptBytes(
                clearText: rawPassBytes,
                secretKey: activeKey,
              );
            }
          }

          if (localEncryptedPrivateKey == null) {
            if (data['encryptedPrivateKey'] != null &&
                (data['encryptedPrivateKey'] as String).isNotEmpty) {
              localEncryptedPrivateKey =
                  base64Decode(data['encryptedPrivateKey'] as String);
            } else if (existing != null) {
              localEncryptedPrivateKey = existing.encryptedPrivateKey;
            } else {
              localEncryptedPrivateKey = Uint8List(0);
            }
          }

          if (localEncryptedPassphrase == null &&
              data['encryptedPassphrase'] != null) {
            localEncryptedPassphrase =
                base64Decode(data['encryptedPassphrase'] as String);
          } else if (localEncryptedPassphrase == null && existing != null) {
            localEncryptedPassphrase = existing.encryptedPassphrase;
          }

          await _db.into(_db.keysTable).insertOnConflictUpdate(
                KeysTableCompanion(
                  id: Value(id),
                  label: Value(data['label'] as String? ?? 'Key'),
                  keyType: Value(data['keyType'] as String? ?? 'ed25519'),
                  encryptedPrivateKey: Value(localEncryptedPrivateKey),
                  publicKey: Value(data['publicKey'] as String? ?? ''),
                  encryptedPassphrase: Value(localEncryptedPassphrase),
                  fingerprint: Value(data['fingerprint'] as String?),
                  createdAt: Value(
                      DateTime.tryParse(data['createdAt'] as String? ?? '') ??
                          DateTime.now()),
                  updatedAt: Value(remoteUpdatedAt),
                ),
              );
        }
        break;

      case 'folder':
        await _db.into(_db.foldersTable).insertOnConflictUpdate(
              FoldersTableCompanion(
                id: Value(id),
                name: Value(data['name'] as String? ?? 'Folder'),
                parentId: Value(data['parentId'] as String?),
                colorHex: Value(data['colorHex'] as String?),
                iconName: Value(data['iconName'] as String?),
                sortOrder: Value(data['sortOrder'] as int? ?? 0),
              ),
            );
        break;

      case 'snippet':
        final existing = await (_db.select(_db.snippetsTable)
              ..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        if (existing == null || remoteUpdatedAt.isAfter(existing.updatedAt)) {
          await _db.into(_db.snippetsTable).insertOnConflictUpdate(
                SnippetsTableCompanion(
                  id: Value(id),
                  title: Value(data['title'] as String? ?? 'Snippet'),
                  command: Value(data['command'] as String? ?? ''),
                  description: Value(data['description'] as String?),
                  tags: Value(data['tags'] as String? ?? '[]'),
                  folderId: Value(data['folderId'] as String?),
                  createdAt: Value(
                      DateTime.tryParse(data['createdAt'] as String? ?? '') ??
                          DateTime.now()),
                  updatedAt: Value(remoteUpdatedAt),
                ),
              );
        }
        break;
    }
  }
}
