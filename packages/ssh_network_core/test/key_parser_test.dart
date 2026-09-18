import 'dart:convert';
import 'package:core_foundation/core_foundation.dart';
import 'package:ssh_network_core/ssh_network_core.dart';
import 'package:test/test.dart';

void main() {
  const parser = KeyParserService();

  const ed25519Key = '-----BEGIN OPENSSH PRIVATE KEY-----\n'
      'b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW\n'
      'QyNTUxOQAAACDZcq6d8NJFGtMgMt4ygyjm4AIQpaEyiYhV4Z7hzlAK4wAAAJAeR4bWHkeG\n'
      '1gAAAAtzc2gtZWQyNTUxOQAAACDZcq6d8NJFGtMgMt4ygyjm4AIQpaEyiYhV4Z7hzlAK4w\n'
      'AAAEAcoMr0qv1s0fhXpjqfaDSJqepL3kPID59f8d+K4oziNtlyrp3w0kUa0yAy3jKDKObg\n'
      'AhCloTKJiFXhnuHOUArjAAAADHRlc3RAc2hlbGxpdAE=\n'
      '-----END OPENSSH PRIVATE KEY-----';

  const rsaKey = '-----BEGIN RSA PRIVATE KEY-----\n'
      'MIICWwIBAAKBgQCNzwSH6pvdZYKPpuXAgwBAg9PlI5a7Vln/k4g0nPk4UBWfrPxk\n'
      'LdaDN2CZTQos9Fr6Y796kzqIKc3/UqWoxVl5WXrc1jdsALyVitbz9+B6/oCflAzD\n'
      'nSjSWfNWOpdW/7gsca4d6uVDLkhJ7mKcnur9OdHJYEtIrEYw0Yf1LgHkuQIDAQAB\n'
      'AoGAVyoHM+/+DDDn9pp0oEclcYJWTYL5lH74ZMLvNr/B5F49XF9856rRLuhsBO64\n'
      'sXclMMD9Ij+6+5UOnMDVOI7NdoEXhoxBjm0YQ8DLCv26lbsIhFbxH4I8r23TCCTj\n'
      '1KoorqOnR5XtO/ocVK86oFk9c5yjiFlQjR1biLSlFy7f0zECQQDTD4r7x0U2ualj\n'
      'tPHEy3OLzqdAPU1ga24HTsXTuvOdGHJgA8o3pip00aL1jnUGNY7dSrEoTUrhe0Ho\n'
      'WSRHDDkFAkEArACye6br14yzXsdjGkS24Zusl2swcAYTmq/dECjFsqAT4FNJbdth\n'
      'WqATX2dGyBL3Km+26U4BQzkQzrjHVOu7JQJATyCSoJYysrOkd8cMpRUJeq69MW5K\n'
      'Jg3gsEiuDhUW5ByYNLr3Ayn+3NEDYUBJS0ylBP3NsShZHHPTX8KbwS8p6QJAbwRU\n'
      'LzNh7dJGw9n1wTKwx5VvJJxuux9w79qq2I84az6fFZ8sOdfrUk8XsfA641A6cA2D\n'
      'BbrvXbArhQIGxm0QcQJAeObHdUcpFKb0X6SyKftKDRnesVaCkyXe7m4nFmtFnKbi\n'
      'baZ9S+GzjRdNI/suz0VORLxwSCj6Exb3VjiaNCeoNA==\n'
      '-----END RSA PRIVATE KEY-----';

  const ecdsaKey = '-----BEGIN OPENSSH PRIVATE KEY-----\n'
      'b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAaAAAABNlY2RzYS\n'
      '1zaGEyLW5pc3RwMjU2AAAACG5pc3RwMjU2AAAAQQS6SL6kEXirf5vsSytoJ+IRM0oXsWqM\n'
      'b1MoElaAnnU5g6dv0/L42oMee2d66F0hRWLAna1BrAyosXurD3G5SthmAAAAqDJEoxAyRK\n'
      'MQAAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLpIvqQReKt/m+xL\n'
      'K2gn4hEzShexaoxvUygSVoCedTmDp2/T8vjagx57Z3roXSFFYsCdrUGsDKixe6sPcblK2G\n'
      'YAAAAgUw+K+8dFNrmpY7TxxMtzi86nQD1NYGtuB07F07rznRgAAAANZWNkc2FAc2hlbGxp\n'
      'dAECAw==\n'
      '-----END OPENSSH PRIVATE KEY-----';

  const encryptedRsaHeader = '-----BEGIN RSA PRIVATE KEY-----\n'
      'Proc-Type: 4,ENCRYPTED\n'
      'DEK-Info: AES-128-CBC,0123456789ABCDEF0123456789ABCDEF\n\n'
      'MIICXAIBAAKBgQC6...==\n'
      '-----END RSA PRIVATE KEY-----';

  group('KeyParserService - Algorithm Detection & Parsing', () {
    test('parses unencrypted Ed25519 PEM key correctly', () {
      expect(parser.detectKeyType(ed25519Key), equals(KeyType.ed25519));
      expect(parser.isEncrypted(ed25519Key), isFalse);

      final result = parser.parseKey(pem: ed25519Key);
      expect(result.isSuccess, isTrue);

      final info = result.getOrThrow();
      expect(info.keyType, equals(KeyType.ed25519));
      expect(info.isEncrypted, isFalse);
      expect(info.publicKeyString, startsWith('ssh-ed25519 '));
      expect(info.fingerprint, startsWith('SHA256:'));
      expect(info.keyPairs, isNotEmpty);
    });

    test('parses unencrypted Ed25519 from raw bytes', () {
      final bytes = utf8.encode(ed25519Key);
      final result = parser.parseKeyBytes(bytes: bytes);
      expect(result.isSuccess, isTrue);
      expect(result.getOrThrow().keyType, equals(KeyType.ed25519));
    });

    test('parses unencrypted RSA PKCS#1 PEM key correctly', () {
      expect(parser.detectKeyType(rsaKey), equals(KeyType.rsa));
      expect(parser.isEncrypted(rsaKey), isFalse);

      final result = parser.parseKey(pem: rsaKey);
      expect(result.isSuccess, isTrue);

      final info = result.getOrThrow();
      expect(info.keyType, equals(KeyType.rsa));
      expect(info.isEncrypted, isFalse);
      expect(info.publicKeyString, startsWith('ssh-rsa '));
      expect(info.fingerprint, startsWith('SHA256:'));
    });

    test('parses unencrypted ECDSA OpenSSH key correctly', () {
      expect(parser.detectKeyType(ecdsaKey), equals(KeyType.ecdsa));
      expect(parser.isEncrypted(ecdsaKey), isFalse);

      final result = parser.parseKey(pem: ecdsaKey);
      expect(result.isSuccess, isTrue);

      final info = result.getOrThrow();
      expect(info.keyType, equals(KeyType.ecdsa));
      expect(info.publicKeyString, startsWith('ecdsa-sha2-nistp256 '));
      expect(info.fingerprint, startsWith('SHA256:'));
    });
  });

  group('KeyParserService - Encryption & Error Handling', () {
    test('detects encrypted key from DEK-Info header', () {
      expect(parser.isEncrypted(encryptedRsaHeader), isTrue);
    });

    test('returns failure when encrypted key has no passphrase', () {
      final result = parser.parseKey(pem: encryptedRsaHeader);
      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message, contains('passphrase'));
    });

    test('returns failure for empty key string', () {
      final result = parser.parseKey(pem: '   \n\t  ');
      expect(result.isError, isTrue);
      expect(
          result.failureOrNull?.type, equals(NetworkFailureType.keyParseError));
    });

    test('returns failure for malformed key string', () {
      final result = parser.parseKey(
        pem:
            '-----BEGIN RSA PRIVATE KEY-----\ninvalid_content\n-----END RSA PRIVATE KEY-----',
      );
      expect(result.isError, isTrue);
      expect(
          result.failureOrNull?.type, equals(NetworkFailureType.keyParseError));
    });

    test('formats public key with custom comment', () {
      final res = parser.parseKey(pem: ed25519Key);
      final info = res.getOrThrow();
      final formatted =
          parser.formatPublicKey(info.primaryKeyPair, comment: 'deploy@prod');
      expect(formatted, endsWith(' deploy@prod'));
    });
  });
}
