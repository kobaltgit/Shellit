import 'dart:io';

import 'package:core_foundation/core_foundation.dart';
import 'package:desktop_plugin_sdk/desktop_plugin_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../di/app_providers.dart';

/// Notifier managing installed `.shellit` plugins and their disk state.
class PluginManagerNotifier extends AsyncNotifier<List<InstalledPlugin>> {
  @override
  Future<List<InstalledPlugin>> build() async {
    final loader = ref.watch(appPluginLoaderProvider);

    // Auto-install bundled docker_monitor.shellit if plugins directory is empty
    await _ensureBundledDemoPlugin(loader);

    return loader.scanInstalledPlugins();
  }

  Future<void> _ensureBundledDemoPlugin(IPluginLoader loader) async {
    try {
      final existing = await loader.scanInstalledPlugins();
      if (existing.isNotEmpty) return;

      final pluginsDir = (loader is DesktopPluginLoader)
          ? loader.pluginsDirectory
          : DesktopPluginLoader.defaultPluginsDirectory();

      final targetDir =
          Directory(p.join(pluginsDir, 'com.shellit.docker-monitor'));
      if (!targetDir.existsSync()) {
        final candidates = [
          p.join(Directory.current.path, 'packages', 'desktop_plugin_sdk',
              'assets', 'demo_plugins', 'docker_monitor.shellit'),
          p.join(Directory.current.path, '..', '..', 'packages',
              'desktop_plugin_sdk', 'assets', 'demo_plugins',
              'docker_monitor.shellit'),
          p.join(Directory.current.path, 'assets', 'demo_plugins',
              'docker_monitor.shellit'),
        ];

        for (final cand in candidates) {
          final file = File(cand);
          if (file.existsSync()) {
            await loader.installFromArchive(cand);
            break;
          }
        }
      }
    } catch (e) {
      AppLogger.w('Failed to auto-install bundled demo plugin: $e');
    }
  }

  Future<Result<InstalledPlugin, PluginFailure>> installFromArchive(
      String archivePath) async {
    final loader = ref.read(appPluginLoaderProvider);
    final result = await loader.installFromArchive(archivePath);
    if (result.isSuccess) {
      state = AsyncData(await loader.scanInstalledPlugins());
    }
    return result;
  }

  Future<Result<void, PluginFailure>> togglePlugin(
      String pluginId, bool enabled) async {
    final loader = ref.read(appPluginLoaderProvider);
    final result = await loader.togglePlugin(pluginId, enabled);
    if (result.isSuccess) {
      state = AsyncData(await loader.scanInstalledPlugins());
    }
    return result;
  }

  Future<Result<void, PluginFailure>> uninstallPlugin(String pluginId) async {
    final loader = ref.read(appPluginLoaderProvider);
    final result = await loader.uninstallPlugin(pluginId);
    if (result.isSuccess) {
      state = AsyncData(await loader.scanInstalledPlugins());
    }
    return result;
  }
}

/// Provider for installed plugins list
final pluginManagerProvider =
    AsyncNotifierProvider<PluginManagerNotifier, List<InstalledPlugin>>(() {
  return PluginManagerNotifier();
});

/// Holds the currently open sidebar plugin (null if sidebar is closed)
final activeSidebarPluginProvider = StateProvider<InstalledPlugin?>((ref) => null);
