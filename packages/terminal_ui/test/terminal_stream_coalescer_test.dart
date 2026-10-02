import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/src/widgets/terminal/terminal_session_registry.dart';
import 'package:terminal_ui/src/widgets/terminal/terminal_stream_coalescer.dart';
import 'package:xterm/xterm.dart';
import 'test_helpers.dart';

class RecordingTerminal extends Terminal {
  final List<String> writtenChunks = [];

  RecordingTerminal({super.maxLines = 1000});

  @override
  void write(String text) {
    writtenChunks.add(text);
    super.write(text);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TerminalStreamCoalescer Core Unit Tests', () {
    test(
        'coalesces multiple rapid byte chunks into a single write call on flush',
        () {
      final terminal = RecordingTerminal();
      final coalescer = TerminalStreamCoalescer(
        terminal: terminal,
        frameDuration: const Duration(milliseconds: 50),
      );

      coalescer.addChunk(utf8.encode('Hello '));
      coalescer.addChunk(utf8.encode('Terminal '));
      coalescer.addChunk(utf8.encode('Coalescer!\r\n'));

      expect(terminal.writtenChunks, isEmpty,
          reason: 'Writes should be buffered until flush or frame');
      expect(coalescer.hasBufferedBytes, isTrue);

      coalescer.flush();

      expect(terminal.writtenChunks.length, 1);
      expect(terminal.writtenChunks.first, 'Hello Terminal Coalescer!\r\n');
      expect(coalescer.hasBufferedBytes, isFalse);

      coalescer.dispose();
    });

    test(
        'coalesces chunks automatically on timer fallback if no scheduler ticks',
        () async {
      final terminal = RecordingTerminal();
      final flushedBatches = <int>[];
      final coalescer = TerminalStreamCoalescer(
        terminal: terminal,
        frameDuration: const Duration(milliseconds: 20),
        onBatchFlushed: (bytes, text) => flushedBatches.add(bytes),
      );

      coalescer.addChunk(utf8.encode('Chunk 1; '));
      coalescer.addChunk(utf8.encode('Chunk 2; '));

      // Wait past fallback timer
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(terminal.writtenChunks.length, 1);
      expect(terminal.writtenChunks.first, 'Chunk 1; Chunk 2; ');
      expect(flushedBatches, [terminal.writtenChunks.first.length]);

      coalescer.dispose();
    });

    test(
        'exceeding maxBatchBytes triggers immediate backpressure flush without waiting for frame',
        () {
      final terminal = RecordingTerminal();
      const maxBatch = 32;
      final coalescer = TerminalStreamCoalescer(
        terminal: terminal,
        maxBatchBytes: maxBatch,
        frameDuration:
            const Duration(seconds: 10), // large to ensure timer did not fire
      );

      final chunk1 = utf8.encode('Short message.'); // 14 bytes (< 32)
      coalescer.addChunk(chunk1);
      expect(terminal.writtenChunks, isEmpty);

      final chunk2 =
          utf8.encode(' This second part pushes buffer over 32 bytes limit!');
      coalescer.addChunk(chunk2);

      // Should flush immediately because 14 + 52 > 32
      expect(terminal.writtenChunks.length, 1);
      expect(terminal.writtenChunks.first,
          'Short message. This second part pushes buffer over 32 bytes limit!');
      expect(coalescer.hasBufferedBytes, isFalse);

      coalescer.dispose();
    });

    test(
        'correctly handles multi-byte UTF-8 split across chunk boundaries (Cyrillic & Emoji)',
        () {
      final terminal = RecordingTerminal();
      final coalescer = TerminalStreamCoalescer(
        terminal: terminal,
        frameDuration: const Duration(milliseconds: 50),
      );

      // 'Привет' in UTF-8:
      // П: [208, 159], р: [209, 128], и: [208, 184], в: [208, 178], е: [208, 181], т: [209, 130]
      final cyrillicBytes = utf8.encode('Привет');
      expect(cyrillicBytes.length, 12);

      // Send first 3 bytes: 'П' (2 bytes) + first half of 'р' (1 byte: 209)
      coalescer.addChunk(cyrillicBytes.sublist(0, 3));

      // Periodic flush before second half arrives:
      // The coalescer must retain the dangling leading byte (209) and NOT decode it as  (U+FFFD)
      coalescer.flush(isFinal: false);

      expect(terminal.writtenChunks.length, 1);
      expect(terminal.writtenChunks.first, 'П');
      expect(coalescer.hasBufferedBytes, isTrue,
          reason: 'Dangling 0xD1 byte should be kept in buffer');

      // Now send the rest of the bytes starting with 128 (second half of 'р')
      coalescer.addChunk(cyrillicBytes.sublist(3));
      coalescer.flush(isFinal: false);

      expect(terminal.writtenChunks.length, 2);
      expect(terminal.writtenChunks[1], 'ривет');

      // Now verify 4-byte Emoji: 🚀 (U+1F680 -> [240, 159, 154, 128])
      final rocketBytes = utf8.encode('🚀');
      expect(rocketBytes.length, 4);

      // Split 4-byte emoji into 2 + 2 bytes
      coalescer.addChunk(rocketBytes.sublist(0, 2));
      coalescer.flush(isFinal: false);

      // Emoji is incomplete, should not be output yet
      expect(terminal.writtenChunks.length, 2);
      expect(coalescer.hasBufferedBytes, isTrue);

      // Send remaining 2 bytes
      coalescer.addChunk(rocketBytes.sublist(2));
      coalescer.flush(isFinal: false);

      expect(terminal.writtenChunks.length, 3);
      expect(terminal.writtenChunks[2], '🚀');

      coalescer.dispose();
    });

    test('attach() binds to Stream and handles onDone and onError cleanly',
        () async {
      final terminal = RecordingTerminal();
      final coalescer = TerminalStreamCoalescer(
        terminal: terminal,
        frameDuration: const Duration(milliseconds: 50),
      );

      final controller = StreamController<List<int>>();
      var errorReceived = false;
      var doneCalled = false;

      coalescer.attach(
        controller.stream,
        onError: (err) {
          errorReceived = true;
        },
        onDone: () {
          doneCalled = true;
        },
      );

      controller.add(utf8.encode('Stream data line 1\r\n'));
      controller.add(utf8.encode('Stream data line 2\r\n'));

      // Flush happens automatically on done
      await controller.close();

      expect(terminal.writtenChunks.length, 1);
      expect(terminal.writtenChunks.first,
          'Stream data line 1\r\nStream data line 2\r\n');
      expect(doneCalled, isTrue);
      expect(errorReceived, isFalse);

      coalescer.dispose();
    });

    test('dispose() flushes remaining buffer and ignores subsequent chunks',
        () {
      final terminal = RecordingTerminal();
      final coalescer = TerminalStreamCoalescer(terminal: terminal);

      coalescer.addChunk(utf8.encode('Buffered before dispose'));
      expect(terminal.writtenChunks, isEmpty);

      coalescer.dispose();

      expect(terminal.writtenChunks.length, 1);
      expect(terminal.writtenChunks.first, 'Buffered before dispose');
      expect(coalescer.isDisposed, isTrue);

      // After dispose
      coalescer.addChunk(utf8.encode('Should be ignored'));
      coalescer.flush();
      expect(terminal.writtenChunks.length, 1,
          reason: 'No new writes after dispose');
    });

    test('flushes buffered data before invoking onError on stream failure',
        () async {
      final terminal = RecordingTerminal();
      final coalescer = TerminalStreamCoalescer(terminal: terminal);
      final controller = StreamController<List<int>>();
      Object? capturedError;

      coalescer.attach(
        controller.stream,
        onError: (err) {
          capturedError = err;
        },
      );

      controller.add(utf8.encode('Pending output before crash'));
      controller.addError(Exception('SSH Pipe Broken'));
      await pumpEventQueue();

      expect(terminal.writtenChunks.length, 1);
      expect(terminal.writtenChunks.first, 'Pending output before crash');
      expect(capturedError, isA<Exception>());

      coalescer.dispose();
      await controller.close();
    });

    testWidgets('flushes on Flutter VSync frame tick during pump',
        (tester) async {
      final terminal = RecordingTerminal();
      final coalescer = TerminalStreamCoalescer(
        terminal: terminal,
        frameDuration: const Duration(
            seconds: 5), // Ensure fallback timer does not trigger early
      );

      coalescer.addChunk(utf8.encode('Frame 1 piece 1; '));
      coalescer.addChunk(utf8.encode('Frame 1 piece 2.'));
      expect(terminal.writtenChunks, isEmpty);

      // Trigger Flutter VSync frame
      await tester.pump(const Duration(milliseconds: 16));

      expect(terminal.writtenChunks.length, 1);
      expect(terminal.writtenChunks.first, 'Frame 1 piece 1; Frame 1 piece 2.');

      coalescer.dispose();
    });

    test(
        'handles high throughput of 200 small chunks by batching without data loss',
        () {
      final terminal = RecordingTerminal();
      var batchCount = 0;
      final coalescer = TerminalStreamCoalescer(
        terminal: terminal,
        onBatchFlushed: (bytes, text) => batchCount++,
      );

      final expectedParts = <String>[];
      for (var i = 0; i < 200; i++) {
        final part = 'chunk-$i,';
        expectedParts.add(part);
        coalescer.addChunk(utf8.encode(part));
      }

      coalescer.flush();

      final fullOutput = terminal.writtenChunks.join();
      expect(fullOutput, expectedParts.join());
      expect(batchCount, 1,
          reason: 'All 200 rapid chunks flushed in a single batch');

      coalescer.dispose();
    });
  });

  group('TerminalSessionRegistry with Coalescer integration tests', () {
    test('getOrCreate configures coalescer and disposes cleanly', () async {
      final session =
          FakeTerminalSession(id: 'coalescer-session-1', hostId: 'host-1');
      final entry = TerminalSessionRegistry.instance.getOrCreate(session);

      expect(entry.coalescer, isNotNull);

      session.emitOutput(Uint8List.fromList(utf8.encode('First chunk; ')));
      session.emitOutput(Uint8List.fromList(utf8.encode('Second chunk; ')));

      // Allow async stream delivery to reach coalescer
      await pumpEventQueue();

      // Flush coalescer
      entry.coalescer.flush();

      // Terminal should receive the merged content
      final lines = entry.terminal.buffer.lines;
      final bufferLines = [
        for (var i = 0; i < lines.length; i++) lines[i].toString()
      ];
      final text = bufferLines.join();
      expect(text, contains('First chunk; Second chunk; '));

      TerminalSessionRegistry.instance.remove('coalescer-session-1');
      expect(entry.coalescer.isDisposed, isTrue);
    });
  });
}
