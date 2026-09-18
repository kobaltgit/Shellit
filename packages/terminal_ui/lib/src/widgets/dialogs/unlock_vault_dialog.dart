import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../localization/localization_scope.dart';
import '../../providers/vault_provider.dart';
import '../../theme/shellit_theme.dart';

/// Shows a dialog prompting the user to enter their Master Password to unlock the vault.
/// Returns `true` if unlocked successfully, or `false`/`null` if cancelled.
Future<bool?> showUnlockVaultDialog(BuildContext context, WidgetRef ref) {
  final passController = TextEditingController();

  return showDialog<bool>(
    context: context,
    builder: (dialogCtx) {
      return Consumer(
        builder: (context, ref, _) {
          return AlertDialog(
            backgroundColor: ShellitColors.obsidianCard,
            title: Row(
              children: [
                const Icon(Icons.lock_rounded,
                    color: ShellitColors.accentCyan, size: 22),
                const SizedBox(width: 8),
                Text(
                  context.tr('vault.unlock_title', defaultText: 'Unlock Vault'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ShellitColors.textPrimary,
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
                  Text(
                    context.tr('vault.unlock_desc',
                        defaultText:
                            'A master password is required to access stored credentials and SSH keys.'),
                    style: const TextStyle(
                      fontSize: 13,
                      color: ShellitColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passController,
                    obscureText: true,
                    autofocus: true,
                    style: const TextStyle(
                      color: ShellitColors.textPrimary,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      labelText: context.tr('vault.unlock_password_label',
                          defaultText: 'Master Password'),
                      hintText: context.tr('vault.unlock_password_hint',
                          defaultText: 'Enter master password'),
                      prefixIcon: const Icon(Icons.key,
                          size: 16, color: ShellitColors.accentCyan),
                    ),
                    onSubmitted: (pwd) async {
                      final ok = await ref
                          .read(vaultProvider.notifier)
                          .unlockWithPassword(pwd);
                      if (dialogCtx.mounted) {
                        if (ok) {
                          Navigator.of(dialogCtx).pop(true);
                        } else {
                          final err = ref.read(vaultProvider).errorMessage ??
                              context.tr('vault.unlock_failed',
                                  defaultText: 'Invalid master password');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(err),
                              backgroundColor: ShellitColors.statusRed,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(false),
                child: Text(context.tr('common.cancel', defaultText: 'Cancel')),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.lock_open_rounded, size: 16),
                label:
                    Text(context.tr('vault.unlock_btn', defaultText: 'Unlock')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ShellitColors.accentBlue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () async {
                  final ok = await ref
                      .read(vaultProvider.notifier)
                      .unlockWithPassword(passController.text);
                  if (dialogCtx.mounted) {
                    if (ok) {
                      Navigator.of(dialogCtx).pop(true);
                    } else {
                      final err = ref.read(vaultProvider).errorMessage ??
                          context.tr('vault.unlock_failed',
                              defaultText: 'Invalid master password');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(err),
                          backgroundColor: ShellitColors.statusRed,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}
