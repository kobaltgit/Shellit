import 'package:core_foundation/core_foundation.dart';
import 'package:test/test.dart';

void main() {
  group('DangerousCommandChecker tests (BUG-039 Regression & Enhancements)',
      () {
    test('Correctly identifies standard dangerous commands', () {
      final dangerous = [
        'rm -rf /',
        'rm -rf /var/www/*',
        'rm -fr /etc/nginx',
        'rm -r -f /data',
        'rm -f -r /data',
        'rm --recursive /var',
        'rm --recursive --force /data',
        'rm --force --recursive /data',
        'rm -rfv /opt',
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

      for (final cmd in dangerous) {
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

    test(
        'Correctly detects bypasses: absolute paths, systemctl, wipefs, truncate',
        () {
      final bypassCommands = [
        '/bin/rm -rf /',
        '/usr/bin/rm -fr /var/lib',
        'sudo /bin/rm -rf /tmp',
        '/sbin/reboot',
        '/sbin/shutdown -r now',
        '/sbin/poweroff',
        'poweroff',
        'halt',
        'systemctl reboot',
        'systemctl poweroff',
        'systemctl emergency',
        'wipefs -a /dev/sdb',
        'truncate -s 0 /var/log/syslog',
        'chmod -R 777 /var/www',
        'chmod -R 000 /etc',
        'kill -9 1',
        'truncate table audit_logs',
        'drop schema public',
        '> /dev/nvme0n1',
        '> /dev/vda',
      ];

      for (final cmd in bypassCommands) {
        expect(
          DangerousCommandChecker.isDangerous(cmd),
          isTrue,
          reason:
              'Expected bypass command "$cmd" to be caught by DangerousCommandChecker',
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
        'systemctl restart nginx',
        'docker ps -a',
        'tail -f access.log',
        'git pull origin main',
        'curl https://api.ipify.org',
        'htop',
        'vim /etc/hosts',
        'rm file.txt',
        'rm -i file.txt',
        'echo "reboot scheduled"',
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

    test('cleanPromptAndExtractCommand strips various shell prompts', () {
      expect(
        DangerousCommandChecker.cleanPromptAndExtractCommand(
            'kobalt@vpn-1-xagq8g:~\$ rm -rf /'),
        'rm -rf /',
      );
      expect(
        DangerousCommandChecker.cleanPromptAndExtractCommand(
            'root@prod-db:/var/lib# /bin/rm -rf *'),
        '/bin/rm -rf *',
      );
      expect(
        DangerousCommandChecker.cleanPromptAndExtractCommand(
            '[user@hostname dir]\$ reboot'),
        'reboot',
      );
      expect(
        DangerousCommandChecker.cleanPromptAndExtractCommand('> shutdown now'),
        'shutdown now',
      );
      expect(
        DangerousCommandChecker.cleanPromptAndExtractCommand('# poweroff'),
        'poweroff',
      );
    });
  });
}
