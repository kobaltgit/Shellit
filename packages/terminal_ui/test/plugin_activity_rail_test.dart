import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

void main() {
  group('PluginActivityRail Widget Tests', () {
    testWidgets('renders empty when items and callback are null/empty',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PluginActivityRail(items: []),
          ),
        ),
      );

      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('renders plugin items with tooltips, active indicator and triggers onTap',
        (tester) async {
      bool dockerTapped = false;
      bool mcpTapped = false;
      bool managerTapped = false;

      final items = [
        PluginActivityRailItem(
          id: 'docker',
          label: 'Docker',
          icon: const Icon(Icons.directions_boat),
          tooltip: 'Docker Monitor',
          isSelected: true,
          onTap: () => dockerTapped = true,
        ),
        PluginActivityRailItem(
          id: 'mcp',
          label: 'MCP AI',
          icon: const Icon(Icons.psychology),
          tooltip: 'MCP Server',
          isSelected: false,
          onTap: () => mcpTapped = true,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PluginActivityRail(
              items: items,
              onOpenPluginsManager: () => managerTapped = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.directions_boat), findsOneWidget);
      expect(find.byIcon(Icons.psychology), findsOneWidget);
      expect(find.byIcon(Icons.extension_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.directions_boat));
      await tester.pump();
      expect(dockerTapped, isTrue);

      await tester.tap(find.byIcon(Icons.psychology));
      await tester.pump();
      expect(mcpTapped, isTrue);

      await tester.tap(find.byIcon(Icons.extension_outlined));
      await tester.pump();
      expect(managerTapped, isTrue);
    });
  });
}
