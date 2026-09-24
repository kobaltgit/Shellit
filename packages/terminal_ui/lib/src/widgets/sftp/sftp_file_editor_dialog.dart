import 'dart:convert';
import 'dart:io';
import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../localization/localization_scope.dart';
import '../../theme/shellit_theme.dart';

/// Modal text editor for viewing and editing remote and local files.
/// Features in-place save (Ctrl+S), line numbers gutter, word-wrap toggle,
/// dirty state tracking, and binary file protection.
class SftpFileEditorDialog extends StatefulWidget {
  final String fileName;
  final String path;
  final bool isRemote;
  final ISftpSession? session;
  final File? localFile;
  final int? fileSize;

  const SftpFileEditorDialog({
    super.key,
    required this.fileName,
    required this.path,
    required this.isRemote,
    this.session,
    this.localFile,
    this.fileSize,
  });

  /// Convenience factory to open a remote file.
  static Future<bool?> openRemote(
    BuildContext context, {
    required ISftpSession session,
    required String remotePath,
    required String fileName,
    int? fileSize,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SftpFileEditorDialog(
        fileName: fileName,
        path: remotePath,
        isRemote: true,
        session: session,
        fileSize: fileSize,
      ),
    );
  }

  /// Convenience factory to open a local file.
  static Future<bool?> openLocal(
    BuildContext context, {
    required File localFile,
    required String fileName,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SftpFileEditorDialog(
        fileName: fileName,
        path: localFile.path,
        isRemote: false,
        localFile: localFile,
      ),
    );
  }

  @override
  State<SftpFileEditorDialog> createState() => _SftpFileEditorDialogState();
}

class _SftpFileEditorDialogState extends State<SftpFileEditorDialog> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _textScrollController = ScrollController();
  final ScrollController _linesScrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDirty = false;
  bool _wordWrap = true;
  String? _errorMessage;
  int _lineCount = 1;
  int _cursorLine = 1;
  int _cursorCol = 1;

  @override
  void initState() {
    super.initState();
    _loadFile();
    _controller.addListener(_onTextChanged);
    _textScrollController.addListener(_syncScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _textScrollController.removeListener(_syncScroll);
    _controller.dispose();
    _textScrollController.dispose();
    _linesScrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _syncScroll() {
    if (_linesScrollController.hasClients &&
        _linesScrollController.offset != _textScrollController.offset) {
      _linesScrollController.jumpTo(_textScrollController.offset);
    }
  }

  void _onTextChanged() {
    final text = _controller.text;
    final lines = text.split('\n').length;
    if (lines != _lineCount) {
      setState(() {
        _lineCount = lines > 0 ? lines : 1;
      });
    }

    // Update cursor position
    final sel = _controller.selection;
    if (sel.isValid) {
      final pos = sel.baseOffset;
      if (pos >= 0 && pos <= text.length) {
        final sub = text.substring(0, pos);
        final lineSplits = sub.split('\n');
        setState(() {
          _cursorLine = lineSplits.length;
          _cursorCol = lineSplits.last.length + 1;
        });
      }
    }

    if (!_isDirty && !_isLoading) {
      setState(() => _isDirty = true);
    }
  }

  Future<void> _loadFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Uint8List bytes;
      if (widget.isRemote) {
        if (widget.session == null) {
          throw Exception('SFTP session is null');
        }
        final result = await widget.session!.readFile(widget.path);
        if (result.isError) {
          throw Exception(
              result.failureOrNull?.message ?? 'Failed to read file');
        }
        bytes = result.valueOrNull!;
      } else {
        if (widget.localFile == null) {
          throw Exception('Local file is null');
        }
        bytes = await widget.localFile!.readAsBytes();
      }

      // Check for binary content (null bytes in first 4000 bytes)
      final checkLen = bytes.length < 4000 ? bytes.length : 4000;
      bool isBinary = false;
      for (int i = 0; i < checkLen; i++) {
        if (bytes[i] == 0) {
          isBinary = true;
          break;
        }
      }

      if (isBinary && mounted) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: ShellitColors.obsidianCard,
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: ShellitColors.statusYellow, size: 20),
                const SizedBox(width: 8),
                Text(context.tr('sftp.binary_warning_title',
                    defaultText: 'Binary File Warning')),
              ],
            ),
            content: Text(context.tr('sftp.binary_warning_msg',
                defaultText:
                    'This file appears to be binary. Opening and editing it in a text editor may corrupt its content. Open anyway?')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(context.tr('common.cancel', defaultText: 'Cancel')),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ShellitColors.statusYellow,
                  foregroundColor: Colors.black,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                    context.tr('sftp.open_anyway', defaultText: 'Open Anyway')),
              ),
            ],
          ),
        );
        if (proceed != true && mounted) {
          Navigator.of(context).pop(false);
          return;
        }
      }

      final content = utf8.decode(bytes, allowMalformed: true);
      _controller.text = content;
      _lineCount = content.split('\n').length;
      _isDirty = false;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveFile() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final bytes = Uint8List.fromList(utf8.encode(_controller.text));
      if (widget.isRemote) {
        final res = await widget.session!.writeFile(widget.path, bytes);
        if (res.isError) {
          throw Exception(res.failureOrNull?.message ?? 'Save failed');
        }
      } else {
        await widget.localFile!.writeAsBytes(bytes);
      }

      if (mounted) {
        setState(() {
          _isDirty = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle,
                    size: 16, color: ShellitColors.statusGreen),
                const SizedBox(width: 8),
                Text(context.tr('sftp.file_saved',
                    defaultText: 'File saved successfully: {name}',
                    namedArgs: {'name': widget.fileName})),
              ],
            ),
            backgroundColor: ShellitColors.obsidianCard,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save error: $e'),
            backgroundColor: ShellitColors.statusRed,
          ),
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;

    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ShellitColors.obsidianCard,
        title: Text(context.tr('sftp.unsaved_changes_title',
            defaultText: 'Unsaved Changes')),
        content: Text(context.tr('sftp.unsaved_changes_msg',
            defaultText:
                'You have unsaved changes in "{name}". Do you want to discard them?',
            namedArgs: {'name': widget.fileName})),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.tr('common.cancel', defaultText: 'Cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ShellitColors.statusRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.tr('sftp.discard', defaultText: 'Discard')),
          ),
        ],
      ),
    );

    return discard == true;
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isCtrlOrCmd = HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed;
      if (isCtrlOrCmd && event.logicalKey == LogicalKeyboardKey.keyS) {
        _saveFile();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: PopScope(
        canPop: !_isDirty,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final canClose = await _onWillPop();
          if (canClose && context.mounted) {
            Navigator.of(context).pop(true);
          }
        },
        child: Dialog(
          backgroundColor: ShellitColors.obsidianBackground,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: ShellitColors.border),
          ),
          child: Column(
            children: [
              // Header Toolbar
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: const BoxDecoration(
                  color: ShellitColors.obsidianHeader,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                  border: Border(
                    bottom: BorderSide(color: ShellitColors.border, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.isRemote ? Icons.cloud_outlined : Icons.computer,
                      size: 16,
                      color: ShellitColors.accentCyan,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.fileName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: ShellitColors.textPrimary,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                    if (_isDirty)
                      const Text(
                        ' *',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: ShellitColors.statusYellow,
                        ),
                      ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: ShellitColors.obsidianCard,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: ShellitColors.border),
                      ),
                      child: Text(
                        widget.isRemote ? 'Remote (SFTP)' : 'Local',
                        style: const TextStyle(
                          fontSize: 10,
                          color: ShellitColors.textSecondary,
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Word wrap toggle
                    IconButton(
                      icon: Icon(
                        _wordWrap ? Icons.wrap_text : Icons.notes,
                        size: 16,
                        color: _wordWrap
                            ? ShellitColors.accentCyan
                            : ShellitColors.textMuted,
                      ),
                      tooltip: context.tr('sftp.word_wrap',
                          defaultText: 'Toggle Word Wrap'),
                      onPressed: () => setState(() => _wordWrap = !_wordWrap),
                      visualDensity: VisualDensity.compact,
                    ),

                    // Reload
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 16),
                      tooltip: context.tr('common.refresh',
                          defaultText: 'Reload file'),
                      onPressed: _loadFile,
                      visualDensity: VisualDensity.compact,
                    ),

                    const SizedBox(width: 8),

                    // Save Button
                    ElevatedButton.icon(
                      icon: _isSaving
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(Icons.save_outlined,
                              size: 14, color: Colors.black),
                      label: Text(
                        context.tr('common.save', defaultText: 'Save (Ctrl+S)'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isDirty
                            ? ShellitColors.statusGreen
                            : ShellitColors.accentCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: _isSaving ? null : _saveFile,
                    ),

                    const SizedBox(width: 8),

                    // Close Button
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: context.tr('common.close', defaultText: 'Close'),
                      onPressed: () async {
                        final canClose = await _onWillPop();
                        if (canClose && context.mounted) {
                          Navigator.of(context).pop(true);
                        }
                      },
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

              // Editor Body
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                'Error loading file: $_errorMessage',
                                style: const TextStyle(
                                    color: ShellitColors.statusRed,
                                    fontSize: 13),
                              ),
                            ),
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Line numbers gutter
                              Container(
                                width: 44,
                                color: ShellitColors.obsidianHeader
                                    .withValues(alpha: 0.6),
                                child: ListView.builder(
                                  controller: _linesScrollController,
                                  itemCount: _lineCount,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 4),
                                  itemBuilder: (ctx, i) => Text(
                                    '${i + 1}',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'JetBrains Mono',
                                      color: (i + 1 == _cursorLine)
                                          ? ShellitColors.accentCyan
                                          : ShellitColors.textMuted
                                              .withValues(alpha: 0.5),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                              const VerticalDivider(
                                  width: 1, color: ShellitColors.border),

                              // Text Area
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  child: TextField(
                                    controller: _controller,
                                    scrollController: _textScrollController,
                                    maxLines: null,
                                    expands: true,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'JetBrains Mono',
                                      color: ShellitColors.textPrimary,
                                      height: 1.4,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
              ),

              // Bottom Status Bar
              Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: const BoxDecoration(
                  color: ShellitColors.obsidianHeader,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(10)),
                  border: Border(
                    top: BorderSide(color: ShellitColors.border, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      widget.path,
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'JetBrains Mono',
                        color: ShellitColors.textMuted,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Ln $_cursorLine, Col $_cursorCol',
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'JetBrains Mono',
                        color: ShellitColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      '$_lineCount lines',
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'JetBrains Mono',
                        color: ShellitColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'UTF-8',
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'JetBrains Mono',
                        color: ShellitColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
