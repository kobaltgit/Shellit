import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:core_foundation/core_foundation.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:ssh_network_core/ssh_network_core.dart';
import 'package:test/test.dart';

class FakeSSHSession implements SSHSession {
  final StreamController<Uint8List> _stdoutController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> _stderrController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> _stdinController =
      StreamController<Uint8List>();
  final Completer<void> _doneCompleter = Completer<void>();

  int? lastResizeCols;
  int? lastResizeRows;
  bool isClosed = false;

  @override
  Stream<Uint8List> get stdout => _stdoutController.stream;

  @override
  Stream<Uint8List> get stderr => _stderrController.stream;

  @override
  StreamSink<Uint8List> get stdin => _stdinController.sink;

  @override
  Future<void> get done => _doneCompleter.future;

  @override
  void resizeTerminal(int width, int height,
      [int pixelWidth = 0, int pixelHeight = 0]) {
    lastResizeCols = width;
    lastResizeRows = height;
  }

  @override
  void close() {
    if (isClosed) return;
    isClosed = true;
    _stdoutController.close();
    _stderrController.close();
    _stdinController.close();
    if (!_doneCompleter.isCompleted) {
      _doneCompleter.complete();
    }
  }

  void emitStdout(String text) {
    _stdoutController.add(Uint8List.fromList(utf8.encode(text)));
  }

  void emitStderr(String text) {
    _stderrController.add(Uint8List.fromList(utf8.encode(text)));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSSHClient implements SSHClient {
  final Completer<void> _doneCompleter = Completer<void>();
  @override
  bool isClosed = false;

  @override
  Future<void> get done => _doneCompleter.future;

  @override
  void close() {
    if (isClosed) return;
    isClosed = true;
    if (!_doneCompleter.isCompleted) {
      _doneCompleter.complete();
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('TerminalSession Contract & Streaming Tests', () {
    late FakeSSHClient fakeClient;
    late FakeSSHSession fakeSession;
    late TerminalSession session;

    setUp(() {
      fakeClient = FakeSSHClient();
      fakeSession = FakeSSHSession();
      session = TerminalSession(
        id: 'term_test_1',
        hostId: 'host_123',
        client: fakeClient,
        sshSession: fakeSession,
      );
    });

    tearDown(() async {
      await session.terminate();
    });

    test('initializes in ready state with matching identifiers', () {
      expect(session.id, equals('term_test_1'));
      expect(session.hostId, equals('host_123'));
      expect(session.currentState, equals(SessionState.ready));
    });

    test('merges stdout and stderr into outputStream', () async {
      final received = <String>[];
      final sub = session.outputStream.listen((data) {
        received.add(utf8.decode(data));
      });

      fakeSession.emitStdout('Hello from stdout\n');
      fakeSession.emitStderr('Warning from stderr\n');

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(received, contains('Hello from stdout\n'));
      expect(received, contains('Warning from stderr\n'));

      await sub.cancel();
    });

    test('forwards inputStream to session stdin when isReadOnly is false',
        () async {
      final written = <int>[];
      fakeSession._stdinController.stream.listen(written.addAll);

      final input = utf8.encode('ls -la\n');
      session.inputStream.add(Uint8List.fromList(input));

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(utf8.decode(written), equals('ls -la\n'));
    });

    test('discards inputStream keystrokes when isReadOnly is true', () async {
      final readOnlySession = TerminalSession(
        id: 'term_readonly_test',
        hostId: 'host_ro',
        client: fakeClient,
        sshSession: fakeSession,
        isReadOnly: true,
      );

      final written = <int>[];
      fakeSession._stdinController.stream.listen(written.addAll);

      final input = utf8.encode('rm -rf / --no-preserve-root\n');
      readOnlySession.inputStream.add(Uint8List.fromList(input));

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(written, isEmpty);

      await readOnlySession.terminate();
    });

    test('supports dynamic toggling of isReadOnly at runtime', () async {
      final written = <int>[];
      fakeSession._stdinController.stream.listen(written.addAll);

      // Initially false -> input is allowed
      expect(session.isReadOnly, isFalse);
      session.inputStream.add(Uint8List.fromList(utf8.encode('step1;')));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(utf8.decode(written), equals('step1;'));

      // Enable readOnly -> input is discarded
      session.isReadOnly = true;
      session.inputStream
          .add(Uint8List.fromList(utf8.encode('dangerous_cmd;')));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(utf8.decode(written), equals('step1;'));

      // Disable readOnly -> input is accepted again
      session.isReadOnly = false;
      session.inputStream.add(Uint8List.fromList(utf8.encode('step2;')));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(utf8.decode(written), equals('step1;step2;'));
    });

    test('streams remote stdout and stderr even when isReadOnly is true',
        () async {
      final readOnlySession = TerminalSession(
        id: 'term_readonly_output',
        hostId: 'host_ro',
        client: fakeClient,
        sshSession: fakeSession,
        isReadOnly: true,
      );

      final received = <String>[];
      final sub = readOnlySession.outputStream.listen((data) {
        received.add(utf8.decode(data));
      });

      fakeSession.emitStdout('Remote logs\n');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(received, contains('Remote logs\n'));

      await sub.cancel();
      await readOnlySession.terminate();
    });

    test('resize changes remote terminal dimensions', () {
      session.resize(const TerminalDimensions(cols: 120, rows: 40));
      expect(fakeSession.lastResizeCols, equals(120));
      expect(fakeSession.lastResizeRows, equals(40));
    });

    test('terminate cleans up and transitions state to disconnected', () async {
      final states = <SessionState>[];
      final sub = session.stateStream.listen(states.add);

      await session.terminate();

      expect(session.currentState, equals(SessionState.disconnected));
      expect(states, contains(SessionState.disconnected));
      expect(fakeSession.isClosed, isTrue);
      expect(fakeClient.isClosed, isTrue);

      await sub.cancel();
    });

    test('terminate is idempotent when called multiple times', () async {
      await session.terminate();
      await session.terminate();
      expect(session.currentState, equals(SessionState.disconnected));
    });

    test('session ends gracefully when remote session closes', () async {
      final states = <SessionState>[];
      final sub = session.stateStream.listen(states.add);

      fakeSession.close();

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(session.currentState, equals(SessionState.disconnected));

      await sub.cancel();
    });
  });
}
