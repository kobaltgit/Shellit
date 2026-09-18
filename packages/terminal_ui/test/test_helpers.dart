import 'dart:async';
import 'dart:typed_data';
import 'package:core_foundation/core_foundation.dart';

class FakeTerminalSession implements ITerminalSession {
  @override
  final String id;
  @override
  final String hostId;

  final StreamController<Uint8List> _outputController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> _inputController =
      StreamController<Uint8List>.broadcast();
  final StreamController<SessionState> _stateController =
      StreamController<SessionState>.broadcast();

  final List<Uint8List> receivedInputs = [];
  TerminalDimensions lastDimensions =
      const TerminalDimensions(cols: 80, rows: 24);
  SessionState _state = SessionState.ready;
  bool isTerminated = false;

  FakeTerminalSession({
    required this.id,
    required this.hostId,
  }) {
    _inputController.stream.listen((bytes) {
      receivedInputs.add(bytes);
    });
  }

  @override
  Stream<Uint8List> get outputStream => _outputController.stream;

  @override
  Sink<Uint8List> get inputStream => _inputController.sink;

  @override
  SessionState get currentState => _state;

  @override
  Stream<SessionState> get stateStream => _stateController.stream;

  void emitOutput(Uint8List bytes) {
    _outputController.add(bytes);
  }

  void emitState(SessionState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  @override
  void resize(TerminalDimensions dimensions) {
    lastDimensions = dimensions;
  }

  @override
  Future<void> terminate() async {
    if (isTerminated) return;
    isTerminated = true;
    _state = SessionState.disconnected;
    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
    await _outputController.close();
    await _inputController.close();
    await _stateController.close();
  }

  @override
  dynamic get underlyingClient => null;

  @override
  ISessionRecorder? recorder;
}
