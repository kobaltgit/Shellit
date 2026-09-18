import 'dart:convert';
import 'dart:typed_data';
import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_ui/terminal_ui.dart';
import '../../di/app_providers.dart';

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
        title: const Text(
          'SSH Keychain & Certificates',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: ShellitColors.obsidianBackground,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: const Text('Add Key'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ShellitColors.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
              onPressed: () => _showAddKeyDialog(context, ref),
            ),
          ),
        ],
      ),
      body: keysAsync.when(
        data: (keys) {
          if (keys.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.vpn_key_outlined,
                    size: 48,
                    color: ShellitColors.textMuted,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No SSH Keys Saved',
                    style: TextStyle(
                      color: ShellitColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Add an Ed25519, RSA, or ECDSA key to connect passwordless',
                    style: TextStyle(
                      color: ShellitColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add New Key'),
                    onPressed: () => _showAddKeyDialog(context, ref),
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
              return Card(
                color: ShellitColors.obsidianCard,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: ShellitColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ShellitColors.accentBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.vpn_key,
                      color: ShellitColors.accentBlue,
                      size: 20,
                    ),
                  ),
                  title: Row(
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
                          color: ShellitColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          key.keyType.name.toUpperCase(),
                          style: const TextStyle(
                            color: ShellitColors.accentCyan,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    'Fingerprint: ${key.fingerprint ?? 'SHA256:...'}\nCreated: ${key.createdAt.toLocal().toString().split('.')[0]}',
                    style: const TextStyle(
                      color: ShellitColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: ShellitColors.statusRed,
                      size: 18,
                    ),
                    tooltip: 'Delete Key',
                    onPressed: () async {
                      await ref.read(appKeyManagerProvider).deleteKey(key.id);
                      ref.invalidate(keychainListProvider);
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(
            'Error loading keys: $err',
            style: const TextStyle(color: ShellitColors.statusRed),
          ),
        ),
      ),
    );
  }

  void _showAddKeyDialog(BuildContext context, WidgetRef ref) {
    final labelCtrl = TextEditingController();
    final pemCtrl = TextEditingController();
    KeyType selectedType = KeyType.ed25519;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: ShellitColors.obsidianCard,
          title: const Text(
            'Add SSH Key',
            style: TextStyle(color: ShellitColors.textPrimary, fontSize: 16),
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelCtrl,
                  style: const TextStyle(
                    color: ShellitColors.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Key Label (e.g. id_ed25519_github)',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<KeyType>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'Key Type'),
                  items: KeyType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => selectedType = val);
                  },
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
                  decoration: const InputDecoration(
                    labelText: 'Private Key PEM Content',
                    hintText: '-----BEGIN OPENSSH PRIVATE KEY-----\n...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: ShellitColors.textMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ShellitColors.accentBlue,
              ),
              onPressed: () async {
                if (labelCtrl.text.isNotEmpty && pemCtrl.text.isNotEmpty) {
                  final now = DateTime.now();
                  final key = KeyEntity(
                    id: 'key_${now.millisecondsSinceEpoch}',
                    label: labelCtrl.text.trim(),
                    keyType: selectedType,
                    encryptedPrivateKey: Uint8List.fromList(
                      utf8.encode(pemCtrl.text.trim()),
                    ),
                    publicKey: 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5...',
                    fingerprint: 'SHA256:${labelCtrl.text.hashCode}',
                    createdAt: now,
                    updatedAt: now,
                  );
                  await ref.read(appKeyManagerProvider).saveKey(key);
                  ref.invalidate(keychainListProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text(
                'Save Key',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
