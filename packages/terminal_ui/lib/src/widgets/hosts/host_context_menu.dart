import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../localization/localization_scope.dart';
import '../../theme/shellit_theme.dart';

class HostContextMenu {
  const HostContextMenu._();

  static Future<void> show({
    required BuildContext context,
    required Offset globalPosition,
    required HostEntity host,
    required List<FolderEntity> folders,
    VoidCallback? onConnect,
    VoidCallback? onOpenSftp,
    VoidCallback? onConnectInSplit,
    VoidCallback? onEdit,
    VoidCallback? onDuplicate,
    ValueChanged<String?>? onMoveToFolder,
    VoidCallback? onDelete,
  }) async {
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        globalPosition.dx + 1,
        globalPosition.dy + 1,
      ),
      color: ShellitColors.obsidianCard,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: ShellitColors.border, width: 1),
      ),
      items: [
        // Quick Connect
        PopupMenuItem<String>(
          value: 'quick_connect',
          height: 38,
          child: _buildItem(
            icon: Icons.bolt_rounded,
            iconColor: ShellitColors.accentBlue,
            title: context.tr(
              'hosts.context_menu.quick_connect',
              defaultText: 'Quick Connect',
            ),
            shortcut: '↵',
          ),
        ),

        // Connect > (Terminal, SFTP, Split)
        PopupMenuItem<String>(
          value: 'connect_submenu',
          height: 38,
          child: _buildItem(
            icon: Icons.terminal_rounded,
            title: context.tr(
              'hosts.context_menu.connect',
              defaultText: 'Connect',
            ),
            hasSubmenu: true,
          ),
        ),

        const PopupMenuDivider(height: 8),

        // Edit Host Details
        PopupMenuItem<String>(
          value: 'edit',
          height: 38,
          child: _buildItem(
            icon: Icons.edit_outlined,
            title: context.tr(
              'hosts.context_menu.edit_details',
              defaultText: 'Edit Host Details',
            ),
            shortcut: 'E',
          ),
        ),

        // Move to Folder >
        PopupMenuItem<String>(
          value: 'move_to_folder',
          height: 38,
          child: _buildItem(
            icon: Icons.drive_file_move_outlined,
            title: context.tr(
              'hosts.context_menu.move_to_folder',
              defaultText: 'Move to Folder',
            ),
            hasSubmenu: true,
          ),
        ),

        // Duplicate
        PopupMenuItem<String>(
          value: 'duplicate',
          height: 38,
          child: _buildItem(
            icon: Icons.copy_rounded,
            title: context.tr(
              'hosts.context_menu.duplicate',
              defaultText: 'Duplicate',
            ),
          ),
        ),

        // Copy >
        PopupMenuItem<String>(
          value: 'copy_submenu',
          height: 38,
          child: _buildItem(
            icon: Icons.content_copy_rounded,
            title: context.tr(
              'hosts.context_menu.copy',
              defaultText: 'Copy',
            ),
            hasSubmenu: true,
          ),
        ),

        const PopupMenuDivider(height: 8),

        // Remove
        PopupMenuItem<String>(
          value: 'remove',
          height: 38,
          child: _buildItem(
            icon: Icons.delete_outline_rounded,
            iconColor: ShellitColors.statusRed,
            textColor: ShellitColors.statusRed,
            title: context.tr(
              'hosts.context_menu.remove',
              defaultText: 'Remove',
            ),
          ),
        ),
      ],
    );

    if (result == null || !context.mounted) return;

    switch (result) {
      case 'quick_connect':
        onConnect?.call();
        break;

      case 'connect_submenu':
        await _showConnectSubmenu(
          context: context,
          position: globalPosition,
          onConnect: onConnect,
          onOpenSftp: onOpenSftp,
          onConnectInSplit: onConnectInSplit,
        );
        break;

      case 'edit':
        onEdit?.call();
        break;

      case 'move_to_folder':
        await _showMoveToFolderSubmenu(
          context: context,
          position: globalPosition,
          currentFolderId: host.folderId,
          folders: folders,
          onSelectFolder: (folderId) => onMoveToFolder?.call(folderId),
        );
        break;

      case 'duplicate':
        onDuplicate?.call();
        break;

      case 'copy_submenu':
        await _showCopySubmenu(
          context: context,
          position: globalPosition,
          host: host,
        );
        break;

      case 'remove':
        onDelete?.call();
        break;
    }
  }

  static Future<void> _showConnectSubmenu({
    required BuildContext context,
    required Offset position,
    VoidCallback? onConnect,
    VoidCallback? onOpenSftp,
    VoidCallback? onConnectInSplit,
  }) async {
    final res = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx + 40,
        position.dy,
        position.dx + 41,
        position.dy + 1,
      ),
      color: ShellitColors.obsidianCard,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: ShellitColors.border, width: 1),
      ),
      items: [
        PopupMenuItem<String>(
          value: 'terminal',
          height: 36,
          child: _buildItem(
            icon: Icons.terminal_rounded,
            title: context.tr(
              'hosts.context_menu.ssh_terminal',
              defaultText: 'SSH Terminal',
            ),
            iconColor: ShellitColors.accentBlue,
          ),
        ),
        PopupMenuItem<String>(
          value: 'sftp',
          height: 36,
          child: _buildItem(
            icon: Icons.folder_shared_outlined,
            title: context.tr(
              'hosts.context_menu.sftp_explorer',
              defaultText: 'SFTP Explorer',
            ),
            iconColor: ShellitColors.accentCyan,
          ),
        ),
        if (onConnectInSplit != null)
          PopupMenuItem<String>(
            value: 'split',
            height: 36,
            child: _buildItem(
              icon: Icons.vertical_split_rounded,
              title: context.tr(
                'hosts.context_menu.open_split',
                defaultText: 'Open in New Split',
              ),
              iconColor: ShellitColors.accentPurple,
            ),
          ),
      ],
    );

    if (res == null || !context.mounted) return;
    if (res == 'terminal') onConnect?.call();
    if (res == 'sftp') onOpenSftp?.call();
    if (res == 'split') onConnectInSplit?.call();
  }

  static Future<void> _showMoveToFolderSubmenu({
    required BuildContext context,
    required Offset position,
    required String? currentFolderId,
    required List<FolderEntity> folders,
    required ValueChanged<String?> onSelectFolder,
  }) async {
    final items = <PopupMenuEntry<String?>>[
      PopupMenuItem<String?>(
        value: null,
        height: 36,
        child: Row(
          children: [
            Icon(
              currentFolderId == null
                  ? Icons.check_circle_rounded
                  : Icons.folder_off_outlined,
              size: 16,
              color: currentFolderId == null
                  ? ShellitColors.accentBlue
                  : ShellitColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              context.tr(
                'hosts.context_menu.root_folder',
                defaultText: 'None (Root)',
              ),
              style: const TextStyle(
                fontSize: 12,
                color: ShellitColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      if (folders.isNotEmpty) const PopupMenuDivider(height: 8),
      for (final f in folders)
        PopupMenuItem<String?>(
          value: f.id,
          height: 36,
          child: Row(
            children: [
              Icon(
                currentFolderId == f.id
                    ? Icons.check_circle_rounded
                    : Icons.folder_outlined,
                size: 16,
                color: currentFolderId == f.id
                    ? ShellitColors.accentBlue
                    : ShellitColors.accentBlue.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  f.name,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ShellitColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
    ];

    final selected = await showMenu<String?>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx + 40,
        position.dy,
        position.dx + 41,
        position.dy + 1,
      ),
      color: ShellitColors.obsidianCard,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: ShellitColors.border, width: 1),
      ),
      items: items,
    );

    // If user clicked outside, selected is not triggered
    if (selected != null || currentFolderId != null) {
      onSelectFolder(selected);
    }
  }

  static Future<void> _showCopySubmenu({
    required BuildContext context,
    required Offset position,
    required HostEntity host,
  }) async {
    final portPart = host.port != 22 ? ' -p ${host.port}' : '';
    final sshCommand = 'ssh ${host.username}@${host.hostname}$portPart';
    final userAtHost = '${host.username}@${host.hostname}';

    final res = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx + 40,
        position.dy,
        position.dx + 41,
        position.dy + 1,
      ),
      color: ShellitColors.obsidianCard,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: ShellitColors.border, width: 1),
      ),
      items: [
        PopupMenuItem<String>(
          value: 'ssh_cmd',
          height: 36,
          child: _buildItem(
            icon: Icons.terminal,
            title: context.tr(
              'hosts.context_menu.copy_ssh_cmd',
              defaultText: 'SSH Command',
            ),
            shortcut: sshCommand.length > 20
                ? '${sshCommand.substring(0, 20)}...'
                : sshCommand,
          ),
        ),
        PopupMenuItem<String>(
          value: 'hostname',
          height: 36,
          child: _buildItem(
            icon: Icons.dns_outlined,
            title: context.tr(
              'hosts.context_menu.copy_host_ip',
              defaultText: 'Host / IP',
            ),
            shortcut: host.hostname,
          ),
        ),
        PopupMenuItem<String>(
          value: 'user_host',
          height: 36,
          child: _buildItem(
            icon: Icons.person_outline,
            title: context.tr(
              'hosts.context_menu.copy_user_host',
              defaultText: 'user@host',
            ),
            shortcut: userAtHost,
          ),
        ),
      ],
    );

    if (res == null || !context.mounted) return;

    String toCopy = '';
    String label = '';
    switch (res) {
      case 'ssh_cmd':
        toCopy = sshCommand;
        label = context.tr(
          'hosts.context_menu.copy_ssh_cmd',
          defaultText: 'SSH Command',
        );
        break;
      case 'hostname':
        toCopy = host.hostname;
        label = context.tr(
          'hosts.context_menu.copy_host_ip',
          defaultText: 'Host / IP',
        );
        break;
      case 'user_host':
        toCopy = userAtHost;
        label = context.tr(
          'hosts.context_menu.copy_user_host',
          defaultText: 'user@host',
        );
        break;
    }

    if (toCopy.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: toCopy));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context
                  .tr(
                    'hosts.context_menu.copied_snackbar',
                    defaultText: '{label} copied to clipboard',
                  )
                  .replaceAll('{label}', label),
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            backgroundColor: ShellitColors.obsidianCard,
          ),
        );
      }
    }
  }

  static Widget _buildItem({
    required IconData icon,
    required String title,
    Color? iconColor,
    Color? textColor,
    String? shortcut,
    bool hasSubmenu = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: iconColor ?? ShellitColors.textSecondary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: textColor ?? ShellitColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (shortcut != null) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: ShellitColors.obsidianSidebar,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: ShellitColors.borderLight),
            ),
            child: Text(
              shortcut,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: ShellitColors.accentCyan,
              ),
            ),
          ),
        ],
        if (hasSubmenu) ...[
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: ShellitColors.textMuted,
          ),
        ],
      ],
    );
  }
}
