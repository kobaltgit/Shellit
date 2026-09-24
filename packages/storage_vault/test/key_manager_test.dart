import 'dart:convert';
import 'dart:typed_data';
import 'package:core_foundation/core_foundation.dart';
import 'package:storage_vault/storage_vault.dart';
import 'package:test/test.dart';

void main() {
  group('KeyManager', () {
    late VaultDatabase db;
    late VaultSecurityContext securityContext;
    late VaultCryptoService cryptoService;
    late VaultRepository vaultRepository;
    late KeyManager keyManager;

    setUp(() async {
      db = VaultDatabaseConnection.inMemory();
      securityContext = VaultSecurityContext();
      cryptoService = VaultCryptoService(
        argon2Memory: 1024,
        argon2Iterations: 2,
        argon2Parallelism: 1,
        argon2HashLength: 32,
      );

      vaultRepository = VaultRepository(
        db: db,
        cryptoService: cryptoService,
        securityContext: securityContext,
      );

      keyManager = KeyManager(
        db: db,
        cryptoService: cryptoService,
        securityContext: securityContext,
      );

      await vaultRepository.initializeVault('MasterPass');
    });

    tearDown(() async {
      await vaultRepository.dispose();
      await db.close();
    });

    test(
        'encryptAndSaveKey safely encrypts and stores private key and passphrase',
        () async {
      const rawPem =
          '-----BEGIN EC PRIVATE KEY-----\nMHcCAQEEIBX...\n-----END EC PRIVATE KEY-----';
      const rawPass = 'SecretPassphrase123!';

      final result = await keyManager.encryptAndSaveKey(
        id: 'key-1',
        label: 'My Prod Key',
        keyType: KeyType.ecdsa,
        rawPrivateKey: utf8.encode(rawPem),
        publicKey: 'ecdsa-sha2-nistp256 AAAAE2VjZHNh...',
        rawPassphrase: rawPass,
        fingerprint: 'SHA256:abc123xyz',
      );

      expect(result.isSuccess, isTrue);
      final keyEntity = result.valueOrNull!;
      expect(keyEntity.id, equals('key-1'));
      expect(keyEntity.label, equals('My Prod Key'));
      expect(keyEntity.encryptedPrivateKey, isNot(equals(utf8.encode(rawPem))));

      // Decrypt private key
      final decryptedKeyResult =
          await keyManager.getDecryptedPrivateKey('key-1');
      expect(decryptedKeyResult.isSuccess, isTrue);
      expect(utf8.decode(decryptedKeyResult.valueOrNull!), equals(rawPem));

      // Decrypt passphrase
      final decryptedPassResult =
          await keyManager.getDecryptedPassphrase('key-1');
      expect(decryptedPassResult.isSuccess, isTrue);
      expect(decryptedPassResult.valueOrNull, equals(rawPass));
    });

    test('savePasswordCredential stores and retrieves encrypted password',
        () async {
      final res = await keyManager.savePasswordCredential(
        id: 'pwd-server-01',
        label: 'Password for Server 01',
        password: 'SuperSecretSSHPassword!',
      );
      expect(res.isSuccess, isTrue);

      final decrypted =
          await keyManager.getDecryptedPassphrase('pwd-server-01');
      expect(decrypted.isSuccess, isTrue);
      expect(decrypted.valueOrNull, equals('SuperSecretSSHPassword!'));
    });

    test('getDecryptedPrivateKey fails when vault is locked', () async {
      await keyManager.encryptAndSaveKey(
        id: 'key-locked',
        label: 'Locked Test',
        keyType: KeyType.ed25519,
        rawPrivateKey: utf8.encode('priv-key-bytes'),
        publicKey: 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5...',
      );

      vaultRepository.lock();

      final result = await keyManager.getDecryptedPrivateKey('key-locked');
      expect(result.isError, isTrue);
      expect(result.failureOrNull?.type, equals(VaultFailureType.locked));
    });

    test('deleteKey removes key from database', () async {
      await keyManager.encryptAndSaveKey(
        id: 'key-to-del',
        label: 'To Delete',
        keyType: KeyType.ed25519,
        rawPrivateKey: utf8.encode('priv-key'),
        publicKey: 'pub-key',
      );

      final delResult = await keyManager.deleteKey('key-to-del');
      expect(delResult.isSuccess, isTrue);

      final key = await keyManager.getKeyById('key-to-del');
      expect(key, isNull);
    });

    test('byte-based passphrase and key APIs correctly zeroize buffers',
        () async {
      final pwdBytes = Uint8List.fromList(utf8.encode('BytePassword123!'));
      final saveRes = await keyManager.savePasswordCredentialBytes(
        id: 'pwd-byte-1',
        label: 'Byte Password Credential',
        passwordBytes: pwdBytes,
        zeroizePasswordBytes: true,
      );
      expect(saveRes.isSuccess, isTrue);
      // Source buffer should have been zeroized
      expect(pwdBytes, everyElement(equals(0)));

      // Test withDecryptedPassphraseBytes
      Uint8List? capturedPassphrase;
      final passRes =
          await keyManager.withDecryptedPassphraseBytes('pwd-byte-1', (bytes) {
        capturedPassphrase = bytes;
        expect(utf8.decode(bytes!), equals('BytePassword123!'));
        return true;
      });
      expect(passRes.isSuccess, isTrue);
      expect(passRes.valueOrNull, isTrue);
      // Decrypted buffer should have been zeroized after execution
      expect(capturedPassphrase, isNotNull);
      expect(capturedPassphrase!, everyElement(equals(0)));

      // Save a private key
      final privKey = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      await keyManager.encryptAndSaveKey(
        id: 'key-byte-1',
        label: 'Byte Key',
        keyType: KeyType.ed25519,
        rawPrivateKey: privKey,
        publicKey: 'pub-test',
      );

      // Test withDecryptedPrivateKey
      Uint8List? capturedKey;
      final keyRes =
          await keyManager.withDecryptedPrivateKey('key-byte-1', (bytes) {
        capturedKey = bytes;
        expect(bytes, equals([1, 2, 3, 4, 5, 6, 7, 8]));
        return 42;
      });
      expect(keyRes.isSuccess, isTrue);
      expect(keyRes.valueOrNull, equals(42));
      // Decrypted key buffer should have been zeroized after execution
      expect(capturedKey, isNotNull);
      expect(capturedKey!, everyElement(equals(0)));
    });
  });
}
