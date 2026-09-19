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
    testWidgets('Renders Shellit brand identity, version, and update button', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Shellit'), findsOneWidget);
      expect(find.text('0.8.0'), findsOneWidget);
      expect(find.text('α'), findsOneWidget);
      expect(find.text('Check for updates'), findsOneWidget);
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
      expect(find.text('Report an Issue'), findsOneWidget);
    });
  });
}
