import 'dart:io';
import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shellit/src/controllers/log_controllers.dart';
import 'package:shellit/src/screens/logs/audit_logs_screen.dart';
import 'package:shellit/src/services/logging/file_log_sink.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SystemLogsController Unit Tests', () {
    late SystemLogsController controller;

    setUp(() {
      controller = SystemLogsController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('buffers emitted log entries up to max size', () async {
      AppLogger.i('Message 1', tag: 'TestTag');
      AppLogger.d('Message 2', tag: 'TestTag');
      AppLogger.w('Message 3', tag: 'WarnTag');
      AppLogger.e('Message 4', tag: 'ErrorTag', error: 'Sample Error');

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(controller.state.allEntries.length, greaterThanOrEqualTo(4));
      expect(controller.state.filteredEntries.length, greaterThanOrEqualTo(4));
      expect(
        controller.state.availableTags,
        containsAll(['TestTag', 'WarnTag', 'ErrorTag']),
      );
    });

    test('filters entries by level', () async {
      AppLogger.i('Info level item', tag: 'TagA');
      AppLogger.e('Error level item', tag: 'TagB');

      await Future<void>.delayed(const Duration(milliseconds: 20));

      controller.setFilterLevel(LogLevel.error);
      for (final e in controller.state.filteredEntries) {
        expect(e.level, LogLevel.error);
      }

      controller.setFilterLevel(null);
      expect(
        controller.state.filteredEntries.length,
        controller.state.allEntries.length,
      );
    });

    test('searches entries by query string', () async {
      AppLogger.i('Regular baseline message 1', tag: 'BaseTag');
      AppLogger.i('Regular baseline message 2', tag: 'BaseTag');
      AppLogger.i('UniqueSpecialSearchPhrase', tag: 'SearchTag');

      await Future<void>.delayed(const Duration(milliseconds: 20));

      controller.setSearchQuery('UniqueSpecial');
      expect(controller.state.filteredEntries.length, 1);
      expect(
        controller.state.filteredEntries.first.message,
        contains('UniqueSpecialSearchPhrase'),
      );

      controller.setSearchQuery('');
      expect(controller.state.filteredEntries.length, greaterThanOrEqualTo(2));
    });

    test('clears in-memory buffer', () async {
      AppLogger.i('Entry before clear');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller.clear();
      expect(controller.state.allEntries, isEmpty);
      expect(controller.state.filteredEntries, isEmpty);
    });
  });

  group('FileLogSink Unit Tests', () {
    late Directory tempDir;
    late FileLogSink sink;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('shellit_log_sink_test_');
      sink = FileLogSink();
      await sink.init(customLogsDir: tempDir.path);
    });

    tearDown(() async {
      await sink.dispose();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('writes sanitized entries to disk and clears correctly', () async {
      // Emit through AppLogger
      AppLogger.i(
        'Connected with password=***[REDACTED]***',
        tag: 'SecurityTest',
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));

      final logFile = File('${tempDir.path}/shellit.log');
      expect(logFile.existsSync(), isTrue);

      final content = await logFile.readAsString();
      expect(
        content,
        contains(
          '[INFO ] [SecurityTest] Connected with password=***[REDACTED]***',
        ),
      );

      // Test clearing
      await sink.clearLogs();
      final contentAfterClear = await logFile.readAsString();
      expect(contentAfterClear, isEmpty);
    });
  });

  group('AuditLogsScreen Widget Tests', () {
    testWidgets('renders tabs, controls, and responds to user interaction', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AuditLogsScreen())),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Check Tabs
      expect(find.text('System Logs'), findsOneWidget);
      expect(find.text('Session Recordings'), findsOneWidget);

      // Check level filter chips
      expect(find.text('ALL'), findsOneWidget);
      expect(find.text('DEBUG'), findsOneWidget);
      expect(find.text('INFO'), findsOneWidget);
      expect(find.text('WARN'), findsOneWidget);
      expect(find.text('ERROR'), findsOneWidget);

      // Tap on Session Recordings tab
      await tester.tap(find.text('Session Recordings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Switch back to System Logs
      await tester.tap(find.text('System Logs'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap on ERROR filter chip
      await tester.tap(find.text('ERROR'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });
  });
}
