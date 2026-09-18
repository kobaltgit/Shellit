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
        _allowInsecure = settings.allowInsecureCertificates;
        if (settings.lastSyncedAt != null) {
          _statusMessage =
              'Last synced: ${_formatDate(settings.lastSyncedAt!)}';
          _statusColor = ShellitColors.statusGreen;
        }
      });
    }
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
      _showMessage('Enter a Server URL first', isError: true);
      return;
    }

    setState(() {
      _isSyncing = true;
      _statusMessage = 'Testing connection...';
      _statusColor = ShellitColors.accentCyan;
    });

    final client = SyncClient(allowInsecureCertificates: _allowInsecure);
    final res = await client.checkHealth(url);

    if (mounted) {
      setState(() {
        _isSyncing = false;
        if (res.isSuccess) {
          _statusMessage = 'Connection successful! (Server Online)';
          _statusColor = ShellitColors.statusGreen;
        } else {
          _statusMessage = res.failureOrNull?.message ?? 'Connection failed';
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
      _showMessage('Server URL is required', isError: true);
      return;
    }
    if (vaultId.isEmpty) {
      _showMessage('Vault ID is required', isError: true);
      return;
    }
    if (passphrase.isEmpty) {
      _showMessage(
        'Sync Passphrase is required for E2EE encryption',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSyncing = true;
      _statusMessage = 'Synchronizing with server...';
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
          _statusMessage =
              'Synced successfully (Rev ${summary.serverRevision}, Pulled ${summary.pulledCount}, Pushed ${summary.pushedCount})';
          _statusColor = ShellitColors.statusGreen;
          _showMessage(
            'Sync complete: ${summary.pulledCount} pulled, ${summary.pushedCount} pushed',
          );
        } else {
          _statusMessage = 'Sync failed: ${res.failureOrNull?.message}';
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Self-Hosted Synchronization (E2EE)',
                        style: TextStyle(
                          color: ShellitColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Sync across devices via your personal VPS with Zero-Knowledge encryption',
                        style: TextStyle(
                          color: ShellitColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_statusMessage != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _statusColor.withAlpha(100)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _statusMessage!,
                          style: TextStyle(color: _statusColor, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: ShellitColors.border),
            const SizedBox(height: 12),

            // Server URL Field
            TextFormField(
              controller: _urlController,
              style: const TextStyle(
                color: ShellitColors.textPrimary,
                fontSize: 13,
              ),
              decoration: const InputDecoration(
                labelText: 'Server URL (HTTP / HTTPS)',
                labelStyle: TextStyle(
                  color: ShellitColors.textMuted,
                  fontSize: 12,
                ),
                hintText:
                    'e.g. http://192.168.1.50:8080 or https://sync.my-vps.net',
                hintStyle: TextStyle(
                  color: ShellitColors.textMuted,
                  fontSize: 12,
                ),
                prefixIcon: Icon(
                  Icons.dns_outlined,
                  color: ShellitColors.textMuted,
                  size: 18,
                ),
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Vault ID Field
            TextFormField(
              controller: _vaultIdController,
              style: const TextStyle(
                color: ShellitColors.textPrimary,
                fontSize: 13,
              ),
              decoration: const InputDecoration(
                labelText: 'Vault ID (Namespace)',
                labelStyle: TextStyle(
                  color: ShellitColors.textMuted,
                  fontSize: 12,
                ),
                hintText: 'e.g. personal-vault',
                prefixIcon: Icon(
                  Icons.folder_shared_outlined,
                  color: ShellitColors.textMuted,
                  size: 18,
                ),
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Sync Passphrase Field (Zero-Knowledge)
            TextFormField(
              controller: _passphraseController,
              obscureText: _obscurePassphrase,
              style: const TextStyle(
                color: ShellitColors.textPrimary,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                labelText: 'Sync Passphrase (E2EE Encryption Key)',
                labelStyle: const TextStyle(
                  color: ShellitColors.textMuted,
                  fontSize: 12,
                ),
                helperText:
                    'Derived on your device via Argon2id. The server NEVER sees this password.',
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
              style: const TextStyle(
                color: ShellitColors.textPrimary,
                fontSize: 13,
              ),
              decoration: const InputDecoration(
                labelText: 'Registration Token (Optional)',
                labelStyle: TextStyle(
                  color: ShellitColors.textMuted,
                  fontSize: 12,
                ),
                helperText:
                    'Required only when creating a new vault on a token-protected server',
                helperStyle: TextStyle(
                  color: ShellitColors.textMuted,
                  fontSize: 11,
                ),
                prefixIcon: Icon(
                  Icons.security_outlined,
                  color: ShellitColors.textMuted,
                  size: 18,
                ),
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            // Allow Insecure / Self-Signed SSL
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Allow Insecure / Self-Signed Certificates & Plain HTTP',
                style: TextStyle(
                  color: ShellitColors.textPrimary,
                  fontSize: 13,
                ),
              ),
              subtitle: const Text(
                'Enable for local LAN IP, WireGuard / Tailscale without SSL, or self-signed HTTPS',
                style: TextStyle(color: ShellitColors.textMuted, fontSize: 11),
              ),
              value: _allowInsecure,
              activeThumbColor: ShellitColors.accentCyan,
              onChanged: (val) => setState(() => _allowInsecure = val),
            ),
            const SizedBox(height: 14),

            // Actions
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _isSyncing ? null : _testConnection,
                  icon: const Icon(Icons.network_check_rounded, size: 16),
                  label: const Text('Test Connection'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ShellitColors.textPrimary,
                    side: const BorderSide(color: ShellitColors.border),
                  ),
                ),
                const SizedBox(width: 12),
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
                  label: Text(_isSyncing ? 'Syncing...' : 'Sync Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ShellitColors.accentCyan,
                    foregroundColor: Colors.black,
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
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
