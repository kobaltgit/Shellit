import 'dart:async';
import 'dart:convert';
import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';
import '../../localization/localization_scope.dart';
import '../../providers/ping_monitor_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/shellit_theme.dart';
import '../terminal/terminal_session_registry.dart';
import 'mobile_accessory_bar.dart';

class MobileTerminalScreen extends ConsumerStatefulWidget {
  final ITerminalSession session;
  final HostEntity? host;
  final VoidCallback onDisconnect;
  final VoidCallback? onReconnect;

  const MobileTerminalScreen({
    super.key,
    required this.session,
    this.host,
    required this.onDisconnect,
    this.onReconnect,
  });

  @override
  ConsumerState<MobileTerminalScreen> createState() =>
      _MobileTerminalScreenState();
}

class _MobileTerminalScreenState extends ConsumerState<MobileTerminalScreen> {
  late final Terminal _terminal;
  late final TerminalController _controller;
  late final FocusNode _focusNode;
  double _fontSize = 13.0;
  double _baseFontSizeOnPinch = 13.0;
  bool _isDisconnected = false;
  StreamSubscription<dynamic>? _sessionCloseSubscription;

  @override
  void initState() {
    super.initState();
    final entry = TerminalSessionRegistry.instance.getOrCreate(widget.session);
    _terminal = entry.terminal;
    _controller = entry.controller;
    _focusNode = FocusNode();

    _terminal.onResize = (width, height, pixelWidth, pixelHeight) {
      widget.session.resize(TerminalDimensions(cols: width, rows: height));
    };

    _terminal.onOutput = (data) {
      if (!_isDisconnected) {
        widget.session.inputStream.add(Uint8List.fromList(utf8.encode(data)));
      }
    };

    _sessionCloseSubscription = widget.session.outputStream.listen(
      null,
      onDone: () {
        if (mounted) {
          setState(() {
            _isDisconnected = true;
          });
        }
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
        if (_terminal.viewWidth > 0 && _terminal.viewHeight > 0) {
          widget.session.resize(
            TerminalDimensions(
              cols: _terminal.viewWidth,
              rows: _terminal.viewHeight,
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _sessionCloseSubscription?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  Future<bool> _showDisconnectConfirmation(BuildContext context) async {
    if (_isDisconnected) return true;

    final hostLabel = widget.host?.label ?? 'Server';
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ShellitColors.obsidianCard,
        title: Text(
          context.tr('terminal.disconnect_title',
              defaultText: 'Disconnect from $hostLabel?'),
          style: const TextStyle(color: ShellitColors.textPrimary, fontSize: 16),
        ),
        content: Text(
          context.tr('terminal.disconnect_prompt',
              defaultText:
                  'Are you sure you want to terminate the active SSH session?'),
          style:
              const TextStyle(color: ShellitColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              context.tr('common.cancel', defaultText: 'Cancel'),
              style: const TextStyle(color: ShellitColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ShellitColors.statusRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              context.tr('terminal.disconnect_btn',
                  defaultText: 'Disconnect'),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _handleBackPress() async {
    final confirmed = await _showDisconnectConfirmation(context);
    if (confirmed && mounted) {
      widget.onDisconnect();
    }
  }

  @override
  Widget build(BuildContext context) {
    final terminalTheme = ref.watch(activeTerminalThemeProvider);
    final pingState = ref.watch(pingMonitorProvider);
    final latency = widget.host != null
        ? (pingState.latencyFor(widget.host!.id) ??
            widget.host!.lastPingLatencyMs)
        : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: ShellitColors.obsidianBackground,
        body: SafeArea(
          child: Column(
            children: [
              // Top compact Mobile Terminal Header
              Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: const BoxDecoration(
                  color: ShellitColors.obsidianHeader,
                  border: Border(
                    bottom: BorderSide(color: ShellitColors.border, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: ShellitColors.textPrimary, size: 20),
                      onPressed: _handleBackPress,
                      tooltip:
                          context.tr('common.back', defaultText: 'Back'),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.host?.label ?? 'Terminal',
                              style: const TextStyle(
                                color: ShellitColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.host?.environment ==
                              HostEnvironment.production) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: ShellitColors.statusRed
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: ShellitColors.statusRed, width: 1),
                              ),
                              child: const Text(
                                'PROD',
                                style: TextStyle(
                                  color: ShellitColors.statusRed,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (latency != null) ...[
                      Text(
                        '${latency}ms',
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'JetBrains Mono',
                          color: ShellitColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: latency.pingStatus == PingStatus.fast
                              ? ShellitColors.statusGreen
                              : (latency.pingStatus == PingStatus.medium
                                  ? ShellitColors.statusYellow
                                  : (latency.pingStatus == PingStatus.slow
                                      ? ShellitColors.statusOrange
                                      : ShellitColors.statusRed)),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    IconButton(
                      icon: const Icon(Icons.power_settings_new,
                          color: ShellitColors.statusRed, size: 20),
                      onPressed: _handleBackPress,
                      tooltip: context.tr('terminal.disconnect_btn',
                          defaultText: 'Disconnect'),
                    ),
                  ],
                ),
              ),

              // Reconnection Banner (if disconnected)
              if (_isDisconnected)
                Container(
                  color: ShellitColors.statusRed.withValues(alpha: 0.2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: ShellitColors.statusRed, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.tr('terminal.connection_lost',
                              defaultText: 'Connection lost'),
                          style: const TextStyle(
                            color: ShellitColors.statusRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (widget.onReconnect != null)
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: ShellitColors.statusRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                          onPressed: () {
                            setState(() => _isDisconnected = false);
                            widget.onReconnect!();
                          },
                          child: Text(
                            context.tr('terminal.reconnect_btn',
                                defaultText: 'Reconnect'),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close,
                            size: 16, color: ShellitColors.textPrimary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: widget.onDisconnect,
                      ),
                    ],
                  ),
                ),

              // Terminal View with Pinch-To-Zoom Gesture
              Expanded(
                child: GestureDetector(
                  onScaleStart: (_) {
                    _baseFontSizeOnPinch = _fontSize;
                  },
                  onScaleUpdate: (details) {
                    if (details.scale != 1.0) {
                      setState(() {
                        _fontSize = (_baseFontSizeOnPinch * details.scale)
                            .clamp(10.0, 22.0);
                      });
                    }
                  },
                  child: TerminalView(
                    _terminal,
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: true,
                    theme: terminalTheme,
                    textStyle: TerminalStyle(
                      fontSize: _fontSize,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ),
              ),

              // Mobile Accessory Bar pinned above keyboard
              MobileAccessoryBar(
                onKeyPress: (sequence) {
                  if (!_isDisconnected) {
                    widget.session.inputStream
                        .add(Uint8List.fromList(utf8.encode(sequence)));
                  }
                },
                onPaste: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null &&
                      data!.text!.isNotEmpty &&
                      !_isDisconnected) {
                    widget.session.inputStream
                        .add(Uint8List.fromList(utf8.encode(data.text!)));
                  }
                },
                onHideKeyboard: () {
                  _focusNode.unfocus();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
