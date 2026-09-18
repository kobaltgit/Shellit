import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:storage_vault/storage_vault.dart';
import 'package:test/test.dart';

void main() {
  group('VaultCryptoService', () {
    late VaultCryptoService cryptoService;

    setUp(() {
      // Use low Argon2 memory in unit tests for fast execution
      cryptoService = VaultCryptoService(
        argon2Memory: 1024,
        argon2Iterations: 2,
        argon2Parallelism: 1,
        argon2HashLength: 32,
      );
    });

    test('derives 32-byte key deterministically with same salt and password',
        () async {
      final salt = cryptoService.generateRandomBytes(16);
      final key1 = await cryptoService.deriveMasterKey(
        password: 'SuperSecretMasterPassword!123',
        salt: salt,
      );
      final key2 = await cryptoService.deriveMasterKey(
        password: 'SuperSecretMasterPassword!123',
        salt: salt,
      );

      final bytes1 = await key1.extractBytes();
      final bytes2 = await key2.extractBytes();

      expect(bytes1.length, equals(32));
      expect(bytes1, equals(bytes2));
    });

    test('different passwords or salts produce different derived keys',
        () async {
      final salt1 = cryptoService.generateRandomBytes(16);
      final salt2 = cryptoService.generateRandomBytes(16);

      final key1 = await cryptoService.deriveMasterKey(
          password: 'Password_A', salt: salt1);
      final key2 = await cryptoService.deriveMasterKey(
          password: 'Password_B', salt: salt1);
      final key3 = await cryptoService.deriveMasterKey(
          password: 'Password_A', salt: salt2);

      final bytes1 = await key1.extractBytes();
      final bytes2 = await key2.extractBytes();
      final bytes3 = await key3.extractBytes();

      expect(bytes1, isNot(equals(bytes2)));
      expect(bytes1, isNot(equals(bytes3)));
    });

    test('encryptBytes and decryptBytes roundtrip payload using AES-256-GCM',
        () async {
      final salt = cryptoService.generateRandomBytes(16);
      final masterKey = await cryptoService.deriveMasterKey(
        password: 'aes_test_password',
        salt: salt,
      );

      final originalData = utf8.encode(
          '-----BEGIN OPENSSH PRIVATE KEY-----\nMIIBOgIBAAJBA...\n-----END OPENSSH PRIVATE KEY-----');
      final encrypted = await cryptoService.encryptBytes(
        clearText: originalData,
        secretKey: masterKey,
      );

      expect(encrypted.length, greaterThan(originalData.length));

      final decrypted = await cryptoService.decryptBytes(
        encryptedData: encrypted,
        secretKey: masterKey,
      );

      expect(decrypted, equals(originalData));
    });

    test('decryptBytes fails if encrypted payload is tampered with', () async {
      final salt = cryptoService.generateRandomBytes(16);
      final key =
          await cryptoService.deriveMasterKey(password: 'pass', salt: salt);

      final encrypted = await cryptoService.encryptBytes(
        clearText: utf8.encode('Top Secret Data'),
        secretKey: key,
      );

      final tampered = Uint8List.fromList(encrypted);
      tampered[tampered.length - 1] ^= 0xFF; // flip last bit

      expect(
        () async =>
            cryptoService.decryptBytes(encryptedData: tampered, secretKey: key),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });

    test('createVerificationBlob and verifyKey with correct and incorrect keys',
        () async {
      final salt = cryptoService.generateRandomBytes(16);
      final correctKey = await cryptoService.deriveMasterKey(
          password: 'CorrectPassword', salt: salt);
      final wrongKey = await cryptoService.deriveMasterKey(
          password: 'WrongPassword', salt: salt);

      final blob = await cryptoService.createVerificationBlob(correctKey);

      final isValidWithCorrect = await cryptoService.verifyKey(
          verificationBlob: blob, key: correctKey);
      final isValidWithWrong =
          await cryptoService.verifyKey(verificationBlob: blob, key: wrongKey);

      expect(isValidWithCorrect, isTrue);
      expect(isValidWithWrong, isFalse);
    });

    test('zeroize securely wipes memory buffers', () {
      final sensitive = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
      VaultCryptoService.zeroize(sensitive);
      expect(sensitive, everyElement(equals(0)));
    });

    test('constantTimeEquals correctly compares byte lists', () {
      expect(
          VaultCryptoService.constantTimeEquals([1, 2, 3], [1, 2, 3]), isTrue);
      expect(
          VaultCryptoService.constantTimeEquals([1, 2, 3], [1, 2, 4]), isFalse);
      expect(VaultCryptoService.constantTimeEquals([1, 2], [1, 2, 3]), isFalse);
    });
  });
}
