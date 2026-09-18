import 'dart:async';
import 'dart:convert';
import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';
import '../../providers/theme_provider.dart';
import 'prod_confirmation_dialog.dart';
import 'prod_guard_border.dart';

class TerminalScreen extends ConsumerStatefulWidget {
  final ITerminalSession session;
  final HostEntity? host;
  final ValueChanged<String>? onBroadcastOutput;
  final bool autoFocus;
  final VoidCallback? onOpenSftp;

  const TerminalScreen({
    super.key,
    required this.session,
    this.host,
    this.onBroadcastOutput,
    this.autoFocus = true,
    this.onOpenSftp,
  });

  @override
  ConsumerState<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends ConsumerState<TerminalScreen> {
  late final Terminal _terminal;
  late final TerminalController _controller;
  late final FocusNode _focusNode;
  StreamSubscription<Uint8List>? _outputSub;
  Timer? _blinkTimer;
  bool _cursorVisible = true;

  final StringBuffer _commandLineBuffer = StringBuffer();
  bool _isAwaitingConfirmation = false;
  double _fontSize = 13.0;

  @override
  void initState() {
    super.initState();
    _terminal = Terminal(maxLines: 5000);
    _controller = TerminalController();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);

    // Resize listener
    _terminal.onResize = (width, height, pixelWidth, pixelHeight) {
      widget.session.resize(TerminalDimensions(cols: width, rows: height));
    };

    // User input listener
    _terminal.onOutput = _handleTerminalOutput;

    // Listen to remote session output
    _outputSub = widget.session.outputStream.listen(
      (bytes) {
        final decoded = utf8.decode(bytes, allowMalformed: true);
        _terminal.write(decoded);
      },
      onError: (err) {
        _terminal.write('\r\n[Session Error: $err]\r\n');
      },
      onDone: () {
        _terminal.write('\r\n[Session disconnected]\r\n');
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.autoFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(TerminalScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoFocus && !oldWidget.autoFocus && !_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _stopCursorBlink();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _outputSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _startCursorBlink();
    } else {
      _stopCursorBlink();
    }
  }

  void _startCursorBlink() {
    _blinkTimer?.cancel();
    _cursorVisible = true;
    _terminal.setCursorVisibleMode(true);
    _terminal.notifyListeners();

    _blinkTimer = Timer.periodic(const Duration(milliseconds: 550), (timer) {
      if (!mounted || !_focusNode.hasFocus) {
        timer.cancel();
        return;
      }
      _cursorVisible = !_cursorVisible;
      _terminal.setCursorVisibleMode(_cursorVisible);
      _terminal.notifyListeners();
    });
  }

  void _stopCursorBlink() {
    _blinkTimer?.cancel();
    _blinkTimer = null;
    _cursorVisible = true;
    _terminal.setCursorVisibleMode(true);
    _terminal.notifyListeners();
  }

  void _resetCursorBlink() {
    if (_focusNode.hasFocus) {
      _cursorVisible = true;
      _terminal.setCursorVisibleMode(true);
      _terminal.notifyListeners();
      _startCursorBlink();
    }
  }

  void _sendToSession(String data) {
    _resetCursorBlink();
    widget.session.inputStream.add(Uint8List.fromList(utf8.encode(data)));
    widget.onBroadcastOutput?.call(data);
  }

  KeyEventResult _handleTerminalKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;

    // Let Ctrl and Alt combinations be handled by xterm shortcuts and keyInput
    final isCtrl = HardwareKeyboard.instance.isControlPressed;
    final isAlt = HardwareKeyboard.instance.isAltPressed;
    if (isCtrl || isAlt) {
      return KeyEventResult.ignored;
    }

    // Let special navigation/editing keys be handled by xterm keytab
    final specialKeys = {
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.numpadEnter,
      LogicalKeyboardKey.tab,
      LogicalKeyboardKey.backspace,
      LogicalKeyboardKey.escape,
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.delete,
      LogicalKeyboardKey.home,
      LogicalKeyboardKey.end,
      LogicalKeyboardKey.pageUp,
      LogicalKeyboardKey.pageDown,
    };

    if (specialKeys.contains(event.logicalKey)) {
      return KeyEventResult.ignored;
    }

    // Direct emission of printable characters (Latin, Cyrillic, symbols, space)
    if (event.character != null && event.character!.isNotEmpty) {
      _terminal.textInput(event.character!);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Future<void> _handleTerminalOutput(String data) async {
    if (_isAwaitingConfirmation) return;

    final isProd = widget.host?.isProduction ?? false;
    final hasProtection = widget.host?.dangerousCommandProtection ?? false;

    // Enter pressed
    if (data.contains('\r') || data.contains('\n')) {
      final cmd = _commandLineBuffer.toString().trim();
      _commandLineBuffer.clear();

      if (isProd && hasProtection && DangerousCommandChecker.isDangerous(cmd)) {
        _isAwaitingConfirmation = true;
        final confirmed = await ProdConfirmationDialog.confirmDangerousCommand(
          context: context,
          command: cmd,
          hostLabel: widget.host?.label ?? 'Server',
        );
        _isAwaitingConfirmation = false;

        if (confirmed) {
          _sendToSession(data);
        } else {
          // Send Ctrl+C to remote terminal to abort line safely
          _sendToSession('\x03');
          _terminal.write('\r\n[Aborted by PROD Guard]\r\n');
        }
        return;
      }

      _sendToSession(data);
      return;
    }

    // Handle backspace or cancel keystrokes in buffer
    if (data == '\x7f' || data == '\b') {
      final str = _commandLineBuffer.toString();
      if (str.isNotEmpty) {
        _commandLineBuffer.clear();
        _commandLineBuffer.write(str.substring(0, str.length - 1));
      }
    } else if (data == '\x03' || data == '\x15') {
      // Ctrl+C or Ctrl+U
      _commandLineBuffer.clear();
    } else {
      // Filter out non-printable ANSI escape sequences from command buffer
      if (!data.startsWith('\x1b')) {
        _commandLineBuffer.write(data);
      }
    }

    _sendToSession(data);
  }

  void writeFromExternal(String data) {
    _sendToSession(data);
  }

  @override
  Widget build(BuildContext context) {
    final terminalTheme = ref.watch(activeTerminalThemeProvider);
    final isProd = widget.host?.isProduction ?? false;
    final isDesktop = defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;

    return ProdGuardBorder(
      isProduction: isProd,
      hostLabel: widget.host?.label,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (!_focusNode.hasFocus) {
            _focusNode.requestFocus();
          }
        },
        child: Stack(
          children: [
            Container(
              color: terminalTheme.background,
              padding: EdgeInsets.only(top: isProd ? 24 : 0),
              child: TerminalView(
                _terminal,
                controller: _controller,
                focusNode: _focusNode,
                autofocus: widget.autoFocus,
                hardwareKeyboardOnly: isDesktop,
                onKeyEvent: _handleTerminalKeyEvent,
                theme: terminalTheme,
                textStyle: TerminalStyle(
                  fontSize: _fontSize,
                  fontFamily: 'JetBrains Mono',
                ),
                backgroundOpacity: 1.0,
              ),
            ),

            // Floating font zoom buttons on hover/top-right
            Positioned(
              top: isProd ? 28 : 8,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.onOpenSftp != null) ...[
                      Tooltip(
                        message: 'Open SFTP for this host',
                        child: InkWell(
                          onTap: widget.onOpenSftp,
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.folder_shared_outlined,
                                    size: 13, color: Colors.white70),
                                SizedBox(width: 4),
                                Text(
                                  'SFTP',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(width: 1, height: 12, color: Colors.white24),
                      const SizedBox(width: 4),
                    ],
                    InkWell(
                      onTap: () {
                        if (_fontSize > 8) setState(() => _fontSize -= 1);
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child:
                            Icon(Icons.remove, size: 14, color: Colors.white70),
                      ),
                    ),
                    Text(
                      '${_fontSize.toInt()}pt',
                      style:
                          const TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                    InkWell(
                      onTap: () {
                        if (_fontSize < 28) setState(() => _fontSize += 1);
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.add, size: 14, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
