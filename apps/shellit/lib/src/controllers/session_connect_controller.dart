import 'dart:async';
import 'package:core_foundation/core_foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_ui/terminal_ui.dart';
import '../di/app_providers.dart';

final sessionConnectControllerProvider = Provider<SessionConnectController>((
  ref,
) {
  return SessionConnectController(ref);
});

class SessionConnectController {
  final Ref _ref;

  SessionConnectController(this._ref);

  ISshClientService get _sshService => _ref.read(appSshClientServiceProvider);
  IKeyManager get _keyManager => _ref.read(appKeyManagerProvider);
  IHostRepository get _hostRepository => _ref.read(appHostRepositoryProvider);
  IOsDetector get _osDetector => _ref.read(appOsDetectorProvider);

  void _triggerBackgroundOsDetection(HostEntity host, dynamic client) {
    if (client == null) return;
    unawaited(() async {
      try {
        final detected = await _osDetector.detectOs(client);
        if (detected != OsType.genericServer && detected != host.osType) {
          final updated = host.copyWith(osType: detected);
          await _hostRepository.saveHost(updated);
          _ref.read(hostsProvider.notifier).updateHost(updated);
          AppLogger.i(
            'Host ${host.label} OS auto-detected and updated to: $detected',
            tag: 'SessionConnectController',
          );
        }
      } catch (e, stack) {
        AppLogger.w(
          'Background OS detection error: $e',
          tag: 'SessionConnectController',
          stackTrace: stack,
        );
      }
    }());
  }

  /// Connect and return an interactive terminal session
  Future<ITerminalSession> connectTerminal(HostEntity host) async {
    String? password;
    List<int>? keyBytes;

    if (host.credentialRefId != null) {
      if (host.authType == HostAuthType.password) {
        final passRes = await _keyManager.getDecryptedPassphrase(
          host.credentialRefId!,
        );
        passRes.when(
          success: (pwd) => password = pwd,
          error: (f) => AppLogger.w('Failed to decrypt password: ${f.message}'),
        );
      } else if (host.authType == HostAuthType.privateKey) {
        final keyRes = await _keyManager.getDecryptedPrivateKey(
          host.credentialRefId!,
        );
        keyRes.when(
          success: (bytes) => keyBytes = bytes,
          error: (f) => AppLogger.w('Failed to decrypt key: ${f.message}'),
        );
      }
    }

    final result = await _sshService.createTerminalSession(
      host: host,
      initialDimensions: const TerminalDimensions(cols: 80, rows: 24),
      password: password,
      privateKeyBytes: keyBytes,
    );

    return result.when(
      success: (session) {
        _triggerBackgroundOsDetection(host, session.underlyingClient);
        return session;
      },
      error: (failure) => throw Exception(failure.message),
    );
  }

  /// Open and return a dedicated SFTP session
  Future<ISftpSession> connectSftp(HostEntity host) async {
    String? password;
    List<int>? keyBytes;

    if (host.credentialRefId != null) {
      if (host.authType == HostAuthType.password) {
        final passRes = await _keyManager.getDecryptedPassphrase(
          host.credentialRefId!,
        );
        passRes.when(
          success: (pwd) => password = pwd,
          error: (f) => AppLogger.w('Failed to decrypt password: ${f.message}'),
        );
      } else if (host.authType == HostAuthType.privateKey) {
        final keyRes = await _keyManager.getDecryptedPrivateKey(
          host.credentialRefId!,
        );
        keyRes.when(
          success: (bytes) => keyBytes = bytes,
          error: (f) => AppLogger.w('Failed to decrypt key: ${f.message}'),
        );
      }
    }

    final result = await _sshService.openSftpSession(
      host: host,
      password: password,
      privateKeyBytes: keyBytes,
    );

    return result.when(
      success: (session) {
        _triggerBackgroundOsDetection(host, session.underlyingClient);
        return session;
      },
      error: (failure) => throw Exception(failure.message),
    );
  }
}
