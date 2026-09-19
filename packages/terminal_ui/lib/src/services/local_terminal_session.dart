import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:core_foundation/core_foundation.dart';
import 'package:flutter_pty2/flutter_pty2.dart';

/// Concrete implementation of [ITerminalSession] for a local operating system shell.
/// Uses native pseudo-terminal (ConPTY on Windows, Unix PTY on macOS/Linux).
class LocalTerminalSession implements ITerminalSession {
  @override
  final String id;

  @override
  final String hostId;

  final LocalShellProfile profile;
  final Pty _pty;
  final void Function(int exitCode)? onExit;

  @override
  ISessionRecorder? recorder;

  @override
  dynamic get underlyingClient => null;

  final StreamController<Uint8List> _outputController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> _inputController =
      StreamController<Uint8List>();
  final StreamController<SessionState> _stateController =
      StreamController<SessionState>.broadcast();
  StreamSubscription<Uint8List>? _ptyOutputSub;

  SessionState _currentState = SessionState.ready;
  bool _isTerminated = false;

  LocalTerminalSession._({
    required this.id,
    required this.hostId,
    required this.profile,
    required Pty pty,
    this.onExit,
  }) : _pty = pty {
    _ptyOutputSub = _pty.output.listen(
      (data) {
        if (!_outputController.isClosed) {
          _outputController.add(data);
        }
      },
      onError: (err) {
        if (!_outputController.isClosed) {
          _outputController.addError(err);
        }
      },
      onDone: () {
        if (!_outputController.isClosed) {
          _outputController.close();
        }
      },
    );

    _inputController.stream.listen((data) {
      if (!_isTerminated) {
        _pty.write(data);
      }
    });

    _pty.exitCode.then((code) {
      _currentState = SessionState.disconnected;
      if (!_stateController.isClosed) {
        _stateController.add(SessionState.disconnected);
      }
      onExit?.call(code);
    }).catchError((_) {
      _currentState = SessionState.error;
      if (!_stateController.isClosed) {
        _stateController.add(SessionState.error);
      }
    });
  }

  /// Spawns a new local pseudo-terminal for the given [profile].
  static Future<LocalTerminalSession> start({
    required LocalShellProfile profile,
    required TerminalDimensions initialDimensions,
    void Function(int exitCode)? onExit,
    String? customWorkingDirectory,
  }) async {
    final homeDir = customWorkingDirectory ??
        profile.workingDirectory ??
        (Platform.isWindows
            ? Platform.environment['USERPROFILE']
            : Platform.environment['HOME']) ??
        Directory.current.path;

    // Set up environment with forced UTF-8 for clean unicode rendering
    final env = Map<String, String>.from(Platform.environment);
    env['TERM'] = 'xterm-256color';
    env['COLORTERM'] = 'truecolor';
    env['LANG'] = 'en_US.UTF-8';
    if (Platform.isWindows) {
      env['PYTHONIOENCODING'] = 'utf-8';
    }
    if (profile.environment.isNotEmpty) {
      env.addAll(profile.environment);
    }

    final pty = Pty.start(
      profile.executablePath,
      arguments: profile.arguments,
      workingDirectory: homeDir,
      environment: env,
      rows: initialDimensions.rows > 0 ? initialDimensions.rows : 24,
      columns: initialDimensions.cols > 0 ? initialDimensions.cols : 80,
    );

    final sessionId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    return LocalTerminalSession._(
      id: sessionId,
      hostId: 'local',
      profile: profile,
      pty: pty,
      onExit: onExit,
    );
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
  void resize(TerminalDimensions dimensions) {
    if (_isTerminated) return;
    try {
      if (dimensions.rows > 0 && dimensions.cols > 0) {
        _pty.resize(dimensions.rows, dimensions.cols);
      }
    } catch (_) {}
  }

  @override
  Future<void> terminate() async {
    if (_isTerminated) return;
    _isTerminated = true;
    try {
      await _ptyOutputSub?.cancel();
      _ptyOutputSub = null;
    } catch (_) {}
    try {
      _pty.kill();
    } catch (_) {}
    _currentState = SessionState.disconnected;
    if (!_stateController.isClosed) {
      _stateController.add(SessionState.disconnected);
      await _stateController.close();
    }
    if (!_outputController.isClosed) {
      await _outputController.close();
    }
    if (!_inputController.isClosed) {
      await _inputController.close();
    }
  }
}
