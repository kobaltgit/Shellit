import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Randomart unit tests', () {
    test('parses SHA256 base64 fingerprint correctly', () {
      const fp = 'SHA256:4yJq/f0zJq4uD8oD8oD8oD8oD8oD8oD8oD8oD8oD8o';
      final bytes = Randomart.parseFingerprint(fp);
      expect(bytes, isNotEmpty);
    });

    test('generates 11-line drunken bishop ASCII box with frame and markers',
        () {
      const fp = 'SHA256:ro3p7pZ4xV8w9K3L9Z4xV8w9K3L9Z4xV8w9K3L9Z4xV';
      final art = Randomart.generate(
        fingerprint: fp,
        keyType: 'ED25519',
        hashAlgo: 'SHA256',
      );

      final lines = art.split('\n');
      expect(lines.length, equals(11));

      // First line has [ED25519] header tag
      expect(lines[0].startsWith('+'), isTrue);
      expect(lines[0].endsWith('+'), isTrue);
      expect(lines[0].contains('[ED25519]'), isTrue);
      expect(lines[0].length, equals(19));

      // 9 middle lines are framed by '|' and have 17 chars inside
      for (int i = 1; i <= 9; i++) {
        expect(lines[i].startsWith('|'), isTrue);
        expect(lines[i].endsWith('|'), isTrue);
        expect(lines[i].length, equals(19));
      }

      // Last line has [SHA256] footer tag
      expect(lines[10].startsWith('+'), isTrue);
      expect(lines[10].endsWith('+'), isTrue);
      expect(lines[10].contains('[SHA256]'), isTrue);
      expect(lines[10].length, equals(19));

      // Visual art contains Start (S) or End (E)
      expect(art.contains('S') || art.contains('E'), isTrue);
    });

    test('generates deterministic art for identical input', () {
      const fp = 'SHA256:samplefingerprintfortestingdeterministic123';
      final art1 = Randomart.generate(fingerprint: fp, keyType: 'RSA');
      final art2 = Randomart.generate(fingerprint: fp, keyType: 'RSA');
      expect(art1, equals(art2));
    });
  });

  group('HostKeyDialog widget tests', () {
    const testHost = 'bastion.example.com';
    const testPort = 2222;
    const testKeyType = 'ED25519';
    const testFp = 'SHA256:u1234567890abcdef1234567890abcdef123456789';

    testWidgets('TOFU state (isMismatch == false) displays details and buttons',
        (tester) async {
      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          theme: ShellitTheme.obsidianDarkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await HostKeyDialog.show(
                    context: context,
                    hostname: testHost,
                    port: testPort,
                    keyType: testKeyType,
                    fingerprintSha256: testFp,
                    isMismatch: false,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Check title and TOFU intro
      expect(find.text('Trust this host?'), findsOneWidget);
      expect(find.textContaining('bastion.example.com:2222'), findsWidgets);
      expect(find.text(testKeyType), findsOneWidget);
      expect(find.text(testFp), findsOneWidget);

      // Check Randomart label and ASCII art
      expect(find.text('Visual Host Key (Randomart):'), findsOneWidget);
      expect(find.textContaining('[ED25519]'), findsOneWidget);

      // Check buttons
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Trust and Connect'), findsOneWidget);

      // Trust and connect returns true
      await tester.tap(find.text('Trust and Connect'));
      await tester.pumpAndSettle();
      expect(dialogResult, isTrue);
    });

    testWidgets('TOFU state Cancel button returns false', (tester) async {
      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          theme: ShellitTheme.obsidianDarkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await HostKeyDialog.show(
                    context: context,
                    hostname: testHost,
                    port: testPort,
                    keyType: testKeyType,
                    fingerprintSha256: testFp,
                    isMismatch: false,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(dialogResult, isFalse);
    });

    testWidgets(
        'MitM Mismatch state (isMismatch == true) blocks connection by default and shows danger warning',
        (tester) async {
      bool? dialogResult;
      const expectedFp = 'SHA256:old-trusted-fingerprint-00000000000000000';

      await tester.pumpWidget(
        MaterialApp(
          theme: ShellitTheme.obsidianDarkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await HostKeyDialog.show(
                    context: context,
                    hostname: testHost,
                    port: testPort,
                    keyType: testKeyType,
                    fingerprintSha256: testFp,
                    expectedFingerprint: expectedFp,
                    isMismatch: true,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Check Danger warning header
      expect(find.text('WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!'),
          findsOneWidget);
      expect(find.text('POTENTIAL SECURITY BREACH (MAN-IN-THE-MIDDLE)!'),
          findsOneWidget);

      // Check Old and New fingerprints
      expect(find.text(expectedFp), findsOneWidget);
      expect(find.text(testFp), findsOneWidget);

      // "Trust and Connect" button must be disabled by default (onPressed == null)
      final trustButtonFinder =
          find.widgetWithText(ElevatedButton, 'Trust and Connect');
      final ElevatedButton trustButton = tester.widget(trustButtonFinder);
      expect(trustButton.onPressed, isNull);

      // Verify Cancel works
      expect(find.text('Cancel (Abort Connection)'), findsOneWidget);

      // Check the security override confirmation checkbox
      final checkboxFinder = find.byType(Checkbox);
      expect(checkboxFinder, findsOneWidget);
      await tester.ensureVisible(checkboxFinder);
      await tester.pumpAndSettle();
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // After confirmation checkbox is ticked, button is enabled
      final ElevatedButton enabledButton = tester.widget(trustButtonFinder);
      expect(enabledButton.onPressed, isNotNull);

      // Tap Trust and Connect
      await tester.ensureVisible(trustButtonFinder);
      await tester.pumpAndSettle();
      await tester.tap(trustButtonFinder);
      await tester.pumpAndSettle();
      expect(dialogResult, isTrue);
    });
  });
}
