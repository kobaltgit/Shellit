import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/shellit_theme.dart';
import 'pane_reload_controller.dart';
import 'sftp_dialogs.dart';

class RemoteFilePane extends StatefulWidget {
  final ISftpSession session;
  final ValueChanged<SftpItem?>? onSelectionChanged;
  final ValueChanged<String>? onPathChanged;
  final VoidCallback? onDownloadSelected;
  final PaneReloadController? reloadController;

  const RemoteFilePane({
    super.key,
    required this.session,
    this.onSelectionChanged,
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
  SftpItem? _selectedItem;
  bool _isLoading = false;
  String? _errorMessage;
  bool _showHiddenFiles = false;
  bool _itemRightClickHandled = false;
  final TextEditingController _pathController =
      TextEditingController(text: '/');

  @override
  void initState() {
    super.initState();
    widget.reloadController?.addListener(reload);
    _loadDirectory(_currentPath);
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
    _pathController.dispose();
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
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });

        setState(() {
          _currentPath = path;
          _pathController.text = path;
          _items = sorted;
          _selectedItem = null;
          _isLoading = false;
        });
        widget.onPathChanged?.call(path);
        widget.onSelectionChanged?.call(null);
      },
      error: (err) {
        setState(() {
          _isLoading = false;
          _errorMessage = err.message;
        });
      },
    );
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

  String _join(String parent, String name) {
    if (parent.endsWith('/')) {
      return '$parent$name';
    }
    return '$parent/$name';
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
    setState(() => _selectedItem = item);
    widget.onSelectionChanged?.call(item);

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
        const PopupMenuItem(
          value: 'download',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.download, size: 16, color: ShellitColors.accentCyan),
              SizedBox(width: 8),
              Text('Download', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'chmod',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.security, size: 16, color: ShellitColors.accentCyan),
              SizedBox(width: 8),
              Text('Permissions (chmod)', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'copy_path',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.copy, size: 16, color: ShellitColors.textSecondary),
              SizedBox(width: 8),
              Text('Copy Remote Path', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        const PopupMenuItem(
          value: 'rename',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.edit_outlined,
                  size: 16, color: ShellitColors.accentBlue),
              SizedBox(width: 8),
              Text('Rename', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.delete_outline,
                  size: 16, color: ShellitColors.statusRed),
              SizedBox(width: 8),
              Text('Delete',
                  style:
                      TextStyle(fontSize: 12, color: ShellitColors.statusRed)),
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
              content: Text('Copied: ${item.path}'),
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
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => SftpDeleteConfirmDialog(
            name: item.name,
            isDirectory: item.isDirectory,
          ),
        );
        if (confirmed == true) {
          final res = item.isDirectory
              ? await widget.session.deleteDirectory(item.path, recursive: true)
              : await widget.session.deleteFile(item.path);
          res.when(
            success: (_) => reload(),
            error: (err) => _showError(err.message),
          );
        }
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
        const PopupMenuItem(
          value: 'new_folder',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.create_new_folder_outlined,
                  size: 16, color: ShellitColors.accentCyan),
              SizedBox(width: 8),
              Text('New Directory', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'new_file',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.note_add_outlined,
                  size: 16, color: ShellitColors.accentBlue),
              SizedBox(width: 8),
              Text('New File', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        const PopupMenuItem(
          value: 'refresh',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.refresh, size: 16, color: ShellitColors.textSecondary),
              SizedBox(width: 8),
              Text('Refresh', style: TextStyle(fontSize: 12)),
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
              SizedBox(width: 8),
              Text(
                _showHiddenFiles ? 'Hide Hidden Files' : 'Show Hidden Files',
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ShellitColors.obsidianBackground,
      child: Column(
        children: [
          // Header / Path bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              color: ShellitColors.obsidianHeader,
              border: Border(
                  bottom: BorderSide(color: ShellitColors.border, width: 1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_outlined,
                    size: 16, color: ShellitColors.accentCyan),
                const SizedBox(width: 8),
                const Text(
                  'Remote',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 16),
                  tooltip: 'Go Up',
                  onPressed: _navigateUp,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 16),
                  tooltip: 'Refresh',
                  onPressed: reload,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: Icon(
                    _showHiddenFiles ? Icons.visibility : Icons.visibility_off,
                    size: 16,
                    color: _showHiddenFiles
                        ? ShellitColors.accentCyan
                        : ShellitColors.textMuted,
                  ),
                  tooltip: _showHiddenFiles
                      ? 'Hide Hidden Files'
                      : 'Show Hidden Files',
                  onPressed: () {
                    setState(() {
                      _showHiddenFiles = !_showHiddenFiles;
                      _loadDirectory(_currentPath);
                    });
                  },
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.create_new_folder_outlined, size: 16),
                  tooltip: 'New Directory',
                  onPressed: _createNewDirectory,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.note_add_outlined, size: 16),
                  tooltip: 'New File',
                  onPressed: _createNewFile,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: SizedBox(
                    height: 28,
                    child: TextField(
                      controller: _pathController,
                      style: const TextStyle(
                          fontSize: 11, fontFamily: 'JetBrains Mono'),
                      decoration: const InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      ),
                      onSubmitted: (newPath) => _loadDirectory(newPath),
                    ),
                  ),
                ),
                if (_selectedItem != null &&
                    widget.onDownloadSelected != null) ...[
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download,
                        size: 14, color: Colors.black),
                    label: const Text(
                      'Download',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ShellitColors.accentCyan,
                      foregroundColor: Colors.black,
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: widget.onDownloadSelected,
                  ),
                ],
              ],
            ),
          ),

          // File List or Loading/Error with Context Menu
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
                        child: _items.isEmpty
                            ? Center(
                                child: Text(
                                  _showHiddenFiles
                                      ? 'Empty folder'
                                      : 'No items (hidden files excluded)',
                                  style: const TextStyle(
                                      color: ShellitColors.textMuted,
                                      fontSize: 12),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 80),
                                itemCount: _items.length,
                                itemBuilder: (context, index) {
                                  final item = _items[index];
                                  final isSelected =
                                      _selectedItem?.path == item.path;

                                  return GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onSecondaryTapDown: (details) =>
                                        _showItemContextMenu(context, item,
                                            details.globalPosition),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() => _selectedItem = item);
                                        widget.onSelectionChanged?.call(item);
                                      },
                                      onDoubleTap: () {
                                        if (item.isDirectory) {
                                          _loadDirectory(item.path);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? ShellitColors.accentCyan
                                                  .withValues(alpha: 0.15)
                                              : Colors.transparent,
                                          border: Border(
                                            bottom: BorderSide(
                                              color: ShellitColors.border
                                                  .withValues(alpha: 0.5),
                                              width: 0.5,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              item.isDirectory
                                                  ? Icons.folder
                                                  : Icons
                                                      .insert_drive_file_outlined,
                                              size: 16,
                                              color: item.isDirectory
                                                  ? ShellitColors.accentCyan
                                                  : ShellitColors.textSecondary,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                item.name,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isSelected
                                                      ? ShellitColors.accentCyan
                                                      : ShellitColors
                                                          .textPrimary,
                                                  fontWeight: item.isDirectory
                                                      ? FontWeight.w500
                                                      : FontWeight.normal,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (!item.isDirectory)
                                              Text(
                                                _formatSize(item.sizeBytes),
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color:
                                                      ShellitColors.textMuted,
                                                  fontFamily: 'JetBrains Mono',
                                                ),
                                              ),
                                            const SizedBox(width: 12),
                                            Text(
                                              _formatPermissions(
                                                  item.permissions),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: ShellitColors.textMuted,
                                                fontFamily: 'JetBrains Mono',
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              '${item.modifiedAt.year}-${item.modifiedAt.month.toString().padLeft(2, '0')}-${item.modifiedAt.day.toString().padLeft(2, '0')}',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: ShellitColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}
