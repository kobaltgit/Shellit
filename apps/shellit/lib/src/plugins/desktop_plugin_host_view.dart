import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:core_foundation/core_foundation.dart';
import 'package:desktop_plugin_sdk/desktop_plugin_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_ui/terminal_ui.dart';
import 'package:webview_windows/webview_windows.dart';

import '../di/app_providers.dart';

/// Desktop host container that renders a `.shellit` plugin in an isolated WebView2 sandbox
/// and establishes a two-way JSON-RPC bridge with Shellit's active SSH terminal session.
class DesktopPluginHostView extends ConsumerStatefulWidget {
  final InstalledPlugin plugin;
  final VoidCallback? onClose;

  const DesktopPluginHostView({
    super.key,
    required this.plugin,
    this.onClose,
  });

  @override
  ConsumerState<DesktopPluginHostView> createState() =>
      _DesktopPluginHostViewState();
}

class _DesktopPluginHostViewState extends ConsumerState<DesktopPluginHostView> {
  final WebviewController _controller = WebviewController();
  final PluginStaticServer _staticServer = PluginStaticServer();

  bool _isInitialized = false;
  String? _errorMessage;
  StreamSubscription<dynamic>? _webMessageSub;
  StreamSubscription<Map<String, dynamic>>? _outgoingSub;

  @override
  void initState() {
    super.initState();
    _initPluginHost();
  }

  Future<void> _initPluginHost() async {
    if (kIsWeb || !Platform.isWindows) {
      setState(() {
        _errorMessage = 'Desktop plugins are currently supported on Windows (WebView2).';
      });
      return;
    }

    try {
      final bridge = ref.read(appPluginBridgeProvider);
      if (bridge is DesktopPluginBridge) {
        bridge.registerPlugin(widget.plugin.manifest);
        _registerRpcHandlers(bridge);
      }

      // 1. Start localhost HTTP server for the plugin directory
      final port = await _staticServer.start(widget.plugin.installDirectory);

      // 2. Initialize WebView2
      await _controller.initialize();
      await _controller.setBackgroundColor(const Color(0xFF181825));

      // 3. Listen to incoming JSON-RPC from WebView (window.chrome.webview.postMessage)
      _webMessageSub = _controller.webMessage.listen((dynamic raw) {
        _handleIncomingFromPlugin(raw);
      });

      // 4. Pipe outgoing JSON-RPC from Shellit to WebView
      if (bridge is DesktopPluginBridge) {
        _outgoingSub = bridge
            .outgoingMessagesStream(widget.plugin.manifest.id)
            .listen((message) {
          try {
            final jsonStr = json.encode(message);
            _controller.postWebMessage(jsonStr);
          } catch (e) {
            AppLogger.w('Failed to post web message to plugin: $e');
          }
        });
      }

      // 5. Load plugin entry URL
      final url = 'http://127.0.0.1:$port/${widget.plugin.manifest.entryPoint}';
      await _controller.loadUrl(url);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e, st) {
      AppLogger.e('Failed to initialize plugin WebView',
          tag: 'DesktopPluginHost', error: e, stackTrace: st);
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to launch plugin: $e';
        });
      }
    }
  }

  void _registerRpcHandlers(DesktopPluginBridge bridge) {
    // 1. terminal.runCommand
    bridge.registerHandler('terminal.runCommand', (pluginId, params) async {
      final command = params is Map ? params['command'] as String? : null;
      if (command == null || command.isEmpty) {
        return {'error': 'Missing command parameter'};
      }

      final activeTab = ref.read(sessionManagerProvider).activeTab;
      final session = activeTab?.terminalSession;

      final client = session?.underlyingClient;
      if (client != null) {
        try {
          final cleanCmd = command.endsWith('\n')
              ? command.substring(0, command.length - 1)
              : command;
          final resultBytes = await client.run(cleanCmd);
          final output = utf8.decode(resultBytes as List<int>);
          return {'output': output};
        } catch (err) {
          return {'error': err.toString()};
        }
      }

      // If no active terminal session is connected
      return {
        'error': 'No active SSH terminal session. Please connect to a server.'
      };
    });

    // 2. notifications.show
    bridge.registerHandler('notifications.show', (pluginId, params) async {
      if (!mounted) return {'status': 'ignored'};
      final title = params is Map ? params['title'] as String? : 'Shellit';
      final message = params is Map ? params['message'] as String? : '';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title: $message'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return {'status': 'shown'};
    });
  }

  void _handleIncomingFromPlugin(dynamic raw) {
    try {
      Map<String, dynamic> messageMap;
      if (raw is String) {
        messageMap = json.decode(raw) as Map<String, dynamic>;
      } else if (raw is Map) {
        messageMap = Map<String, dynamic>.from(raw);
      } else {
        return;
      }

      final bridge = ref.read(appPluginBridgeProvider);
      if (bridge is DesktopPluginBridge) {
        bridge.handleIncomingMessage(widget.plugin.manifest.id, messageMap);
      }
    } catch (e) {
      AppLogger.w('Malformed message received from plugin WebView: $e');
    }
  }

  void _handlePointerScroll(double deltaY) {
    if (!_isInitialized) return;
    try {
      _controller.executeScript('''
        (() => {
          const modal = document.querySelector('.modal.active');
          if (modal) {
            const logs = document.getElementById('logsTerminal');
            if (logs) logs.scrollTop += $deltaY;
            return;
          }
          const list = document.getElementById('containerList');
          if (list) {
            list.scrollTop += $deltaY;
          } else {
            window.scrollBy({ top: $deltaY, behavior: 'auto' });
          }
        })();
      ''');
    } catch (_) {}
  }

  void _notifyHostChanged(SessionTab? tab) {
    if (!_isInitialized) return;
    final payload = {
      'hostId': tab?.host?.id,
      'label': tab?.host?.label ?? 'No Active Session',
    };

    // 1. Post JSON-RPC notification through bridge
    final bridge = ref.read(appPluginBridgeProvider);
    if (bridge is DesktopPluginBridge) {
      bridge.postMessageToPlugin(widget.plugin.manifest.id, {
        'jsonrpc': '2.0',
        'method': 'host.changed',
        'params': payload,
      });
    }

    // 2. Direct JS execution fallback
    try {
      _controller.executeScript(
        'if (window.onHostChanged) window.onHostChanged(${json.encode(payload)});',
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _webMessageSub?.cancel();
    _outgoingSub?.cancel();
    _staticServer.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for tab switching to automatically update plugin data
    ref.listen(
      sessionManagerProvider.select((s) => s.activeTab?.id),
      (previous, next) {
        if (previous != next) {
          final activeTab = ref.read(sessionManagerProvider).activeTab;
          _notifyHostChanged(activeTab);
        }
      },
    );

    final activeTab = ref.watch(sessionManagerProvider).activeTab;
    final hostLabel = activeTab?.host?.label ?? 'No Active Session';

    return Container(
      width: 340,
      decoration: const BoxDecoration(
        color: ShellitColors.obsidianBackground,
        border: Border(
          left: BorderSide(color: ShellitColors.border),
        ),
      ),
      child: Column(
        children: [
          // Sub-header showing which server the plugin is bound to
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: ShellitColors.obsidianCard,
              border: Border(
                bottom: BorderSide(color: ShellitColors.border),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: ShellitColors.accentCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.developer_board_outlined,
                    color: ShellitColors.accentCyan,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.plugin.manifest.name,
                        style: const TextStyle(
                          color: ShellitColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Target: $hostLabel',
                        style: const TextStyle(
                          color: ShellitColors.accentCyan,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (widget.onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    color: ShellitColors.textMuted,
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    onPressed: widget.onClose,
                  ),
              ],
            ),
          ),

          // Main WebView Body with mouse wheel scrolling support
          Expanded(
            child: _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: ShellitColors.textSecondary,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : !_isInitialized
                    ? const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ShellitColors.accentCyan,
                        ),
                      )
                    : Listener(
                        onPointerSignal: (event) {
                          if (event is PointerScrollEvent) {
                            _handlePointerScroll(event.scrollDelta.dy);
                          }
                        },
                        child: Webview(_controller),
                      ),
          ),
        ],
      ),
    );
  }
}
