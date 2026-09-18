import 'dart:typed_data';
import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shellit/src/di/app_providers.dart';
import 'package:shellit/src/screens/keychain/generate_key_dialog.dart';
import 'package:shellit/src/screens/keychain/import_ssh_keys_dialog.dart';
import 'package:shellit/src/screens/keychain/keychain_screen.dart';
import 'package:ssh_network_core/ssh_network_core.dart';

class MockKeyManager implements IKeyManager {
  final List<KeyEntity> _keys = [];

  MockKeyManager([List<KeyEntity>? initialKeys]) {
    if (initialKeys != null) _keys.addAll(initialKeys);
  }

  @override
  Future<List<KeyEntity>> getAllKeys() async => List.unmodifiable(_keys);

  @override
  Stream<List<KeyEntity>> watchAllKeys() =>
      Stream.value(List.unmodifiable(_keys));

  @override
  Future<KeyEntity?> getKeyById(String id) async {
    return _keys.where((k) => k.id == id).firstOrNull;
  }

  @override
  Future<Result<void, VaultFailure>> saveKey(KeyEntity key) async {
    _keys.removeWhere((k) => k.id == key.id);
    _keys.add(key);
    return const Result.success(null);
  }

  @override
  Future<Result<void, VaultFailure>> deleteKey(String id) async {
    _keys.removeWhere((k) => k.id == id);
    return const Result.success(null);
  }

  @override
  Future<Result<List<int>, VaultFailure>> getDecryptedPrivateKey(
    String keyId,
  ) async {
    return const Result.success([1, 2, 3]);
  }

  @override
  Future<Result<String?, VaultFailure>> getDecryptedPassphrase(
    String keyId,
  ) async {
    return const Result.success(null);
  }

  @override
  Future<Result<void, VaultFailure>> savePasswordCredential({
    required String id,
    required String label,
    required String password,
  }) async {
    return const Result.success(null);
  }
}

class MockSshDiscoveryService implements SshDirectoryDiscoveryService {
  @override
  String? getDefaultSshDirectoryPath() => 'C:\\Users\\MockUser\\.ssh';

  @override
  Future<List<DiscoveredKey>> scanDirectory([String? customPath]) async {
    return [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleKey = KeyEntity(
    id: 'key_1',
    label: 'id_ed25519_prod',
    keyType: KeyType.ed25519,
    encryptedPrivateKey: Uint8List.fromList([1, 2, 3]),
    publicKey: 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG... user@host',
    fingerprint: 'SHA256:roX2tJvX92...',
    createdAt: DateTime(2026, 9, 18),
    updatedAt: DateTime(2026, 9, 18),
  );

  testWidgets('KeychainScreen displays keys and action buttons', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mockKeyManager = MockKeyManager([sampleKey]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appKeyManagerProvider.overrideWithValue(mockKeyManager)],
        child: const MaterialApp(home: KeychainScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('SSH Keychain & Certificates'), findsOneWidget);
    expect(find.text('Import ~/.ssh'), findsOneWidget);
    expect(find.text('Generate Key'), findsOneWidget);
    expect(find.text('id_ed25519_prod'), findsOneWidget);
    expect(find.text('ED25519'), findsOneWidget);
    expect(find.textContaining('SHA256:roX2tJvX92...'), findsOneWidget);
    expect(find.byTooltip('Copy Public Key'), findsOneWidget);
    expect(
      find.byTooltip('Deploy Key to Server (ssh-copy-id)'),
      findsOneWidget,
    );
  });

  testWidgets('KeychainScreen opens GenerateKeyDialog on button press', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mockKeyManager = MockKeyManager([]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appKeyManagerProvider.overrideWithValue(mockKeyManager)],
        child: const MaterialApp(home: KeychainScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Generate Key
    await tester.tap(find.text('Generate Key').first);
    await tester.pumpAndSettle();

    expect(find.byType(GenerateKeyDialog), findsOneWidget);
    expect(find.text('Generate SSH Key Pair'), findsOneWidget);
    expect(find.text('Ed25519'), findsOneWidget);
    expect(find.text('RSA 4096-bit'), findsOneWidget);
  });

  testWidgets('KeychainScreen opens ImportSshKeysDialog on button press', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mockKeyManager = MockKeyManager([]);
    final mockDiscovery = MockSshDiscoveryService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appKeyManagerProvider.overrideWithValue(mockKeyManager),
          appSshDiscoveryServiceProvider.overrideWithValue(mockDiscovery),
        ],
        child: const MaterialApp(home: KeychainScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Import ~/.ssh
    await tester.tap(find.text('Import ~/.ssh').first);
    await tester.pumpAndSettle();

    expect(find.byType(ImportSshKeysDialog), findsOneWidget);
    expect(find.text('Import from ~/.ssh'), findsWidgets);
  });
}
