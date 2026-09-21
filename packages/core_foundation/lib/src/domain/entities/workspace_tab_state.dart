import 'dart:convert';
import 'package:meta/meta.dart';

/// Lightweight representation of an open workspace tab for persistent storage.
@immutable
class WorkspaceTabState {
  final String id;
  final String title;
  final String? customTitle;
  final int? colorTagValue;
  final bool isPinned;
  final String type; // 'terminal', 'sftp', 'splitTerminal', 'localTerminal'
  final String? hostId;
  final String splitLayout; // 'single', 'horizontal', 'vertical', 'grid2x2'
  final String? localShellId;

  const WorkspaceTabState({
    required this.id,
    required this.title,
    this.customTitle,
    this.colorTagValue,
    this.isPinned = false,
    this.type = 'terminal',
    this.hostId,
    this.splitLayout = 'single',
    this.localShellId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (customTitle != null) 'customTitle': customTitle,
      if (colorTagValue != null) 'colorTagValue': colorTagValue,
      'isPinned': isPinned,
      'type': type,
      if (hostId != null) 'hostId': hostId,
      'splitLayout': splitLayout,
      if (localShellId != null) 'localShellId': localShellId,
    };
  }

  factory WorkspaceTabState.fromJson(Map<String, dynamic> json) {
    return WorkspaceTabState(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Terminal',
      customTitle: json['customTitle'] as String?,
      colorTagValue: json['colorTagValue'] as int?,
      isPinned: json['isPinned'] as bool? ?? false,
      type: json['type'] as String? ?? 'terminal',
      hostId: json['hostId'] as String?,
      splitLayout: json['splitLayout'] as String? ?? 'single',
      localShellId: json['localShellId'] as String?,
    );
  }

  static String encodeList(List<WorkspaceTabState> tabs) {
    return jsonEncode(tabs.map((t) => t.toJson()).toList());
  }

  static List<WorkspaceTabState> decodeList(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((item) => WorkspaceTabState.fromJson(item))
            .toList();
      }
    } catch (_) {
      // Return empty list on parse failure
    }
    return const [];
  }

  WorkspaceTabState copyWith({
    String? id,
    String? title,
    String? customTitle,
    int? colorTagValue,
    bool? isPinned,
    String? type,
    String? hostId,
    String? splitLayout,
    String? localShellId,
  }) {
    return WorkspaceTabState(
      id: id ?? this.id,
      title: title ?? this.title,
      customTitle: customTitle ?? this.customTitle,
      colorTagValue: colorTagValue ?? this.colorTagValue,
      isPinned: isPinned ?? this.isPinned,
      type: type ?? this.type,
      hostId: hostId ?? this.hostId,
      splitLayout: splitLayout ?? this.splitLayout,
      localShellId: localShellId ?? this.localShellId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkspaceTabState &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          customTitle == other.customTitle &&
          colorTagValue == other.colorTagValue &&
          isPinned == other.isPinned &&
          type == other.type &&
          hostId == other.hostId &&
          splitLayout == other.splitLayout &&
          localShellId == other.localShellId;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      customTitle.hashCode ^
      colorTagValue.hashCode ^
      isPinned.hashCode ^
      type.hashCode ^
      hostId.hashCode ^
      splitLayout.hashCode ^
      localShellId.hashCode;
}
