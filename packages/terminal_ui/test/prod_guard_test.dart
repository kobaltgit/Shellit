import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

void main() {
  group('DangerousCommandChecker tests', () {
    test('Correctly identifies dangerous destructive commands', () {
      final dangerousCommands = [
        'rm -rf /',
        'rm -rf /var/www/*',
        'rm -fr /etc/nginx',
        'rm -r -f /data',
        'rm --recursive /var',
        'reboot',
        'sudo reboot',
        'shutdown',
        'shutdown -h now',
        'init 0',
        'init 6',
        'mkfs /dev/sdb1',
        'mkfs.ext4 /dev/nvme0n1p1',
        'dd if=/dev/zero of=/dev/sda',
        'drop database production',
        'drop table users',
        ':(){ :|:& };:',
        '> /dev/sda',
      ];

      for (final cmd in dangerousCommands) {
        expect(
          DangerousCommandChecker.isDangerous(cmd),
          isTrue,
          reason: 'Expected "$cmd" to be detected as dangerous',
        );
        expect(
          DangerousCommandChecker.detectPatternDescription(cmd),
          isNotNull,
        );
      }
    });

    test('Correctly allows safe commands', () {
      final safeCommands = [
        'ls -la',
        'cd /var/log',
        'cat /etc/os-release',
        'pwd',
        'systemctl status nginx',
        'docker ps -a',
        'tail -f access.log',
        'git pull origin main',
        'curl https://api.ipify.org',
        'htop',
        'vim /etc/hosts',
      ];

      for (final cmd in safeCommands) {
        expect(
          DangerousCommandChecker.isDangerous(cmd),
          isFalse,
          reason: 'Expected "$cmd" to be recognized as safe',
        );
        expect(
          DangerousCommandChecker.detectPatternDescription(cmd),
          isNull,
        );
      }
    });
  });

  group('ProdGuardBorder widget tests', () {
    testWidgets('Renders red border and banner when isProduction is true',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProdGuardBorder(
              isProduction: true,
              hostLabel: 'PROD-DB-01',
              child: SizedBox(
                  width: 300, height: 200, child: Text('Terminal Body')),
            ),
          ),
        ),
      );

      expect(find.text('Terminal Body'), findsOneWidget);
      expect(
        find.text(
            'PROD ENVIRONMENT: PROD-DB-01 — DANGEROUS OPERATIONS GUARD ACTIVE'),
        findsOneWidget,
      );
    });

    testWidgets('Renders only child when isProduction is false',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProdGuardBorder(
              isProduction: false,
              hostLabel: 'DEV-SERVER',
              child: SizedBox(
                  width: 300, height: 200, child: Text('Terminal Body')),
            ),
          ),
        ),
      );

      expect(find.text('Terminal Body'), findsOneWidget);
      expect(
        find.textContaining('PROD ENVIRONMENT'),
        findsNothing,
      );
    });
  });

  group('ProdConfirmationDialog widget tests', () {
    testWidgets('Aborts command when Cancel is tapped', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: ShellitTheme.obsidianDarkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result =
                        await ProdConfirmationDialog.confirmDangerousCommand(
                      context: context,
                      command: 'rm -rf /var/data',
                      hostLabel: 'Production Primary',
                    );
                  },
                  child: const Text('Trigger'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      expect(find.text('PROD GUARD: Destructive Command'), findsOneWidget);
      expect(find.text('rm -rf /var/data'), findsOneWidget);

      await tester.tap(find.text('Cancel (Abort)'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('Confirms command when Execute Anyway is tapped',
        (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: ShellitTheme.obsidianDarkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result =
                        await ProdConfirmationDialog.confirmDangerousCommand(
                      context: context,
                      command: 'reboot',
                      hostLabel: 'Production Primary',
                    );
                  },
                  child: const Text('Trigger'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Execute Anyway'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });
}
