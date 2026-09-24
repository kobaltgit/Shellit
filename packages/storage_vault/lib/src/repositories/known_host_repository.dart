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

  /// Canonicalizes an SSH SHA-256 fingerprint into standard OpenSSH format:
  /// `SHA256:<base64-without-trailing-padding>` (e.g. `SHA256:+DiY3wvvV6...`).
  static String canonicalizeFingerprint(String fingerprint) {
    var trimmed = fingerprint.trim();
    if (trimmed.isEmpty) return trimmed;

    // Strip case-insensitive 'SHA256:' or 'sha256:' prefix if present
    if (trimmed.toUpperCase().startsWith('SHA256:')) {
      trimmed = trimmed.substring(7).trim();
    }

    // Strip trailing base64 padding '=' characters as per standard OpenSSH convention
    trimmed = trimmed.replaceAll('=', '');

    return 'SHA256:$trimmed';
  }

  @override
  Future<KnownHostEntity?> findKnownHost(String host, int port) async {
    final query = _db.select(_db.knownHostsTable)
      ..where((t) => t.host.equals(host) & t.port.equals(port));
    final record = await query.getSingleOrNull();
    if (record == null) return null;
    return record.toEntity().copyWith(
          fingerprintSha256: canonicalizeFingerprint(record.fingerprintSha256),
        );
  }

  /// Finds all known hosts matching [fingerprint] (in canonical, raw, or padded format).
  Future<List<KnownHostEntity>> findKnownHostsByFingerprint(
      String fingerprint) async {
    final canonical = canonicalizeFingerprint(fingerprint);
    final rawBase64 = canonical.substring(7);
    final paddedCanonical = '$canonical=';
    final paddedRaw = '$rawBase64=';

    final query = _db.select(_db.knownHostsTable)
      ..where((t) =>
          t.fingerprintSha256.equals(canonical) |
          t.fingerprintSha256.equals(paddedCanonical) |
          t.fingerprintSha256.equals(rawBase64) |
          t.fingerprintSha256.equals(paddedRaw) |
          t.fingerprintSha256.equals(fingerprint));
    final records = await query.get();
    return records
        .map((r) => r.toEntity().copyWith(
              fingerprintSha256: canonicalizeFingerprint(r.fingerprintSha256),
            ))
        .toList();
  }

  /// Finds a single known host matching [fingerprint].
  Future<KnownHostEntity?> findKnownHostByFingerprint(
      String fingerprint) async {
    final list = await findKnownHostsByFingerprint(fingerprint);
    return list.isNotEmpty ? list.first : null;
  }

  /// Checks whether the known host for [host] and [port] matches [fingerprint]
  /// using canonical comparison.
  Future<bool> matchesFingerprint({
    required String host,
    required int port,
    required String fingerprint,
  }) async {
    final known = await findKnownHost(host, port);
    if (known == null) return false;
    return canonicalizeFingerprint(known.fingerprintSha256) ==
        canonicalizeFingerprint(fingerprint);
  }

  @override
  Future<Result<void, VaultFailure>> saveKnownHost(
      KnownHostEntity entity) async {
    if (_securityContext != null && !_securityContext!.isUnlocked) {
      return Result.error(VaultFailure.locked());
    }

    try {
      final canonicalFp = canonicalizeFingerprint(entity.fingerprintSha256);
      await _db.into(_db.knownHostsTable).insertOnConflictUpdate(
            KnownHostsTableCompanion(
              id: Value(entity.id),
              host: Value(entity.host),
              port: Value(entity.port),
              keyType: Value(entity.keyType),
              fingerprintSha256: Value(canonicalFp),
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
    return records
        .map((r) => r.toEntity().copyWith(
              fingerprintSha256: canonicalizeFingerprint(r.fingerprintSha256),
            ))
        .toList();
  }

  @override
  Stream<List<KnownHostEntity>> watchAllKnownHosts() {
    final query = _db.select(_db.knownHostsTable)
      ..orderBy([
        (t) => OrderingTerm.asc(t.host),
        (t) => OrderingTerm.asc(t.port),
      ]);
    return query.watch().map((records) => records
        .map((r) => r.toEntity().copyWith(
              fingerprintSha256: canonicalizeFingerprint(r.fingerprintSha256),
            ))
        .toList());
  }
}
