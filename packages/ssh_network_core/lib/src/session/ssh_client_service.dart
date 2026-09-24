import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:core_foundation/core_foundation.dart';
import 'package:dartssh2/dartssh2.dart';

import '../keys/key_parser_service.dart';
import '../sftp/sftp_session.dart';
import 'terminal_session.dart';

/// Implementation of [ISshClientService] using pure Dart `dartssh2`.
class SshClientService implements ISshClientService {
  final KeyParserService _keyParser;

  SshClientService({KeyParserService? keyParser})
      : _keyParser = keyParser ?? const KeyParserService();

  @override
  Future<Result<ITerminalSession, NetworkFailure>> createTerminalSession({
    required HostEntity host,
    required TerminalDimensions initialDimensions,
    String? password,
    List<int>? privateKeyBytes,
    String? passphrase,
    ISessionRecorder? recorder,
    HostKeyVerifyCallback? onVerifyHostKey,
    bool isReadOnly = false,
    void Function(String status)? onProgress,
  }) async {
    try {
      List<SSHKeyPair>? identities;

      if (privateKeyBytes != null && privateKeyBytes.isNotEmpty) {
        onProgress?.call('Parsing SSH private key...');
        final keyRes = _keyParser.parseKeyBytes(
          bytes: privateKeyBytes,
          passphrase: passphrase,
        );
        if (keyRes.isError) {
          return Result.error(keyRes.failureOrNull!);
        }
        identities = keyRes.getOrThrow().keyPairs;
      }

      onProgress?.call('Connecting socket to ${host.hostname}:${host.port}...');
      AppLogger.d(
        'Connecting SSH socket to ${host.connectionTarget}...',
        tag: 'SshClientService',
      );

      final socket = await SSHSocket.connect(
        host.hostname,
        host.port,
        timeout: const Duration(seconds: 15),
      );

      onProgress?.call('SSH protocol handshake...');
      final client = SSHClient(
        socket,
        username: host.username,
        onPasswordRequest: password != null ? () => password : null,
        identities: identities,
        keepAliveInterval: host.keepAliveIntervalSeconds > 0
            ? Duration(seconds: host.keepAliveIntervalSeconds)
            : null,
        onVerifyHostKey: (String type, Uint8List fingerprint) async {
          final fingerprintStr = utf8.decode(fingerprint);
          if (onVerifyHostKey != null) {
            final accepted = await onVerifyHostKey(
              hostname: host.hostname,
              port: host.port,
              keyType: type,
              fingerprintSha256: fingerprintStr,
            );
            if (!accepted) return false;
            return true;
          }
          AppLogger.w(
            'Host key verification bypassed (no callback provided) for ${host.connectionTarget} [$type: $fingerprintStr]',
            tag: 'SshClientService',
          );
          return true;
        },
      );

      onProgress?.call('Authenticating as ${host.username}...');
      AppLogger.d(
        'Authenticating SSH session for ${host.username}...',
        tag: 'SshClientService',
      );

      await client.authenticated;

      onProgress?.call('Allocating remote PTY shell...');
      AppLogger.d(
        'Spawning PTY shell (${initialDimensions.cols}x${initialDimensions.rows})...',
        tag: 'SshClientService',
      );

      SSHSession sshSession;
      try {
        sshSession = await client.shell(
          pty: SSHPtyConfig(
            width: initialDimensions.cols,
            height: initialDimensions.rows,
            type: 'xterm-256color',
          ),
          environment: const {
            'TERM': 'xterm-256color',
            'LANG': 'en_US.UTF-8',
          },
        );
      } catch (e) {
        AppLogger.w(
          'Failed to request shell with environment variables: $e. Retrying without custom env...',
          tag: 'SshClientService',
        );
        sshSession = await client.shell(
          pty: SSHPtyConfig(
            width: initialDimensions.cols,
            height: initialDimensions.rows,
            type: 'xterm-256color',
          ),
        );
      }

      final sessionId =
          'term_${host.id}_${DateTime.now().millisecondsSinceEpoch}';

      final session = TerminalSession(
        id: sessionId,
        hostId: host.id,
        client: client,
        sshSession: sshSession,
        recorder: recorder,
        isReadOnly: isReadOnly,
      );

      AppLogger.i(
        'Terminal session $sessionId successfully opened for ${host.label}',
        tag: 'SshClientService',
      );

      return Result.success(session);
    } on SocketException catch (e) {
      return Result.error(
          NetworkFailure.unreachable(host.hostname, host.port, e));
    } on TimeoutException {
      return Result.error(NetworkFailure.timeout(host.connectionTarget));
    } on SSHAuthFailError catch (e) {
      return Result.error(NetworkFailure.authFailed(host.username, e));
    } on SSHHostkeyError catch (e) {
      return Result.error(
        NetworkFailure(
          'Host key verification rejected: $e',
          type: NetworkFailureType.channelError,
          cause: e,
        ),
      );
    } catch (e, stack) {
      return Result.error(
        NetworkFailure(
          'Failed to establish terminal SSH session: $e',
          type: NetworkFailureType.channelError,
          cause: e,
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<ISftpSession, NetworkFailure>> openSftpSession({
    required HostEntity host,
    String? password,
    List<int>? privateKeyBytes,
    String? passphrase,
    HostKeyVerifyCallback? onVerifyHostKey,
    void Function(String status)? onProgress,
  }) async {
    try {
      List<SSHKeyPair>? identities;

      if (privateKeyBytes != null && privateKeyBytes.isNotEmpty) {
        onProgress?.call('Parsing SSH private key...');
        final keyRes = _keyParser.parseKeyBytes(
          bytes: privateKeyBytes,
          passphrase: passphrase,
        );
        if (keyRes.isError) {
          return Result.error(keyRes.failureOrNull!);
        }
        identities = keyRes.getOrThrow().keyPairs;
      }

      onProgress?.call('Connecting socket to ${host.hostname}:${host.port}...');
      AppLogger.d(
        'Opening SFTP connection to ${host.connectionTarget}...',
        tag: 'SshClientService',
      );

      final socket = await SSHSocket.connect(
        host.hostname,
        host.port,
        timeout: const Duration(seconds: 15),
      );

      onProgress?.call('SSH protocol handshake...');
      final client = SSHClient(
        socket,
        username: host.username,
        onPasswordRequest: password != null ? () => password : null,
        identities: identities,
        keepAliveInterval: host.keepAliveIntervalSeconds > 0
            ? Duration(seconds: host.keepAliveIntervalSeconds)
            : null,
        onVerifyHostKey: (String type, Uint8List fingerprint) async {
          final fingerprintStr = utf8.decode(fingerprint);
          if (onVerifyHostKey != null) {
            final accepted = await onVerifyHostKey(
              hostname: host.hostname,
              port: host.port,
              keyType: type,
              fingerprintSha256: fingerprintStr,
            );
            if (!accepted) return false;
            return true;
          }
          AppLogger.w(
            'Host key verification bypassed (no callback provided) for ${host.connectionTarget} [$type: $fingerprintStr]',
            tag: 'SshClientService',
          );
          return true;
        },
      );

      onProgress?.call('Authenticating as ${host.username}...');
      await client.authenticated;

      onProgress?.call('Initializing SFTP subsystem...');
      AppLogger.d('Initializing SFTP subsystem...', tag: 'SshClientService');
      final sftp = await client.sftp();

      final sessionId =
          'sftp_${host.id}_${DateTime.now().millisecondsSinceEpoch}';

      final session = SftpSession(
        id: sessionId,
        hostId: host.id,
        client: client,
        sftp: sftp,
      );

      AppLogger.i(
        'SFTP session $sessionId successfully opened for ${host.label}',
        tag: 'SshClientService',
      );

      return Result.success(session);
    } on SocketException catch (e) {
      return Result.error(
          NetworkFailure.unreachable(host.hostname, host.port, e));
    } on TimeoutException {
      return Result.error(NetworkFailure.timeout(host.connectionTarget));
    } on SSHAuthFailError catch (e) {
      return Result.error(NetworkFailure.authFailed(host.username, e));
    } on SSHHostkeyError catch (e) {
      return Result.error(
        NetworkFailure(
          'Host key verification rejected: $e',
          type: NetworkFailureType.channelError,
          cause: e,
        ),
      );
    } catch (e, stack) {
      return Result.error(
        NetworkFailure(
          'Failed to open SFTP session: $e',
          type: NetworkFailureType.channelError,
          cause: e,
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<int, NetworkFailure>> pingHost(
    String hostname,
    int port, {
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final socket = await Socket.connect(hostname, port, timeout: timeout);
      stopwatch.stop();
      await socket.close();
      final latencyMs = stopwatch.elapsedMilliseconds;
      AppLogger.d('Ping to $hostname:$port succeeded in ${latencyMs}ms',
          tag: 'SshClientService');
      return Result.success(latencyMs);
    } on SocketException catch (e) {
      stopwatch.stop();
      return Result.error(NetworkFailure.unreachable(hostname, port, e));
    } on TimeoutException {
      stopwatch.stop();
      return Result.error(NetworkFailure.timeout('$hostname:$port'));
    } catch (e, stack) {
      stopwatch.stop();
      return Result.error(
        NetworkFailure(
          'Error checking reachability of $hostname:$port: $e',
          type: NetworkFailureType.hostUnreachable,
          cause: e,
          stackTrace: stack,
        ),
      );
    }
  }
}
