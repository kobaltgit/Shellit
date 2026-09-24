import 'dart:async';
import 'package:cryptography/cryptography.dart';
import '../crypto/vault_crypto_service.dart';

/// Centralized security context that holds the active [SecretKey] in RAM
/// and notifies listeners of lock/unlock state changes.
class VaultSecurityContext {
  SecretKey? _activeMasterKey;
  final StreamController<bool> _lockStateController =
      StreamController<bool>.broadcast();

  /// True if the vault is currently unlocked and key is in memory.
  bool get isUnlocked => _activeMasterKey != null;

  /// Returns the current active master key or null if locked.
  SecretKey? get activeMasterKey => _activeMasterKey;

  /// Stream of lock status changes: true when unlocked, false when locked.
  Stream<bool> get lockStateStream => _lockStateController.stream;

  /// Activates the security context with derived [masterKey].
  void unlock(SecretKey masterKey) {
    _activeMasterKey = masterKey;
    _lockStateController.add(true);
  }

  /// Locks the vault and zeroizes any references.
  void lock() {
    VaultCryptoService.destroySecretKey(_activeMasterKey);
    _activeMasterKey = null;
    _lockStateController.add(false);
  }

  /// Closes the status stream controller.
  Future<void> dispose() async {
    lock();
    await _lockStateController.close();
  }
}
