import '../enums/enums.dart';

/// Represents a configured or detected local shell profile.
class LocalShellProfile {
  final String id;
  final String name;
  final ShellType shellType;
  final String executablePath;
  final List<String> arguments;
  final String? workingDirectory;
  final bool isDefault;
  final Map<String, String> environment;

  const LocalShellProfile({
    required this.id,
    required this.name,
    required this.shellType,
    required this.executablePath,
    this.arguments = const [],
    this.workingDirectory,
    this.isDefault = false,
    this.environment = const {},
  });

  LocalShellProfile copyWith({
    String? id,
    String? name,
    ShellType? shellType,
    String? executablePath,
    List<String>? arguments,
    String? workingDirectory,
    bool? isDefault,
    Map<String, String>? environment,
  }) {
    return LocalShellProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      shellType: shellType ?? this.shellType,
      executablePath: executablePath ?? this.executablePath,
      arguments: arguments ?? this.arguments,
      workingDirectory: workingDirectory ?? this.workingDirectory,
      isDefault: isDefault ?? this.isDefault,
      environment: environment ?? this.environment,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalShellProfile &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'LocalShellProfile(id: $id, name: $name, default: $isDefault)';
}
