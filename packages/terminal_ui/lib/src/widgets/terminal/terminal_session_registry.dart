import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:core_foundation/core_foundation.dart';
import 'package:xterm/xterm.dart';

import '../../graphics/kitty_graphics_parser.dart';
import '../../graphics/terminal_graphics_registry.dart';
import '../../shell_integration/shell_integration_bootstrap.dart';
import '../../shell_integration/shell_integration_controller.dart';
import 'terminal_stream_coalescer.dart';

/// Entry holding the live [Terminal], [TerminalController], [TerminalStreamCoalescer],
/// and stream subscription for an active [ITerminalSession], ensuring scrollback and state survive across
/// splits, tab switches, and undocking.
class TerminalSessionEntry {
  final Terminal terminal;
  final TerminalController controller;
  final StreamSubscription<dynamic> outputSubscription;
  final ShellIntegrationController shellIntegration;
  final TerminalStreamCoalescer coalescer;
  final TerminalGraphicsRegistry graphicsRegistry;
  final KittyGraphicsStreamFilter graphicsFilter;
  bool isShellIntegrationInjected;

  TerminalSessionEntry({
    required this.terminal,
    required this.controller,
    required this.outputSubscription,
    required this.shellIntegration,
    TerminalStreamCoalescer? coalescer,
    TerminalGraphicsRegistry? graphicsRegistry,
    KittyGraphicsStreamFilter? graphicsFilter,
    this.isShellIntegrationInjected = false,
  })  : coalescer = coalescer ?? TerminalStreamCoalescer(terminal: terminal),
        graphicsRegistry = graphicsRegistry ?? TerminalGraphicsRegistry(),
        graphicsFilter = graphicsFilter ?? KittyGraphicsStreamFilter();

  void dispose() {
    outputSubscription.cancel();
    coalescer.flush();
    coalescer.dispose();
    graphicsRegistry.dispose();
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

  /// Injects OSC 133 semantic shell integration hook into [session].
  void injectShellIntegration(
    ITerminalSession session,
    TerminalSessionEntry entry, {
    bool permanent = false,
  }) {
    entry.isShellIntegrationInjected = true;
    final snippet = permanent
        ? ShellIntegrationBootstrap.permanentSnippet
        : ShellIntegrationBootstrap.sessionSnippet;
    session.inputStream.add(Uint8List.fromList(utf8.encode(snippet)));
  }

  TerminalSessionEntry getOrCreate(ITerminalSession session) {
    var entry = _entries[session.id];
    if (entry == null) {
      final terminal = Terminal(maxLines: 5000);
      final controller = TerminalController();
      final shellIntegration = ShellIntegrationController();
      final graphicsRegistry = TerminalGraphicsRegistry();
      final graphicsFilter = KittyGraphicsStreamFilter();

      // Hook OSC 133 semantic shell integration
      terminal.onPrivateOSC = (code, args) {
        shellIntegration.handleOSC(code, args, terminal);
      };

      final coalescer = TerminalStreamCoalescer(
        terminal: terminal,
        preWriteFilter: (bytes) {
          final result = graphicsFilter.processBytes(bytes);
          if (result.commands.isNotEmpty) {
            for (final cmd in result.commands) {
              graphicsRegistry.handleCommand(cmd, terminal);
            }
          }
          return result.cleanBytes;
        },
      );

      final sub = session.outputStream.listen(
        (bytes) {
          coalescer.addChunk(bytes);
        },
        onError: (err) {
          coalescer.flush();
          terminal.write('\r\n[Session Error: $err]\r\n');
        },
        onDone: () {
          coalescer.flush();
          terminal.write('\r\n[Session disconnected]\r\n');
        },
      );
      entry = TerminalSessionEntry(
        terminal: terminal,
        controller: controller,
        outputSubscription: sub,
        shellIntegration: shellIntegration,
        coalescer: coalescer,
        graphicsRegistry: graphicsRegistry,
        graphicsFilter: graphicsFilter,
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
