import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';
import 'package:storage_vault/storage_vault.dart';
import 'package:test/test.dart';

void main() {
  group('RFC 9106 Argon2 Test Vectors', () {
    test('Argon2id Section 5.3 official test vector', () async {
      // RFC 9106 Section 5.3 specifications:
      // Memory: 32 KiB, Passes: 3, Parallelism: 4 lanes, Tag length: 32 bytes
      // Password: 32 bytes of 0x01
      // Salt: 16 bytes of 0x02
      // Secret: 8 bytes of 0x03
      // Associated data: 12 bytes of 0x04
      const memory = 32;
      const iterations = 3;
      const parallelism = 4;
      const hashLength = 32;

      final password = Uint8List(32)..fillRange(0, 32, 0x01);
      final salt = Uint8List(16)..fillRange(0, 16, 0x02);
      final secret = Uint8List(8)..fillRange(0, 8, 0x03);
      final associatedData = Uint8List(12)..fillRange(0, 12, 0x04);

      final expectedTag = Uint8List.fromList([
        0x0d,
        0x64,
        0x0d,
        0xf5,
        0x8d,
        0x78,
        0x76,
        0x6c,
        0x08,
        0xc0,
        0x37,
        0xa3,
        0x4a,
        0x8b,
        0x53,
        0xc9,
        0xd0,
        0x1e,
        0xf0,
        0x45,
        0x2d,
        0x75,
        0xb6,
        0x5e,
        0xb5,
        0x25,
        0x20,
        0xe9,
        0x6b,
        0x01,
        0xe6,
        0x59,
      ]);

      final argon2id = DartArgon2id(
        parallelism: parallelism,
        memory: memory,
        iterations: iterations,
        hashLength: hashLength,
      );

      final secretKey = SecretKey(password);
      final derived = await argon2id.deriveKey(
        secretKey: secretKey,
        nonce: salt,
        optionalSecret: secret,
        associatedData: associatedData,
      );

      final derivedBytes = await derived.extractBytes();
      expect(Uint8List.fromList(derivedBytes), equals(expectedTag));
    });

    test('Argon2i Section 5.2 official test vector', () async {
      // RFC 9106 Section 5.2 specifications:
      // Memory: 32 KiB, Passes: 3, Parallelism: 4 lanes, Tag length: 32 bytes
      const memory = 32;
      const iterations = 3;
      const parallelism = 4;
      const hashLength = 32;

      final password = Uint8List(32)..fillRange(0, 32, 0x01);
      final salt = Uint8List(16)..fillRange(0, 16, 0x02);
      final secret = Uint8List(8)..fillRange(0, 8, 0x03);
      final associatedData = Uint8List(12)..fillRange(0, 12, 0x04);

      final expectedTag = Uint8List.fromList([
        0xc8,
        0x14,
        0xd9,
        0xd1,
        0xdc,
        0x7f,
        0x37,
        0xaa,
        0x13,
        0xf0,
        0xd7,
        0x7f,
        0x24,
        0x94,
        0xbd,
        0xa1,
        0xc8,
        0xde,
        0x6b,
        0x01,
        0x6d,
        0xd3,
        0x88,
        0xd2,
        0x99,
        0x52,
        0xa4,
        0xc4,
        0x67,
        0x2b,
        0x6c,
        0xe8,
      ]);

      final state = DartArgon2State(
        mode: DartArgon2Mode.argon2i,
        parallelism: parallelism,
        memory: memory,
        iterations: iterations,
        hashLength: hashLength,
      );

      final derivedBytes = await state.deriveKeyBytes(
        password: password,
        nonce: salt,
        optionalSecret: secret,
        associatedData: associatedData,
      );

      expect(Uint8List.fromList(derivedBytes), equals(expectedTag));
    });

    test('Argon2d Section 5.1 official test vector', () async {
      // RFC 9106 Section 5.1 specifications:
      // Memory: 32 KiB, Passes: 3, Parallelism: 4 lanes, Tag length: 32 bytes
      const memory = 32;
      const iterations = 3;
      const parallelism = 4;
      const hashLength = 32;

      final password = Uint8List(32)..fillRange(0, 32, 0x01);
      final salt = Uint8List(16)..fillRange(0, 16, 0x02);
      final secret = Uint8List(8)..fillRange(0, 8, 0x03);
      final associatedData = Uint8List(12)..fillRange(0, 12, 0x04);

      final expectedTag = Uint8List.fromList([
        0x51,
        0x2b,
        0x39,
        0x1b,
        0x6f,
        0x11,
        0x62,
        0x97,
        0x53,
        0x71,
        0xd3,
        0x09,
        0x19,
        0x73,
        0x42,
        0x94,
        0xf8,
        0x68,
        0xe3,
        0xbe,
        0x39,
        0x84,
        0xf3,
        0xc1,
        0xa1,
        0x3a,
        0x4d,
        0xb9,
        0xfa,
        0xbe,
        0x4a,
        0xcb,
      ]);

      final state = DartArgon2State(
        mode: DartArgon2Mode.argon2d,
        parallelism: parallelism,
        memory: memory,
        iterations: iterations,
        hashLength: hashLength,
      );

      final derivedBytes = await state.deriveKeyBytes(
        password: password,
        nonce: salt,
        optionalSecret: secret,
        associatedData: associatedData,
      );

      expect(Uint8List.fromList(derivedBytes), equals(expectedTag));
    });
  });

  group('VaultCryptoService Memory Zeroization & SecretKey.destroy()', () {
    test(
        'deriveMasterKey returns SecretKey that can be destroyed with zeroization',
        () async {
      final cryptoService = VaultCryptoService(
        argon2Memory: 1024,
        argon2Iterations: 2,
        argon2Parallelism: 1,
        argon2HashLength: 32,
      );

      final salt = cryptoService.generateRandomBytes(16);
      final masterKey = await cryptoService.deriveMasterKey(
        password: 'TestPassword123!',
        salt: salt,
      );

      expect(masterKey.isDestroyed, isFalse);
      final bytesBefore = await masterKey.extractBytes();
      expect(bytesBefore.length, equals(32));

      // Destroy the key
      VaultCryptoService.destroySecretKey(masterKey);

      expect(masterKey.isDestroyed, isTrue);
      expect(() => (masterKey as SecretKeyData).bytes, throwsStateError);
    });

    test('destroySecretKey handles null or already destroyed keys safely', () {
      expect(() => VaultCryptoService.destroySecretKey(null), returnsNormally);

      final key = SecretKeyData(Uint8List.fromList([1, 2, 3]));
      VaultCryptoService.destroySecretKey(key);
      expect(key.isDestroyed, isTrue);

      // Calling destroy again should not throw
      expect(() => VaultCryptoService.destroySecretKey(key), returnsNormally);
    });

    test('VaultSecurityContext.lock destroys the active master key', () {
      final context = VaultSecurityContext();
      final key = SecretKeyData(Uint8List.fromList([1, 2, 3, 4, 5, 6]));

      context.unlock(key);
      expect(context.isUnlocked, isTrue);
      expect(context.activeMasterKey, equals(key));
      expect(key.isDestroyed, isFalse);

      context.lock();
      expect(context.isUnlocked, isFalse);
      expect(context.activeMasterKey, isNull);
      expect(key.isDestroyed, isTrue);
    });

    test(
        'VaultSecurityContext.unlockWithKeyBytes zeroizes source when requested',
        () {
      final context = VaultSecurityContext();
      final sourceBytes = Uint8List.fromList([10, 20, 30, 40, 50]);

      context.unlockWithKeyBytes(sourceBytes, zeroizeSource: true);
      expect(context.isUnlocked, isTrue);
      // Source buffer should have been zeroized immediately
      expect(sourceBytes, equals([0, 0, 0, 0, 0]));

      context.lock();
      expect(context.isUnlocked, isFalse);
    });

    test('VaultSecurityContext.withMasterKeyBytes zeroizes extracted buffer',
        () async {
      final context = VaultSecurityContext();
      final key = SecretKeyData(Uint8List.fromList([1, 2, 3, 4]));
      context.unlock(key);

      Uint8List? capturedBuffer;
      final result = await context.withMasterKeyBytes((bytes) {
        capturedBuffer = bytes;
        expect(bytes, equals([1, 2, 3, 4]));
        return 'executed';
      });

      expect(result, equals('executed'));
      expect(capturedBuffer, isNotNull);
      // The buffer passed to callback should now be zeroized
      expect(capturedBuffer!, equals([0, 0, 0, 0]));

      context.lock();
    });

    test('zeroize safely handles lists and fills with zeros', () {
      final buffer = Uint8List.fromList([0xAA, 0xBB, 0xCC, 0xDD]);
      VaultCryptoService.zeroize(buffer);
      expect(buffer, equals([0, 0, 0, 0]));

      final empty = Uint8List(0);
      expect(() => VaultCryptoService.zeroize(empty), returnsNormally);
    });

    test('deriveMasterKey zeroizes raw passwordBytes and salt when requested',
        () async {
      final cryptoService = VaultCryptoService(
        argon2Memory: 1024,
        argon2Iterations: 2,
        argon2Parallelism: 1,
        argon2HashLength: 32,
      );

      final passwordBytes = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      final salt = Uint8List.fromList([9, 10, 11, 12, 13, 14, 15, 16]);

      final key = await cryptoService.deriveMasterKey(
        passwordBytes: passwordBytes,
        salt: salt,
        zeroizePassword: true,
        zeroizeSalt: true,
      );

      expect(key.isDestroyed, isFalse);
      // Input buffers should be explicitly zeroized with .fillRange(0, length, 0)
      expect(passwordBytes, everyElement(equals(0)));
      expect(salt, everyElement(equals(0)));

      VaultCryptoService.destroySecretKey(key);
      expect(key.isDestroyed, isTrue);
    });

    test('deriveMasterKeyFromBytes works and zeroizes buffers when requested',
        () async {
      final cryptoService = VaultCryptoService(
        argon2Memory: 1024,
        argon2Iterations: 2,
        argon2Parallelism: 1,
        argon2HashLength: 32,
      );

      final passwordBytes = Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF]);
      final salt = Uint8List.fromList(
          [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]);

      final key = await cryptoService.deriveMasterKeyFromBytes(
        passwordBytes: passwordBytes,
        salt: salt,
        zeroizePassword: true,
        zeroizeSalt: true,
      );

      expect(key.isDestroyed, isFalse);
      expect(passwordBytes, everyElement(equals(0)));
      expect(salt, everyElement(equals(0)));

      VaultCryptoService.destroySecretKey(key);
    });

    test('withDecryptedBytes zeroizes cleartext even if action throws',
        () async {
      final cryptoService = VaultCryptoService(
        argon2Memory: 1024,
        argon2Iterations: 2,
        argon2Parallelism: 1,
        argon2HashLength: 32,
      );

      final salt = cryptoService.generateRandomBytes(16);
      final key = await cryptoService.deriveMasterKey(
        password: 'TestPassword',
        salt: salt,
      );

      final clearText = Uint8List.fromList([42, 43, 44, 45]);
      final encrypted = await cryptoService.encryptBytes(
        clearText: clearText,
        secretKey: key,
      );

      Uint8List? capturedBuffer;
      try {
        await cryptoService.withDecryptedBytes(
          encryptedData: encrypted,
          secretKey: key,
          action: (decrypted) async {
            capturedBuffer = decrypted;
            expect(decrypted, equals([42, 43, 44, 45]));
            throw Exception('Intentional failure');
          },
        );
      } catch (_) {}

      expect(capturedBuffer, isNotNull);
      // Captured buffer must be zeroized despite the thrown exception
      expect(capturedBuffer!, equals([0, 0, 0, 0]));

      VaultCryptoService.destroySecretKey(key);
    });
  });
}
