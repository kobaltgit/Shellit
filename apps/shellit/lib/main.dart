import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:terminal_ui/terminal_ui.dart';
import 'package:window_manager/window_manager.dart';
import 'src/di/app_providers.dart';
import 'src/shellit_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final isDesktop = !kIsWeb &&
      (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  if (isDesktop) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1280, 820),
      minimumSize: Size(800, 500),
      center: true,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      title: 'Shellit',
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
    await windowManager.show();
    await windowManager.focus();
  }

  final appSupportDir = await getApplicationSupportDirectory();
  final dbDir = Directory(p.join(appSupportDir.path, 'data'));
  if (!await dbDir.exists()) {
    await dbDir.create(recursive: true);
  }
  final dbFile = File(p.join(dbDir.path, 'shellit_vault.db'));

  runApp(
    ProviderScope(
      overrides: [
        // Inject persistent database file
        vaultDatabaseFileProvider.overrideWithValue(dbFile),
        // Inject concrete storage_vault repositories into terminal_ui interface contracts
        vaultRepositoryProvider.overrideWith(
          (ref) => ref.watch(appVaultRepositoryProvider),
        ),
        hostRepositoryProvider.overrideWith(
          (ref) => ref.watch(appHostRepositoryProvider),
        ),
        keyManagerProvider.overrideWith(
          (ref) => ref.watch(appKeyManagerProvider),
        ),
        folderRepositoryProvider.overrideWith(
          (ref) => ref.watch(appFolderRepositoryProvider),
        ),
        // Inject SSH Client Service for live telemetry pinging
        sshClientServiceProvider.overrideWith(
          (ref) => ref.watch(appSshClientServiceProvider),
        ),
      ],
      child: const ShellitApp(),
    ),
  );
}
