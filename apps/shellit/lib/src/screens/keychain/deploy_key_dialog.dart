import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ssh_network_core/ssh_network_core.dart';
import 'package:terminal_ui/terminal_ui.dart';
import '../../di/app_providers.dart';

class DeployKeyDialog extends ConsumerStatefulWidget {
  final KeyEntity keyEntity;

  const DeployKeyDialog({super.key, required this.keyEntity});

  static Future<void> show(BuildContext context, KeyEntity keyEntity) {
    return showDialog(
      context: context,
      builder: (ctx) => DeployKeyDialog(keyEntity: keyEntity),
    );
  }

  @override
  ConsumerState<DeployKeyDialog> createState() => _DeployKeyDialogState();
}

class _DeployKeyDialogState extends ConsumerState<DeployKeyDialog> {
  List<HostEntity> _hosts = [];
  bool _isLoadingHosts = true;

  HostEntity? _selectedHost;
  bool _useManualHost = false;

  final _hostnameCtrl = TextEditingController();
  final _portCtrl = TextEditingController(text: '22');
  final _usernameCtrl = TextEditingController(text: 'root');
  final _passwordCtrl = TextEditingController();

  bool _bindToHost = true;
  bool _isDeploying = false;
  bool _obscurePassword = true;
  String? _statusMessage;
  bool _isSuccess = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHosts();
  }

  @override
  void dispose() {
    _hostnameCtrl.dispose();
    _portCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHosts() async {
    try {
      final hosts = await ref.read(appHostRepositoryProvider).getAllHosts();
      setState(() {
        _hosts = hosts;
        _isLoadingHosts = false;
        if (hosts.isNotEmpty) {
          _selectedHost = hosts.first;
        } else {
          _useManualHost = true;
        }
      });
    } catch (_) {
      setState(() {
        _isLoadingHosts = false;
        _useManualHost = true;
      });
    }
  }

  Future<void> _handleDeploy() async {
    final String host;
    final int port;
    final String user;

    if (_useManualHost || _selectedHost == null) {
      host = _hostnameCtrl.text.trim();
      port = int.tryParse(_portCtrl.text.trim()) ?? 22;
      user = _usernameCtrl.text.trim();
    } else {
      host = _selectedHost!.hostname;
      port = _selectedHost!.port;
      user = _selectedHost!.username;
    }

    if (host.isEmpty || user.isEmpty) {
      setState(() => _errorMessage = 'Укажите хост и имя пользователя');
      return;
    }

    setState(() {
      _isDeploying = true;
      _errorMessage = null;
      _statusMessage = 'Connecting to $host:$port...';
    });

    try {
      final deployService = ref.read(appSshKeyDeployServiceProvider);
      final password = _passwordCtrl.text.isNotEmpty
          ? _passwordCtrl.text
          : null;

      final result = await deployService.deployPublicKey(
        host: host,
        port: port,
        username: user,
        password: password,
        publicKey: widget.keyEntity.publicKey,
      );

      if (result.isError) {
        setState(() {
          _isDeploying = false;
          _errorMessage =
              result.failureOrNull?.message ?? 'Ошибка деплоя ключа';
        });
        return;
      }

      final status = result.valueOrNull!;
      String msg = status == KeyDeployStatus.alreadyPresent
          ? 'Ключ уже установлен в ~/.ssh/authorized_keys на $host'
          : 'Публичный ключ успешно добавлен в ~/.ssh/authorized_keys на $host!';

      // If bind requested and host was chosen from database
      if (_bindToHost && !_useManualHost && _selectedHost != null) {
        final updatedHost = _selectedHost!.copyWith(
          authType: HostAuthType.privateKey,
          credentialRefId: widget.keyEntity.id,
          updatedAt: DateTime.now(),
        );
        await ref.read(appHostRepositoryProvider).saveHost(updatedHost);
        msg +=
            '\nСервер "${updatedHost.label}" переключен на авторизацию по этому ключу.';
      }

      setState(() {
        _isDeploying = false;
        _isSuccess = true;
        _statusMessage = msg;
      });
    } catch (e) {
      setState(() {
        _isDeploying = false;
        _errorMessage = 'Ошибка: $e';
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
              color: ShellitColors.statusGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.cloud_upload_outlined,
              color: ShellitColors.statusGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Deploy Key to Server (ssh-copy-id)',
            style: TextStyle(
              color: ShellitColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: _isSuccess ? _buildSuccess() : _buildForm(),
      ),
      actions: _isSuccess ? _buildSuccessActions() : _buildFormActions(),
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
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ShellitColors.obsidianBackground,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: ShellitColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.vpn_key,
                size: 16,
                color: ShellitColors.accentCyan,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Deploying: ${widget.keyEntity.label} (${widget.keyEntity.keyType.name.toUpperCase()})',
                  style: const TextStyle(
                    color: ShellitColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (!_isLoadingHosts && _hosts.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: !_useManualHost
                        ? ShellitColors.accentBlue.withValues(alpha: 0.15)
                        : Colors.transparent,
                    side: BorderSide(
                      color: !_useManualHost
                          ? ShellitColors.accentBlue
                          : ShellitColors.border,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () => setState(() => _useManualHost = false),
                  child: Text(
                    'Saved Host',
                    style: TextStyle(
                      fontSize: 12,
                      color: !_useManualHost
                          ? ShellitColors.accentBlue
                          : ShellitColors.textMuted,
                      fontWeight: !_useManualHost
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _useManualHost
                        ? ShellitColors.accentBlue.withValues(alpha: 0.15)
                        : Colors.transparent,
                    side: BorderSide(
                      color: _useManualHost
                          ? ShellitColors.accentBlue
                          : ShellitColors.border,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () => setState(() => _useManualHost = true),
                  child: Text(
                    'Manual Host',
                    style: TextStyle(
                      fontSize: 12,
                      color: _useManualHost
                          ? ShellitColors.accentBlue
                          : ShellitColors.textMuted,
                      fontWeight: _useManualHost
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (!_useManualHost && _hosts.isNotEmpty) ...[
          DropdownButtonFormField<HostEntity>(
            initialValue: _selectedHost,
            decoration: const InputDecoration(
              labelText: 'Target Host',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: _hosts
                .map(
                  (h) => DropdownMenuItem(
                    value: h,
                    child: Text(
                      '${h.label} (${h.username}@${h.hostname}:${h.port})',
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => _selectedHost = val),
          ),
          const SizedBox(height: 12),
        ] else ...[
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _hostnameCtrl,
                  style: const TextStyle(
                    fontSize: 13,
                    color: ShellitColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Host IP or Domain *',
                    hintText: '192.168.1.100',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _portCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 13,
                    color: ShellitColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Port',
                    hintText: '22',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _usernameCtrl,
            style: const TextStyle(
              fontSize: 13,
              color: ShellitColors.textPrimary,
            ),
            decoration: const InputDecoration(
              labelText: 'Username *',
              hintText: 'root / ubuntu',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _passwordCtrl,
          obscureText: _obscurePassword,
          style: const TextStyle(
            fontSize: 13,
            color: ShellitColors.textPrimary,
          ),
          decoration: InputDecoration(
            labelText: 'Server Password (for 1-time key deploy) *',
            hintText: 'Enter password to authenticate',
            isDense: true,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                size: 16,
                color: ShellitColors.textMuted,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        if (!_useManualHost && _selectedHost != null) ...[
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _bindToHost,
            title: const Text(
              'Bind this key to the host in Shellit for future logins',
              style: TextStyle(
                fontSize: 12,
                color: ShellitColors.textSecondary,
              ),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            contentPadding: EdgeInsets.zero,
            activeColor: ShellitColors.accentBlue,
            onChanged: (val) => setState(() => _bindToHost = val ?? true),
          ),
        ],
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ShellitColors.statusGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: ShellitColors.statusGreen.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: ShellitColors.statusGreen,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _statusMessage ?? 'Key successfully deployed!',
                  style: const TextStyle(
                    color: ShellitColors.statusGreen,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
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
          backgroundColor: ShellitColors.statusGreen,
          foregroundColor: Colors.white,
        ),
        icon: _isDeploying
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.cloud_upload, size: 16),
        label: Text(_isDeploying ? 'Deploying...' : 'Deploy Key'),
        onPressed: _isDeploying ? null : _handleDeploy,
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
