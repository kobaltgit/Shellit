import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:core_foundation/core_foundation.dart';
import 'package:desktop_plugin_sdk/desktop_plugin_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ssh_network_core/ssh_network_core.dart';
import 'package:storage_vault/storage_vault.dart';

/// Global root navigator key provider
final rootNavigatorKeyProvider = Provider<GlobalKey<NavigatorState>>((ref) {
  return GlobalKey<NavigatorState>();
});

/// Crypto service provider
final vaultCryptoServiceProvider = Provider<VaultCryptoService>((ref) {
  return VaultCryptoService();
});

/// Security Context provider
final vaultSecurityContextProvider = Provider<VaultSecurityContext>((ref) {
  return VaultSecurityContext();
});

/// Database file provider (overridden in main.dart on desktop/mobile)
final vaultDatabaseFileProvider = Provider<File?>((ref) => null);

/// Database instance provider
final vaultDatabaseProvider = Provider<VaultDatabase>((ref) {
  final file = ref.watch(vaultDatabaseFileProvider);
  final db = file != null
      ? VaultDatabaseConnection.openFile(file)
      : VaultDatabaseConnection.inMemory();
  ref.onDispose(() => db.close());
  return db;
});

/// Concrete Vault Repository Provider
final appVaultRepositoryProvider = Provider<IVaultRepository>((ref) {
  final db = ref.watch(vaultDatabaseProvider);
  final crypto = ref.watch(vaultCryptoServiceProvider);
  final security = ref.watch(vaultSecurityContextProvider);
  return VaultRepository(
    db: db,
    cryptoService: crypto,
    securityContext: security,
  );
});

/// Concrete Host Repository Provider
final appHostRepositoryProvider = Provider<IHostRepository>((ref) {
  final db = ref.watch(vaultDatabaseProvider);
  final security = ref.watch(vaultSecurityContextProvider);
  return HostRepository(db: db, securityContext: security);
});

/// Concrete Key Manager Provider
final appKeyManagerProvider = Provider<IKeyManager>((ref) {
  final db = ref.watch(vaultDatabaseProvider);
  final crypto = ref.watch(vaultCryptoServiceProvider);
  final security = ref.watch(vaultSecurityContextProvider);
  return KeyManager(db: db, cryptoService: crypto, securityContext: security);
});

/// Concrete Folder Repository Provider
final appFolderRepositoryProvider = Provider<IFolderRepository>((ref) {
  final db = ref.watch(vaultDatabaseProvider);
  final security = ref.watch(vaultSecurityContextProvider);
  return FolderRepository(db: db, securityContext: security);
});

/// Concrete Snippet Repository Provider
final appSnippetRepositoryProvider = Provider<ISnippetRepository>((ref) {
  final db = ref.watch(vaultDatabaseProvider);
  final security = ref.watch(vaultSecurityContextProvider);
  return SnippetRepository(db: db, securityContext: security);
});

/// Concrete Known Host Repository Provider (TOFU)
final appKnownHostRepositoryProvider = Provider<IKnownHostRepository>((ref) {
  final db = ref.watch(vaultDatabaseProvider);
  final security = ref.watch(vaultSecurityContextProvider);
  return KnownHostRepository(db: db, securityContext: security);
});

/// Vault Backup Service Provider
final appVaultBackupServiceProvider = Provider<VaultBackupService>((ref) {
  final db = ref.watch(vaultDatabaseProvider);
  final crypto = ref.watch(vaultCryptoServiceProvider);
  return VaultBackupService(db: db, cryptoService: crypto);
});

/// SSH Client Service Provider
final appSshClientServiceProvider = Provider<ISshClientService>((ref) {
  return SshClientService();
});

/// Port Forward Service Provider
final appPortForwardServiceProvider = Provider<IPortForwardService>((ref) {
  return PortForwardService();
});

/// Desktop Plugin Loader Provider
final appPluginLoaderProvider = Provider<IPluginLoader>((ref) {
  return DesktopPluginLoader();
});

/// Desktop Plugin Bridge Provider
final appPluginBridgeProvider = Provider<IPluginBridge>((ref) {
  return DesktopPluginBridge();
});

/// OS Auto-detector Provider
final appOsDetectorProvider = Provider<IOsDetector>((ref) {
  return const OsDetector();
});

/// Sync Crypto Provider
final appSyncCryptoProvider = Provider<SyncCrypto>((ref) {
  final crypto = ref.watch(vaultCryptoServiceProvider);
  return SyncCrypto(cryptoService: crypto);
});

/// Sync Manager Provider
final appSyncManagerProvider = Provider<SyncManager>((ref) {
  final db = ref.watch(vaultDatabaseProvider);
  final syncCrypto = ref.watch(appSyncCryptoProvider);
  final crypto = ref.watch(vaultCryptoServiceProvider);
  final security = ref.watch(vaultSecurityContextProvider);
  return SyncManager(
    db: db,
    syncCrypto: syncCrypto,
    cryptoService: crypto,
    securityContext: security,
  );
});

/// Key Generator Service Provider
final appKeyGeneratorServiceProvider = Provider<KeyGeneratorService>((ref) {
  return const KeyGeneratorService();
});

/// SSH Directory Discovery Service Provider
final appSshDiscoveryServiceProvider = Provider<SshDirectoryDiscoveryService>((
  ref,
) {
  return const SshDirectoryDiscoveryService();
});

/// SSH Key Deploy Service Provider (ssh-copy-id)
final appSshKeyDeployServiceProvider = Provider<SshKeyDeployService>((ref) {
  return const SshKeyDeployService();
});
