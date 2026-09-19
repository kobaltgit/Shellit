import 'dart:convert';
import 'dart:io';
import 'package:core_foundation/core_foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'default_strings.dart';

/// Failure during localization template export.
class TemplateExportFailure extends Failure {
  const TemplateExportFailure(super.message, [super.cause, super.stackTrace]);
}

/// Service for exporting localization string templates for translators and plugin authors.
class TemplateExporter {
  /// Exports the default template map as formatted JSON to [targetFilePath]
  /// or to the system Downloads/Documents directory if not specified.
  static Future<Result<String, TemplateExportFailure>> exportTemplateFile({
    String? targetFilePath,
  }) async {
    try {
      String resolvedPath = targetFilePath ?? '';
      if (resolvedPath.trim().isEmpty) {
        Directory? targetDir;
        try {
          targetDir = await getDownloadsDirectory();
        } catch (_) {}
        targetDir ??= await getApplicationDocumentsDirectory();

        resolvedPath = p.join(targetDir.path, 'shellit_strings_template.json');
      }

      final file = File(resolvedPath);
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }

      const encoder = JsonEncoder.withIndent('  ');
      final jsonOutput = encoder.convert(defaultEnglishStrings);
      await file.writeAsString(jsonOutput, flush: true);

      return Result.success(file.path);
    } catch (e, st) {
      return Result.error(TemplateExportFailure(e.toString(), e, st));
    }
  }
}
