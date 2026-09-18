import 'dart:async';
import 'dart:typed_data';

import 'package:core_foundation/core_foundation.dart';
import 'package:dartssh2/dartssh2.dart';

/// Implementation of [ITerminalSession] using dartssh2 [SSHSession].
class TerminalSession implements ITerminalSession {
  @override
  final String id;

  @override
  final String hostId;

  final SSHClient _client;
  final SSHSession _sshSession;
  ISessionRecorder? _recorder;

  @override
  ISessionRecorder? get recorder => _recorder;

  @override
  set recorder(ISessionRecorder? value) => _recorder = value;

  final StreamController<Uint8List> _outputController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> _inputController =
      StreamController<Uint8List>();
  final StreamController<SessionState> _stateController =
      StreamController<SessionState>.broadcast();

  SessionState _currentState = SessionState.ready;
  bool _isTerminated = false;
  late final StreamSubscription<Uint8List> _stdoutSub;
  late final StreamSubscription<Uint8List> _stderrSub;
  late final StreamSubscription<Uint8List> _inputSub;

  TerminalSession({
    required this.id,
    required this.hostId,
    required SSHClient client,
    required SSHSession sshSession,
    ISessionRecorder? recorder,
  })  : _client = client,
        _sshSession = sshSession,
        _recorder = recorder {
    _initStreams();
  }

  void _initStreams() {
    // Pipe stdout to output stream
    _stdoutSub = _sshSession.stdout.listen(
      (data) {
        if (!_outputController.isClosed) {
          _outputController.add(data);
          if (recorder != null && recorder!.isRecording) {
            recorder!.recordOutput(data);
          }
        }
      },
      onError: (Object error, StackTrace stack) {
        AppLogger.e(
          'SSH stdout stream error on session $id',
          tag: 'TerminalSession',
          error: error,
          stackTrace: stack,
        );
        _updateState(SessionState.error);
      },
      onDone: () {
        _checkCompletion();
      },
    );

    // Pipe stderr to output stream
    _stderrSub = _sshSession.stderr.listen(
      (data) {
        if (!_outputController.isClosed) {
          _outputController.add(data);
          if (recorder != null && recorder!.isRecording) {
            recorder!.recordOutput(data);
          }
        }
      },
      onError: (Object error, StackTrace stack) {
        AppLogger.e(
          'SSH stderr stream error on session $id',
          tag: 'TerminalSession',
          error: error,
          stackTrace: stack,
        );
      },
      onDone: () {
        _checkCompletion();
      },
    );

    // Pipe input sink to SSH session stdin
    _inputSub = _inputController.stream.listen(
      (data) {
        if (!_isTerminated) {
          if (recorder != null && recorder!.isRecording) {
            recorder!.recordInput(data);
          }
          try {
            _sshSession.stdin.add(data);
          } catch (e) {
            AppLogger.w(
              'Failed to write to SSH stdin: $e',
              tag: 'TerminalSession',
            );
          }
        }
      },
      onError: (Object error) {
        AppLogger.w(
          'Terminal input stream error: $error',
          tag: 'TerminalSession',
        );
      },
    );

    // Monitor session completion and client closure
    _sshSession.done.then((_) {
      _onSessionEnded();
    }).catchError((Object error) {
      AppLogger.w(
        'SSH session finished with error: $error',
        tag: 'TerminalSession',
      );
      _onSessionEnded();
    });

    _client.done.then((_) {
      _onSessionEnded();
    }).catchError((Object error) {
      AppLogger.w(
        'SSH client finished with error: $error',
        tag: 'TerminalSession',
      );
      _onSessionEnded();
    });
  }

  @override
  Stream<Uint8List> get outputStream => _outputController.stream;

  @override
  Sink<Uint8List> get inputStream => _inputController.sink;

  @override
  SessionState get currentState => _currentState;

  @override
  Stream<SessionState> get stateStream => _stateController.stream;

  @override
  dynamic get underlyingClient => _client;

  @override
  void resize(TerminalDimensions dimensions) {
    if (_isTerminated) return;
    try {
      _sshSession.resizeTerminal(dimensions.cols, dimensions.rows);
      AppLogger.d(
        'Terminal resized to ${dimensions.cols}x${dimensions.rows}',
        tag: 'TerminalSession',
      );
    } catch (e, stack) {
      AppLogger.w(
        'Failed to resize terminal: $e',
        tag: 'TerminalSession',
        stackTrace: stack,
      );
    }
  }

  @override
  Future<void> terminate() async {
    if (_isTerminated) return;
    _isTerminated = true;
    _updateState(SessionState.disconnected);

    try {
      await _stdoutSub.cancel();
      await _stderrSub.cancel();
      await _inputSub.cancel();
    } catch (_) {}

    if (recorder != null && recorder!.isRecording) {
      try {
        await recorder!.stopRecording();
      } catch (e) {
        AppLogger.w('Failed to stop recording on terminate: $e',
            tag: 'TerminalSession');
      }
    }

    try {
      _sshSession.close();
    } catch (_) {}

    try {
      _client.close();
    } catch (_) {}

    if (!_outputController.isClosed) {
      await _outputController.close();
    }
    if (!_inputController.isClosed) {
      await _inputController.close();
    }
    if (!_stateController.isClosed) {
      await _stateController.close();
    }

    AppLogger.i('Terminal session $id terminated cleanly',
        tag: 'TerminalSession');
  }

  void _onSessionEnded() {
    if (!_isTerminated) {
      _updateState(SessionState.disconnected);
      terminate();
    }
  }

  void _checkCompletion() {
    if (!_isTerminated) {
      _onSessionEnded();
    }
  }

  void _updateState(SessionState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      if (!_stateController.isClosed) {
        _stateController.add(newState);
      }
    }
  }
}
