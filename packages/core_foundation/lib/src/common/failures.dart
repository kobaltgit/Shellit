import 'package:meta/meta.dart';

/// Base failure type across all Shellit packages.
@immutable
abstract class Failure implements Exception {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  const Failure(this.message, [this.cause, this.stackTrace]);

  @override
  String toString() =>
      '$runtimeType: $message${cause != null ? ' (Cause: $cause)' : ''}';
}

/// Failures related to the secure vault and encryption.
class VaultFailure extends Failure {
  final VaultFailureType type;

  const VaultFailure(
    String message, {
    required this.type,
    Object? cause,
    StackTrace? stackTrace,
  }) : super(message, cause, stackTrace);

  factory VaultFailure.locked() => const VaultFailure(
        'Vault is locked. Master password or biometrics required.',
        type: VaultFailureType.locked,
      );

  factory VaultFailure.invalidMasterPassword() => const VaultFailure(
        'Invalid master password or checksum verification failed.',
        type: VaultFailureType.invalidPassword,
      );

  factory VaultFailure.corrupted([Object? cause]) => VaultFailure(
        'Database file is corrupted or cannot be decrypted.',
        type: VaultFailureType.corrupted,
        cause: cause,
      );

  factory VaultFailure.biometricFailed([String? details]) => VaultFailure(
        'Biometric authentication failed${details != null ? ': $details' : ''}.',
        type: VaultFailureType.biometricFailed,
      );
}

enum VaultFailureType {
  locked,
  invalidPassword,
  corrupted,
  biometricFailed,
  notFound,
  ioError,
}

/// Failures related to SSH network connections and channels.
class NetworkFailure extends Failure {
  final NetworkFailureType type;

  const NetworkFailure(
    String message, {
    required this.type,
    Object? cause,
    StackTrace? stackTrace,
  }) : super(message, cause, stackTrace);

  factory NetworkFailure.timeout([String? target]) => NetworkFailure(
        'Connection timeout to server ${target ?? ''}',
        type: NetworkFailureType.connectionTimeout,
      );

  factory NetworkFailure.unreachable(String host, int port, [Object? cause]) =>
      NetworkFailure(
        'Host $host:$port is unreachable${cause != null ? ' ($cause)' : ''}.',
        type: NetworkFailureType.hostUnreachable,
        cause: cause,
      );

  factory NetworkFailure.authFailed(String user, [Object? cause]) =>
      NetworkFailure(
        'Authentication failed for user "$user". Please check your password or SSH key.',
        type: NetworkFailureType.authFailed,
        cause: cause,
      );

  factory NetworkFailure.connectionReset([Object? cause]) => NetworkFailure(
        'Connection reset by peer.',
        type: NetworkFailureType.connectionReset,
        cause: cause,
      );
}

enum NetworkFailureType {
  connectionTimeout,
  hostUnreachable,
  authFailed,
  connectionReset,
  channelError,
  keyParseError,
}

/// Failures related to SFTP operations.
class SftpFailure extends Failure {
  final SftpFailureType type;

  const SftpFailure(
    String message, {
    required this.type,
    Object? cause,
    StackTrace? stackTrace,
  }) : super(message, cause, stackTrace);

  factory SftpFailure.fileNotFound(String path) => SftpFailure(
        'File or directory not found: $path',
        type: SftpFailureType.fileNotFound,
      );

  factory SftpFailure.permissionDenied(String path) => SftpFailure(
        'Permission denied: $path',
        type: SftpFailureType.permissionDenied,
      );

  factory SftpFailure.transferAborted(String path, [Object? cause]) =>
      SftpFailure(
        'File transfer aborted: $path',
        type: SftpFailureType.transferAborted,
        cause: cause,
      );
}

enum SftpFailureType {
  fileNotFound,
  permissionDenied,
  transferAborted,
  quotaExceeded,
  unknown,
}

/// Failures related to plugin loading and IPC.
class PluginFailure extends Failure {
  final PluginFailureType type;

  const PluginFailure(
    String message, {
    required this.type,
    Object? cause,
    StackTrace? stackTrace,
  }) : super(message, cause, stackTrace);

  factory PluginFailure.invalidManifest(String details) => PluginFailure(
        'Invalid plugin manifest.json: $details',
        type: PluginFailureType.invalidManifest,
      );

  factory PluginFailure.zipSlipDetected(String maliciousPath) => PluginFailure(
        'Potential Zip Slip vulnerability detected during extraction: $maliciousPath',
        type: PluginFailureType.zipSlipAttempt,
      );

  factory PluginFailure.permissionDenied(String permission) => PluginFailure(
        'Plugin requested an unauthorized operation without permission: $permission',
        type: PluginFailureType.permissionDenied,
      );
}

enum PluginFailureType {
  invalidManifest,
  zipSlipAttempt,
  permissionDenied,
  runtimeError,
  unsupportedPlatform,
}
