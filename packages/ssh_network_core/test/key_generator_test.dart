import 'package:core_foundation/core_foundation.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:ssh_network_core/src/keys/key_generator_service.dart';
import 'package:ssh_network_core/src/keys/key_parser_service.dart';
import 'package:test/test.dart';

void main() {
  group('KeyGeneratorService', () {
    const generator = KeyGeneratorService();
    const parser = KeyParserService();

    test('generates valid Ed25519 key pair', () {
      final pair = generator.generateEd25519(comment: 'test-user@machine');

      expect(pair.keyType, KeyType.ed25519);
      expect(pair.comment, 'test-user@machine');
      expect(
          pair.privateKeyPem, contains('-----BEGIN OPENSSH PRIVATE KEY-----'));
      expect(pair.publicKeyString, startsWith('ssh-ed25519 '));
      expect(pair.publicKeyString, endsWith(' test-user@machine'));
      expect(pair.fingerprint, startsWith('SHA256:'));

      // Validate with KeyParserService
      final parsedResult = parser.parseKey(pem: pair.privateKeyPem);
      expect(parsedResult.isSuccess, isTrue);

      final parsed = parsedResult.valueOrNull!;
      expect(parsed.keyType, KeyType.ed25519);
      expect(parsed.fingerprint, pair.fingerprint);
      expect(parsed.isEncrypted, isFalse);

      // Validate with dartssh2 SSHKeyPair.fromPem
      final keys = SSHKeyPair.fromPem(pair.privateKeyPem);
      expect(keys, isNotEmpty);
      expect(keys.first.name, 'ssh-ed25519');
    });

    test('generates valid RSA key pair (2048-bit for fast test)', () {
      final pair =
          generator.generateRsa(bitLength: 2048, comment: 'rsa-test@corp');

      expect(pair.keyType, KeyType.rsa);
      expect(pair.comment, 'rsa-test@corp');
      expect(
          pair.privateKeyPem, contains('-----BEGIN OPENSSH PRIVATE KEY-----'));
      expect(pair.publicKeyString, startsWith('ssh-rsa '));
      expect(pair.publicKeyString, endsWith(' rsa-test@corp'));
      expect(pair.fingerprint, startsWith('SHA256:'));

      // Validate with KeyParserService
      final parsedResult = parser.parseKey(pem: pair.privateKeyPem);
      expect(parsedResult.isSuccess, isTrue);

      final parsed = parsedResult.valueOrNull!;
      expect(parsed.keyType, KeyType.rsa);
      expect(parsed.fingerprint, pair.fingerprint);
      expect(parsed.isEncrypted, isFalse);

      // Validate with dartssh2 SSHKeyPair.fromPem
      final keys = SSHKeyPair.fromPem(pair.privateKeyPem);
      expect(keys, isNotEmpty);
      expect(keys.first.name, 'ssh-rsa');
    });
  });
}
