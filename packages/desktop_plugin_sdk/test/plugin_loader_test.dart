import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:desktop_plugin_sdk/desktop_plugin_sdk.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('DesktopPluginLoader Lifecycle & Management', () {
    late Directory tempPluginsDir;
    late Directory tempWorkDir;
    late DesktopPluginLoader loader;

    setUp(() {
      tempPluginsDir = Directory.systemTemp.createTempSync('shellit_plugins_');
      tempWorkDir = Directory.systemTemp.createTempSync('shellit_work_');
      loader = DesktopPluginLoader(pluginsDirectory: tempPluginsDir.path);
    });

    tearDown(() {
      if (tempPluginsDir.existsSync()) {
        tempPluginsDir.deleteSync(recursive: true);
      }
      if (tempWorkDir.existsSync()) {
        tempWorkDir.deleteSync(recursive: true);
      }
    });

    test('scans empty directory and returns empty list', () async {
      final plugins = await loader.scanInstalledPlugins();
      expect(plugins, isEmpty);
    });

    test('packs and installs Docker Monitor demo plugin', () async {
      final demoPluginDir = p.join(
          Directory.current.path, 'assets', 'demo_plugins', 'docker_monitor');
      expect(Directory(demoPluginDir).existsSync(), isTrue);

      final archivePath = p.join(tempWorkDir.path, 'docker_monitor.shellit');

      // Pack
      final packResult = await PluginPacker.packDirectory(
        sourceDir: demoPluginDir,
        outputFilePath: archivePath,
      );
      expect(packResult.isSuccess, isTrue);

      // Install
      final installResult = await loader.installFromArchive(archivePath);
      expect(installResult.isSuccess, isTrue);

      final installed = installResult.getOrThrow();
      expect(installed.manifest.id, 'com.shellit.docker-monitor');
      expect(installed.manifest.name, 'Docker Container Monitor');
      expect(installed.manifest.target, PluginTarget.sidebar);
      expect(installed.isEnabled, isTrue);

      // Verify files installed on disk
      final installedIndex =
          File(p.join(installed.installDirectory, 'index.html'));
      expect(installedIndex.existsSync(), isTrue);

      // Scan
      final scannedList = await loader.scanInstalledPlugins();
      expect(scannedList.length, 1);
      expect(scannedList.first.manifest.id, 'com.shellit.docker-monitor');
      expect(scannedList.first.isEnabled, isTrue);
    });

    test('toggles plugin enabled status and persists state', () async {
      final demoPluginDir = p.join(
          Directory.current.path, 'assets', 'demo_plugins', 'docker_monitor');
      final archivePath = p.join(tempWorkDir.path, 'docker_monitor.shellit');

      await PluginPacker.packDirectory(
        sourceDir: demoPluginDir,
        outputFilePath: archivePath,
      );

      final installResult = await loader.installFromArchive(archivePath);
      final plugin = installResult.getOrThrow();

      // Disable
      final disableResult =
          await loader.togglePlugin(plugin.manifest.id, false);
      expect(disableResult.isSuccess, isTrue);

      var scanned = await loader.scanInstalledPlugins();
      expect(scanned.first.isEnabled, isFalse);

      // Enable again
      final enableResult = await loader.togglePlugin(plugin.manifest.id, true);
      expect(enableResult.isSuccess, isTrue);

      scanned = await loader.scanInstalledPlugins();
      expect(scanned.first.isEnabled, isTrue);
    });

    test('uninstalls plugin cleanly from disk and state', () async {
      final demoPluginDir = p.join(
          Directory.current.path, 'assets', 'demo_plugins', 'docker_monitor');
      final archivePath = p.join(tempWorkDir.path, 'docker_monitor.shellit');

      await PluginPacker.packDirectory(
        sourceDir: demoPluginDir,
        outputFilePath: archivePath,
      );

      final installResult = await loader.installFromArchive(archivePath);
      final plugin = installResult.getOrThrow();

      // Uninstall
      final uninstallResult = await loader.uninstallPlugin(plugin.manifest.id);
      expect(uninstallResult.isSuccess, isTrue);

      expect(Directory(plugin.installDirectory).existsSync(), isFalse);

      final scanned = await loader.scanInstalledPlugins();
      expect(scanned, isEmpty);
    });

    test('rejects archives with unsupported extension', () async {
      final dummyFile = File(p.join(tempWorkDir.path, 'bad.exe'));
      dummyFile.writeAsStringSync('binary');

      final result = await loader.installFromArchive(dummyFile.path);
      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message,
          contains('Unsupported plugin archive extension'));
    });

    test('rejects archive containing Zip Slip path traversal', () async {
      final archive = Archive();
      archive
          .addFile(ArchiveFile('../../escaped.txt', 5, utf8.encode('pwned')));
      archive.addFile(
        ArchiveFile(
          'manifest.json',
          50,
          utf8.encode(
              '{"id":"com.bad","name":"Bad","entryPoint":"index.html","target":"sidebar"}'),
        ),
      );
      archive.addFile(ArchiveFile('index.html', 5, utf8.encode('hello')));

      final zipBytes = ZipEncoder().encode(archive)!;
      final evilArchive = File(p.join(tempWorkDir.path, 'evil.shellit'));
      evilArchive.writeAsBytesSync(zipBytes);

      final result = await loader.installFromArchive(evilArchive.path);
      expect(result.isError, isTrue);
      expect(result.failureOrNull?.type, PluginFailureType.zipSlipAttempt);

      // Verify nothing was installed in plugins directory
      final scanned = await loader.scanInstalledPlugins();
      expect(scanned, isEmpty);
    });

    test('installs and loads localization language pack dictionary', () async {
      final pluginDir = Directory(p.join(tempWorkDir.path, 'lang_pack'))..createSync();
      File(p.join(pluginDir.path, 'manifest.json')).writeAsStringSync('''
      {
        "id": "com.community.lang.ru",
        "name": "Russian Pack",
        "version": "1.0.0",
        "entryPoint": "ru.json",
        "target": "localization",
        "locale": "ru_RU"
      }
      ''');
      File(p.join(pluginDir.path, 'ru.json')).writeAsStringSync('''
      {
        "common.connect": "Подключиться",
        "common.cancel": "Отмена"
      }
      ''');

      final archivePath = p.join(tempWorkDir.path, 'ru.shellit');
      await PluginPacker.packDirectory(
        sourceDir: pluginDir.path,
        outputFilePath: archivePath,
      );

      final installRes = await loader.installFromArchive(archivePath);
      expect(installRes.isSuccess, isTrue);

      final installed = installRes.getOrThrow();
      expect(installed.manifest.target, PluginTarget.localization);
      expect(installed.manifest.locale, 'ru_RU');

      final dictRes = await loader.loadLanguagePack(installed);
      expect(dictRes.isSuccess, isTrue);
      final dict = dictRes.getOrThrow();
      expect(dict['common.connect'], 'Подключиться');
      expect(dict['common.cancel'], 'Отмена');
    });
  });
}
