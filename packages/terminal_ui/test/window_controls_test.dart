import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

void main() {
  group('WindowControls Widget Tests', () {
    testWidgets('renders shrink when all callbacks are null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WindowControls(),
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('renders minimize, maximize, close buttons and triggers callbacks',
        (tester) async {
      bool minimized = false;
      bool maximized = false;
      bool closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WindowControls(
              onMinimize: () => minimized = true,
              onMaximize: () => maximized = true,
              onClose: () => closed = true,
              isMaximized: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);

      // Tap minimize (first GestureDetector)
      await tester.tap(find.byType(GestureDetector).at(0));
      await tester.pump();
      expect(minimized, isTrue);

      // Tap maximize (second GestureDetector)
      await tester.tap(find.byType(GestureDetector).at(1));
      await tester.pump();
      expect(maximized, isTrue);

      // Tap close (third GestureDetector)
      await tester.tap(find.byType(GestureDetector).at(2));
      await tester.pump();
      expect(closed, isTrue);
    });
  });
}
