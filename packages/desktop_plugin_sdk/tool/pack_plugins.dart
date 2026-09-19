import 'dart:io';
import 'package:desktop_plugin_sdk/desktop_plugin_sdk.dart';
import 'package:path/path.dart' as p;

void main() async {
  final current = Directory.current.path;
  final plugins = ['docker_monitor', 'mcp_server', 'russian_lang_pack'];

  for (final name in plugins) {
    final sourceDir = p.join(current, 'assets', 'demo_plugins', name);
    final outputFile =
        p.join(current, 'assets', 'demo_plugins', '$name.shellit');

    print('Packing $sourceDir to $outputFile...');
    final res = await PluginPacker.packDirectory(
      sourceDir: sourceDir,
      outputFilePath: outputFile,
    );

    res.when(
      success: (file) {
        print(
            'Successfully created ${file.path} (${file.lengthSync()} bytes)');
        // Also copy to root plugins/ folder
        final rootPluginsDir =
            p.normalize(p.join(current, '..', '..', 'plugins'));
        if (Directory(rootPluginsDir).existsSync()) {
          final dest = p.join(rootPluginsDir, '$name.shellit');
          file.copySync(dest);
          print('Copied to $dest');
        }
      },
      error: (err) => print('Error packing $name: ${err.message}'),
    );
  }
}
