import 'dart:io' show Platform;

/// Platform capabilities and target detection for Shellit plugins.
class PluginPlatform {
  /// Returns true if running on desktop OS (Windows, macOS, Linux).
  static bool get isDesktop {
    try {
      return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    } catch (_) {
      return false;
    }
  }

  /// Returns true if running on mobile OS (Android, iOS).
  static bool get isMobile {
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }
}
