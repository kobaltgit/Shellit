import 'dart:convert';
import 'package:core_foundation/core_foundation.dart';
import 'package:drift/drift.dart';
import '../database/vault_database.dart';
import '../security/vault_security_context.dart';

/// Implementation of [IHostRepository] providing CRUD and reactive streaming
/// for SSH hosts using Drift.
class HostRepository implements IHostRepository {
  final VaultDatabase _db;
  final VaultSecurityContext _securityContext;

  HostRepository({
    required VaultDatabase db,
    required VaultSecurityContext securityContext,
  })  : _db = db,
        _securityContext = securityContext;

  @override
  Future<List<HostEntity>> getAllHosts() async {
    final query = _db.select(_db.hostsTable)
      ..orderBy([(t) => OrderingTerm.asc(t.label)]);
    final records = await query.get();
    return records.map((r) => r.toEntity()).toList();
  }

  @override
  Stream<List<HostEntity>> watchAllHosts() {
    final query = _db.select(_db.hostsTable)
      ..orderBy([(t) => OrderingTerm.asc(t.label)]);
    return query
        .watch()
        .map((records) => records.map((r) => r.toEntity()).toList());
  }

  @override
  Future<HostEntity?> getHostById(String id) async {
    final query = _db.select(_db.hostsTable)..where((t) => t.id.equals(id));
    final record = await query.getSingleOrNull();
    return record?.toEntity();
  }

  @override
  Future<Result<void, VaultFailure>> saveHost(HostEntity host) async {
    if (!_securityContext.isUnlocked) {
      return Result.error(VaultFailure.locked());
    }

    try {
      await _db.into(_db.hostsTable).insertOnConflictUpdate(
            HostsTableCompanion(
              id: Value(host.id),
              label: Value(host.label),
              hostname: Value(host.hostname),
              port: Value(host.port),
              username: Value(host.username),
              authType: Value(host.authType.name),
              credentialRefId: Value(host.credentialRefId),
              folderId: Value(host.folderId),
              tags: Value(jsonEncode(host.tags)),
              environment: Value(host.environment.name),
              osType: Value(host.osType.name),
              keepAliveIntervalSeconds: Value(host.keepAliveIntervalSeconds),
              dangerousCommandProtection:
                  Value(host.dangerousCommandProtection),
              lastPingLatencyMs: Value(host.lastPingLatencyMs),
              lastConnectedAt: Value(host.lastConnectedAt),
              createdAt: Value(host.createdAt),
              updatedAt: Value(host.updatedAt),
            ),
          );
      return const Result.success(null);
    } catch (e) {
      return Result.error(VaultFailure.corrupted(e));
    }
  }

  @override
  Future<Result<void, VaultFailure>> deleteHost(String id) async {
    if (!_securityContext.isUnlocked) {
      return Result.error(VaultFailure.locked());
    }

    try {
      await (_db.delete(_db.hostsTable)..where((t) => t.id.equals(id))).go();
      return const Result.success(null);
    } catch (e) {
      return Result.error(VaultFailure.corrupted(e));
    }
  }

  @override
  Future<void> updateHostLatency(String hostId, int latencyMs) async {
    await (_db.update(_db.hostsTable)..where((t) => t.id.equals(hostId))).write(
      HostsTableCompanion(
        lastPingLatencyMs: Value(latencyMs),
      ),
    );
  }
}
