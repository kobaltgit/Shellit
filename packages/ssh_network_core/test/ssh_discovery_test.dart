import 'dart:io';
import 'package:core_foundation/core_foundation.dart';
import 'package:ssh_network_core/src/keys/key_generator_service.dart';
import 'package:ssh_network_core/src/keys/ssh_directory_discovery_service.dart';
import 'package:test/test.dart';

void main() {
  group('SshDirectoryDiscoveryService', () {
    late Directory tempDir;
    const discovery = SshDirectoryDiscoveryService();
    const generator = KeyGeneratorService();

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('ssh_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('detects platform default ~/.ssh path', () {
      final path = discovery.getDefaultSshDirectoryPath();
      expect(path, isNotNull);
      expect(path, contains('.ssh'));
    });

    test('scans directory, identifies private keys and pairs with .pub',
        () async {
      // 1. Generate an Ed25519 key pair
      final keyPair = generator.generateEd25519(comment: 'deploy@server');

      // 2. Write private and public key files
      final privFile = File('${tempDir.path}/id_ed25519');
      await privFile.writeAsString(keyPair.privateKeyPem);

      final pubFile = File('${tempDir.path}/id_ed25519.pub');
      await pubFile.writeAsString(keyPair.publicKeyString);

      // 3. Write non-key files (known_hosts, config)
      final knownHosts = File('${tempDir.path}/known_hosts');
      await knownHosts.writeAsString('github.com ssh-ed25519 AAAAC3...');

      final configFile = File('${tempDir.path}/config');
      await configFile.writeAsString('Host myserver\n  HostName 1.2.3.4\n');

      // 4. Run scan on the temp directory
      final discovered = await discovery.scanDirectory(tempDir.path);

      expect(discovered.length, 1);
      final key = discovered.first;
      expect(key.fileName, 'id_ed25519');
      expect(key.keyType, KeyType.ed25519);
      expect(key.isEncrypted, isFalse);
      expect(key.publicKeyPath, isNotNull);
      expect(key.publicKeyPath!.endsWith('id_ed25519.pub'), isTrue);
      expect(key.publicKeyString, keyPair.publicKeyString);
      expect(key.fingerprint, keyPair.fingerprint);
      expect(key.comment, 'deploy@server');
    });

    test('returns empty list for non-existent directory', () async {
      final nonExistent = '${tempDir.path}/does_not_exist';
      final discovered = await discovery.scanDirectory(nonExistent);
      expect(discovered, isEmpty);
    });
  });
}
