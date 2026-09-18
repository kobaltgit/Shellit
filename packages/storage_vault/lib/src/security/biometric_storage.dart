import 'dart:typed_data';

/// Interface for platform-specific biometric secure storage (e.g. Keychain, KeyStore, DPAPI).
abstract class IBiometricStorage {
  /// Reads stored biometric secret bytes, or null if none is saved.
  Future<Uint8List?> readBiometricSecret();

  /// Saves biometric secret bytes protected by platform biometric policy.
  Future<void> writeBiometricSecret(Uint8List secret);

  /// Deletes biometric secret.
  Future<void> deleteBiometricSecret();
}

/// In-memory mock implementation of [IBiometricStorage] for unit tests.
class InMemoryBiometricStorage implements IBiometricStorage {
  Uint8List? _secret;

  @override
  Future<Uint8List?> readBiometricSecret() async => _secret;

  @override
  Future<void> writeBiometricSecret(Uint8List secret) async {
    _secret = Uint8List.fromList(secret);
  }

  @override
  Future<void> deleteBiometricSecret() async {
    _secret = null;
  }
}
