import 'package:core_foundation/core_foundation.dart';
import 'package:drift/drift.dart';
import '../database/vault_database.dart';
import '../security/vault_security_context.dart';

/// Implementation of [IFolderRepository] for organizing hosts and snippets hierarchically.
class FolderRepository implements IFolderRepository {
  final VaultDatabase _db;
  final VaultSecurityContext _securityContext;

  FolderRepository({
    required VaultDatabase db,
    required VaultSecurityContext securityContext,
  })  : _db = db,
        _securityContext = securityContext;

  @override
  Future<List<FolderEntity>> getAllFolders() async {
    final query = _db.select(_db.foldersTable)
      ..orderBy([
        (t) => OrderingTerm.asc(t.sortOrder),
        (t) => OrderingTerm.asc(t.name),
      ]);
    final records = await query.get();
    return records.map((r) => r.toEntity()).toList();
  }

  @override
  Stream<List<FolderEntity>> watchAllFolders() {
    final query = _db.select(_db.foldersTable)
      ..orderBy([
        (t) => OrderingTerm.asc(t.sortOrder),
        (t) => OrderingTerm.asc(t.name),
      ]);
    return query
        .watch()
        .map((records) => records.map((r) => r.toEntity()).toList());
  }

  @override
  Future<Result<void, VaultFailure>> saveFolder(FolderEntity folder) async {
    if (!_securityContext.isUnlocked) {
      return Result.error(VaultFailure.locked());
    }

    try {
      await _db.into(_db.foldersTable).insertOnConflictUpdate(
            FoldersTableCompanion(
              id: Value(folder.id),
              name: Value(folder.name),
              parentId: Value(folder.parentId),
              colorHex: Value(folder.colorHex),
              iconName: Value(folder.iconName),
              sortOrder: Value(folder.sortOrder),
            ),
          );
      await (_db.delete(_db.syncTombstonesTable)
            ..where((t) => t.entityId.equals(folder.id)))
          .go();
      return const Result.success(null);
    } catch (e) {
      return Result.error(VaultFailure.corrupted(e));
    }
  }

  @override
  Future<Result<void, VaultFailure>> deleteFolder(String id) async {
    if (!_securityContext.isUnlocked) {
      return Result.error(VaultFailure.locked());
    }

    try {
      await (_db.delete(_db.foldersTable)..where((t) => t.id.equals(id))).go();
      await _db.into(_db.syncTombstonesTable).insertOnConflictUpdate(
            SyncTombstonesTableCompanion(
              entityId: Value(id),
              entityType: const Value('folder'),
              deletedAt: Value(DateTime.now()),
            ),
          );
      return const Result.success(null);
    } catch (e) {
      return Result.error(VaultFailure.corrupted(e));
    }
  }
}
