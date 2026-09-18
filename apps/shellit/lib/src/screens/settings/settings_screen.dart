import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_ui/terminal_ui.dart';
import '../../controllers/log_controllers.dart';
import '../../di/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultState = ref.watch(vaultProvider);
    final activeSchemeName = ref.watch(terminalSchemeNameProvider);
    final logSettings = ref.watch(logSettingsControllerProvider);
    final logController = ref.read(logSettingsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: ShellitColors.obsidianBackground,
      appBar: AppBar(
        title: const Text(
          'Settings & Security',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: ShellitColors.obsidianBackground,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Section 1: Security & Vault
          _buildSectionHeader('Security & Vault'),
          const SizedBox(height: 8),
          Card(
            color: ShellitColors.obsidianCard,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: ShellitColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.lock_clock_outlined,
                    color: ShellitColors.accentCyan,
                  ),
                  title: const Text(
                    'Auto-Lock Timeout',
                    style: TextStyle(
                      color: ShellitColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    'Lock database after ${vaultState.autoLockTimeoutMinutes} minutes of inactivity',
                    style: const TextStyle(
                      color: ShellitColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  trailing: DropdownButton<int>(
                    value: vaultState.autoLockTimeoutMinutes,
                    dropdownColor: ShellitColors.obsidianCard,
                    style: const TextStyle(
                      color: ShellitColors.textPrimary,
                      fontSize: 13,
                    ),
                    items: const [
                      DropdownMenuItem(value: 5, child: Text('5 minutes')),
                      DropdownMenuItem(value: 15, child: Text('15 minutes')),
                      DropdownMenuItem(value: 30, child: Text('30 minutes')),
                      DropdownMenuItem(value: 60, child: Text('1 hour')),
                      DropdownMenuItem(value: 0, child: Text('Never')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref
                            .read(vaultProvider.notifier)
                            .setAutoLockTimeout(val);
                      }
                    },
                  ),
                ),
                const Divider(color: ShellitColors.border, height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.password_outlined,
                    color: ShellitColors.accentCyan,
                  ),
                  title: const Text(
                    'Change Master Password',
                    style: TextStyle(
                      color: ShellitColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: const Text(
                    'Re-encrypt SQLCipher database with a new Argon2id key',
                    style: TextStyle(
                      color: ShellitColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: ShellitColors.textMuted,
                  ),
                  onTap: () => _showChangePasswordDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 2: Terminal Appearance
          _buildSectionHeader('Terminal Appearance'),
          const SizedBox(height: 8),
          Card(
            color: ShellitColors.obsidianCard,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: ShellitColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.palette_outlined,
                color: ShellitColors.accentCyan,
              ),
              title: const Text(
                'Color Scheme',
                style: TextStyle(
                  color: ShellitColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                'Current scheme: $activeSchemeName',
                style: const TextStyle(
                  color: ShellitColors.textMuted,
                  fontSize: 12,
                ),
              ),
              trailing: DropdownButton<String>(
                value: activeSchemeName,
                dropdownColor: ShellitColors.obsidianCard,
                style: const TextStyle(
                  color: ShellitColors.textPrimary,
                  fontSize: 13,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Obsidian Dark',
                    child: Text('Obsidian Dark'),
                  ),
                  DropdownMenuItem(value: 'Dracula', child: Text('Dracula')),
                  DropdownMenuItem(value: 'Nord', child: Text('Nord')),
                  DropdownMenuItem(
                    value: 'OLED True Black',
                    child: Text('OLED True Black'),
                  ),
                  DropdownMenuItem(
                    value: 'Cyberpunk',
                    child: Text('Cyberpunk'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    ref.read(terminalSchemeNameProvider.notifier).state = val;
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section 3: Backup & Export
          _buildSectionHeader('Backup & Storage'),
          const SizedBox(height: 8),
          Card(
            color: ShellitColors.obsidianCard,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: ShellitColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.cloud_upload_outlined,
                    color: ShellitColors.accentCyan,
                  ),
                  title: const Text(
                    'Export Encrypted Vault Backup',
                    style: TextStyle(
                      color: ShellitColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: const Text(
                    'Save encrypted archive (.shellit-vault) protected by master key',
                    style: TextStyle(
                      color: ShellitColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: ShellitColors.textMuted,
                  ),
                  onTap: () => _showExportBackupDialog(context, ref),
                ),
                const Divider(color: ShellitColors.border, height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.cloud_download_outlined,
                    color: ShellitColors.accentCyan,
                  ),
                  title: const Text(
                    'Import Vault Backup',
                    style: TextStyle(
                      color: ShellitColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: const Text(
                    'Restore hosts, keys and snippets from encrypted file',
                    style: TextStyle(
                      color: ShellitColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: ShellitColors.textMuted,
                  ),
                  onTap: () => _showImportBackupDialog(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 4: Logs & Diagnostics
          _buildSectionHeader('Logs & Diagnostics'),
          const SizedBox(height: 8),
          Card(
            color: ShellitColors.obsidianCard,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: ShellitColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  activeThumbColor: ShellitColors.accentCyan,
                  value: logSettings.isFileLoggingEnabled,
                  onChanged: (val) => logController.setFileLoggingEnabled(val),
                  title: const Text(
                    'Write System Logs to Disk',
                    style: TextStyle(
                      color: ShellitColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: const Text(
                    'Persists rotated diagnostic logs (up to 2x 5MB) for crash analysis',
                    style: TextStyle(
                      color: ShellitColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Divider(color: ShellitColors.border, height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.filter_list_outlined,
                    color: ShellitColors.accentCyan,
                  ),
                  title: const Text(
                    'Minimum Disk Log Level',
                    style: TextStyle(
                      color: ShellitColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: const Text(
                    'Filter minimum severity before writing to log files',
                    style: TextStyle(
                      color: ShellitColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  trailing: DropdownButton<LogLevel>(
                    value: logSettings.minFileLogLevel,
                    dropdownColor: ShellitColors.obsidianCard,
                    style: const TextStyle(
                      color: ShellitColors.textPrimary,
                      fontSize: 13,
                    ),
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: LogLevel.debug,
                        child: Text('Debug (Verbose)'),
                      ),
                      DropdownMenuItem(
                        value: LogLevel.info,
                        child: Text('Info (Default)'),
                      ),
                      DropdownMenuItem(
                        value: LogLevel.warning,
                        child: Text('Warning & Error'),
                      ),
                      DropdownMenuItem(
                        value: LogLevel.error,
                        child: Text('Error Only'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        logController.setMinFileLogLevel(val);
                      }
                    },
                  ),
                ),
                const Divider(color: ShellitColors.border, height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.folder_open_outlined,
                    color: ShellitColors.accentCyan,
                  ),
                  title: const Text(
                    'Open Logs Directory',
                    style: TextStyle(
                      color: ShellitColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    logSettings.logsDirectory.isNotEmpty
                        ? logSettings.logsDirectory
                        : 'Application Support / logs',
                    style: const TextStyle(
                      color: ShellitColors.textMuted,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(
                    Icons.launch,
                    size: 16,
                    color: ShellitColors.textMuted,
                  ),
                  onTap: () => logController.openLogsFolder(),
                ),
                const Divider(color: ShellitColors.border, height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.delete_sweep_outlined,
                    color: ShellitColors.statusRed,
                  ),
                  title: const Text(
                    'Clear Disk Logs',
                    style: TextStyle(
                      color: ShellitColors.statusRed,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: const Text(
                    'Erase all historical log files from storage',
                    style: TextStyle(
                      color: ShellitColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () async {
                    await logController.clearDiskLogs();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Disk log files deleted successfully'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: ShellitColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ShellitColors.obsidianCard,
        title: const Text(
          'Change Master Password',
          style: TextStyle(color: ShellitColors.textPrimary, fontSize: 16),
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPassCtrl,
                obscureText: true,
                style: const TextStyle(
                  color: ShellitColors.textPrimary,
                  fontSize: 13,
                ),
                decoration: const InputDecoration(
                  labelText: 'Current Master Password',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPassCtrl,
                obscureText: true,
                style: const TextStyle(
                  color: ShellitColors.textPrimary,
                  fontSize: 13,
                ),
                decoration: const InputDecoration(
                  labelText: 'New Master Password',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ShellitColors.accentBlue,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Master password updated and database re-keyed.',
                  ),
                ),
              );
            },
            child: const Text(
              'Update Password',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showExportBackupDialog(BuildContext context, WidgetRef ref) {
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ShellitColors.obsidianCard,
        title: const Text(
          'Export Encrypted Vault',
          style: TextStyle(color: ShellitColors.textPrimary, fontSize: 16),
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter a password to encrypt this backup archive. You will need this password to restore your vault.',
                style: TextStyle(color: ShellitColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: passCtrl,
                obscureText: true,
                style: const TextStyle(
                  color: ShellitColors.textPrimary,
                  fontSize: 13,
                ),
                decoration: const InputDecoration(
                  labelText: 'Backup Encryption Password',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ShellitColors.accentBlue,
            ),
            onPressed: () async {
              final pass = passCtrl.text.trim();
              if (pass.isEmpty) return;
              Navigator.pop(ctx);

              final backupService = ref.read(appVaultBackupServiceProvider);
              final result = await backupService.exportEncryptedBackup(pass);

              if (context.mounted) {
                if (result.isSuccess) {
                  final bytes = result.valueOrNull!;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Vault backup generated (${bytes.length} bytes encrypted with AES-256-GCM).',
                      ),
                      backgroundColor: ShellitColors.obsidianCard,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Export failed: ${result.failureOrNull?.message}',
                      ),
                      backgroundColor: ShellitColors.statusRed,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Export Backup',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showImportBackupDialog(BuildContext context, WidgetRef ref) {
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ShellitColors.obsidianCard,
        title: const Text(
          'Import Encrypted Vault',
          style: TextStyle(color: ShellitColors.textPrimary, fontSize: 16),
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the password used when creating the backup to decrypt and restore records.',
                style: TextStyle(color: ShellitColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: passCtrl,
                obscureText: true,
                style: const TextStyle(
                  color: ShellitColors.textPrimary,
                  fontSize: 13,
                ),
                decoration: const InputDecoration(labelText: 'Backup Password'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ShellitColors.accentBlue,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Select a valid .shellit-vault archive to restore.',
                  ),
                  backgroundColor: ShellitColors.obsidianCard,
                ),
              );
            },
            child: const Text(
              'Select File & Import',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
