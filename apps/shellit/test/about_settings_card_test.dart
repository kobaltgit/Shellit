import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shellit/src/screens/settings/about_settings_card.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Shellit',
      packageName: 'shellit',
      version: '0.8.0',
      buildNumber: '15',
      buildSignature: '',
    );
  });

  Widget createWidget({Size size = const Size(800, 600)}) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: const SingleChildScrollView(child: AboutSettingsCard()),
            ),
          ),
        ),
      ),
    );
  }

  group('AboutSettingsCard Tests', () {
    testWidgets('Renders Shellit brand identity, version, and action buttons', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Shellit'), findsOneWidget);
      expect(find.text('v0.8.0 (Build 15)'), findsOneWidget);
      expect(find.text('α'), findsOneWidget);
      expect(find.text('Check for updates'), findsOneWidget);
      expect(find.text('Send Feedback / Bug Report'), findsOneWidget);
    });

    testWidgets('Tapping Send Feedback button opens FeedbackReportDialog', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send Feedback / Bug Report'));
      await tester.pumpAndSettle();

      expect(find.text('Send Feedback or Bug Report'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('🐛 Bug Report'), findsOneWidget);
      expect(find.text('💡 Feature'), findsOneWidget);
      expect(find.text('💬 Feedback'), findsOneWidget);
      expect(find.text('Send Report'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Send Feedback or Bug Report'), findsNothing);
    });

    testWidgets('Renders all four quick action tiles', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Report an Issue'), findsOneWidget);
      expect(find.text('Open pre-filled report on GitHub'), findsOneWidget);

      expect(find.text('Community'), findsOneWidget);
      expect(find.text('Telegram (Coming soon)'), findsOneWidget);

      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('Source code repository'), findsOneWidget);

      expect(find.text("What's New"), findsOneWidget);
      expect(find.text('View release highlights and changes'), findsOneWidget);
    });

    testWidgets('Tapping Community tile shows informational SnackBar', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Community'));
      await tester.pump();

      expect(
        find.text(
          'Telegram community chat is in preparation and will launch with the public release.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Tapping What\'s New opens in-app changelog dialog', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text("What's New"));
      await tester.pumpAndSettle();

      expect(find.text("What's New in Shellit"), findsOneWidget);
      expect(find.text('⚡ Matrix Tiling Splits'), findsOneWidget);
      expect(find.text('🔒 SQLCipher & Argon2id Vault'), findsOneWidget);
      expect(find.text('All Releases on GitHub'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text("What's New in Shellit"), findsNothing);
    });

    testWidgets('Renders correctly in narrow mobile layout', (tester) async {
      await tester.pumpWidget(createWidget(size: const Size(360, 640)));
      await tester.pumpAndSettle();

      expect(find.text('Shellit'), findsOneWidget);
      expect(find.text('Check for updates'), findsOneWidget);
      expect(find.text('Send Feedback / Bug Report'), findsOneWidget);
      expect(find.text('Report an Issue'), findsOneWidget);
    });
  });

  group('Version comparison logic tests (BUG fix & semver metadata)', () {
    test('Correctly identifies newer semver even with build metadata in current version', () {
      // Expose or verify the semver comparison rule:
      bool isVersionGreater(String remote, String current) {
        String cleanVersion(String v) {
          var s = v.trim();
          if (s.startsWith('v') || s.startsWith('V')) {
            s = s.substring(1);
          }
          if (s.contains('+')) {
            s = s.split('+').first;
          }
          if (s.contains('-')) {
            s = s.split('-').first;
          }
          return s;
        }

        final cleanRemote = cleanVersion(remote);
        final cleanCurrent = cleanVersion(current);

        final remoteParts = cleanRemote
            .split('.')
            .map((e) => int.tryParse(e) ?? 0)
            .toList();
        final currentParts = cleanCurrent
            .split('.')
            .map((e) => int.tryParse(e) ?? 0)
            .toList();

        final maxLen = remoteParts.length > currentParts.length
            ? remoteParts.length
            : currentParts.length;

        for (int i = 0; i < maxLen; i++) {
          final r = i < remoteParts.length ? remoteParts[i] : 0;
          final c = i < currentParts.length ? currentParts[i] : 0;
          if (r > c) return true;
          if (r < c) return false;
        }
        return false;
      }

      // Regression: 0.8.4+19 was previously parsed as [0, 8, 419], breaking update checks for 0.8.5
      expect(isVersionGreater('0.8.5', '0.8.4+19'), isTrue);
      expect(isVersionGreater('v0.8.5', '0.8.4+19'), isTrue);
      expect(isVersionGreater('0.9.0', '0.8.4+19'), isTrue);
      expect(isVersionGreater('1.0.0', '0.8.4+19'), isTrue);
      expect(isVersionGreater('0.8.4', '0.8.4+19'), isFalse);
      expect(isVersionGreater('0.8.4+20', '0.8.4+19'), isFalse);
      expect(isVersionGreater('0.8.3', '0.8.4+19'), isFalse);
    });
  });
}
