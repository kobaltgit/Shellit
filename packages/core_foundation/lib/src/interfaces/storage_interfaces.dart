import '../common/failures.dart';
import '../common/result.dart';
import '../domain/entities/folder_entity.dart';
import '../domain/entities/host_entity.dart';
import '../domain/entities/key_entity.dart';
import '../domain/entities/snippet_entity.dart';
import '../domain/entities/vault_settings_entity.dart';

/// Contract for master-password and vault encryption management.
abstract class IVaultRepository {
  /// True if the database has been initialized with a master password.
  Future<bool> isVaultInitialized();

  /// True if the vault is currently unlocked and encryption key is in memory.
  bool get isVaultUnlocked;

  /// Stream of lock status changes.
  Stream<bool> watchUnlockStatus();

  /// Initializes a new vault with master password (derives key via Argon2id).
  Future<Result<void, VaultFailure>> initializeVault(String masterPassword);

  /// Unlocks the vault using the master password.
  Future<Result<void, VaultFailure>> unlockWithPassword(String masterPassword);

  /// Unlocks the vault using OS biometrics (Windows Hello / Touch ID / Face ID).
  Future<Result<void, VaultFailure>> unlockWithBiometrics();

  /// Unlocks the vault using quick PIN code.
  Future<Result<void, VaultFailure>> unlockWithPin(String pin);

  /// Locks the vault and zeroizes encryption keys from RAM.
  void lock();

  /// Changes the master password, re-encrypting the database key.
  Future<Result<void, VaultFailure>> changeMasterPassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Ensures an open/unprotected vault session is active if no master password has been set.
  /// If the vault has been initialized with a master password, this is a no-op.
  Future<void> ensureOpenSession();

  /// Reads current vault settings.
  Future<VaultSettingsEntity> getSettings();

  /// Updates vault settings.
  Future<Result<void, VaultFailure>> updateSettings(
      VaultSettingsEntity settings);
}

/// Contract for Host operations.
abstract class IHostRepository {
  Future<List<HostEntity>> getAllHosts();
  Stream<List<HostEntity>> watchAllHosts();
  Future<HostEntity?> getHostById(String id);
  Future<Result<void, VaultFailure>> saveHost(HostEntity host);
  Future<Result<void, VaultFailure>> deleteHost(String id);
  Future<void> updateHostLatency(String hostId, int latencyMs);
}

/// Contract for SSH Key management and decryption.
abstract class IKeyManager {
  Future<List<KeyEntity>> getAllKeys();
  Stream<List<KeyEntity>> watchAllKeys();
  Future<KeyEntity?> getKeyById(String id);
  Future<Result<void, VaultFailure>> saveKey(KeyEntity key);
  Future<Result<void, VaultFailure>> deleteKey(String id);

  /// Safely returns the decrypted private key bytes in PEM format.
  /// Implementations MUST zeroize buffer after caller is done.
  Future<Result<List<int>, VaultFailure>> getDecryptedPrivateKey(String keyId);

  /// Safely returns the decrypted passphrase if protected.
  Future<Result<String?, VaultFailure>> getDecryptedPassphrase(String keyId);

  /// Safely encrypts and stores a password or passphrase credential.
  Future<Result<void, VaultFailure>> savePasswordCredential({
    required String id,
    required String label,
    required String password,
  });
}

/// Contract for Folders.
abstract class IFolderRepository {
  Future<List<FolderEntity>> getAllFolders();
  Stream<List<FolderEntity>> watchAllFolders();
  Future<Result<void, VaultFailure>> saveFolder(FolderEntity folder);
  Future<Result<void, VaultFailure>> deleteFolder(String id);
}

/// Contract for Snippets.
abstract class ISnippetRepository {
  Future<List<SnippetEntity>> getAllSnippets();
  Stream<List<SnippetEntity>> watchAllSnippets();
  Future<Result<void, VaultFailure>> saveSnippet(SnippetEntity snippet);
  Future<Result<void, VaultFailure>> deleteSnippet(String id);
}
