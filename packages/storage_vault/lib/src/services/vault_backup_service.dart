import 'dart:convert';
import 'package:core_foundation/core_foundation.dart';
import 'package:drift/drift.dart';
import '../crypto/vault_crypto_service.dart';
import '../database/vault_database.dart';

/// Service responsible for exporting and importing complete encrypted vault backups (.shellit-vault).
/// The backup payload contains all hosts, keys, folders, and snippets serialized to JSON,
/// encrypted with AES-256-GCM using a key derived from a backup password via Argon2id.
class VaultBackupService {
  final VaultDatabase _db;
  final VaultCryptoService _cryptoService;

  VaultBackupService({
    required VaultDatabase db,
    required VaultCryptoService cryptoService,
  })  : _db = db,
        _cryptoService = cryptoService;

  /// Exports all vault records into an encrypted binary archive.
  /// Format:
  /// [MAGIC: 'SHLT_V1' (7 bytes)] | [SALT: 16 bytes] | [ENCRYPTED_BLOB (Nonce 12b + Tag 16b + Ciphertext)]
  Future<Result<Uint8List, VaultFailure>> exportEncryptedBackup(
      String backupPassword) async {
    try {
      // 1. Gather all database records
      final hosts = await _db.select(_db.hostsTable).get();
      final keys = await _db.select(_db.keysTable).get();
      final folders = await _db.select(_db.foldersTable).get();
      final snippets = await _db.select(_db.snippetsTable).get();

      final backupData = {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'hosts': hosts
            .map((h) => {
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
                  'dangerousCommandProtection': h.dangerousCommandProtection,
                  'createdAt': h.createdAt.toIso8601String(),
                  'updatedAt': h.updatedAt.toIso8601String(),
                })
            .toList(),
        'keys': keys
            .map((k) => {
                  'id': k.id,
                  'label': k.label,
                  'keyType': k.keyType,
                  'encryptedPrivateKey': base64Encode(k.encryptedPrivateKey),
                  'publicKey': k.publicKey,
                  'encryptedPassphrase': k.encryptedPassphrase != null
                      ? base64Encode(k.encryptedPassphrase!)
                      : null,
                  'fingerprint': k.fingerprint,
                  'createdAt': k.createdAt.toIso8601String(),
                  'updatedAt': k.updatedAt.toIso8601String(),
                })
            .toList(),
        'folders': folders
            .map((f) => {
                  'id': f.id,
                  'name': f.name,
                  'parentId': f.parentId,
                  'colorHex': f.colorHex,
                  'iconName': f.iconName,
                  'sortOrder': f.sortOrder,
                })
            .toList(),
        'snippets': snippets
            .map((s) => {
                  'id': s.id,
                  'title': s.title,
                  'command': s.command,
                  'description': s.description,
                  'tags': s.tags,
                  'folderId': s.folderId,
                  'createdAt': s.createdAt.toIso8601String(),
                  'updatedAt': s.updatedAt.toIso8601String(),
                })
            .toList(),
      };

      final jsonBytes = utf8.encode(jsonEncode(backupData));

      // 2. Derive backup key with fresh random salt
      final salt = _cryptoService.generateRandomBytes(16);
      final derivedKey = await _cryptoService.deriveMasterKey(
        password: backupPassword,
        salt: salt,
      );

      // 3. Encrypt payload
      final encryptedPayload = await _cryptoService.encryptBytes(
        clearText: jsonBytes,
        secretKey: derivedKey,
      );

      // 4. Assemble container [MAGIC (7) | SALT (16) | ENCRYPTED_PAYLOAD]
      final magic = utf8.encode('SHLT_V1');
      final output =
          Uint8List(magic.length + salt.length + encryptedPayload.length);
      output.setRange(0, magic.length, magic);
      output.setRange(magic.length, magic.length + salt.length, salt);
      output.setRange(
          magic.length + salt.length, output.length, encryptedPayload);

      return Result.success(output);
    } catch (e) {
      return Result.error(VaultFailure.corrupted(e));
    }
  }

  /// Restores vault records from an encrypted binary archive.
  /// If [merge] is false, existing records are replaced.
  Future<Result<int, VaultFailure>> importEncryptedBackup({
    required Uint8List backupBytes,
    required String backupPassword,
    bool merge = true,
  }) async {
    try {
      const magicStr = 'SHLT_V1';
      final magicLen = magicStr.length;
      const saltLen = 16;

      if (backupBytes.length < magicLen + saltLen + 28) {
        return Result.error(VaultFailure.corrupted(
            'Invalid backup file format or truncated header'));
      }

      final magic =
          utf8.decode(backupBytes.sublist(0, magicLen), allowMalformed: true);
      if (magic != magicStr) {
        return Result.error(VaultFailure.corrupted(
            'Invalid or unsupported vault backup header'));
      }

      final salt = backupBytes.sublist(magicLen, magicLen + saltLen);
      final encryptedPayload = backupBytes.sublist(magicLen + saltLen);

      // 1. Derive key
      final derivedKey = await _cryptoService.deriveMasterKey(
        password: backupPassword,
        salt: salt,
      );

      // 2. Decrypt payload
      Uint8List decryptedBytes;
      try {
        decryptedBytes = await _cryptoService.decryptBytes(
          encryptedData: encryptedPayload,
          secretKey: derivedKey,
        );
      } catch (_) {
        return Result.error(VaultFailure.invalidMasterPassword());
      }

      final jsonString = utf8.decode(decryptedBytes);
      final Map<String, dynamic> data = jsonDecode(jsonString);

      final hostsList = (data['hosts'] as List<dynamic>?) ?? [];
      final keysList = (data['keys'] as List<dynamic>?) ?? [];
      final foldersList = (data['folders'] as List<dynamic>?) ?? [];
      final snippetsList = (data['snippets'] as List<dynamic>?) ?? [];

      int restoredCount = 0;

      await _db.transaction(() async {
        if (!merge) {
          await _db.delete(_db.hostsTable).go();
          await _db.delete(_db.keysTable).go();
          await _db.delete(_db.foldersTable).go();
          await _db.delete(_db.snippetsTable).go();
        }

        // Insert Folders
        for (final item in foldersList) {
          final f = item as Map<String, dynamic>;
          await _db.into(_db.foldersTable).insertOnConflictUpdate(
                FoldersTableCompanion.insert(
                  id: f['id'] as String,
                  name: f['name'] as String,
                  parentId: Value(f['parentId'] as String?),
                  colorHex: Value(f['colorHex'] as String?),
                  iconName: Value(f['iconName'] as String?),
                  sortOrder: Value((f['sortOrder'] as num?)?.toInt() ?? 0),
                ),
              );
          restoredCount++;
        }

        // Insert Keys
        for (final item in keysList) {
          final k = item as Map<String, dynamic>;
          await _db.into(_db.keysTable).insertOnConflictUpdate(
                KeysTableCompanion.insert(
                  id: k['id'] as String,
                  label: k['label'] as String,
                  keyType: k['keyType'] as String,
                  encryptedPrivateKey:
                      base64Decode(k['encryptedPrivateKey'] as String),
                  publicKey: k['publicKey'] as String,
                  encryptedPassphrase: Value(k['encryptedPassphrase'] != null
                      ? base64Decode(k['encryptedPassphrase'] as String)
                      : null),
                  fingerprint: Value(k['fingerprint'] as String?),
                  createdAt: DateTime.parse(k['createdAt'] as String),
                  updatedAt: DateTime.parse(k['updatedAt'] as String),
                ),
              );
          restoredCount++;
        }

        // Insert Hosts
        for (final item in hostsList) {
          final h = item as Map<String, dynamic>;
          await _db.into(_db.hostsTable).insertOnConflictUpdate(
                HostsTableCompanion.insert(
                  id: h['id'] as String,
                  label: h['label'] as String,
                  hostname: h['hostname'] as String,
                  port: Value((h['port'] as num?)?.toInt() ?? 22),
                  username: h['username'] as String,
                  authType: h['authType'] as String,
                  credentialRefId: Value(h['credentialRefId'] as String?),
                  folderId: Value(h['folderId'] as String?),
                  tags: h['tags'] as String,
                  environment: h['environment'] as String,
                  osType: h['osType'] as String,
                  dangerousCommandProtection: Value(
                      (h['dangerousCommandProtection'] as bool?) ?? false),
                  createdAt: DateTime.parse(h['createdAt'] as String),
                  updatedAt: DateTime.parse(h['updatedAt'] as String),
                ),
              );
          restoredCount++;
        }

        // Insert Snippets
        for (final item in snippetsList) {
          final s = item as Map<String, dynamic>;
          await _db.into(_db.snippetsTable).insertOnConflictUpdate(
                SnippetsTableCompanion.insert(
                  id: s['id'] as String,
                  title: s['title'] as String,
                  command: s['command'] as String,
                  description: Value(s['description'] as String?),
                  tags: s['tags'] as String,
                  folderId: Value(s['folderId'] as String?),
                  createdAt: DateTime.parse(s['createdAt'] as String),
                  updatedAt: DateTime.parse(s['updatedAt'] as String),
                ),
              );
          restoredCount++;
        }
      });

      return Result.success(restoredCount);
    } catch (e) {
      return Result.error(VaultFailure.corrupted(e));
    }
  }
}
