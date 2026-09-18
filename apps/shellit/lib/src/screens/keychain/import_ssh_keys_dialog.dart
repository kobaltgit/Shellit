import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ssh_network_core/ssh_network_core.dart';
import 'package:storage_vault/storage_vault.dart';
import 'package:terminal_ui/terminal_ui.dart';
import '../../di/app_providers.dart';

class ImportSshKeysDialog extends ConsumerStatefulWidget {
  const ImportSshKeysDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const ImportSshKeysDialog(),
    );
  }

  @override
  ConsumerState<ImportSshKeysDialog> createState() =>
      _ImportSshKeysDialogState();
}

class _ImportSshKeysDialogState extends ConsumerState<ImportSshKeysDialog> {
  bool _isLoading = true;
  String? _scannedPath;
  List<DiscoveredKey> _discoveredKeys = [];
  final Map<String, bool> _selected = {};
  final Map<String, TextEditingController> _passphraseControllers = {};

  bool _isImporting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scan();
  }

  @override
  void dispose() {
    for (final ctrl in _passphraseControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _scan() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final discovery = ref.read(appSshDiscoveryServiceProvider);
      _scannedPath = discovery.getDefaultSshDirectoryPath();
      final keys = await discovery.scanDirectory();

      for (final k in keys) {
        _selected[k.privateKeyPath] = true;
        if (k.isEncrypted) {
          _passphraseControllers[k.privateKeyPath] = TextEditingController();
        }
      }

      setState(() {
        _discoveredKeys = keys;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Scan error: $e';
      });
    }
  }

  Future<void> _handleImport() async {
    final selectedKeys = _discoveredKeys
        .where((k) => _selected[k.privateKeyPath] == true)
        .toList();

    if (selectedKeys.isEmpty) {
      setState(
        () => _errorMessage = context.tr(
          'keychain.import_dialog_err_none_selected',
          defaultText: 'Select at least one key to import.',
        ),
      );
      return;
    }

    setState(() {
      _isImporting = true;
      _errorMessage = null;
    });

    final keyManager = ref.read(appKeyManagerProvider);
    final parser = const KeyParserService();
    int importedCount = 0;

    try {
      for (final key in selectedKeys) {
        final file = File(key.privateKeyPath);
        if (!await file.exists()) continue;

        final rawPem = await file.readAsString();
        final passphrase = _passphraseControllers[key.privateKeyPath]?.text
            .trim();

        // Validate key and parse info
        final parseRes = parser.parseKey(
          pem: rawPem,
          passphrase: passphrase?.isNotEmpty == true ? passphrase : null,
        );

        if (parseRes.isError) {
          throw Exception(
            'Key ${key.fileName}: ${parseRes.failureOrNull?.message ?? "Decryption error"}',
          );
        }

        final parsed = parseRes.valueOrNull!;
        final id =
            'key_${DateTime.now().millisecondsSinceEpoch}_$importedCount';

        if (keyManager is KeyManager) {
          final saveRes = await keyManager.encryptAndSaveKey(
            id: id,
            label: key.fileName,
            keyType: parsed.keyType,
            rawPrivateKey: utf8.encode(rawPem),
            publicKey: parsed.publicKeyString,
            rawPassphrase: passphrase?.isNotEmpty == true ? passphrase : null,
            fingerprint: parsed.fingerprint,
          );

          if (saveRes.isError) {
            throw Exception(saveRes.failureOrNull?.message ?? 'Save error');
          }
        } else {
          final entity = KeyEntity(
            id: id,
            label: key.fileName,
            keyType: parsed.keyType,
            encryptedPrivateKey: Uint8List.fromList(utf8.encode(rawPem)),
            publicKey: parsed.publicKeyString,
            fingerprint: parsed.fingerprint,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await keyManager.saveKey(entity);
        }

        importedCount++;
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                'keychain.import_dialog_success_msg',
                defaultText: 'Successfully imported keys: {count}',
              ).replaceAll('{count}', importedCount.toString()),
            ),
            backgroundColor: ShellitColors.statusGreen,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isImporting = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ShellitColors.obsidianCard,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: ShellitColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: ShellitColors.accentCyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.folder_open_rounded,
              color: ShellitColors.accentCyan,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            context.tr('keychain.import_dialog_title', defaultText: 'Import from ~/.ssh'),
            style: const TextStyle(
              color: ShellitColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SizedBox(width: 540, child: _buildContent()),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            context.tr('common.cancel', defaultText: 'Cancel'),
            style: const TextStyle(color: ShellitColors.textMuted),
          ),
        ),
        if (!_isLoading && _discoveredKeys.isNotEmpty)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: ShellitColors.accentBlue,
              foregroundColor: Colors.white,
            ),
            icon: _isImporting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download, size: 16),
            label: Text(
              _isImporting
                  ? context.tr('keychain.import_dialog_btn_importing', defaultText: 'Importing...')
                  : context.tr('keychain.import_dialog_btn_import_selected', defaultText: 'Import Selected'),
            ),
            onPressed: _isImporting ? null : _handleImport,
          ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              context.tr(
                'keychain.import_dialog_scanning',
                defaultText: 'Scanning ~/.ssh directory...',
              ),
              style: const TextStyle(color: ShellitColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_discoveredKeys.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.folder_off_outlined,
              size: 44,
              color: ShellitColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('keychain.import_dialog_no_keys_title', defaultText: 'No SSH Keys Found'),
              style: const TextStyle(
                color: ShellitColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr(
                'keychain.import_dialog_dir_label',
                defaultText: 'Directory: {dir}',
              ).replaceAll('{dir}', _scannedPath ?? 'unknown'),
              style: const TextStyle(
                color: ShellitColors.textMuted,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final selectedCount = _selected.values.where((v) => v).length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_errorMessage != null)
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
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 16,
                  color: ShellitColors.statusRed,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: ShellitColors.statusRed,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr(
                'keychain.import_dialog_found_keys',
                defaultText: 'Found {count} keys in {dir}',
              ).replaceAll('{count}', _discoveredKeys.length.toString()).replaceAll('{dir}', _scannedPath ?? '~/.ssh'),
              style: const TextStyle(
                color: ShellitColors.textSecondary,
                fontSize: 12,
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              onPressed: () {
                final allSelected = selectedCount == _discoveredKeys.length;
                setState(() {
                  for (final k in _discoveredKeys) {
                    _selected[k.privateKeyPath] = !allSelected;
                  }
                });
              },
              child: Text(
                selectedCount == _discoveredKeys.length
                    ? context.tr('keychain.import_dialog_deselect_all', defaultText: 'Deselect All')
                    : context.tr('keychain.import_dialog_select_all', defaultText: 'Select All'),
                style: const TextStyle(
                  color: ShellitColors.accentBlue,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _discoveredKeys.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final key = _discoveredKeys[index];
              final isChecked = _selected[key.privateKeyPath] ?? false;

              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isChecked
                      ? ShellitColors.obsidianBackground
                      : ShellitColors.obsidianBackground.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isChecked
                        ? ShellitColors.borderFocus
                        : ShellitColors.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: isChecked,
                          activeColor: ShellitColors.accentBlue,
                          onChanged: (val) {
                            setState(
                              () =>
                                  _selected[key.privateKeyPath] = val ?? false,
                            );
                          },
                        ),
                        const SizedBox(width: 4),
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            key.fileName,
                            style: const TextStyle(
                              color: ShellitColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (key.isEncrypted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: ShellitColors.statusYellow.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.lock,
                                  size: 11,
                                  color: ShellitColors.statusYellow,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  context.tr(
                                    'keychain.import_dialog_badge_encrypted',
                                    defaultText: 'Encrypted',
                                  ),
                                  style: const TextStyle(
                                    color: ShellitColors.statusYellow,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (key.fingerprint != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 48, top: 2),
                        child: Text(
                          key.fingerprint!,
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            color: ShellitColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    if (key.isEncrypted && isChecked)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 48,
                          top: 8,
                          right: 12,
                          bottom: 4,
                        ),
                        child: TextField(
                          controller:
                              _passphraseControllers[key.privateKeyPath],
                          obscureText: true,
                          style: const TextStyle(
                            color: ShellitColors.textPrimary,
                            fontSize: 12,
                          ),
                          decoration: InputDecoration(
                            labelText: context.tr(
                              'keychain.import_dialog_passphrase_field',
                              defaultText: 'Key Passphrase (required to decrypt)',
                            ),
                            isDense: true,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.key, size: 14),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
