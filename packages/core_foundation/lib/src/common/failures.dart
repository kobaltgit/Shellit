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
        'Хранилище заблокировано. Требуется мастер-пароль или биометрия.',
        type: VaultFailureType.locked,
      );

  factory VaultFailure.invalidMasterPassword() => const VaultFailure(
        'Неверный мастер-пароль или ошибка проверки контрольной суммы.',
        type: VaultFailureType.invalidPassword,
      );

  factory VaultFailure.corrupted([Object? cause]) => VaultFailure(
        'Файл базы данных поврежден или не может быть расшифрован.',
        type: VaultFailureType.corrupted,
        cause: cause,
      );

  factory VaultFailure.biometricFailed([String? details]) => VaultFailure(
        'Биометрическая аутентификация не удалась${details != null ? ': $details' : ''}.',
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
        'Таймаут подключения к серверу ${target ?? ''}',
        type: NetworkFailureType.connectionTimeout,
      );

  factory NetworkFailure.unreachable(String host, int port, [Object? cause]) =>
      NetworkFailure(
        'Хост $host:$port недоступен${cause != null ? ' ($cause)' : ''}.',
        type: NetworkFailureType.hostUnreachable,
        cause: cause,
      );

  factory NetworkFailure.authFailed(String user, [Object? cause]) =>
      NetworkFailure(
        'Аутентификация для пользователя "$user" не удалась. Проверьте пароль или SSH-ключ.',
        type: NetworkFailureType.authFailed,
        cause: cause,
      );

  factory NetworkFailure.connectionReset([Object? cause]) => NetworkFailure(
        'Соединение разорвано удаленной стороной (Connection reset by peer).',
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
        'Файл или директория не найдены: $path',
        type: SftpFailureType.fileNotFound,
      );

  factory SftpFailure.permissionDenied(String path) => SftpFailure(
        'Доступ запрещен (Permission denied): $path',
        type: SftpFailureType.permissionDenied,
      );

  factory SftpFailure.transferAborted(String path, [Object? cause]) =>
      SftpFailure(
        'Передача файла прервана: $path',
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
        'Некорректный manifest.json плагина: $details',
        type: PluginFailureType.invalidManifest,
      );

  factory PluginFailure.zipSlipDetected(String maliciousPath) => PluginFailure(
        'Обнаружена потенциальная Zip Slip уязвимость при распаковке: $maliciousPath',
        type: PluginFailureType.zipSlipAttempt,
      );

  factory PluginFailure.permissionDenied(String permission) => PluginFailure(
        'Плагин запросил недопустимую операцию без разрешения: $permission',
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
