import 'dart:convert';
import 'dart:typed_data';

/// Represents a single synchronized entity (or tombstone) in encrypted form.
class SyncItem {
  final String itemId;
  final String entityType;
  final int version;
  final bool isDeleted;
  final Uint8List encryptedBlob;
  final DateTime updatedAt;

  const SyncItem({
    required this.itemId,
    required this.entityType,
    required this.version,
    required this.isDeleted,
    required this.encryptedBlob,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'entityType': entityType,
        'version': version,
        'isDeleted': isDeleted,
        'encryptedBlob': base64Encode(encryptedBlob),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory SyncItem.fromJson(Map<String, dynamic> json) => SyncItem(
        itemId: json['itemId'] as String,
        entityType: json['entityType'] as String,
        version: json['version'] as int? ?? 1,
        isDeleted: json['isDeleted'] as bool? ?? false,
        encryptedBlob: json['encryptedBlob'] != null &&
                (json['encryptedBlob'] as String).isNotEmpty
            ? base64Decode(json['encryptedBlob'] as String)
            : Uint8List(0),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// Changes response from the server containing the latest revision and updated items.
class SyncChangesResponse {
  final int currentRevision;
  final List<SyncItem> items;

  const SyncChangesResponse({
    required this.currentRevision,
    required this.items,
  });

  factory SyncChangesResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] as List<dynamic>? ?? [])
        .map((e) => SyncItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return SyncChangesResponse(
      currentRevision: json['currentRevision'] as int? ?? 0,
      items: list,
    );
  }
}
