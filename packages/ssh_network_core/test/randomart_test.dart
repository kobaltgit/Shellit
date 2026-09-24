import 'dart:convert';

import 'package:ssh_network_core/ssh_network_core.dart';
import 'package:test/test.dart';

void main() {
  group('OpenSSH Randomart Generator (Drunken Bishop)', () {
    test('produces exact 11 lines and 19 characters per line box geometry', () {
      final art = Randomart.fromBytes(
        List<int>.filled(32, 0),
        title: 'TEST',
        hashAlgorithm: 'SHA256',
      );

      final lines = art.split('\n');
      expect(lines.length, equals(11));
      for (final line in lines) {
        expect(line.length, equals(19));
      }
      expect(lines.first.startsWith('+'), isTrue);
      expect(lines.first.endsWith('+'), isTrue);
      expect(lines.last.startsWith('+'), isTrue);
      expect(lines.last.endsWith('+'), isTrue);
      for (var i = 1; i <= 9; i++) {
        expect(lines[i].startsWith('|'), isTrue);
        expect(lines[i].endsWith('|'), isTrue);
      }
    });

    test('reproduces classic Dirk Loss paper test vector for RSA 2048 MD5', () {
      const fingerprint = 'fc:94:b0:c1:e5:b0:98:7c:58:43:99:76:97:ee:9f:b7';
      final art = Randomart.fromFingerprint(
        fingerprint,
        title: 'RSA 2048',
        hashAlgorithm: 'MD5',
      );

      final lines = art.split('\n');
      expect(lines[0], equals('+---[RSA 2048]----+'));
      expect(lines[1], equals('|       .=o.  .   |'));
      expect(lines[2], equals('|     . *+*. o    |'));
      expect(lines[3], equals('|      =.*..o     |'));
      expect(lines[4], equals('|       o + ..    |'));
      expect(lines[5], equals('|        S o.     |'));
      expect(lines[6], equals('|         o  .    |'));
      expect(lines[7], equals('|          .  . . |'));
      expect(lines[8], equals('|              o .|'));
      expect(lines[9], equals('|               E.|'));
      expect(lines[10], equals('+------[MD5]------+'));
    });

    test('reproduces OpenSSH ssh-keygen -lv output for ED25519 SHA256', () {
      const fingerprint = 'SHA256:odNASZ9R9wgUvflXXvW3mAknOsv+LO0eV0l6NskeNDw';
      final art = Randomart.fromFingerprint(
        fingerprint,
        title: 'ED25519 256',
      );

      final lines = art.split('\n');
      expect(lines[0], equals('+--[ED25519 256]--+'));
      expect(lines[1], equals('|     .o..o=o.    |'));
      expect(lines[2], equals('|     ... o o.o. .|'));
      expect(lines[3], equals('|      . +   .o.Eo|'));
      expect(lines[4], equals('|       + . oo.= X|'));
      expect(lines[5], equals('|      o S . +o+@=|'));
      expect(lines[6], equals('|       . o   +*.=|'));
      expect(lines[7], equals('|        . +. . o |'));
      expect(lines[8], equals('|         +..o    |'));
      expect(lines[9], equals('|        ..==     |'));
      expect(lines[10], equals('+----[SHA256]-----+'));
    });

    test('supports colon-separated hex without prefix', () {
      const hexFingerprint = 'fc:94:b0:c1:e5:b0:98:7c:58:43:99:76:97:ee:9f:b7';
      final art = Randomart.fromFingerprint(hexFingerprint);
      expect(art, contains('|        S o.     |'));
      expect(art, contains('|               E.|'));
    });

    test('supports raw hex string without colons', () {
      const rawHex = 'fc94b0c1e5b0987c5843997697ee9fb7';
      final art = Randomart.fromFingerprint(rawHex);
      expect(art, contains('|        S o.     |'));
      expect(art, contains('|               E.|'));
    });

    test('supports raw base64 string with and without padding', () {
      const base64Unpadded = 'odNASZ9R9wgUvflXXvW3mAknOsv+LO0eV0l6NskeNDw';
      final art1 = Randomart.fromFingerprint(base64Unpadded);
      expect(art1, contains('|      o S . +o+@=|'));

      const base64Padded = 'odNASZ9R9wgUvflXXvW3mAknOsv+LO0eV0l6NskeNDw=';
      final art2 = Randomart.fromFingerprint(base64Padded);
      expect(art2, equals(art1));
    });

    test(
        'Randomart.fromString correctly parses canonical SHA256:<base64> format',
        () {
      final rawBytes = List<int>.generate(32, (i) => (i * 17 + 5) % 256);
      final base64Hash = base64.encode(rawBytes).replaceAll('=', '');
      final canonicalFp = 'SHA256:$base64Hash';

      final artFromBytes = Randomart.fromBytes(
        rawBytes,
        title: 'ED25519 256',
        hashAlgorithm: 'SHA256',
      );
      final artFromString = Randomart.fromString(
        canonicalFp,
        title: 'ED25519 256',
      );

      expect(artFromString, equals(artFromBytes));
      expect(artFromString, contains('+----[SHA256]-----+'));
      expect(artFromString, contains('+--[ED25519 256]--+'));
    });

    test(
        'Randomart.fromString handles both padded and unpadded SHA256:<base64>',
        () {
      const unpadded = 'SHA256:odNASZ9R9wgUvflXXvW3mAknOsv+LO0eV0l6NskeNDw';
      const padded = 'SHA256:odNASZ9R9wgUvflXXvW3mAknOsv+LO0eV0l6NskeNDw=';

      final art1 = Randomart.fromString(unpadded, title: 'ED25519 256');
      final art2 = Randomart.fromString(padded, title: 'ED25519 256');

      expect(art1, equals(art2));
      expect(art1, contains('+----[SHA256]-----+'));
    });

    test('handles empty bytes gracefully with start and end at center', () {
      final art = Randomart.fromBytes(const []);
      final lines = art.split('\n');
      // Center (column 8, row 4) should have 'E' (overwriting 'S' in OpenSSH order)
      expect(lines[5], equals('|        E        |'));
    });

    test('throws ArgumentError on empty or invalid fingerprint', () {
      expect(() => Randomart.fromFingerprint(''), throwsArgumentError);
      expect(() => Randomart.fromFingerprint('   '), throwsArgumentError);
      expect(
        () => Randomart.fromFingerprint('invalid%%%base64!!!'),
        throwsArgumentError,
      );
    });

    test('handles long title by clamping/truncating within border width', () {
      final art = Randomart.fromBytes(
        [1, 2, 3],
        title: 'VERY LONG TITLE EXCEEDING MAXIMUM FIELD WIDTH',
      );
      final firstLine = art.split('\n').first;
      expect(firstLine.length, equals(19));
      expect(firstLine.startsWith('+'), isTrue);
      expect(firstLine.endsWith('+'), isTrue);
    });
  });
}
