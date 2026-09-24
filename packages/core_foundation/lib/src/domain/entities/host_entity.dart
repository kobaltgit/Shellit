import 'package:meta/meta.dart';
import '../enums/enums.dart';

/// Represents an SSH Host / Server configured by the user.
@immutable
class HostEntity {
  final String id;
  final String label;
  final String hostname;
  final int port;
  final String username;
  final HostAuthType authType;
  final String? credentialRefId;
  final String? folderId;
  final List<String> tags;
  final HostEnvironment environment;
  final OsType osType;
  final int keepAliveIntervalSeconds;
  final bool dangerousCommandProtection;
  final bool isReadOnly;
  final int? lastPingLatencyMs;
  final DateTime? lastConnectedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HostEntity({
    required this.id,
    required this.label,
    required this.hostname,
    this.port = 22,
    required this.username,
    required this.authType,
    this.credentialRefId,
    this.folderId,
    this.tags = const [],
    this.environment = HostEnvironment.defaultEnv,
    this.osType = OsType.genericServer,
    this.keepAliveIntervalSeconds = 30,
    this.dangerousCommandProtection = false,
    this.isReadOnly = false,
    this.lastPingLatencyMs,
    this.lastConnectedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// True if this host is in production environment.
  bool get isProduction => environment == HostEnvironment.production;

  /// Quick representation string e.g. "root@192.168.1.1:22".
  String get connectionTarget => '$username@$hostname:$port';

  HostEntity copyWith({
    String? id,
    String? label,
    String? hostname,
    int? port,
    String? username,
    HostAuthType? authType,
    String? credentialRefId,
    String? folderId,
    List<String>? tags,
    HostEnvironment? environment,
    OsType? osType,
    int? keepAliveIntervalSeconds,
    bool? dangerousCommandProtection,
    bool? isReadOnly,
    int? lastPingLatencyMs,
    DateTime? lastConnectedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HostEntity(
      id: id ?? this.id,
      label: label ?? this.label,
      hostname: hostname ?? this.hostname,
      port: port ?? this.port,
      username: username ?? this.username,
      authType: authType ?? this.authType,
      credentialRefId: credentialRefId ?? this.credentialRefId,
      folderId: folderId ?? this.folderId,
      tags: tags ?? this.tags,
      environment: environment ?? this.environment,
      osType: osType ?? this.osType,
      keepAliveIntervalSeconds:
          keepAliveIntervalSeconds ?? this.keepAliveIntervalSeconds,
      dangerousCommandProtection:
          dangerousCommandProtection ?? this.dangerousCommandProtection,
      isReadOnly: isReadOnly ?? this.isReadOnly,
      lastPingLatencyMs: lastPingLatencyMs ?? this.lastPingLatencyMs,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HostEntity && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'HostEntity($label, $connectionTarget, env: $environment)';
}
