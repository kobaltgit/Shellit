import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/shellit_theme.dart';
import 'sftp_dialogs.dart';

class LocalFilePane extends StatefulWidget {
  final ValueChanged<FileSystemEntity?>? onSelectionChanged;
  final ValueChanged<String>? onPathChanged;
  final VoidCallback? onUploadSelected;

  const LocalFilePane({
    super.key,
    this.onSelectionChanged,
    this.onPathChanged,
    this.onUploadSelected,
  });

  @override
  State<LocalFilePane> createState() => LocalFilePaneState();
}

class LocalFilePaneState extends State<LocalFilePane> {
  late Directory _currentDirectory;
  List<FileSystemEntity> _items = [];
  FileSystemEntity? _selectedEntity;
  final TextEditingController _pathController = TextEditingController();
  bool _showHiddenFiles = false;
  bool _itemRightClickHandled = false;

  @override
  void initState() {
    super.initState();
    _currentDirectory = Directory.current;
    _pathController.text = _currentDirectory.path;
    _loadDirectory(_currentDirectory);
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  /// Public reload method for real-time updates.
  void reload() {
    _loadDirectory(_currentDirectory);
  }

  void _loadDirectory(Directory dir) {
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
        return a.path.toLowerCase().compareTo(b.path.toLowerCase());
      });

      setState(() {
        _currentDirectory = dir;
        _items = list;
        _selectedEntity = null;
        _pathController.text = dir.path;
      });
      widget.onPathChanged?.call(dir.path);
      widget.onSelectionChanged?.call(null);
    } catch (e) {
      _showError('Failed to read directory: $e');
    }
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

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
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

  Future<void> _showItemContextMenu(
    BuildContext context,
    FileSystemEntity item,
    Offset globalPosition,
  ) async {
    _itemRightClickHandled = true;
    setState(() => _selectedEntity = item);
    widget.onSelectionChanged?.call(item);

    final isDir = FileSystemEntity.isDirectorySync(item.path);
    final name = item.path.split(Platform.pathSeparator).last;
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
          value: 'upload',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.upload_file,
                  size: 16, color: ShellitColors.accentBlue),
              SizedBox(width: 8),
              Text('Upload to Server', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'reveal',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.folder_open,
                  size: 16, color: ShellitColors.accentCyan),
              SizedBox(width: 8),
              Text('Show in File Explorer', style: TextStyle(fontSize: 12)),
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
              Text('Copy Local Path', style: TextStyle(fontSize: 12)),
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
      case 'upload':
        widget.onUploadSelected?.call();
        break;
      case 'reveal':
        _revealInExplorer(item.path);
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
          builder: (_) => SftpRenameDialog(currentName: name),
        );
        if (newName != null && newName.isNotEmpty && newName != name) {
          final newPath =
              '${item.parent.path}${Platform.pathSeparator}$newName';
          try {
            await item.rename(newPath);
            reload();
          } catch (e) {
            _showError('Rename failed: $e');
          }
        }
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) =>
              SftpDeleteConfirmDialog(name: name, isDirectory: isDir),
        );
        if (confirmed == true) {
          try {
            await item.delete(recursive: isDir);
            reload();
          } catch (e) {
            _showError('Delete failed: $e');
          }
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
                  size: 16, color: ShellitColors.accentBlue),
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
                  size: 16, color: ShellitColors.accentCyan),
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
          _loadDirectory(_currentDirectory);
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ShellitColors.obsidianBackground,
        border:
            Border(right: BorderSide(color: ShellitColors.border, width: 1)),
      ),
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
                const Icon(Icons.computer,
                    size: 16, color: ShellitColors.accentBlue),
                const SizedBox(width: 8),
                const Text(
                  'Local',
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
                  icon: const Icon(Icons.home_outlined, size: 16),
                  tooltip: 'Home Folder',
                  onPressed: _navigateToHome,
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
                        ? ShellitColors.accentBlue
                        : ShellitColors.textMuted,
                  ),
                  tooltip: _showHiddenFiles
                      ? 'Hide Hidden Files'
                      : 'Show Hidden Files',
                  onPressed: () {
                    setState(() {
                      _showHiddenFiles = !_showHiddenFiles;
                      _loadDirectory(_currentDirectory);
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
                      onSubmitted: (newPath) {
                        final dir = Directory(newPath);
                        if (dir.existsSync()) {
                          _loadDirectory(dir);
                        }
                      },
                    ),
                  ),
                ),
                if (_selectedEntity != null &&
                    widget.onUploadSelected != null) ...[
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file,
                        size: 14, color: Colors.white),
                    label: const Text(
                      'Upload',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ShellitColors.accentBlue,
                      foregroundColor: Colors.white,
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: widget.onUploadSelected,
                  ),
                ],
              ],
            ),
          ),

          // File List with Context Menu
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onSecondaryTapDown: (details) =>
                  _showBackgroundContextMenu(context, details.globalPosition),
              child: _items.isEmpty
                  ? Center(
                      child: Text(
                        _showHiddenFiles
                            ? 'Empty folder'
                            : 'No items (hidden files excluded)',
                        style: const TextStyle(
                            color: ShellitColors.textMuted, fontSize: 12),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final isDir =
                            FileSystemEntity.isDirectorySync(item.path);
                        final name =
                            item.path.split(Platform.pathSeparator).last;
                        final isSelected = _selectedEntity?.path == item.path;

                        int size = 0;
                        DateTime? modified;
                        if (!isDir) {
                          try {
                            final stat = item.statSync();
                            size = stat.size;
                            modified = stat.modified;
                          } catch (_) {}
                        }

                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onSecondaryTapDown: (details) => _showItemContextMenu(
                              context, item, details.globalPosition),
                          child: InkWell(
                            onTap: () {
                              setState(() => _selectedEntity = item);
                              widget.onSelectionChanged?.call(item);
                            },
                            onDoubleTap: () {
                              if (isDir) {
                                _loadDirectory(Directory(item.path));
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? ShellitColors.accentBlue
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
                                    isDir
                                        ? Icons.folder
                                        : Icons.insert_drive_file_outlined,
                                    size: 16,
                                    color: isDir
                                        ? ShellitColors.accentBlue
                                        : ShellitColors.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isSelected
                                            ? ShellitColors.accentBlue
                                            : ShellitColors.textPrimary,
                                        fontWeight: isDir
                                            ? FontWeight.w500
                                            : FontWeight.normal,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (!isDir)
                                    Text(
                                      _formatSize(size),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: ShellitColors.textMuted,
                                        fontFamily: 'JetBrains Mono',
                                      ),
                                    ),
                                  const SizedBox(width: 12),
                                  if (modified != null)
                                    Text(
                                      '${modified.year}-${modified.month.toString().padLeft(2, '0')}-${modified.day.toString().padLeft(2, '0')}',
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
