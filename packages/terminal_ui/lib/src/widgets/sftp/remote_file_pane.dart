import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../localization/localization_scope.dart';
import '../../theme/shellit_theme.dart';
import 'local_file_pane.dart'; // For SftpSortField
import 'pane_reload_controller.dart';
import 'sftp_breadcrumbs.dart';
import 'sftp_dialogs.dart';
import 'sftp_drag_payload.dart';
import 'sftp_file_editor_dialog.dart';

class RemoteFilePane extends StatefulWidget {
  final ISftpSession session;
  final ValueChanged<SftpItem?>? onSelectionChanged;
  final ValueChanged<List<SftpItem>>? onMultiSelectionChanged;
  final ValueChanged<String>? onPathChanged;
  final VoidCallback? onDownloadSelected;
  final PaneReloadController? reloadController;

  const RemoteFilePane({
    super.key,
    required this.session,
    this.onSelectionChanged,
    this.onMultiSelectionChanged,
    this.onPathChanged,
    this.onDownloadSelected,
    this.reloadController,
  });

  @override
  State<RemoteFilePane> createState() => RemoteFilePaneState();
}

class RemoteFilePaneState extends State<RemoteFilePane> {
  String _currentPath = '/';
  List<SftpItem> _items = [];
  final Set<String> _selectedPaths = {};
  String? _lastAnchorPath;

  bool _isLoading = false;
  String? _errorMessage;
  bool _showHiddenFiles = false;
  bool _itemRightClickHandled = false;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  SftpSortField _sortField = SftpSortField.name;
  bool _sortAscending = true;

  final FocusNode _focusNode = FocusNode();

  List<SftpItem> get selectedItems =>
      _items.where((item) => _selectedPaths.contains(item.path)).toList();

  List<String> get selectedPaths => _selectedPaths.toList();

  @override
  void initState() {
    super.initState();
    widget.reloadController?.addListener(reload);
    _initStartingPath();
  }

  Future<void> _initStartingPath() async {
    setState(() => _isLoading = true);
    final homeResult = await widget.session.getDefaultPath();
    final startingPath = homeResult.valueOrNull ?? '/';
    _currentPath = startingPath;
    await _loadDirectory(startingPath);
  }

  @override
  void didUpdateWidget(covariant RemoteFilePane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reloadController != oldWidget.reloadController) {
      oldWidget.reloadController?.removeListener(reload);
      widget.reloadController?.addListener(reload);
    }
  }

  @override
  void dispose() {
    widget.reloadController?.removeListener(reload);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Public reload method for real-time updates.
  void reload() {
    _loadDirectory(_currentPath);
  }

  Future<void> _loadDirectory(String path) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await widget.session.listDirectory(path);
    if (!mounted) return;

    result.when(
      success: (items) {
        var filtered = items;
        if (!_showHiddenFiles) {
          filtered = items.where((i) => !i.name.startsWith('.')).toList();
        }

        final sorted = List<SftpItem>.from(filtered);
        sorted.sort((a, b) {
          if (a.isDirectory && !b.isDirectory) return -1;
          if (!a.isDirectory && b.isDirectory) return 1;

          int cmp = 0;
          switch (_sortField) {
            case SftpSortField.name:
              cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
              break;
            case SftpSortField.size:
              cmp = a.sizeBytes.compareTo(b.sizeBytes);
              break;
            case SftpSortField.modified:
              cmp = a.modifiedAt.compareTo(b.modifiedAt);
              break;
          }
          return _sortAscending ? cmp : -cmp;
        });

        setState(() {
          _currentPath = path;
          _items = sorted;
          _selectedPaths.clear();
          _lastAnchorPath = null;
          _isLoading = false;
        });
        widget.onPathChanged?.call(path);
        _notifySelectionChanged();
      },
      error: (err) {
        setState(() {
          _isLoading = false;
          _errorMessage = err.message;
        });
      },
    );
  }

  void _notifySelectionChanged() {
    final list = selectedItems;
    widget.onSelectionChanged?.call(list.isNotEmpty ? list.first : null);
    widget.onMultiSelectionChanged?.call(list);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ShellitColors.statusRed,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _navigateUp() {
    if (_currentPath == '/' || _currentPath.isEmpty) return;
    final parts = _currentPath.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.isNotEmpty) {
      parts.removeLast();
    }
    final parent = parts.isEmpty ? '/' : '/${parts.join('/')}';
    _loadDirectory(parent);
  }

  Future<void> _navigateToHome() async {
    final res = await widget.session.getDefaultPath();
    final home = res.valueOrNull ?? '/';
    _loadDirectory(home);
  }

  void _navigateToRoot() {
    _loadDirectory('/');
  }

  String _join(String parent, String name) {
    if (parent.endsWith('/')) {
      return '$parent$name';
    }
    return '$parent/$name';
  }

  void _toggleSort(SftpSortField field) {
    setState(() {
      if (_sortField == field) {
        _sortAscending = !_sortAscending;
      } else {
        _sortField = field;
        _sortAscending = true;
      }
    });
    _loadDirectory(_currentPath);
  }

  void _selectSingle(SftpItem item) {
    setState(() {
      _selectedPaths.clear();
      _selectedPaths.add(item.path);
      _lastAnchorPath = item.path;
    });
    _notifySelectionChanged();
  }

  void _toggleSelect(SftpItem item) {
    setState(() {
      if (_selectedPaths.contains(item.path)) {
        _selectedPaths.remove(item.path);
      } else {
        _selectedPaths.add(item.path);
        _lastAnchorPath = item.path;
      }
    });
    _notifySelectionChanged();
  }

  void _selectRangeTo(SftpItem target) {
    final filtered = _getFilteredItems();
    if (_lastAnchorPath == null || filtered.isEmpty) {
      _selectSingle(target);
      return;
    }

    final anchorIdx = filtered.indexWhere((i) => i.path == _lastAnchorPath);
    final targetIdx = filtered.indexWhere((i) => i.path == target.path);
    if (anchorIdx == -1 || targetIdx == -1) {
      _selectSingle(target);
      return;
    }

    final start = anchorIdx < targetIdx ? anchorIdx : targetIdx;
    final end = anchorIdx < targetIdx ? targetIdx : anchorIdx;

    setState(() {
      _selectedPaths.clear();
      for (int i = start; i <= end; i++) {
        _selectedPaths.add(filtered[i].path);
      }
    });
    _notifySelectionChanged();
  }

  void _selectAll() {
    final filtered = _getFilteredItems();
    setState(() {
      _selectedPaths.clear();
      for (final item in filtered) {
        _selectedPaths.add(item.path);
      }
    });
    _notifySelectionChanged();
  }

  void _clearSelection() {
    setState(() {
      _selectedPaths.clear();
      _lastAnchorPath = null;
    });
    _notifySelectionChanged();
  }

  List<SftpItem> _getFilteredItems() {
    if (_searchQuery.trim().isEmpty) return _items;
    final q = _searchQuery.trim().toLowerCase();
    return _items.where((item) => item.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _createNewDirectory() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const SftpCreateDialog(isDirectory: true),
    );
    if (name != null && name.isNotEmpty) {
      final newPath = _join(_currentPath, name);
      final res = await widget.session.createDirectory(newPath);
      res.when(
        success: (_) => reload(),
        error: (err) => _showError(err.message),
      );
    }
  }

  Future<void> _createNewFile() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const SftpCreateDialog(isDirectory: false),
    );
    if (name != null && name.isNotEmpty) {
      final newPath = _join(_currentPath, name);
      final res = await widget.session.createFile(newPath);
      res.when(
        success: (_) => reload(),
        error: (err) => _showError(err.message),
      );
    }
  }

  Future<void> _deleteSelected() async {
    final items = selectedItems;
    if (items.isEmpty) return;

    final isSingle = items.length == 1;
    final firstName = items.first.name;
    final isDir = isSingle && items.first.isDirectory;

    final title = isSingle
        ? (isDir
            ? context.tr('sftp.delete_dir_title',
                defaultText: 'Delete Directory')
            : context.tr('sftp.delete_file_title', defaultText: 'Delete File'))
        : context.tr('sftp.delete_batch_title',
            defaultText: 'Delete {count} items',
            namedArgs: {'count': items.length.toString()});

    final message = isSingle
        ? context.tr('sftp.delete_confirm_msg',
            defaultText: 'Are you sure you want to delete "{name}"?',
            namedArgs: {'name': firstName})
        : context.tr('sftp.delete_batch_confirm_msg',
            defaultText:
                'Are you sure you want to delete {count} selected files/folders from server?',
            namedArgs: {'count': items.length.toString()});

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ShellitColors.obsidianCard,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
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
            child: Text(context.tr('common.delete', defaultText: 'Delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final item in items) {
        final res = item.isDirectory
            ? await widget.session.deleteDirectory(item.path, recursive: true)
            : await widget.session.deleteFile(item.path);
        if (res.isError) {
          _showError(res.failureOrNull?.message ?? 'Delete failed');
        }
      }
      reload();
    }
  }

  void _openFileInEditor(SftpItem item) {
    if (item.isDirectory) return;
    SftpFileEditorDialog.openRemote(
      context,
      session: widget.session,
      remotePath: item.path,
      fileName: item.name,
      fileSize: item.sizeBytes,
    ).then((_) => reload());
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatPermissions(int mode) {
    final octal = mode.toRadixString(8);
    return octal.length >= 3 ? octal.substring(octal.length - 3) : octal;
  }

  Future<void> _showItemContextMenu(
    BuildContext context,
    SftpItem item,
    Offset globalPosition,
  ) async {
    _itemRightClickHandled = true;
    if (!_selectedPaths.contains(item.path)) {
      _selectSingle(item);
    }

    final selectedCount = _selectedPaths.length;
    final isSingle = selectedCount <= 1;

    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final position = RelativeRect.fromRect(
      globalPosition & const Size(40, 40),
      Offset.zero & (overlay?.size ?? MediaQuery.of(context).size),
    );

    final action = await showMenu<String>(
      context: context,
      position: position,
      color: ShellitColors.obsidianCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: ShellitColors.border),
      ),
      items: [
        PopupMenuItem(
          value: 'download',
          height: 36,
          child: Row(
            children: [
              const Icon(Icons.download,
                  size: 16, color: ShellitColors.accentCyan),
              const SizedBox(width: 8),
              Text(
                isSingle
                    ? context.tr('sftp.download', defaultText: 'Download')
                    : context.tr('sftp.download_selected',
                        defaultText: 'Download {count} items',
                        namedArgs: {'count': selectedCount.toString()}),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        if (isSingle && !item.isDirectory)
          PopupMenuItem(
            value: 'edit',
            height: 36,
            child: Row(
              children: [
                const Icon(Icons.edit_note,
                    size: 16, color: ShellitColors.accentCyan),
                const SizedBox(width: 8),
                Text(context.tr('sftp.edit_file', defaultText: 'Edit File'),
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        if (isSingle)
          PopupMenuItem(
            value: 'chmod',
            height: 36,
            child: Row(
              children: [
                const Icon(Icons.security,
                    size: 16, color: ShellitColors.accentBlue),
                const SizedBox(width: 8),
                Text(
                    context.tr('sftp.permissions_chmod',
                        defaultText: 'Permissions (chmod)'),
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        if (isSingle)
          PopupMenuItem(
            value: 'copy_path',
            height: 36,
            child: Row(
              children: [
                const Icon(Icons.copy,
                    size: 16, color: ShellitColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                    context.tr('sftp.copy_remote_path',
                        defaultText: 'Copy Remote Path'),
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        const PopupMenuDivider(height: 1),
        if (isSingle)
          PopupMenuItem(
            value: 'rename',
            height: 36,
            child: Row(
              children: [
                const Icon(Icons.edit_outlined,
                    size: 16, color: ShellitColors.accentBlue),
                const SizedBox(width: 8),
                Text(context.tr('sftp.rename', defaultText: 'Rename'),
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'delete',
          height: 36,
          child: Row(
            children: [
              const Icon(Icons.delete_outline,
                  size: 16, color: ShellitColors.statusRed),
              const SizedBox(width: 8),
              Text(
                isSingle
                    ? context.tr('common.delete', defaultText: 'Delete')
                    : context.tr('sftp.delete_selected',
                        defaultText: 'Delete {count} items',
                        namedArgs: {'count': selectedCount.toString()}),
                style: const TextStyle(
                    fontSize: 12, color: ShellitColors.statusRed),
              ),
            ],
          ),
        ),
      ],
    );

    if (!mounted || action == null) return;

    switch (action) {
      case 'download':
        widget.onDownloadSelected?.call();
        break;
      case 'edit':
        _openFileInEditor(item);
        break;
      case 'chmod':
        final newPermissions = await showDialog<int>(
          context: context,
          builder: (_) => SftpChmodDialog(
            fileName: item.name,
            initialPermissions: item.permissions,
          ),
        );
        if (newPermissions != null) {
          final res =
              await widget.session.setPermissions(item.path, newPermissions);
          res.when(
            success: (_) => reload(),
            error: (err) => _showError(err.message),
          );
        }
        break;
      case 'copy_path':
        await Clipboard.setData(ClipboardData(text: item.path));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('sftp.copied_path',
                  defaultText: 'Copied: {path}',
                  namedArgs: {'path': item.path})),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        break;
      case 'rename':
        final newName = await showDialog<String>(
          context: context,
          builder: (_) => SftpRenameDialog(currentName: item.name),
        );
        if (newName != null && newName.isNotEmpty && newName != item.name) {
          final newPath = _join(_currentPath, newName);
          final res = await widget.session.rename(item.path, newPath);
          res.when(
            success: (_) => reload(),
            error: (err) => _showError(err.message),
          );
        }
        break;
      case 'delete':
        await _deleteSelected();
        break;
    }
  }

  Future<void> _showBackgroundContextMenu(
      BuildContext context, Offset globalPosition) async {
    if (_itemRightClickHandled) {
      _itemRightClickHandled = false;
      return;
    }

    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final position = RelativeRect.fromRect(
      globalPosition & const Size(40, 40),
      Offset.zero & (overlay?.size ?? MediaQuery.of(context).size),
    );

    final action = await showMenu<String>(
      context: context,
      position: position,
      color: ShellitColors.obsidianCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: ShellitColors.border),
      ),
      items: [
        PopupMenuItem(
          value: 'new_folder',
          height: 36,
          child: Row(
            children: [
              const Icon(Icons.create_new_folder_outlined,
                  size: 16, color: ShellitColors.accentCyan),
              const SizedBox(width: 8),
              Text(
                  context.tr('sftp.new_directory',
                      defaultText: 'New Directory'),
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'new_file',
          height: 36,
          child: Row(
            children: [
              const Icon(Icons.note_add_outlined,
                  size: 16, color: ShellitColors.accentBlue),
              const SizedBox(width: 8),
              Text(context.tr('sftp.new_file', defaultText: 'New File'),
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem(
          value: 'select_all',
          height: 36,
          child: Row(
            children: [
              const Icon(Icons.select_all,
                  size: 16, color: ShellitColors.accentCyan),
              const SizedBox(width: 8),
              Text(
                  context.tr('sftp.select_all',
                      defaultText: 'Select All (Ctrl+A)'),
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'refresh',
          height: 36,
          child: Row(
            children: [
              const Icon(Icons.refresh,
                  size: 16, color: ShellitColors.textSecondary),
              const SizedBox(width: 8),
              Text(context.tr('common.refresh', defaultText: 'Refresh'),
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'toggle_hidden',
          height: 36,
          child: Row(
            children: [
              Icon(
                _showHiddenFiles ? Icons.visibility_off : Icons.visibility,
                size: 16,
                color: ShellitColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                _showHiddenFiles
                    ? context.tr('sftp.hide_hidden_files',
                        defaultText: 'Hide Hidden Files')
                    : context.tr('sftp.show_hidden_files',
                        defaultText: 'Show Hidden Files'),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );

    if (!mounted || action == null) return;

    switch (action) {
      case 'new_folder':
        await _createNewDirectory();
        break;
      case 'new_file':
        await _createNewFile();
        break;
      case 'select_all':
        _selectAll();
        break;
      case 'refresh':
        reload();
        break;
      case 'toggle_hidden':
        setState(() {
          _showHiddenFiles = !_showHiddenFiles;
          _loadDirectory(_currentPath);
        });
        break;
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final isCtrlOrCmd = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    if (isCtrlOrCmd && event.logicalKey == LogicalKeyboardKey.keyA) {
      _selectAll();
      return;
    }

    if (event.logicalKey == LogicalKeyboardKey.delete) {
      _deleteSelected();
      return;
    }

    if (event.logicalKey == LogicalKeyboardKey.f2 &&
        _selectedPaths.length == 1) {
      final item = selectedItems.first;
      showDialog<String>(
        context: context,
        builder: (_) => SftpRenameDialog(currentName: item.name),
      ).then((newName) {
        if (newName != null && newName.isNotEmpty && newName != item.name) {
          widget.session
              .rename(item.path, _join(_currentPath, newName))
              .then((res) {
            res.when(
              success: (_) => reload(),
              error: (err) => _showError(err.message),
            );
          });
        }
      });
      return;
    }

    if (event.logicalKey == LogicalKeyboardKey.f5) {
      widget.onDownloadSelected?.call();
      return;
    }

    if (event.logicalKey == LogicalKeyboardKey.space &&
        _selectedPaths.length == 1) {
      final item = selectedItems.first;
      if (!item.isDirectory) {
        _openFileInEditor(item);
      }
      return;
    }

    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _navigateUp();
      return;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter &&
        _selectedPaths.length == 1) {
      final item = selectedItems.first;
      if (item.isDirectory) {
        _loadDirectory(item.path);
      } else {
        _openFileInEditor(item);
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredItems();

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Container(
        color: ShellitColors.obsidianBackground,
        child: Column(
          children: [
            // Breadcrumbs Bar
            SftpBreadcrumbsBar(
              currentPath: _currentPath,
              isRemote: true,
              onNavigate: (path) => _loadDirectory(path),
              onRefresh: reload,
              onNavigateUp: _navigateUp,
              onNavigateHome: _navigateToHome,
              onNavigateRoot: _navigateToRoot,
            ),

            // Secondary Quick Actions & Search Bar
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: const BoxDecoration(
                color: ShellitColors.obsidianBackground,
                border: Border(
                  bottom: BorderSide(color: ShellitColors.border, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_outlined,
                      size: 15, color: ShellitColors.accentCyan),
                  const SizedBox(width: 6),
                  Text(
                    context.tr('sftp.remote_title',
                        defaultText: 'Remote Files'),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),

                  // Search Filter
                  Expanded(
                    child: SizedBox(
                      height: 24,
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(fontSize: 11),
                        decoration: InputDecoration(
                          hintText: context.tr('sftp.filter_hint',
                              defaultText: 'Filter files...'),
                          hintStyle: const TextStyle(
                              fontSize: 11, color: ShellitColors.textMuted),
                          prefixIcon: const Icon(Icons.search,
                              size: 14, color: ShellitColors.textMuted),
                          prefixIconConstraints:
                              const BoxConstraints(minWidth: 24),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 12),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                )
                              : null,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 4),
                          filled: true,
                          fillColor: ShellitColors.obsidianCard,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide:
                                const BorderSide(color: ShellitColors.border),
                          ),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                  ),

                  IconButton(
                    icon:
                        const Icon(Icons.create_new_folder_outlined, size: 15),
                    tooltip: context.tr('sftp.new_directory',
                        defaultText: 'New Directory'),
                    onPressed: _createNewDirectory,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(Icons.note_add_outlined, size: 15),
                    tooltip:
                        context.tr('sftp.new_file', defaultText: 'New File'),
                    onPressed: _createNewFile,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: Icon(
                      _showHiddenFiles
                          ? Icons.visibility
                          : Icons.visibility_off,
                      size: 15,
                      color: _showHiddenFiles
                          ? ShellitColors.accentCyan
                          : ShellitColors.textMuted,
                    ),
                    tooltip: _showHiddenFiles
                        ? context.tr('sftp.hide_hidden_files',
                            defaultText: 'Hide Hidden Files')
                        : context.tr('sftp.show_hidden_files',
                            defaultText: 'Show Hidden Files'),
                    onPressed: () {
                      setState(() {
                        _showHiddenFiles = !_showHiddenFiles;
                        _loadDirectory(_currentPath);
                      });
                    },
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            // Table Column Headers (Clickable for Sorting)
            Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              color: ShellitColors.obsidianCard.withValues(alpha: 0.6),
              child: Row(
                children: [
                  const SizedBox(width: 24), // Checkbox space
                  Expanded(
                    child: InkWell(
                      onTap: () => _toggleSort(SftpSortField.name),
                      child: Row(
                        children: [
                          Text(
                            context.tr('sftp.col_name', defaultText: 'Name'),
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: ShellitColors.textMuted),
                          ),
                          if (_sortField == SftpSortField.name)
                            Icon(
                              _sortAscending
                                  ? Icons.arrow_drop_up
                                  : Icons.arrow_drop_down,
                              size: 14,
                              color: ShellitColors.accentCyan,
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: InkWell(
                      onTap: () => _toggleSort(SftpSortField.size),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            context.tr('sftp.col_size', defaultText: 'Size'),
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: ShellitColors.textMuted),
                          ),
                          if (_sortField == SftpSortField.size)
                            Icon(
                              _sortAscending
                                  ? Icons.arrow_drop_up
                                  : Icons.arrow_drop_down,
                              size: 14,
                              color: ShellitColors.accentCyan,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  SizedBox(
                    width: 50,
                    child: Text(
                      context.tr('sftp.col_mode', defaultText: 'Mode'),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: ShellitColors.textMuted),
                    ),
                  ),
                  const SizedBox(width: 14),
                  SizedBox(
                    width: 80,
                    child: InkWell(
                      onTap: () => _toggleSort(SftpSortField.modified),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            context.tr('sftp.col_date', defaultText: 'Date'),
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: ShellitColors.textMuted),
                          ),
                          if (_sortField == SftpSortField.modified)
                            Icon(
                              _sortAscending
                                  ? Icons.arrow_drop_up
                                  : Icons.arrow_drop_down,
                              size: 14,
                              color: ShellitColors.accentCyan,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // File List with Multi-Select and Drag Support
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Text(
                            'Error: $_errorMessage',
                            style: const TextStyle(
                                color: ShellitColors.statusRed, fontSize: 12),
                          ),
                        )
                      : GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onSecondaryTapDown: (details) =>
                              _showBackgroundContextMenu(
                                  context, details.globalPosition),
                          child: filtered.isEmpty
                              ? Center(
                                  child: Text(
                                    _searchQuery.isNotEmpty
                                        ? context.tr('sftp.no_matching_items',
                                            defaultText: 'No matching items')
                                        : (_showHiddenFiles
                                            ? context.tr('sftp.empty_folder',
                                                defaultText: 'Empty folder')
                                            : context.tr('sftp.no_items_hidden',
                                                defaultText:
                                                    'No items (hidden files excluded)')),
                                    style: const TextStyle(
                                        color: ShellitColors.textMuted,
                                        fontSize: 12),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.only(bottom: 60),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) {
                                    final item = filtered[index];
                                    final isSelected =
                                        _selectedPaths.contains(item.path);

                                    return Draggable<SftpRemoteDragPayload>(
                                      data: SftpRemoteDragPayload(
                                        isSelected
                                            ? _selectedPaths.toList()
                                            : [item.path],
                                      ),
                                      feedback: Material(
                                        elevation: 4,
                                        borderRadius: BorderRadius.circular(6),
                                        color: ShellitColors.obsidianCard,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                                color:
                                                    ShellitColors.accentBlue),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                item.isDirectory
                                                    ? Icons.folder
                                                    : Icons
                                                        .insert_drive_file_outlined,
                                                size: 14,
                                                color: ShellitColors.accentBlue,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                _selectedPaths.length > 1 &&
                                                        isSelected
                                                    ? '${_selectedPaths.length} items'
                                                    : item.name,
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onSecondaryTapDown: (details) =>
                                            _showItemContextMenu(context, item,
                                                details.globalPosition),
                                        child: InkWell(
                                          onTap: () {
                                            final isCtrlOrCmd = HardwareKeyboard
                                                    .instance
                                                    .isControlPressed ||
                                                HardwareKeyboard
                                                    .instance.isMetaPressed;
                                            final isShift = HardwareKeyboard
                                                .instance.isShiftPressed;

                                            if (isShift) {
                                              _selectRangeTo(item);
                                            } else if (isCtrlOrCmd) {
                                              _toggleSelect(item);
                                            } else {
                                              _selectSingle(item);
                                            }
                                          },
                                          onDoubleTap: () {
                                            if (item.isDirectory) {
                                              _loadDirectory(item.path);
                                            } else {
                                              _openFileInEditor(item);
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? ShellitColors.accentCyan
                                                      .withValues(alpha: 0.18)
                                                  : Colors.transparent,
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: ShellitColors.border
                                                      .withValues(alpha: 0.4),
                                                  width: 0.5,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                // Multi-select checkbox
                                                SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child: Checkbox(
                                                    value: isSelected,
                                                    activeColor: ShellitColors
                                                        .accentCyan,
                                                    side: const BorderSide(
                                                      color:
                                                          ShellitColors.border,
                                                      width: 1,
                                                    ),
                                                    onChanged: (_) =>
                                                        _toggleSelect(item),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),

                                                // Icon
                                                Icon(
                                                  item.isDirectory
                                                      ? Icons.folder
                                                      : Icons
                                                          .insert_drive_file_outlined,
                                                  size: 15,
                                                  color: item.isDirectory
                                                      ? ShellitColors.accentCyan
                                                      : ShellitColors
                                                          .textSecondary,
                                                ),
                                                const SizedBox(width: 6),

                                                // Name
                                                Expanded(
                                                  child: Text(
                                                    item.name,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isSelected
                                                          ? ShellitColors
                                                              .accentCyan
                                                          : ShellitColors
                                                              .textPrimary,
                                                      fontWeight: item
                                                              .isDirectory
                                                          ? FontWeight.w500
                                                          : FontWeight.normal,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),

                                                // Size
                                                if (!item.isDirectory)
                                                  SizedBox(
                                                    width: 70,
                                                    child: Text(
                                                      _formatSize(
                                                          item.sizeBytes),
                                                      textAlign:
                                                          TextAlign.right,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: ShellitColors
                                                            .textMuted,
                                                        fontFamily:
                                                            'JetBrains Mono',
                                                      ),
                                                    ),
                                                  )
                                                else
                                                  const SizedBox(width: 70),

                                                const SizedBox(width: 14),

                                                // Permissions
                                                SizedBox(
                                                  width: 50,
                                                  child: Text(
                                                    _formatPermissions(
                                                        item.permissions),
                                                    textAlign: TextAlign.right,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: ShellitColors
                                                          .textMuted,
                                                      fontFamily:
                                                          'JetBrains Mono',
                                                    ),
                                                  ),
                                                ),

                                                const SizedBox(width: 14),

                                                // Date
                                                SizedBox(
                                                  width: 80,
                                                  child: Text(
                                                    '${item.modifiedAt.year}-${item.modifiedAt.month.toString().padLeft(2, '0')}-${item.modifiedAt.day.toString().padLeft(2, '0')}',
                                                    textAlign: TextAlign.right,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: ShellitColors
                                                          .textMuted,
                                                      fontFamily:
                                                          'JetBrains Mono',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
            ),

            // Batch Action Toolbar (When 1 or more items selected)
            if (_selectedPaths.isNotEmpty)
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: const BoxDecoration(
                  color: ShellitColors.obsidianHeader,
                  border: Border(
                    top: BorderSide(color: ShellitColors.border, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      context.tr('sftp.selected_count',
                          defaultText: '{count} selected',
                          namedArgs: {
                            'count': _selectedPaths.length.toString()
                          }),
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: ShellitColors.accentCyan),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _clearSelection,
                      child: Text(
                          context.tr('sftp.deselect', defaultText: 'Deselect'),
                          style: const TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 16, color: ShellitColors.statusRed),
                      tooltip:
                          context.tr('common.delete', defaultText: 'Delete'),
                      onPressed: _deleteSelected,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.download,
                          size: 14, color: Colors.black),
                      label: Text(
                        context.tr('sftp.download', defaultText: 'Download'),
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ShellitColors.accentCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: widget.onDownloadSelected,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
