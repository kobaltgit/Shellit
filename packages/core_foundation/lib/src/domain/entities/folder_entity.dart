import 'package:meta/meta.dart';

/// Represents a folder/group for organizing hosts and snippets hierarchically.
@immutable
class FolderEntity {
  final String id;
  final String name;
  final String? parentId;
  final String? colorHex;
  final String? iconName;
  final int sortOrder;

  const FolderEntity({
    required this.id,
    required this.name,
    this.parentId,
    this.colorHex,
    this.iconName,
    this.sortOrder = 0,
  });

  /// Returns true if this is a top-level root folder.
  bool get isRoot => parentId == null;

  FolderEntity copyWith({
    String? id,
    String? name,
    String? parentId,
    String? colorHex,
    String? iconName,
    int? sortOrder,
  }) {
    return FolderEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FolderEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'FolderEntity($name, parent: $parentId)';
}
