import 'package:meta/meta.dart';

/// Metadata about an available AI model fetched from the Gemini API.
@immutable
class AiModelInfo {
  final String id;
  final String displayName;
  final String description;
  final bool isRecommended;

  const AiModelInfo({
    required this.id,
    required this.displayName,
    this.description = '',
    this.isRecommended = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiModelInfo &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AiModelInfo(id: $id, name: $displayName)';
}

/// Structured response returned by Gemini API for a generated snippet.
@immutable
class AiSnippetResponse {
  final String title;
  final String command;
  final String description;
  final List<String> tags;
  final String explanation;
  final bool isDangerous;
  final String? dangerWarning;

  const AiSnippetResponse({
    required this.title,
    required this.command,
    required this.description,
    this.tags = const [],
    this.explanation = '',
    this.isDangerous = false,
    this.dangerWarning,
  });

  factory AiSnippetResponse.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    List<String> parsedTags = [];
    if (rawTags is List) {
      parsedTags = rawTags
          .map((t) => t.toString().trim())
          .where((t) => t.isNotEmpty)
          .toList();
    }

    return AiSnippetResponse(
      title: json['title'] as String? ?? 'Generated Snippet',
      command: json['command'] as String? ?? '',
      description: json['description'] as String? ?? '',
      tags: parsedTags,
      explanation: json['explanation'] as String? ?? '',
      isDangerous: json['isDangerous'] as bool? ?? false,
      dangerWarning: json['dangerWarning'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'command': command,
        'description': description,
        'tags': tags,
        'explanation': explanation,
        'isDangerous': isDangerous,
        if (dangerWarning != null) 'dangerWarning': dangerWarning,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiSnippetResponse &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          command == other.command &&
          description == other.description &&
          isDangerous == other.isDangerous;

  @override
  int get hashCode => Object.hash(title, command, description, isDangerous);
}

/// A message in the multi-turn AI Snippet Chat thread.
@immutable
class AiChatMessage {
  final String id;
  final bool isUser;
  final String text;
  final AiSnippetResponse? snippet;
  final DateTime timestamp;

  const AiChatMessage({
    required this.id,
    required this.isUser,
    required this.text,
    this.snippet,
    required this.timestamp,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiChatMessage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
