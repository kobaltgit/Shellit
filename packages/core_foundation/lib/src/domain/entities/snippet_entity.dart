import 'package:meta/meta.dart';

/// Represents a reusable terminal command or script.
@immutable
class SnippetEntity {
  final String id;
  final String title;
  final String command;
  final String? description;
  final List<String> tags;
  final String? folderId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SnippetEntity({
    required this.id,
    required this.title,
    required this.command,
    this.description,
    this.tags = const [],
    this.folderId,
    required this.createdAt,
    required this.updatedAt,
  });

  SnippetEntity copyWith({
    String? id,
    String? title,
    String? command,
    String? description,
    List<String>? tags,
    String? folderId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SnippetEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      command: command ?? this.command,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      folderId: folderId ?? this.folderId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SnippetEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SnippetEntity($title)';
}
