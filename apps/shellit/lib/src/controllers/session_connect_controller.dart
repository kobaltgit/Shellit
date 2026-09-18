import 'dart:async';
import 'package:core_foundation/core_foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ssh_network_core/ssh_network_core.dart';
import 'package:terminal_ui/terminal_ui.dart';
import '../di/app_providers.dart';
import 'log_controllers.dart';
import 'recording_settings_provider.dart';

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

  /// Creates and starts an active [SessionRecorder] for a host session.
  Future<SessionRecorder> createRecorder(HostEntity host) async {
    final storageService = _ref.read(sessionStorageServiceProvider);
    await storageService.init();

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeLabel = host.label.replaceAll(RegExp(r'[^\w\.-]'), '_');
    final castPath =
        '${storageService.recordingsDirectoryPath}/rec_${safeLabel}_$timestamp.cast';
    final logPath =
        '${storageService.recordingsDirectoryPath}/rec_${safeLabel}_$timestamp.log';

    final meta = SessionRecordingEntity(
      id: 'rec-$timestamp',
      hostId: host.id,
      hostLabel: host.label,
      username: host.username,
      startedAt: DateTime.now(),
      castFilePath: castPath,
      logFilePath: logPath,
    );

    final recorder = SessionRecorder(
      onRecordingFinished: (finalized) async {
        await storageService.saveRecording(finalized);
        _ref.read(sessionRecordingsControllerProvider.notifier).refresh();
      },
    );

    await recorder.startRecording(meta);
    return recorder;
  }

  /// Toggles session recording on or off for an active terminal session.
  Future<void> toggleRecording(
    ITerminalSession session,
    HostEntity host,
  ) async {
    if (session.recorder != null && session.recorder!.isRecording) {
      await session.recorder!.stopRecording();
    } else {
      final recorder = await createRecorder(host);
      session.recorder = recorder;
    }
  }

  /// Connect and return an interactive terminal session
  Future<ITerminalSession> connectTerminal(
    HostEntity host, {
    void Function(String status)? onProgress,
  }) async {
    String? password;
    List<int>? keyBytes;

    if (host.credentialRefId != null) {
      if (!_ref.read(vaultProvider).isUnlocked) {
        throw Exception(
          'Vault is locked. Master password required to decrypt host credentials.',
        );
      }

      onProgress?.call('Decrypting credentials...');
      if (host.authType == HostAuthType.password) {
        final passRes = await _keyManager.getDecryptedPassphrase(
          host.credentialRefId!,
        );
        passRes.when(
          success: (pwd) => password = pwd,
          error: (f) {
            if (f.type == VaultFailureType.locked) {
              throw Exception(
                'Vault is locked. Master password required to decrypt host credentials.',
              );
            }
            AppLogger.w('Failed to decrypt password: ${f.message}');
          },
        );
      } else if (host.authType == HostAuthType.privateKey) {
        final keyRes = await _keyManager.getDecryptedPrivateKey(
          host.credentialRefId!,
        );
        keyRes.when(
          success: (bytes) => keyBytes = bytes,
          error: (f) {
            if (f.type == VaultFailureType.locked) {
              throw Exception(
                'Vault is locked. Master password required to decrypt host credentials.',
              );
            }
            AppLogger.w('Failed to decrypt key: ${f.message}');
          },
        );
      }
    }

    final mode = _ref.read(sessionRecordingModeProvider);
    final shouldRecord =
        mode == SessionRecordingMode.all ||
        (mode == SessionRecordingMode.prodOnly &&
            host.environment == HostEnvironment.production);

    SessionRecorder? recorder;
    if (shouldRecord) {
      try {
        recorder = await createRecorder(host);
      } catch (e, stack) {
        AppLogger.w(
          'Failed to initialize session recorder: $e',
          tag: 'SessionConnectController',
          stackTrace: stack,
        );
      }
    }

    final result = await _sshService.createTerminalSession(
      host: host,
      initialDimensions: const TerminalDimensions(cols: 80, rows: 24),
      password: password,
      privateKeyBytes: keyBytes,
      recorder: recorder,
      onProgress: onProgress,
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
  Future<ISftpSession> connectSftp(
    HostEntity host, {
    void Function(String status)? onProgress,
  }) async {
    String? password;
    List<int>? keyBytes;

    if (host.credentialRefId != null) {
      if (!_ref.read(vaultProvider).isUnlocked) {
        throw Exception(
          'Vault is locked. Master password required to decrypt host credentials.',
        );
      }

      onProgress?.call('Decrypting credentials...');
      if (host.authType == HostAuthType.password) {
        final passRes = await _keyManager.getDecryptedPassphrase(
          host.credentialRefId!,
        );
        passRes.when(
          success: (pwd) => password = pwd,
          error: (f) {
            if (f.type == VaultFailureType.locked) {
              throw Exception(
                'Vault is locked. Master password required to decrypt host credentials.',
              );
            }
            AppLogger.w('Failed to decrypt password: ${f.message}');
          },
        );
      } else if (host.authType == HostAuthType.privateKey) {
        final keyRes = await _keyManager.getDecryptedPrivateKey(
          host.credentialRefId!,
        );
        keyRes.when(
          success: (bytes) => keyBytes = bytes,
          error: (f) {
            if (f.type == VaultFailureType.locked) {
              throw Exception(
                'Vault is locked. Master password required to decrypt host credentials.',
              );
            }
            AppLogger.w('Failed to decrypt key: ${f.message}');
          },
        );
      }
    }

    final result = await _sshService.openSftpSession(
      host: host,
      password: password,
      privateKeyBytes: keyBytes,
      onProgress: onProgress,
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
