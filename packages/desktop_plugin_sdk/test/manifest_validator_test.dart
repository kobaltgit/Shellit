import 'package:desktop_plugin_sdk/desktop_plugin_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('PluginManifestValidator', () {
    test('successfully validates a complete valid manifest map', () {
      final json = {
        'id': 'com.shellit.docker-monitor',
        'name': 'Docker Monitor',
        'version': '1.2.3',
        'author': 'Dev Team',
        'description': 'Monitors containers',
        'entryPoint': 'index.html',
        'target': 'sidebar',
        'permissions': ['terminal:execute', 'notifications:show'],
        'minAppVersion': '1.0.0',
      };

      final result = PluginManifestValidator.validateMap(json);
      expect(result.isSuccess, isTrue);

      final manifest = result.getOrThrow();
      expect(manifest.id, 'com.shellit.docker-monitor');
      expect(manifest.name, 'Docker Monitor');
      expect(manifest.version, '1.2.3');
      expect(manifest.entryPoint, 'index.html');
      expect(manifest.target, PluginTarget.sidebar);
      expect(manifest.permissions,
          containsAll(['terminal:execute', 'notifications:show']));
    });

    test('successfully validates from raw JSON string', () {
      const jsonStr = '''
      {
        "id": "com.developer.tool",
        "name": "Quick Tool",
        "version": "0.5.0",
        "entryPoint": "dist/index.html",
        "target": "statusbar"
      }
      ''';

      final result = PluginManifestValidator.validateString(jsonStr);
      expect(result.isSuccess, isTrue);
      final manifest = result.getOrThrow();
      expect(manifest.id, 'com.developer.tool');
      expect(manifest.target, PluginTarget.statusbar);
      expect(manifest.entryPoint, 'dist/index.html');
    });

    test('rejects missing or empty id', () {
      final json = {
        'name': 'Test Plugin',
        'entryPoint': 'index.html',
        'target': 'sidebar',
      };
      final result = PluginManifestValidator.validateMap(json);
      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message, contains("'id' is required"));
    });

    test('rejects id with invalid characters or path traversal', () {
      final invalidIds = [
        '../evil',
        'plugin/with/slash',
        'plugin\\backslash',
        'id with spaces',
        'ab', // too short (<3)
      ];

      for (final id in invalidIds) {
        final json = {
          'id': id,
          'name': 'Test Plugin',
          'entryPoint': 'index.html',
          'target': 'sidebar',
        };
        final result = PluginManifestValidator.validateMap(json);
        expect(result.isError, isTrue, reason: 'ID "$id" should be rejected');
      }
    });

    test('rejects non-semver version strings', () {
      final json = {
        'id': 'com.test.plugin',
        'name': 'Test',
        'version': 'v1.0-alpha',
        'entryPoint': 'index.html',
        'target': 'sidebar',
      };
      final result = PluginManifestValidator.validateMap(json);
      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message, contains('semantic versioning'));
    });

    test('rejects entryPoint with path traversal or absolute paths', () {
      final badEntryPoints = [
        '../../index.html',
        '/etc/passwd',
        'C:\\index.html',
        'index.exe', // bad extension
      ];

      for (final ep in badEntryPoints) {
        final json = {
          'id': 'com.test.plugin',
          'name': 'Test',
          'entryPoint': ep,
          'target': 'sidebar',
        };
        final result = PluginManifestValidator.validateMap(json);
        expect(result.isError, isTrue,
            reason: 'EntryPoint "$ep" should be rejected');
      }
    });

    test('supports all valid targets (sidebar, statusbar, modal, headless)',
        () {
      final targets = ['sidebar', 'statusbar', 'modal', 'headless'];
      for (final t in targets) {
        final json = {
          'id': 'com.test.plugin',
          'name': 'Test',
          'entryPoint': 'index.html',
          'target': t,
        };
        final result = PluginManifestValidator.validateMap(json);
        expect(result.isSuccess, isTrue);
      }
    });

    test('validates localization manifest with json entryPoint and locale', () {
      final json = {
        'id': 'com.community.lang.ru',
        'name': 'Russian Language Pack',
        'entryPoint': 'ru.json',
        'target': 'localization',
        'locale': 'ru_RU',
      };
      final result = PluginManifestValidator.validateMap(json);
      expect(result.isSuccess, isTrue);
      final manifest = result.getOrThrow();
      expect(manifest.target, PluginTarget.localization);
      expect(manifest.locale, 'ru_RU');
    });

    test('rejects localization manifest without locale or non-json entryPoint', () {
      final noLocale = {
        'id': 'com.community.lang.ru',
        'name': 'Russian Language Pack',
        'entryPoint': 'ru.json',
        'target': 'localization',
      };
      expect(PluginManifestValidator.validateMap(noLocale).isError, isTrue);

      final nonJson = {
        'id': 'com.community.lang.ru',
        'name': 'Russian Language Pack',
        'entryPoint': 'ru.html',
        'target': 'localization',
        'locale': 'ru_RU',
      };
      expect(PluginManifestValidator.validateMap(nonJson).isError, isTrue);
    });

    test('rejects invalid target', () {
      final json = {
        'id': 'com.test.plugin',
        'name': 'Test',
        'entryPoint': 'index.html',
        'target': 'floating-window',
      };
      final result = PluginManifestValidator.validateMap(json);
      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message, contains('Unknown target'));
    });

    test('rejects malformed JSON string', () {
      final result = PluginManifestValidator.validateString('{ invalid: json');
      expect(result.isError, isTrue);
      expect(result.failureOrNull?.type, PluginFailureType.invalidManifest);
    });
  });
}
