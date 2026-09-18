import 'dart:io';

import 'package:core_foundation/core_foundation.dart';
import 'package:ssh_network_core/ssh_network_core.dart';
import 'package:test/test.dart';

void main() {
  group('SshClientService - Ping & Session Creation Tests', () {
    late SshClientService service;

    setUp(() {
      service = SshClientService();
    });

    test('pingHost measures latency against listening TCP port', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = server.port;

      final result = await service.pingHost('127.0.0.1', port);
      expect(result.isSuccess, isTrue);

      final latency = result.getOrThrow();
      expect(latency, isNonNegative);

      await server.close();
    });

    test('pingHost returns failure when port is closed', () async {
      // Find an unused port and immediately close it
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = server.port;
      await server.close();

      final result = await service.pingHost('127.0.0.1', port);
      expect(result.isError, isTrue);
      expect(result.failureOrNull?.type,
          equals(NetworkFailureType.hostUnreachable));
    });

    test('pingHost returns failure on timeout', () async {
      // 192.0.2.1 is TEST-NET-1 (RFC 5737), non-routable in public internet
      final result = await service.pingHost(
        '192.0.2.1',
        54321,
        timeout: const Duration(milliseconds: 100),
      );
      expect(result.isError, isTrue);
    });

    test('createTerminalSession returns keyParseError on invalid key bytes',
        () async {
      final host = HostEntity(
        id: 'h1',
        label: 'Test Host',
        hostname: '127.0.0.1',
        username: 'root',
        authType: HostAuthType.privateKey,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await service.createTerminalSession(
        host: host,
        initialDimensions: const TerminalDimensions(cols: 80, rows: 24),
        privateKeyBytes: [1, 2, 3, 4], // Malformed UTF-8/PEM
      );

      expect(result.isError, isTrue);
      expect(
          result.failureOrNull?.type, equals(NetworkFailureType.keyParseError));
    });

    test('createTerminalSession returns unreachable failure when server down',
        () async {
      final host = HostEntity(
        id: 'h2',
        label: 'Test Host 2',
        hostname: '127.0.0.1',
        port: 65432, // Closed port
        username: 'root',
        authType: HostAuthType.password,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await service.createTerminalSession(
        host: host,
        initialDimensions: const TerminalDimensions(cols: 80, rows: 24),
        password: 'test',
      );

      expect(result.isError, isTrue);
      expect(result.failureOrNull?.type,
          equals(NetworkFailureType.hostUnreachable));
    });

    test('openSftpSession returns unreachable failure when server down',
        () async {
      final host = HostEntity(
        id: 'h3',
        label: 'Test Host 3',
        hostname: '127.0.0.1',
        port: 65431, // Closed port
        username: 'root',
        authType: HostAuthType.password,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await service.openSftpSession(
        host: host,
        password: 'test',
      );

      expect(result.isError, isTrue);
      expect(result.failureOrNull?.type,
          equals(NetworkFailureType.hostUnreachable));
    });
  });
}
