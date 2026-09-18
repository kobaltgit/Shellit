import 'dart:async';
import 'dart:convert';
import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';
import 'package:flutter/gestures.dart';
import '../../providers/theme_provider.dart';
import '../../theme/shellit_theme.dart';
import 'prod_confirmation_dialog.dart';
import 'prod_guard_border.dart';
import 'terminal_context_menu.dart';
import 'terminal_session_registry.dart';
import 'terminal_shortcuts_dialog.dart';

class TerminalScreen extends ConsumerStatefulWidget {
  final ITerminalSession session;
  final HostEntity? host;
  final ValueChanged<String>? onBroadcastOutput;
  final bool autoFocus;
  final VoidCallback? onOpenSftp;
  final VoidCallback? onToggleRecording;

  const TerminalScreen({
    super.key,
    required this.session,
    this.host,
    this.onBroadcastOutput,
    this.autoFocus = true,
    this.onOpenSftp,
    this.onToggleRecording,
  });

  @override
  ConsumerState<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends ConsumerState<TerminalScreen> {
  late final Terminal _terminal;
  late final TerminalController _controller;
  late final FocusNode _focusNode;
  Timer? _blinkTimer;
  bool _cursorVisible = true;

  final StringBuffer _commandLineBuffer = StringBuffer();
  bool _isAwaitingConfirmation = false;
  double _fontSize = 13.0;

  Timer? _recordTimer;
  int _recordDurationSeconds = 0;

  @override
  void initState() {
    super.initState();
    final entry = TerminalSessionRegistry.instance.getOrCreate(widget.session);
    _terminal = entry.terminal;
    _controller = entry.controller;
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);

    if (widget.session.recorder?.isRecording == true) {
      _syncRecordTimer();
    }

    // Resize listener
    _terminal.onResize = (width, height, pixelWidth, pixelHeight) {
      widget.session.resize(TerminalDimensions(cols: width, rows: height));
    };

    // User input listener
    _terminal.onOutput = _handleTerminalOutput;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.autoFocus) {
        _focusNode.requestFocus();
      }
      // Guarantee immediate terminal resize sync on mount/drop
      if (mounted && _terminal.viewWidth > 0 && _terminal.viewHeight > 0) {
        widget.session.resize(
          TerminalDimensions(
            cols: _terminal.viewWidth,
            rows: _terminal.viewHeight,
          ),
        );
      }
    });
  }

  void _syncRecordTimer() {
    final isRec = widget.session.recorder?.isRecording ?? false;
    if (isRec) {
      _recordTimer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordDurationSeconds++;
          });
        }
      });
    } else {
      _recordTimer?.cancel();
      _recordTimer = null;
      _recordDurationSeconds = 0;
    }
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void didUpdateWidget(TerminalScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncRecordTimer();
    if (widget.autoFocus && !oldWidget.autoFocus && !_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _recordTimer = null;
    _stopCursorBlink();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
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

  Future<void> _copySelection() async {
    final selection = _controller.selection;
    if (selection == null) return;
    final text = _terminal.buffer.getText(selection);
    if (text.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, size: 14, color: ShellitColors.statusGreen),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Copied (${text.trim().length} chars)',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: ShellitColors.obsidianCard,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 1500),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: ShellitColors.border),
            ),
          ),
        );
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text != null && text.isNotEmpty) {
      _terminal.paste(text);
      _controller.clearSelection();
    }
  }

  void _selectAll() {
    final height = _terminal.buffer.height;
    _controller.setSelection(
      _terminal.buffer.createAnchor(0, 0),
      _terminal.buffer.createAnchor(_terminal.viewWidth, height > 0 ? height - 1 : 0),
      mode: SelectionMode.line,
    );
  }

  void _clearTerminalBuffer() {
    _terminal.buffer.clear();
    _terminal.setCursor(0, 0);
    _terminal.notifyListeners();
    _controller.clearSelection();
  }

  void _showShortcutsHelp() {
    TerminalShortcutsDialog.show(context);
  }

  void _showContextMenu(Offset globalPosition) {
    final selection = _controller.selection;
    String? selectedText;
    if (selection != null) {
      selectedText = _terminal.buffer.getText(selection);
    }
    TerminalContextMenu.show(
      context: context,
      globalPosition: globalPosition,
      hasSelection: selection != null,
      selectedText: selectedText,
      onCopy: _copySelection,
      onPaste: _pasteFromClipboard,
      onSelectAll: _selectAll,
      onClear: _clearTerminalBuffer,
      onShowShortcuts: _showShortcutsHelp,
    );
  }

  KeyEventResult _handleTerminalKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;

    final isCtrl = HardwareKeyboard.instance.isControlPressed;
    final isAlt = HardwareKeyboard.instance.isAltPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;
    final isMeta = HardwareKeyboard.instance.isMetaPressed;
    final isCmdOrCtrl = isCtrl || isMeta;
    final key = event.logicalKey;

    // 1. Help: F1
    if (key == LogicalKeyboardKey.f1) {
      _showShortcutsHelp();
      return KeyEventResult.handled;
    }

    // 2. Escape: If text is selected, clear selection!
    if (key == LogicalKeyboardKey.escape && _controller.selection != null) {
      _controller.clearSelection();
      return KeyEventResult.handled;
    }

    // 3. Zoom shortcuts:
    // Ctrl + Plus, Ctrl + =, Ctrl + NumpadAdd
    if (isCmdOrCtrl && !isAlt && (key == LogicalKeyboardKey.equal || key == LogicalKeyboardKey.add || key == LogicalKeyboardKey.numpadAdd)) {
      if (_fontSize < 28) setState(() => _fontSize += 1);
      return KeyEventResult.handled;
    }
    // Ctrl + Minus, Ctrl + NumpadSubtract
    if (isCmdOrCtrl && !isAlt && (key == LogicalKeyboardKey.minus || key == LogicalKeyboardKey.numpadSubtract)) {
      if (_fontSize > 8) setState(() => _fontSize -= 1);
      return KeyEventResult.handled;
    }
    // Ctrl + 0, Ctrl + Numpad0
    if (isCmdOrCtrl && !isAlt && (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0)) {
      setState(() => _fontSize = 13.0);
      return KeyEventResult.handled;
    }

    // 4. Copy:
    // Ctrl + Shift + C
    // Ctrl + Insert
    // Or Ctrl + C / Cmd + C when there IS an active selection!
    final isCopyShortcut = (isCmdOrCtrl && isShift && key == LogicalKeyboardKey.keyC) ||
        (isCtrl && key == LogicalKeyboardKey.insert);
    final isSmartCtrlC = isCmdOrCtrl && !isShift && !isAlt && key == LogicalKeyboardKey.keyC && _controller.selection != null;

    if (isCopyShortcut || isSmartCtrlC) {
      _copySelection();
      return KeyEventResult.handled;
    }

    // 5. Paste:
    // Ctrl + Shift + V
    // Ctrl + V
    // Shift + Insert
    // Cmd + V
    final isPasteShortcut = (isCmdOrCtrl && isShift && key == LogicalKeyboardKey.keyV) ||
        (isCmdOrCtrl && !isAlt && key == LogicalKeyboardKey.keyV) ||
        (isShift && key == LogicalKeyboardKey.insert);

    if (isPasteShortcut) {
      _pasteFromClipboard();
      return KeyEventResult.handled;
    }

    // 6. Select All:
    // Ctrl + Shift + A or Cmd + A
    if ((isCmdOrCtrl && isShift && key == LogicalKeyboardKey.keyA) ||
        (isMeta && key == LogicalKeyboardKey.keyA)) {
      _selectAll();
      return KeyEventResult.handled;
    }

    // 7. Clear buffer:
    // Ctrl + Shift + K
    if (isCmdOrCtrl && isShift && key == LogicalKeyboardKey.keyK) {
      _clearTerminalBuffer();
      return KeyEventResult.handled;
    }

    // Let Ctrl and Alt combinations be handled by xterm shortcuts and keyInput
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

    if (specialKeys.contains(key)) {
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
              child: Listener(
                onPointerDown: (event) {
                  if (event.buttons == kMiddleMouseButton) {
                    _pasteFromClipboard();
                  }
                },
                child: TerminalView(
                  _terminal,
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: widget.autoFocus,
                  hardwareKeyboardOnly: isDesktop,
                  onKeyEvent: _handleTerminalKeyEvent,
                  onSecondaryTapUp: (details, offset) {
                    _showContextMenu(details.globalPosition);
                  },
                  theme: terminalTheme,
                  textStyle: TerminalStyle(
                    fontSize: _fontSize,
                    fontFamily: 'JetBrains Mono',
                  ),
                  backgroundOpacity: 1.0,
                ),
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
                    Tooltip(
                      message: 'Keyboard Shortcuts (F1)',
                      child: InkWell(
                        onTap: _showShortcutsHelp,
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.keyboard_outlined,
                                  size: 13, color: Colors.white70),
                              SizedBox(width: 4),
                              Text(
                                'Keys',
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
                    if (widget.onToggleRecording != null ||
                        (widget.session.recorder?.isRecording ?? false)) ...[
                      Tooltip(
                        message: (widget.session.recorder?.isRecording ?? false)
                            ? 'Session Recording Active (Click to Stop)'
                            : 'Start Session Recording',
                        child: InkWell(
                          onTap: () async {
                            widget.onToggleRecording?.call();
                            await Future<void>.delayed(
                                const Duration(milliseconds: 100));
                            if (mounted) {
                              setState(() {
                                _syncRecordTimer();
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.fiber_manual_record,
                                  size: 11,
                                  color:
                                      (widget.session.recorder?.isRecording ??
                                              false)
                                          ? const Color(0xFFFF5252)
                                          : Colors.white54,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  (widget.session.recorder?.isRecording ??
                                          false)
                                      ? 'REC ${_formatDuration(_recordDurationSeconds)}'
                                      : 'REC',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        (widget.session.recorder?.isRecording ??
                                                false)
                                            ? const Color(0xFFFF5252)
                                            : Colors.white54,
                                    letterSpacing: 0.5,
                                  ),
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
