import 'package:meta/meta.dart';
import '../enums/enums.dart';

/// Represents a recorded SSH terminal session with associated metadata and artifacts.
@immutable
class SessionRecordingEntity {
  final String id;
  final String hostId;
  final String hostLabel;
  final String username;
  final HostEnvironment environment;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int byteSize;
  final int commandCount;
  final String castFilePath;
  final String logFilePath;

  const SessionRecordingEntity({
    required this.id,
    required this.hostId,
    required this.hostLabel,
    required this.username,
    this.environment = HostEnvironment.defaultEnv,
    required this.startedAt,
    this.endedAt,
    this.byteSize = 0,
    this.commandCount = 0,
    required this.castFilePath,
    required this.logFilePath,
  });

  /// Calculates duration of the session if finished, or since start if ongoing.
  Duration get duration {
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  SessionRecordingEntity copyWith({
    String? id,
    String? hostId,
    String? hostLabel,
    String? username,
    HostEnvironment? environment,
    DateTime? startedAt,
    DateTime? endedAt,
    int? byteSize,
    int? commandCount,
    String? castFilePath,
    String? logFilePath,
  }) {
    return SessionRecordingEntity(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      hostLabel: hostLabel ?? this.hostLabel,
      username: username ?? this.username,
      environment: environment ?? this.environment,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      byteSize: byteSize ?? this.byteSize,
      commandCount: commandCount ?? this.commandCount,
      castFilePath: castFilePath ?? this.castFilePath,
      logFilePath: logFilePath ?? this.logFilePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hostId': hostId,
      'hostLabel': hostLabel,
      'username': username,
      'environment': environment.name,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'byteSize': byteSize,
      'commandCount': commandCount,
      'castFilePath': castFilePath,
      'logFilePath': logFilePath,
    };
  }

  factory SessionRecordingEntity.fromJson(Map<String, dynamic> json) {
    return SessionRecordingEntity(
      id: json['id'] as String,
      hostId: json['hostId'] as String,
      hostLabel: json['hostLabel'] as String,
      username: json['username'] as String,
      environment: HostEnvironment.values.firstWhere(
        (e) => e.name == json['environment'],
        orElse: () => HostEnvironment.defaultEnv,
      ),
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      byteSize: json['byteSize'] as int? ?? 0,
      commandCount: json['commandCount'] as int? ?? 0,
      castFilePath: json['castFilePath'] as String,
      logFilePath: json['logFilePath'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionRecordingEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
