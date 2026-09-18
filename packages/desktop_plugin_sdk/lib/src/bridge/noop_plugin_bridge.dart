import 'package:core_foundation/core_foundation.dart';

/// Lightweight No-Op implementation of [IPluginBridge] for mobile (iOS / Android) platforms.
class NoOpPluginBridge implements IPluginBridge {
  const NoOpPluginBridge();

  @override
  void postMessageToPlugin(String pluginId, Map<String, dynamic> message) {
    // No-op on mobile targets
  }

  @override
  Stream<Map<String, dynamic>> onMessageFromPlugin(String pluginId) {
    return const Stream.empty();
  }
}
