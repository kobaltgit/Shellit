import 'dart:convert';
import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ssh_network_core/ssh_network_core.dart';
import 'package:storage_vault/storage_vault.dart';
import 'package:terminal_ui/terminal_ui.dart';
import '../../di/app_providers.dart';

class GenerateKeyDialog extends ConsumerStatefulWidget {
  const GenerateKeyDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const GenerateKeyDialog(),
    );
  }

  @override
  ConsumerState<GenerateKeyDialog> createState() => _GenerateKeyDialogState();
}

class _GenerateKeyDialogState extends ConsumerState<GenerateKeyDialog> {
  final _labelCtrl = TextEditingController(text: 'id_ed25519');
  final _commentCtrl = TextEditingController(text: 'shellit@local');
  final _passphraseCtrl = TextEditingController();

  KeyType _selectedType = KeyType.ed25519;
  bool _isGenerating = false;
  bool _obscurePassphrase = true;
  String? _errorMessage;

  GeneratedKeyPair? _generatedKey;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _commentCtrl.dispose();
    _passphraseCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleGenerate() async {
    final label = _labelCtrl.text.trim();
    if (label.isEmpty) {
      setState(() => _errorMessage = 'Введите название ключа (Label)');
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final generator = ref.read(appKeyGeneratorServiceProvider);
      final comment = _commentCtrl.text.trim();
      final passphrase = _passphraseCtrl.text.trim();

      final GeneratedKeyPair pair;
      if (_selectedType == KeyType.ed25519) {
        pair = generator.generateEd25519(
          comment: comment.isNotEmpty ? comment : null,
        );
      } else {
        pair = generator.generateRsa(
          bitLength: 4096,
          comment: comment.isNotEmpty ? comment : null,
        );
      }

      // Save to KeyManager
      final keyManager = ref.read(appKeyManagerProvider);
      final id = 'key_${DateTime.now().millisecondsSinceEpoch}';

      if (keyManager is KeyManager) {
        final saveRes = await keyManager.encryptAndSaveKey(
          id: id,
          label: label,
          keyType: pair.keyType,
          rawPrivateKey: utf8.encode(pair.privateKeyPem),
          publicKey: pair.publicKeyString,
          rawPassphrase: passphrase.isNotEmpty ? passphrase : null,
          fingerprint: pair.fingerprint,
        );

        if (saveRes.isError) {
          throw Exception(saveRes.failureOrNull?.message ?? 'Save error');
        }
      } else {
        final entity = KeyEntity(
          id: id,
          label: label,
          keyType: pair.keyType,
          encryptedPrivateKey: Uint8List.fromList(
            utf8.encode(pair.privateKeyPem),
          ),
          publicKey: pair.publicKeyString,
          fingerprint: pair.fingerprint,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await keyManager.saveKey(entity);
      }

      setState(() {
        _isGenerating = false;
        _generatedKey = pair;
      });
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _errorMessage = 'Ошибка генерации: $e';
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
              color: ShellitColors.accentBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.vpn_key_rounded,
              color: ShellitColors.accentBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _generatedKey == null ? 'Generate SSH Key Pair' : 'Key Generated!',
            style: const TextStyle(
              color: ShellitColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: _generatedKey == null ? _buildForm() : _buildSuccessView(),
      ),
      actions: _generatedKey == null
          ? _buildFormActions()
          : _buildSuccessActions(),
    );
  }

  Widget _buildForm() {
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
        const Text(
          'Algorithm Type',
          style: TextStyle(
            color: ShellitColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _buildTypeOption(
                type: KeyType.ed25519,
                title: 'Ed25519',
                subtitle: 'Fast & Secure (Recommended)',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTypeOption(
                type: KeyType.rsa,
                title: 'RSA 4096-bit',
                subtitle: 'Legacy compatibility',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _labelCtrl,
          style: const TextStyle(
            color: ShellitColors.textPrimary,
            fontSize: 13,
          ),
          decoration: const InputDecoration(
            labelText: 'Key Label / Name *',
            hintText: 'e.g. id_ed25519_prod',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _commentCtrl,
          style: const TextStyle(
            color: ShellitColors.textPrimary,
            fontSize: 13,
          ),
          decoration: const InputDecoration(
            labelText: 'Comment (Public ID)',
            hintText: 'e.g. user@hostname',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passphraseCtrl,
          obscureText: _obscurePassphrase,
          style: const TextStyle(
            color: ShellitColors.textPrimary,
            fontSize: 13,
          ),
          decoration: InputDecoration(
            labelText: 'Passphrase (Optional)',
            hintText: 'Leave empty for no passphrase',
            border: const OutlineInputBorder(),
            isDense: true,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassphrase ? Icons.visibility_off : Icons.visibility,
                size: 16,
                color: ShellitColors.textMuted,
              ),
              onPressed: () =>
                  setState(() => _obscurePassphrase = !_obscurePassphrase),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeOption({
    required KeyType type,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
          if (_labelCtrl.text == 'id_ed25519' || _labelCtrl.text == 'id_rsa') {
            _labelCtrl.text = type == KeyType.ed25519 ? 'id_ed25519' : 'id_rsa';
          }
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? ShellitColors.accentBlue.withValues(alpha: 0.12)
              : ShellitColors.obsidianBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? ShellitColors.accentBlue : ShellitColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 14,
                  color: isSelected
                      ? ShellitColors.accentBlue
                      : ShellitColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected
                        ? ShellitColors.textPrimary
                        : ShellitColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: ShellitColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    final key = _generatedKey!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: ShellitColors.statusGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: ShellitColors.statusGreen.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: ShellitColors.statusGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Key Pair created & safely encrypted in Vault!\nFingerprint: ${key.fingerprint}',
                  style: const TextStyle(
                    color: ShellitColors.statusGreen,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'OpenSSH Public Key (Add this to your servers):',
          style: TextStyle(
            color: ShellitColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: ShellitColors.obsidianBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ShellitColors.border),
          ),
          child: SelectableText(
            key.publicKeyString,
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 11,
              color: ShellitColors.textPrimary,
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
          label: const Text('Copy Public Key to Clipboard'),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: key.publicKeyString));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Public key copied to clipboard!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }

  List<Widget> _buildFormActions() {
    return [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text(
          'Cancel',
          style: TextStyle(color: ShellitColors.textMuted),
        ),
      ),
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: ShellitColors.accentBlue,
          foregroundColor: Colors.white,
        ),
        icon: _isGenerating
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.bolt, size: 16),
        label: Text(_isGenerating ? 'Generating...' : 'Generate & Save'),
        onPressed: _isGenerating ? null : _handleGenerate,
      ),
    ];
  }

  List<Widget> _buildSuccessActions() {
    return [
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: ShellitColors.accentBlue,
          foregroundColor: Colors.white,
        ),
        onPressed: () => Navigator.pop(context),
        child: const Text('Done'),
      ),
    ];
  }
}
