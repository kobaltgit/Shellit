import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_ui/terminal_ui.dart';
import '../../controllers/log_controllers.dart';
import '../../controllers/recording_settings_provider.dart';
import '../../di/app_providers.dart';
import '../../localization/localization_providers.dart';
import '../../localization/template_exporter.dart';
import 'about_settings_card.dart';
import 'ai_settings_card.dart';
import 'sync_settings_card.dart';
import 'workspace_settings_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultState = ref.watch(vaultProvider);
    final activeSchemeName = ref.watch(terminalSchemeNameProvider);
    final logSettings = ref.watch(logSettingsControllerProvider);
    final logController = ref.read(logSettingsControllerProvider.notifier);
    final recordingMode = ref.watch(sessionRecordingModeProvider);
    final activeLocale = ref.watch(activeLocaleProvider);
    final availableLocales = ref.watch(availableLocalesProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobilePlatform =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    final isMobile =
        screenWidth < 700 || (isMobilePlatform && screenWidth < 900);
    final showDesktopExtensions = !isMobile && !isMobilePlatform;

    return Scaffold(
      backgroundColor: ShellitColors.obsidianBackground,
      appBar: AppBar(
        title: Text(
          isMobile
              ? context.tr('sidebar.nav_settings', defaultText: 'Settings')
              : context.tr(
                  'settings.title',
                  defaultText: 'Settings & Security',
                ),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: ShellitColors.obsidianBackground,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_outline, size: 20),
            tooltip: context.tr(
              'settings.lock_vault_now',
              defaultText: 'Lock Vault',
            ),
            onPressed: () => ref.read(vaultProvider.notifier).lock(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Section 1: Security & Vault
          _buildSectionHeader(
            context.tr(
              'settings.security_vault_title',
              defaultText: 'Security & Vault',
            ),
          ),
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
                  title: Text(
                    context.tr(
                      'settings.vault.auto_lock_title',
                      defaultText: 'Auto-Lock Timeout',
                    ),
                    style: const TextStyle(
                      color: ShellitColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    context.tr(
                      'settings.vault.auto_lock_subtitle',
                      params: {
                        'minutes': '${vaultState.autoLockTimeoutMinutes}',
                      },
                      defaultText:
                          'Lock database after ${vaultState.autoLockTimeoutMinutes} minutes of inactivity',
                    ),
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
                    items: [
                      DropdownMenuItem(
                        value: 5,
                        child: Text(
                          context.tr(
                            'settings.vault.auto_lock_5m',
                            defaultText: '5 minutes',
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 15,
                        child: Text(
                          context.tr(
                            'settings.vault.auto_lock_15m',
                            defaultText: '15 minutes',
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 30,
                        child: Text(
                          context.tr(
                            'settings.vault.auto_lock_30m',
                            defaultText: '30 minutes',
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 60,
                        child: Text(
                          context.tr(
                            'settings.vault.auto_lock_1h',
                            defaultText: '1 hour',
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 0,
                        child: Text(
                          context.tr(
                            'settings.vault.auto_lock_never',
                            defaultText: 'Never',
                          ),
                        ),
                      ),
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
                  title: Text(
                    vaultState.isInitialized
                        ? context.tr(
                            'settings.vault.change_password_title',
                            defaultText: 'Change Master Password',
                          )
                        : context.tr(
                            'settings.vault.set_password_title',
                            defaultText: 'Set Master Password',
                          ),
                    style: const TextStyle(
                      color: ShellitColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    vaultState.isInitialized
                        ? context.tr(
                            'settings.vault.change_password_subtitle',
                            defaultText:
                                'Re-encrypt SQLCipher database with a new Argon2id key',
                          )
                        : context.tr(
                            'settings.vault.set_password_subtitle',
                            defaultText:
                                'Protect database and SSH keys with Argon2id encryption',
                          ),
                    style: const TextStyle(
                      color: ShellitColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: ShellitColors.textMuted,
                  ),
                  onTap: () => _showChangePasswordDialog(
                    context,
                    ref,
                    isInitialized: vaultState.isInitialized,
                  ),
                ),
                if (vaultState.isInitialized) ...[
                  const Divider(color: ShellitColors.border, height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.lock_open_rounded,
                      color: ShellitColors.statusRed,
                    ),
                    title: Text(
                      context.tr(
                        'settings.vault.disable_password_title',
                        defaultText: 'Disable Master Password',
                      ),
                      style: const TextStyle(
                        color: ShellitColors.statusRed,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      context.tr(
                        'settings.vault.disable_password_subtitle',
                        defaultText:
                            'The vault will remain open without prompting for a password when launching the app',
                      ),
                      style: const TextStyle(
                        color: ShellitColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: ShellitColors.textMuted,
                    ),
                    onTap: () => _showDisableMasterPasswordDialog(context, ref),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (showDesktopExtensions) ...[
            // Section: Workspace & Sessions
            _buildSectionHeader(
              context.tr(
                'settings.workspace.title',
                defaultText: 'Workspace & Sessions',
              ),
            ),
            const SizedBox(height: 8),
            const WorkspaceSettingsCard(),
            const SizedBox(height: 24),
          ],

          // Section 2: Terminal Appearance
          _buildSectionHeader(
            context.tr(
              'settings.terminal_appearance_title',
              defaultText: 'Terminal Appearance',
            ),
          ),
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
              title: Text(
                context.tr(
                  'settings.terminal.color_scheme_label',
                  defaultText: 'Color Scheme',
                ),
                style: const TextStyle(
                  color: ShellitColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                context.tr(
                  'settings.terminal.current_scheme',
                  params: {'scheme': activeSchemeName},
                  defaultText: 'Current scheme: $activeSchemeName',
                ),
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
                items: [
                  DropdownMenuItem(
                    value: 'Obsidian Dark',
                    child: Text(
                      context.tr(
                        'settings.theme_obsidian',
                        defaultText: 'Obsidian Dark',
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Dracula',
                    child: Text(
                      context.tr(
                        'settings.theme_dracula',
                        defaultText: 'Dracula',
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Nord',
                    child: Text(
                      context.tr('settings.theme_nord', defaultText: 'Nord'),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'OLED True Black',
                    child: Text(
                      context.tr(
                        'settings.theme_oled',
                        defaultText: 'OLED True Black',
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Cyberpunk',
                    child: Text(
                      context.tr(
                        'settings.theme_cyberpunk',
                        defaultText: 'Cyberpunk',
                      ),
                    ),
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
          _buildSectionHeader(
            context.tr(
              'settings.backup_storage_title',
              defaultText: 'Backup & Storage',
            ),
          ),
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
                  title: Text(
                    context.tr(
                      'settings.backup.export_title',
                      defaultText: 'Export Encrypted Vault Backup',
                    ),
                    style: const TextStyle(
                      color: ShellitColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    context.tr(
                      'settings.backup.export_subtitle',
                      defaultText:
                          'Save encrypted archive (.shellit-vault) protected by master key',
                    ),
                    style: const TextStyle(
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
                  title: Text(
                    context.tr(
                      'settings.backup.import_title',
                      defaultText: 'Import Vault Backup',
                    ),
                    style: const TextStyle(
                      color: ShellitColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    context.tr(
                      'settings.backup.import_subtitle',
                      defaultText:
                          'Restore hosts, keys and snippets from encrypted file',
                    ),
                    style: const TextStyle(
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

          // Section: Cross-Device Sync (E2EE)
          _buildSectionHeader(
            context.tr(
              'settings.sync.title',
              defaultText: 'Cross-Device Sync (E2EE)',
            ),
          ),
          const SizedBox(height: 8),
          const SyncSettingsCard(),
          const SizedBox(height: 24),

          // Section: AI Assistant & Gemini
          _buildSectionHeader(
            context.tr(
              'settings.ai.section_title',
              defaultText: 'AI Assistant & Gemini',
            ),
          ),
          const SizedBox(height: 8),
          const AiSettingsCard(),
          const SizedBox(height: 24),

          if (showDesktopExtensions) ...[
            // Section: Language & Translation
            _buildSectionHeader(
              context.tr(
                'settings.language_title',
                defaultText: 'Language & Translation',
              ),
            ),
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
                      Icons.translate_outlined,
                      color: ShellitColors.accentCyan,
                    ),
                    title: Text(
                      context.tr(
                        'settings.language.select_label',
                        defaultText: 'Active Language',
                      ),
                      style: const TextStyle(
                        color: ShellitColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'Current: ${_formatLocaleName(activeLocale)}',
                      style: const TextStyle(
                        color: ShellitColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    trailing: DropdownButton<String>(
                      value: availableLocales.contains(activeLocale)
                          ? activeLocale
                          : 'en',
                      dropdownColor: ShellitColors.obsidianCard,
                      style: const TextStyle(
                        color: ShellitColors.textPrimary,
                        fontSize: 13,
                      ),
                      underline: const SizedBox.shrink(),
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: ShellitColors.accentCyan,
                      ),
                      items: availableLocales.map((code) {
                        return DropdownMenuItem<String>(
                          value: code,
                          child: Text(_formatLocaleName(code)),
                        );
                      }).toList(),
                      onChanged: (newVal) {
                        if (newVal != null) {
                          ref
                              .read(activeLocaleProvider.notifier)
                              .changeLocale(newVal);
                        }
                      },
                    ),
                  ),
                  const Divider(color: ShellitColors.border, height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.file_download_outlined,
                      color: ShellitColors.accentBlue,
                    ),
                    title: Text(
                      context.tr(
                        'settings.language.export_template_btn',
                        defaultText: 'Export Translation Template (.json)',
                      ),
                      style: const TextStyle(
                        color: ShellitColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      context.tr(
                        'settings.language.export_subtitle',
                        defaultText:
                            'Export complete master string dictionary to create custom language plugins',
                      ),
                      style: const TextStyle(
                        color: ShellitColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: ShellitColors.textMuted,
                    ),
                    onTap: () => _showExportTemplateDialog(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          if (showDesktopExtensions) ...[
            // Section 5: Logs & Diagnostics
            _buildSectionHeader(
              context.tr(
                'settings.logs_title',
                defaultText: 'Logs & Diagnostics',
              ),
            ),
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
                    onChanged: (val) =>
                        logController.setFileLoggingEnabled(val),
                    title: Text(
                      context.tr(
                        'settings.logging.write_disk_title',
                        defaultText: 'Write System Logs to Disk',
                      ),
                      style: const TextStyle(
                        color: ShellitColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      context.tr(
                        'settings.logging.write_disk_subtitle',
                        defaultText:
                            'Persists rotated diagnostic logs (up to 2x 5MB) for crash analysis',
                      ),
                      style: const TextStyle(
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
                    title: Text(
                      context.tr(
                        'settings.logging.min_disk_log_title',
                        defaultText: 'Minimum Disk Log Level',
                      ),
                      style: const TextStyle(
                        color: ShellitColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      context.tr(
                        'settings.logging.min_disk_log_subtitle',
                        defaultText:
                            'Filter minimum severity before writing to log files',
                      ),
                      style: const TextStyle(
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
                      items: [
                        DropdownMenuItem(
                          value: LogLevel.debug,
                          child: Text(
                            context.tr(
                              'settings.logs.level_debug',
                              defaultText: 'Debug (Verbose)',
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: LogLevel.info,
                          child: Text(
                            context.tr(
                              'settings.logs.level_info',
                              defaultText: 'Info (Default)',
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: LogLevel.warning,
                          child: Text(
                            context.tr(
                              'settings.logs.level_warn_error',
                              defaultText: 'Warning & Error',
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: LogLevel.error,
                          child: Text(
                            context.tr(
                              'settings.logs.level_error_only',
                              defaultText: 'Error Only',
                            ),
                          ),
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
                      Icons.fiber_manual_record,
                      color: ShellitColors.statusRed,
                    ),
                    title: Text(
                      context.tr(
                        'settings.logging.recording_policy_title',
                        defaultText: 'Terminal Session Recording Policy',
                      ),
                      style: const TextStyle(
                        color: ShellitColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      context.tr(
                        'settings.logging.recording_policy_subtitle',
                        defaultText:
                            'Capture terminal sessions (asciinema .cast and plain text .log)',
                      ),
                      style: const TextStyle(
                        color: ShellitColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    trailing: DropdownButton<SessionRecordingMode>(
                      value: recordingMode,
                      dropdownColor: ShellitColors.obsidianCard,
                      style: const TextStyle(
                        color: ShellitColors.textPrimary,
                        fontSize: 13,
                      ),
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem(
                          value: SessionRecordingMode.prodOnly,
                          child: Text(
                            context.tr(
                              'settings.logs.rec_prod',
                              defaultText: 'PROD Only (Recommended)',
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: SessionRecordingMode.all,
                          child: Text(
                            context.tr(
                              'settings.logs.rec_all',
                              defaultText: 'All Sessions',
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: SessionRecordingMode.manual,
                          child: Text(
                            context.tr(
                              'settings.logs.rec_manual',
                              defaultText: 'Manual (REC button only)',
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref
                              .read(sessionRecordingModeProvider.notifier)
                              .setMode(val);
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
                    title: Text(
                      context.tr(
                        'settings.logging.open_logs_dir_title',
                        defaultText: 'Open Logs Directory',
                      ),
                      style: const TextStyle(
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
                    title: Text(
                      context.tr(
                        'settings.logging.clear_logs_title',
                        defaultText: 'Clear Disk Logs',
                      ),
                      style: const TextStyle(
                        color: ShellitColors.statusRed,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      context.tr(
                        'settings.logging.clear_logs_subtitle',
                        defaultText:
                            'Erase all historical log files from storage',
                      ),
                      style: const TextStyle(
                        color: ShellitColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () async {
                      await logController.clearDiskLogs();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.tr(
                                'settings.logs.files_deleted_msg',
                                defaultText:
                                    'Disk log files deleted successfully',
                              ),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Section: About Shellit
          _buildSectionHeader(
            context.tr(
              'settings.about.section_title',
              defaultText: 'About Shellit',
            ),
          ),
          const SizedBox(height: 8),
          const AboutSettingsCard(),
          const SizedBox(height: 24),
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

  String _formatLocaleName(String code) {
    switch (code) {
      case 'en':
        return 'English (Built-in)';
      case 'ru_RU':
      case 'ru':
        return 'Русский (Russian)';
      case 'de_DE':
      case 'de':
        return 'Deutsch (German)';
      case 'es_ES':
      case 'es':
        return 'Español (Spanish)';
      case 'fr_FR':
      case 'fr':
        return 'Français (French)';
      case 'zh_CN':
      case 'zh':
        return '中文 (Chinese)';
      default:
        return code;
    }
  }

  void _showExportTemplateDialog(BuildContext context) {
    final pathCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ShellitColors.obsidianCard,
        title: Text(
          context.tr(
            'settings.export_template.title',
            defaultText: 'Export Translation Template',
          ),
          style: const TextStyle(
            color: ShellitColors.textPrimary,
            fontSize: 16,
          ),
        ),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(
                  'settings.export_template.description',
                  defaultText:
                      'Export complete master strings dictionary (JSON) to create custom language plugins or submit community translations:',
                ),
                style: const TextStyle(
                  color: ShellitColors.textMuted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: pathCtrl,
                style: const TextStyle(
                  color: ShellitColors.textPrimary,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  labelText: context.tr(
                    'settings.export_template.path_label',
                    defaultText: 'Output File Path (Optional)',
                  ),
                  hintText: context.tr(
                    'settings.export_template.path_hint',
                    defaultText: 'Leave empty for default Downloads folder',
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('common.cancel', defaultText: 'Cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ShellitColors.accentBlue,
            ),
            onPressed: () async {
              final customPath = pathCtrl.text.trim();
              Navigator.pop(ctx);

              final res = await TemplateExporter.exportTemplateFile(
                targetFilePath: customPath.isNotEmpty ? customPath : null,
              );

              if (context.mounted) {
                if (res.isSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.tr(
                          'settings.export_template.success_msg',
                          defaultText:
                              'Template exported successfully to: {path}',
                          namedArgs: {'path': res.valueOrNull ?? ''},
                        ),
                      ),
                      backgroundColor: ShellitColors.statusGreen,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.tr(
                          'settings.export_template.error_msg',
                          defaultText: 'Export failed: {err}',
                          namedArgs: {'err': res.failureOrNull.toString()},
                        ),
                      ),
                      backgroundColor: ShellitColors.statusRed,
                    ),
                  );
                }
              }
            },
            child: Text(
              context.tr(
                'settings.export_template.btn_export',
                defaultText: 'Export Template',
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(
    BuildContext context,
    WidgetRef ref, {
    required bool isInitialized,
  }) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    String? localError;
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: !isProcessing,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: ShellitColors.obsidianCard,
            title: Text(
              isInitialized ? 'Change Master Password' : 'Set Master Password',
              style: const TextStyle(
                color: ShellitColors.textPrimary,
                fontSize: 16,
              ),
            ),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (localError != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: ShellitColors.statusRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: ShellitColors.statusRed.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: ShellitColors.statusRed,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              localError!,
                              style: const TextStyle(
                                color: ShellitColors.statusRed,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (isInitialized) ...[
                    TextField(
                      controller: oldPassCtrl,
                      obscureText: true,
                      enabled: !isProcessing,
                      style: const TextStyle(
                        color: ShellitColors.textPrimary,
                        fontSize: 13,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Current Master Password',
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: newPassCtrl,
                    obscureText: true,
                    enabled: !isProcessing,
                    style: const TextStyle(
                      color: ShellitColors.textPrimary,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      labelText: isInitialized
                          ? 'New Master Password'
                          : 'Master Password',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPassCtrl,
                    obscureText: true,
                    enabled: !isProcessing,
                    style: const TextStyle(
                      color: ShellitColors.textPrimary,
                      fontSize: 13,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isProcessing ? null : () => Navigator.pop(ctx),
                child: Text(context.tr('common.cancel', defaultText: 'Cancel')),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ShellitColors.accentBlue,
                ),
                onPressed: isProcessing
                    ? null
                    : () async {
                        final oldPass = oldPassCtrl.text;
                        final newPass = newPassCtrl.text;
                        final confirmPass = confirmPassCtrl.text;

                        if (isInitialized && oldPass.isEmpty) {
                          setState(() {
                            localError =
                                'Please enter your current master password.';
                          });
                          return;
                        }
                        if (newPass.isEmpty) {
                          setState(() {
                            localError =
                                'Please enter the new master password.';
                          });
                          return;
                        }
                        if (newPass.length < 6) {
                          setState(() {
                            localError =
                                'Master password must be at least 6 characters.';
                          });
                          return;
                        }
                        if (isInitialized && newPass == oldPass) {
                          setState(() {
                            localError =
                                'New password must be different from the current password.';
                          });
                          return;
                        }
                        if (newPass != confirmPass) {
                          setState(() {
                            localError = 'Passwords do not match.';
                          });
                          return;
                        }

                        setState(() {
                          isProcessing = true;
                          localError = null;
                        });

                        if (isInitialized) {
                          final res = await ref
                              .read(vaultProvider.notifier)
                              .changeMasterPassword(
                                currentPassword: oldPass,
                                newPassword: newPass,
                              );

                          if (!ctx.mounted) return;

                          if (res.isSuccess) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Master password updated and database re-keyed.',
                                ),
                                backgroundColor: ShellitColors.statusGreen,
                              ),
                            );
                          } else {
                            setState(() {
                              isProcessing = false;
                              localError =
                                  res.failureOrNull?.message ??
                                  'Failed to update master password.';
                            });
                          }
                        } else {
                          final ok = await ref
                              .read(vaultProvider.notifier)
                              .initializeVault(newPass);

                          if (!ctx.mounted) return;

                          if (ok) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Master password set and database encrypted.',
                                ),
                                backgroundColor: ShellitColors.statusGreen,
                              ),
                            );
                          } else {
                            setState(() {
                              isProcessing = false;
                              localError =
                                  ref.read(vaultProvider).errorMessage ??
                                  'Failed to set master password.';
                            });
                          }
                        }
                      },
                child: isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isInitialized ? 'Update Password' : 'Set Password',
                        style: const TextStyle(color: Colors.white),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDisableMasterPasswordDialog(BuildContext context, WidgetRef ref) {
    final passCtrl = TextEditingController();
    String? localError;
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: !isProcessing,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: ShellitColors.obsidianCard,
            title: const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: ShellitColors.statusRed,
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  'Disable Master Password?',
                  style: TextStyle(
                    color: ShellitColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Warning: The database and stored SSH keys will no longer be encrypted with your master password. The vault will be automatically accessible every time you launch the app.',
                    style: TextStyle(
                      color: ShellitColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (localError != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: ShellitColors.statusRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: ShellitColors.statusRed.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: ShellitColors.statusRed,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              localError!,
                              style: const TextStyle(
                                color: ShellitColors.statusRed,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    autofocus: true,
                    enabled: !isProcessing,
                    style: const TextStyle(
                      color: ShellitColors.textPrimary,
                      fontSize: 13,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Current Master Password',
                      hintText: 'Enter master password to confirm',
                    ),
                    onSubmitted: (pwd) async {
                      if (pwd.isEmpty) return;
                      setState(() {
                        isProcessing = true;
                        localError = null;
                      });

                      final res = await ref
                          .read(vaultProvider.notifier)
                          .disableMasterPassword(currentPassword: pwd);

                      if (!ctx.mounted) return;

                      if (res.isSuccess) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Master password successfully disabled. Vault remains open.',
                            ),
                            backgroundColor: ShellitColors.statusGreen,
                          ),
                        );
                      } else {
                        setState(() {
                          isProcessing = false;
                          localError =
                              res.failureOrNull?.message ??
                              'Invalid master password.';
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isProcessing ? null : () => Navigator.pop(ctx),
                child: Text(context.tr('common.cancel', defaultText: 'Cancel')),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ShellitColors.statusRed,
                ),
                onPressed: isProcessing
                    ? null
                    : () async {
                        final pwd = passCtrl.text;
                        if (pwd.isEmpty) {
                          setState(() {
                            localError =
                                'Please enter your current master password.';
                          });
                          return;
                        }

                        setState(() {
                          isProcessing = true;
                          localError = null;
                        });

                        final res = await ref
                            .read(vaultProvider.notifier)
                            .disableMasterPassword(currentPassword: pwd);

                        if (!ctx.mounted) return;

                        if (res.isSuccess) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Master password successfully disabled. Vault remains open.',
                              ),
                              backgroundColor: ShellitColors.statusGreen,
                            ),
                          );
                        } else {
                          setState(() {
                            isProcessing = false;
                            localError =
                                res.failureOrNull?.message ??
                                'Invalid master password.';
                          });
                        }
                      },
                child: isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Disable Password',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          );
        },
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
            child: Text(context.tr('common.cancel', defaultText: 'Cancel')),
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
            child: Text(context.tr('common.cancel', defaultText: 'Cancel')),
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
