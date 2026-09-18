import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:core_foundation/core_foundation.dart';
import 'package:ssh_network_core/ssh_network_core.dart';
import 'package:test/test.dart';

void main() {
  group('SessionRecorder', () {
    late Directory tempDir;
    late String castPath;
    late String logPath;
    late SessionRecorder recorder;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('shellit_rec_test_');
      castPath = '${tempDir.path}/test_session.cast';
      logPath = '${tempDir.path}/test_session.log';
      recorder = SessionRecorder();
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('records terminal output into asciinema .cast and text log', () async {
      final meta = SessionRecordingEntity(
        id: 'rec-test-1',
        hostId: 'host-1',
        hostLabel: 'Test Server',
        username: 'ubuntu',
        environment: HostEnvironment.production,
        startedAt: DateTime.now(),
        castFilePath: castPath,
        logFilePath: logPath,
      );

      await recorder.startRecording(meta);
      expect(recorder.isRecording, isTrue);

      // Simulate user input (commands)
      recorder.recordInput(Uint8List.fromList(utf8.encode('uname -a\n')));
      recorder.recordInput(
        Uint8List.fromList(utf8.encode('docker ps\r')),
      );

      // Simulate terminal output
      recorder.recordOutput(
        Uint8List.fromList(utf8.encode('Linux test-server 5.15.0\r\n')),
      );
      recorder.recordOutput(
        Uint8List.fromList(utf8.encode('CONTAINER ID   IMAGE\r\n')),
      );

      final finalized = await recorder.stopRecording();
      expect(recorder.isRecording, isFalse);

      expect(finalized.commandCount, 2);
      expect(finalized.byteSize, greaterThan(0));
      expect(finalized.endedAt, isNotNull);

      // Verify .cast file content
      final castFile = File(castPath);
      expect(castFile.existsSync(), isTrue);
      final castLines = await castFile.readAsLines();
      expect(castLines.length, greaterThanOrEqualTo(3));

      // First line is JSON header
      final header = jsonDecode(castLines[0]) as Map<String, dynamic>;
      expect(header['version'], 2);
      expect(header['title'], contains('Test Server'));

      // Subsequent lines are asciinema events [time, "o", data]
      final event1 = jsonDecode(castLines[1]) as List<dynamic>;
      expect(event1[1], 'o');
      expect(event1[2], contains('Linux test-server'));

      // Verify .log file content
      final logFile = File(logPath);
      expect(logFile.existsSync(), isTrue);
      final logContent = await logFile.readAsString();
      expect(logContent, contains('Test Server'));
      expect(logContent, contains('Linux test-server 5.15.0'));
      expect(logContent, contains('CONTAINER ID   IMAGE'));
      expect(logContent, contains('Total Commands: 2'));
    });
  });
}
