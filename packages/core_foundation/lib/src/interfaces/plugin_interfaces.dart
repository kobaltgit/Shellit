import '../common/failures.dart';
import '../common/result.dart';
import '../domain/enums/enums.dart';

/// Specification of a Shellit plugin's manifest.json.
class PluginManifest {
  final String id;
  final String name;
  final String version;
  final String author;
  final String description;
  final String entryPoint;
  final PluginTarget target;
  final List<String> permissions;
  final String minAppVersion;

  const PluginManifest({
    required this.id,
    required this.name,
    required this.version,
    required this.author,
    required this.description,
    required this.entryPoint,
    required this.target,
    this.permissions = const [],
    this.minAppVersion = '1.0.0',
  });

  factory PluginManifest.fromJson(Map<String, dynamic> json) {
    return PluginManifest(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String? ?? '1.0.0',
      author: json['author'] as String? ?? 'Unknown',
      description: json['description'] as String? ?? '',
      entryPoint: json['entryPoint'] as String? ?? 'index.html',
      target: _parseTarget(json['target'] as String?),
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      minAppVersion: json['minAppVersion'] as String? ?? '1.0.0',
    );
  }

  static PluginTarget _parseTarget(String? target) {
    switch (target?.toLowerCase()) {
      case 'statusbar':
        return PluginTarget.statusbar;
      case 'modal':
        return PluginTarget.modal;
      case 'headless':
        return PluginTarget.headless;
      case 'sidebar':
      default:
        return PluginTarget.sidebar;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'version': version,
        'author': author,
        'description': description,
        'entryPoint': entryPoint,
        'target': target.name,
        'permissions': permissions,
        'minAppVersion': minAppVersion,
      };

  @override
  String toString() => 'PluginManifest($id, v$version, target: ${target.name})';
}

/// Represents an installed plugin on disk.
class InstalledPlugin {
  final PluginManifest manifest;
  final String installDirectory;
  final bool isEnabled;
  final String? iconPath;

  const InstalledPlugin({
    required this.manifest,
    required this.installDirectory,
    this.isEnabled = true,
    this.iconPath,
  });

  InstalledPlugin copyWith({bool? isEnabled}) {
    return InstalledPlugin(
      manifest: manifest,
      installDirectory: installDirectory,
      isEnabled: isEnabled ?? this.isEnabled,
      iconPath: iconPath,
    );
  }
}

/// Contract for plugin lifecycle management (Desktop only).
abstract class IPluginLoader {
  /// Scans default plugin directory (~/.shellit/plugins) and returns detected plugins.
  Future<List<InstalledPlugin>> scanInstalledPlugins();

  /// Unpacks and installs a `.shell-plugin` or `.pkit` archive.
  Future<Result<InstalledPlugin, PluginFailure>> installFromArchive(
      String archiveFilePath);

  /// Uninstalls and removes plugin directory.
  Future<Result<void, PluginFailure>> uninstallPlugin(String pluginId);

  /// Toggles plugin enabled/disabled status.
  Future<Result<void, PluginFailure>> togglePlugin(
      String pluginId, bool enabled);
}

/// Contract for two-way JSON-RPC communications between Shellit and Plugin WebView.
abstract class IPluginBridge {
  /// Sends a notification or response to the plugin sandbox.
  void postMessageToPlugin(String pluginId, Map<String, dynamic> message);

  /// Stream of incoming JSON-RPC calls from the plugin.
  Stream<Map<String, dynamic>> onMessageFromPlugin(String pluginId);
}
