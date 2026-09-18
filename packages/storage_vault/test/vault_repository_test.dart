import 'package:core_foundation/core_foundation.dart';
import 'package:storage_vault/storage_vault.dart';
import 'package:test/test.dart';

void main() {
  group('VaultRepository', () {
    late VaultDatabase db;
    late VaultCryptoService cryptoService;
    late VaultSecurityContext securityContext;
    late InMemoryBiometricStorage biometricStorage;
    late VaultRepository vaultRepository;

    setUp(() {
      db = VaultDatabaseConnection.inMemory();
      cryptoService = VaultCryptoService(
        argon2Memory: 1024,
        argon2Iterations: 2,
        argon2Parallelism: 1,
        argon2HashLength: 32,
      );
      securityContext = VaultSecurityContext();
      biometricStorage = InMemoryBiometricStorage();

      vaultRepository = VaultRepository(
        db: db,
        cryptoService: cryptoService,
        securityContext: securityContext,
        biometricStorage: biometricStorage,
      );
    });

    tearDown(() async {
      await vaultRepository.dispose();
      await db.close();
    });

    test('initial state is uninitialized and locked', () async {
      final initialized = await vaultRepository.isVaultInitialized();
      expect(initialized, isFalse);
      expect(vaultRepository.isVaultUnlocked, isFalse);
    });

    test(
        'ensureOpenSession unlocks uninitialized vault and allows migrating to master password',
        () async {
      await vaultRepository.ensureOpenSession();
      expect(await vaultRepository.isVaultInitialized(), isFalse);
      expect(vaultRepository.isVaultUnlocked, isTrue);

      // Now set master password - should migrate and mark initialized
      final initRes = await vaultRepository.initializeVault('Master123');
      expect(initRes.isSuccess, isTrue);
      expect(await vaultRepository.isVaultInitialized(), isTrue);
      expect(vaultRepository.isVaultUnlocked, isTrue);
    });

    test('initializeVault creates keys, marks initialized, and unlocks vault',
        () async {
      final result =
          await vaultRepository.initializeVault('MySecretPassword123');

      expect(result.isSuccess, isTrue);
      expect(await vaultRepository.isVaultInitialized(), isTrue);
      expect(vaultRepository.isVaultUnlocked, isTrue);
      expect(securityContext.activeMasterKey, isNotNull);
    });

    test('lock zeroes memory key and emits false on watchUnlockStatus',
        () async {
      await vaultRepository.initializeVault('Pass123');
      expect(vaultRepository.isVaultUnlocked, isTrue);

      final statusHistory = <bool>[];
      final subscription =
          vaultRepository.watchUnlockStatus().listen(statusHistory.add);

      vaultRepository.lock();
      expect(vaultRepository.isVaultUnlocked, isFalse);
      expect(securityContext.activeMasterKey, isNull);

      await Future<void>.delayed(Duration.zero);
      expect(statusHistory, contains(false));

      await subscription.cancel();
    });

    test('unlockWithPassword succeeds with correct password', () async {
      await vaultRepository.initializeVault('SuperSecurePassword!');
      vaultRepository.lock();
      expect(vaultRepository.isVaultUnlocked, isFalse);

      final unlockResult =
          await vaultRepository.unlockWithPassword('SuperSecurePassword!');
      expect(unlockResult.isSuccess, isTrue);
      expect(vaultRepository.isVaultUnlocked, isTrue);
    });

    test(
        'unlockWithPassword fails with invalidMasterPassword on wrong password',
        () async {
      await vaultRepository.initializeVault('CorrectPassword');
      vaultRepository.lock();

      final unlockResult =
          await vaultRepository.unlockWithPassword('IncorrectPassword');
      expect(unlockResult.isError, isTrue);

      final failure = unlockResult.failureOrNull!;
      expect(failure, isA<VaultFailure>());
      expect(failure.type, equals(VaultFailureType.invalidPassword));
      expect(vaultRepository.isVaultUnlocked, isFalse);
    });

    test(
        'changeMasterPassword updates master password and allows unlocking with new password',
        () async {
      await vaultRepository.initializeVault('OldPassword_1');

      // Attempt change with wrong current password
      final wrongChange = await vaultRepository.changeMasterPassword(
        currentPassword: 'BadOldPassword',
        newPassword: 'NewPassword_2',
      );
      expect(wrongChange.isError, isTrue);
      expect(wrongChange.failureOrNull?.type,
          equals(VaultFailureType.invalidPassword));

      // Successful change
      final successfulChange = await vaultRepository.changeMasterPassword(
        currentPassword: 'OldPassword_1',
        newPassword: 'NewPassword_2',
      );
      expect(successfulChange.isSuccess, isTrue);

      // Lock and verify old password no longer works
      vaultRepository.lock();
      final oldUnlock =
          await vaultRepository.unlockWithPassword('OldPassword_1');
      expect(oldUnlock.isError, isTrue);
      expect(oldUnlock.failureOrNull?.type,
          equals(VaultFailureType.invalidPassword));

      // Verify new password works
      final newUnlock =
          await vaultRepository.unlockWithPassword('NewPassword_2');
      expect(newUnlock.isSuccess, isTrue);
      expect(vaultRepository.isVaultUnlocked, isTrue);
    });

    test('enablePin and unlockWithPin workflow', () async {
      await vaultRepository.initializeVault('MasterPass');

      // Enable PIN 1234
      final enableResult = await vaultRepository.enablePin('1234');
      expect(enableResult.isSuccess, isTrue);

      final settings = await vaultRepository.getSettings();
      expect(settings.isPinEnabled, isTrue);

      // Lock vault
      vaultRepository.lock();

      // Unlock with wrong PIN
      final wrongPin = await vaultRepository.unlockWithPin('9999');
      expect(wrongPin.isError, isTrue);
      expect(wrongPin.failureOrNull?.type,
          equals(VaultFailureType.invalidPassword));
      expect(vaultRepository.isVaultUnlocked, isFalse);

      // Unlock with correct PIN
      final correctPin = await vaultRepository.unlockWithPin('1234');
      expect(correctPin.isSuccess, isTrue);
      expect(vaultRepository.isVaultUnlocked, isTrue);
    });

    test('enableBiometrics and unlockWithBiometrics workflow', () async {
      await vaultRepository.initializeVault('MasterPass');

      final enableBio = await vaultRepository.enableBiometrics();
      expect(enableBio.isSuccess, isTrue);

      final settings = await vaultRepository.getSettings();
      expect(settings.isBiometricsEnabled, isTrue);

      vaultRepository.lock();
      expect(vaultRepository.isVaultUnlocked, isFalse);

      final unlockBio = await vaultRepository.unlockWithBiometrics();
      expect(unlockBio.isSuccess, isTrue);
      expect(vaultRepository.isVaultUnlocked, isTrue);
    });

    test('getSettings and updateSettings persists user preferences', () async {
      await vaultRepository.initializeVault('Pass');
      final initial = await vaultRepository.getSettings();
      expect(initial.idleLockTimeoutMinutes, equals(15));
      expect(initial.themeId, equals('deep_slate'));

      final updated = initial.copyWith(
        idleLockTimeoutMinutes: 30,
        themeId: 'nord_night',
        terminalFontSize: 16.0,
      );

      final updateResult = await vaultRepository.updateSettings(updated);
      expect(updateResult.isSuccess, isTrue);

      final fetched = await vaultRepository.getSettings();
      expect(fetched.idleLockTimeoutMinutes, equals(30));
      expect(fetched.themeId, equals('nord_night'));
      expect(fetched.terminalFontSize, equals(16.0));
    });
  });
}
