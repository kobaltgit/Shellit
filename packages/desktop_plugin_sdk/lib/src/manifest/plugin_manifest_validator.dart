import 'dart:convert';
import 'package:core_foundation/core_foundation.dart';
import 'package:path/path.dart' as p;
import 'plugin_permissions.dart';

/// Validates manifest.json format and field constraints according to Shellit plugin specifications.
class PluginManifestValidator {
  static final RegExp _idRegex = RegExp(r'^[a-zA-Z0-9_-]+(\.[a-zA-Z0-9_-]+)*$');
  static final RegExp _semVerRegex =
      RegExp(r'^\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$');

  /// Validates a raw JSON string and converts it to a [PluginManifest].
  static Result<PluginManifest, PluginFailure> validateString(
      String jsonString) {
    try {
      final decoded = json.decode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return Result.error(
          PluginFailure.invalidManifest('Manifest JSON must be an object'),
        );
      }
      return validateMap(decoded);
    } on FormatException catch (e) {
      return Result.error(
        PluginFailure.invalidManifest('Malformed JSON: ${e.message}'),
      );
    } catch (e) {
      return Result.error(
        PluginFailure.invalidManifest('Unexpected parsing error: $e'),
      );
    }
  }

  /// Validates a JSON map according to plugin specification.
  static Result<PluginManifest, PluginFailure> validateMap(
      Map<String, dynamic> json) {
    // 1. Validate 'id'
    final idVal = json['id'];
    if (idVal == null || idVal is! String || idVal.trim().isEmpty) {
      return Result.error(
        PluginFailure.invalidManifest(
            "Field 'id' is required and must be a non-empty string"),
      );
    }
    final id = idVal.trim();
    if (id.length < 3 || id.length > 128) {
      return Result.error(
        PluginFailure.invalidManifest(
            "Field 'id' length must be between 3 and 128 characters"),
      );
    }
    if (!_idRegex.hasMatch(id)) {
      return Result.error(
        PluginFailure.invalidManifest(
          "Field 'id' contains invalid characters. Use alphanumeric, hyphens, and dots (e.g. 'com.example.plugin')",
        ),
      );
    }
    if (id.contains('/') || id.contains('\\') || id.contains('..')) {
      return Result.error(
        PluginFailure.invalidManifest(
            "Field 'id' must not contain path traversal characters"),
      );
    }

    // 2. Validate 'name'
    final nameVal = json['name'];
    if (nameVal == null || nameVal is! String || nameVal.trim().isEmpty) {
      return Result.error(
        PluginFailure.invalidManifest(
            "Field 'name' is required and must be a non-empty string"),
      );
    }
    final name = nameVal.trim();
    if (name.length > 100) {
      return Result.error(
        PluginFailure.invalidManifest(
            "Field 'name' must not exceed 100 characters"),
      );
    }

    // 3. Validate 'version'
    final versionVal = json['version'];
    String version = '1.0.0';
    if (versionVal != null) {
      if (versionVal is! String || !_semVerRegex.hasMatch(versionVal.trim())) {
        return Result.error(
          PluginFailure.invalidManifest(
            "Field 'version' must follow semantic versioning format (e.g. '1.0.0')",
          ),
        );
      }
      version = versionVal.trim();
    }

    // 4. Validate 'entryPoint'
    final entryPointVal = json['entryPoint'];
    if (entryPointVal == null ||
        entryPointVal is! String ||
        entryPointVal.trim().isEmpty) {
      return Result.error(
        PluginFailure.invalidManifest(
            "Field 'entryPoint' is required and must be a non-empty string"),
      );
    }
    final entryPoint = entryPointVal.trim();
    if (p.posix.isAbsolute(entryPoint) ||
        p.windows.isAbsolute(entryPoint) ||
        entryPoint.startsWith('/') ||
        entryPoint.startsWith('\\') ||
        RegExp(r'^[a-zA-Z]:').hasMatch(entryPoint) ||
        entryPoint.contains('..')) {
      return Result.error(
        PluginFailure.invalidManifest(
          "Field 'entryPoint' must be a relative path and cannot contain path traversal ('..')",
        ),
      );
    }
    final ext = p.extension(entryPoint).toLowerCase();
    final targetRaw = (json['target'] as String?)?.trim().toLowerCase();
    if (targetRaw == 'localization') {
      if (ext != '.json') {
        return Result.error(
          PluginFailure.invalidManifest(
            "For 'localization' target, field 'entryPoint' must point to a JSON dictionary (.json)",
          ),
        );
      }
    } else if (ext != '.html' && ext != '.htm' && ext != '.js') {
      return Result.error(
        PluginFailure.invalidManifest(
          "Field 'entryPoint' must point to an HTML or JS file (.html, .htm, .js)",
        ),
      );
    }

    // 5. Validate 'target'
    final targetVal = json['target'];
    if (targetVal == null || targetVal is! String || targetVal.trim().isEmpty) {
      return Result.error(
        PluginFailure.invalidManifest(
          "Field 'target' is required and must be one of: 'sidebar', 'statusbar', 'modal', 'headless', 'localization'",
        ),
      );
    }
    final targetStr = targetVal.trim().toLowerCase();
    PluginTarget target;
    switch (targetStr) {
      case 'sidebar':
        target = PluginTarget.sidebar;
        break;
      case 'statusbar':
        target = PluginTarget.statusbar;
        break;
      case 'modal':
        target = PluginTarget.modal;
        break;
      case 'headless':
        target = PluginTarget.headless;
        break;
      case 'localization':
        target = PluginTarget.localization;
        break;
      default:
        return Result.error(
          PluginFailure.invalidManifest(
            "Unknown target '$targetStr'. Allowed targets: 'sidebar', 'statusbar', 'modal', 'headless', 'localization'",
          ),
        );
    }

    // 5.1 Validate 'locale' for localization target
    String? locale;
    if (target == PluginTarget.localization) {
      final locVal = json['locale'];
      if (locVal == null || locVal is! String || locVal.trim().isEmpty) {
        return Result.error(
          PluginFailure.invalidManifest(
            "Field 'locale' is required for 'localization' target (e.g. 'ru_RU', 'de_DE')",
          ),
        );
      }
      locale = locVal.trim();
    } else if (json.containsKey('locale')) {
      locale = (json['locale'] as String?)?.trim();
    }

    // 6. Validate 'permissions'
    List<String> permissions = const [];
    if (json.containsKey('permissions')) {
      final permsVal = json['permissions'];
      if (permsVal is! List) {
        return Result.error(
          PluginFailure.invalidManifest(
              "Field 'permissions' must be a list of strings"),
        );
      }
      final parsedPerms = <String>[];
      for (final item in permsVal) {
        if (item is! String || item.trim().isEmpty) {
          return Result.error(
            PluginFailure.invalidManifest(
                "Permission item must be a non-empty string"),
          );
        }
        final trimmed = item.trim();
        if (!PluginPermissions.isValidFormat(trimmed)) {
          return Result.error(
            PluginFailure.invalidManifest(
                "Invalid permission format: '$trimmed'"),
          );
        }
        parsedPerms.add(trimmed);
      }
      permissions = List.unmodifiable(parsedPerms);
    }

    // 7. Validate 'minAppVersion'
    String minAppVersion = '1.0.0';
    if (json.containsKey('minAppVersion')) {
      final minVerVal = json['minAppVersion'];
      if (minVerVal is! String || !_semVerRegex.hasMatch(minVerVal.trim())) {
        return Result.error(
          PluginFailure.invalidManifest(
            "Field 'minAppVersion' must follow semantic versioning format (e.g. '1.0.0')",
          ),
        );
      }
      minAppVersion = minVerVal.trim();
    }

    final author = (json['author'] as String?)?.trim() ?? 'Unknown';
    final description = (json['description'] as String?)?.trim() ?? '';

    final manifest = PluginManifest(
      id: id,
      name: name,
      version: version,
      author: author,
      description: description,
      entryPoint: entryPoint,
      target: target,
      locale: locale,
      permissions: permissions,
      minAppVersion: minAppVersion,
    );

    return Result.success(manifest);
  }
}
