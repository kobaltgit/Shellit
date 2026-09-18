import 'dart:io';
import 'package:archive/archive.dart';
import 'package:core_foundation/core_foundation.dart';
import 'package:path/path.dart' as p;

/// Safe ZIP archive extractor with robust protection against Zip Slip (Path Traversal) vulnerabilities.
class SafeArchiveExtractor {
  /// Maximum allowed uncompressed size for a plugin archive (100 MB).
  static const int maxUncompressedBytes = 100 * 1024 * 1024;

  /// Inspects and safely extracts a ZIP archive from [archiveBytes] into [destinationDir].
  ///
  /// Returns a [Result] with the list of created file paths on success,
  /// or a [PluginFailure.zipSlipDetected] if any path traversal attempt is found.
  static Result<List<String>, PluginFailure> extractZipBytes(
    List<int> archiveBytes,
    String destinationDir,
  ) {
    try {
      final archive = ZipDecoder().decodeBytes(archiveBytes, verify: true);
      return extractArchive(archive, destinationDir);
    } catch (e, st) {
      return Result.error(
        PluginFailure(
          'Failed to decode plugin archive: $e',
          type: PluginFailureType.runtimeError,
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Extracts an archive from disk file at [archiveFilePath] into [destinationDir].
  static Future<Result<List<String>, PluginFailure>> extractZipFile(
    String archiveFilePath,
    String destinationDir,
  ) async {
    final file = File(archiveFilePath);
    if (!await file.exists()) {
      return Result.error(
        PluginFailure(
          'Archive file not found: $archiveFilePath',
          type: PluginFailureType.runtimeError,
        ),
      );
    }

    try {
      final bytes = await file.readAsBytes();
      return extractZipBytes(bytes, destinationDir);
    } catch (e, st) {
      return Result.error(
        PluginFailure(
          'Failed to read archive file: $e',
          type: PluginFailureType.runtimeError,
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Validates all archive entries for Zip Slip attacks before extracting.
  /// If safe, extracts all files and returns their absolute paths.
  static Result<List<String>, PluginFailure> extractArchive(
    Archive archive,
    String destinationDir,
  ) {
    final destDir = Directory(destinationDir);
    if (!destDir.existsSync()) {
      destDir.createSync(recursive: true);
    }

    final canonicalDest = p.canonicalize(destDir.path);

    // 1. Pre-validation Phase: Validate ALL entries BEFORE writing any file to disk
    int totalBytes = 0;
    for (final entry in archive) {
      final entryName = entry.name;

      final validationFailure = checkEntrySafety(entryName, canonicalDest);
      if (validationFailure != null) {
        return Result.error(validationFailure);
      }

      if (entry.isFile) {
        totalBytes += entry.size;
        if (totalBytes > maxUncompressedBytes) {
          return Result.error(
            PluginFailure(
              'Archive uncompressed size exceeds maximum allowed limit ($maxUncompressedBytes bytes)',
              type: PluginFailureType.runtimeError,
            ),
          );
        }
      }
    }

    // 2. Extraction Phase: Safe extraction
    final extractedFiles = <String>[];
    try {
      for (final entry in archive) {
        final rawNormalizedPath =
            p.normalize(p.join(canonicalDest, entry.name));
        final targetPath = p.canonicalize(rawNormalizedPath);

        if (!entry.isFile) {
          final dir = Directory(targetPath);
          if (!dir.existsSync()) {
            dir.createSync(recursive: true);
          }
        } else if (entry.isFile) {
          // Ensure parent directory exists
          final parentDir = Directory(p.dirname(targetPath));
          if (!parentDir.existsSync()) {
            parentDir.createSync(recursive: true);
          }

          final outFile = File(targetPath);
          final dynamic content = entry.content;
          if (content is List<int>) {
            outFile.writeAsBytesSync(content, flush: true);
          } else {
            // In case archive stores content as other stream/data
            outFile.writeAsBytesSync(
                List<int>.from(content as Iterable<dynamic>),
                flush: true);
          }
          extractedFiles.add(targetPath);
        }
      }
      return Result.success(extractedFiles);
    } catch (e, st) {
      // Cleanup partially extracted files on failure
      try {
        if (destDir.existsSync()) {
          destDir.deleteSync(recursive: true);
        }
      } catch (_) {}

      return Result.error(
        PluginFailure(
          'Failed extracting archive files: $e',
          type: PluginFailureType.runtimeError,
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Checks if a single archive entry path is safe against Zip Slip (Path Traversal).
  /// Returns null if safe, or a [PluginFailure] if unsafe.
  static PluginFailure? checkEntrySafety(
      String entryName, String canonicalDestination) {
    // Check for null bytes
    if (entryName.contains('\x00')) {
      return PluginFailure.zipSlipDetected(entryName);
    }

    // Normalize forward slashes / backslashes
    final normalizedEntry = entryName.replaceAll('\\', '/');

    // Check for absolute paths (Unix root or Windows drive letter)
    if (p.isAbsolute(normalizedEntry) ||
        normalizedEntry.startsWith('/') ||
        RegExp(r'^[a-zA-Z]:').hasMatch(normalizedEntry)) {
      return PluginFailure.zipSlipDetected(entryName);
    }

    // Check for explicit directory traversal patterns
    final pathSegments = normalizedEntry.split('/');
    if (pathSegments.contains('..')) {
      return PluginFailure.zipSlipDetected(entryName);
    }

    // Check canonicalized target path against destination boundary
    final resolvedPath =
        p.canonicalize(p.join(canonicalDestination, entryName));
    if (resolvedPath != canonicalDestination &&
        !p.isWithin(canonicalDestination, resolvedPath)) {
      return PluginFailure.zipSlipDetected(entryName);
    }

    return null;
  }
}
