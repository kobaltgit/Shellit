import 'dart:io';
import 'package:flutter/material.dart';
import '../../localization/localization_scope.dart';
import '../../theme/shellit_theme.dart';

/// Interactive Breadcrumbs and navigation bar for SFTP panes.
/// Supports clicking any path segment, history back/forward,
/// quick home/root jumps, and in-place manual path editing.
class SftpBreadcrumbsBar extends StatefulWidget {
  final String currentPath;
  final bool isRemote;
  final ValueChanged<String> onNavigate;
  final VoidCallback onRefresh;
  final VoidCallback onNavigateUp;
  final VoidCallback onNavigateHome;
  final VoidCallback? onNavigateRoot;

  const SftpBreadcrumbsBar({
    super.key,
    required this.currentPath,
    required this.isRemote,
    required this.onNavigate,
    required this.onRefresh,
    required this.onNavigateUp,
    required this.onNavigateHome,
    this.onNavigateRoot,
  });

  @override
  State<SftpBreadcrumbsBar> createState() => _SftpBreadcrumbsBarState();
}

class _SftpBreadcrumbsBarState extends State<SftpBreadcrumbsBar> {
  bool _isEditing = false;
  late TextEditingController _textController;
  final FocusNode _editFocusNode = FocusNode();

  // Navigation History Stack
  final List<String> _historyBack = [];
  final List<String> _historyForward = [];
  String? _lastTrackedPath;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.currentPath);
    _lastTrackedPath = widget.currentPath;
  }

  @override
  void didUpdateWidget(covariant SftpBreadcrumbsBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPath != oldWidget.currentPath) {
      if (!_isEditing) {
        _textController.text = widget.currentPath;
      }
      if (_lastTrackedPath != null && _lastTrackedPath != widget.currentPath) {
        _historyBack.add(_lastTrackedPath!);
        // Cap history to 50 entries
        if (_historyBack.length > 50) {
          _historyBack.removeAt(0);
        }
        _historyForward.clear();
      }
      _lastTrackedPath = widget.currentPath;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _editFocusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _textController.text = widget.currentPath;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _editFocusNode.requestFocus();
        _textController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _textController.text.length,
        );
      }
    });
  }

  void _finishEditing(String value) {
    setState(() => _isEditing = false);
    final trimmed = value.trim();
    if (trimmed.isNotEmpty && trimmed != widget.currentPath) {
      widget.onNavigate(trimmed);
    }
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _textController.text = widget.currentPath;
    });
  }

  void _goBack() {
    if (_historyBack.isNotEmpty) {
      final prev = _historyBack.removeLast();
      if (_lastTrackedPath != null) {
        _historyForward.add(_lastTrackedPath!);
      }
      _lastTrackedPath = prev;
      widget.onNavigate(prev);
    }
  }

  void _goForward() {
    if (_historyForward.isNotEmpty) {
      final next = _historyForward.removeLast();
      if (_lastTrackedPath != null) {
        _historyBack.add(_lastTrackedPath!);
      }
      _lastTrackedPath = next;
      widget.onNavigate(next);
    }
  }

  List<BreadcrumbSegment> _parseSegments(String path, bool isRemote) {
    final segments = <BreadcrumbSegment>[];
    if (path.isEmpty) return segments;

    final isWindows = !isRemote && Platform.isWindows;

    if (isWindows) {
      // e.g. C:\Users\Kobalt\Docs
      final parts =
          path.split(RegExp(r'[\\/]')).where((p) => p.isNotEmpty).toList();
      String accumulated = '';
      for (int i = 0; i < parts.length; i++) {
        final part = parts[i];
        if (i == 0 && part.endsWith(':')) {
          accumulated = '$part\\';
        } else if (accumulated.endsWith('\\')) {
          accumulated = '$accumulated$part';
        } else {
          accumulated = '$accumulated\\$part';
        }
        segments.add(BreadcrumbSegment(name: part, fullPath: accumulated));
      }
    } else {
      // Unix-style /var/log/nginx
      segments.add(const BreadcrumbSegment(name: '/', fullPath: '/'));
      final parts = path.split('/').where((p) => p.isNotEmpty).toList();
      String accumulated = '';
      for (final part in parts) {
        accumulated = '$accumulated/$part';
        segments.add(BreadcrumbSegment(name: part, fullPath: accumulated));
      }
    }

    return segments;
  }

  @override
  Widget build(BuildContext context) {
    final segments = _parseSegments(widget.currentPath, widget.isRemote);

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: const BoxDecoration(
        color: ShellitColors.obsidianHeader,
        border: Border(
          bottom: BorderSide(color: ShellitColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // History Back
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 13),
            tooltip: context.tr('sftp.nav_back', defaultText: 'Back'),
            onPressed: _historyBack.isNotEmpty ? _goBack : null,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
          ),

          // History Forward
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 13),
            tooltip: context.tr('sftp.nav_forward', defaultText: 'Forward'),
            onPressed: _historyForward.isNotEmpty ? _goForward : null,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
          ),

          // Go Up (Parent)
          IconButton(
            icon: const Icon(Icons.arrow_upward, size: 15),
            tooltip:
                context.tr('sftp.go_up', defaultText: 'Up to parent folder'),
            onPressed: widget.onNavigateUp,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
          ),

          // Home (~)
          IconButton(
            icon: const Icon(Icons.home_outlined, size: 15),
            tooltip:
                context.tr('sftp.go_home', defaultText: 'Home directory (~)'),
            onPressed: widget.onNavigateHome,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
          ),

          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh, size: 15),
            tooltip: context.tr('common.refresh', defaultText: 'Refresh'),
            onPressed: widget.onRefresh,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
          ),

          const SizedBox(width: 4),

          // Breadcrumb Track or Editable TextField
          Expanded(
            child: _isEditing
                ? SizedBox(
                    height: 28,
                    child: TextField(
                      controller: _textController,
                      focusNode: _editFocusNode,
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'JetBrains Mono',
                        color: ShellitColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.close, size: 14),
                          tooltip: context.tr('common.cancel',
                              defaultText: 'Cancel'),
                          onPressed: _cancelEditing,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      onSubmitted: _finishEditing,
                    ),
                  )
                : Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: ShellitColors.obsidianBackground,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: ShellitColors.border.withValues(alpha: 0.8)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            reverse: true,
                            child: Row(
                              children: [
                                for (int i = 0; i < segments.length; i++) ...[
                                  _BreadcrumbChip(
                                    segment: segments[i],
                                    isLast: i == segments.length - 1,
                                    onTap: () =>
                                        widget.onNavigate(segments[i].fullPath),
                                  ),
                                  if (i < segments.length - 1 &&
                                      segments[i].name != '/')
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 2),
                                      child: Icon(
                                        Icons.chevron_right,
                                        size: 14,
                                        color: ShellitColors.textMuted,
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: _startEditing,
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 13,
                              color: ShellitColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class BreadcrumbSegment {
  final String name;
  final String fullPath;

  const BreadcrumbSegment({required this.name, required this.fullPath});
}

class _BreadcrumbChip extends StatelessWidget {
  final BreadcrumbSegment segment;
  final bool isLast;
  final VoidCallback onTap;

  const _BreadcrumbChip({
    required this.segment,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLast ? null : onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          segment.name,
          style: TextStyle(
            fontSize: 11,
            fontFamily: 'JetBrains Mono',
            fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
            color:
                isLast ? ShellitColors.accentCyan : ShellitColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
