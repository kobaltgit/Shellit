import 'package:core_foundation/core_foundation.dart';
import 'package:drift/drift.dart';
import '../database/vault_database.dart';
import '../security/vault_security_context.dart';

/// Implementation of [IKnownHostRepository] providing CRUD and reactive streaming
/// for known SSH host fingerprints (TOFU) using Drift.
class KnownHostRepository implements IKnownHostRepository {
  final VaultDatabase _db;
  final VaultSecurityContext? _securityContext;

  KnownHostRepository({
    required VaultDatabase db,
    VaultSecurityContext? securityContext,
  })  : _db = db,
        _securityContext = securityContext;

  @override
  Future<KnownHostEntity?> findKnownHost(String host, int port) async {
    final query = _db.select(_db.knownHostsTable)
      ..where((t) => t.host.equals(host) & t.port.equals(port));
    final record = await query.getSingleOrNull();
    return record?.toEntity();
  }

  @override
  Future<Result<void, VaultFailure>> saveKnownHost(
      KnownHostEntity entity) async {
    if (_securityContext != null && !_securityContext!.isUnlocked) {
      return Result.error(VaultFailure.locked());
    }

    try {
      await _db.into(_db.knownHostsTable).insertOnConflictUpdate(
            KnownHostsTableCompanion(
              id: Value(entity.id),
              host: Value(entity.host),
              port: Value(entity.port),
              keyType: Value(entity.keyType),
              fingerprintSha256: Value(entity.fingerprintSha256),
              firstSeenAt: Value(entity.firstSeenAt),
              lastSeenAt: Value(entity.lastSeenAt),
            ),
          );
      return const Result.success(null);
    } catch (e) {
      return Result.error(VaultFailure.corrupted(e));
    }
  }

  @override
  Future<Result<void, VaultFailure>> deleteKnownHost(
      String host, int port) async {
    if (_securityContext != null && !_securityContext!.isUnlocked) {
      return Result.error(VaultFailure.locked());
    }

    try {
      await (_db.delete(_db.knownHostsTable)
            ..where((t) => t.host.equals(host) & t.port.equals(port)))
          .go();
      return const Result.success(null);
    } catch (e) {
      return Result.error(VaultFailure.corrupted(e));
    }
  }

  @override
  Future<List<KnownHostEntity>> getAllKnownHosts() async {
    final query = _db.select(_db.knownHostsTable)
      ..orderBy([
        (t) => OrderingTerm.asc(t.host),
        (t) => OrderingTerm.asc(t.port),
      ]);
    final records = await query.get();
    return records.map((r) => r.toEntity()).toList();
  }

  @override
  Stream<List<KnownHostEntity>> watchAllKnownHosts() {
    final query = _db.select(_db.knownHostsTable)
      ..orderBy([
        (t) => OrderingTerm.asc(t.host),
        (t) => OrderingTerm.asc(t.port),
      ]);
    return query
        .watch()
        .map((records) => records.map((r) => r.toEntity()).toList());
  }
}
