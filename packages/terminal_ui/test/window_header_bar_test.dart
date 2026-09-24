import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

void main() {
  group('WindowHeaderBar Widget Tests', () {
    testWidgets(
        'renders logo, Quick Connect button, Ctrl+K button, and window controls',
        (tester) async {
      bool quickConnectTapped = false;
      bool omniBarTapped = false;
      bool minimized = false;
      bool maximized = false;
      bool closed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ShellitTheme.obsidianDarkTheme,
          home: Scaffold(
            body: WindowHeaderBar(
              onQuickConnect: (target) => quickConnectTapped = true,
              onOmniBarOpen: () => omniBarTapped = true,
              onWindowMinimize: () => minimized = true,
              onWindowMaximize: () => maximized = true,
              onWindowClose: () => closed = true,
              isWindowMaximized: false,
            ),
          ),
        ),
      );

      // Verify ShellitLogo is rendered
      expect(find.byType(ShellitLogo), findsOneWidget);

      // Verify Quick Connect button is rendered and opens dialog
      expect(find.byIcon(Icons.bolt), findsOneWidget);
      await tester.tap(find.byIcon(Icons.bolt));
      await tester.pumpAndSettle();
      expect(find.text('Connect'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'root@10.0.0.1:22');
      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();
      expect(quickConnectTapped, isTrue);

      // Verify Search icon (Ctrl+K) is rendered and can be tapped
      final searchButton = find.byIcon(Icons.search);
      expect(searchButton, findsOneWidget);
      await tester.tap(searchButton);
      await tester.pump();
      expect(omniBarTapped, isTrue);

      // Verify WindowControls (minimize, maximize, close) are rendered
      final windowGestures = find.descendant(
        of: find.byType(WindowControls),
        matching: find.byType(GestureDetector),
      );
      expect(windowGestures, findsNWidgets(3));

      await tester.tap(windowGestures.at(0)); // minimize
      await tester.pump();
      expect(minimized, isTrue);

      await tester.tap(windowGestures.at(1)); // maximize
      await tester.pump();
      expect(maximized, isTrue);

      await tester.tap(windowGestures.at(2)); // close
      await tester.pump();
      expect(closed, isTrue);
    });

    testWidgets('supports custom dragAreaBuilder and trailing widget',
        (tester) async {
      bool dragAreaBuilt = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ShellitTheme.obsidianDarkTheme,
          home: Scaffold(
            body: WindowHeaderBar(
              trailing: const Icon(Icons.hub, key: Key('trailing_mcp')),
              dragAreaBuilder: (ctx, child) {
                dragAreaBuilt = true;
                return Container(
                  key: const Key('drag_region'),
                  child: child,
                );
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('trailing_mcp')), findsOneWidget);
      expect(find.byKey(const Key('drag_region')), findsOneWidget);
      expect(dragAreaBuilt, isTrue);
    });
  });
}
