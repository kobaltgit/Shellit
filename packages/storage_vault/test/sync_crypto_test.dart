import 'package:storage_vault/storage_vault.dart';
import 'package:test/test.dart';

void main() {
  group('SyncCrypto', () {
    late SyncCrypto syncCrypto;

    setUp(() {
      syncCrypto = SyncCrypto();
    });

    test('derives consistent sync key from passphrase and vaultId', () async {
      final key1 = await syncCrypto.deriveSyncKey(
        passphrase: 'super-secret-sync-password',
        vaultId: 'vault-uuid-1234',
      );
      final key2 = await syncCrypto.deriveSyncKey(
        passphrase: 'super-secret-sync-password',
        vaultId: 'vault-uuid-1234',
      );

      final bytes1 = await key1.extractBytes();
      final bytes2 = await key2.extractBytes();

      expect(bytes1, equals(bytes2));
    });

    test('computes deterministic blind auth hash', () async {
      final key = await syncCrypto.deriveSyncKey(
        passphrase: 'my-password',
        vaultId: 'vault-42',
      );

      final hash1 = await syncCrypto.computeAuthHash(
        syncKey: key,
        vaultId: 'vault-42',
      );
      final hash2 = await syncCrypto.computeAuthHash(
        syncKey: key,
        vaultId: 'vault-42',
      );

      expect(hash1.length, equals(64)); // 32 bytes in hex
      expect(hash1, equals(hash2));
    });

    test('encrypts and decrypts entity payload roundtrip', () async {
      final key = await syncCrypto.deriveSyncKey(
        passphrase: 'secure-vault-passphrase',
        vaultId: 'v1',
      );

      final payload = {
        'id': 'host-99',
        'label': 'Production Kubernetes Worker',
        'hostname': '10.0.0.5',
        'port': 2222,
        'username': 'k8sadmin',
        'tags': '["k8s", "prod"]',
        'environment': 'production',
        'dangerousCommandProtection': true,
      };

      final encrypted = await syncCrypto.encryptPayload(
        payload: payload,
        syncKey: key,
      );

      expect(encrypted.isNotEmpty, isTrue);

      final decrypted = await syncCrypto.decryptPayload(
        encryptedBlob: encrypted,
        syncKey: key,
      );

      expect(decrypted['id'], equals('host-99'));
      expect(decrypted['label'], equals('Production Kubernetes Worker'));
      expect(decrypted['hostname'], equals('10.0.0.5'));
      expect(decrypted['port'], equals(2222));
      expect(decrypted['dangerousCommandProtection'], isTrue);
    });
  });
}
