import 'dart:convert';
import 'package:core_foundation/core_foundation.dart';
import 'package:drift/drift.dart';
import '../database/vault_database.dart';
import '../security/vault_security_context.dart';

/// Implementation of [ISnippetRepository] for storing and querying reusable commands/scripts.
class SnippetRepository implements ISnippetRepository {
  final VaultDatabase _db;
  final VaultSecurityContext _securityContext;

  SnippetRepository({
    required VaultDatabase db,
    required VaultSecurityContext securityContext,
  })  : _db = db,
        _securityContext = securityContext;

  @override
  Future<List<SnippetEntity>> getAllSnippets() async {
    final query = _db.select(_db.snippetsTable)
      ..orderBy([(t) => OrderingTerm.asc(t.title)]);
    final records = await query.get();
    return records.map((r) => r.toEntity()).toList();
  }

  @override
  Stream<List<SnippetEntity>> watchAllSnippets() {
    final query = _db.select(_db.snippetsTable)
      ..orderBy([(t) => OrderingTerm.asc(t.title)]);
    return query
        .watch()
        .map((records) => records.map((r) => r.toEntity()).toList());
  }

  @override
  Future<Result<void, VaultFailure>> saveSnippet(SnippetEntity snippet) async {
    if (!_securityContext.isUnlocked) {
      return Result.error(VaultFailure.locked());
    }

    try {
      await _db.into(_db.snippetsTable).insertOnConflictUpdate(
            SnippetsTableCompanion(
              id: Value(snippet.id),
              title: Value(snippet.title),
              command: Value(snippet.command),
              description: Value(snippet.description),
              tags: Value(jsonEncode(snippet.tags)),
              folderId: Value(snippet.folderId),
              createdAt: Value(snippet.createdAt),
              updatedAt: Value(snippet.updatedAt),
            ),
          );
      try {
        await (_db.delete(_db.syncTombstonesTable)
              ..where((t) => t.entityId.equals(snippet.id)))
            .go();
      } catch (_) {
        // Non-critical: tombstone deletion error should not fail snippet saving
      }
      return const Result.success(null);
    } catch (e) {
      return Result.error(VaultFailure.corrupted(e));
    }
  }

  @override
  Future<Result<void, VaultFailure>> deleteSnippet(String id) async {
    if (!_securityContext.isUnlocked) {
      return Result.error(VaultFailure.locked());
    }

    try {
      await (_db.delete(_db.snippetsTable)..where((t) => t.id.equals(id))).go();
      try {
        await _db.into(_db.syncTombstonesTable).insertOnConflictUpdate(
              SyncTombstonesTableCompanion(
                entityId: Value(id),
                entityType: const Value('snippet'),
                deletedAt: Value(DateTime.now()),
              ),
            );
      } catch (_) {
        // Non-critical: tombstone insertion error should not fail snippet deletion
      }
      return const Result.success(null);
    } catch (e) {
      return Result.error(VaultFailure.corrupted(e));
    }
  }
}
