import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shellit/src/mcp/mcp_icon.dart';

void main() {
  group('McpVectorIcon Tests', () {
    testWidgets('renders SvgPicture with default size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: McpVectorIcon())),
        ),
      );

      final svgFinder = find.byType(SvgPicture);
      expect(svgFinder, findsOneWidget);

      final svgWidget = tester.widget<SvgPicture>(svgFinder);
      expect(svgWidget.width, 18);
      expect(svgWidget.height, 18);
      expect(svgWidget.colorFilter, isNull);
    });

    testWidgets('renders with custom size and color tint', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: McpVectorIcon(size: 24, color: Colors.red)),
          ),
        ),
      );

      final svgFinder = find.byType(SvgPicture);
      expect(svgFinder, findsOneWidget);

      final svgWidget = tester.widget<SvgPicture>(svgFinder);
      expect(svgWidget.width, 24);
      expect(svgWidget.height, 24);
      expect(svgWidget.colorFilter, isNotNull);
    });

    testWidgets('respects useOriginalColors flag even when color is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: McpVectorIcon(
                size: 20,
                color: Colors.blue,
                useOriginalColors: true,
              ),
            ),
          ),
        ),
      );

      final svgFinder = find.byType(SvgPicture);
      expect(svgFinder, findsOneWidget);

      final svgWidget = tester.widget<SvgPicture>(svgFinder);
      expect(svgWidget.width, 20);
      expect(svgWidget.height, 20);
      expect(svgWidget.colorFilter, isNull);
    });
  });
}
