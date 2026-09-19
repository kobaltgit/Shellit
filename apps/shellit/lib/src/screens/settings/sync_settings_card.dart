import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storage_vault/storage_vault.dart';
import 'package:terminal_ui/terminal_ui.dart';
import '../../di/app_providers.dart';

/// Interactive UI card for configuring E2EE Self-Hosted synchronization.
class SyncSettingsCard extends ConsumerStatefulWidget {
  const SyncSettingsCard({super.key});

  @override
  ConsumerState<SyncSettingsCard> createState() => _SyncSettingsCardState();
}

class _SyncSettingsCardState extends ConsumerState<SyncSettingsCard> {
  late final TextEditingController _urlController;
  late final TextEditingController _vaultIdController;
  late final TextEditingController _passphraseController;
  late final TextEditingController _tokenController;

  bool _allowInsecure = false;
  bool _obscurePassphrase = true;
  bool _isSyncing = false;
  String? _statusMessage;
  Color _statusColor = ShellitColors.textMuted;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _vaultIdController = TextEditingController(text: 'main-vault');
    _passphraseController = TextEditingController();
    _tokenController = TextEditingController();

    _loadExistingSettings();
  }

  Future<void> _loadExistingSettings() async {
    final vaultRepo = ref.read(appVaultRepositoryProvider);
    final settings = await vaultRepo.getSettings();
    if (mounted) {
      setState(() {
        if (settings.syncServerUrl != null &&
            settings.syncServerUrl!.isNotEmpty) {
          _urlController.text = settings.syncServerUrl!;
        }
        if (settings.syncVaultId != null && settings.syncVaultId!.isNotEmpty) {
          _vaultIdController.text = settings.syncVaultId!;
        }
        if (settings.syncPassphrase != null &&
            settings.syncPassphrase!.isNotEmpty) {
          _passphraseController.text = settings.syncPassphrase!;
        }
        if (settings.registrationToken != null &&
            settings.registrationToken!.isNotEmpty) {
          _tokenController.text = settings.registrationToken!;
        }
        _allowInsecure = settings.allowInsecureCertificates;
        if (settings.lastSyncedAt != null) {
          _statusMessage = context
              .tr('sync.last_synced', defaultText: 'Last synced: {time}')
              .replaceAll('{time}', _formatDate(settings.lastSyncedAt!));
          _statusColor = ShellitColors.statusGreen;
        }
      });
    }
  }

  Future<void> _saveCurrentSettings({
    DateTime? lastSyncedAt,
    bool? isSyncEnabled,
  }) async {
    try {
      final vaultRepo = ref.read(appVaultRepositoryProvider);
      final current = await vaultRepo.getSettings();
      final updated = current.copyWith(
        syncServerUrl: _urlController.text.trim(),
        syncVaultId: _vaultIdController.text.trim(),
        syncPassphrase: _passphraseController.text,
        registrationToken: _tokenController.text.trim(),
        allowInsecureCertificates: _allowInsecure,
        lastSyncedAt: lastSyncedAt ?? current.lastSyncedAt,
        isSyncEnabled: isSyncEnabled ?? current.isSyncEnabled,
      );
      await vaultRepo.updateSettings(updated);
    } catch (_) {}
  }

  String _formatDate(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')} (${dt.day}.${dt.month}.${dt.year})';
  }

  @override
  void dispose() {
    _urlController.dispose();
    _vaultIdController.dispose();
    _passphraseController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      _showMessage(
        context.tr(
          'sync.err_url_required',
          defaultText: 'Server URL is required',
        ),
        isError: true,
      );
      return;
    }

    await _saveCurrentSettings();

    setState(() {
      _isSyncing = true;
      _statusMessage = context.tr(
        'sync.test_testing',
        defaultText: 'Testing connection...',
      );
      _statusColor = ShellitColors.accentCyan;
    });

    final client = SyncClient(allowInsecureCertificates: _allowInsecure);
    final res = await client.checkHealth(url);

    if (mounted) {
      setState(() {
        _isSyncing = false;
        if (res.isSuccess) {
          _statusMessage = context.tr(
            'sync.test_success',
            defaultText: 'Connection successful! (Server Online)',
          );
          _statusColor = ShellitColors.statusGreen;
        } else {
          _statusMessage =
              res.failureOrNull?.message ??
              context.tr(
                'sync.test_failed',
                defaultText: 'Connection failed',
              );
          _statusColor = ShellitColors.statusRed;
        }
      });
    }
  }

  Future<void> _runSync() async {
    final url = _urlController.text.trim();
    final vaultId = _vaultIdController.text.trim();
    final passphrase = _passphraseController.text;
    final token = _tokenController.text.trim();

    if (url.isEmpty) {
      _showMessage(
        context.tr(
          'sync.err_url_required',
          defaultText: 'Server URL is required',
        ),
        isError: true,
      );
      return;
    }
    if (vaultId.isEmpty) {
      _showMessage(
        context.tr(
          'sync.err_vault_id_required',
          defaultText: 'Vault ID is required',
        ),
        isError: true,
      );
      return;
    }
    if (passphrase.isEmpty) {
      _showMessage(
        context.tr(
          'sync.err_passphrase_required',
          defaultText: 'Sync Passphrase is required for E2EE encryption',
        ),
        isError: true,
      );
      return;
    }

    await _saveCurrentSettings();

    setState(() {
      _isSyncing = true;
      _statusMessage = context.tr(
        'sync.syncing',
        defaultText: 'Synchronizing with server...',
      );
      _statusColor = ShellitColors.accentCyan;
    });

    final syncManager = ref.read(appSyncManagerProvider);
    final res = await syncManager.synchronize(
      serverUrl: url,
      vaultId: vaultId,
      passphrase: passphrase,
      registrationToken: token.isNotEmpty ? token : null,
      allowInsecureCertificates: _allowInsecure,
    );

    if (mounted) {
      setState(() {
        _isSyncing = false;
        if (res.isSuccess) {
          final summary = res.valueOrNull!;
          _statusMessage = context
              .tr(
                'sync.sync_success',
                defaultText:
                    'Synced successfully (Rev {rev}, Pulled {pulled}, Pushed {pushed})',
              )
              .replaceAll('{rev}', summary.serverRevision.toString())
              .replaceAll('{pulled}', summary.pulledCount.toString())
              .replaceAll('{pushed}', summary.pushedCount.toString());
          _statusColor = ShellitColors.statusGreen;
          _showMessage(
            context
                .tr(
                  'sync.sync_complete_msg',
                  defaultText:
                      'Sync complete: {pulled} pulled, {pushed} pushed',
                )
                .replaceAll('{pulled}', summary.pulledCount.toString())
                .replaceAll('{pushed}', summary.pushedCount.toString()),
          );
          _saveCurrentSettings(
            lastSyncedAt: DateTime.now(),
            isSyncEnabled: true,
          );
        } else {
          final errMsg = res.failureOrNull?.message ?? '';
          _statusMessage = context
              .tr(
                'sync.sync_failed',
                defaultText: 'Sync failed: {error}',
              )
              .replaceAll('{error}', errMsg);
          _statusColor = ShellitColors.statusRed;
          _showMessage(_statusMessage!, isError: true);
        }
      });
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? ShellitColors.statusRed
            : ShellitColors.statusGreen,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ShellitColors.obsidianCard,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: ShellitColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.sync_lock_rounded,
                  color: ShellitColors.accentCyan,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(
                          'sync.card_title',
                          defaultText: 'Self-Hosted Synchronization (E2EE)',
                        ),
                        style: const TextStyle(
                          color: ShellitColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        context.tr(
                          'sync.card_subtitle',
                          defaultText:
                              'Sync across devices via your personal VPS with Zero-Knowledge encryption',
                        ),
                        style: const TextStyle(
                          color: ShellitColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _statusColor.withAlpha(90)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          color: _statusColor,
                          fontSize: 12,
                          height: 1.3,
                        ),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(color: ShellitColors.border),
            const SizedBox(height: 12),

            // Server URL Field
            TextFormField(
              controller: _urlController,
              onChanged: (_) => _saveCurrentSettings(),
              style: const TextStyle(
                color: ShellitColors.textPrimary,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                labelText: context.tr(
                  'sync.server_url_label',
                  defaultText: 'Server URL (HTTP / HTTPS)',
                ),
                labelStyle: const TextStyle(
                  color: ShellitColors.textMuted,
                  fontSize: 12,
                ),
                hintText: context.tr(
                  'sync.server_url_hint',
                  defaultText:
                      'e.g. http://192.168.1.50:8080 or https://sync.my-vps.net',
                ),
                hintStyle: const TextStyle(
                  color: ShellitColors.textMuted,
                  fontSize: 12,
                ),
                prefixIcon: const Icon(
                  Icons.dns_outlined,
                  color: ShellitColors.textMuted,
                  size: 18,
                ),
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Vault ID Field
            TextFormField(
              controller: _vaultIdController,
              onChanged: (_) => _saveCurrentSettings(),
              style: const TextStyle(
                color: ShellitColors.textPrimary,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                labelText: context.tr(
                  'sync.vault_id_label',
                  defaultText: 'Vault ID (Namespace)',
                ),
                labelStyle: const TextStyle(
                  color: ShellitColors.textMuted,
                  fontSize: 12,
                ),
                hintText: context.tr(
                  'sync.vault_id_hint',
                  defaultText: 'e.g. personal-vault',
                ),
                prefixIcon: const Icon(
                  Icons.folder_shared_outlined,
                  color: ShellitColors.textMuted,
                  size: 18,
                ),
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Sync Passphrase Field (Zero-Knowledge)
            TextFormField(
              controller: _passphraseController,
              onChanged: (_) => _saveCurrentSettings(),
              obscureText: _obscurePassphrase,
              style: const TextStyle(
                color: ShellitColors.textPrimary,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                labelText: context.tr(
                  'sync.passphrase_label',
                  defaultText: 'Sync Passphrase (E2EE Encryption Key)',
                ),
                labelStyle: const TextStyle(
                  color: ShellitColors.textMuted,
                  fontSize: 12,
                ),
                helperText: context.tr(
                  'sync.passphrase_helper',
                  defaultText:
                      'Derived on your device via Argon2id. The server NEVER sees this password.',
                ),
                helperStyle: const TextStyle(
                  color: ShellitColors.textMuted,
                  fontSize: 11,
                ),
                prefixIcon: const Icon(
                  Icons.key_outlined,
                  color: ShellitColors.textMuted,
                  size: 18,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassphrase
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: ShellitColors.textMuted,
                    size: 18,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassphrase = !_obscurePassphrase),
                ),
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Optional Registration Token
            TextFormField(
              controller: _tokenController,
              onChanged: (_) => _saveCurrentSettings(),
              style: const TextStyle(
                color: ShellitColors.textPrimary,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                labelText: context.tr(
                  'sync.token_label',
                  defaultText: 'Registration Token (Optional)',
                ),
                labelStyle: const TextStyle(
                  color: ShellitColors.textMuted,
                  fontSize: 12,
                ),
                helperText: context.tr(
                  'sync.token_helper',
                  defaultText:
                      'Required only when creating a new vault on a token-protected server',
                ),
                helperStyle: const TextStyle(
                  color: ShellitColors.textMuted,
                  fontSize: 11,
                ),
                prefixIcon: const Icon(
                  Icons.security_outlined,
                  color: ShellitColors.textMuted,
                  size: 18,
                ),
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            // Allow Insecure / Self-Signed SSL
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                context.tr(
                  'sync.allow_insecure_title',
                  defaultText:
                      'Allow Insecure / Self-Signed Certificates & Plain HTTP',
                ),
                style: const TextStyle(
                  color: ShellitColors.textPrimary,
                  fontSize: 13,
                ),
              ),
              subtitle: Text(
                context.tr(
                  'sync.allow_insecure_subtitle',
                  defaultText:
                      'Enable for local LAN IP, WireGuard / Tailscale without SSL, or self-signed HTTPS',
                ),
                style: const TextStyle(
                  color: ShellitColors.textMuted,
                  fontSize: 11,
                ),
              ),
              value: _allowInsecure,
              activeThumbColor: ShellitColors.accentCyan,
              onChanged: (val) {
                setState(() => _allowInsecure = val);
                _saveCurrentSettings();
              },
            ),
            const SizedBox(height: 14),

            // Actions
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: _isSyncing ? null : _runSync,
                  icon: _isSyncing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.sync_rounded, size: 16),
                  label: Text(
                    _isSyncing
                        ? context.tr(
                            'sync.btn_syncing',
                            defaultText: 'Syncing...',
                          )
                        : context.tr(
                            'sync.btn_sync_now',
                            defaultText: 'Sync Now',
                          ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ShellitColors.accentCyan,
                    foregroundColor: Colors.black,
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await _saveCurrentSettings();
                    if (!context.mounted) return;
                    _showMessage(
                      context.tr(
                        'sync.saved_success',
                        defaultText: 'Sync settings saved successfully',
                      ),
                    );
                  },
                  icon: const Icon(Icons.save_outlined, size: 16),
                  label: Text(
                    context.tr(
                      'sync.btn_save_settings',
                      defaultText: 'Save Settings',
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ShellitColors.textPrimary,
                    side: const BorderSide(color: ShellitColors.border),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _isSyncing ? null : _testConnection,
                  icon: const Icon(Icons.network_check_rounded, size: 16),
                  label: Text(
                    context.tr(
                      'sync.btn_test_connection',
                      defaultText: 'Test Connection',
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ShellitColors.textPrimary,
                    side: const BorderSide(color: ShellitColors.border),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
