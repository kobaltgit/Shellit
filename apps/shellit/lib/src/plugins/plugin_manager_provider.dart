import 'dart:io';

import 'package:core_foundation/core_foundation.dart';
import 'package:desktop_plugin_sdk/desktop_plugin_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../di/app_providers.dart';
import '../localization/localization_providers.dart';

/// Notifier managing installed `.shellit` plugins and their disk state.
class PluginManagerNotifier extends AsyncNotifier<List<InstalledPlugin>> {
  @override
  Future<List<InstalledPlugin>> build() async {
    final loader = ref.watch(appPluginLoaderProvider);

    // Auto-install bundled plugins (Docker Monitor & MCP Server) if missing
    await _ensureBundledPlugins(loader);

    final plugins = await loader.scanInstalledPlugins();
    await _syncLocalizationPlugins(plugins, loader);
    return plugins;
  }

  Future<void> _ensureBundledPlugins(IPluginLoader loader) async {
    try {
      final existing = await loader.scanInstalledPlugins();
      final installedIds = existing.map((p) => p.manifest.id).toSet();

      final pluginsToEnsure = [
        (
          id: 'com.shellit.docker-monitor',
          fileName: 'docker_monitor.shellit',
        ),
        (
          id: 'com.shellit.mcp-server',
          fileName: 'mcp_server.shellit',
        ),
      ];

      for (final item in pluginsToEnsure) {
        if (installedIds.contains(item.id)) continue;

        final candidates = [
          p.join(
            Directory.current.path,
            'packages',
            'desktop_plugin_sdk',
            'assets',
            'demo_plugins',
            item.fileName,
          ),
          p.join(
            Directory.current.path,
            '..',
            '..',
            'packages',
            'desktop_plugin_sdk',
            'assets',
            'demo_plugins',
            item.fileName,
          ),
          p.join(
            Directory.current.path,
            'plugins',
            item.fileName,
          ),
          p.join(
            Directory.current.path,
            '..',
            '..',
            'plugins',
            item.fileName,
          ),
          p.join(
            Directory.current.path,
            'assets',
            'demo_plugins',
            item.fileName,
          ),
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
      AppLogger.w('Failed to auto-install bundled plugins: $e');
    }
  }


  Future<void> _syncLocalizationPlugins(
    List<InstalledPlugin> plugins,
    IPluginLoader loader,
  ) async {
    if (loader is! DesktopPluginLoader) return;

    // Collect all installed and enabled localization plugins by their locale
    final activeLocales = <String, InstalledPlugin>{};
    for (final plugin in plugins) {
      if (plugin.manifest.target == PluginTarget.localization &&
          plugin.manifest.locale != null &&
          plugin.isEnabled) {
        activeLocales[plugin.manifest.locale!] = plugin;
      }
    }

    final activeLocaleNotifier = ref.read(activeLocaleProvider.notifier);
    final localizationService = ref.read(localizationServiceProvider);

    // 1. Unregister any locale that is no longer installed or has been disabled
    final currentLocales =
        List<String>.from(localizationService.availableLocales);
    for (final locale in currentLocales) {
      if (locale == 'en') continue; // Built-in English cannot be unregistered
      if (!activeLocales.containsKey(locale)) {
        activeLocaleNotifier.unregisterLanguagePack(locale);
      }
    }

    // 2. Register/update active localization packs
    for (final entry in activeLocales.entries) {
      final locale = entry.key;
      final plugin = entry.value;
      final packRes = await loader.loadLanguagePack(plugin);
      if (packRes.isSuccess) {
        activeLocaleNotifier.registerLanguagePack(
            locale, packRes.getOrThrow());
      }
    }
  }

  Future<Result<InstalledPlugin, PluginFailure>> installFromArchive(
    String archivePath,
  ) async {
    final loader = ref.read(appPluginLoaderProvider);
    final result = await loader.installFromArchive(archivePath);
    if (result.isSuccess) {
      final plugins = await loader.scanInstalledPlugins();
      await _syncLocalizationPlugins(plugins, loader);
      state = AsyncData(plugins);
    }
    return result;
  }

  Future<Result<void, PluginFailure>> togglePlugin(
    String pluginId,
    bool enabled,
  ) async {
    final loader = ref.read(appPluginLoaderProvider);
    final result = await loader.togglePlugin(pluginId, enabled);
    if (result.isSuccess) {
      final plugins = await loader.scanInstalledPlugins();
      await _syncLocalizationPlugins(plugins, loader);
      state = AsyncData(plugins);
    }
    return result;
  }

  Future<Result<void, PluginFailure>> uninstallPlugin(String pluginId) async {
    final loader = ref.read(appPluginLoaderProvider);
    final result = await loader.uninstallPlugin(pluginId);
    if (result.isSuccess) {
      final plugins = await loader.scanInstalledPlugins();
      await _syncLocalizationPlugins(plugins, loader);
      state = AsyncData(plugins);
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
final activeSidebarPluginProvider = StateProvider<InstalledPlugin?>(
  (ref) => null,
);
