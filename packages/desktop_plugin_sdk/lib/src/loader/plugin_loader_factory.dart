import 'package:core_foundation/core_foundation.dart';

import '../platform/plugin_platform.dart';
import 'desktop_plugin_loader.dart';
import 'noop_plugin_loader.dart';

/// Factory for instantiating the appropriate [IPluginLoader] implementation.
class PluginLoaderFactory {
  /// Returns [DesktopPluginLoader] on Desktop platforms (Windows, macOS, Linux),
  /// or [NoOpPluginLoader] on Mobile platforms (Android, iOS).
  static IPluginLoader create({String? pluginsDirectory}) {
    if (PluginPlatform.isDesktop) {
      return DesktopPluginLoader(pluginsDirectory: pluginsDirectory);
    }
    return const NoOpPluginLoader();
  }
}
