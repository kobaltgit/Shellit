import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import '../crypto/crypto_utils.dart';
import '../crypto/vault_crypto_service.dart';

/// Zero-knowledge cryptographic assistant for Shellit synchronization.
/// Handles deriving sync keys, computing blind authorization hashes,
/// and encrypting/decrypting sync item payloads using AES-256-GCM.
class SyncCrypto {
  final VaultCryptoService _cryptoService;

  SyncCrypto({VaultCryptoService? cryptoService})
      : _cryptoService = cryptoService ?? VaultCryptoService();

  /// Derives a 256-bit [SecretKey] from [passphrase] and [vaultId] salt.
  Future<SecretKey> deriveSyncKey({
    required String passphrase,
    required String vaultId,
  }) async {
    final sha256 = Sha256();
    final saltHash =
        await sha256.hash(utf8.encode('shellit_sync_salt_$vaultId'));
    return _cryptoService.deriveMasterKey(
      password: passphrase,
      salt: Uint8List.fromList(saltHash.bytes),
    );
  }

  /// Generates a blind authentication hash to present to the sync server.
  /// Server validates this hash to allow read/write, but CANNOT deduce the sync key or passphrase from it.
  Future<String> computeAuthHash({
    required SecretKey syncKey,
    required String vaultId,
  }) async {
    final keyBytes = await syncKey.extractBytes();
    final combined = <int>[
      ...keyBytes,
      ...utf8.encode('shellit_auth_salt_$vaultId'),
    ];
    final sha256 = Sha256();
    final hash = await sha256.hash(combined);
    VaultCryptoService.zeroize(keyBytes);
    return CryptoUtils.bytesToHex(hash.bytes);
  }

  /// Encrypts an arbitrary JSON-serializable Map [payload] into a binary blob.
  Future<Uint8List> encryptPayload({
    required Map<String, dynamic> payload,
    required SecretKey syncKey,
  }) async {
    final jsonStr = jsonEncode(payload);
    final utf8Bytes = utf8.encode(jsonStr);
    return _cryptoService.encryptBytes(
      clearText: utf8Bytes,
      secretKey: syncKey,
    );
  }

  /// Decrypts a binary blob produced by [encryptPayload] back into a Map.
  Future<Map<String, dynamic>> decryptPayload({
    required Uint8List encryptedBlob,
    required SecretKey syncKey,
  }) async {
    final decryptedBytes = await _cryptoService.decryptBytes(
      encryptedData: encryptedBlob,
      secretKey: syncKey,
    );
    final jsonStr = utf8.decode(decryptedBytes);
    VaultCryptoService.zeroize(decryptedBytes);
    return jsonDecode(jsonStr) as Map<String, dynamic>;
  }
}
