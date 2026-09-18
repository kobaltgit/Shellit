import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

void main() {
  group('ShellitTheme and TerminalColorSchemes tests', () {
    test('ShellitColors constants are defined properly', () {
      expect(ShellitColors.obsidianBackground, const Color(0xFF151824));
      expect(ShellitColors.obsidianCard, const Color(0xFF1E2235));
      expect(ShellitColors.accentBlue, const Color(0xFF3B82F6));
      expect(ShellitColors.statusRed, const Color(0xFFEF4444));
      expect(ShellitColors.statusGreen, const Color(0xFF10B981));
    });

    test('ShellitTheme obsidianDarkTheme properties', () {
      final theme = ShellitTheme.obsidianDarkTheme;
      expect(theme.scaffoldBackgroundColor, ShellitColors.obsidianBackground);
      expect(theme.colorScheme.primary, ShellitColors.accentBlue);
      expect(theme.cardTheme.color, ShellitColors.obsidianCard);
    });

    test('TerminalColorSchemes contains all required schemes', () {
      expect(
          TerminalColorSchemes.allSchemes.containsKey('Obsidian Dark'), isTrue);
      expect(TerminalColorSchemes.allSchemes.containsKey('Dracula'), isTrue);
      expect(TerminalColorSchemes.allSchemes.containsKey('Nord'), isTrue);
      expect(TerminalColorSchemes.allSchemes.containsKey('OLED True Black'),
          isTrue);
      expect(TerminalColorSchemes.allSchemes.containsKey('Cyberpunk'), isTrue);

      final oled = TerminalColorSchemes.oledTrueBlack;
      expect(oled.background, const Color(0xFF000000));

      final obsidian = TerminalColorSchemes.obsidianDark;
      expect(obsidian.background, const Color(0xFF151824));
    });
  });

  group('HostCard widget tests', () {
    final now = DateTime.now();

    final prodHost = HostEntity(
      id: 'prod-1',
      label: 'Production Web App',
      hostname: 'prod.example.com',
      port: 22,
      username: 'admin',
      authType: HostAuthType.privateKey,
      environment: HostEnvironment.production,
      osType: OsType.ubuntu,
      tags: const ['prod', 'web', 'nginx'],
      dangerousCommandProtection: true,
      lastPingLatencyMs: 24, // < 50ms (green)
      createdAt: now,
      updatedAt: now,
    );

    final devHost = HostEntity(
      id: 'dev-1',
      label: 'Dev Kubernetes Node',
      hostname: '10.0.1.5',
      port: 2222,
      username: 'developer',
      authType: HostAuthType.password,
      environment: HostEnvironment.development,
      osType: OsType.alpine,
      tags: const ['k8s', 'dev'],
      lastPingLatencyMs: 120, // < 200ms (yellow)
      createdAt: now,
      updatedAt: now,
    );

    final offlineHost = HostEntity(
      id: 'off-1',
      label: 'Old Router',
      hostname: '192.168.1.1',
      port: 22,
      username: 'root',
      authType: HostAuthType.password,
      environment: HostEnvironment.defaultEnv,
      osType: OsType.router,
      lastPingLatencyMs: null, // offline
      createdAt: now,
      updatedAt: now,
    );

    testWidgets('Renders grid card with PROD badge, latency and tags',
        (tester) async {
      bool connected = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ShellitTheme.obsidianDarkTheme,
            home: Scaffold(
              body: SizedBox(
                width: 350,
                height: 220,
                child: HostCard(
                  host: prodHost,
                  onConnect: () => connected = true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Production Web App'), findsOneWidget);
      expect(find.text('admin@prod.example.com:22'), findsOneWidget);
      expect(find.text('PROD'), findsOneWidget);
      expect(find.text('#web'), findsOneWidget);
      expect(find.text('24ms'), findsOneWidget);

      await tester.tap(find.byType(HostCard));
      await tester.pump();
      expect(connected, isTrue);
    });

    testWidgets('Renders dense row view with latency and tags', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ShellitTheme.obsidianDarkTheme,
            home: Scaffold(
              body: SizedBox(
                width: 600,
                height: 80,
                child: HostCard(
                  host: devHost,
                  isDense: true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Dev Kubernetes Node'), findsOneWidget);
      expect(find.text('developer@10.0.1.5:2222'), findsOneWidget);
      expect(find.text('DEV'), findsOneWidget);
      expect(find.text('120ms'), findsOneWidget);
    });

    testWidgets('Renders offline host with offline status text',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ShellitTheme.obsidianDarkTheme,
            home: Scaffold(
              body: SizedBox(
                width: 350,
                height: 220,
                child: HostCard(
                  host: offlineHost,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Old Router'), findsOneWidget);
      expect(find.text('offline'), findsOneWidget);
    });
  });
}
