import 'package:flutter/material.dart';
import '../../theme/shellit_theme.dart';

/// Interactive dialog to edit POSIX file permissions (chmod).
class SftpChmodDialog extends StatefulWidget {
  final String fileName;
  final int initialPermissions;

  const SftpChmodDialog({
    super.key,
    required this.fileName,
    required this.initialPermissions,
  });

  @override
  State<SftpChmodDialog> createState() => _SftpChmodDialogState();
}

class _SftpChmodDialogState extends State<SftpChmodDialog> {
  late bool _uRead, _uWrite, _uExec;
  late bool _gRead, _gWrite, _gExec;
  late bool _oRead, _oWrite, _oExec;
  late TextEditingController _octalController;

  @override
  void initState() {
    super.initState();
    final p = widget.initialPermissions;
    _uRead = (p & 0x100) != 0; // 0400
    _uWrite = (p & 0x080) != 0; // 0200
    _uExec = (p & 0x040) != 0; // 0100

    _gRead = (p & 0x020) != 0; // 0040
    _gWrite = (p & 0x010) != 0; // 0020
    _gExec = (p & 0x008) != 0; // 0010

    _oRead = (p & 0x004) != 0; // 0004
    _oWrite = (p & 0x002) != 0; // 0002
    _oExec = (p & 0x001) != 0; // 0001

    _octalController = TextEditingController(text: _calculateOctalString());
  }

  @override
  void dispose() {
    _octalController.dispose();
    super.dispose();
  }

  int _calculateMode() {
    var mode = 0;
    if (_uRead) mode |= 0x100;
    if (_uWrite) mode |= 0x080;
    if (_uExec) mode |= 0x040;

    if (_gRead) mode |= 0x020;
    if (_gWrite) mode |= 0x010;
    if (_gExec) mode |= 0x008;

    if (_oRead) mode |= 0x004;
    if (_oWrite) mode |= 0x002;
    if (_oExec) mode |= 0x001;
    return mode;
  }

  String _calculateOctalString() {
    final mode = _calculateMode();
    return '0${mode.toRadixString(8).padLeft(3, '0')}';
  }

  void _onCheckboxChanged() {
    setState(() {
      _octalController.text = _calculateOctalString();
    });
  }

  void _onOctalChanged(String val) {
    var clean = val.trim();
    if (clean.startsWith('0') && clean.length > 3) {
      clean = clean.substring(1);
    }
    final parsed = int.tryParse(clean, radix: 8);
    if (parsed != null) {
      setState(() {
        _uRead = (parsed & 0x100) != 0;
        _uWrite = (parsed & 0x080) != 0;
        _uExec = (parsed & 0x040) != 0;

        _gRead = (parsed & 0x020) != 0;
        _gWrite = (parsed & 0x010) != 0;
        _gExec = (parsed & 0x008) != 0;

        _oRead = (parsed & 0x004) != 0;
        _oWrite = (parsed & 0x002) != 0;
        _oExec = (parsed & 0x001) != 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ShellitColors.obsidianCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: ShellitColors.border),
      ),
      title: Row(
        children: [
          const Icon(Icons.security, size: 20, color: ShellitColors.accentCyan),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Permissions: ${widget.fileName}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1.2),
                2: FlexColumnWidth(1.2),
                3: FlexColumnWidth(1.2),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                const TableRow(
                  children: [
                    Text('', style: TextStyle(fontSize: 12)),
                    Center(
                        child: Text('Read (r)',
                            style: TextStyle(
                                fontSize: 11,
                                color: ShellitColors.textSecondary))),
                    Center(
                        child: Text('Write (w)',
                            style: TextStyle(
                                fontSize: 11,
                                color: ShellitColors.textSecondary))),
                    Center(
                        child: Text('Exec (x)',
                            style: TextStyle(
                                fontSize: 11,
                                color: ShellitColors.textSecondary))),
                  ],
                ),
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text('Owner',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    Center(
                      child: Checkbox(
                        value: _uRead,
                        activeColor: ShellitColors.accentCyan,
                        onChanged: (v) {
                          _uRead = v ?? false;
                          _onCheckboxChanged();
                        },
                      ),
                    ),
                    Center(
                      child: Checkbox(
                        value: _uWrite,
                        activeColor: ShellitColors.accentCyan,
                        onChanged: (v) {
                          _uWrite = v ?? false;
                          _onCheckboxChanged();
                        },
                      ),
                    ),
                    Center(
                      child: Checkbox(
                        value: _uExec,
                        activeColor: ShellitColors.accentCyan,
                        onChanged: (v) {
                          _uExec = v ?? false;
                          _onCheckboxChanged();
                        },
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text('Group',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    Center(
                      child: Checkbox(
                        value: _gRead,
                        activeColor: ShellitColors.accentCyan,
                        onChanged: (v) {
                          _gRead = v ?? false;
                          _onCheckboxChanged();
                        },
                      ),
                    ),
                    Center(
                      child: Checkbox(
                        value: _gWrite,
                        activeColor: ShellitColors.accentCyan,
                        onChanged: (v) {
                          _gWrite = v ?? false;
                          _onCheckboxChanged();
                        },
                      ),
                    ),
                    Center(
                      child: Checkbox(
                        value: _gExec,
                        activeColor: ShellitColors.accentCyan,
                        onChanged: (v) {
                          _gExec = v ?? false;
                          _onCheckboxChanged();
                        },
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text('Others',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    Center(
                      child: Checkbox(
                        value: _oRead,
                        activeColor: ShellitColors.accentCyan,
                        onChanged: (v) {
                          _oRead = v ?? false;
                          _onCheckboxChanged();
                        },
                      ),
                    ),
                    Center(
                      child: Checkbox(
                        value: _oWrite,
                        activeColor: ShellitColors.accentCyan,
                        onChanged: (v) {
                          _oWrite = v ?? false;
                          _onCheckboxChanged();
                        },
                      ),
                    ),
                    Center(
                      child: Checkbox(
                        value: _oExec,
                        activeColor: ShellitColors.accentCyan,
                        onChanged: (v) {
                          _oExec = v ?? false;
                          _onCheckboxChanged();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Octal notation: ',
                    style: TextStyle(
                        fontSize: 12, color: ShellitColors.textSecondary)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  height: 32,
                  child: TextField(
                    controller: _octalController,
                    style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'JetBrains Mono',
                        fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    onChanged: _onOctalChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ShellitColors.accentCyan,
            foregroundColor: Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(_calculateMode()),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

/// Dialog for renaming an entity.
class SftpRenameDialog extends StatefulWidget {
  final String currentName;

  const SftpRenameDialog({super.key, required this.currentName});

  @override
  State<SftpRenameDialog> createState() => _SftpRenameDialogState();
}

class _SftpRenameDialogState extends State<SftpRenameDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ShellitColors.obsidianCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: ShellitColors.border),
      ),
      title: const Row(
        children: [
          Icon(Icons.edit_outlined, size: 18, color: ShellitColors.accentBlue),
          SizedBox(width: 8),
          Text('Rename',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: TextField(
          controller: _controller,
          autofocus: true,
          style: const TextStyle(fontSize: 13, fontFamily: 'JetBrains Mono'),
          decoration: const InputDecoration(
            labelText: 'New name',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onSubmitted: (val) {
            final trimmed = val.trim();
            if (trimmed.isNotEmpty) {
              Navigator.of(context).pop(trimmed);
            }
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ShellitColors.accentBlue,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            final trimmed = _controller.text.trim();
            if (trimmed.isNotEmpty) {
              Navigator.of(context).pop(trimmed);
            }
          },
          child: const Text('Rename'),
        ),
      ],
    );
  }
}

/// Dialog for creating a new file or directory.
class SftpCreateDialog extends StatefulWidget {
  final bool isDirectory;

  const SftpCreateDialog({super.key, required this.isDirectory});

  @override
  State<SftpCreateDialog> createState() => _SftpCreateDialogState();
}

class _SftpCreateDialogState extends State<SftpCreateDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isDirectory ? 'New Directory' : 'New File';
    final label = widget.isDirectory ? 'Directory name' : 'File name';
    final icon = widget.isDirectory
        ? Icons.create_new_folder_outlined
        : Icons.note_add_outlined;

    return AlertDialog(
      backgroundColor: ShellitColors.obsidianCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: ShellitColors.border),
      ),
      title: Row(
        children: [
          Icon(icon, size: 20, color: ShellitColors.accentBlue),
          const SizedBox(width: 8),
          Text(title,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: TextField(
          controller: _controller,
          autofocus: true,
          style: const TextStyle(fontSize: 13, fontFamily: 'JetBrains Mono'),
          decoration: InputDecoration(
            labelText: label,
            hintText: widget.isDirectory ? 'folder_name' : 'filename.txt',
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onSubmitted: (val) {
            final trimmed = val.trim();
            if (trimmed.isNotEmpty) {
              Navigator.of(context).pop(trimmed);
            }
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ShellitColors.accentBlue,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            final trimmed = _controller.text.trim();
            if (trimmed.isNotEmpty) {
              Navigator.of(context).pop(trimmed);
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

/// Confirmation dialog for deleting a file or directory.
class SftpDeleteConfirmDialog extends StatelessWidget {
  final String name;
  final bool isDirectory;

  const SftpDeleteConfirmDialog({
    super.key,
    required this.name,
    required this.isDirectory,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ShellitColors.obsidianCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: ShellitColors.border),
      ),
      title: Row(
        children: [
          const Icon(Icons.delete_forever,
              size: 20, color: ShellitColors.statusRed),
          const SizedBox(width: 8),
          Text(
            isDirectory ? 'Delete Directory' : 'Delete File',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to delete "$name"?',
            style: const TextStyle(fontSize: 13),
          ),
          if (isDirectory) ...[
            const SizedBox(height: 8),
            const Text(
              'This will recursively delete the directory and all of its contents. This action cannot be undone.',
              style: TextStyle(fontSize: 12, color: ShellitColors.statusRed),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ShellitColors.statusRed,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
