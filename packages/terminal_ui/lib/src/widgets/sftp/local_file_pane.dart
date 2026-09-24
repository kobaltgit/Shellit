import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../localization/localization_scope.dart';
import '../../theme/shellit_theme.dart';
import 'pane_reload_controller.dart';
import 'sftp_breadcrumbs.dart';
import 'sftp_dialogs.dart';
import 'sftp_drag_payload.dart';
import 'sftp_file_editor_dialog.dart';

enum SftpSortField { name, size, modified }

class LocalFilePane extends StatefulWidget {
  final ValueChanged<FileSystemEntity?>? onSelectionChanged;
  final ValueChanged<List<FileSystemEntity>>? onMultiSelectionChanged;
  final ValueChanged<String>? onPathChanged;
  final VoidCallback? onUploadSelected;
  final PaneReloadController? reloadController;

  const LocalFilePane({
    super.key,
    this.onSelectionChanged,
    this.onMultiSelectionChanged,
    this.onPathChanged,
    this.onUploadSelected,
    this.reloadController,
  });

  @override
  State<LocalFilePane> createState() => LocalFilePaneState();
}

class LocalFilePaneState extends State<LocalFilePane> {
  late Directory _currentDirectory;
  List<FileSystemEntity> _items = [];
  final Set<String> _selectedPaths = {};
  String? _lastAnchorPath;

  bool _showHiddenFiles = false;
  bool _itemRightClickHandled = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  SftpSortField _sortField = SftpSortField.name;
  bool _sortAscending = true;

  final FocusNode _focusNode = FocusNode();

  List<FileSystemEntity> get selectedEntities =>
      _items.where((item) => _selectedPaths.contains(item.path)).toList();

  List<String> get selectedPaths => _selectedPaths.toList();

  @override
  void initState() {
    super.initState();
    widget.reloadController?.addListener(reload);
    _currentDirectory = _getInitialDirectory();
    _readDirectorySync(_currentDirectory);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onPathChanged?.call(_currentDirectory.path);
      widget.onSelectionChanged?.call(null);
      widget.onMultiSelectionChanged?.call([]);
    });
  }

  @override
  void didUpdateWidget(covariant LocalFilePane oldWidget) {
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

  Directory _getInitialDirectory() {
    try {
      final userProfile =
          Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
      if (userProfile != null && Directory(userProfile).existsSync()) {
        return Directory(userProfile);
      }
      return Directory.current;
    } catch (_) {
      return Directory.current;
    }
  }

  /// Public reload method for real-time updates.
  void reload() {
    _loadDirectory(_currentDirectory);
  }

  void _readDirectorySync(Directory dir) {
    try {
      var list = dir.listSync().toList();
      if (!_showHiddenFiles) {
        list = list.where((entity) {
          final name = entity.path.split(Platform.pathSeparator).last;
          return !name.startsWith('.');
        }).toList();
      }

      list.sort((a, b) {
        final aIsDir = FileSystemEntity.isDirectorySync(a.path);
        final bIsDir = FileSystemEntity.isDirectorySync(b.path);
        if (aIsDir && !bIsDir) return -1;
        if (!aIsDir && bIsDir) return 1;

        int cmp = 0;
        switch (_sortField) {
          case SftpSortField.name:
            final aName = a.path.split(Platform.pathSeparator).last;
            final bName = b.path.split(Platform.pathSeparator).last;
            cmp = aName.toLowerCase().compareTo(bName.toLowerCase());
            break;
          case SftpSortField.size:
            int aSize = 0, bSize = 0;
            if (!aIsDir) {
              try {
                aSize = a.statSync().size;
              } catch (_) {}
            }
            if (!bIsDir) {
              try {
                bSize = b.statSync().size;
              } catch (_) {}
            }
            cmp = aSize.compareTo(bSize);
            break;
          case SftpSortField.modified:
            DateTime aMod = DateTime(1970), bMod = DateTime(1970);
            try {
              aMod = a.statSync().modified;
            } catch (_) {}
            try {
              bMod = b.statSync().modified;
            } catch (_) {}
            cmp = aMod.compareTo(bMod);
            break;
        }
        return _sortAscending ? cmp : -cmp;
      });

      _currentDirectory = dir;
      _items = list;
      _selectedPaths.clear();
      _lastAnchorPath = null;
    } catch (e) {
      _items = [];
      _selectedPaths.clear();
      _lastAnchorPath = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showError('Failed to read directory: $e');
      });
    }
  }

  void _loadDirectory(Directory dir) {
    _readDirectorySync(dir);
    if (mounted) {
      setState(() {});
    }
    widget.onPathChanged?.call(dir.path);
    _notifySelectionChanged();
  }

  void _notifySelectionChanged() {
    final selectedList = selectedEntities;
    widget.onSelectionChanged
        ?.call(selectedList.isNotEmpty ? selectedList.first : null);
    widget.onMultiSelectionChanged?.call(selectedList);
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
    final parent = _currentDirectory.parent;
    if (parent.path != _currentDirectory.path) {
      _loadDirectory(parent);
    }
  }

  void _navigateToHome() {
    final home = Platform.environment['USERPROFILE'] ??
        Platform.environment['HOME'] ??
        Directory.current.path;
    _loadDirectory(Directory(home));
  }

  void _navigateToRoot() {
    if (Platform.isWindows) {
      final drive = _currentDirectory.path.substring(0, 3); // e.g. C:\
      _loadDirectory(Directory(drive));
    } else {
      _loadDirectory(Directory('/'));
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _toggleSort(SftpSortField field) {
    setState(() {
      if (_sortField == field) {
        _sortAscending = !_sortAscending;
      } else {
        _sortField = field;
        _sortAscending = true;
      }
      _readDirectorySync(_currentDirectory);
    });
  }

  void _selectSingle(FileSystemEntity item) {
    setState(() {
      _selectedPaths.clear();
      _selectedPaths.add(item.path);
      _lastAnchorPath = item.path;
    });
    _notifySelectionChanged();
  }

  void _toggleSelect(FileSystemEntity item) {
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

  void _selectRangeTo(FileSystemEntity target) {
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

  List<FileSystemEntity> _getFilteredItems() {
    if (_searchQuery.trim().isEmpty) return _items;
    final q = _searchQuery.trim().toLowerCase();
    return _items.where((item) {
      final name = item.path.split(Platform.pathSeparator).last.toLowerCase();
      return name.contains(q);
    }).toList();
  }

  void _revealInExplorer(String path) {
    try {
      if (Platform.isWindows) {
        Process.run('explorer.exe', ['/select,', path]);
      } else if (Platform.isMacOS) {
        Process.run('open', ['-R', path]);
      } else if (Platform.isLinux) {
        final target =
            Directory(path).existsSync() ? path : File(path).parent.path;
        Process.run('xdg-open', [target]);
      }
    } catch (_) {}
  }

  Future<void> _createNewDirectory() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const SftpCreateDialog(isDirectory: true),
    );
    if (name != null && name.isNotEmpty) {
      final newDir =
          Directory('${_currentDirectory.path}${Platform.pathSeparator}$name');
      try {
        await newDir.create();
        reload();
      } catch (e) {
        _showError('Create directory failed: $e');
      }
    }
  }

  Future<void> _createNewFile() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const SftpCreateDialog(isDirectory: false),
    );
    if (name != null && name.isNotEmpty) {
      final newFile =
          File('${_currentDirectory.path}${Platform.pathSeparator}$name');
      try {
        await newFile.create();
        reload();
      } catch (e) {
        _showError('Create file failed: $e');
      }
    }
  }

  Future<void> _deleteSelected() async {
    final entities = selectedEntities;
    if (entities.isEmpty) return;

    final isSingle = entities.length == 1;
    final firstName = entities.first.path.split(Platform.pathSeparator).last;
    final isDir =
        isSingle && FileSystemEntity.isDirectorySync(entities.first.path);

    final title = isSingle
        ? (isDir
            ? context.tr('sftp.delete_dir_title',
                defaultText: 'Delete Directory')
            : context.tr('sftp.delete_file_title', defaultText: 'Delete File'))
        : context.tr('sftp.delete_batch_title',
            defaultText: 'Delete {count} items',
            namedArgs: {'count': entities.length.toString()});

    final message = isSingle
        ? context.tr('sftp.delete_confirm_msg',
            defaultText: 'Are you sure you want to delete "{name}"?',
            namedArgs: {'name': firstName})
        : context.tr('sftp.delete_batch_confirm_msg',
            defaultText:
                'Are you sure you want to delete {count} selected files/folders?',
            namedArgs: {'count': entities.length.toString()});

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
      for (final entity in entities) {
        try {
          if (FileSystemEntity.isDirectorySync(entity.path)) {
            await entity.delete(recursive: true);
          } else {
            await entity.delete();
          }
        } catch (e) {
          _showError('Delete failed: $e');
        }
      }
      reload();
    }
  }

  Future<void> _renameSingle(FileSystemEntity item) async {
    final name = item.path.split(Platform.pathSeparator).last;
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => SftpRenameDialog(currentName: name),
    );
    if (newName != null && newName.isNotEmpty && newName != name) {
      final newPath = '${item.parent.path}${Platform.pathSeparator}$newName';
      try {
        await item.rename(newPath);
        reload();
      } catch (e) {
        _showError('Rename failed: $e');
      }
    }
  }

  void _openFileInEditor(FileSystemEntity item) {
    if (FileSystemEntity.isDirectorySync(item.path)) return;
    final file = File(item.path);
    final name = item.path.split(Platform.pathSeparator).last;
    SftpFileEditorDialog.openLocal(
      context,
      localFile: file,
      fileName: name,
    ).then((_) => reload());
  }

  Future<void> _showItemContextMenu(
    BuildContext context,
    FileSystemEntity item,
    Offset globalPosition,
  ) async {
    _itemRightClickHandled = true;
    if (!_selectedPaths.contains(item.path)) {
      _selectSingle(item);
    }

    final selectedCount = _selectedPaths.length;
    final isSingle = selectedCount <= 1;
    final isDir = FileSystemEntity.isDirectorySync(item.path);

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
          value: 'upload',
          height: 36,
          child: Row(
            children: [
              const Icon(Icons.upload_file,
                  size: 16, color: ShellitColors.accentCyan),
              const SizedBox(width: 8),
              Text(
                isSingle
                    ? context.tr('sftp.upload_to_server',
                        defaultText: 'Upload to Server')
                    : context.tr('sftp.upload_selected',
                        defaultText: 'Upload {count} items',
                        namedArgs: {'count': selectedCount.toString()}),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        if (isSingle && !isDir)
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
            value: 'reveal',
            height: 36,
            child: Row(
              children: [
                const Icon(Icons.folder_open,
                    size: 16, color: ShellitColors.accentBlue),
                const SizedBox(width: 8),
                Text(
                    context.tr('sftp.show_in_explorer',
                        defaultText: 'Show in File Explorer'),
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
                    context.tr('sftp.copy_local_path',
                        defaultText: 'Copy Local Path'),
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
      case 'upload':
        widget.onUploadSelected?.call();
        break;
      case 'edit':
        _openFileInEditor(item);
        break;
      case 'reveal':
        _revealInExplorer(item.path);
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
        await _renameSingle(item);
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
                  size: 16, color: ShellitColors.accentBlue),
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
                  size: 16, color: ShellitColors.accentCyan),
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
          _loadDirectory(_currentDirectory);
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
      final item = selectedEntities.first;
      _renameSingle(item);
      return;
    }

    if (event.logicalKey == LogicalKeyboardKey.f5) {
      widget.onUploadSelected?.call();
      return;
    }

    if (event.logicalKey == LogicalKeyboardKey.space &&
        _selectedPaths.length == 1) {
      final item = selectedEntities.first;
      if (!FileSystemEntity.isDirectorySync(item.path)) {
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
      final item = selectedEntities.first;
      if (FileSystemEntity.isDirectorySync(item.path)) {
        _loadDirectory(Directory(item.path));
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
            // Breadcrumbs Navigation Bar
            SftpBreadcrumbsBar(
              currentPath: _currentDirectory.path,
              isRemote: false,
              onNavigate: (path) => _loadDirectory(Directory(path)),
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
                  const Icon(Icons.computer,
                      size: 15, color: ShellitColors.accentBlue),
                  const SizedBox(width: 6),
                  Text(
                    context.tr('sftp.local_title', defaultText: 'Local Files'),
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
                          ? ShellitColors.accentBlue
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
                        _loadDirectory(_currentDirectory);
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
                  const SizedBox(width: 24), // Space for checkbox
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
                              color: ShellitColors.accentBlue,
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
                              color: ShellitColors.accentBlue,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
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
                              color: ShellitColors.accentBlue,
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
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onSecondaryTapDown: (details) =>
                    _showBackgroundContextMenu(context, details.globalPosition),
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
                              color: ShellitColors.textMuted, fontSize: 12),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 60),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final isDir =
                              FileSystemEntity.isDirectorySync(item.path);
                          final name =
                              item.path.split(Platform.pathSeparator).last;
                          final isSelected = _selectedPaths.contains(item.path);

                          int size = 0;
                          DateTime? modified;
                          if (!isDir) {
                            try {
                              final stat = item.statSync();
                              size = stat.size;
                              modified = stat.modified;
                            } catch (_) {}
                          }

                          return Draggable<SftpLocalDragPayload>(
                            data: SftpLocalDragPayload(
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
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: ShellitColors.accentCyan),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isDir
                                          ? Icons.folder
                                          : Icons.insert_drive_file_outlined,
                                      size: 14,
                                      color: ShellitColors.accentCyan,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _selectedPaths.length > 1 && isSelected
                                          ? '${_selectedPaths.length} items'
                                          : name,
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onSecondaryTapDown: (details) =>
                                  _showItemContextMenu(
                                      context, item, details.globalPosition),
                              child: InkWell(
                                onTap: () {
                                  final isCtrlOrCmd = HardwareKeyboard
                                          .instance.isControlPressed ||
                                      HardwareKeyboard.instance.isMetaPressed;
                                  final isShift =
                                      HardwareKeyboard.instance.isShiftPressed;

                                  if (isShift) {
                                    _selectRangeTo(item);
                                  } else if (isCtrlOrCmd) {
                                    _toggleSelect(item);
                                  } else {
                                    _selectSingle(item);
                                  }
                                },
                                onDoubleTap: () {
                                  if (isDir) {
                                    _loadDirectory(Directory(item.path));
                                  } else {
                                    _openFileInEditor(item);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? ShellitColors.accentBlue
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
                                          activeColor: ShellitColors.accentBlue,
                                          side: const BorderSide(
                                            color: ShellitColors.border,
                                            width: 1,
                                          ),
                                          onChanged: (_) => _toggleSelect(item),
                                        ),
                                      ),
                                      const SizedBox(width: 4),

                                      // Icon
                                      Icon(
                                        isDir
                                            ? Icons.folder
                                            : Icons.insert_drive_file_outlined,
                                        size: 15,
                                        color: isDir
                                            ? ShellitColors.accentBlue
                                            : ShellitColors.textSecondary,
                                      ),
                                      const SizedBox(width: 6),

                                      // Name
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isSelected
                                                ? ShellitColors.accentCyan
                                                : ShellitColors.textPrimary,
                                            fontWeight: isDir
                                                ? FontWeight.w500
                                                : FontWeight.normal,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),

                                      // Size
                                      if (!isDir)
                                        SizedBox(
                                          width: 70,
                                          child: Text(
                                            _formatSize(size),
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: ShellitColors.textMuted,
                                              fontFamily: 'JetBrains Mono',
                                            ),
                                          ),
                                        )
                                      else
                                        const SizedBox(width: 70),

                                      const SizedBox(width: 16),

                                      // Date
                                      if (modified != null)
                                        SizedBox(
                                          width: 80,
                                          child: Text(
                                            '${modified.year}-${modified.month.toString().padLeft(2, '0')}-${modified.day.toString().padLeft(2, '0')}',
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: ShellitColors.textMuted,
                                              fontFamily: 'JetBrains Mono',
                                            ),
                                          ),
                                        )
                                      else
                                        const SizedBox(width: 80),
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

            // Batch Action Toolbar (When 1 or more items are selected)
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
                      icon: const Icon(Icons.upload_file,
                          size: 14, color: Colors.white),
                      label: Text(
                        context.tr('sftp.upload', defaultText: 'Upload'),
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ShellitColors.accentBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: widget.onUploadSelected,
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
