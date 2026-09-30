import 'dart:async';
import 'dart:convert';
import 'package:core_foundation/core_foundation.dart';
import 'package:xterm/xterm.dart';

import '../../shell_integration/shell_integration_controller.dart';

/// Entry holding the live [Terminal], [TerminalController], and stream subscription
/// for an active [ITerminalSession], ensuring scrollback and state survive across
/// splits, tab switches, and undocking.
class TerminalSessionEntry {
  final Terminal terminal;
  final TerminalController controller;
  final StreamSubscription<dynamic> outputSubscription;
  final ShellIntegrationController shellIntegration;

  TerminalSessionEntry({
    required this.terminal,
    required this.controller,
    required this.outputSubscription,
    required this.shellIntegration,
  });

  void dispose() {
    outputSubscription.cancel();
    controller.dispose();
    shellIntegration.dispose();
  }
}

/// Registry ensuring terminal state and history are retained across UI reparenting,
/// such as moving between standalone tabs and split matrix panes.
class TerminalSessionRegistry {
  static final TerminalSessionRegistry instance = TerminalSessionRegistry._();
  TerminalSessionRegistry._();

  final Map<String, TerminalSessionEntry> _entries = {};

  TerminalSessionEntry getOrCreate(ITerminalSession session) {
    var entry = _entries[session.id];
    if (entry == null) {
      final terminal = Terminal(maxLines: 5000);
      final controller = TerminalController();
      final shellIntegration = ShellIntegrationController();

      // Hook OSC 133 semantic shell integration
      terminal.onPrivateOSC = (code, args) {
        shellIntegration.handleOSC(code, args, terminal);
      };

      final sub = session.outputStream.listen(
        (bytes) {
          final decoded = utf8.decode(bytes, allowMalformed: true);
          terminal.write(decoded);
        },
        onError: (err) {
          terminal.write('\r\n[Session Error: $err]\r\n');
        },
        onDone: () {
          terminal.write('\r\n[Session disconnected]\r\n');
        },
      );
      entry = TerminalSessionEntry(
        terminal: terminal,
        controller: controller,
        outputSubscription: sub,
        shellIntegration: shellIntegration,
      );
      _entries[session.id] = entry;
    }
    return entry;
  }

  void remove(String sessionId) {
    final entry = _entries.remove(sessionId);
    entry?.dispose();
  }

  void clear() {
    for (final entry in _entries.values) {
      entry.dispose();
    }
    _entries.clear();
  }
}
