import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:core_foundation/core_foundation.dart';

void main() {
  group('Domain Entities', () {
    test('HostEntity creation and copyWith', () {
      final now = DateTime.now();
      final host = HostEntity(
        id: 'host-1',
        label: 'Production DB',
        hostname: '192.168.1.100',
        port: 2222,
        username: 'admin',
        authType: HostAuthType.privateKey,
        environment: HostEnvironment.production,
        osType: OsType.ubuntu,
        dangerousCommandProtection: true,
        createdAt: now,
        updatedAt: now,
      );

      expect(host.isProduction, isTrue);
      expect(host.connectionTarget, equals('admin@192.168.1.100:2222'));

      final updated = host.copyWith(port: 22);
      expect(updated.port, equals(22));
      expect(updated.label, equals('Production DB'));
    });

    test('KeyEntity properties and copyWith', () {
      final now = DateTime.now();
      final key = KeyEntity(
        id: 'key-1',
        label: 'Work Ed25519',
        keyType: KeyType.ed25519,
        encryptedPrivateKey: Uint8List.fromList([1, 2, 3]),
        publicKey: 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5...',
        fingerprint: 'SHA256:abc123xyz',
        createdAt: now,
        updatedAt: now,
      );

      expect(key.hasPassphrase, isFalse);
      expect(key.keyType, equals(KeyType.ed25519));
    });

    test('FolderEntity and SnippetEntity', () {
      const folder = FolderEntity(id: 'f1', name: 'Web Servers');
      expect(folder.isRoot, isTrue);

      final now = DateTime.now();
      final snippet = SnippetEntity(
        id: 's1',
        title: 'Check Nginx',
        command: 'systemctl status nginx',
        createdAt: now,
        updatedAt: now,
      );
      expect(snippet.command, equals('systemctl status nginx'));
    });

    test('PluginManifest json roundtrip', () {
      final manifest = PluginManifest.fromJson({
        'id': 'com.shellit.docker-monitor',
        'name': 'Docker Monitor',
        'version': '1.2.0',
        'author': 'Shellit Team',
        'description': 'Container inspector',
        'entryPoint': 'index.html',
        'target': 'sidebar',
        'permissions': ['terminal:execute'],
      });

      expect(manifest.id, equals('com.shellit.docker-monitor'));
      expect(manifest.target, equals(PluginTarget.sidebar));
      expect(manifest.permissions, contains('terminal:execute'));
    });
  });
}
