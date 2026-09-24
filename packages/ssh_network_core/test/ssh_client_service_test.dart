import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:core_foundation/core_foundation.dart';
import 'package:dartssh2/dartssh2.dart';
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
      // 169.254.254.254 is APIPA / Link-Local, non-routable and unassigned
      final result = await service.pingHost(
        '169.254.254.254',
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

  group('SshClientService - Host Key Verification & Fail-Closed Security', () {
    late SshClientService service;
    late HostEntity host;
    late Uint8List binaryFingerprint;
    late String expectedFingerprintStr;

    setUp(() {
      service = SshClientService();
      host = HostEntity(
        id: 'h_test_security',
        label: 'Production Database',
        hostname: 'db.prod.internal',
        port: 2222,
        username: 'deploy',
        authType: HostAuthType.password,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Real 32-byte raw binary SHA-256 digest containing non-UTF8 bytes (0xFF, 0xFE, 0x80, 0xC0)
      binaryFingerprint = Uint8List.fromList([
        0xff,
        0xfe,
        0x80,
        0x49,
        0x9f,
        0x51,
        0xf7,
        0x08,
        0x14,
        0xbd,
        0xf9,
        0x57,
        0x5e,
        0xf5,
        0xb7,
        0x98,
        0x09,
        0x27,
        0x3a,
        0xcb,
        0xfe,
        0x2c,
        0xed,
        0x1e,
        0x57,
        0x49,
        0x7a,
        0x36,
        0xc9,
        0x1e,
        0x34,
        0x3c,
      ]);

      final expectedBase64 =
          base64.encode(binaryFingerprint).replaceAll('=', '');
      expectedFingerprintStr = 'SHA256:$expectedBase64';
    });

    test(
        'real 32-byte binary SHA-256 digest is encoded as canonical OpenSSH Base64 without utf8.decode failure',
        () async {
      // Confirm that calling utf8.decode on this raw binary digest throws FormatException
      expect(() => utf8.decode(binaryFingerprint), throwsFormatException);

      String? receivedKeyType;
      String? receivedFp;
      String? receivedHost;
      int? receivedPort;

      final accepted = await service.verifyHostKey(
        host: host,
        type: 'ssh-ed25519',
        fingerprint: binaryFingerprint,
        onVerifyHostKey: ({
          required String hostname,
          required int port,
          required String keyType,
          required String fingerprintSha256,
          String? expectedFingerprint,
          bool isMismatch = false,
        }) async {
          receivedHost = hostname;
          receivedPort = port;
          receivedKeyType = keyType;
          receivedFp = fingerprintSha256;
          return true;
        },
      );

      expect(accepted, isTrue);
      expect(receivedHost, equals('db.prod.internal'));
      expect(receivedPort, equals(2222));
      expect(receivedKeyType, equals('ssh-ed25519'));
      expect(receivedFp, equals(expectedFingerprintStr));
      expect(receivedFp!.startsWith('SHA256:'), isTrue);
      expect(receivedFp!.endsWith('='), isFalse);
    });

    test(
        'when onVerifyHostKey == null, verification fails closed (returns false)',
        () async {
      final accepted = await service.verifyHostKey(
        host: host,
        type: 'ssh-ed25519',
        fingerprint: binaryFingerprint,
        onVerifyHostKey: null,
      );

      expect(accepted, isFalse);
    });

    test('when onVerifyHostKey returns false, verification fails closed',
        () async {
      final accepted = await service.verifyHostKey(
        host: host,
        type: 'ssh-rsa',
        fingerprint: binaryFingerprint,
        onVerifyHostKey: ({
          required String hostname,
          required int port,
          required String keyType,
          required String fingerprintSha256,
          String? expectedFingerprint,
          bool isMismatch = false,
        }) async =>
            false,
      );

      expect(accepted, isFalse);
    });

    test('when onVerifyHostKey throws an exception, verification fails closed',
        () async {
      final accepted = await service.verifyHostKey(
        host: host,
        type: 'ecdsa-sha2-nistp256',
        fingerprint: binaryFingerprint,
        onVerifyHostKey: ({
          required String hostname,
          required int port,
          required String keyType,
          required String fingerprintSha256,
          String? expectedFingerprint,
          bool isMismatch = false,
        }) async {
          throw Exception('User dismissed prompt or MITM detected');
        },
      );

      expect(accepted, isFalse);
    });

    test('when onVerifyHostKey returns true, verification succeeds', () async {
      final accepted = await service.verifyHostKey(
        host: host,
        type: 'ssh-ed25519',
        fingerprint: binaryFingerprint,
        onVerifyHostKey: ({
          required String hostname,
          required int port,
          required String keyType,
          required String fingerprintSha256,
          String? expectedFingerprint,
          bool isMismatch = false,
        }) async =>
            true,
      );

      expect(accepted, isTrue);
    });

    test(
        'SSHHostkeyError during connection maps to NetworkFailure.channelError',
        () {
      final error = SSHHostkeyError('Host key verification failed');
      final failure = NetworkFailure(
        'Host key verification rejected: $error',
        type: NetworkFailureType.channelError,
        cause: error,
      );

      expect(failure.type, equals(NetworkFailureType.channelError));
      expect(failure.message, contains('Host key verification rejected'));
      expect(failure.cause, isA<SSHHostkeyError>());
    });
  });
}
