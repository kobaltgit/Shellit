import 'package:desktop_plugin_sdk/desktop_plugin_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('NoOp Implementations for Mobile Targets', () {
    test(
        'NoOpPluginLoader returns safe defaults and unsupportedPlatform errors',
        () async {
      const loader = NoOpPluginLoader();

      final scanned = await loader.scanInstalledPlugins();
      expect(scanned, isEmpty);

      final installResult =
          await loader.installFromArchive('test.shell-plugin');
      expect(installResult.isError, isTrue);
      expect(installResult.failureOrNull?.type,
          PluginFailureType.unsupportedPlatform);

      final uninstallResult =
          await loader.uninstallPlugin('com.example.plugin');
      expect(uninstallResult.isError, isTrue);
      expect(uninstallResult.failureOrNull?.type,
          PluginFailureType.unsupportedPlatform);

      final toggleResult =
          await loader.togglePlugin('com.example.plugin', true);
      expect(toggleResult.isError, isTrue);
      expect(toggleResult.failureOrNull?.type,
          PluginFailureType.unsupportedPlatform);
    });

    test('NoOpPluginBridge returns empty stream and accepts messages as no-op',
        () async {
      const bridge = NoOpPluginBridge();

      expect(() => bridge.postMessageToPlugin('any', {'key': 'val'}),
          returnsNormally);

      final stream = bridge.onMessageFromPlugin('any');
      final list = await stream.toList();
      expect(list, isEmpty);
    });

    test('PluginLoaderFactory creates DesktopPluginLoader on desktop', () {
      final loader = PluginLoaderFactory.create();
      if (PluginPlatform.isDesktop) {
        expect(loader, isA<DesktopPluginLoader>());
      } else {
        expect(loader, isA<NoOpPluginLoader>());
      }
    });
  });
}
