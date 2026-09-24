import 'package:core_foundation/core_foundation.dart';
import 'package:cryptography/cryptography.dart';
import 'package:storage_vault/storage_vault.dart';
import 'package:test/test.dart';

void main() {
  group('KnownHostRepository', () {
    late VaultDatabase db;
    late VaultSecurityContext securityContext;
    late KnownHostRepository repositoryWithAuth;
    late KnownHostRepository repositoryOpen;

    setUp(() {
      db = VaultDatabaseConnection.inMemory();
      securityContext = VaultSecurityContext();

      repositoryWithAuth = KnownHostRepository(
        db: db,
        securityContext: securityContext,
      );

      repositoryOpen = KnownHostRepository(
        db: db,
      );
    });

    tearDown(() async {
      await db.close();
      await securityContext.dispose();
    });

    final now = DateTime.now();
    final testHost1 = KnownHostEntity(
      id: 'kh-1',
      host: 'github.com',
      port: 22,
      keyType: 'ssh-ed25519',
      fingerprintSha256: 'SHA256:+DiY3wvvV6TuKe7v5s20dab0q6guWOATPwp199vgKt0',
      firstSeenAt: now,
      lastSeenAt: now,
    );

    final testHost2 = KnownHostEntity(
      id: 'kh-2',
      host: 'gitlab.com',
      port: 2222,
      keyType: 'ecdsa-sha2-nistp256',
      fingerprintSha256: 'SHA256:HbW3g8zUjNSksFbqTiUWPWg2Bq1x8HFzTEh4hWVMjCo',
      firstSeenAt: now,
      lastSeenAt: now,
    );

    test('findKnownHost returns null for non-existent host', () async {
      final result = await repositoryOpen.findKnownHost('unknown.com', 22);
      expect(result, isNull);
    });

    test('saveKnownHost and findKnownHost roundtrip correctly', () async {
      final saveResult = await repositoryOpen.saveKnownHost(testHost1);
      expect(saveResult.isSuccess, isTrue);

      final found = await repositoryOpen.findKnownHost('github.com', 22);
      expect(found, isNotNull);
      expect(found!.id, equals(testHost1.id));
      expect(found.host, equals('github.com'));
      expect(found.port, equals(22));
      expect(found.keyType, equals('ssh-ed25519'));
      expect(found.fingerprintSha256, equals(testHost1.fingerprintSha256));
    });

    test('differentiates hosts by both host and port', () async {
      final hostPort22 = testHost1.copyWith(id: 'kh-22', port: 22);
      final hostPort2222 = testHost1.copyWith(
        id: 'kh-2222',
        port: 2222,
        fingerprintSha256: 'SHA256:DifferentFingerprint',
      );

      await repositoryOpen.saveKnownHost(hostPort22);
      await repositoryOpen.saveKnownHost(hostPort2222);

      final found22 = await repositoryOpen.findKnownHost('github.com', 22);
      final found2222 = await repositoryOpen.findKnownHost('github.com', 2222);

      expect(found22, isNotNull);
      expect(found22!.port, equals(22));
      expect(found2222, isNotNull);
      expect(found2222!.port, equals(2222));
      expect(found22.fingerprintSha256,
          isNot(equals(found2222.fingerprintSha256)));
    });

    test('saveKnownHost updates existing record with insertOnConflictUpdate',
        () async {
      await repositoryOpen.saveKnownHost(testHost1);

      final updatedTime = now.add(const Duration(days: 5));
      final updated = testHost1.copyWith(
        lastSeenAt: updatedTime,
        fingerprintSha256: 'SHA256:UpdatedKeyFingerprint',
      );

      final updateResult = await repositoryOpen.saveKnownHost(updated);
      expect(updateResult.isSuccess, isTrue);

      final found = await repositoryOpen.findKnownHost('github.com', 22);
      expect(found, isNotNull);
      expect(found!.fingerprintSha256, equals('SHA256:UpdatedKeyFingerprint'));
    });

    test('deleteKnownHost removes entry from database', () async {
      await repositoryOpen.saveKnownHost(testHost1);
      final beforeDelete = await repositoryOpen.findKnownHost('github.com', 22);
      expect(beforeDelete, isNotNull);

      final deleteResult =
          await repositoryOpen.deleteKnownHost('github.com', 22);
      expect(deleteResult.isSuccess, isTrue);

      final afterDelete = await repositoryOpen.findKnownHost('github.com', 22);
      expect(afterDelete, isNull);
    });

    test('getAllKnownHosts returns all hosts sorted by host and port',
        () async {
      expect(await repositoryOpen.getAllKnownHosts(), isEmpty);

      await repositoryOpen.saveKnownHost(testHost2);
      await repositoryOpen.saveKnownHost(testHost1);

      final list = await repositoryOpen.getAllKnownHosts();
      expect(list.length, equals(2));
      expect(list[0].host, equals('github.com'));
      expect(list[1].host, equals('gitlab.com'));
    });

    test('watchAllKnownHosts emits updates reactively', () async {
      final emissions = <List<KnownHostEntity>>[];
      final subscription =
          repositoryOpen.watchAllKnownHosts().listen(emissions.add);

      await Future.delayed(const Duration(milliseconds: 50));
      expect(emissions.last, isEmpty);

      await repositoryOpen.saveKnownHost(testHost1);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(emissions.last.length, equals(1));
      expect(emissions.last.first.host, equals('github.com'));

      await repositoryOpen.deleteKnownHost('github.com', 22);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(emissions.last, isEmpty);

      await subscription.cancel();
    });

    test(
        'saveKnownHost and deleteKnownHost fail when securityContext is locked',
        () async {
      expect(securityContext.isUnlocked, isFalse);

      final saveResult = await repositoryWithAuth.saveKnownHost(testHost1);
      expect(saveResult.isSuccess, isFalse);
      expect(saveResult.failureOrNull, isA<VaultFailure>());

      final deleteResult =
          await repositoryWithAuth.deleteKnownHost('github.com', 22);
      expect(deleteResult.isSuccess, isFalse);
      expect(deleteResult.failureOrNull, isA<VaultFailure>());

      // Unlock and verify it succeeds
      securityContext.unlock(VaultCryptoService.constantTimeEquals([], [])
          ? SecretKey([1, 2, 3])
          : SecretKey([]));
      expect(securityContext.isUnlocked, isTrue);

      final unlockedSave = await repositoryWithAuth.saveKnownHost(testHost1);
      expect(unlockedSave.isSuccess, isTrue);
    });
  });
}
