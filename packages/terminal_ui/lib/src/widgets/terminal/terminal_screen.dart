import 'dart:async';
import 'dart:convert';
import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xterm/xterm.dart';
// ignore: implementation_imports
import 'package:xterm/src/ui/render.dart';
import 'package:flutter/gestures.dart';
import '../../localization/localization_scope.dart';
import '../../providers/theme_provider.dart';
import '../../theme/shellit_theme.dart';
import 'multiline_paste_dialog.dart';
import 'prod_confirmation_dialog.dart';
import 'prod_guard_border.dart';
import 'terminal_context_menu.dart';
import 'terminal_link_detector.dart';
import 'terminal_session_registry.dart';
import 'terminal_shortcuts_dialog.dart';

class TerminalScreen extends ConsumerStatefulWidget {
  final ITerminalSession session;
  final HostEntity? host;
  final ValueChanged<String>? onBroadcastOutput;
  final bool autoFocus;
  final VoidCallback? onOpenSftp;
  final VoidCallback? onToggleRecording;
  final void Function(String filePath)? onOpenFile;
  final void Function(String url)? onOpenUrl;
  final bool enableMultilineDefense;
  final bool enableClickableLinks;

  const TerminalScreen({
    super.key,
    required this.session,
    this.host,
    this.onBroadcastOutput,
    this.autoFocus = true,
    this.onOpenSftp,
    this.onToggleRecording,
    this.onOpenFile,
    this.onOpenUrl,
    this.enableMultilineDefense = true,
    this.enableClickableLinks = true,
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

  late final ScrollController _scrollController;
  final GlobalKey<TerminalViewState> _terminalViewKey =
      GlobalKey<TerminalViewState>();
  TerminalLinkMatch? _hoveredLink;
  Offset? _hoveredPosition;
  bool _isCtrlPressed = false;
  Offset? _pointerDownPosition;
  bool _isPointerDownWithCtrl = false;

  @override
  void initState() {
    super.initState();
    final entry = TerminalSessionRegistry.instance.getOrCreate(widget.session);
    _terminal = entry.terminal;
    _controller = entry.controller;
    _scrollController = ScrollController();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);

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
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    _recordTimer?.cancel();
    _recordTimer = null;
    _stopCursorBlink();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _scrollController.dispose();
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
                const Icon(Icons.check_circle_outline,
                    size: 14, color: ShellitColors.statusGreen),
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

  Future<void> _copyToClipboard(String text, String feedbackMessage) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline,
                  size: 14, color: ShellitColors.statusGreen),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  feedbackMessage,
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

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;

    final isMultilined = text.contains('\n') || text.contains('\r');
    final lines = text.split(RegExp(r'\r\n|\r|\n'));

    if (widget.enableMultilineDefense &&
        (isMultilined && (lines.length > 1 || text.endsWith('\n') || text.endsWith('\r')))) {
      final confirmedText = await MultilinePasteDialog.show(
        context: context,
        text: text,
        host: widget.host,
        isProduction: widget.host?.isProduction ?? false,
      );
      if (confirmedText != null && confirmedText.isNotEmpty) {
        _terminal.paste(confirmedText);
        _controller.clearSelection();
      }
      return;
    }

    _terminal.paste(text);
    _controller.clearSelection();
  }

  Future<void> _handleLinkAction(TerminalLinkMatch match) async {
    if (match.isUrl) {
      if (widget.onOpenUrl != null) {
        widget.onOpenUrl!(match.text);
        return;
      }
      try {
        final uri = Uri.parse(match.text);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          await _copyToClipboard(
            match.text,
            context.tr('terminal.link_copied_toast',
                defaultText: 'Link copied to clipboard'),
          );
        }
      } catch (_) {
        await _copyToClipboard(
          match.text,
          context.tr('terminal.link_copied_toast',
              defaultText: 'Link copied to clipboard'),
        );
      }
    } else if (match.isFilePath) {
      if (widget.onOpenFile != null) {
        widget.onOpenFile!(match.text);
        return;
      }
      if (widget.onOpenSftp != null) {
        widget.onOpenSftp!();
        return;
      }
      await _copyToClipboard(
        match.text,
        context.tr('terminal.path_copied_toast',
            defaultText: 'File path copied to clipboard'),
      );
    }
  }

  bool _handleHardwareKey(KeyEvent event) {
    final isCtrl = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    if (isCtrl != _isCtrlPressed && mounted) {
      setState(() {
        _isCtrlPressed = isCtrl;
      });
    }
    return false;
  }

  CellOffset? _getCellOffset(Offset globalPosition) {
    final state = _terminalViewKey.currentState;
    if (state != null) {
      try {
        final RenderTerminal renderTerminal = state.renderTerminal;
        if (renderTerminal.hasSize) {
          final localOffset = renderTerminal.globalToLocal(globalPosition);
          return renderTerminal.getCellOffset(localOffset);
        }
      } catch (_) {}
    }
    return null;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (event.buttons == kMiddleMouseButton) {
      _pasteFromClipboard();
      return;
    }
    if (event.buttons == kPrimaryMouseButton) {
      _pointerDownPosition = event.position;
      _isPointerDownWithCtrl = HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed;
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (!widget.enableClickableLinks) {
      _pointerDownPosition = null;
      return;
    }

    if (_pointerDownPosition != null) {
      final distance = (event.position - _pointerDownPosition!).distance;
      _pointerDownPosition = null;

      // Click/Tap tolerance (not a drag selection)
      if (distance < 6.0) {
        final isCmdOrCtrl = _isPointerDownWithCtrl ||
            HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed;
        final isMobile = defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS;

        final cellOffset = _getCellOffset(event.position);
        if (cellOffset != null) {
          final match =
              TerminalLinkDetector.findMatchAtOffset(_terminal, cellOffset);
          if (match != null) {
            if (isCmdOrCtrl || isMobile) {
              _controller.clearSelection();
              _handleLinkAction(match);
            } else {
              // Clicked without Ctrl: show helpful hint toast
              final hintKey = defaultTargetPlatform == TargetPlatform.macOS
                  ? 'Cmd+Click'
                  : 'Ctrl+Click';
              _copyToClipboard(
                match.text,
                '$hintKey to open: ${match.text}',
              );
            }
          }
        }
      }
    }
  }

  void _handlePointerHover(PointerHoverEvent event) {
    if (!widget.enableClickableLinks) {
      if (_hoveredLink != null) {
        setState(() {
          _hoveredLink = null;
          _hoveredPosition = null;
        });
      }
      return;
    }

    final cellOffset = _getCellOffset(event.position);
    final match = cellOffset != null
        ? TerminalLinkDetector.findMatchAtOffset(_terminal, cellOffset)
        : null;

    final box = context.findRenderObject() as RenderBox?;
    final stackPos = box != null && box.hasSize
        ? box.globalToLocal(event.position)
        : event.localPosition;

    if (_hoveredLink?.text != match?.text ||
        (_hoveredLink == null && match != null) ||
        (_hoveredLink != null && match == null)) {
      setState(() {
        _hoveredLink = match;
        _hoveredPosition = stackPos;
      });
    } else if (match != null &&
        _hoveredPosition != null &&
        (_hoveredPosition! - stackPos).distance > 4.0) {
      setState(() {
        _hoveredPosition = stackPos;
      });
    }
  }

  void _handlePointerExit(PointerExitEvent event) {
    if (_hoveredLink != null || _hoveredPosition != null) {
      setState(() {
        _hoveredLink = null;
        _hoveredPosition = null;
      });
    }
  }

  void _handleTerminalTapUp(TapUpDetails details, CellOffset offset) {
    if (!widget.enableClickableLinks) return;
    final isCmdOrCtrl = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    final isMobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    if (isCmdOrCtrl || isMobile) {
      final match = TerminalLinkDetector.findMatchAtOffset(_terminal, offset);
      if (match != null) {
        _handleLinkAction(match);
      }
    }
  }

  void _selectAll() {
    final height = _terminal.buffer.height;
    _controller.setSelection(
      _terminal.buffer.createAnchor(0, 0),
      _terminal.buffer
          .createAnchor(_terminal.viewWidth, height > 0 ? height - 1 : 0),
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

  void _showContextMenu(Offset globalPosition, [CellOffset? offset]) {
    final selection = _controller.selection;
    String? selectedText;
    if (selection != null) {
      selectedText = _terminal.buffer.getText(selection);
    }

    TerminalLinkMatch? detectedLink;
    if (widget.enableClickableLinks) {
      if (offset != null) {
        detectedLink =
            TerminalLinkDetector.findMatchAtOffset(_terminal, offset);
      }
      if (detectedLink == null && selectedText != null) {
        detectedLink = TerminalLinkDetector.findMatchInText(selectedText);
      }
    }

    TerminalContextMenu.show(
      context: context,
      globalPosition: globalPosition,
      hasSelection: selection != null,
      selectedText: selectedText,
      detectedLink: detectedLink,
      onOpenLink:
          detectedLink != null ? () => _handleLinkAction(detectedLink!) : null,
      onCopyLink: detectedLink != null
          ? () => _copyToClipboard(
                detectedLink!.text,
                detectedLink.isUrl
                    ? context.tr('terminal.link_copied_toast',
                        defaultText: 'Link copied to clipboard')
                    : context.tr('terminal.path_copied_toast',
                        defaultText: 'File path copied to clipboard'),
              )
          : null,
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
    if (isCmdOrCtrl &&
        !isAlt &&
        (key == LogicalKeyboardKey.equal ||
            key == LogicalKeyboardKey.add ||
            key == LogicalKeyboardKey.numpadAdd)) {
      if (_fontSize < 28) {
        setState(() {
          _fontSize += 1;
        });
      }
      return KeyEventResult.handled;
    }
    // Ctrl + Minus, Ctrl + NumpadSubtract
    if (isCmdOrCtrl &&
        !isAlt &&
        (key == LogicalKeyboardKey.minus ||
            key == LogicalKeyboardKey.numpadSubtract)) {
      if (_fontSize > 8) {
        setState(() {
          _fontSize -= 1;
        });
      }
      return KeyEventResult.handled;
    }
    // Ctrl + 0, Ctrl + Numpad0
    if (isCmdOrCtrl &&
        !isAlt &&
        (key == LogicalKeyboardKey.digit0 ||
            key == LogicalKeyboardKey.numpad0)) {
      setState(() {
        _fontSize = 13.0;
      });
      return KeyEventResult.handled;
    }

    // 4. Copy:
    // Ctrl + Shift + C
    final isKeyC = key == LogicalKeyboardKey.keyC ||
        event.physicalKey == PhysicalKeyboardKey.keyC;
    final isKeyV = key == LogicalKeyboardKey.keyV ||
        event.physicalKey == PhysicalKeyboardKey.keyV;
    final isKeyA = key == LogicalKeyboardKey.keyA ||
        event.physicalKey == PhysicalKeyboardKey.keyA;
    final isKeyK = key == LogicalKeyboardKey.keyK ||
        event.physicalKey == PhysicalKeyboardKey.keyK;

    // 4. Copy:
    // Ctrl + Shift + C
    // Ctrl + Insert
    // Or Ctrl + C / Cmd + C when there IS an active selection!
    final isCopyShortcut = (isCmdOrCtrl && isShift && isKeyC) ||
        (isCtrl && key == LogicalKeyboardKey.insert);
    final isSmartCtrlC = isCmdOrCtrl &&
        !isShift &&
        !isAlt &&
        isKeyC &&
        _controller.selection != null;

    if (isCopyShortcut || isSmartCtrlC) {
      _copySelection();
      return KeyEventResult.handled;
    }

    // 5. Paste:
    // Ctrl + Shift + V
    // Ctrl + V
    // Shift + Insert
    // Cmd + V
    final isPasteShortcut = (isCmdOrCtrl && isShift && isKeyV) ||
        (isCmdOrCtrl && !isAlt && isKeyV) ||
        (isShift && key == LogicalKeyboardKey.insert);

    if (isPasteShortcut) {
      _pasteFromClipboard();
      return KeyEventResult.handled;
    }

    // 6. Select All:
    // Ctrl + Shift + A or Cmd + A
    if ((isCmdOrCtrl && isShift && isKeyA) || (isMeta && isKeyA)) {
      _selectAll();
      return KeyEventResult.handled;
    }

    // 7. Clear buffer:
    // Ctrl + Shift + K
    if (isCmdOrCtrl && isShift && isKeyK) {
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
              child: MouseRegion(
                cursor: _hoveredLink != null
                    ? SystemMouseCursors.click
                    : MouseCursor.defer,
                onExit: _handlePointerExit,
                child: Listener(
                  onPointerDown: _handlePointerDown,
                  onPointerUp: _handlePointerUp,
                  onPointerHover: _handlePointerHover,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Proactively sync terminal size whenever Flutter layout changes
                      // This ensures the terminal expands when the window grows,
                      // not just when it shrinks.
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted &&
                            _terminal.viewWidth > 0 &&
                            _terminal.viewHeight > 0) {
                          widget.session.resize(
                            TerminalDimensions(
                              cols: _terminal.viewWidth,
                              rows: _terminal.viewHeight,
                            ),
                          );
                        }
                      });
                      return TerminalView(
                        _terminal,
                        key: _terminalViewKey,
                        controller: _controller,
                        scrollController: _scrollController,
                        focusNode: _focusNode,
                        autofocus: widget.autoFocus,
                        hardwareKeyboardOnly: isDesktop,
                        padding: const EdgeInsets.all(12),
                        onKeyEvent: _handleTerminalKeyEvent,
                        mouseCursor: _hoveredLink != null
                            ? SystemMouseCursors.click
                            : SystemMouseCursors.text,
                        onTapUp: (details, offset) {
                          _handleTerminalTapUp(details, offset);
                        },
                        onSecondaryTapUp: (details, offset) {
                          _showContextMenu(details.globalPosition, offset);
                        },
                        theme: terminalTheme,
                        textStyle: TerminalStyle(
                          fontSize: _fontSize,
                          fontFamily: 'JetBrains Mono',
                        ),
                        backgroundOpacity: 1.0,
                      );
                    },
                  ),
                ),
              ),
            ),

            if (_hoveredLink != null && _hoveredPosition != null) ...[
              Positioned(
                left: (_hoveredPosition!.dx + 12).clamp(
                  8.0,
                  (MediaQuery.of(context).size.width - 340)
                      .clamp(8.0, double.infinity),
                ),
                top: (_hoveredPosition!.dy - 34).clamp(8.0, double.infinity),
                child: IgnorePointer(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ShellitColors.obsidianCard,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: ShellitColors.accentCyan.withValues(alpha: 0.7),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _hoveredLink!.isUrl
                              ? Icons.link_rounded
                              : Icons.insert_drive_file_outlined,
                          size: 13,
                          color: ShellitColors.accentCyan,
                        ),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 280),
                          child: Text(
                            '${defaultTargetPlatform == TargetPlatform.macOS ? "Cmd" : "Ctrl"}+Click: ${_hoveredLink!.text}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontFamily: 'JetBrains Mono',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

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
                      message: context.tr('terminal.shortcuts_tooltip',
                          defaultText: 'Keyboard Shortcuts (F1)'),
                      child: InkWell(
                        onTap: _showShortcutsHelp,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.keyboard_outlined,
                                  size: 13, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(
                                context.tr('terminal.shortcuts_btn',
                                    defaultText: 'Keys'),
                                style: const TextStyle(
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
                        message: context.tr('terminal.open_sftp_tooltip',
                            defaultText: 'Open SFTP for this host'),
                        child: InkWell(
                          onTap: widget.onOpenSftp,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.folder_shared_outlined,
                                    size: 13, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  context.tr('terminal.sftp_btn',
                                      defaultText: 'SFTP'),
                                  style: const TextStyle(
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
                            ? context.tr('terminal.recording_active_tooltip',
                                defaultText:
                                    'Session Recording Active (Click to Stop)')
                            : context.tr('terminal.start_recording_tooltip',
                                defaultText: 'Start Session Recording'),
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
                                      ? '${context.tr('terminal.rec_badge', defaultText: 'REC')} ${_formatDuration(_recordDurationSeconds)}'
                                      : context.tr('terminal.rec_badge',
                                          defaultText: 'REC'),
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
                        if (_fontSize > 8) {
                          setState(() {
                            _fontSize -= 1;
                          });
                        }
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
                        if (_fontSize < 28) {
                          setState(() {
                            _fontSize += 1;
                          });
                        }
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
