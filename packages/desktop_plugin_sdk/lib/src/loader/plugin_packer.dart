import 'dart:io';
import 'package:archive/archive.dart';
import 'package:core_foundation/core_foundation.dart';
import 'package:path/path.dart' as p;
import '../manifest/plugin_manifest_validator.dart';

/// Utility to pack a plugin directory into a `.shell-plugin` or `.pkit` archive.
class PluginPacker {
  /// Packs the contents of [sourceDir] into [outputFilePath].
  /// Validates [manifest.json] and ensures [entryPoint] exists before packaging.
  static Future<Result<File, PluginFailure>> packDirectory({
    required String sourceDir,
    required String outputFilePath,
  }) async {
    final dir = Directory(sourceDir);
    if (!await dir.exists()) {
      return Result.error(
        PluginFailure(
          'Source directory does not exist: $sourceDir',
          type: PluginFailureType.invalidManifest,
        ),
      );
    }

    final manifestFile = File(p.join(dir.path, 'manifest.json'));
    if (!await manifestFile.exists()) {
      return Result.error(
        PluginFailure.invalidManifest(
            "Source directory missing 'manifest.json'"),
      );
    }

    final manifestContent = await manifestFile.readAsString();
    final manifestResult =
        PluginManifestValidator.validateString(manifestContent);
    if (manifestResult.isError) {
      return Result.error(manifestResult.failureOrNull!);
    }
    final manifest = manifestResult.getOrThrow();

    // Verify entryPoint exists
    final entryPointFile = File(p.join(dir.path, manifest.entryPoint));
    if (!await entryPointFile.exists()) {
      return Result.error(
        PluginFailure.invalidManifest(
          "Entry point '${manifest.entryPoint}' not found in source directory",
        ),
      );
    }

    // Ensure output extension is valid
    final ext = p.extension(outputFilePath).toLowerCase();
    if (ext != '.shell-plugin' && ext != '.pkit' && ext != '.zip') {
      return Result.error(
        PluginFailure(
          "Invalid archive extension '$ext'. Supported: .shell-plugin, .pkit",
          type: PluginFailureType.invalidManifest,
        ),
      );
    }

    try {
      final archive = Archive();
      final entities = dir.listSync(recursive: true, followLinks: false);

      for (final entity in entities) {
        final relPath =
            p.relative(entity.path, from: dir.path).replaceAll('\\', '/');
        if (entity is File) {
          final bytes = entity.readAsBytesSync();
          final archiveFile = ArchiveFile(relPath, bytes.length, bytes);
          archive.addFile(archiveFile);
        }
      }

      final zipData = ZipEncoder().encode(archive);
      if (zipData == null) {
        return Result.error(
          PluginFailure('Failed to encode ZIP archive',
              type: PluginFailureType.runtimeError),
        );
      }

      final outFile = File(outputFilePath);
      final outDir = outFile.parent;
      if (!outDir.existsSync()) {
        outDir.createSync(recursive: true);
      }

      await outFile.writeAsBytes(zipData, flush: true);
      return Result.success(outFile);
    } catch (e, st) {
      return Result.error(
        PluginFailure(
          'Failed packing plugin: $e',
          type: PluginFailureType.runtimeError,
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}
