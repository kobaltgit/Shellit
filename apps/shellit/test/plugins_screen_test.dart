import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shellit/src/plugins/plugin_manager_provider.dart';
import 'package:shellit/src/screens/plugins/plugins_screen.dart';

class TestPluginManagerNotifier extends PluginManagerNotifier {
  final List<InstalledPlugin> initial;
  TestPluginManagerNotifier(this.initial);

  @override
  Future<List<InstalledPlugin>> build() async => initial;

  @override
  Future<Result<void, PluginFailure>> togglePlugin(
      String pluginId, bool enabled) async {
    state = AsyncData(
      state.valueOrNull
              ?.map((p) => p.manifest.id == pluginId
                  ? p.copyWith(isEnabled: enabled)
                  : p)
              .toList() ??
          [],
    );
    return const Result.success(null);
  }
}

void main() {
  group('PluginsScreen Widget Tests', () {
    const sampleManifest = PluginManifest(
      id: 'com.test.docker',
      name: 'Docker Test Extension',
      version: '1.0.0',
      author: 'Tester',
      description: 'Monitors docker test containers',
      entryPoint: 'index.html',
      target: PluginTarget.sidebar,
      permissions: ['terminal:execute'],
    );

    const samplePlugin = InstalledPlugin(
      manifest: sampleManifest,
      installDirectory: '/fake/plugins/com.test.docker',
      isEnabled: true,
    );

    testWidgets('renders installed plugins and handles toggling',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pluginManagerProvider.overrideWith(
              () => TestPluginManagerNotifier([samplePlugin]),
            ),
          ],
          child: const MaterialApp(
            home: PluginsScreen(),
          ),
        ),
      );

      await tester.pump();

      // Check title and button
      expect(find.text('Desktop Plugin Extensions (.shellit)'), findsOneWidget);
      expect(find.text('Install .shellit'), findsOneWidget);

      // Check installed plugin details
      expect(find.text('Docker Test Extension'), findsOneWidget);
      expect(find.text('Monitors docker test containers'), findsOneWidget);
      expect(find.text('terminal:execute'), findsOneWidget);

      // Check toggle switch
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      final switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, isTrue);

      // Toggle switch off
      await tester.tap(switchFinder);
      await tester.pump();

      final updatedSwitch = tester.widget<Switch>(find.byType(Switch));
      expect(updatedSwitch.value, isFalse);
    });

    testWidgets('opens install dialog with .shellit prompt', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pluginManagerProvider.overrideWith(
              () => TestPluginManagerNotifier([samplePlugin]),
            ),
          ],
          child: const MaterialApp(
            home: PluginsScreen(),
          ),
        ),
      );

      await tester.pump();

      // Click install
      await tester.tap(find.text('Install .shellit'));
      await tester.pumpAndSettle();

      expect(find.text('Install Plugin Package'), findsOneWidget);
      expect(
        find.text(
          'Enter full file path to .shellit (or .zip) bundle archive:',
        ),
        findsOneWidget,
      );
    });
  });
}
