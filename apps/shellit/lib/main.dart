import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:terminal_ui/terminal_ui.dart';
import 'src/di/app_providers.dart';
import 'src/shellit_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        // Inject SSH Client Service for live telemetry pinging
        sshClientServiceProvider.overrideWith(
          (ref) => ref.watch(appSshClientServiceProvider),
        ),
      ],
      child: const ShellitApp(),
    ),
  );
}
