import 'dart:typed_data';
import '../domain/entities/session_recording_entity.dart';

/// Contract for recording terminal input and output streams into asciinema .cast and text logs.
abstract class ISessionRecorder {
  /// Whether recording is currently active.
  bool get isRecording;

  /// Starts recording with session metadata.
  Future<void> startRecording(SessionRecordingEntity meta);

  /// Records terminal output bytes (stdout/stderr).
  void recordOutput(Uint8List bytes);

  /// Records terminal input bytes (keystrokes / commands).
  void recordInput(Uint8List bytes);

  /// Stops recording and finalizes files on disk, returning updated metadata.
  Future<SessionRecordingEntity> stopRecording();
}
