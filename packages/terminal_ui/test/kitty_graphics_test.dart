import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/src/graphics/kitty_graphics_parser.dart';
import 'package:terminal_ui/src/graphics/kitty_graphics_types.dart';
import 'package:terminal_ui/src/graphics/terminal_graphics_registry.dart';

void main() {
  group('KittyGraphicsStreamFilter tests', () {
    test('passes standard terminal text through unmodified when no APC present',
        () {
      final filter = KittyGraphicsStreamFilter();
      final input = Uint8List.fromList(
          utf8.encode('Hello world!\r\nuser@host:~\$ ls -la\r\n'));
      final result = filter.processBytes(input);

      expect(utf8.decode(result.cleanBytes),
          equals('Hello world!\r\nuser@host:~\$ ls -la\r\n'));
      expect(result.commands, isEmpty);
    });

    test(
        'extracts single-chunk Kitty graphics command and leaves surrounding text intact',
        () {
      final filter = KittyGraphicsStreamFilter();
      // 1x1 red PNG base64
      const b64Data =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
      final commandStr = '\x1b_Ga=T,f=100,s=1,v=1,m=0;$b64Data\x1b\\';
      final rawStream = Uint8List.fromList(
          utf8.encode('Before text\r\n$commandStr\r\nAfter text'));

      final result = filter.processBytes(rawStream);

      expect(utf8.decode(result.cleanBytes),
          equals('Before text\r\n\r\nAfter text'));
      expect(result.commands.length, equals(1));

      final cmd = result.commands.first;
      expect(cmd.action, equals(KittyAction.transmitDisplayAndSet));
      expect(cmd.format, equals(KittyFormat.png));
      expect(cmd.hasMoreChunks, isFalse);
      expect(cmd.payload, isNotNull);
      expect(base64.encode(cmd.payload!), equals(b64Data));
    });

    test('extracts multi-chunk Kitty graphics commands across chunk boundaries',
        () {
      final filter = KittyGraphicsStreamFilter();
      // Part 1: m=1
      final chunk1 =
          '\x1b_Ga=T,f=100,m=1;iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJ\x1b\\';
      // Part 2: m=0
      final chunk2 =
          '\x1b_Gm=0;AAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==\x1b\\';

      final res1 = filter
          .processBytes(Uint8List.fromList(utf8.encode('Prompt> $chunk1')));
      expect(utf8.decode(res1.cleanBytes), equals('Prompt> '));
      expect(res1.commands.length, equals(1));
      expect(res1.commands.first.hasMoreChunks, isTrue);

      final res2 = filter.processBytes(Uint8List.fromList(utf8.encode(chunk2)));
      expect(utf8.decode(res2.cleanBytes), isEmpty);
      expect(res2.commands.length, equals(1));
      expect(res2.commands.first.hasMoreChunks, isFalse);
    });

    test('handles APC sequence split across stream write boundaries', () {
      final filter = KittyGraphicsStreamFilter();
      const b64Data =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
      final fullSeq = '\x1b_Ga=T,f=100,m=0;$b64Data\x1b\\';

      // Split sequence right in the middle of base64
      final part1 = fullSeq.substring(0, 25);
      final part2 = fullSeq.substring(25);

      final res1 = filter.processBytes(Uint8List.fromList(utf8.encode(part1)));
      expect(res1.commands, isEmpty);
      expect(res1.cleanBytes, isEmpty); // Held in buffer

      final res2 = filter
          .processBytes(Uint8List.fromList(utf8.encode('$part2\r\nDone!')));
      expect(res2.commands.length, equals(1));
      expect(res2.commands.first.payload, isNotNull);
      expect(base64.encode(res2.commands.first.payload!), equals(b64Data));
      expect(utf8.decode(res2.cleanBytes), equals('\r\nDone!'));
    });

    test('parses delete action a=d cleanly', () {
      final filter = KittyGraphicsStreamFilter();
      final deleteSeq = '\x1b_Ga=d,d=a\x1b\\';
      final result = filter.processBytes(
          Uint8List.fromList(utf8.encode('Clearing screen\r\n$deleteSeq')));

      expect(utf8.decode(result.cleanBytes), equals('Clearing screen\r\n'));
      expect(result.commands.length, equals(1));
      expect(result.commands.first.action, equals(KittyAction.delete));
    });
  });

  group('TerminalGraphicsRegistry tests', () {
    test('handles clearAll and notifies listeners', () {
      final registry = TerminalGraphicsRegistry();
      var notified = false;
      registry.addListener(() => notified = true);

      registry.clearAll();
      expect(registry.placements, isEmpty);
      expect(notified, isTrue);
      registry.dispose();
    });

    test('disposes all images on dispose()', () {
      final registry = TerminalGraphicsRegistry();
      registry.dispose();
      expect(registry.placements, isEmpty);
    });
  });
}
