import 'dart:async';
import 'dart:typed_data';
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
    if (_activeMasterKey != null && !identical(_activeMasterKey, masterKey)) {
      VaultCryptoService.destroySecretKey(_activeMasterKey);
    }
    _activeMasterKey = masterKey;
    _lockStateController.add(true);
  }

  /// Activates the security context directly from raw master key bytes.
  ///
  /// The key is stored as a [SecretKeyData] with `overwriteWhenDestroyed: true`.
  /// If [zeroizeSource] is true, [keyBytes] will be explicitly zeroized immediately.
  void unlockWithKeyBytes(Uint8List keyBytes, {bool zeroizeSource = false}) {
    final copy = Uint8List.fromList(keyBytes);
    final key = SecretKeyData(copy, overwriteWhenDestroyed: true);
    unlock(key);
    if (zeroizeSource) {
      VaultCryptoService.zeroize(keyBytes);
    }
  }

  /// Safely executes [action] with the extracted master key bytes, guaranteeing
  /// that the extracted key bytes buffer is zeroized with [fillRange] immediately afterwards.
  Future<T?> withMasterKeyBytes<T>(
      FutureOr<T> Function(Uint8List keyBytes) action) async {
    if (_activeMasterKey == null) return null;
    final extracted = await _activeMasterKey!.extractBytes();
    final keyBuffer = Uint8List.fromList(extracted);
    try {
      return await action(keyBuffer);
    } finally {
      VaultCryptoService.zeroize(keyBuffer);
      VaultCryptoService.zeroize(extracted);
    }
  }

  /// Safely executes [action] with the active [SecretKey] if unlocked.
  FutureOr<T?> withMasterKey<T>(
      FutureOr<T> Function(SecretKey masterKey) action) {
    if (_activeMasterKey == null) return null;
    return action(_activeMasterKey!);
  }

  /// Locks the vault and explicitly calls [SecretKey.destroy()] on the active key
  /// to ensure raw key material is immediately purged and zeroized from RAM.
  void lock() {
    final keyToDestroy = _activeMasterKey;
    _activeMasterKey = null;
    if (keyToDestroy != null) {
      try {
        keyToDestroy.destroy();
      } catch (_) {}
      VaultCryptoService.destroySecretKey(keyToDestroy);
    }
    _lockStateController.add(false);
  }

  /// Closes the status stream controller and locks the vault.
  Future<void> dispose() async {
    lock();
    await _lockStateController.close();
  }
}
