import 'dart:typed_data';
import '../common/failures.dart';
import '../common/result.dart';
import '../domain/entities/host_entity.dart';
import '../domain/enums/enums.dart';
import 'session_recorder_interface.dart';

/// Geometry dimensions of a terminal emulator screen.
class TerminalDimensions {
  final int cols;
  final int rows;

  const TerminalDimensions({required this.cols, required this.rows});

  @override
  String toString() => '${cols}x$rows';
}

/// Active SSH PTY Terminal Session Contract.
abstract class ITerminalSession {
  String get id;
  String get hostId;

  /// Output stream from remote server (stdout & stderr) to write into xterm widget.
  Stream<Uint8List> get outputStream;

  /// Input sink to send user keystrokes into remote server.
  Sink<Uint8List> get inputStream;

  /// Current session connection state.
  SessionState get currentState;

  /// Stream of session state changes.
  Stream<SessionState> get stateStream;

  /// Resizes the remote PTY window to match terminal widget dimensions.
  void resize(TerminalDimensions dimensions);

  /// Closes and terminates this SSH session.
  Future<void> terminate();

  /// Optional active session recorder.
  ISessionRecorder? get recorder => null;
  set recorder(ISessionRecorder? value) {}

  /// Underlying platform or library SSH client instance (e.g. SSHClient).
  dynamic get underlyingClient => null;
}

/// Metadata item for SFTP file browser.
class SftpItem {
  final String path;
  final String name;
  final bool isDirectory;
  final int sizeBytes;
  final int permissions;
  final DateTime modifiedAt;

  const SftpItem({
    required this.path,
    required this.name,
    required this.isDirectory,
    required this.sizeBytes,
    required this.permissions,
    required this.modifiedAt,
  });

  @override
  String toString() => '${isDirectory ? "[DIR] " : ""}$name ($sizeBytes bytes)';
}

/// Two-pane SFTP session interface.
abstract class ISftpSession {
  String get id;
  String get hostId;

  /// Lists items in a remote directory.
  Future<Result<List<SftpItem>, SftpFailure>> listDirectory(String remotePath);

  /// Creates a remote directory.
  Future<Result<void, SftpFailure>> createDirectory(String remotePath);

  /// Deletes a remote file.
  Future<Result<void, SftpFailure>> deleteFile(String remotePath);

  /// Deletes a remote directory (optionally recursive).
  Future<Result<void, SftpFailure>> deleteDirectory(String remotePath,
      {bool recursive = false});

  /// Renames or moves a file/folder.
  Future<Result<void, SftpFailure>> rename(String oldPath, String newPath);

  /// Sets Unix permissions (chmod) for a remote file or directory.
  Future<Result<void, SftpFailure>> setPermissions(
      String remotePath, int permissions);

  /// Creates an empty file at the remote path.
  Future<Result<void, SftpFailure>> createFile(String remotePath);

  /// Streams file download from remote to local disk with transfer progress (0.0 to 1.0).
  Stream<double> downloadFile({
    required String remotePath,
    required String localPath,
  });

  /// Streams file upload from local disk to remote with transfer progress (0.0 to 1.0).
  Stream<double> uploadFile({
    required String localPath,
    required String remotePath,
  });

  /// Closes the SFTP channel.
  Future<void> close();

  /// Underlying platform or library SSH client instance (e.g. SSHClient).
  dynamic get underlyingClient => null;
}

/// Contract for SSH network core operations.
abstract class ISshClientService {
  /// Connects and launches an interactive PTY shell session.
  Future<Result<ITerminalSession, NetworkFailure>> createTerminalSession({
    required HostEntity host,
    required TerminalDimensions initialDimensions,
    String? password,
    List<int>? privateKeyBytes,
    String? passphrase,
    ISessionRecorder? recorder,
    void Function(String status)? onProgress,
  });

  /// Opens a dedicated SFTP session for the given host.
  Future<Result<ISftpSession, NetworkFailure>> openSftpSession({
    required HostEntity host,
    String? password,
    List<int>? privateKeyBytes,
    String? passphrase,
    void Function(String status)? onProgress,
  });

  /// Performs a lightweight background TCP ping to check availability and RTT latency in ms.
  Future<Result<int, NetworkFailure>> pingHost(String hostname, int port,
      {Duration timeout = const Duration(seconds: 4)});
}

/// Contract for Port Forwarding tunnels.
abstract class IPortForwardService {
  Future<Result<String, NetworkFailure>> startLocalForward({
    required HostEntity host,
    required int localPort,
    required String remoteHost,
    required int remotePort,
    String? password,
    List<int>? privateKeyBytes,
  });

  Future<Result<String, NetworkFailure>> startRemoteForward({
    required HostEntity host,
    required int remotePort,
    required String targetHost,
    required int targetPort,
    String? password,
    List<int>? privateKeyBytes,
  });

  Future<void> stopTunnel(String tunnelId);
  List<String> get activeTunnelIds;
}

/// Contract for remote host OS auto-detection.
abstract class IOsDetector {
  /// Probes the remote host OS using an active SSH client connection.
  Future<OsType> detectOs(dynamic sshClient);

  /// Parses raw command output (e.g. /etc/os-release or uname) into an [OsType].
  OsType parseOsRelease(String output);
}
