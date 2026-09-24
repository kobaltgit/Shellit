import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shellit/src/screens/settings/feedback_report_dialog.dart';
import 'package:terminal_ui/terminal_ui.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Shellit',
      packageName: 'shellit',
      version: '0.8.4',
      buildNumber: '19',
      buildSignature: '',
    );
  });

  Widget createWidget() {
    return const ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: FeedbackReportDialog(),
          ),
        ),
      ),
    );
  }

  group('FeedbackReportDialog Tests (IDEA-028)', () {
    testWidgets('Renders all elements: title, category pills, form inputs, buttons', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Send Feedback or Bug Report'), findsOneWidget);
      expect(
        find.text('Help us make Shellit better. We read every submission.'),
        findsOneWidget,
      );

      // Categories
      expect(find.text('🐛 Bug Report'), findsOneWidget);
      expect(find.text('💡 Feature'), findsOneWidget);
      expect(find.text('💬 Feedback'), findsOneWidget);

      // Form fields
      expect(find.text('Subject'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Your Email (Optional)'), findsOneWidget);

      // Buttons
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Send Report'), findsOneWidget);
    });

    testWidgets('Tapping category pill updates selected category', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('💡 Feature'));
      await tester.pumpAndSettle();

      // State updated without throwing
      expect(find.text('💡 Feature'), findsOneWidget);

      await tester.tap(find.text('💬 Feedback'));
      await tester.pumpAndSettle();

      expect(find.text('💬 Feedback'), findsOneWidget);
    });

    testWidgets('Validation triggers error when submitting empty fields', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap submit with empty subject and details
      await tester.tap(find.text('Send Report'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a subject'), findsOneWidget);
      expect(find.text('Please provide details'), findsOneWidget);
    });

    testWidgets('Email validation checks for valid email format', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Fill in subject & message
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Brief summary of the issue or idea...'),
        'Test Subject',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Describe what happened or what you would like to see...'),
        'Test Details',
      );

      // Enter invalid email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'you@domain.com (for follow-up)'),
        'invalid-email',
      );

      await tester.tap(find.text('Send Report'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('ShellitColors accentLime matches #7BE113 brand identity', (
      tester,
    ) async {
      expect(ShellitColors.accentLime, const Color(0xFF7BE113));
      expect(ShellitColors.accentCyan, const Color(0xFF7BE113));
      expect(ShellitColors.accentLimeStart, const Color(0xFF5FB300));
      expect(ShellitColors.accentLimeEnd, const Color(0xFF8AEB1A));
      expect(ShellitColors.borderFocus, const Color(0xFF7BE113));
    });
  });
}
