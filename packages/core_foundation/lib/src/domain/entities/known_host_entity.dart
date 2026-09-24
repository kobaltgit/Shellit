import 'package:meta/meta.dart';

/// Represents a trusted SSH host key fingerprint stored in the vault (TOFU model).
@immutable
class KnownHostEntity {
  final String id;
  final String host;
  final int port;
  final String keyType;
  final String fingerprintSha256;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;

  const KnownHostEntity({
    required this.id,
    required this.host,
    this.port = 22,
    required this.keyType,
    required this.fingerprintSha256,
    required this.firstSeenAt,
    required this.lastSeenAt,
  });

  KnownHostEntity copyWith({
    String? id,
    String? host,
    int? port,
    String? keyType,
    String? fingerprintSha256,
    DateTime? firstSeenAt,
    DateTime? lastSeenAt,
  }) {
    return KnownHostEntity(
      id: id ?? this.id,
      host: host ?? this.host,
      port: port ?? this.port,
      keyType: keyType ?? this.keyType,
      fingerprintSha256: fingerprintSha256 ?? this.fingerprintSha256,
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnownHostEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          host == other.host &&
          port == other.port &&
          keyType == other.keyType &&
          fingerprintSha256 == other.fingerprintSha256;

  @override
  int get hashCode =>
      id.hashCode ^
      host.hashCode ^
      port.hashCode ^
      keyType.hashCode ^
      fingerprintSha256.hashCode;
}
