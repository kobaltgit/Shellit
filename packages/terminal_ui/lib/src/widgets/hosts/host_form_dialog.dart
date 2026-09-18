import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import '../../theme/shellit_theme.dart';

typedef HostFormSaveCallback = void Function(HostEntity host, String? password);

class HostFormDialog extends StatefulWidget {
  final HostEntity? initialHost;
  final HostFormSaveCallback onSave;
  final List<KeyEntity> availableKeys;

  const HostFormDialog({
    super.key,
    this.initialHost,
    required this.onSave,
    this.availableKeys = const [],
  });

  @override
  State<HostFormDialog> createState() => _HostFormDialogState();
}

class _HostFormDialogState extends State<HostFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _labelController;
  late TextEditingController _hostnameController;
  late TextEditingController _portController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _tagsController;
  late TextEditingController _folderController;

  late HostAuthType _authType;
  late HostEnvironment _environment;
  late OsType _osType;
  late bool _dangerousCommandProtection;
  late bool _obscurePassword;
  String? _selectedKeyId;

  @override
  void initState() {
    super.initState();
    final h = widget.initialHost;
    _labelController = TextEditingController(text: h?.label ?? '');
    _hostnameController = TextEditingController(text: h?.hostname ?? '');
    _portController = TextEditingController(text: (h?.port ?? 22).toString());
    _usernameController = TextEditingController(text: h?.username ?? 'root');
    _passwordController = TextEditingController();
    _tagsController = TextEditingController(text: h?.tags.join(', ') ?? '');
    _folderController = TextEditingController(text: h?.folderId ?? '');

    _authType = h?.authType ?? HostAuthType.password;
    _environment = h?.environment ?? HostEnvironment.defaultEnv;
    _osType = h?.osType ?? OsType.genericServer;
    _dangerousCommandProtection = h?.dangerousCommandProtection ?? false;
    _obscurePassword = true;
    _selectedKeyId = h?.credentialRefId;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _hostnameController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _tagsController.dispose();
    _folderController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final now = DateTime.now();
      final tags = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final host = HostEntity(
        id: widget.initialHost?.id ?? 'host-${now.millisecondsSinceEpoch}',
        label: _labelController.text.trim(),
        hostname: _hostnameController.text.trim(),
        port: int.tryParse(_portController.text.trim()) ?? 22,
        username: _usernameController.text.trim(),
        authType: _authType,
        credentialRefId: _authType == HostAuthType.privateKey
            ? _selectedKeyId
            : widget.initialHost?.credentialRefId,
        environment: _environment,
        osType: _osType,
        tags: tags,
        folderId: _folderController.text.trim().isEmpty
            ? null
            : _folderController.text.trim(),
        dangerousCommandProtection: _dangerousCommandProtection,
        lastPingLatencyMs: widget.initialHost?.lastPingLatencyMs,
        createdAt: widget.initialHost?.createdAt ?? now,
        updatedAt: now,
      );

      final enteredPassword = _passwordController.text.trim().isNotEmpty
          ? _passwordController.text.trim()
          : null;

      widget.onSave(host, enteredPassword);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialHost != null;

    return AlertDialog(
      title: Text(
        isEdit ? 'Edit Host' : 'New SSH Host',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label
                TextFormField(
                  controller: _labelController,
                  decoration: const InputDecoration(
                    labelText: 'Label / Alias',
                    hintText: 'e.g. Production Web 01',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Label is required'
                      : null,
                ),
                const SizedBox(height: 12),

                // Hostname & Port
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _hostnameController,
                        decoration: const InputDecoration(
                          labelText: 'Hostname / IP',
                          hintText: '192.168.1.1 or example.com',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Hostname is required'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _portController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Port',
                        ),
                        validator: (v) {
                          final p = int.tryParse(v ?? '');
                          if (p == null || p <= 0 || p > 65535)
                            return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Username & Auth Type
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          hintText: 'root, ubuntu, etc.',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Username is required'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<HostAuthType>(
                        initialValue: _authType,
                        decoration:
                            const InputDecoration(labelText: 'Auth Method'),
                        items: HostAuthType.values.map((a) {
                          return DropdownMenuItem(
                            value: a,
                            child: Text(a.name,
                                style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _authType = v);
                        },
                      ),
                    ),
                  ],
                ),
                if (_authType == HostAuthType.password) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: isEdit
                          ? 'SSH Password (leave blank to keep current)'
                          : 'SSH Password',
                      hintText: 'Enter server password',
                      prefixIcon: const Icon(Icons.lock_outline, size: 18),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 18,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                ] else if (_authType == HostAuthType.privateKey) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: _selectedKeyId,
                    decoration: const InputDecoration(
                      labelText: 'SSH Key (from Keychain)',
                      prefixIcon: Icon(Icons.vpn_key_outlined, size: 18),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('None (Use system agent or prompt)',
                            style: TextStyle(fontSize: 13)),
                      ),
                      ...widget.availableKeys
                          .map((k) => DropdownMenuItem<String?>(
                                value: k.id,
                                child: Text(
                                    '${k.label} (${k.keyType.name.toUpperCase()})',
                                    style: const TextStyle(fontSize: 13)),
                              )),
                    ],
                    onChanged: (v) => setState(() => _selectedKeyId = v),
                  ),
                ],
                const SizedBox(height: 12),

                // Environment (OS is auto-detected upon connection)
                DropdownButtonFormField<HostEnvironment>(
                  initialValue: _environment,
                  decoration: const InputDecoration(
                    labelText: 'Environment',
                    helperText:
                        'OS / Distribution is auto-detected upon SSH connection',
                  ),
                  items: HostEnvironment.values.map((env) {
                    return DropdownMenuItem(
                      value: env,
                      child:
                          Text(env.name, style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _environment = v;
                        if (v == HostEnvironment.production) {
                          _dangerousCommandProtection = true;
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Folder & Tags
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _folderController,
                        decoration: const InputDecoration(
                          labelText: 'Folder (optional)',
                          hintText: 'e.g. Datacenter EU',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _tagsController,
                        decoration: const InputDecoration(
                          labelText: 'Tags (comma separated)',
                          hintText: 'web, db, k8s',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Dangerous Command Protection switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Production Command Guard',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Intercept destructive commands (rm -rf, reboot, etc.) and require confirmation',
                    style: TextStyle(
                        fontSize: 12, color: ShellitColors.textSecondary),
                  ),
                  value: _dangerousCommandProtection,
                  activeThumbColor: ShellitColors.statusRed,
                  onChanged: (val) {
                    setState(() => _dangerousCommandProtection = val);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: ShellitColors.accentBlue,
            foregroundColor: Colors.white,
          ),
          child: Text(isEdit ? 'Save Changes' : 'Create'),
        ),
      ],
    );
  }
}
