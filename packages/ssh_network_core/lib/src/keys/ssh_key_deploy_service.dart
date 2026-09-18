import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:core_foundation/core_foundation.dart';
import 'package:dartssh2/dartssh2.dart';

/// Status of public key deployment on a remote server.
enum KeyDeployStatus {
  deployed,
  alreadyPresent,
}

/// Service that deploys an OpenSSH public key to a remote host (like `ssh-copy-id`).
class SshKeyDeployService {
  const SshKeyDeployService();

  /// Deploys [publicKey] into `~/.ssh/authorized_keys` on the remote [host].
  ///
  /// Can authenticate using [password] or existing [identities].
  Future<Result<KeyDeployStatus, NetworkFailure>> deployPublicKey({
    required String host,
    required int port,
    required String username,
    String? password,
    List<SSHKeyPair>? identities,
    required String publicKey,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final cleanKey = publicKey.trim();
    if (cleanKey.isEmpty) {
      return const Result.error(
        NetworkFailure(
          'Публичный ключ пуст.',
          type: NetworkFailureType.keyParseError,
        ),
      );
    }

    if (cleanKey.contains('\n') || cleanKey.contains('\r')) {
      return const Result.error(
        NetworkFailure(
          'Публичный ключ должен быть одной строкой.',
          type: NetworkFailureType.keyParseError,
        ),
      );
    }

    SSHSocket? socket;
    SSHClient? client;

    try {
      socket = await SSHSocket.connect(
        host,
        port,
        timeout: timeout,
      );

      client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: password != null ? () => password : null,
        identities: identities,
      );

      await client.authenticated.timeout(
        timeout,
        onTimeout: () =>
            throw TimeoutException('SSH authentication timed out.'),
      );

      // 1. Ensure ~/.ssh directory exists and has 0700 permissions
      try {
        final prepSession = await client.execute(
          'sh -c "umask 077; mkdir -p ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"',
        );
        await prepSession.done.timeout(const Duration(seconds: 10));
      } catch (_) {
        // Fallback for shells without sh wrapper
        try {
          final s1 = await client.execute('mkdir -p ~/.ssh');
          await s1.done;
          final s2 = await client.execute('touch ~/.ssh/authorized_keys');
          await s2.done;
        } catch (_) {}
      }

      // 2. Read existing authorized_keys to check if key is already present
      final readSession = await client.execute('cat ~/.ssh/authorized_keys');
      final outputChunks = <Uint8List>[];
      final sub = readSession.stdout.listen((data) => outputChunks.add(data));
      await readSession.done.timeout(const Duration(seconds: 10));
      await sub.cancel();

      final existingContent = utf8.decode(
        outputChunks.expand((e) => e).toList(),
        allowMalformed: true,
      );

      // Key matching: compare without comments (type + base64)
      final keyTokens = cleanKey.split(RegExp(r'\s+'));
      final keyCore =
          keyTokens.length >= 2 ? '${keyTokens[0]} ${keyTokens[1]}' : cleanKey;

      if (existingContent.contains(keyCore)) {
        return const Result.success(KeyDeployStatus.alreadyPresent);
      }

      // 3. Append the key securely via stdin
      final appendSession =
          await client.execute('cat >> ~/.ssh/authorized_keys');
      appendSession.stdin.add(utf8.encode('$cleanKey\n'));
      await appendSession.stdin.close();
      await appendSession.done.timeout(const Duration(seconds: 10));

      // 4. Secure permissions
      try {
        final permSession = await client.execute(
          'chmod 600 ~/.ssh/authorized_keys && chmod 700 ~/.ssh',
        );
        await permSession.done.timeout(const Duration(seconds: 5));
      } catch (_) {}

      return const Result.success(KeyDeployStatus.deployed);
    } on TimeoutException catch (e, st) {
      return Result.error(
        NetworkFailure(
          'Превышено время ожидания при деплое ключа на $host:$port: $e',
          type: NetworkFailureType.connectionTimeout,
          cause: e,
          stackTrace: st,
        ),
      );
    } on SSHAuthFailError catch (e, st) {
      return Result.error(
        NetworkFailure(
          'Ошибка авторизации на сервере $host:$port ($username). Проверьте пароль.',
          type: NetworkFailureType.authFailed,
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        NetworkFailure(
          'Не удалось скопировать ключ на $host:$port: $e',
          type: NetworkFailureType.channelError,
          cause: e,
          stackTrace: st,
        ),
      );
    } finally {
      try {
        client?.close();
      } catch (_) {}
      try {
        await socket?.close();
      } catch (_) {}
    }
  }
}
