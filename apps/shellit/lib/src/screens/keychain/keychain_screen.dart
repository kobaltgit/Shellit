import 'dart:convert';
import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ssh_network_core/ssh_network_core.dart';
import 'package:storage_vault/storage_vault.dart';
import 'package:terminal_ui/terminal_ui.dart';
import '../../di/app_providers.dart';
import 'deploy_key_dialog.dart';
import 'generate_key_dialog.dart';
import 'import_ssh_keys_dialog.dart';

final keychainListProvider = FutureProvider.autoDispose<List<KeyEntity>>((
  ref,
) async {
  final keyManager = ref.watch(appKeyManagerProvider);
  return keyManager.getAllKeys();
});

class KeychainScreen extends ConsumerWidget {
  const KeychainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keysAsync = ref.watch(keychainListProvider);

    return Scaffold(
      backgroundColor: ShellitColors.obsidianBackground,
      appBar: AppBar(
        title: Text(
          context.tr(
            'keychain.title',
            defaultText: 'SSH Keychain & Certificates',
          ),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: ShellitColors.obsidianBackground,
        elevation: 0,
        actions: [
          OutlinedButton.icon(
            icon: const Icon(
              Icons.folder_open,
              size: 15,
              color: ShellitColors.accentCyan,
            ),
            label: Text(
              context.tr('keychain.btn_import', defaultText: 'Import ~/.ssh'),
              style: const TextStyle(
                color: ShellitColors.accentCyan,
                fontSize: 12,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: ShellitColors.accentCyan),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            onPressed: () async {
              await ImportSshKeysDialog.show(context);
              ref.invalidate(keychainListProvider);
            },
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.bolt, size: 16),
            label: Text(
              context.tr('keychain.btn_generate', defaultText: 'Generate Key'),
              style: const TextStyle(fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: ShellitColors.accentBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            onPressed: () async {
              await GenerateKeyDialog.show(context);
              ref.invalidate(keychainListProvider);
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              size: 20,
              color: ShellitColors.textSecondary,
            ),
            tooltip: context.tr(
              'keychain.tooltip_add_pem',
              defaultText: 'Add Key Manually (PEM)',
            ),
            onPressed: () => _showAddKeyDialog(context, ref),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: keysAsync.when(
        data: (keys) {
          if (keys.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ShellitColors.obsidianCard,
                      shape: BoxShape.circle,
                      border: Border.all(color: ShellitColors.border),
                    ),
                    child: const Icon(
                      Icons.vpn_key_outlined,
                      size: 48,
                      color: ShellitColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.tr(
                      'keychain.empty_title',
                      defaultText: 'No SSH Keys in Vault',
                    ),
                    style: const TextStyle(
                      color: ShellitColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.tr(
                      'keychain.empty_desc',
                      defaultText:
                          'Generate a modern Ed25519 key or import existing keys from your local ~/.ssh folder',
                    ),
                    style: const TextStyle(
                      color: ShellitColors.textMuted,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.bolt, size: 16),
                        label: Text(
                          context.tr(
                            'keychain.btn_generate_pair',
                            defaultText: 'Generate Key Pair',
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ShellitColors.accentBlue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          await GenerateKeyDialog.show(context);
                          ref.invalidate(keychainListProvider);
                        },
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.folder_open, size: 16),
                        label: Text(
                          context.tr(
                            'keychain.btn_import_ssh',
                            defaultText: 'Import from ~/.ssh',
                          ),
                        ),
                        onPressed: () async {
                          await ImportSshKeysDialog.show(context);
                          ref.invalidate(keychainListProvider);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: keys.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final key = keys[index];
              final isEd25519 = key.keyType == KeyType.ed25519;
              final isRsa = key.keyType == KeyType.rsa;

              final badgeColor = isEd25519
                  ? ShellitColors.accentCyan
                  : (isRsa
                        ? ShellitColors.accentBlue
                        : ShellitColors.accentPurple);

              return Card(
                color: ShellitColors.obsidianCard,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: ShellitColors.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: badgeColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.vpn_key_rounded,
                          color: badgeColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  key.label,
                                  style: const TextStyle(
                                    color: ShellitColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: badgeColor.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Text(
                                    key.keyType.name.toUpperCase(),
                                    style: TextStyle(
                                      color: badgeColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (key.hasPassphrase) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ShellitColors.statusYellow
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.lock,
                                          size: 10,
                                          color: ShellitColors.statusYellow,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          context.tr(
                                            'keychain.badge_passphrase',
                                            defaultText: 'PASSPHRASE',
                                          ),
                                          style: const TextStyle(
                                            color: ShellitColors.statusYellow,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${context.tr('keychain.fingerprint_label', defaultText: 'Fingerprint')}: ${key.fingerprint ?? "N/A"}',
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                color: ShellitColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${context.tr('keychain.created_label', defaultText: 'Created')}: ${key.createdAt.toLocal().toString().split('.')[0]}',
                              style: const TextStyle(
                                color: ShellitColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Actions
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.copy_rounded,
                              size: 18,
                              color: ShellitColors.textSecondary,
                            ),
                            tooltip: context.tr(
                              'keychain.btn_copy_public_key',
                              defaultText: 'Copy Public Key',
                            ),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: key.publicKey),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    context.tr(
                                      'keychain.copied_snackbar',
                                      defaultText:
                                          'Public key copied to clipboard!',
                                    ),
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.cloud_upload_outlined,
                              size: 18,
                              color: ShellitColors.statusGreen,
                            ),
                            tooltip: context.tr(
                              'keychain.btn_deploy_key',
                              defaultText:
                                  'Deploy Key to Server (ssh-copy-id)',
                            ),
                            onPressed: () async {
                              await DeployKeyDialog.show(context, key);
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.visibility_outlined,
                              size: 18,
                              color: ShellitColors.textSecondary,
                            ),
                            tooltip: context.tr(
                              'keychain.btn_view_details',
                              defaultText: 'View Details',
                            ),
                            onPressed: () => _showKeyDetails(context, key),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: ShellitColors.statusRed,
                            ),
                            tooltip: context.tr(
                              'keychain.btn_delete_key',
                              defaultText: 'Delete Key',
                            ),
                            onPressed: () => _confirmDelete(context, ref, key),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(
            '${context.tr('keychain.error_loading', defaultText: 'Error loading keys')}: $err',
            style: const TextStyle(color: ShellitColors.statusRed),
          ),
        ),
      ),
    );
  }

  void _showKeyDetails(BuildContext context, KeyEntity key) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ShellitColors.obsidianCard,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: ShellitColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.vpn_key_rounded,
              size: 18,
              color: ShellitColors.accentCyan,
            ),
            const SizedBox(width: 8),
            Text(
              key.label,
              style: const TextStyle(
                color: ShellitColors.textPrimary,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${context.tr('keychain.details_type', defaultText: 'Type')}: ${key.keyType.name.toUpperCase()}',
                style: const TextStyle(
                  color: ShellitColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${context.tr('keychain.details_fingerprint', defaultText: 'Fingerprint')}: ${key.fingerprint ?? "N/A"}',
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  color: ShellitColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${context.tr('keychain.details_public_key', defaultText: 'Public Key')}:',
                style: const TextStyle(
                  color: ShellitColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ShellitColors.obsidianBackground,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: ShellitColors.border),
                ),
                child: SelectableText(
                  key.publicKey,
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    color: ShellitColors.textPrimary,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ShellitColors.borderLight,
                  foregroundColor: ShellitColors.textPrimary,
                  minimumSize: const Size.fromHeight(36),
                ),
                icon: const Icon(Icons.copy, size: 14),
                label: Text(
                  context.tr(
                    'keychain.btn_copy_public_key',
                    defaultText: 'Copy Public Key',
                  ),
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: key.publicKey));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.tr(
                          'keychain.copied_snackbar',
                          defaultText: 'Public key copied to clipboard!',
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              context.tr('keychain.btn_close', defaultText: 'Close'),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, KeyEntity key) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ShellitColors.obsidianCard,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: ShellitColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        title: Text(
          context.tr('keychain.delete_dialog_title', defaultText: 'Delete SSH Key?'),
          style: const TextStyle(color: ShellitColors.textPrimary, fontSize: 16),
        ),
        content: Text(
          context.tr(
            'keychain.delete_dialog_message',
            defaultText:
                'Are you sure you want to delete "{label}"? Any servers relying exclusively on this key will need another authentication method.',
          ).replaceAll('{label}', key.label),
          style: const TextStyle(
            color: ShellitColors.textSecondary,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              context.tr('keychain.btn_cancel', defaultText: 'Cancel'),
              style: const TextStyle(color: ShellitColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ShellitColors.statusRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await ref.read(appKeyManagerProvider).deleteKey(key.id);
              ref.invalidate(keychainListProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(
              context.tr('keychain.btn_delete', defaultText: 'Delete'),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddKeyDialog(BuildContext context, WidgetRef ref) {
    final labelCtrl = TextEditingController();
    final pemCtrl = TextEditingController();
    final passphraseCtrl = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: ShellitColors.obsidianCard,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: ShellitColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            context.tr('keychain.add_dialog_title', defaultText: 'Add SSH Key Manually (PEM)'),
            style: const TextStyle(
              color: ShellitColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (errorText != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ShellitColors.statusRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: ShellitColors.statusRed.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      errorText!,
                      style: const TextStyle(
                        color: ShellitColors.statusRed,
                        fontSize: 12,
                      ),
                    ),
                  ),
                TextField(
                  controller: labelCtrl,
                  style: const TextStyle(
                    color: ShellitColors.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    labelText: context.tr('keychain.add_label_field', defaultText: 'Key Label *'),
                    hintText: context.tr('keychain.add_label_hint', defaultText: 'e.g. id_ed25519_custom'),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pemCtrl,
                  maxLines: 5,
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    color: ShellitColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: context.tr('keychain.add_pem_field', defaultText: 'Private Key PEM Content *'),
                    hintText: '-----BEGIN OPENSSH PRIVATE KEY-----\n...',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passphraseCtrl,
                  obscureText: true,
                  style: const TextStyle(
                    color: ShellitColors.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    labelText: context.tr('keychain.add_passphrase_field', defaultText: 'Passphrase (if key is encrypted)'),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                context.tr('keychain.btn_cancel', defaultText: 'Cancel'),
                style: const TextStyle(color: ShellitColors.textMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ShellitColors.accentBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final label = labelCtrl.text.trim();
                final pem = pemCtrl.text.trim();
                final pass = passphraseCtrl.text.trim();

                if (label.isEmpty || pem.isEmpty) {
                  setState(
                    () => errorText = context.tr(
                      'keychain.error_missing_fields',
                      defaultText: 'Please fill in key label and PEM content.',
                    ),
                  );
                  return;
                }

                final parser = const KeyParserService();
                final parseRes = parser.parseKey(
                  pem: pem,
                  passphrase: pass.isNotEmpty ? pass : null,
                );

                if (parseRes.isError) {
                  setState(
                    () => errorText =
                        parseRes.failureOrNull?.message ??
                        context.tr('keychain.error_parsing', defaultText: 'Error parsing key'),
                  );
                  return;
                }

                final info = parseRes.valueOrNull!;
                final keyManager = ref.read(appKeyManagerProvider);
                final id = 'key_${DateTime.now().millisecondsSinceEpoch}';

                if (keyManager is KeyManager) {
                  final saveRes = await keyManager.encryptAndSaveKey(
                    id: id,
                    label: label,
                    keyType: info.keyType,
                    rawPrivateKey: utf8.encode(pem),
                    publicKey: info.publicKeyString,
                    rawPassphrase: pass.isNotEmpty ? pass : null,
                    fingerprint: info.fingerprint,
                  );

                  if (saveRes.isError) {
                    setState(
                      () => errorText =
                          saveRes.failureOrNull?.message ??
                          context.tr('keychain.error_saving', defaultText: 'Error saving to Vault'),
                    );
                    return;
                  }
                } else {
                  final entity = KeyEntity(
                    id: id,
                    label: label,
                    keyType: info.keyType,
                    encryptedPrivateKey: Uint8List.fromList(utf8.encode(pem)),
                    publicKey: info.publicKeyString,
                    fingerprint: info.fingerprint,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  await keyManager.saveKey(entity);
                }

                ref.invalidate(keychainListProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(
                context.tr('keychain.add_btn_save', defaultText: 'Validate & Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
