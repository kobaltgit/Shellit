import 'dart:async';
import 'dart:io';

import 'package:core_foundation/core_foundation.dart';
import 'package:dartssh2/dartssh2.dart';

import '../keys/key_parser_service.dart';

class _TunnelHandle {
  final String id;
  final SSHClient client;
  final ServerSocket? serverSocket;
  final StreamSubscription<dynamic>? subscription;
  final List<Socket> sockets = [];
  final List<SSHForwardChannel> channels = [];
  bool isClosed = false;

  _TunnelHandle({
    required this.id,
    required this.client,
    this.serverSocket,
    this.subscription,
  });

  Future<void> close() async {
    if (isClosed) return;
    isClosed = true;

    try {
      await subscription?.cancel();
    } catch (_) {}

    try {
      await serverSocket?.close();
    } catch (_) {}

    for (final s in sockets) {
      try {
        s.destroy();
      } catch (_) {}
    }
    sockets.clear();

    for (final ch in channels) {
      try {
        ch.sink.close();
      } catch (_) {}
    }
    channels.clear();

    try {
      client.close();
    } catch (_) {}
  }
}

/// Service managing Local and Remote SSH port forwarding tunnels.
class PortForwardService implements IPortForwardService {
  final KeyParserService _keyParser;
  final Map<String, _TunnelHandle> _tunnels = {};

  PortForwardService({KeyParserService? keyParser})
      : _keyParser = keyParser ?? const KeyParserService();

  @override
  List<String> get activeTunnelIds => _tunnels.keys.toList();

  @override
  Future<Result<String, NetworkFailure>> startLocalForward({
    required HostEntity host,
    required int localPort,
    required String remoteHost,
    required int remotePort,
    String? password,
    List<int>? privateKeyBytes,
  }) async {
    final clientResult = await _connectSsh(
      host: host,
      password: password,
      privateKeyBytes: privateKeyBytes,
    );

    if (clientResult.isError) {
      return Result.error(clientResult.failureOrNull!);
    }

    final client = clientResult.getOrThrow();
    ServerSocket? serverSocket;

    try {
      serverSocket =
          await ServerSocket.bind(InternetAddress.loopbackIPv4, localPort);
      final tunnelId =
          'local_${host.id}_${localPort}_${DateTime.now().millisecondsSinceEpoch}';

      final handle = _TunnelHandle(
        id: tunnelId,
        client: client,
        serverSocket: serverSocket,
      );

      serverSocket.listen(
        (socket) async {
          handle.sockets.add(socket);
          try {
            final channel = await client.forwardLocal(remoteHost, remotePort);
            handle.channels.add(channel);

            // Pipe data streams bi-directionally
            channel.stream.listen(
              socket.add,
              onError: (_) => socket.destroy(),
              onDone: () => socket.destroy(),
              cancelOnError: true,
            );
            socket.listen(
              channel.sink.add,
              onError: (_) => channel.sink.close(),
              onDone: () => channel.sink.close(),
              cancelOnError: true,
            );
          } catch (e) {
            AppLogger.w(
              'Failed to forward local connection to $remoteHost:$remotePort: $e',
              tag: 'PortForwardService',
            );
            socket.destroy();
          }
        },
        onError: (Object error) {
          AppLogger.w('Local forward server error: $error',
              tag: 'PortForwardService');
        },
      );

      _tunnels[tunnelId] = handle;
      AppLogger.i(
        'Started Local Forward: 127.0.0.1:$localPort -> $remoteHost:$remotePort (ID: $tunnelId)',
        tag: 'PortForwardService',
      );

      return Result.success(tunnelId);
    } catch (e, stack) {
      try {
        await serverSocket?.close();
      } catch (_) {}
      try {
        client.close();
      } catch (_) {}

      return Result.error(
        NetworkFailure(
          'Failed to start local forward on port $localPort: $e',
          type: NetworkFailureType.channelError,
          cause: e,
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<String, NetworkFailure>> startRemoteForward({
    required HostEntity host,
    required int remotePort,
    required String targetHost,
    required int targetPort,
    String? password,
    List<int>? privateKeyBytes,
  }) async {
    final clientResult = await _connectSsh(
      host: host,
      password: password,
      privateKeyBytes: privateKeyBytes,
    );

    if (clientResult.isError) {
      return Result.error(clientResult.failureOrNull!);
    }

    final client = clientResult.getOrThrow();

    try {
      final remoteForward = await client.forwardRemote(port: remotePort);
      if (remoteForward == null) {
        client.close();
        return const Result.error(
          NetworkFailure(
            'Server rejected remote forward request.',
            type: NetworkFailureType.channelError,
          ),
        );
      }

      final tunnelId =
          'remote_${host.id}_${remotePort}_${DateTime.now().millisecondsSinceEpoch}';

      final subscription = remoteForward.connections.listen((channel) async {
        try {
          final targetSocket = await Socket.connect(targetHost, targetPort);
          // Pipe data streams bi-directionally
          channel.stream.listen(
            targetSocket.add,
            onError: (_) => targetSocket.destroy(),
            onDone: () => targetSocket.destroy(),
            cancelOnError: true,
          );
          targetSocket.listen(
            channel.sink.add,
            onError: (_) => channel.sink.close(),
            onDone: () => channel.sink.close(),
            cancelOnError: true,
          );
        } catch (e) {
          AppLogger.w(
            'Failed to connect to target $targetHost:$targetPort: $e',
            tag: 'PortForwardService',
          );
          channel.sink.close();
        }
      });

      final handle = _TunnelHandle(
        id: tunnelId,
        client: client,
        subscription: subscription,
      );

      _tunnels[tunnelId] = handle;
      AppLogger.i(
        'Started Remote Forward: :$remotePort -> $targetHost:$targetPort (ID: $tunnelId)',
        tag: 'PortForwardService',
      );

      return Result.success(tunnelId);
    } catch (e, stack) {
      try {
        client.close();
      } catch (_) {}

      return Result.error(
        NetworkFailure(
          'Failed to start remote forward on port $remotePort: $e',
          type: NetworkFailureType.channelError,
          cause: e,
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<void> stopTunnel(String tunnelId) async {
    final handle = _tunnels.remove(tunnelId);
    if (handle != null) {
      await handle.close();
      AppLogger.i('Tunnel $tunnelId stopped', tag: 'PortForwardService');
    }
  }

  Future<Result<SSHClient, NetworkFailure>> _connectSsh({
    required HostEntity host,
    String? password,
    List<int>? privateKeyBytes,
  }) async {
    try {
      List<SSHKeyPair>? identities;

      if (privateKeyBytes != null && privateKeyBytes.isNotEmpty) {
        final parseRes = _keyParser.parseKeyBytes(bytes: privateKeyBytes);
        if (parseRes.isError) {
          return Result.error(parseRes.failureOrNull!);
        }
        identities = parseRes.getOrThrow().keyPairs;
      }

      final socket = await SSHSocket.connect(
        host.hostname,
        host.port,
        timeout: const Duration(seconds: 15),
      );

      final client = SSHClient(
        socket,
        username: host.username,
        onPasswordRequest: password != null ? () => password : null,
        identities: identities,
        keepAliveInterval: host.keepAliveIntervalSeconds > 0
            ? Duration(seconds: host.keepAliveIntervalSeconds)
            : null,
      );

      await client.authenticated;
      return Result.success(client);
    } on SocketException catch (e) {
      return Result.error(
        NetworkFailure.unreachable(host.hostname, host.port, e),
      );
    } on TimeoutException {
      return Result.error(
        NetworkFailure.timeout(host.connectionTarget),
      );
    } on SSHAuthFailError catch (e) {
      return Result.error(
        NetworkFailure.authFailed(host.username, e),
      );
    } catch (e, stack) {
      return Result.error(
        NetworkFailure(
          'Failed to connect to ${host.connectionTarget}: $e',
          type: NetworkFailureType.channelError,
          cause: e,
          stackTrace: stack,
        ),
      );
    }
  }
}
