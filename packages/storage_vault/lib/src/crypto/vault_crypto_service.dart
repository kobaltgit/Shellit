import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// Service providing Argon2id key derivation, AES-256-GCM authenticated
/// encryption/decryption, secure random generation, and memory zeroization.
class VaultCryptoService {
  final int argon2Memory;
  final int argon2Iterations;
  final int argon2Parallelism;
  final int argon2HashLength;

  /// Verification token string to validate master password integrity.
  static const String verificationToken = 'SHELLIT_VAULT_TOKEN_V1';

  VaultCryptoService({
    this.argon2Memory = 19456, // 19 MB standard Argon2id memory
    this.argon2Iterations = 2,
    this.argon2Parallelism = 1,
    this.argon2HashLength = 32,
  });

  /// Derives a 256-bit [SecretKey] from [password] and [salt] via Argon2id.
  Future<SecretKey> deriveMasterKey({
    required String password,
    required Uint8List salt,
  }) async {
    final argon2id = Argon2id(
      parallelism: argon2Parallelism,
      memory: argon2Memory,
      iterations: argon2Iterations,
      hashLength: argon2HashLength,
    );

    final passwordBytes = Uint8List.fromList(utf8.encode(password));
    final passwordKey = SecretKeyData(
      passwordBytes,
      overwriteWhenDestroyed: true,
    );
    try {
      final derived = await argon2id.deriveKey(
        secretKey: passwordKey,
        nonce: salt,
      );
      final derivedBytes = await derived.extractBytes();
      final secureDerivedKey = SecretKeyData(
        Uint8List.fromList(derivedBytes),
        overwriteWhenDestroyed: true,
      );
      derived.destroy();
      return secureDerivedKey;
    } finally {
      passwordKey.destroy();
      zeroize(passwordBytes);
    }
  }

  /// Encrypts [clearText] using AES-256-GCM with [secretKey].
  /// Output format: [12-byte Nonce | 16-byte MAC | Ciphertext].
  Future<Uint8List> encryptBytes({
    required List<int> clearText,
    required SecretKey secretKey,
  }) async {
    final algorithm = AesGcm.with256bits();
    final nonce = algorithm.newNonce();
    final secretBox = await algorithm.encrypt(
      clearText,
      secretKey: secretKey,
      nonce: nonce,
    );

    final macBytes = secretBox.mac.bytes;
    final cipherText = secretBox.cipherText;

    final output =
        Uint8List(nonce.length + macBytes.length + cipherText.length);
    output.setRange(0, nonce.length, nonce);
    output.setRange(nonce.length, nonce.length + macBytes.length, macBytes);
    output.setRange(nonce.length + macBytes.length, output.length, cipherText);

    return output;
  }

  /// Decrypts encrypted bytes produced by [encryptBytes].
  /// Throws [SecretBoxAuthenticationError] or [ArgumentError] if invalid or corrupted.
  Future<Uint8List> decryptBytes({
    required Uint8List encryptedData,
    required SecretKey secretKey,
  }) async {
    const nonceLength = 12;
    const macLength = 16;
    if (encryptedData.length < nonceLength + macLength) {
      throw ArgumentError(
          'Encrypted payload is too short: ${encryptedData.length} bytes');
    }

    final nonce = encryptedData.sublist(0, nonceLength);
    final macBytes =
        encryptedData.sublist(nonceLength, nonceLength + macLength);
    final cipherText = encryptedData.sublist(nonceLength + macLength);

    final algorithm = AesGcm.with256bits();
    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    final clearText = await algorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    return Uint8List.fromList(clearText);
  }

  /// Creates a verification blob by encrypting [verificationToken] with [key].
  Future<Uint8List> createVerificationBlob(SecretKey key) async {
    return encryptBytes(
      clearText: utf8.encode(verificationToken),
      secretKey: key,
    );
  }

  /// Validates if [key] can successfully decrypt [verificationBlob] to [verificationToken].
  Future<bool> verifyKey({
    required Uint8List verificationBlob,
    required SecretKey key,
  }) async {
    try {
      final decrypted = await decryptBytes(
        encryptedData: verificationBlob,
        secretKey: key,
      );
      final text = utf8.decode(decrypted, allowMalformed: false);
      final isMatch = constantTimeEquals(
        utf8.encode(text),
        utf8.encode(verificationToken),
      );
      zeroize(decrypted);
      return isMatch;
    } catch (_) {
      return false;
    }
  }

  /// Generates cryptographically secure random bytes of given [length].
  Uint8List generateRandomBytes(int length) {
    final rng = Random.secure();
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = rng.nextInt(256);
    }
    return bytes;
  }

  /// Securely overwrites a byte buffer with zeros to purge sensitive data from RAM.
  /// If the list is unmodifiable (e.g. UnmodifiableUint8ListView from package:cryptography),
  /// mutation is safely skipped.
  static void zeroize(List<int> buffer) {
    try {
      buffer.fillRange(0, buffer.length, 0);
    } on UnsupportedError {
      // Buffer is unmodifiable, cannot zeroize in-place.
    } catch (_) {
      try {
        for (var i = 0; i < buffer.length; i++) {
          buffer[i] = 0;
        }
      } catch (_) {}
    }
  }

  /// Safely destroys a [SecretKey] by invoking its [SecretKey.destroy] method.
  /// If the key is backed by [SecretKeyData] with [overwriteWhenDestroyed],
  /// this also purges and zeroizes its underlying bytes from memory.
  static void destroySecretKey(SecretKey? key) {
    if (key == null || key.isDestroyed) return;
    try {
      key.destroy();
    } catch (_) {
      // In case destroy throws or is unsupported.
    }
  }

  /// Performs a constant-time comparison of two byte sequences to prevent timing attacks.
  static bool constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}
