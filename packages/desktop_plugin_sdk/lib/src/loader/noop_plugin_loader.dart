import 'package:core_foundation/core_foundation.dart';

/// Lightweight No-Op implementation of [IPluginLoader] for mobile (iOS / Android) platforms.
/// Prevents runtime errors and avoids importing desktop WebView or native plugins on mobile targets.
class NoOpPluginLoader implements IPluginLoader {
  const NoOpPluginLoader();

  @override
  Future<List<InstalledPlugin>> scanInstalledPlugins() async {
    return const [];
  }

  @override
  Future<Result<InstalledPlugin, PluginFailure>> installFromArchive(
    String archiveFilePath,
  ) async {
    return Result.error(
      const PluginFailure(
        'Plugins are not supported on this platform.',
        type: PluginFailureType.unsupportedPlatform,
      ),
    );
  }

  @override
  Future<Result<void, PluginFailure>> uninstallPlugin(String pluginId) async {
    return Result.error(
      const PluginFailure(
        'Plugins are not supported on this platform.',
        type: PluginFailureType.unsupportedPlatform,
      ),
    );
  }

  @override
  Future<Result<void, PluginFailure>> togglePlugin(
      String pluginId, bool enabled) async {
    return Result.error(
      const PluginFailure(
        'Plugins are not supported on this platform.',
        type: PluginFailureType.unsupportedPlatform,
      ),
    );
  }
}

/// Alias for service naming convention
typedef NoOpPluginLoaderService = NoOpPluginLoader;
