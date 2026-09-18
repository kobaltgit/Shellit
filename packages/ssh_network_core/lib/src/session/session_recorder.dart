import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:core_foundation/core_foundation.dart';

/// Records terminal sessions into asciinema v2 format (.cast) and human-readable text logs (.log).
class SessionRecorder implements ISessionRecorder {
  SessionRecordingEntity? _meta;
  IOSink? _castSink;
  IOSink? _textSink;
  Stopwatch? _stopwatch;
  bool _isRecording = false;
  int _byteSize = 0;
  int _commandCount = 0;

  @override
  bool get isRecording => _isRecording;

  SessionRecordingEntity? get currentMeta => _meta;

  @override
  Future<void> startRecording(SessionRecordingEntity meta) async {
    _meta = meta;
    _byteSize = 0;
    _commandCount = 0;
    _stopwatch = Stopwatch()..start();

    // Ensure parent directories exist
    if (meta.castFilePath.isNotEmpty) {
      final castFile = File(meta.castFilePath);
      await castFile.parent.create(recursive: true);
      _castSink = castFile.openWrite(mode: FileMode.writeOnly);

      // Write asciinema v2 header
      final header = {
        'version': 2,
        'width': 80,
        'height': 24,
        'timestamp': meta.startedAt.millisecondsSinceEpoch ~/ 1000,
        'title': 'Session: ${meta.hostLabel} (${meta.username})',
        'env': {'TERM': 'xterm-256color'},
      };
      _castSink!.writeln(jsonEncode(header));
    }

    if (meta.logFilePath.isNotEmpty) {
      final logFile = File(meta.logFilePath);
      await logFile.parent.create(recursive: true);
      _textSink = logFile.openWrite(mode: FileMode.writeOnly);
      _textSink!.writeln('=== Shellit Session Recording Log ===');
      _textSink!.writeln('Host: ${meta.hostLabel} (${meta.username})');
      _textSink!.writeln('Started: ${meta.startedAt.toIso8601String()}');
      _textSink!.writeln('=====================================\n');
    }

    _isRecording = true;
    AppLogger.i(
      'Started session recording for ${meta.hostLabel}',
      tag: 'SessionRecorder',
    );
  }

  @override
  void recordOutput(Uint8List bytes) {
    if (!_isRecording || _stopwatch == null) return;

    _byteSize += bytes.length;
    final elapsedSec = _stopwatch!.elapsedMicroseconds / 1000000.0;
    final text = utf8.decode(bytes, allowMalformed: true);

    // Write asciinema event: [time, "o", text]
    if (_castSink != null) {
      final event = jsonEncode([
        double.parse(elapsedSec.toStringAsFixed(6)),
        'o',
        text,
      ]);
      _castSink!.writeln(event);
    }

    // Write clean text log
    if (_textSink != null) {
      _textSink!.write(text);
    }
  }

  @override
  void recordInput(Uint8List bytes) {
    if (!_isRecording) return;

    // Detect Enter / Return key (CR or LF) to approximate command count
    for (final b in bytes) {
      if (b == 13 || b == 10) {
        _commandCount++;
      }
    }
  }

  @override
  Future<SessionRecordingEntity> stopRecording() async {
    if (!_isRecording || _meta == null) {
      throw StateError('Recorder is not actively recording');
    }

    _isRecording = false;
    _stopwatch?.stop();

    if (_textSink != null) {
      _textSink!.writeln('\n\n=====================================');
      _textSink!.writeln(
        'Session ended at: ${DateTime.now().toIso8601String()}',
      );
      _textSink!.writeln('Total Commands: $_commandCount');
      _textSink!.writeln('=====================================');
      await _textSink!.flush();
      await _textSink!.close();
      _textSink = null;
    }

    if (_castSink != null) {
      await _castSink!.flush();
      await _castSink!.close();
      _castSink = null;
    }

    final finalized = _meta!.copyWith(
      endedAt: DateTime.now(),
      byteSize: _byteSize,
      commandCount: _commandCount,
    );

    AppLogger.i(
      'Stopped session recording for ${_meta!.hostLabel} (${finalized.duration.inSeconds}s, $_byteSize bytes, $_commandCount commands)',
      tag: 'SessionRecorder',
    );

    _meta = null;
    return finalized;
  }
}
