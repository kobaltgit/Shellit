import 'dart:async';
import 'dart:convert';
import 'package:core_foundation/core_foundation.dart';
import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import '../crypto/crypto_utils.dart';
import '../crypto/vault_crypto_service.dart';
import '../database/vault_database.dart';
import '../security/biometric_storage.dart';
import '../security/vault_security_context.dart';

/// Implementation of [IVaultRepository] managing master password encryption,
/// auto-lock timers, biometrics, quick PIN, and vault settings.
class VaultRepository implements IVaultRepository {
  final VaultDatabase _db;
  final VaultCryptoService _cryptoService;
  final VaultSecurityContext _securityContext;
  final IBiometricStorage? _biometricStorage;

  Timer? _idleTimer;
  VaultSettingsEntity? _cachedSettings;

  VaultRepository({
    required VaultDatabase db,
    required VaultCryptoService cryptoService,
    required VaultSecurityContext securityContext,
    IBiometricStorage? biometricStorage,
  })  : _db = db,
        _cryptoService = cryptoService,
        _securityContext = securityContext,
        _biometricStorage = biometricStorage;

  VaultSecurityContext get securityContext => _securityContext;
  VaultCryptoService get cryptoService => _cryptoService;
  VaultDatabase get database => _db;

  @override
  bool get isVaultUnlocked => _securityContext.isUnlocked;

  @override
  Stream<bool> watchUnlockStatus() => _securityContext.lockStateStream;

  @override
  Future<bool> isVaultInitialized() async {
    final record = await (_db.select(_db.vaultMetadataTable)
          ..where((t) => t.metaKey.equals('is_initialized')))
        .getSingleOrNull();
    return record?.metaValue == 'true';
  }

  @override
  Future<Result<void, VaultFailure>> initializeVault(
      String masterPassword) async {
    try {
      final salt = _cryptoService.generateRandomBytes(16);
      final masterKey = await _cryptoService.deriveMasterKey(
        password: masterPassword,
        salt: salt,
      );

      final verificationBlob =
          await _cryptoService.createVerificationBlob(masterKey);

      // Check if there was an open_session_key to migrate existing keys from
      final openKeyRecord = await (_db.select(_db.vaultMetadataTable)
            ..where((t) => t.metaKey.equals('open_session_key')))
          .getSingleOrNull();

      if (openKeyRecord != null) {
        final openKeyBytes = CryptoUtils.hexToBytes(openKeyRecord.metaValue);
        final oldOpenKey = SecretKey(openKeyBytes);

        // Re-encrypt any existing keys with the new master key
        final allKeys = await _db.select(_db.keysTable).get();
        for (final keyRecord in allKeys) {
          try {
            final decryptedPrivKey = await _cryptoService.decryptBytes(
              encryptedData: keyRecord.encryptedPrivateKey,
              secretKey: oldOpenKey,
            );

            Uint8List? decryptedPassphrase;
            if (keyRecord.encryptedPassphrase != null) {
              decryptedPassphrase = await _cryptoService.decryptBytes(
                encryptedData: keyRecord.encryptedPassphrase!,
                secretKey: oldOpenKey,
              );
            }

            final reEncryptedPrivKey = await _cryptoService.encryptBytes(
              clearText: decryptedPrivKey,
              secretKey: masterKey,
            );
            VaultCryptoService.zeroize(decryptedPrivKey);

            Uint8List? reEncryptedPassphrase;
            if (decryptedPassphrase != null) {
              reEncryptedPassphrase = await _cryptoService.encryptBytes(
                clearText: decryptedPassphrase,
                secretKey: masterKey,
              );
              VaultCryptoService.zeroize(decryptedPassphrase);
            }

            await (_db.update(_db.keysTable)
                  ..where((t) => t.id.equals(keyRecord.id)))
                .write(
              KeysTableCompanion(
                encryptedPrivateKey: Value(reEncryptedPrivKey),
                encryptedPassphrase: Value(reEncryptedPassphrase),
                updatedAt: Value(DateTime.now()),
              ),
            );
          } catch (_) {
            // Non-fatal: if a foreign key cannot be decrypted, don't abort vault initialization
          }
        }

        // Re-encrypt sync passphrase if present
        final settingsRecord = await (_db.select(_db.vaultSettingsTable)
              ..where((t) => t.id.equals(1)))
            .getSingleOrNull();
        if (settingsRecord?.encryptedSyncPassphrase != null) {
          try {
            final clearBytes = await _cryptoService.decryptBytes(
              encryptedData: settingsRecord!.encryptedSyncPassphrase!,
              secretKey: oldOpenKey,
            );
            final reEncrypted = await _cryptoService.encryptBytes(
              clearText: clearBytes,
              secretKey: masterKey,
            );
            VaultCryptoService.zeroize(clearBytes);
            await (_db.update(_db.vaultSettingsTable)
                  ..where((t) => t.id.equals(1)))
                .write(
              VaultSettingsTableCompanion(
                encryptedSyncPassphrase: Value(reEncrypted),
                syncPassphrase: const Value(null),
              ),
            );
          } catch (_) {}
        }
      }

      await _db.batch((batch) {
        batch.insert(
          _db.vaultMetadataTable,
          VaultMetadataTableCompanion.insert(
            metaKey: 'is_initialized',
            metaValue: 'true',
          ),
          mode: InsertMode.insertOrReplace,
        );
        batch.insert(
          _db.vaultMetadataTable,
          VaultMetadataTableCompanion.insert(
            metaKey: 'salt',
            metaValue: CryptoUtils.bytesToHex(salt),
          ),
          mode: InsertMode.insertOrReplace,
        );
        batch.insert(
          _db.vaultMetadataTable,
          VaultMetadataTableCompanion.insert(
            metaKey: 'verification_blob',
            metaValue: CryptoUtils.bytesToHex(verificationBlob),
          ),
          mode: InsertMode.insertOrReplace,
        );
        batch.deleteWhere(_db.vaultMetadataTable,
            (t) => t.metaKey.equals('open_session_key'));
      });

      _securityContext.unlock(masterKey);
      await _resetIdleTimer();

      return const Result.success(null);
    } catch (e) {
      return Result.error(VaultFailure.corrupted(e));
    }
  }

  @override
  Future<Result<void, VaultFailure>> unlockWithPassword(
      String masterPassword) async {
    try {
      final initialized = await isVaultInitialized();
      if (!initialized) {
        return Result.error(
          const VaultFailure(
            'Vault has not been initialized yet.',
            type: VaultFailureType.notFound,
          ),
        );
      }

      final saltRecord = await (_db.select(_db.vaultMetadataTable)
            ..where((t) => t.metaKey.equals('salt')))
          .getSingleOrNull();
      final verificationRecord = await (_db.select(_db.vaultMetadataTable)
            ..where((t) => t.metaKey.equals('verification_blob')))
          .getSingleOrNull();

      if (saltRecord == null || verificationRecord == null) {
        return Result.error(
            VaultFailure.corrupted('Missing vault initialization metadata'));
      }

      final salt = CryptoUtils.hexToBytes(saltRecord.metaValue);
      final verificationBlob =
          CryptoUtils.hexToBytes(verificationRecord.metaValue);

      final derivedKey = await _cryptoService.deriveMasterKey(
        password: masterPassword,
        salt: salt,
      );

      final isValid = await _cryptoService.verifyKey(
        verificationBlob: verificationBlob,
        key: derivedKey,
      );

      if (!isValid) {
        return Result.error(VaultFailure.invalidMasterPassword());
      }

      _securityContext.unlock(derivedKey);
      await _resetIdleTimer();

      return const Result.success(null);
    } catch (e) {
      return Result.error(VaultFailure.corrupted(e));
    }
  }

  @override
  Future<Result<void, VaultFailure>> unlockWithBiometrics() async {
    if (_biometricStorage == null) {
      return Result.error(VaultFailure.biometricFailed(
          'Biometrics is not supported on this platform'));
    }

    final settings = await getSettings();
    if (!settings.isBiometricsEnabled) {
      return Result.error(
          VaultFailure.biometricFailed('Biometrics is disabled in settings'));
    }

    try {
      final secret = await _biometricStorage!.readBiometricSecret();
      if (secret == null || secret.isEmpty) {
        return Result.error(
            VaultFailure.biometricFailed('Biometric key not found'));
      }

      final masterKey = SecretKey(secret);
      final verificationRecord = await (_db.select(_db.vaultMetadataTable)
            ..where((t) => t.metaKey.equals('verification_blob')))
          .getSingleOrNull();

      if (verificationRecord == null) {
        return Result.error(
            VaultFailure.corrupted('Missing verification metadata'));
      }

      final verificationBlob =
          CryptoUtils.hexToBytes(verificationRecord.metaValue);
      final isValid = await _cryptoService.verifyKey(
        verificationBlob: verificationBlob,
        key: masterKey,
      );

      VaultCryptoService.zeroize(secret);

      if (!isValid) {
        return Result.error(
            VaultFailure.biometricFailed('Invalid biometric key'));
      }

      _securityContext.unlock(masterKey);
      await _resetIdleTimer();

      return const Result.success(null);
    } catch (e) {
      return Result.error(VaultFailure.biometricFailed(e.toString()));
    }
  }

  @override
  Future<Result<void, VaultFailure>> unlockWithPin(String pin) async {
    final settings = await getSettings();
    if (!settings.isPinEnabled) {
      return Result.error(
        const VaultFailure(
          'PIN unlock is disabled in settings.',
          type: VaultFailureType.invalidPassword,
        ),
      );
    }

    try {
      final pinSaltRecord = await (_db.select(_db.vaultMetadataTable)
            ..where((t) => t.metaKey.equals('pin_salt')))
          .getSingleOrNull();
      final pinVerificationRecord = await (_db.select(_db.vaultMetadataTable)
            ..where((t) => t.metaKey.equals('pin_verification_blob')))
          .getSingleOrNull();
      final encryptedMasterKeyRecord = await (_db.select(_db.vaultMetadataTable)
            ..where((t) => t.metaKey.equals('pin_encrypted_master_key')))
          .getSingleOrNull();

      if (pinSaltRecord == null ||
          pinVerificationRecord == null ||
          encryptedMasterKeyRecord == null) {
        return Result.error(VaultFailure.corrupted('Missing PIN metadata.'));
      }

      final pinSalt = CryptoUtils.hexToBytes(pinSaltRecord.metaValue);
      final pinVerificationBlob =
          CryptoUtils.hexToBytes(pinVerificationRecord.metaValue);
      final encryptedMasterKey =
          CryptoUtils.hexToBytes(encryptedMasterKeyRecord.metaValue);

      final pinKey =
          await _cryptoService.deriveMasterKey(password: pin, salt: pinSalt);
      final isValid = await _cryptoService.verifyKey(
        verificationBlob: pinVerificationBlob,
        key: pinKey,
      );

      if (!isValid) {
        return Result.error(VaultFailure.invalidMasterPassword());
      }

      final masterKeyBytes = await _cryptoService.decryptBytes(
        encryptedData: encryptedMasterKey,
        secretKey: pinKey,
      );

      final masterKey = SecretKey(masterKeyBytes);
      VaultCryptoService.zeroize(masterKeyBytes);

      _securityContext.unlock(masterKey);
      await _resetIdleTimer();

      return const Result.success(null);
    } catch (e) {
      return Result.error(VaultFailure.invalidMasterPassword());
    }
  }

  /// Enables quick PIN unlocking by deriving a pin key and encrypting the current master key.
  Future<Result<void, VaultFailure>> enablePin(String pin) async {
    if (!_securityContext.isUnlocked ||
        _securityContext.activeMasterKey == null) {
      return Result.error(VaultFailure.locked());
    }

    try {
      final pinSalt = _cryptoService.generateRandomBytes(16);
      final pinKey =
          await _cryptoService.deriveMasterKey(password: pin, salt: pinSalt);
      final pinVerificationBlob =
          await _cryptoService.createVerificationBlob(pinKey);

      final masterKeyBytes =
          await _securityContext.activeMasterKey!.extractBytes();
      final encryptedMasterKey = await _cryptoService.encryptBytes(
        clearText: masterKeyBytes,
        secretKey: pinKey,
      );
      VaultCryptoService.zeroize(masterKeyBytes);

      await _db.batch((batch) {
        batch.insert(
          _db.vaultMetadataTable,
          VaultMetadataTableCompanion.insert(
            metaKey: 'pin_salt',
            metaValue: CryptoUtils.bytesToHex(pinSalt),
          ),
          mode: InsertMode.insertOrReplace,
        );
        batch.insert(
          _db.vaultMetadataTable,
          VaultMetadataTableCompanion.insert(
            metaKey: 'pin_verification_blob',
            metaValue: CryptoUtils.bytesToHex(pinVerificationBlob),
          ),
          mode: InsertMode.insertOrReplace,
        );
        batch.insert(
          _db.vaultMetadataTable,
          VaultMetadataTableCompanion.insert(
            metaKey: 'pin_encrypted_master_key',
            metaValue: CryptoUtils.bytesToHex(encryptedMasterKey),
          ),
          mode: InsertMode.insertOrReplace,
        );
      });

      final currentSettings = await getSettings();
      await updateSettings(currentSettings.copyWith(isPinEnabled: true));

      return const Result.success(null);
    } catch (e) {
      return Result.error(VaultFailure.corrupted(e));
    }
  }

  /// Disables quick PIN unlocking.
  Future<Result<void, VaultFailure>> disablePin() async {
    await (_db.delete(_db.vaultMetadataTable)
          ..where((t) => t.metaKey.isIn([
                'pin_salt',
                'pin_verification_blob',
                'pin_encrypted_master_key'
              ])))
        .go();

    final currentSettings = await getSettings();
    await updateSettings(currentSettings.copyWith(isPinEnabled: false));
    return const Result.success(null);
  }

  /// Enables biometric unlock by securely saving the active master key in [IBiometricStorage].
  Future<Result<void, VaultFailure>> enableBiometrics() async {
    if (_biometricStorage == null) {
      return Result.error(
          VaultFailure.biometricFailed('Biometrics is not supported'));
    }
    if (!_securityContext.isUnlocked ||
        _securityContext.activeMasterKey == null) {
      return Result.error(VaultFailure.locked());
    }

    try {
      final masterKeyBytes =
          await _securityContext.activeMasterKey!.extractBytes();
      await _biometricStorage!
          .writeBiometricSecret(Uint8List.fromList(masterKeyBytes));
      VaultCryptoService.zeroize(masterKeyBytes);

      final currentSettings = await getSettings();
      await updateSettings(currentSettings.copyWith(isBiometricsEnabled: true));

      return const Result.success(null);
    } catch (e) {
      return Result.error(VaultFailure.biometricFailed(e.toString()));
    }
  }

  /// Disables biometric unlock.
  Future<Result<void, VaultFailure>> disableBiometrics() async {
    if (_biometricStorage != null) {
      await _biometricStorage!.deleteBiometricSecret();
    }
    final currentSettings = await getSettings();
    await updateSettings(currentSettings.copyWith(isBiometricsEnabled: false));
    return const Result.success(null);
  }

  @override
  void lock() {
    _cachedSettings = null;
    _idleTimer?.cancel();
    _idleTimer = null;
    _securityContext.lock();
  }

  /// Resets the auto-lock timer if the vault is unlocked.
  /// Call this on user interaction (keypress, mouse move, terminal input).
  void recordActivity() {
    if (_securityContext.isUnlocked) {
      _resetIdleTimer();
    }
  }

  @override
  Future<Result<void, VaultFailure>> changeMasterPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    // 1. Verify current password
    final saltRecord = await (_db.select(_db.vaultMetadataTable)
          ..where((t) => t.metaKey.equals('salt')))
        .getSingleOrNull();
    final verificationRecord = await (_db.select(_db.vaultMetadataTable)
          ..where((t) => t.metaKey.equals('verification_blob')))
        .getSingleOrNull();

    if (saltRecord == null || verificationRecord == null) {
      return Result.error(
          VaultFailure.corrupted('Missing vault initialization metadata'));
    }

    final currentSalt = CryptoUtils.hexToBytes(saltRecord.metaValue);
    final currentVerificationBlob =
        CryptoUtils.hexToBytes(verificationRecord.metaValue);

    final currentDerivedKey = await _cryptoService.deriveMasterKey(
      password: currentPassword,
      salt: currentSalt,
    );

    final isValid = await _cryptoService.verifyKey(
      verificationBlob: currentVerificationBlob,
      key: currentDerivedKey,
    );

    if (!isValid) {
      return Result.error(VaultFailure.invalidMasterPassword());
    }

    try {
      // 2. Derive new master key
      final newSalt = _cryptoService.generateRandomBytes(16);
      final newMasterKey = await _cryptoService.deriveMasterKey(
        password: newPassword,
        salt: newSalt,
      );

      // 3. Re-encrypt all private keys and passphrases in KeysTable
      final allKeys = await _db.select(_db.keysTable).get();
      for (final keyRecord in allKeys) {
        try {
          // Decrypt with current key
          final decryptedPrivKey = await _cryptoService.decryptBytes(
            encryptedData: keyRecord.encryptedPrivateKey,
            secretKey: currentDerivedKey,
          );

          Uint8List? decryptedPassphrase;
          if (keyRecord.encryptedPassphrase != null) {
            decryptedPassphrase = await _cryptoService.decryptBytes(
              encryptedData: keyRecord.encryptedPassphrase!,
              secretKey: currentDerivedKey,
            );
          }

          // Re-encrypt with new key
          final reEncryptedPrivKey = await _cryptoService.encryptBytes(
            clearText: decryptedPrivKey,
            secretKey: newMasterKey,
          );
          VaultCryptoService.zeroize(decryptedPrivKey);

          Uint8List? reEncryptedPassphrase;
          if (decryptedPassphrase != null) {
            reEncryptedPassphrase = await _cryptoService.encryptBytes(
              clearText: decryptedPassphrase,
              secretKey: newMasterKey,
            );
            VaultCryptoService.zeroize(decryptedPassphrase);
          }

          // Update database row
          await (_db.update(_db.keysTable)
                ..where((t) => t.id.equals(keyRecord.id)))
              .write(
            KeysTableCompanion(
              encryptedPrivateKey: Value(reEncryptedPrivKey),
              encryptedPassphrase: Value(reEncryptedPassphrase),
              updatedAt: Value(DateTime.now()),
            ),
          );
        } catch (_) {
          // Non-fatal: ignore keys that cannot be decrypted by current key
        }
      }

      // Re-encrypt sync passphrase if present
      final settingsRecord = await (_db.select(_db.vaultSettingsTable)
            ..where((t) => t.id.equals(1)))
          .getSingleOrNull();
      if (settingsRecord?.encryptedSyncPassphrase != null) {
        try {
          final clearBytes = await _cryptoService.decryptBytes(
            encryptedData: settingsRecord!.encryptedSyncPassphrase!,
            secretKey: currentDerivedKey,
          );
          final reEncrypted = await _cryptoService.encryptBytes(
            clearText: clearBytes,
            secretKey: newMasterKey,
          );
          VaultCryptoService.zeroize(clearBytes);
          await (_db.update(_db.vaultSettingsTable)
                ..where((t) => t.id.equals(1)))
              .write(
            VaultSettingsTableCompanion(
              encryptedSyncPassphrase: Value(reEncrypted),
              syncPassphrase: const Value(null),
            ),
          );
        } catch (_) {}
      }

      // 4. Create new verification blob
      final newVerificationBlob =
          await _cryptoService.createVerificationBlob(newMasterKey);

      // 5. Update metadata
      await _db.batch((batch) {
        batch.insert(
          _db.vaultMetadataTable,
          VaultMetadataTableCompanion.insert(
            metaKey: 'salt',
            metaValue: CryptoUtils.bytesToHex(newSalt),
          ),
          mode: InsertMode.insertOrReplace,
        );
        batch.insert(
          _db.vaultMetadataTable,
          VaultMetadataTableCompanion.insert(
            metaKey: 'verification_blob',
            metaValue: CryptoUtils.bytesToHex(newVerificationBlob),
          ),
          mode: InsertMode.insertOrReplace,
        );
      });

      // 6. If biometric is enabled, update stored biometric secret
      final settings = await getSettings();
      if (settings.isBiometricsEnabled && _biometricStorage != null) {
        final newMasterKeyBytes = await newMasterKey.extractBytes();
        await _biometricStorage!
            .writeBiometricSecret(Uint8List.fromList(newMasterKeyBytes));
        VaultCryptoService.zeroize(newMasterKeyBytes);
      }

      // 7. If PIN is enabled, invalidate it to prevent stale key restoration
      if (settings.isPinEnabled) {
        await disablePin();
      }

      _securityContext.unlock(newMasterKey);
      await _resetIdleTimer();

      return const Result.success(null);
    } catch (e) {
      return Result.error(VaultFailure.corrupted(e));
    }
  }

  @override
  Future<Result<void, VaultFailure>> disableMasterPassword({
    required String currentPassword,
  }) async {
    // 1. Verify current password
    final saltRecord = await (_db.select(_db.vaultMetadataTable)
          ..where((t) => t.metaKey.equals('salt')))
        .getSingleOrNull();
    final verificationRecord = await (_db.select(_db.vaultMetadataTable)
          ..where((t) => t.metaKey.equals('verification_blob')))
        .getSingleOrNull();

    if (saltRecord == null || verificationRecord == null) {
      return Result.error(
          VaultFailure.corrupted('Missing vault initialization metadata'));
    }

    final currentSalt = CryptoUtils.hexToBytes(saltRecord.metaValue);
    final currentVerificationBlob =
        CryptoUtils.hexToBytes(verificationRecord.metaValue);

    final currentDerivedKey = await _cryptoService.deriveMasterKey(
      password: currentPassword,
      salt: currentSalt,
    );

    final isValid = await _cryptoService.verifyKey(
      verificationBlob: currentVerificationBlob,
      key: currentDerivedKey,
    );

    if (!isValid) {
      return Result.error(VaultFailure.invalidMasterPassword());
    }

    try {
      // 2. Generate random 32-byte open session key
      final openKeyBytes = _cryptoService.generateRandomBytes(32);
      final openKey = SecretKey(openKeyBytes);

      // 3. Re-encrypt all keys in KeysTable with the new open session key
      final allKeys = await _db.select(_db.keysTable).get();
      for (final keyRecord in allKeys) {
        final decryptedPrivKey = await _cryptoService.decryptBytes(
          encryptedData: keyRecord.encryptedPrivateKey,
          secretKey: currentDerivedKey,
        );

        Uint8List? decryptedPassphrase;
        if (keyRecord.encryptedPassphrase != null) {
          decryptedPassphrase = await _cryptoService.decryptBytes(
            encryptedData: keyRecord.encryptedPassphrase!,
            secretKey: currentDerivedKey,
          );
        }

        final reEncryptedPrivKey = await _cryptoService.encryptBytes(
          clearText: decryptedPrivKey,
          secretKey: openKey,
        );
        VaultCryptoService.zeroize(decryptedPrivKey);

        Uint8List? reEncryptedPassphrase;
        if (decryptedPassphrase != null) {
          reEncryptedPassphrase = await _cryptoService.encryptBytes(
            clearText: decryptedPassphrase,
            secretKey: openKey,
          );
          VaultCryptoService.zeroize(decryptedPassphrase);
        }

        await (_db.update(_db.keysTable)
              ..where((t) => t.id.equals(keyRecord.id)))
            .write(
          KeysTableCompanion(
            encryptedPrivateKey: Value(reEncryptedPrivKey),
            encryptedPassphrase: Value(reEncryptedPassphrase),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }

      // 4. Update vault metadata: remove master password artifacts and insert open_session_key
      await _db.batch((batch) {
        batch.deleteWhere(
          _db.vaultMetadataTable,
          (t) => t.metaKey.isIn([
            'is_initialized',
            'salt',
            'verification_blob',
            'pin_salt',
            'pin_verification_blob',
            'pin_encrypted_master_key',
          ]),
        );
        batch.insert(
          _db.vaultMetadataTable,
          VaultMetadataTableCompanion.insert(
            metaKey: 'open_session_key',
            metaValue: CryptoUtils.bytesToHex(openKeyBytes),
          ),
          mode: InsertMode.insertOrReplace,
        );
      });

      // 5. Cleanup biometric and PIN settings
      if (_biometricStorage != null) {
        await _biometricStorage!.deleteBiometricSecret();
      }
      final currentSettings = await getSettings();
      await updateSettings(currentSettings.copyWith(
        isBiometricsEnabled: false,
        isPinEnabled: false,
        idleLockTimeoutMinutes: 0,
      ));

      // 6. Unlock security context with open key and cancel idle timer
      _idleTimer?.cancel();
      _idleTimer = null;
      _securityContext.unlock(openKey);

      return const Result.success(null);
    } catch (e) {
      return Result.error(VaultFailure.corrupted(e));
    }
  }

  Future<SecretKey?> _getActiveOrOpenKey() async {
    if (_securityContext.isUnlocked &&
        _securityContext.activeMasterKey != null) {
      return _securityContext.activeMasterKey;
    }
    final record = await (_db.select(_db.vaultMetadataTable)
          ..where((t) => t.metaKey.equals('open_session_key')))
        .getSingleOrNull();
    if (record != null && record.metaValue.isNotEmpty) {
      return SecretKey(CryptoUtils.hexToBytes(record.metaValue));
    }
    return null;
  }

  @override
  Future<VaultSettingsEntity> getSettings() async {
    if (_cachedSettings != null) return _cachedSettings!;
    final record = await (_db.select(_db.vaultSettingsTable)
          ..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    if (record == null) {
      _cachedSettings = const VaultSettingsEntity();
      return _cachedSettings!;
    }

    String? decryptedPassphrase;
    String? decryptedGeminiApiKey;
    final activeKey = await _getActiveOrOpenKey();

    if (record.encryptedSyncPassphrase != null && activeKey != null) {
      try {
        final clearBytes = await _cryptoService.decryptBytes(
          encryptedData: record.encryptedSyncPassphrase!,
          secretKey: activeKey,
        );
        decryptedPassphrase = utf8.decode(clearBytes);
        VaultCryptoService.zeroize(clearBytes);
      } catch (_) {}
    } else if (record.syncPassphrase != null &&
        record.syncPassphrase!.isNotEmpty) {
      decryptedPassphrase = record.syncPassphrase;
      if (activeKey != null) {
        try {
          final encryptedBytes = await _cryptoService.encryptBytes(
            clearText: utf8.encode(decryptedPassphrase!),
            secretKey: activeKey,
          );
          await (_db.update(_db.vaultSettingsTable)
                ..where((t) => t.id.equals(1)))
              .write(
            VaultSettingsTableCompanion(
              encryptedSyncPassphrase: Value(encryptedBytes),
              syncPassphrase: const Value(null),
            ),
          );
        } catch (_) {}
      }
    } else if (record.encryptedSyncPassphrase != null && activeKey == null) {
      // Fallback in case raw UTF-8 bytes were written when activeKey was null
      try {
        decryptedPassphrase = utf8.decode(record.encryptedSyncPassphrase!);
      } catch (_) {}
    }

    if (record.encryptedGeminiApiKey != null && activeKey != null) {
      try {
        final clearBytes = await _cryptoService.decryptBytes(
          encryptedData: record.encryptedGeminiApiKey!,
          secretKey: activeKey,
        );
        decryptedGeminiApiKey = utf8.decode(clearBytes);
        VaultCryptoService.zeroize(clearBytes);
      } catch (_) {}
    } else if (record.geminiApiKey != null && record.geminiApiKey!.isNotEmpty) {
      decryptedGeminiApiKey = record.geminiApiKey;
      if (activeKey != null) {
        try {
          final encryptedBytes = await _cryptoService.encryptBytes(
            clearText: utf8.encode(decryptedGeminiApiKey!),
            secretKey: activeKey,
          );
          await (_db.update(_db.vaultSettingsTable)
                ..where((t) => t.id.equals(1)))
              .write(
            VaultSettingsTableCompanion(
              encryptedGeminiApiKey: Value(encryptedBytes),
              geminiApiKey: const Value(null),
            ),
          );
        } catch (_) {}
      }
    } else if (record.encryptedGeminiApiKey != null && activeKey == null) {
      // Fallback in case raw UTF-8 bytes were written when activeKey was null
      try {
        decryptedGeminiApiKey = utf8.decode(record.encryptedGeminiApiKey!);
      } catch (_) {}
    }

    final restoreWorkspaceMeta = await getMetadata('setting_restore_workspace');
    final autoReconnectMeta = await getMetadata('setting_auto_reconnect');
    final multilinePasteMeta =
        await getMetadata('setting_multiline_paste_defense');
    final clickableLinksMeta = await getMetadata('setting_clickable_links');
    final restoreWorkspace =
        restoreWorkspaceMeta == null ? true : restoreWorkspaceMeta == 'true';
    final autoReconnect = autoReconnectMeta == 'true';
    final multilinePaste =
        multilinePasteMeta == null ? true : multilinePasteMeta == 'true';
    final clickableLinks =
        clickableLinksMeta == null ? true : clickableLinksMeta == 'true';

    final settings = record
        .toEntity(
          decryptedPassphrase: decryptedPassphrase,
          decryptedGeminiApiKey: decryptedGeminiApiKey,
        )
        .copyWith(
          restoreWorkspaceSessions: restoreWorkspace,
          autoReconnectOnRestore: autoReconnect,
          multilinePasteDefense: multilinePaste,
          enableClickableLinks: clickableLinks,
        );
    _cachedSettings = settings;
    return settings;
  }

  @override
  Future<String?> getMetadata(String key) async {
    final record = await (_db.select(_db.vaultMetadataTable)
          ..where((t) => t.metaKey.equals(key)))
        .getSingleOrNull();
    return record?.metaValue;
  }

  @override
  Future<void> setMetadata(String key, String value) async {
    await _db.into(_db.vaultMetadataTable).insertOnConflictUpdate(
          VaultMetadataTableCompanion(
            metaKey: Value(key),
            metaValue: Value(value),
          ),
        );
  }

  @override
  Future<void> deleteMetadata(String key) async {
    await (_db.delete(_db.vaultMetadataTable)
          ..where((t) => t.metaKey.equals(key)))
        .go();
  }

  @override
  Future<Result<void, VaultFailure>> updateSettings(
      VaultSettingsEntity settings) async {
    try {
      Uint8List? encryptedPassphraseBytes;
      Uint8List? encryptedGeminiKeyBytes;
      final activeKey = await _getActiveOrOpenKey();

      if (settings.syncPassphrase != null &&
          settings.syncPassphrase!.isNotEmpty &&
          activeKey != null) {
        encryptedPassphraseBytes = await _cryptoService.encryptBytes(
          clearText: utf8.encode(settings.syncPassphrase!),
          secretKey: activeKey,
        );
      }

      if (settings.geminiApiKey != null &&
          settings.geminiApiKey!.isNotEmpty &&
          activeKey != null) {
        encryptedGeminiKeyBytes = await _cryptoService.encryptBytes(
          clearText: utf8.encode(settings.geminiApiKey!),
          secretKey: activeKey,
        );
      }

      await _db.into(_db.vaultSettingsTable).insertOnConflictUpdate(
            VaultSettingsTableCompanion(
              id: const Value(1),
              idleLockTimeoutMinutes: Value(settings.idleLockTimeoutMinutes),
              isBiometricsEnabled: Value(settings.isBiometricsEnabled),
              isPinEnabled: Value(settings.isPinEnabled),
              themeId: Value(settings.themeId),
              terminalFontFamily: Value(settings.terminalFontFamily),
              terminalFontSize: Value(settings.terminalFontSize),
              enableLiveLatencyPing: Value(settings.enableLiveLatencyPing),
              pingIntervalSeconds: Value(settings.pingIntervalSeconds),
              syncServerUrl: Value(settings.syncServerUrl),
              isSyncEnabled: Value(settings.isSyncEnabled),
              syncVaultId: Value(settings.syncVaultId),
              allowInsecureCertificates:
                  Value(settings.allowInsecureCertificates),
              lastSyncedAt: Value(settings.lastSyncedAt),
              encryptedSyncPassphrase: encryptedPassphraseBytes != null
                  ? Value(encryptedPassphraseBytes)
                  : const Value(null),
              syncPassphrase: activeKey == null &&
                      settings.syncPassphrase != null &&
                      settings.syncPassphrase!.isNotEmpty
                  ? Value(settings.syncPassphrase)
                  : const Value(null),
              registrationToken: Value(settings.registrationToken),
              encryptedGeminiApiKey: encryptedGeminiKeyBytes != null
                  ? Value(encryptedGeminiKeyBytes)
                  : const Value(null),
              geminiApiKey: activeKey == null &&
                      settings.geminiApiKey != null &&
                      settings.geminiApiKey!.isNotEmpty
                  ? Value(settings.geminiApiKey)
                  : const Value(null),
              geminiModelId: Value(settings.geminiModelId),
              isAiSnippetEnabled: Value(settings.isAiSnippetEnabled),
            ),
          );
      await setMetadata('setting_restore_workspace',
          settings.restoreWorkspaceSessions.toString());
      await setMetadata(
          'setting_auto_reconnect', settings.autoReconnectOnRestore.toString());
      await setMetadata('setting_multiline_paste_defense',
          settings.multilinePasteDefense.toString());
      await setMetadata(
          'setting_clickable_links', settings.enableClickableLinks.toString());
      _cachedSettings = settings;
      await _resetIdleTimer();
      return const Result.success(null);
    } catch (e) {
      return Result.error(VaultFailure.corrupted(e));
    }
  }

  Future<void> _resetIdleTimer() async {
    _idleTimer?.cancel();
    _idleTimer = null;

    if (!_securityContext.isUnlocked) return;

    try {
      final settings = await getSettings();
      if (settings.idleLockTimeoutMinutes > 0) {
        _idleTimer = Timer(
          Duration(minutes: settings.idleLockTimeoutMinutes),
          () => lock(),
        );
      }
    } catch (_) {
      // Non-critical: failure to read settings should not crash or prevent unlocking
    }
  }

  @override
  Future<void> ensureOpenSession() async {
    final initialized = await isVaultInitialized();
    if (initialized) {
      // Vault is protected with master password, remains locked until unlocked by user
      return;
    }

    final record = await (_db.select(_db.vaultMetadataTable)
          ..where((t) => t.metaKey.equals('open_session_key')))
        .getSingleOrNull();

    Uint8List keyBytes;
    if (record != null) {
      keyBytes = CryptoUtils.hexToBytes(record.metaValue);
    } else {
      keyBytes = _cryptoService.generateRandomBytes(32);
      await _db.into(_db.vaultMetadataTable).insert(
            VaultMetadataTableCompanion.insert(
              metaKey: 'open_session_key',
              metaValue: CryptoUtils.bytesToHex(keyBytes),
            ),
            mode: InsertMode.insertOrReplace,
          );
    }

    final openKey = SecretKey(keyBytes);
    _securityContext.unlock(openKey);
  }

  Future<void> dispose() async {
    _idleTimer?.cancel();
    _idleTimer = null;
    await _securityContext.dispose();
  }
}
