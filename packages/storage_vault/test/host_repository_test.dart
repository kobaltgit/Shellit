import 'package:core_foundation/core_foundation.dart';
import 'package:storage_vault/storage_vault.dart';
import 'package:test/test.dart';

void main() {
  group('HostRepository', () {
    late VaultDatabase db;
    late VaultSecurityContext securityContext;
    late VaultCryptoService cryptoService;
    late VaultRepository vaultRepository;
    late HostRepository hostRepository;

    setUp(() async {
      db = VaultDatabaseConnection.inMemory();
      securityContext = VaultSecurityContext();
      cryptoService = VaultCryptoService(
        argon2Memory: 1024,
        argon2Iterations: 2,
        argon2Parallelism: 1,
        argon2HashLength: 32,
      );

      vaultRepository = VaultRepository(
        db: db,
        cryptoService: cryptoService,
        securityContext: securityContext,
      );

      hostRepository = HostRepository(
        db: db,
        securityContext: securityContext,
      );

      await vaultRepository.initializeVault('MasterPassword');
    });

    tearDown(() async {
      await vaultRepository.dispose();
      await db.close();
    });

    final now = DateTime.now();
    final testHost1 = HostEntity(
      id: 'host-1',
      label: 'Production DB',
      hostname: '10.0.0.1',
      port: 2222,
      username: 'admin',
      authType: HostAuthType.privateKey,
      tags: ['db', 'prod'],
      environment: HostEnvironment.production,
      osType: OsType.debian,
      createdAt: now,
      updatedAt: now,
    );

    final testHost2 = HostEntity(
      id: 'host-2',
      label: 'Staging App',
      hostname: '10.0.0.2',
      port: 22,
      username: 'deploy',
      authType: HostAuthType.password,
      tags: ['web'],
      environment: HostEnvironment.staging,
      osType: OsType.ubuntu,
      createdAt: now,
      updatedAt: now,
    );

    test('saveHost fails when vault is locked', () async {
      vaultRepository.lock();
      final result = await hostRepository.saveHost(testHost1);
      expect(result.isError, isTrue);
      expect(result.failureOrNull?.type, equals(VaultFailureType.locked));
    });

    test('saveHost and getAllHosts roundtrip', () async {
      final save1 = await hostRepository.saveHost(testHost1);
      final save2 = await hostRepository.saveHost(testHost2);
      expect(save1.isSuccess, isTrue);
      expect(save2.isSuccess, isTrue);

      final hosts = await hostRepository.getAllHosts();
      expect(hosts.length, equals(2));
      expect(hosts.any((h) => h.id == 'host-1' && h.label == 'Production DB'),
          isTrue);
      expect(
          hosts.any(
              (h) => h.id == 'host-2' && h.authType == HostAuthType.password),
          isTrue);
    });

    test('getHostById returns correct host or null if not found', () async {
      await hostRepository.saveHost(testHost1);

      final found = await hostRepository.getHostById('host-1');
      expect(found, isNotNull);
      expect(found?.label, equals('Production DB'));
      expect(found?.hostname, equals('10.0.0.1'));
      expect(found?.port, equals(2222));
      expect(found?.tags, equals(['db', 'prod']));

      final notFound = await hostRepository.getHostById('unknown-id');
      expect(notFound, isNull);
    });

    test('updateHostLatency updates latency field in database', () async {
      await hostRepository.saveHost(testHost1);
      await hostRepository.updateHostLatency('host-1', 42);

      final updated = await hostRepository.getHostById('host-1');
      expect(updated?.lastPingLatencyMs, equals(42));
    });

    test('deleteHost removes host from database', () async {
      await hostRepository.saveHost(testHost1);
      final delResult = await hostRepository.deleteHost('host-1');
      expect(delResult.isSuccess, isTrue);

      final remaining = await hostRepository.getAllHosts();
      expect(remaining.isEmpty, isTrue);
    });

    test('watchAllHosts emits reactive updates on inserts and updates',
        () async {
      final emitted = <List<HostEntity>>[];
      final subscription = hostRepository.watchAllHosts().listen(emitted.add);

      await Future<void>.delayed(Duration.zero);
      expect(emitted.last, isEmpty);

      await hostRepository.saveHost(testHost1);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emitted.last.length, equals(1));

      await hostRepository.saveHost(testHost2);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emitted.last.length, equals(2));

      await subscription.cancel();
    });
  });
}
