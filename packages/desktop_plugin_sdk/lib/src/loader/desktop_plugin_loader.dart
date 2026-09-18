import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:core_foundation/core_foundation.dart';
import 'package:path/path.dart' as p;

import '../manifest/plugin_manifest_validator.dart';
import '../security/safe_archive_extractor.dart';

/// Desktop implementation of [IPluginLoader] supporting `.shellit` and `.zip` packages.
class DesktopPluginLoader implements IPluginLoader {
  static const String stateFileName = 'plugins_state.json';
  final String pluginsDirectory;

  DesktopPluginLoader({String? pluginsDirectory})
      : pluginsDirectory = pluginsDirectory ?? defaultPluginsDirectory();

  /// Resolves the default plugins directory: `~/.shellit/plugins`.
  static String defaultPluginsDirectory() {
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        Directory.current.path;
    return p.join(home, '.shellit', 'plugins');
  }

  Directory get _directory => Directory(pluginsDirectory);
  File get _stateFile => File(p.join(pluginsDirectory, stateFileName));

  Map<String, bool> _loadState() {
    if (!_stateFile.existsSync()) return {};
    try {
      final content = _stateFile.readAsStringSync();
      final decoded = json.decode(content);
      if (decoded is Map<String, dynamic>) {
        return decoded.map((key, value) => MapEntry(key, value == true));
      }
    } catch (_) {}
    return {};
  }

  void _saveState(Map<String, bool> state) {
    try {
      if (!_directory.existsSync()) {
        _directory.createSync(recursive: true);
      }
      _stateFile.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(state),
        flush: true,
      );
    } catch (_) {}
  }

  @override
  Future<List<InstalledPlugin>> scanInstalledPlugins() async {
    if (!await _directory.exists()) {
      return [];
    }

    final state = _loadState();
    final installedList = <InstalledPlugin>[];

    final entities = _directory.listSync(followLinks: false);
    for (final entity in entities) {
      if (entity is! Directory) continue;

      final manifestFile = File(p.join(entity.path, 'manifest.json'));
      if (!manifestFile.existsSync()) continue;

      try {
        final content = manifestFile.readAsStringSync();
        final manifestResult = PluginManifestValidator.validateString(content);
        if (manifestResult.isError) {
          continue;
        }

        final manifest = manifestResult.getOrThrow();

        // Check entryPoint existence
        final entryPointFile = File(p.join(entity.path, manifest.entryPoint));
        if (!entryPointFile.existsSync()) {
          continue;
        }

        // Check optional icon
        String? iconPath;
        final iconFile = File(p.join(entity.path, 'icon.png'));
        if (iconFile.existsSync()) {
          iconPath = iconFile.path;
        } else {
          final assetIconFile = File(p.join(entity.path, 'assets', 'icon.png'));
          if (assetIconFile.existsSync()) {
            iconPath = assetIconFile.path;
          }
        }

        final isEnabled = state[manifest.id] ?? true;

        installedList.add(
          InstalledPlugin(
            manifest: manifest,
            installDirectory: entity.path,
            isEnabled: isEnabled,
            iconPath: iconPath,
          ),
        );
      } catch (_) {
        // Corrupted directory or unreadable file
      }
    }

    return installedList;
  }

  @override
  Future<Result<InstalledPlugin, PluginFailure>> installFromArchive(
    String archiveFilePath,
  ) async {
    final archiveFile = File(archiveFilePath);
    if (!await archiveFile.exists()) {
      return Result.error(
        PluginFailure(
          'Archive file not found: $archiveFilePath',
          type: PluginFailureType.invalidManifest,
        ),
      );
    }

    final ext = p.extension(archiveFilePath).toLowerCase();
    if (ext != '.shellit' && ext != '.zip') {
      return Result.error(
        PluginFailure(
          "Unsupported plugin archive extension '$ext'. Supported: .shellit, .zip",
          type: PluginFailureType.invalidManifest,
        ),
      );
    }

    List<int> bytes;
    try {
      bytes = await archiveFile.readAsBytes();
    } catch (e, st) {
      return Result.error(
        PluginFailure(
          'Failed to read archive bytes: $e',
          type: PluginFailureType.runtimeError,
          cause: e,
          stackTrace: st,
        ),
      );
    }

    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes, verify: true);
    } catch (e, st) {
      return Result.error(
        PluginFailure(
          'Corrupted or invalid ZIP archive: $e',
          type: PluginFailureType.invalidManifest,
          cause: e,
          stackTrace: st,
        ),
      );
    }

    // 1. Verify Zip Slip protection on ALL entries before doing anything
    for (final entry in archive) {
      final safetyError =
          SafeArchiveExtractor.checkEntrySafety(entry.name, pluginsDirectory);
      if (safetyError != null) {
        return Result.error(safetyError);
      }
    }

    // 2. Find manifest.json
    ArchiveFile? manifestEntry;
    for (final entry in archive) {
      if (entry.isFile &&
          (entry.name == 'manifest.json' || entry.name == './manifest.json')) {
        manifestEntry = entry;
        break;
      }
    }

    if (manifestEntry == null) {
      return Result.error(
        PluginFailure.invalidManifest(
            "Archive missing required 'manifest.json' at root"),
      );
    }

    // 3. Parse and validate manifest.json
    String manifestContent;
    try {
      final dynamic rawContent = manifestEntry.content;
      final List<int> manifestBytes = rawContent is List<int>
          ? rawContent
          : List<int>.from(rawContent as Iterable<dynamic>);
      manifestContent = utf8.decode(manifestBytes);
    } catch (e) {
      return Result.error(
        PluginFailure.invalidManifest(
            'Failed to decode manifest.json as UTF-8: $e'),
      );
    }

    final manifestResult =
        PluginManifestValidator.validateString(manifestContent);
    if (manifestResult.isError) {
      return Result.error(manifestResult.failureOrNull!);
    }
    final manifest = manifestResult.getOrThrow();

    // 4. Verify entryPoint file is present in archive
    final normalizedEntryPoint = manifest.entryPoint.replaceAll('\\', '/');
    final entryPointFound = archive.any(
      (entry) =>
          entry.isFile &&
          (entry.name.replaceAll('\\', '/') == normalizedEntryPoint ||
              entry.name.replaceAll('\\', '/') == './$normalizedEntryPoint'),
    );

    if (!entryPointFound) {
      return Result.error(
        PluginFailure.invalidManifest(
          "EntryPoint file '${manifest.entryPoint}' not found inside archive",
        ),
      );
    }

    // 5. Target install directory: ~/.shellit/plugins/<pluginId>
    final targetPluginDir = p.join(pluginsDirectory, manifest.id);
    final targetDir = Directory(targetPluginDir);

    if (targetDir.existsSync()) {
      try {
        targetDir.deleteSync(recursive: true);
      } catch (e, st) {
        return Result.error(
          PluginFailure(
            'Failed to clean existing plugin directory: $e',
            type: PluginFailureType.runtimeError,
            cause: e,
            stackTrace: st,
          ),
        );
      }
    }

    // 6. Safe extract
    final extractResult =
        SafeArchiveExtractor.extractArchive(archive, targetPluginDir);
    if (extractResult.isError) {
      return Result.error(extractResult.failureOrNull!);
    }

    // 7. Update state to enabled
    final state = _loadState();
    state[manifest.id] = true;
    _saveState(state);

    // 8. Find icon if extracted
    String? iconPath;
    final iconFile = File(p.join(targetPluginDir, 'icon.png'));
    if (iconFile.existsSync()) {
      iconPath = iconFile.path;
    } else {
      final assetIcon = File(p.join(targetPluginDir, 'assets', 'icon.png'));
      if (assetIcon.existsSync()) {
        iconPath = assetIcon.path;
      }
    }

    final installedPlugin = InstalledPlugin(
      manifest: manifest,
      installDirectory: targetPluginDir,
      isEnabled: true,
      iconPath: iconPath,
    );

    return Result.success(installedPlugin);
  }

  @override
  Future<Result<void, PluginFailure>> uninstallPlugin(String pluginId) async {
    final targetPluginDir = p.join(pluginsDirectory, pluginId);
    final targetDir = Directory(targetPluginDir);

    if (!await targetDir.exists()) {
      return Result.error(
        PluginFailure(
          'Plugin with id $pluginId is not installed',
          type: PluginFailureType.invalidManifest,
        ),
      );
    }

    try {
      await targetDir.delete(recursive: true);
      final state = _loadState();
      state.remove(pluginId);
      _saveState(state);
      return const Result.success(null);
    } catch (e, st) {
      return Result.error(
        PluginFailure(
          'Failed to remove plugin directory: $e',
          type: PluginFailureType.runtimeError,
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<void, PluginFailure>> togglePlugin(
      String pluginId, bool enabled) async {
    final targetPluginDir = p.join(pluginsDirectory, pluginId);
    final targetDir = Directory(targetPluginDir);

    if (!await targetDir.exists()) {
      return Result.error(
        PluginFailure(
          'Plugin with id $pluginId is not installed',
          type: PluginFailureType.invalidManifest,
        ),
      );
    }

    final state = _loadState();
    state[pluginId] = enabled;
    _saveState(state);

    return const Result.success(null);
  }
}

/// Alias for service naming convention
typedef DesktopPluginLoaderService = DesktopPluginLoader;
