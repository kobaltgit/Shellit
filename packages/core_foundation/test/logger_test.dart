import 'package:test/test.dart';
import 'package:core_foundation/core_foundation.dart';

void main() {
  group('AppLogger Sanitizer', () {
    test('sanitizes private keys from log messages', () {
      const msg =
          'Loaded key: -----BEGIN OPENSSH PRIVATE KEY-----\nb3BlbnNzaC1rZXktdjEAAAA\n-----END OPENSSH PRIVATE KEY----- for host';
      final clean = AppLogger.sanitize(msg);

      expect(clean, contains('***[REDACTED_PRIVATE_KEY]***'));
      expect(clean, isNot(contains('b3BlbnNzaC1rZXktdjEAAAA')));
    });

    test('sanitizes password and passphrase params', () {
      const msg =
          'Connecting with password: "superSecretPassword123" and token="abc-xyz"';
      final clean = AppLogger.sanitize(msg);

      expect(clean, contains('password=***[REDACTED]***'));
      expect(clean, contains('token=***[REDACTED]***'));
      expect(clean, isNot(contains('superSecretPassword123')));
    });

    test('broadcasts sanitized LogEntry to entryStream', () async {
      final entries = <LogEntry>[];
      final sub = AppLogger.entryStream.listen(entries.add);

      AppLogger.i('Testing info stream: password="plainPassword"');
      AppLogger.d('Testing debug stream');
      AppLogger.e('Testing error stream', error: 'Connection failed');

      // Wait a microtask
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(entries.length, 3);
      expect(entries[0].level, LogLevel.info);
      expect(entries[0].message, contains('password=***[REDACTED]***'));
      expect(entries[1].level, LogLevel.debug);
      expect(entries[2].level, LogLevel.error);
      expect(entries[2].error, 'Connection failed');

      await sub.cancel();
    });

    test('SessionRecordingEntity serializes and deserializes correctly', () {
      final now = DateTime.now();
      final entity = SessionRecordingEntity(
        id: 'rec-123',
        hostId: 'host-456',
        hostLabel: 'Production Server',
        username: 'root',
        environment: HostEnvironment.production,
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 5)),
        byteSize: 1024,
        commandCount: 15,
        castFilePath: '/tmp/rec.cast',
        logFilePath: '/tmp/rec.log',
      );

      final json = entity.toJson();
      final restored = SessionRecordingEntity.fromJson(json);

      expect(restored.id, entity.id);
      expect(restored.hostLabel, 'Production Server');
      expect(restored.environment, HostEnvironment.production);
      expect(restored.commandCount, 15);
      expect(restored.byteSize, 1024);
      expect(restored.castFilePath, '/tmp/rec.cast');
      expect(restored.duration.inMinutes, 5);
    });
  });
}
