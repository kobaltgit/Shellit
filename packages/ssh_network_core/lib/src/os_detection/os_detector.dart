import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:core_foundation/core_foundation.dart';
import 'package:dartssh2/dartssh2.dart';

/// Service responsible for probing and determining the remote operating system / distribution.
class OsDetector implements IOsDetector {
  const OsDetector();

  @override
  Future<OsType> detectOs(dynamic sshClient) async {
    if (sshClient is! SSHClient) {
      return OsType.genericServer;
    }

    try {
      // Execute non-blocking probe command on an independent channel
      final session = await sshClient
          .execute(
            'cat /etc/os-release 2>/dev/null || uname -s 2>/dev/null',
          )
          .timeout(const Duration(seconds: 4));

      final outputBuffer = StringBuffer();
      final completer = Completer<String>();

      final sub = session.stdout.listen(
        (Uint8List data) {
          outputBuffer.write(utf8.decode(data, allowMalformed: true));
        },
        onError: (_) {
          if (!completer.isCompleted) {
            completer.complete(outputBuffer.toString());
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete(outputBuffer.toString());
          }
        },
      );

      // Give at most 3 seconds for output collection
      final rawOutput = await completer.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          sub.cancel();
          return outputBuffer.toString();
        },
      );

      try {
        session.close();
      } catch (_) {}

      final detected = parseOsRelease(rawOutput);
      AppLogger.i('Detected remote OS: $detected', tag: 'OsDetector');
      return detected;
    } catch (e, stack) {
      AppLogger.w('OS detection probe failed or timed out: $e',
          tag: 'OsDetector', stackTrace: stack);
      return OsType.genericServer;
    }
  }

  @override
  OsType parseOsRelease(String output) {
    if (output.trim().isEmpty) {
      return OsType.genericServer;
    }

    // 1. Extract exact ID= value if present in /etc/os-release
    final idRegex = RegExp(
      r'''^ID\s*=\s*["']?([a-zA-Z0-9_-]+)["']?''',
      multiLine: true,
    );
    final idMatch = idRegex.firstMatch(output);
    if (idMatch != null) {
      final id = idMatch.group(1)!.toLowerCase();
      switch (id) {
        case 'ubuntu':
          return OsType.ubuntu;
        case 'debian':
          return OsType.debian;
        case 'raspbian':
          return OsType.raspberryPi;
        case 'alpine':
          return OsType.alpine;
        case 'arch':
        case 'manjaro':
        case 'endeavouros':
          return OsType.arch;
        case 'fedora':
          return OsType.fedora;
        case 'rocky':
          return OsType.rocky;
        case 'almalinux':
        case 'alma':
          return OsType.almalinux;
        case 'rhel':
          return OsType.redhat;
        case 'centos':
          return OsType.centos;
        case 'openwrt':
          return OsType.router;
      }
    }

    final lower = output.toLowerCase();

    // 2. Specific matching in output
    if (lower.contains('rocky')) return OsType.rocky;
    if (lower.contains('almalinux') || lower.contains('alma linux')) {
      return OsType.almalinux;
    }
    if (lower.contains('red hat') ||
        lower.contains('rhel') ||
        lower.contains('redhat')) {
      return OsType.redhat;
    }
    if (lower.contains('centos')) return OsType.centos;
    if (lower.contains('ubuntu')) return OsType.ubuntu;
    if (lower.contains('raspbian') || lower.contains('raspberry')) {
      return OsType.raspberryPi;
    }
    if (lower.contains('debian')) return OsType.debian;
    if (lower.contains('alpine')) return OsType.alpine;
    if (lower.contains('arch') ||
        lower.contains('manjaro') ||
        lower.contains('endeavouros')) {
      return OsType.arch;
    }
    if (lower.contains('fedora')) return OsType.fedora;
    if (lower.contains('darwin') ||
        lower.contains('macos') ||
        lower.contains('mac os')) {
      return OsType.macOS;
    }
    if (lower.contains('freebsd') ||
        lower.contains('openbsd') ||
        lower.contains('netbsd')) {
      return OsType.freebsd;
    }
    if (lower.contains('openwrt') ||
        lower.contains('routeros') ||
        lower.contains('mikrotik') ||
        lower.contains('vyos') ||
        lower.contains('pfsense') ||
        lower.contains('opnsense')) {
      return OsType.router;
    }
    if (lower.contains('windows') ||
        lower.contains('cygwin') ||
        lower.contains('mingw') ||
        lower.contains('msys')) {
      return OsType.windows;
    }

    // Generic Linux or fallback
    return OsType.genericServer;
  }
}
