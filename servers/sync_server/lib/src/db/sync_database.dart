import 'dart:io';
import 'package:sqlite3/sqlite3.dart';

/// Database layer for Shellit Sync Server using SQLite.
class SyncDatabase {
  final Database _db;

  SyncDatabase(this._db) {
    _initSchema();
  }

  factory SyncDatabase.openFile(String path) {
    final file = File(path);
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }
    final db = sqlite3.open(path);
    return SyncDatabase(db);
  }

  factory SyncDatabase.inMemory() {
    return SyncDatabase(sqlite3.openInMemory());
  }

  void _initSchema() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS vaults (
        vault_id TEXT PRIMARY KEY,
        auth_hash TEXT NOT NULL,
        created_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS sync_revisions (
        vault_id TEXT PRIMARY KEY,
        current_revision INTEGER NOT NULL DEFAULT 0
      );

      CREATE TABLE IF NOT EXISTS sync_items (
        vault_id TEXT NOT NULL,
        item_id TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        version INTEGER NOT NULL,
        is_deleted INTEGER NOT NULL,
        encrypted_blob TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        revision INTEGER NOT NULL,
        PRIMARY KEY (vault_id, item_id)
      );

      CREATE INDEX IF NOT EXISTS idx_sync_items_rev ON sync_items(vault_id, revision);
    ''');
  }

  /// Returns true if a vault with [vaultId] already exists.
  bool hasVault(String vaultId) {
    final rows =
        _db.select('SELECT 1 FROM vaults WHERE vault_id = ?', [vaultId]);
    return rows.isNotEmpty;
  }

  /// Initializes or registers a new vault.
  /// If vault exists, verifies auth_hash.
  bool initOrVerifyVault(String vaultId, String authHash) {
    final existing = _db.select(
      'SELECT auth_hash FROM vaults WHERE vault_id = ?',
      [vaultId],
    );

    if (existing.isEmpty) {
      _db.execute(
        'INSERT INTO vaults (vault_id, auth_hash, created_at) VALUES (?, ?, ?)',
        [vaultId, authHash, DateTime.now().toIso8601String()],
      );
      _db.execute(
        'INSERT INTO sync_revisions (vault_id, current_revision) VALUES (?, 0)',
        [vaultId],
      );
      return true;
    } else {
      final currentHash = existing.first['auth_hash'] as String;
      return currentHash == authHash;
    }
  }

  /// Authenticates an existing vault request.
  bool authenticateVault(String vaultId, String authHash) {
    final row = _db.select(
      'SELECT auth_hash FROM vaults WHERE vault_id = ?',
      [vaultId],
    );
    if (row.isEmpty) return false;
    return row.first['auth_hash'] == authHash;
  }

  /// Returns current revision for a vault.
  int getCurrentRevision(String vaultId) {
    final row = _db.select(
      'SELECT current_revision FROM sync_revisions WHERE vault_id = ?',
      [vaultId],
    );
    if (row.isEmpty) return 0;
    return row.first['current_revision'] as int;
  }

  /// Pushes a batch of items and increments the revision.
  int pushItems({
    required String vaultId,
    required List<Map<String, dynamic>> items,
  }) {
    final currentRev = getCurrentRevision(vaultId);
    final nextRev = currentRev + 1;

    final stmt = _db.prepare('''
      INSERT INTO sync_items (
        vault_id, item_id, entity_type, version, is_deleted, encrypted_blob, updated_at, revision
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(vault_id, item_id) DO UPDATE SET
        entity_type = excluded.entity_type,
        version = excluded.version,
        is_deleted = excluded.is_deleted,
        encrypted_blob = excluded.encrypted_blob,
        updated_at = excluded.updated_at,
        revision = excluded.revision
      WHERE excluded.updated_at >= sync_items.updated_at
    ''');

    for (final item in items) {
      stmt.execute([
        vaultId,
        item['itemId'] as String,
        item['entityType'] as String,
        item['version'] as int? ?? 1,
        (item['isDeleted'] as bool? ?? false) ? 1 : 0,
        item['encryptedBlob'] as String? ?? '',
        item['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
        nextRev,
      ]);
    }
    stmt.dispose();

    _db.execute(
      'UPDATE sync_revisions SET current_revision = ? WHERE vault_id = ?',
      [nextRev, vaultId],
    );

    return nextRev;
  }

  /// Fetches items that were modified or deleted since [sinceRevision].
  List<Map<String, dynamic>> getItemsSince({
    required String vaultId,
    required int sinceRevision,
  }) {
    final rows = _db.select(
      '''
      SELECT item_id, entity_type, version, is_deleted, encrypted_blob, updated_at, revision
      FROM sync_items
      WHERE vault_id = ? AND revision > ?
      ORDER BY revision ASC
      ''',
      [vaultId, sinceRevision],
    );

    return rows
        .map((r) => {
              'itemId': r['item_id'] as String,
              'entityType': r['entity_type'] as String,
              'version': r['version'] as int,
              'isDeleted': (r['is_deleted'] as int) == 1,
              'encryptedBlob': r['encrypted_blob'] as String,
              'updatedAt': r['updated_at'] as String,
              'revision': r['revision'] as int,
            })
        .toList();
  }

  void close() {
    _db.dispose();
  }
}
